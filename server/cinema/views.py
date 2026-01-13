from rest_framework import generics, status, viewsets
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.http import HttpResponse
from rest_framework.authtoken.models import Token
from django.contrib.auth.models import User as DjangoUser
from django.contrib.auth.hashers import check_password, make_password
from django.db import transaction
from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
from datetime import datetime, timedelta
import json
import qrcode
import uuid
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A5
from reportlab.lib.utils import ImageReader
from io import BytesIO
import io
import os


from .models import (
    User, Movie, Session, Ticket, Order, Hall, Seat, SessionSeat,
    Genre, UserPointsBalance, PointsTransaction, Cancellation
)
from .serializers import MovieSerializer, SessionSerializer, TicketSerializer



# ==================== VIEWSETS (для админ-панели) ====================
from rest_framework.parsers import MultiPartParser, FormParser  # Добавьте эту строку

class MovieViewSet(viewsets.ModelViewSet):
    """ViewSet для фильмов - автоматически создает все CRUD методы"""
    queryset = Movie.objects.filter(is_active=True)
    serializer_class = MovieSerializer
    parser_classes = [MultiPartParser, FormParser]  # ДОБАВЬТЕ ЭТУ СТРОКУ



class SessionViewSet(viewsets.ModelViewSet):
    """ViewSet для сеансов - автоматически создает все CRUD методы"""
    queryset = Session.objects.filter(is_active=True)
    serializer_class = SessionSerializer
    
    def get_queryset(self):
        queryset = super().get_queryset()
        movie_id = self.request.query_params.get('movie_id')
        if movie_id:
            queryset = queryset.filter(movie_id=movie_id)
        return queryset

ADMIN_PASSWORD = os.getenv('ADMIN_PANEL_PASSWORD')

@csrf_exempt
@api_view(['POST'])
def admin_login_check(request):
    """Проверка пароля для доступа к админке"""
    try:
        data = json.loads(request.body)
        password = data.get('password')
        if password == ADMIN_PASSWORD:
            return JsonResponse({'success': True})
        else:
            return JsonResponse({'error': 'Неверный пароль'}, status=403)
    except Exception:
        return JsonResponse({'error': 'Ошибка запроса'}, status=400)


# ==================== СТАРЫЕ VIEWS (для остального функционала) ====================

# Билеты
class TicketListView(generics.ListAPIView):
    queryset = Ticket.objects.filter(ticket_status='valid')
    serializer_class = TicketSerializer



# Места и сеансы
@api_view(['GET'])
def get_session_seats(request, session_id):
    """Получить места для сеанса"""
    try:
        session = Session.objects.get(session_id=session_id)
        
        # Получаем все места в зале
        seats = Seat.objects.filter(hall_id=session.hall_id).order_by('row_number', 'seat_number')
        
        seat_data = []
        for seat in seats:
            # Проверяем статус места на этом сеансе
            session_seat = SessionSeat.objects.filter(
                session_id=session_id,
                seat_id=seat.seat_id
            ).first()
            
            seat_status = session_seat.status if session_seat else 'free'
            
            seat_data.append({
                'seat_id': seat.seat_id,
                'row_number': seat.row_number,
                'seat_number': seat.seat_number,
                'seat_type': seat.seat_type,
                'status': seat_status
            })
        
        return Response({
            'session_id': session_id,
            'hall_name': session.hall.name,
            'movie_title': session.movie.title,
            'session_datetime': session.session_datetime,
            'price': str(session.price),
            'seats': seat_data
        }, status=status.HTTP_200_OK)
    
    except Session.DoesNotExist:
        return Response({'error': 'Сеанс не найден'}, status=status.HTTP_404_NOT_FOUND)



# Регистрация
@api_view(['POST'])
def register(request):
    """Регистрация нового пользователя"""
    try:
        data = request.data
        
        # Проверяем обязательные поля
        required_fields = ['email', 'password', 'full_name', 'birth_date']
        for field in required_fields:
            if field not in data:
                return Response(
                    {'error': f'Поле {field} обязательно'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        # Проверяем что email уникален
        if User.objects.filter(email=data['email']).exists():
            return Response(
                {'error': 'Пользователь с этим email уже существует'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Создаем пользователя
        user = User.objects.create(
            email=data['email'],
            password_hash=make_password(data['password']),
            full_name=data['full_name'],
            phone=data.get('phone', ''),
            birth_date=data['birth_date'],
            is_active=True
        )
        
        # Создаем баланс баллов
        UserPointsBalance.objects.create(user=user, current_points=0)
        
        return Response({
            'user_id': user.user_id,
            'email': user.email,
            'full_name': user.full_name,
            'message': 'Регистрация успешна'
        }, status=status.HTTP_201_CREATED)
    
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)



# Вход
@api_view(['POST'])
def login(request):
    """Вход пользователя"""
    try:
        data = request.data
        
        if 'email' not in data or 'password' not in data:
            return Response(
                {'error': 'Email и пароль обязательны'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Ищем пользователя
        user = User.objects.filter(email=data['email']).first()
        
        if not user or not check_password(data['password'], user.password_hash):
            return Response(
                {'error': 'Неверные учетные данные'},
                status=status.HTTP_401_UNAUTHORIZED
            )
        
        # Генерируем токен
        token = f"token_{user.user_id}_{datetime.now().timestamp()}"
        
        return Response({
            'token': token,
            'user_id': user.user_id,
            'email': user.email,
            'full_name': user.full_name,
            'message': 'Вход успешен'
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)



# Профиль
@api_view(['GET'])
def get_profile(request):
    """Получить профиль пользователя"""
    try:
        user_id = request.query_params.get('user_id')
        if not user_id:
            return Response(
                {'error': 'user_id обязателен'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user = User.objects.get(user_id=user_id)
        points = UserPointsBalance.objects.get(user=user)
        
        return Response({
            'user_id': user.user_id,
            'email': user.email,
            'full_name': user.full_name,
            'phone': user.phone,
            'birth_date': user.birth_date,
            'current_points': points.current_points,
            'created_at': user.created_at
        }, status=status.HTTP_200_OK)
    
    except User.DoesNotExist:
        return Response({'error': 'Пользователь не найден'}, status=status.HTTP_404_NOT_FOUND)



# Купить билет
@api_view(['POST'])
@transaction.atomic
def buy_ticket(request):
    """Купить билет"""
    try:
        data = request.data
        
        required_fields = ['user_id', 'session_id', 'seat_id']
        for field in required_fields:
            if field not in data:
                return Response(
                    {'error': f'Поле {field} обязательно'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        user_id = data['user_id']
        session_id = data['session_id']
        seat_id = data['seat_id']
        
        # Получаем объекты
        user = User.objects.get(user_id=user_id)
        session = Session.objects.get(session_id=session_id)
        seat = Seat.objects.get(seat_id=seat_id)
        movie = session.movie
        
        # Проверяем возраст пользователя
        birth_date = user.birth_date
        today = datetime.now().date()
        age = today.year - birth_date.year - (
            (today.month, today.day) < (birth_date.month, birth_date.day)
        )
        
        required_age = {
            '0+': 0, '6+': 6, '12+': 12, '16+': 16, '18+': 18
        }.get(movie.age_rating, 0)
        
        if age < required_age:
            return Response(
                {'error': f'Вам должно быть не менее {required_age} лет для этого фильма'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Проверяем статус места
        session_seat = SessionSeat.objects.filter(
            session_id=session_id,
            seat_id=seat_id
        ).first()
        
        if session_seat and session_seat.status != 'free':
            return Response(
                {'error': 'Это место уже занято'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Создаем заказ и билет
        if session.price is None:
            return Response(
                {'error': 'Цена для этого сеанса не установлена'},
                status=status.HTTP_400_BAD_REQUEST
            )
        ticket_price = session.price  # Цена билета
        
        order = Order.objects.create(
            user=user,
            total_price=ticket_price,
            order_status='completed'
        )
        
        # Генерируем QR-код
        qr_code = str(uuid.uuid4())  
        ticket = Ticket.objects.create(
            order=order,
            session=session,
            seat=seat,
            qr_code=qr_code,
        )
        
        # Обновляем статус места
        if not session_seat:
            session_seat = SessionSeat.objects.create(
                session=session,
                seat=seat,
                status='sold',
                sold_at=datetime.now()
            )
        else:
            session_seat.status = 'sold'
            session_seat.sold_at = datetime.now()
            session_seat.save()
        
        # Начисляем баллы (!!!10 за 100 рублей!!!)
        points_earned = int(ticket_price / 100 * 10)
        points_balance = UserPointsBalance.objects.get(user=user)
        points_balance.current_points += points_earned
        points_balance.save()
        
        # Записываем транзакцию баллов
        expiry_date = datetime.now().date() + timedelta(days=30)
        PointsTransaction.objects.create(
            user=user,
            order=order,
            points_amount=points_earned,
            operation_type='earn',
            expiry_date=expiry_date,
            description=f'Покупка билета на {movie.title}'
        )
        
        # Уменьшаем количество доступных мест
        session.available_seats -= 1
        session.save()
        
        return Response({
            'ticket_id': ticket.ticket_id,
            'order_id': order.order_id,
            'qr_code': qr_code,
            'price': float(ticket_price),
            'points_earned': points_earned,
            'movie_title': movie.title,
            'session_datetime': session.session_datetime,
            'seat': f'{seat.row_number}{seat.seat_number}',
            'message': 'Билет успешно куплен'
        }, status=status.HTTP_201_CREATED)
    
    except User.DoesNotExist:
        return Response({'error': 'Пользователь не найден'}, status=status.HTTP_404_NOT_FOUND)
    except Session.DoesNotExist:
        return Response({'error': 'Сеанс не найден'}, status=status.HTTP_404_NOT_FOUND)
    except Seat.DoesNotExist:
        return Response({'error': 'Место не найдено'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

#Логика qr-кодов

@api_view(['GET'])
def qr_code_image(request, qr_code):
    try:
        ticket = Ticket.objects.get(qr_code=qr_code)
    except Ticket.DoesNotExist:
        return Response({'error': 'QR-код не найден'}, status=status.HTTP_404_NOT_FOUND)


    # Формируем URL для PDF (пока заглушка)
    target_url = request.build_absolute_uri(f"/api/ticket/pdf/{qr_code}/")


    # Генерация QR
    qr = qrcode.QRCode(version=1, box_size=8, border=4)
    qr.add_data(target_url)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white")


    # Сохраняем в буфер
    buffer = BytesIO()
    img.save(buffer, format="PNG")
    buffer.seek(0)


    # Возвращаем как файл через DRF
    return HttpResponse(buffer.getvalue(), content_type="image/png")

@api_view(['GET'])
def ticket_pdf(request, qr_code):
    django_request = request._request

    try:
        ticket = Ticket.objects.select_related('session__movie', 'seat').get(qr_code=qr_code)
    except Ticket.DoesNotExist:
        return Response({'error': 'Ticket not found'}, status=status.HTTP_404_NOT_FOUND)

    # Используем io.BytesIO явно
    pdf_buffer = io.BytesIO()
    p = canvas.Canvas(pdf_buffer, pagesize=A5)
    width, height = A5

    # === Оформление ===
    p.setFont("Helvetica-Bold", 18)
    p.drawString(50, height - 60, "NORA CINEMA TICKET")
    p.rect(40, height - 75, width - 80, 30, fill=0)
    p.line(40, height - 85, width - 40, height - 85)

    p.setFont("Helvetica", 12)
    y = height - 110
    line_height = 22

    p.drawString(50, y, f"Date: {ticket.session.session_datetime.strftime('%d.%m.%Y %H:%M')}")
    y -= line_height
    p.drawString(50, y, f"Seat: Row {ticket.seat.row_number}, Seat {ticket.seat.seat_number}")
    y -= line_height
    p.drawString(50, y, f"Ticket ID: {ticket.ticket_id}")
    y -= line_height
    p.drawString(50, y, f"Status: {ticket.ticket_status}")

    # === QR-код ===
    qr_url = django_request.build_absolute_uri(f"/api/ticket/pdf/{qr_code}/")
    qr = qrcode.QRCode(version=1, box_size=2, border=1)
    qr.add_data(qr_url)
    qr.make(fit=True)
    qr_img = qr.make_image(fill_color="black", back_color="white")

    qr_buffer = io.BytesIO() 
    qr_img.save(qr_buffer, format="PNG")
    qr_buffer.seek(0)
    qr_image_reader = ImageReader(qr_buffer)

    qr_size = 80
    qr_x = width - qr_size - 40
    qr_y = 60
    p.drawImage(qr_image_reader, qr_x, qr_y, width=qr_size, height=qr_size)

    p.setFont("Helvetica", 8)
    p.drawString(qr_x, qr_y - 15, "Scan to verify")

    p.line(40, 40, width - 40, 40)
    p.setFont("Helvetica-Oblique", 8)
    p.drawString(50, 25, "© NORA Cinema System | Valid only for this session")

    p.showPage()
    p.save()

    pdf_buffer.seek(0)
    response = HttpResponse(pdf_buffer.getvalue(), content_type='application/pdf')
    response['Content-Disposition'] = f'inline; filename="ticket_{qr_code}.pdf"'
    return response


@api_view(['GET'])
def get_user_tickets(request):
    """Получить все билеты пользователя"""
    try:
        user_id = request.query_params.get('user_id')
        if not user_id:
            return Response(
                {'error': 'user_id обязателен'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        tickets = Ticket.objects.filter(
            order__user_id=user_id
        ).select_related(
            'order', 
            'session__movie',  
            'seat'
        ).order_by('-created_at')
        
        ticket_data = []
        for ticket in tickets:
            ticket_data.append({
                'ticket_id': ticket.ticket_id,
                'movie_title': ticket.session.movie.title,  
                'session_datetime': ticket.session.session_datetime,
                'seat': f'{ticket.seat.row_number}{ticket.seat.seat_number}',
                'qr_code': ticket.qr_code,
                'ticket_status': ticket.ticket_status,
                'price': float(ticket.order.total_price),
                'created_at': ticket.created_at
            })
        
        return Response(ticket_data, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)



# Отменить билет
@api_view(['POST'])
@transaction.atomic
def cancel_ticket(request):
    """Отменить билет"""
    try:
        data = request.data
        
        if 'ticket_id' not in data:
            return Response(
                {'error': 'ticket_id обязателен'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        ticket = Ticket.objects.get(ticket_id=data['ticket_id'])
        session = ticket.session
        
        # Проверяем, что сеанс ещё не начался (>30 минут)
        now = datetime.now()
        time_until_session = session.session_datetime.replace(tzinfo=None) - now
        
        if time_until_session.total_seconds() < 30 * 60:
            return Response(
                {'error': 'Билет можно отменить не позже чем за 30 минут до начала'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Отмечаем билет как отменённый
        ticket.ticket_status = 'cancelled'
        ticket.is_valid = False
        ticket.save()
        
        # Освобождаем место
        session_seat = SessionSeat.objects.get(
            session_id=session.session_id,
            seat_id=ticket.seat_id
        )
        session_seat.status = 'free'
        session_seat.sold_at = None
        session_seat.save()
        
        # Увеличиваем доступные места
        session.available_seats += 1
        session.save()
        
        # КОСТЫЛЬ: не отнимаем баллы, если их нет (баланс <= 0)
        points_earned = int(ticket.order.total_price / 100 * 10)
        points_balance = UserPointsBalance.objects.get(user=ticket.order.user)
        
        if points_balance.current_points > 0:
            # Отнимаем, но не больше, чем есть
            actual_deduction = min(points_earned, points_balance.current_points)
            points_balance.current_points -= actual_deduction
            points_balance.save()
            
            # Записываем транзакцию возврата
            PointsTransaction.objects.create(
                user=ticket.order.user,
                points_amount=actual_deduction,
                operation_type='refund',
                description=f'Отмена начисления за отмену билета на {session.movie.title}'
            )
        else:
            # Баланс 0 или меньше — ничего не делаем
            actual_deduction = 0

        # Создаем запись об отмене
        Cancellation.objects.create(
            ticket=ticket,
            reason='Пользователь отменил билет',
            refunded_points=actual_deduction
        )
        
        return Response({
            'message': 'Билет успешно отменен',
            'refunded_points': actual_deduction  # сколько реально списано
        }, status=status.HTTP_200_OK)
    
    except Ticket.DoesNotExist:
        return Response({'error': 'Билет не найден'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)



# Получить баланс баллов
@api_view(['GET'])
def get_points_balance(request):
    """Получить баланс баллов пользователя"""
    try:
        user_id = request.query_params.get('user_id')
        if not user_id:
            return Response(
                {'error': 'user_id обязателен'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        points = UserPointsBalance.objects.get(user_id=user_id)
        
        return Response({
            'current_points': points.current_points,
            'last_updated': points.last_updated
        }, status=status.HTTP_200_OK)
    
    except UserPointsBalance.DoesNotExist:
        return Response(
            {'error': 'Баланс баллов не найден'},
            status=status.HTTP_404_NOT_FOUND
        )