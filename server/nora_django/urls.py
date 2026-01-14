from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework.routers import DefaultRouter

from cinema.views import (
    MovieViewSet, SessionViewSet, TicketListView,
    get_session_seats, register, login, get_profile,
    buy_ticket, get_user_tickets, cancel_ticket, get_points_balance,
    qr_code_image, ticket_pdf, admin_login_check, HallViewSet,
    get_reports  # ← ДОБАВЛЕНА НОВАЯ ФУНКЦИЯ
)

# Router для ViewSets
router = DefaultRouter()
router.register(r'api/movies', MovieViewSet, basename='movie')
router.register(r'api/sessions', SessionViewSet, basename='session')
router.register(r'api/halls', HallViewSet, basename='hall')

urlpatterns = [
    # Admin
    path('admin/', admin.site.urls),
    path('api/admin-check', admin_login_check, name='admin-check'),
    
    # Router для CRUD операций
    path('', include(router.urls)),
    
    # API - Отчёты (НОВЫЙ МАРШРУТ)
    path('api/reports/', get_reports, name='reports'),
    
    # API - Билеты
    path('api/tickets/', TicketListView.as_view(), name='ticket-list'),
    path('api/session/<int:session_id>/seats/', get_session_seats, name='session-seats'),
    path('api/tickets/buy/', buy_ticket, name='buy-ticket'),
    path('api/tickets/user/', get_user_tickets, name='user-tickets'),
    path('api/tickets/cancel/', cancel_ticket, name='cancel-ticket'),
    path('api/ticket/pdf/<str:qr_code>/', ticket_pdf, name='ticket-pdf'),
    
    # API - QR коды
    path('qr/<str:qr_code>/', qr_code_image, name='qr-code-image'),
    
    # API - Аутентификация
    path('api/register/', register, name='register'),
    path('api/login/', login, name='login'),
    path('api/profile/', get_profile, name='profile'),
    
    # API - Баллы
    path('api/points/', get_points_balance, name='points-balance'),
]

# Медиафайлы
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)