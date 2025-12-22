from django.contrib import admin
from django.urls import path
from cinema.views import MovieListView, SessionListView, TicketListView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/movies/', MovieListView.as_view()),
    path('api/sessions/', SessionListView.as_view()),
    path('api/tickets/', TicketListView.as_view()),
]