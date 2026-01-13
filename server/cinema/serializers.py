from rest_framework import serializers
from .models import Movie, Session, Ticket, Genre, Hall

class HallSerializer(serializers.ModelSerializer):  # НОВЫЙ СЕРИАЛИЗАТОР
    class Meta:
        model = Hall
        fields = ['hall_id', 'name', 'capacity']

class GenreSerializer(serializers.ModelSerializer):
    class Meta:
        model = Genre
        fields = ['genre_id', 'name', 'description']

class MovieSerializer(serializers.ModelSerializer):
    genres = GenreSerializer(many=True, read_only=True)  
    
    release_date = serializers.DateField(format="%Y-%m-%d", required=False)
    end_date = serializers.DateField(format="%Y-%m-%d", required=False)
    
    class Meta:
        model = Movie
        fields = ['movie_id', 'title', 'director', 'genres', 'description', 'age_rating', 'duration_minutes', 'release_date', 'end_date', 'poster_url']

    def get_poster_url(self, obj):
        if obj.poster_url:  
            request = self.context.get('request')
            return request.build_absolute_uri(obj.poster_url.url)
        return None

class SessionSerializer(serializers.ModelSerializer):
    movie = MovieSerializer(read_only=True)
    movie_id = serializers.PrimaryKeyRelatedField(
        write_only=True, 
        queryset=Movie.objects.all(),
        source='movie'
    )
    hall_id = serializers.PrimaryKeyRelatedField(
        write_only=True, 
        queryset=Hall.objects.all(),
        source='hall'
    )
    
    class Meta:
        model = Session
        fields = ['session_id', 'movie', 'movie_id', 'hall_id', 'session_datetime', 'end_datetime', 'available_seats', 'price']

class TicketSerializer(serializers.ModelSerializer):
    session = SessionSerializer(read_only=True)
    class Meta:
        model = Ticket
        fields = ['ticket_id', 'session', 'qr_code', 'ticket_status']