from rest_framework import generics
from .models import Movie, Session, Ticket
from .serializers import MovieSerializer, SessionSerializer, TicketSerializer

class MovieListView(generics.ListAPIView):
    queryset = Movie.objects.filter(is_active=True)
    serializer_class = MovieSerializer

class SessionListView(generics.ListAPIView):
    queryset = Session.objects.filter(is_active=True)
    serializer_class = SessionSerializer

class TicketListView(generics.ListAPIView):
    queryset = Ticket.objects.filter(ticket_status='valid')
    serializer_class = TicketSerializer