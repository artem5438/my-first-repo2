from django.contrib import admin
from .models import (
    User, Movie, Hall, Session, Ticket, Genre, MovieGenre, Seat,
    SessionSeat, Order, Cancellation, UserPointsBalance, PointsTransaction
)

@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ('user_id', 'full_name', 'email', 'is_active')
    search_fields = ('full_name', 'email')

@admin.register(Movie)
class MovieAdmin(admin.ModelAdmin):
    list_display = ('title', 'director', 'age_rating', 'is_active')
    list_filter = ('age_rating', 'is_active')

@admin.register(Hall)
class HallAdmin(admin.ModelAdmin):
    list_display = ('name', 'capacity', 'is_active')

@admin.register(Session)
class SessionAdmin(admin.ModelAdmin):
    list_display = ('movie', 'hall', 'session_datetime')
    list_filter = ('hall',)

@admin.register(Ticket)
class TicketAdmin(admin.ModelAdmin):
    list_display = ('ticket_id', 'session', 'ticket_status')
    list_filter = ('ticket_status',)

@admin.register(Genre)
class GenreAdmin(admin.ModelAdmin):
    list_display = ('genre_id', 'name', 'description')

admin.site.register([ #Временное решение для отображения на админ-панели ВСЕХ данных из оставшихся таблиц (без исключений, фильтров и т.д.) 
    MovieGenre, Seat, SessionSeat, Order, Cancellation, UserPointsBalance, PointsTransaction #ОШИБКА С MovieGenre!!!!!
])