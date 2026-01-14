from django.db import models

class User(models.Model):
    user_id = models.AutoField(primary_key=True)
    email = models.EmailField(unique=True, max_length=255)
    password_hash = models.CharField(max_length=255)
    full_name = models.CharField(max_length=255)
    phone = models.CharField(max_length=20, blank=True, null=True)
    birth_date = models.DateField()
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        managed = False
        db_table = 'users'

class Hall(models.Model):
    hall_id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=100)
    capacity = models.IntegerField()
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        managed = False
        db_table = 'halls'

class Genre(models.Model):
    genre_id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'genres'

class Movie(models.Model):
    movie_id = models.AutoField(primary_key=True)
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    director = models.CharField(max_length=255, blank=True, null=True)
    duration_minutes = models.IntegerField()
    age_rating = models.CharField(max_length=10)
    release_date = models.DateField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    genres = models.ManyToManyField(
        Genre,
        through='MovieGenre',
        related_name='movies'
    )
    poster_url = models.ImageField(upload_to='posters/', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'movies'

class Session(models.Model):
    session_id = models.AutoField(primary_key=True)
    # ✅ ИСПРАВЛЕНО: on_delete=models.CASCADE (было DO_NOTHING)
    movie = models.ForeignKey(Movie, on_delete=models.CASCADE, db_column='movie_id')
    # ✅ ИСПРАВЛЕНО: on_delete=models.CASCADE
    hall = models.ForeignKey(Hall, on_delete=models.CASCADE, db_column='hall_id')
    session_datetime = models.DateTimeField()
    end_datetime = models.DateTimeField()
    available_seats = models.IntegerField()
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    price = models.DecimalField(max_digits=10, decimal_places=2, null=False, blank=True)

    class Meta:
        managed = False
        db_table = 'sessions'

class MovieGenre(models.Model):
    id = models.AutoField(primary_key=True)
    movie = models.ForeignKey(Movie, on_delete=models.CASCADE, db_column='movie_id')
    genre = models.ForeignKey(Genre, on_delete=models.CASCADE, db_column='genre_id')

    class Meta:
        managed = False
        db_table = 'movie_genres'
        unique_together = (('movie', 'genre'),)

class Seat(models.Model):
    seat_id = models.AutoField(primary_key=True)
    hall = models.ForeignKey(Hall, on_delete=models.CASCADE, db_column='hall_id')
    row_number = models.CharField(max_length=1)
    seat_number = models.IntegerField()
    seat_type = models.CharField(max_length=20, default='standard')

    class Meta:
        managed = False
        db_table = 'seats'
        unique_together = (('hall', 'row_number', 'seat_number'),)

class SessionSeat(models.Model):
    session_seat_id = models.AutoField(primary_key=True)
    session = models.ForeignKey('Session', on_delete=models.CASCADE, db_column='session_id')
    seat = models.ForeignKey(Seat, on_delete=models.CASCADE, db_column='seat_id')
    status = models.CharField(max_length=20, default='free')
    reserved_at = models.DateTimeField(blank=True, null=True)
    sold_at = models.DateTimeField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        managed = False
        db_table = 'session_seats'
        unique_together = (('session', 'seat'),)

class Order(models.Model):
    order_id = models.AutoField(primary_key=True)
    user = models.ForeignKey(User, on_delete=models.RESTRICT, db_column='user_id')
    total_price = models.DecimalField(max_digits=10, decimal_places=2)
    order_status = models.CharField(max_length=20, default='completed')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        managed = False
        db_table = 'orders'

class Ticket(models.Model):
    ticket_id = models.AutoField(primary_key=True)
    order = models.ForeignKey(Order, on_delete=models.CASCADE, db_column='order_id')
    # ✅ ИСПРАВЛЕНО: on_delete=models.CASCADE (было RESTRICT)
    session = models.ForeignKey(Session, on_delete=models.CASCADE, db_column='session_id')
    seat = models.ForeignKey(Seat, on_delete=models.RESTRICT, db_column='seat_id')
    qr_code = models.CharField(max_length=500, unique=True, blank=True, null=True)
    ticket_status = models.CharField(max_length=20, default='valid')
    is_valid = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        managed = False
        db_table = 'tickets'

class Cancellation(models.Model):
    cancellation_id = models.AutoField(primary_key=True)
    ticket = models.OneToOneField(Ticket, on_delete=models.CASCADE, db_column='ticket_id')
    cancelled_at = models.DateTimeField(auto_now_add=True)
    reason = models.CharField(max_length=255, blank=True, null=True)
    refunded_points = models.IntegerField(default=0)

    class Meta:
        managed = False
        db_table = 'cancellations'

class UserPointsBalance(models.Model):
    balance_id = models.AutoField(primary_key=True)
    user = models.OneToOneField(User, on_delete=models.CASCADE, db_column='user_id')
    current_points = models.IntegerField(default=0)
    last_updated = models.DateTimeField(auto_now=True)

    class Meta:
        managed = False
        db_table = 'user_points_balance'

class PointsTransaction(models.Model):
    transaction_id = models.AutoField(primary_key=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, db_column='user_id')
    order = models.ForeignKey(Order, on_delete=models.SET_NULL, db_column='order_id', blank=True, null=True)
    points_amount = models.IntegerField()
    operation_type = models.CharField(max_length=20)
    expiry_date = models.DateField(blank=True, null=True)
    description = models.CharField(max_length=255, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        managed = False
        db_table = 'points_transactions'