from rest_framework import serializers
from .models import Movie, Session, Ticket

class MovieSerializer(serializers.ModelSerializer):
    class Meta:
        model = Movie
        fields = ['movie_id', 'title', 'description', 'age_rating', 'duration_minutes']

class SessionSerializer(serializers.ModelSerializer):
    movie = MovieSerializer(read_only=True)
    class Meta:
        model = Session
        fields = ['session_id', 'movie', 'session_datetime', 'hall_id']

class TicketSerializer(serializers.ModelSerializer):
    session = SessionSerializer(read_only=True)
    class Meta:
        model = Ticket
        fields = ['ticket_id', 'session', 'qr_code', 'ticket_status']