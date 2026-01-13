# urls_working.py - РАБОЧИЙ ВАРИАНТ
# Путь: server/nora_django/urls.py

from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework.routers import DefaultRouter
from cinema.views import (
    MovieViewSet, SessionViewSet, TicketListView,
    get_session_seats, register, login, get_profile,
    buy_ticket, get_user_tickets, cancel_ticket, get_points_balance, 
    qr_code_image, ticket_pdf, admin_login_check
)

# Создаем router для ViewSets
router = DefaultRouter()
router.register(r'api/movies', MovieViewSet, basename='movie')
router.register(r'api/sessions', SessionViewSet, basename='session')


urlpatterns = [
    # Admin
    path('admin/', admin.site.urls),

    #admin-check for panel
    path('api/admin-check/', admin_login_check, name='admin_check'),
    
    # ===== ВАРИАНТ 1: СПЕЦИАЛЬНЫЕ URL'Ы ДО ROUTER =====
    # ВАЖНО: эти URL'ы ДОЛЖНЫ быть ДО include(router.urls)
    # Иначе router перехватит их раньше
    path('api/movies/create/', MovieViewSet.as_view({'post': 'create', 'get': 'list'}), name='movie-create'),
    path('api/sessions/create/', SessionViewSet.as_view({'post': 'create', 'get': 'list'}), name='session-create'),
    
    # Подключаем все маршруты из router (автоматически создаст все CRUD endpoints)
    path('', include(router.urls)),
    
    # API - Билеты
    path('api/tickets/', TicketListView.as_view(), name='ticket-list'),
    path('api/session/<int:session_id>/seats/', get_session_seats, name='session-seats'),
    path('api/tickets/buy/', buy_ticket, name='buy-ticket'),
    path('api/tickets/user/', get_user_tickets, name='user-tickets'),
    path('api/tickets/cancel/', cancel_ticket, name='cancel-ticket'),
    path('api/ticket/pdf/<str:qr_code>/', ticket_pdf, name='ticket-pdf'),
    
    # QR коды
    path('qr/<str:qr_code>/', qr_code_image, name='qr-code-image'),
    
    # API - Аутентификация
    path('api/register/', register, name='register'),
    path('api/login/', login, name='login'),
    path('api/profile/', get_profile, name='profile'),
    
    # API - Баллы
    path('api/points/', get_points_balance, name='points-balance'),

] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)