-- ============================================
-- ПРОЕКТ "НОРА" - СИСТЕМА УПРАВЛЕНИЯ КИНОТЕАТРОМ
-- Физическая модель БД (PostgreSQL)
-- ============================================
-- Версия: 1.0
-- Дата: 17 декабря 2025 г.
-- ============================================

-- ПОДГОТОВКА: ОЧИСТКА (Если БД уже существует)
-- DROP DATABASE IF EXISTS nora_db;

-- СОЗДАНИЕ БД
--CREATE DATABASE nora_db
--  ENCODING 'UTF8'
--  TEMPLATE template0
--  LC_COLLATE 'en_US.UTF-8'
--  LC_CTYPE 'en_US.UTF-8';

-- ПОДКЛЮЧЕНИЕ К БД
-- \c nora_db

-- ============================================
-- ТАБЛИЦА 1: ПОЛЬЗОВАТЕЛИ (USERS)
-- ============================================
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    birth_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT age_minimum CHECK (EXTRACT(YEAR FROM AGE(birth_date)) >= 0)
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_birth_date ON users(birth_date);
CREATE INDEX idx_users_is_active ON users(is_active);

COMMENT ON TABLE users IS 'Таблица зарегистрированных пользователей кинотеатра';
COMMENT ON COLUMN users.email IS 'Уникальный email для входа';
COMMENT ON COLUMN users.password_hash IS 'Хеш пароля (bcrypt)';
COMMENT ON COLUMN users.birth_date IS 'Дата рождения для проверки возраста';

-- ============================================
-- ТАБЛИЦА 2: ЖАНРЫ ФИЛЬМОВ (GENRES)
-- ============================================
CREATE TABLE genres (
    genre_id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT
);

CREATE INDEX idx_genres_name ON genres(name);

COMMENT ON TABLE genres IS 'Жанры фильмов (боевик, комедия и т.д.)';

-- ============================================
-- ТАБЛИЦА 3: ФИЛЬМЫ (MOVIES)
-- ============================================
CREATE TABLE movies (
    movie_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    director VARCHAR(255),
    duration_minutes INT NOT NULL,
    age_rating VARCHAR(10) NOT NULL,
    release_date DATE,
    end_date DATE,
    poster_url VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT duration_positive CHECK (duration_minutes > 0),
    CONSTRAINT valid_age_rating CHECK (age_rating IN ('0+', '6+', '12+', '16+', '18+')),
    CONSTRAINT end_date_after_release CHECK (end_date IS NULL OR release_date IS NULL OR end_date >= release_date)
);

CREATE INDEX idx_movies_is_active ON movies(is_active);
CREATE INDEX idx_movies_age_rating ON movies(age_rating);
CREATE INDEX idx_movies_title ON movies(title);
CREATE INDEX idx_movies_release_date ON movies(release_date);

COMMENT ON TABLE movies IS 'Информация о фильмах в прокате';
COMMENT ON COLUMN movies.age_rating IS 'Возрастное ограничение (0+, 6+, 12+, 16+, 18+)';
COMMENT ON COLUMN movies.duration_minutes IS 'Продолжительность фильма в минутах';

-- ============================================
-- ТАБЛИЦА 4: СВЯЗЬ ФИЛЬМ-ЖАНР (MOVIE_GENRES)
-- ============================================
CREATE TABLE movie_genres (
    movie_id INT NOT NULL,
    genre_id INT NOT NULL,
    
    PRIMARY KEY (movie_id, genre_id),
    FOREIGN KEY (movie_id) REFERENCES movies(movie_id) ON DELETE CASCADE,
    FOREIGN KEY (genre_id) REFERENCES genres(genre_id) ON DELETE CASCADE
);

CREATE INDEX idx_movie_genres_movie_id ON movie_genres(movie_id);
CREATE INDEX idx_movie_genres_genre_id ON movie_genres(genre_id);

COMMENT ON TABLE movie_genres IS 'Связь Many-to-Many между фильмами и жанрами';

-- ============================================
-- ТАБЛИЦА 5: ЗАЛЫ КИНОТЕАТРА (HALLS)
-- ============================================
CREATE TABLE halls (
    hall_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    capacity INT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT capacity_positive CHECK (capacity > 0),
    CONSTRAINT capacity_reasonable CHECK (capacity <= 100)
);

CREATE INDEX idx_halls_name ON halls(name);
CREATE INDEX idx_halls_is_active ON halls(is_active);

COMMENT ON TABLE halls IS 'Залы кинотеатра (максимум 5 залов)';
COMMENT ON COLUMN halls.capacity IS 'Количество мест в зале (обычно 50)';

-- ============================================
-- ТАБЛИЦА 6: МЕСТА В ЗАЛАХ (SEATS)
-- ============================================
CREATE TABLE seats (
    seat_id SERIAL PRIMARY KEY,
    hall_id INT NOT NULL,
    row_number CHAR(1) NOT NULL,
    seat_number INT NOT NULL,
    seat_type VARCHAR(20) DEFAULT 'standard',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (hall_id) REFERENCES halls(hall_id) ON DELETE CASCADE,
    UNIQUE (hall_id, row_number, seat_number),
    CONSTRAINT valid_row CHECK (row_number IN ('A', 'B', 'C', 'D', 'E')),
    CONSTRAINT valid_seat_number CHECK (seat_number >= 1 AND seat_number <= 10),
    CONSTRAINT valid_seat_type CHECK (seat_type IN ('standard', 'vip', 'disability'))
);

CREATE INDEX idx_seats_hall_id ON seats(hall_id);
CREATE INDEX idx_seats_row_number ON seats(row_number);

COMMENT ON TABLE seats IS 'Места в залах (ряд A-E, места 1-10)';
COMMENT ON COLUMN seats.row_number IS 'Ряд (A, B, C, D, E)';
COMMENT ON COLUMN seats.seat_number IS 'Номер места в ряду (1-10)';

-- ============================================
-- ТАБЛИЦА 7: СЕАНСЫ (SESSIONS)
-- ============================================
CREATE TABLE sessions (
    session_id SERIAL PRIMARY KEY,
    movie_id INT NOT NULL,
    hall_id INT NOT NULL,
    session_datetime TIMESTAMP NOT NULL,
    end_datetime TIMESTAMP NOT NULL,
    available_seats INT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (movie_id) REFERENCES movies(movie_id) ON DELETE RESTRICT,
    FOREIGN KEY (hall_id) REFERENCES halls(hall_id) ON DELETE RESTRICT,
    CONSTRAINT end_after_start CHECK (end_datetime > session_datetime),
    CONSTRAINT available_seats_positive CHECK (available_seats >= 0),
    CONSTRAINT session_datetime_future CHECK (session_datetime > CURRENT_TIMESTAMP)
);

CREATE INDEX idx_sessions_movie_id ON sessions(movie_id);
CREATE INDEX idx_sessions_hall_id ON sessions(hall_id);
CREATE INDEX idx_sessions_datetime ON sessions(session_datetime);
CREATE INDEX idx_sessions_is_active ON sessions(is_active);

COMMENT ON TABLE sessions IS 'Сеансы показа фильмов (обычно 2 раза в день)';
COMMENT ON COLUMN sessions.session_datetime IS 'Дата и время начала сеанса (18:00, 21:00)';
COMMENT ON COLUMN sessions.available_seats IS 'Количество свободных мест на момент создания';

-- ============================================
-- ТАБЛИЦА 8: СОСТОЯНИЕ МЕСТ НА СЕАНС (SESSION_SEATS)
-- ============================================
CREATE TABLE session_seats (
    session_seat_id SERIAL PRIMARY KEY,
    session_id INT NOT NULL,
    seat_id INT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'free',
    reserved_at TIMESTAMP,
    sold_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (session_id) REFERENCES sessions(session_id) ON DELETE CASCADE,
    FOREIGN KEY (seat_id) REFERENCES seats(seat_id) ON DELETE CASCADE,
    UNIQUE (session_id, seat_id),
    CONSTRAINT valid_status CHECK (status IN ('free', 'reserved', 'sold', 'cancelled'))
);

CREATE INDEX idx_session_seats_session_id ON session_seats(session_id);
CREATE INDEX idx_session_seats_seat_id ON session_seats(seat_id);
CREATE INDEX idx_session_seats_status ON session_seats(status);

COMMENT ON TABLE session_seats IS 'Состояние каждого места на конкретный сеанс';
COMMENT ON COLUMN session_seats.status IS 'Статус места: free (свободно), reserved (зарезервировано), sold (продано), cancelled (отменено)';

-- ============================================
-- ТАБЛИЦА 9: ЗАКАЗЫ (ORDERS)
-- ============================================
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    order_status VARCHAR(20) DEFAULT 'completed',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE RESTRICT,
    CONSTRAINT price_non_negative CHECK (total_price >= 0),
    CONSTRAINT valid_order_status CHECK (order_status IN ('pending', 'completed', 'cancelled'))
);

CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_order_status ON orders(order_status);
CREATE INDEX idx_orders_created_at ON orders(created_at);

COMMENT ON TABLE orders IS 'Заказы билетов (покупки)';
COMMENT ON COLUMN orders.total_price IS 'Общая сумма заказа (в рублях)';
COMMENT ON COLUMN orders.order_status IS 'Статус заказа';

-- ============================================
-- ТАБЛИЦА 10: БИЛЕТЫ (TICKETS)
-- ============================================
CREATE TABLE tickets (
    ticket_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    session_id INT NOT NULL,
    seat_id INT NOT NULL,
    qr_code VARCHAR(500) UNIQUE,
    ticket_status VARCHAR(20) DEFAULT 'valid',
    is_valid BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (session_id) REFERENCES sessions(session_id) ON DELETE RESTRICT,
    FOREIGN KEY (seat_id) REFERENCES seats(seat_id) ON DELETE RESTRICT,
    CONSTRAINT valid_ticket_status CHECK (ticket_status IN ('valid', 'used', 'cancelled'))
);

CREATE INDEX idx_tickets_order_id ON tickets(order_id);
CREATE INDEX idx_tickets_session_id ON tickets(session_id);
CREATE INDEX idx_tickets_seat_id ON tickets(seat_id);
CREATE INDEX idx_tickets_qr_code ON tickets(qr_code);
CREATE INDEX idx_tickets_ticket_status ON tickets(ticket_status);

COMMENT ON TABLE tickets IS 'Проданные билеты';
COMMENT ON COLUMN tickets.qr_code IS 'Уникальный QR-код для входа в кинотеатр';
COMMENT ON COLUMN tickets.ticket_status IS 'Статус билета: valid (действителен), used (использован), cancelled (отменен)';

-- ============================================
-- ТАБЛИЦА 11: ОТМЕНЫ БИЛЕТОВ (CANCELLATIONS)
-- ============================================
CREATE TABLE cancellations (
    cancellation_id SERIAL PRIMARY KEY,
    ticket_id INT NOT NULL UNIQUE,
    cancelled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reason VARCHAR(255),
    refunded_points INT DEFAULT 0,
    
    FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id) ON DELETE CASCADE,
    CONSTRAINT refunded_points_non_negative CHECK (refunded_points >= 0)
);

CREATE INDEX idx_cancellations_ticket_id ON cancellations(ticket_id);
CREATE INDEX idx_cancellations_cancelled_at ON cancellations(cancelled_at);

COMMENT ON TABLE cancellations IS 'История отмен билетов';
COMMENT ON COLUMN cancellations.reason IS 'Причина отмены';
COMMENT ON COLUMN cancellations.refunded_points IS 'Количество возвращённых баллов';

-- ============================================
-- ТАБЛИЦА 12: БАЛАНС БАЛЛОВ ПОЛЬЗОВАТЕЛЯ (USER_POINTS_BALANCE)
-- ============================================
CREATE TABLE user_points_balance (
    balance_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    current_points INT DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT points_non_negative CHECK (current_points >= 0)
);

CREATE INDEX idx_user_points_balance_user_id ON user_points_balance(user_id);

COMMENT ON TABLE user_points_balance IS 'Текущий баланс баллов для каждого пользователя';
COMMENT ON COLUMN user_points_balance.current_points IS 'Текущее количество баллов (10 баллов за 100 рублей)';

-- ============================================
-- ТАБЛИЦА 13: ИСТОРИЯ БАЛЛОВ (POINTS_TRANSACTIONS)
-- ============================================
CREATE TABLE points_transactions (
    transaction_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    order_id INT,
    points_amount INT NOT NULL,
    operation_type VARCHAR(20) NOT NULL,
    expiry_date DATE,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE SET NULL,
    CONSTRAINT valid_operation_type CHECK (operation_type IN ('earn', 'spend', 'expire', 'refund')),
    CONSTRAINT expiry_date_future CHECK (expiry_date IS NULL OR expiry_date > CURRENT_DATE)
);

CREATE INDEX idx_points_transactions_user_id ON points_transactions(user_id);
CREATE INDEX idx_points_transactions_order_id ON points_transactions(order_id);
CREATE INDEX idx_points_transactions_operation_type ON points_transactions(operation_type);
CREATE INDEX idx_points_transactions_created_at ON points_transactions(created_at);
CREATE INDEX idx_points_transactions_expiry_date ON points_transactions(expiry_date);

COMMENT ON TABLE points_transactions IS 'История всех операций с баллами';
COMMENT ON COLUMN points_transactions.operation_type IS 'Тип операции: earn (начисление), spend (трата), expire (сгорание), refund (возврат)';
COMMENT ON COLUMN points_transactions.expiry_date IS 'Дата истечения баллов (обычно +1 месяц от даты получения)';

-- ============================================
-- ПРЕДСТАВЛЕНИЯ (VIEWS) ДЛЯ АНАЛИТИКИ
-- ============================================

-- VIEW 1: ПОПУЛЯРНЫЕ ФИЛЬМЫ
CREATE VIEW view_popular_movies AS
SELECT 
    m.movie_id,
    m.title,
    m.director,
    m.age_rating,
    COUNT(DISTINCT t.ticket_id) as total_tickets_sold,
    COUNT(DISTINCT t.ticket_id) * 100.0 / 
        (SELECT COUNT(*) FROM tickets) as percentage,
    SUM(o.total_price)::DECIMAL(10, 2) as total_revenue,
    ROUND(AVG(o.total_price)::NUMERIC, 2)::DECIMAL(10, 2) as avg_price_per_ticket
FROM movies m
LEFT JOIN sessions s ON m.movie_id = s.movie_id
LEFT JOIN tickets t ON s.session_id = t.session_id AND t.ticket_status IN ('valid', 'used')
LEFT JOIN orders o ON t.order_id = o.order_id
WHERE m.is_active = TRUE
GROUP BY m.movie_id, m.title, m.director, m.age_rating
ORDER BY total_tickets_sold DESC;

COMMENT ON VIEW view_popular_movies IS 'Популярные фильмы (топ по количеству проданных билетов)';

-- VIEW 2: ЗАГРУЖЕННОСТЬ ЗАЛОВ
CREATE VIEW view_hall_occupancy AS
SELECT 
    h.hall_id,
    h.name,
    s.session_datetime,
    h.capacity,
    COUNT(CASE WHEN ss.status = 'sold' THEN 1 END) as sold_seats,
    COUNT(CASE WHEN ss.status = 'free' THEN 1 END) as free_seats,
    ROUND(
        COUNT(CASE WHEN ss.status = 'sold' THEN 1 END) * 100.0 / h.capacity, 
        2
    ) as occupancy_percentage,
    m.title as movie_title
FROM halls h
LEFT JOIN sessions s ON h.hall_id = s.hall_id
LEFT JOIN movies m ON s.movie_id = m.movie_id
LEFT JOIN session_seats ss ON s.session_id = ss.session_id
WHERE s.session_datetime > CURRENT_TIMESTAMP
GROUP BY h.hall_id, h.name, s.session_datetime, s.session_id, h.capacity, m.title
ORDER BY s.session_datetime ASC, h.hall_id ASC;

COMMENT ON VIEW view_hall_occupancy IS 'Загруженность залов (процент заполненности)';

-- VIEW 3: ДОХОД ПО ДНЯМ
CREATE VIEW view_daily_revenue AS
SELECT 
    CAST(o.created_at AS DATE) as sale_date,
    COUNT(DISTINCT o.order_id) as orders_count,
    COUNT(DISTINCT t.ticket_id) as tickets_sold,
    SUM(o.total_price)::DECIMAL(10, 2) as total_revenue,
    ROUND(AVG(o.total_price)::NUMERIC, 2)::DECIMAL(10, 2) as avg_order_value
FROM orders o
LEFT JOIN tickets t ON o.order_id = t.order_id
WHERE o.order_status = 'completed'
GROUP BY CAST(o.created_at AS DATE)
ORDER BY sale_date DESC;

COMMENT ON VIEW view_daily_revenue IS 'Финансовые показатели (доход по дням)';

-- VIEW 4: АКТИВНОСТЬ ПОЛЬЗОВАТЕЛЕЙ
CREATE VIEW view_user_activity AS
SELECT 
    u.user_id,
    u.full_name,
    u.email,
    COUNT(DISTINCT o.order_id) as total_purchases,
    COUNT(DISTINCT t.ticket_id) as total_tickets_bought,
    COUNT(DISTINCT c.cancellation_id) as tickets_cancelled,
    upb.current_points as current_points_balance,
    MAX(o.created_at)::DATE as last_purchase_date
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
LEFT JOIN tickets t ON o.order_id = t.order_id
LEFT JOIN cancellations c ON t.ticket_id = c.ticket_id
LEFT JOIN user_points_balance upb ON u.user_id = upb.user_id
WHERE u.is_active = TRUE
GROUP BY u.user_id, u.full_name, u.email, upb.current_points
ORDER BY total_purchases DESC;

COMMENT ON VIEW view_user_activity IS 'Активность пользователей (количество покупок, баллов и т.д.)';

-- VIEW 5: ВОЗВРАЩАЕМОСТЬ БИЛЕТОВ
CREATE VIEW view_cancellation_stats AS
SELECT 
    CAST(c.cancelled_at AS DATE) as cancellation_date,
    COUNT(DISTINCT c.cancellation_id) as total_cancellations,
    COUNT(DISTINCT c.ticket_id) as cancelled_tickets,
    SUM(c.refunded_points) as total_refunded_points
FROM cancellations c
GROUP BY CAST(c.cancelled_at AS DATE)
ORDER BY cancellation_date DESC;

COMMENT ON VIEW view_cancellation_stats IS 'Статистика отмен билетов';

-- ============================================
-- ТРИГГЕРЫ
-- ============================================

-- ТРИГГЕР 1: Автоматическое обновление updated_at в users
CREATE OR REPLACE FUNCTION update_users_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_users_timestamp();

COMMENT ON TRIGGER trigger_users_updated_at ON users IS 'Автоматически обновляет updated_at при изменении пользователя';

-- ТРИГГЕР 2: Автоматическое обновление updated_at в movies
CREATE OR REPLACE FUNCTION update_movies_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_movies_updated_at
BEFORE UPDATE ON movies
FOR EACH ROW
EXECUTE FUNCTION update_movies_timestamp();

-- ТРИГГЕР 3: Автоматическое обновление updated_at в sessions
CREATE OR REPLACE FUNCTION update_sessions_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_sessions_updated_at
BEFORE UPDATE ON sessions
FOR EACH ROW
EXECUTE FUNCTION update_sessions_timestamp();

-- ТРИГГЕР 4: Автоматическое обновление updated_at в session_seats
CREATE OR REPLACE FUNCTION update_session_seats_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_session_seats_updated_at
BEFORE UPDATE ON session_seats
FOR EACH ROW
EXECUTE FUNCTION update_session_seats_timestamp();

-- ТРИГГЕР 5: Обновление последнего обновления баланса баллов
CREATE OR REPLACE FUNCTION update_points_balance_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_points_balance_timestamp
BEFORE UPDATE ON user_points_balance
FOR EACH ROW
EXECUTE FUNCTION update_points_balance_timestamp();

-- ============================================
-- ФУНКЦИИ (FUNCTIONS)
-- ============================================

-- ФУНКЦИЯ 1: Расчет возраста пользователя
CREATE OR REPLACE FUNCTION calculate_user_age(birth_date DATE)
RETURNS INT AS $$
BEGIN
    RETURN EXTRACT(YEAR FROM AGE(birth_date));
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_user_age(DATE) IS 'Расчитывает возраст пользователя по дате рождения';

-- ФУНКЦИЯ 2: Проверка возможности покупки билета (по возрасту)
CREATE OR REPLACE FUNCTION can_buy_ticket(user_id INT, movie_age_rating VARCHAR)
RETURNS BOOLEAN AS $$
DECLARE
    user_age INT;
    required_age INT;
BEGIN
    -- Получаем возраст пользователя
    SELECT calculate_user_age(u.birth_date) INTO user_age
    FROM users u
    WHERE u.user_id = $1;
    
    -- Определяем требуемый возраст по рейтингу
    required_age := CASE 
        WHEN movie_age_rating = '0+' THEN 0
        WHEN movie_age_rating = '6+' THEN 6
        WHEN movie_age_rating = '12+' THEN 12
        WHEN movie_age_rating = '16+' THEN 16
        WHEN movie_age_rating = '18+' THEN 18
        ELSE 0
    END;
    
    RETURN user_age >= required_age;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION can_buy_ticket(INT, VARCHAR) IS 'Проверяет, может ли пользователь купить билет на фильм с указанным рейтингом';

-- ФУНКЦИЯ 3: Получение доступных мест на сеанс
CREATE OR REPLACE FUNCTION get_available_seats_for_session(session_id INT)
RETURNS INT AS $$
DECLARE
    available_count INT;
BEGIN
    SELECT COUNT(*) INTO available_count
    FROM session_seats
    WHERE session_seats.session_id = $1 AND status = 'free';
    
    RETURN COALESCE(available_count, 0);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_available_seats_for_session(INT) IS 'Возвращает количество свободных мест на сеанс';

-- ФУНКЦИЯ 4: Расчет баллов за билет
CREATE OR REPLACE FUNCTION calculate_points_from_price(price DECIMAL)
RETURNS INT AS $$
BEGIN
    RETURN FLOOR(price / 100 * 10)::INT;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_points_from_price(DECIMAL) IS 'Расчитывает количество баллов (10 баллов за 100 рублей)';

-- ФУНКЦИЯ 5: Проверка возможности отмены билета (за 30 минут до начала)
CREATE OR REPLACE FUNCTION can_cancel_ticket(ticket_id INT)
RETURNS BOOLEAN AS $$
DECLARE
    session_start TIMESTAMP;
BEGIN
    SELECT s.session_datetime INTO session_start
    FROM tickets t
    JOIN sessions s ON t.session_id = s.session_id
    WHERE t.ticket_id = $1;
    
    -- Можно отменить если до начала больше 30 минут
    RETURN (session_start - CURRENT_TIMESTAMP) > INTERVAL '30 minutes';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION can_cancel_ticket(INT) IS 'Проверяет, может ли быть отменен билет (за 30 минут до начала)';

-- ============================================
-- ПОСЛЕДОВАТЕЛЬНОСТИ (SEQUENCES) - Для резервного копирования
-- ============================================

-- Проверка статуса всех SERIAL ID (они создаются автоматически)
-- SELECT * FROM information_schema.sequences WHERE sequence_schema = 'public';

-- ============================================
-- ФИНАЛЬНЫЕ КОММЕНТАРИИ К СХЕМЕ
-- ============================================

COMMENT ON SCHEMA public IS 'Схема для проекта "НОРА" - система управления кинотеатром';

-- ============================================
-- ИНФОРМАЦИЯ О ВЕРСИИ БД
-- ============================================
-- Создано: 17 декабря 2025 г.
-- СУБД: PostgreSQL 12+
-- Кодировка: UTF-8
-- Таблиц: 13
-- Представлений: 5
-- Функций: 5
-- Триггеров: 5
-- ============================================

-- Конец скрипта