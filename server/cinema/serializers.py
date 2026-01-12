from rest_framework import serializers
from .models import Movie, Session, Ticket, Genre

class GenreSerializer(serializers.ModelSerializer):
    class Meta:
        model = Genre
        fields = ['genre_id', 'name', 'description']

class MovieSerializer(serializers.ModelSerializer):
    genres = GenreSerializer(many=True, read_only=True)  
    poster_url = serializers.SerializerMethodField()

    class Meta:
        model = Movie
        fields = ['movie_id', 'title', 'director', 'genres', 'description', 'age_rating', 'duration_minutes', 'poster_url' ]

    def get_poster_url(self, obj):
        if obj.poster_url:  
            request = self.context.get('request')
            return request.build_absolute_uri(obj.poster_url.url)
        return None

class SessionSerializer(serializers.ModelSerializer):
    movie = MovieSerializer(read_only=True)
    class Meta:
        model = Session
        fields = ['session_id', 'movie', 'session_datetime', 'hall_id', 'available_seats', 'price']

class TicketSerializer(serializers.ModelSerializer):
    session = SessionSerializer(read_only=True)
    class Meta:
        model = Ticket
        fields = ['ticket_id', 'session', 'qr_code', 'ticket_status']