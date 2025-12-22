import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nora_django.settings')
django.setup()

from cinema.models import User, Movie, Session

# получить все фильмы
movies = Movie.objects.all()[:3]
for m in movies:
    print(f"Фильм: {m.title}, рейтинг: {m.age_rating}")

# создать пользователя
u = User(
    email="test2@example.com",
    password_hash="fake_hash",
    full_name="Тест Пользователь",
    birth_date="1995-05-05"
)
u.save()
print("Тестовый пользователь создан!")