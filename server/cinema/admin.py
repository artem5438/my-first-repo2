from django.contrib import admin
from .models import (
    User, Movie, Hall, Session, Ticket, Genre, Seat, MovieGenre,
    SessionSeat, Order, Cancellation, UserPointsBalance, PointsTransaction
)

@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ('user_id', 'full_name', 'email', 'is_active')
    search_fields = ('full_name', 'email')

class MovieGenreInline(admin.TabularInline):
    model = MovieGenre
    extra = 1

@admin.register(Movie)
class MovieAdmin(admin.ModelAdmin):
    list_display = ('title', 'director', 'age_rating', 'is_active')
    list_filter = ('age_rating', 'is_active')
    inlines = [MovieGenreInline]

@admin.register(Hall)
class HallAdmin(admin.ModelAdmin):
    list_display = ('name', 'capacity', 'is_active')

@admin.register(Session)
class SessionAdmin(admin.ModelAdmin):
    list_display = ('movie', 'hall', 'session_datetime', 'price')
    list_filter = ('hall',)

@admin.register(Ticket)
class TicketAdmin(admin.ModelAdmin):
    list_display = ('ticket_id', 'session', 'ticket_status', 'is_valid')
    list_filter = ('ticket_status', 'is_valid')

@admin.register(Genre)
class GenreAdmin(admin.ModelAdmin):
    list_display = ('genre_id', 'name', 'description')

@admin.register(Seat)
class SeatAdmin(admin.ModelAdmin):
    list_display = ('seat_id', 'hall', 'row_number', 'seat_number')
    list_filter = ('row_number', 'hall')

@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
     list_display = ('order_id', 'order_status', 'total_price')
     list_filter = ('order_status', 'total_price')

admin.site.register([ #Временное решение для отображения на админ-панели ВСЕХ данных из оставшихся таблиц (без исключений, фильтров и т.д.) 
    SessionSeat, Cancellation, UserPointsBalance, PointsTransaction 
])