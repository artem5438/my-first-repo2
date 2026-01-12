--
-- PostgreSQL database dump
--

\restrict jtVtRazTHEQSyvlZUk1RtQvxXiYlgSMGDixbdAyWtTSKZ7Nn9j2M1t18kbEmXph

-- Dumped from database version 18.1 (Debian 18.1-1.pgdg13+2)
-- Dumped by pg_dump version 18.1 (Debian 18.1-1.pgdg13+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'Схема для проекта "НОРА" - система управления кинотеатром';


--
-- Name: calculate_points_from_price(numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_points_from_price(price numeric) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN FLOOR(price / 100 * 10)::INT;
END;
$$;


--
-- Name: FUNCTION calculate_points_from_price(price numeric); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.calculate_points_from_price(price numeric) IS 'Расчитывает количество баллов (10 баллов за 100 рублей)';


--
-- Name: calculate_user_age(date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_user_age(birth_date date) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN EXTRACT(YEAR FROM AGE(birth_date));
END;
$$;


--
-- Name: FUNCTION calculate_user_age(birth_date date); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.calculate_user_age(birth_date date) IS 'Расчитывает возраст пользователя по дате рождения';


--
-- Name: can_buy_ticket(integer, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.can_buy_ticket(user_id integer, movie_age_rating character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
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
$_$;


--
-- Name: FUNCTION can_buy_ticket(user_id integer, movie_age_rating character varying); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.can_buy_ticket(user_id integer, movie_age_rating character varying) IS 'Проверяет, может ли пользователь купить билет на фильм с указанным рейтингом';


--
-- Name: can_cancel_ticket(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.can_cancel_ticket(ticket_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
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
$_$;


--
-- Name: FUNCTION can_cancel_ticket(ticket_id integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.can_cancel_ticket(ticket_id integer) IS 'Проверяет, может ли быть отменен билет (за 30 минут до начала)';


--
-- Name: get_available_seats_for_session(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_available_seats_for_session(session_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE
    available_count INT;
BEGIN
    SELECT COUNT(*) INTO available_count
    FROM session_seats
    WHERE session_seats.session_id = $1 AND status = 'free';
    
    RETURN COALESCE(available_count, 0);
END;
$_$;


--
-- Name: FUNCTION get_available_seats_for_session(session_id integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.get_available_seats_for_session(session_id integer) IS 'Возвращает количество свободных мест на сеанс';


--
-- Name: update_movies_timestamp(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_movies_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


--
-- Name: update_points_balance_timestamp(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_points_balance_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.last_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


--
-- Name: update_session_seats_timestamp(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_session_seats_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


--
-- Name: update_sessions_timestamp(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_sessions_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


--
-- Name: update_users_timestamp(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_users_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: auth_group; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_group (
    id integer NOT NULL,
    name character varying(150) NOT NULL
);


--
-- Name: auth_group_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.auth_group ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: auth_group_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_group_permissions (
    id bigint NOT NULL,
    group_id integer NOT NULL,
    permission_id integer NOT NULL
);


--
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.auth_group_permissions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_group_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: auth_permission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_permission (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    content_type_id integer NOT NULL,
    codename character varying(100) NOT NULL
);


--
-- Name: auth_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.auth_permission ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_permission_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: auth_user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_user (
    id integer NOT NULL,
    password character varying(128) NOT NULL,
    last_login timestamp with time zone,
    is_superuser boolean NOT NULL,
    username character varying(150) NOT NULL,
    first_name character varying(150) NOT NULL,
    last_name character varying(150) NOT NULL,
    email character varying(254) NOT NULL,
    is_staff boolean NOT NULL,
    is_active boolean NOT NULL,
    date_joined timestamp with time zone NOT NULL
);


--
-- Name: auth_user_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_user_groups (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    group_id integer NOT NULL
);


--
-- Name: auth_user_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.auth_user_groups ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_user_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: auth_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.auth_user ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: auth_user_user_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_user_user_permissions (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    permission_id integer NOT NULL
);


--
-- Name: auth_user_user_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.auth_user_user_permissions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_user_user_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: cancellations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cancellations (
    cancellation_id integer NOT NULL,
    ticket_id integer NOT NULL,
    cancelled_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    reason character varying(255),
    refunded_points integer DEFAULT 0,
    CONSTRAINT refunded_points_non_negative CHECK ((refunded_points >= 0))
);


--
-- Name: TABLE cancellations; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.cancellations IS 'История отмен билетов';


--
-- Name: COLUMN cancellations.reason; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.cancellations.reason IS 'Причина отмены';


--
-- Name: COLUMN cancellations.refunded_points; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.cancellations.refunded_points IS 'Количество возвращённых баллов';


--
-- Name: cancellations_cancellation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cancellations_cancellation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cancellations_cancellation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cancellations_cancellation_id_seq OWNED BY public.cancellations.cancellation_id;


--
-- Name: django_admin_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.django_admin_log (
    id integer NOT NULL,
    action_time timestamp with time zone NOT NULL,
    object_id text,
    object_repr character varying(200) NOT NULL,
    action_flag smallint NOT NULL,
    change_message text NOT NULL,
    content_type_id integer,
    user_id integer NOT NULL,
    CONSTRAINT django_admin_log_action_flag_check CHECK ((action_flag >= 0))
);


--
-- Name: django_admin_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.django_admin_log ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_admin_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: django_content_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.django_content_type (
    id integer NOT NULL,
    app_label character varying(100) NOT NULL,
    model character varying(100) NOT NULL
);


--
-- Name: django_content_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.django_content_type ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_content_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: django_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.django_migrations (
    id bigint NOT NULL,
    app character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    applied timestamp with time zone NOT NULL
);


--
-- Name: django_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.django_migrations ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: django_session; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.django_session (
    session_key character varying(40) NOT NULL,
    session_data text NOT NULL,
    expire_date timestamp with time zone NOT NULL
);


--
-- Name: genres; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.genres (
    genre_id integer NOT NULL,
    name character varying(100) NOT NULL,
    description text
);


--
-- Name: TABLE genres; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.genres IS 'Жанры фильмов (боевик, комедия и т.д.)';


--
-- Name: genres_genre_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.genres_genre_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: genres_genre_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.genres_genre_id_seq OWNED BY public.genres.genre_id;


--
-- Name: halls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.halls (
    hall_id integer NOT NULL,
    name character varying(100) NOT NULL,
    capacity integer NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT capacity_positive CHECK ((capacity > 0)),
    CONSTRAINT capacity_reasonable CHECK ((capacity <= 100))
);


--
-- Name: TABLE halls; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.halls IS 'Залы кинотеатра (максимум 5 залов)';


--
-- Name: COLUMN halls.capacity; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.halls.capacity IS 'Количество мест в зале (обычно 50)';


--
-- Name: halls_hall_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.halls_hall_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: halls_hall_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.halls_hall_id_seq OWNED BY public.halls.hall_id;


--
-- Name: movie_genres; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.movie_genres (
    id integer NOT NULL,
    movie_id integer NOT NULL,
    genre_id integer NOT NULL
);


--
-- Name: TABLE movie_genres; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.movie_genres IS 'Связь Many-to-Many между фильмами и жанрами';


--
-- Name: movie_genres_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.movie_genres_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: movie_genres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.movie_genres_id_seq OWNED BY public.movie_genres.id;


--
-- Name: movies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.movies (
    movie_id integer NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    director character varying(255),
    duration_minutes integer NOT NULL,
    age_rating character varying(10) NOT NULL,
    release_date date,
    end_date date,
    poster_url character varying(500),
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT duration_positive CHECK ((duration_minutes > 0)),
    CONSTRAINT end_date_after_release CHECK (((end_date IS NULL) OR (release_date IS NULL) OR (end_date >= release_date))),
    CONSTRAINT valid_age_rating CHECK (((age_rating)::text = ANY ((ARRAY['0+'::character varying, '6+'::character varying, '12+'::character varying, '16+'::character varying, '18+'::character varying])::text[])))
);


--
-- Name: TABLE movies; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.movies IS 'Информация о фильмах в прокате';


--
-- Name: COLUMN movies.duration_minutes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.movies.duration_minutes IS 'Продолжительность фильма в минутах';


--
-- Name: COLUMN movies.age_rating; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.movies.age_rating IS 'Возрастное ограничение (0+, 6+, 12+, 16+, 18+)';


--
-- Name: movies_movie_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.movies_movie_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: movies_movie_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.movies_movie_id_seq OWNED BY public.movies.movie_id;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders (
    order_id integer NOT NULL,
    user_id integer NOT NULL,
    total_price numeric(10,2) NOT NULL,
    order_status character varying(20) DEFAULT 'completed'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT price_non_negative CHECK ((total_price >= (0)::numeric)),
    CONSTRAINT valid_order_status CHECK (((order_status)::text = ANY ((ARRAY['pending'::character varying, 'completed'::character varying, 'cancelled'::character varying])::text[])))
);


--
-- Name: TABLE orders; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.orders IS 'Заказы билетов (покупки)';


--
-- Name: COLUMN orders.total_price; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.orders.total_price IS 'Общая сумма заказа (в рублях)';


--
-- Name: COLUMN orders.order_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.orders.order_status IS 'Статус заказа';


--
-- Name: orders_order_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.orders_order_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: orders_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.orders_order_id_seq OWNED BY public.orders.order_id;


--
-- Name: points_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_transactions (
    transaction_id integer NOT NULL,
    user_id integer NOT NULL,
    order_id integer,
    points_amount integer NOT NULL,
    operation_type character varying(20) NOT NULL,
    expiry_date date,
    description character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT expiry_date_future CHECK (((expiry_date IS NULL) OR (expiry_date > CURRENT_DATE))),
    CONSTRAINT valid_operation_type CHECK (((operation_type)::text = ANY ((ARRAY['earn'::character varying, 'spend'::character varying, 'expire'::character varying, 'refund'::character varying])::text[])))
);


--
-- Name: TABLE points_transactions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.points_transactions IS 'История всех операций с баллами';


--
-- Name: COLUMN points_transactions.operation_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.points_transactions.operation_type IS 'Тип операции: earn (начисление), spend (трата), expire (сгорание), refund (возврат)';


--
-- Name: COLUMN points_transactions.expiry_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.points_transactions.expiry_date IS 'Дата истечения баллов (обычно +1 месяц от даты получения)';


--
-- Name: points_transactions_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_transactions_transaction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_transactions_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_transactions_transaction_id_seq OWNED BY public.points_transactions.transaction_id;


--
-- Name: seats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.seats (
    seat_id integer NOT NULL,
    hall_id integer NOT NULL,
    row_number character(1) NOT NULL,
    seat_number integer NOT NULL,
    seat_type character varying(20) DEFAULT 'standard'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_row CHECK ((row_number = ANY (ARRAY['A'::bpchar, 'B'::bpchar, 'C'::bpchar, 'D'::bpchar, 'E'::bpchar]))),
    CONSTRAINT valid_seat_number CHECK (((seat_number >= 1) AND (seat_number <= 10))),
    CONSTRAINT valid_seat_type CHECK (((seat_type)::text = ANY ((ARRAY['standard'::character varying, 'vip'::character varying, 'disability'::character varying])::text[])))
);


--
-- Name: TABLE seats; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.seats IS 'Места в залах (ряд A-E, места 1-10)';


--
-- Name: COLUMN seats.row_number; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.seats.row_number IS 'Ряд (A, B, C, D, E)';


--
-- Name: COLUMN seats.seat_number; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.seats.seat_number IS 'Номер места в ряду (1-10)';


--
-- Name: seats_seat_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.seats_seat_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: seats_seat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.seats_seat_id_seq OWNED BY public.seats.seat_id;


--
-- Name: session_seats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.session_seats (
    session_seat_id integer NOT NULL,
    session_id integer NOT NULL,
    seat_id integer NOT NULL,
    status character varying(20) DEFAULT 'free'::character varying NOT NULL,
    reserved_at timestamp without time zone,
    sold_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_status CHECK (((status)::text = ANY ((ARRAY['free'::character varying, 'reserved'::character varying, 'sold'::character varying, 'cancelled'::character varying])::text[])))
);


--
-- Name: TABLE session_seats; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.session_seats IS 'Состояние каждого места на конкретный сеанс';


--
-- Name: COLUMN session_seats.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.session_seats.status IS 'Статус места: free (свободно), reserved (зарезервировано), sold (продано), cancelled (отменено)';


--
-- Name: session_seats_session_seat_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.session_seats_session_seat_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: session_seats_session_seat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.session_seats_session_seat_id_seq OWNED BY public.session_seats.session_seat_id;


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    session_id integer NOT NULL,
    movie_id integer NOT NULL,
    hall_id integer NOT NULL,
    session_datetime timestamp without time zone NOT NULL,
    end_datetime timestamp without time zone NOT NULL,
    available_seats integer NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    price numeric(10,2),
    CONSTRAINT available_seats_positive CHECK ((available_seats >= 0)),
    CONSTRAINT end_after_start CHECK ((end_datetime > session_datetime)),
    CONSTRAINT session_datetime_future CHECK ((session_datetime > CURRENT_TIMESTAMP))
);


--
-- Name: TABLE sessions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.sessions IS 'Сеансы показа фильмов (обычно 2 раза в день)';


--
-- Name: COLUMN sessions.session_datetime; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sessions.session_datetime IS 'Дата и время начала сеанса (18:00, 21:00)';


--
-- Name: COLUMN sessions.available_seats; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sessions.available_seats IS 'Количество свободных мест на момент создания';


--
-- Name: sessions_session_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sessions_session_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_session_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sessions_session_id_seq OWNED BY public.sessions.session_id;


--
-- Name: tickets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tickets (
    ticket_id integer NOT NULL,
    order_id integer NOT NULL,
    session_id integer NOT NULL,
    seat_id integer NOT NULL,
    qr_code character varying(500),
    ticket_status character varying(20) DEFAULT 'valid'::character varying,
    is_valid boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_ticket_status CHECK (((ticket_status)::text = ANY ((ARRAY['valid'::character varying, 'used'::character varying, 'cancelled'::character varying])::text[])))
);


--
-- Name: TABLE tickets; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.tickets IS 'Проданные билеты';


--
-- Name: COLUMN tickets.qr_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tickets.qr_code IS 'Уникальный QR-код для входа в кинотеатр';


--
-- Name: COLUMN tickets.ticket_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tickets.ticket_status IS 'Статус билета: valid (действителен), used (использован), cancelled (отменен)';


--
-- Name: tickets_ticket_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tickets_ticket_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tickets_ticket_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tickets_ticket_id_seq OWNED BY public.tickets.ticket_id;


--
-- Name: user_points_balance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_points_balance (
    balance_id integer NOT NULL,
    user_id integer NOT NULL,
    current_points integer DEFAULT 0,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT points_non_negative CHECK ((current_points >= 0))
);


--
-- Name: TABLE user_points_balance; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.user_points_balance IS 'Текущий баланс баллов для каждого пользователя';


--
-- Name: COLUMN user_points_balance.current_points; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.user_points_balance.current_points IS 'Текущее количество баллов (10 баллов за 100 рублей)';


--
-- Name: user_points_balance_balance_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_points_balance_balance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_points_balance_balance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_points_balance_balance_id_seq OWNED BY public.user_points_balance.balance_id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    user_id integer NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    full_name character varying(255) NOT NULL,
    phone character varying(20),
    birth_date date NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT age_minimum CHECK ((EXTRACT(year FROM age((birth_date)::timestamp with time zone)) >= (0)::numeric))
);


--
-- Name: TABLE users; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.users IS 'Таблица зарегистрированных пользователей кинотеатра';


--
-- Name: COLUMN users.email; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.email IS 'Уникальный email для входа';


--
-- Name: COLUMN users.password_hash; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.password_hash IS 'Хеш пароля (bcrypt)';


--
-- Name: COLUMN users.birth_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.birth_date IS 'Дата рождения для проверки возраста';


--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- Name: view_cancellation_stats; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.view_cancellation_stats AS
 SELECT (cancelled_at)::date AS cancellation_date,
    count(DISTINCT cancellation_id) AS total_cancellations,
    count(DISTINCT ticket_id) AS cancelled_tickets,
    sum(refunded_points) AS total_refunded_points
   FROM public.cancellations c
  GROUP BY ((cancelled_at)::date)
  ORDER BY ((cancelled_at)::date) DESC;


--
-- Name: VIEW view_cancellation_stats; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.view_cancellation_stats IS 'Статистика отмен билетов';


--
-- Name: view_daily_revenue; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.view_daily_revenue AS
 SELECT (o.created_at)::date AS sale_date,
    count(DISTINCT o.order_id) AS orders_count,
    count(DISTINCT t.ticket_id) AS tickets_sold,
    (sum(o.total_price))::numeric(10,2) AS total_revenue,
    (round(avg(o.total_price), 2))::numeric(10,2) AS avg_order_value
   FROM (public.orders o
     LEFT JOIN public.tickets t ON ((o.order_id = t.order_id)))
  WHERE ((o.order_status)::text = 'completed'::text)
  GROUP BY ((o.created_at)::date)
  ORDER BY ((o.created_at)::date) DESC;


--
-- Name: VIEW view_daily_revenue; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.view_daily_revenue IS 'Финансовые показатели (доход по дням)';


--
-- Name: view_hall_occupancy; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.view_hall_occupancy AS
 SELECT h.hall_id,
    h.name,
    s.session_datetime,
    h.capacity,
    count(
        CASE
            WHEN ((ss.status)::text = 'sold'::text) THEN 1
            ELSE NULL::integer
        END) AS sold_seats,
    count(
        CASE
            WHEN ((ss.status)::text = 'free'::text) THEN 1
            ELSE NULL::integer
        END) AS free_seats,
    round((((count(
        CASE
            WHEN ((ss.status)::text = 'sold'::text) THEN 1
            ELSE NULL::integer
        END))::numeric * 100.0) / (h.capacity)::numeric), 2) AS occupancy_percentage,
    m.title AS movie_title
   FROM (((public.halls h
     LEFT JOIN public.sessions s ON ((h.hall_id = s.hall_id)))
     LEFT JOIN public.movies m ON ((s.movie_id = m.movie_id)))
     LEFT JOIN public.session_seats ss ON ((s.session_id = ss.session_id)))
  WHERE (s.session_datetime > CURRENT_TIMESTAMP)
  GROUP BY h.hall_id, h.name, s.session_datetime, s.session_id, h.capacity, m.title
  ORDER BY s.session_datetime, h.hall_id;


--
-- Name: VIEW view_hall_occupancy; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.view_hall_occupancy IS 'Загруженность залов (процент заполненности)';


--
-- Name: view_popular_movies; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.view_popular_movies AS
 SELECT m.movie_id,
    m.title,
    m.director,
    m.age_rating,
    count(DISTINCT t.ticket_id) AS total_tickets_sold,
    (((count(DISTINCT t.ticket_id))::numeric * 100.0) / (( SELECT count(*) AS count
           FROM public.tickets))::numeric) AS percentage,
    (sum(o.total_price))::numeric(10,2) AS total_revenue,
    (round(avg(o.total_price), 2))::numeric(10,2) AS avg_price_per_ticket
   FROM (((public.movies m
     LEFT JOIN public.sessions s ON ((m.movie_id = s.movie_id)))
     LEFT JOIN public.tickets t ON (((s.session_id = t.session_id) AND ((t.ticket_status)::text = ANY ((ARRAY['valid'::character varying, 'used'::character varying])::text[])))))
     LEFT JOIN public.orders o ON ((t.order_id = o.order_id)))
  WHERE (m.is_active = true)
  GROUP BY m.movie_id, m.title, m.director, m.age_rating
  ORDER BY (count(DISTINCT t.ticket_id)) DESC;


--
-- Name: VIEW view_popular_movies; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.view_popular_movies IS 'Популярные фильмы (топ по количеству проданных билетов)';


--
-- Name: view_user_activity; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.view_user_activity AS
 SELECT u.user_id,
    u.full_name,
    u.email,
    count(DISTINCT o.order_id) AS total_purchases,
    count(DISTINCT t.ticket_id) AS total_tickets_bought,
    count(DISTINCT c.cancellation_id) AS tickets_cancelled,
    upb.current_points AS current_points_balance,
    (max(o.created_at))::date AS last_purchase_date
   FROM ((((public.users u
     LEFT JOIN public.orders o ON ((u.user_id = o.user_id)))
     LEFT JOIN public.tickets t ON ((o.order_id = t.order_id)))
     LEFT JOIN public.cancellations c ON ((t.ticket_id = c.ticket_id)))
     LEFT JOIN public.user_points_balance upb ON ((u.user_id = upb.user_id)))
  WHERE (u.is_active = true)
  GROUP BY u.user_id, u.full_name, u.email, upb.current_points
  ORDER BY (count(DISTINCT o.order_id)) DESC;


--
-- Name: VIEW view_user_activity; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.view_user_activity IS 'Активность пользователей (количество покупок, баллов и т.д.)';


--
-- Name: cancellations cancellation_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cancellations ALTER COLUMN cancellation_id SET DEFAULT nextval('public.cancellations_cancellation_id_seq'::regclass);


--
-- Name: genres genre_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genres ALTER COLUMN genre_id SET DEFAULT nextval('public.genres_genre_id_seq'::regclass);


--
-- Name: halls hall_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.halls ALTER COLUMN hall_id SET DEFAULT nextval('public.halls_hall_id_seq'::regclass);


--
-- Name: movie_genres id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movie_genres ALTER COLUMN id SET DEFAULT nextval('public.movie_genres_id_seq'::regclass);


--
-- Name: movies movie_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movies ALTER COLUMN movie_id SET DEFAULT nextval('public.movies_movie_id_seq'::regclass);


--
-- Name: orders order_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders ALTER COLUMN order_id SET DEFAULT nextval('public.orders_order_id_seq'::regclass);


--
-- Name: points_transactions transaction_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_transactions ALTER COLUMN transaction_id SET DEFAULT nextval('public.points_transactions_transaction_id_seq'::regclass);


--
-- Name: seats seat_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seats ALTER COLUMN seat_id SET DEFAULT nextval('public.seats_seat_id_seq'::regclass);


--
-- Name: session_seats session_seat_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_seats ALTER COLUMN session_seat_id SET DEFAULT nextval('public.session_seats_session_seat_id_seq'::regclass);


--
-- Name: sessions session_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions ALTER COLUMN session_id SET DEFAULT nextval('public.sessions_session_id_seq'::regclass);


--
-- Name: tickets ticket_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets ALTER COLUMN ticket_id SET DEFAULT nextval('public.tickets_ticket_id_seq'::regclass);


--
-- Name: user_points_balance balance_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_points_balance ALTER COLUMN balance_id SET DEFAULT nextval('public.user_points_balance_balance_id_seq'::regclass);


--
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- Data for Name: auth_group; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.auth_group (id, name) FROM stdin;
\.


--
-- Data for Name: auth_group_permissions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.auth_group_permissions (id, group_id, permission_id) FROM stdin;
\.


--
-- Data for Name: auth_permission; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.auth_permission (id, name, content_type_id, codename) FROM stdin;
1	Can add log entry	1	add_logentry
2	Can change log entry	1	change_logentry
3	Can delete log entry	1	delete_logentry
4	Can view log entry	1	view_logentry
5	Can add permission	3	add_permission
6	Can change permission	3	change_permission
7	Can delete permission	3	delete_permission
8	Can view permission	3	view_permission
9	Can add group	2	add_group
10	Can change group	2	change_group
11	Can delete group	2	delete_group
12	Can view group	2	view_group
13	Can add user	4	add_user
14	Can change user	4	change_user
15	Can delete user	4	delete_user
16	Can view user	4	view_user
17	Can add content type	5	add_contenttype
18	Can change content type	5	change_contenttype
19	Can delete content type	5	delete_contenttype
20	Can view content type	5	view_contenttype
21	Can add session	6	add_session
22	Can change session	6	change_session
23	Can delete session	6	delete_session
24	Can view session	6	view_session
25	Can add cancellation	7	add_cancellation
26	Can change cancellation	7	change_cancellation
27	Can delete cancellation	7	delete_cancellation
28	Can view cancellation	7	view_cancellation
29	Can add genre	8	add_genre
30	Can change genre	8	change_genre
31	Can delete genre	8	delete_genre
32	Can view genre	8	view_genre
33	Can add hall	9	add_hall
34	Can change hall	9	change_hall
35	Can delete hall	9	delete_hall
36	Can view hall	9	view_hall
37	Can add movie	10	add_movie
38	Can change movie	10	change_movie
39	Can delete movie	10	delete_movie
40	Can view movie	10	view_movie
41	Can add movie genre	11	add_moviegenre
42	Can change movie genre	11	change_moviegenre
43	Can delete movie genre	11	delete_moviegenre
44	Can view movie genre	11	view_moviegenre
45	Can add order	12	add_order
46	Can change order	12	change_order
47	Can delete order	12	delete_order
48	Can view order	12	view_order
49	Can add points transaction	13	add_pointstransaction
50	Can change points transaction	13	change_pointstransaction
51	Can delete points transaction	13	delete_pointstransaction
52	Can view points transaction	13	view_pointstransaction
53	Can add seat	14	add_seat
54	Can change seat	14	change_seat
55	Can delete seat	14	delete_seat
56	Can view seat	14	view_seat
57	Can add session	15	add_session
58	Can change session	15	change_session
59	Can delete session	15	delete_session
60	Can view session	15	view_session
61	Can add session seat	16	add_sessionseat
62	Can change session seat	16	change_sessionseat
63	Can delete session seat	16	delete_sessionseat
64	Can view session seat	16	view_sessionseat
65	Can add ticket	17	add_ticket
66	Can change ticket	17	change_ticket
67	Can delete ticket	17	delete_ticket
68	Can view ticket	17	view_ticket
69	Can add user	18	add_user
70	Can change user	18	change_user
71	Can delete user	18	delete_user
72	Can view user	18	view_user
73	Can add user points balance	19	add_userpointsbalance
74	Can change user points balance	19	change_userpointsbalance
75	Can delete user points balance	19	delete_userpointsbalance
76	Can view user points balance	19	view_userpointsbalance
\.


--
-- Data for Name: auth_user; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.auth_user (id, password, last_login, is_superuser, username, first_name, last_name, email, is_staff, is_active, date_joined) FROM stdin;
1	pbkdf2_sha256$1200000$qCsabY9Fzpav9QqcH5eYYC$nB2yG9KhlYueGHyy3BK/5iNq7ii8mvm8uafRZabVsoU=	2026-01-06 22:26:22.770819+00	t	root			ivanivanich220111@gmail.com	t	t	2025-12-22 19:20:37.805257+00
\.


--
-- Data for Name: auth_user_groups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.auth_user_groups (id, user_id, group_id) FROM stdin;
\.


--
-- Data for Name: auth_user_user_permissions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.auth_user_user_permissions (id, user_id, permission_id) FROM stdin;
\.


--
-- Data for Name: cancellations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.cancellations (cancellation_id, ticket_id, cancelled_at, reason, refunded_points) FROM stdin;
3	10	2026-01-08 17:27:48.875719	Пользователь отменил билет	10
4	12	2026-01-08 17:28:45.303138	Пользователь отменил билет	10
5	11	2026-01-08 17:30:00.510497	Пользователь отменил билет	0
6	13	2026-01-09 13:50:27.179483	Пользователь отменил билет	10
7	14	2026-01-09 17:05:40.915098	Пользователь отменил билет	50
8	15	2026-01-10 11:01:37.339988	Пользователь отменил билет	50
\.


--
-- Data for Name: django_admin_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.django_admin_log (id, action_time, object_id, object_repr, action_flag, change_message, content_type_id, user_id) FROM stdin;
1	2025-12-22 19:21:39.934742+00	1	Genre object (1)	1	[{"added": {}}]	8	1
2	2025-12-22 19:21:53.045809+00	2	Genre object (2)	1	[{"added": {}}]	8	1
3	2025-12-22 19:22:09.497029+00	3	Genre object (3)	1	[{"added": {}}]	8	1
4	2025-12-22 19:22:23.634995+00	4	Genre object (4)	1	[{"added": {}}]	8	1
5	2025-12-22 19:22:36.396618+00	5	Genre object (5)	1	[{"added": {}}]	8	1
6	2025-12-22 19:25:54.475502+00	1	Movie object (1)	1	[{"added": {}}, {"added": {"name": "movie genre", "object": "MovieGenre object (1)"}}]	10	1
7	2025-12-22 19:27:33.154156+00	2	Movie object (2)	1	[{"added": {}}, {"added": {"name": "movie genre", "object": "MovieGenre object (2)"}}]	10	1
8	2025-12-22 19:27:40.279085+00	1	Movie object (1)	2	[{"changed": {"fields": ["Description"]}}]	10	1
9	2025-12-22 19:28:42.764597+00	3	Movie object (3)	1	[{"added": {}}]	10	1
10	2025-12-22 19:29:44.623144+00	1	Hall object (1)	1	[{"added": {}}]	9	1
11	2025-12-22 19:30:31.553663+00	2	Hall object (2)	1	[{"added": {}}]	9	1
12	2025-12-22 19:32:46.671497+00	1	Seat object (1)	1	[{"added": {}}]	14	1
13	2025-12-22 19:32:56.600273+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
14	2025-12-22 19:32:58.181517+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
15	2025-12-22 19:32:59.456618+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
16	2025-12-22 19:33:00.755121+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
17	2025-12-22 19:33:01.934237+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
18	2025-12-22 19:33:03.229712+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
19	2025-12-22 19:33:04.550228+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
20	2025-12-22 19:33:05.933122+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
21	2025-12-22 19:33:08.482679+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
22	2025-12-22 19:33:13.114524+00	1	Seat object (1)	2	[{"changed": {"fields": ["Row number", "Seat number"]}}]	14	1
23	2025-12-22 19:33:14.296956+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
24	2025-12-22 19:33:15.445689+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
25	2025-12-22 19:33:16.623129+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
26	2025-12-22 19:33:17.759583+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
27	2025-12-22 19:33:18.851878+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
28	2025-12-22 19:33:19.981676+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
29	2025-12-22 19:33:21.066501+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
30	2025-12-22 19:33:22.235376+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
31	2025-12-22 19:33:24.298295+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
32	2025-12-22 19:33:26.844528+00	1	Seat object (1)	2	[{"changed": {"fields": ["Row number", "Seat number"]}}]	14	1
33	2025-12-22 19:33:27.976372+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
34	2025-12-22 19:33:28.989117+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
35	2025-12-22 19:33:30.251467+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
36	2025-12-22 19:33:31.725129+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
37	2025-12-22 19:33:32.827414+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
38	2025-12-22 19:33:33.970218+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
39	2025-12-22 19:33:35.129397+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
40	2025-12-22 19:33:36.307496+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
41	2025-12-22 19:33:38.327622+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
42	2025-12-22 19:33:42.513634+00	1	Seat object (1)	2	[{"changed": {"fields": ["Row number", "Seat number"]}}]	14	1
43	2025-12-22 19:33:43.701802+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
44	2025-12-22 19:33:44.931953+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
45	2025-12-22 19:33:46.222513+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
46	2025-12-22 19:33:47.303249+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
47	2025-12-22 19:33:48.482301+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
48	2025-12-22 19:33:49.619225+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
49	2025-12-22 19:33:50.766031+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
50	2025-12-22 19:33:52.954329+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
51	2025-12-22 19:33:55.375178+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
52	2025-12-22 19:34:05.278368+00	1	Seat object (1)	2	[{"changed": {"fields": ["Row number", "Seat number"]}}]	14	1
53	2025-12-22 19:34:06.376693+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
54	2025-12-22 19:34:07.584031+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
55	2025-12-22 19:34:08.682211+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
56	2025-12-22 19:34:09.675434+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
57	2025-12-22 19:34:10.809631+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
58	2025-12-22 19:34:12.263408+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
59	2025-12-22 19:34:13.421346+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
60	2025-12-22 19:34:14.709599+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
61	2025-12-22 19:34:16.599259+00	1	Seat object (1)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
62	2025-12-22 19:34:30.658518+00	1	Seat object (1)	2	[{"changed": {"fields": ["Row number", "Seat number"]}}]	14	1
63	2025-12-22 19:34:43.679355+00	2	Seat object (2)	1	[{"added": {}}]	14	1
64	2025-12-22 19:35:20.809084+00	3	Seat object (3)	1	[{"added": {}}]	14	1
65	2025-12-22 19:35:26.596223+00	4	Seat object (4)	1	[{"added": {}}]	14	1
66	2025-12-22 19:35:32.741327+00	5	Seat object (5)	1	[{"added": {}}]	14	1
67	2025-12-22 19:35:40.004944+00	6	Seat object (6)	1	[{"added": {}}]	14	1
68	2025-12-22 19:35:51.96079+00	7	Seat object (7)	1	[{"added": {}}]	14	1
69	2025-12-22 19:36:02.809127+00	8	Seat object (8)	1	[{"added": {}}]	14	1
70	2025-12-22 19:36:12.829886+00	9	Seat object (9)	1	[{"added": {}}]	14	1
71	2025-12-22 19:36:21.712701+00	10	Seat object (10)	1	[{"added": {}}]	14	1
72	2025-12-22 19:39:47.80967+00	11	Seat object (11)	1	[{"added": {}}]	14	1
73	2025-12-22 19:39:53.776838+00	12	Seat object (12)	1	[{"added": {}}]	14	1
74	2025-12-22 19:39:58.37963+00	13	Seat object (13)	1	[{"added": {}}]	14	1
75	2025-12-22 19:40:04.413478+00	14	Seat object (14)	1	[{"added": {}}]	14	1
76	2025-12-22 19:40:10.891429+00	15	Seat object (15)	1	[{"added": {}}]	14	1
77	2025-12-22 19:40:16.350684+00	16	Seat object (16)	1	[{"added": {}}]	14	1
78	2025-12-22 19:40:25.003981+00	17	Seat object (17)	1	[{"added": {}}]	14	1
79	2025-12-22 19:40:31.62825+00	18	Seat object (18)	1	[{"added": {}}]	14	1
80	2025-12-22 19:40:37.922841+00	19	Seat object (19)	1	[{"added": {}}]	14	1
81	2025-12-22 19:40:42.881181+00	20	Seat object (20)	1	[{"added": {}}]	14	1
82	2025-12-22 19:41:01.440114+00	21	Seat object (21)	1	[{"added": {}}]	14	1
83	2025-12-22 19:41:09.519997+00	22	Seat object (22)	1	[{"added": {}}]	14	1
84	2025-12-22 19:41:12.9678+00	23	Seat object (23)	1	[{"added": {}}]	14	1
85	2025-12-22 19:41:16.329454+00	24	Seat object (24)	1	[{"added": {}}]	14	1
86	2025-12-22 19:41:19.054403+00	25	Seat object (25)	1	[{"added": {}}]	14	1
87	2025-12-22 19:41:22.845259+00	26	Seat object (26)	1	[{"added": {}}]	14	1
88	2025-12-22 19:41:30.615568+00	27	Seat object (27)	1	[{"added": {}}]	14	1
89	2025-12-22 19:41:34.024701+00	28	Seat object (28)	1	[{"added": {}}]	14	1
90	2025-12-22 19:41:37.033812+00	29	Seat object (29)	1	[{"added": {}}]	14	1
91	2025-12-22 19:41:40.166346+00	30	Seat object (30)	1	[{"added": {}}]	14	1
92	2025-12-22 19:41:55.706589+00	31	Seat object (31)	1	[{"added": {}}]	14	1
93	2025-12-22 19:41:59.807928+00	32	Seat object (32)	1	[{"added": {}}]	14	1
94	2025-12-22 19:42:02.364077+00	33	Seat object (33)	1	[{"added": {}}]	14	1
95	2025-12-22 19:42:04.769127+00	34	Seat object (34)	1	[{"added": {}}]	14	1
96	2025-12-22 19:42:07.181687+00	35	Seat object (35)	1	[{"added": {}}]	14	1
97	2025-12-22 19:42:10.503073+00	36	Seat object (36)	1	[{"added": {}}]	14	1
98	2025-12-22 19:42:14.054267+00	37	Seat object (37)	1	[{"added": {}}]	14	1
99	2025-12-22 19:42:17.1948+00	38	Seat object (38)	1	[{"added": {}}]	14	1
100	2025-12-22 19:42:20.097647+00	39	Seat object (39)	1	[{"added": {}}]	14	1
101	2025-12-22 19:42:23.415178+00	40	Seat object (40)	1	[{"added": {}}]	14	1
102	2025-12-22 19:42:27.121292+00	41	Seat object (41)	1	[{"added": {}}]	14	1
103	2025-12-22 19:42:29.876053+00	42	Seat object (42)	1	[{"added": {}}]	14	1
104	2025-12-22 19:42:32.906493+00	43	Seat object (43)	1	[{"added": {}}]	14	1
105	2025-12-22 19:42:35.994352+00	44	Seat object (44)	1	[{"added": {}}]	14	1
106	2025-12-22 19:42:39.251492+00	45	Seat object (45)	1	[{"added": {}}]	14	1
107	2025-12-22 19:42:41.971186+00	46	Seat object (46)	1	[{"added": {}}]	14	1
108	2025-12-22 19:42:45.232482+00	47	Seat object (47)	1	[{"added": {}}]	14	1
109	2025-12-22 19:42:49.153511+00	48	Seat object (48)	1	[{"added": {}}]	14	1
110	2025-12-22 19:42:51.998893+00	49	Seat object (49)	1	[{"added": {}}]	14	1
111	2025-12-22 19:42:55.424541+00	50	Seat object (50)	1	[{"added": {}}]	14	1
112	2025-12-22 19:43:43.050869+00	2	Hall object (2)	2	[{"changed": {"fields": ["Capacity"]}}]	9	1
113	2025-12-22 19:43:45.963001+00	2	Hall object (2)	2	[]	9	1
114	2025-12-22 19:44:55.762473+00	52	Seat object (52)	1	[{"added": {}}]	14	1
115	2025-12-22 19:45:26.955931+00	53	Seat object (53)	1	[{"added": {}}]	14	1
116	2025-12-22 19:45:38.498182+00	54	Seat object (54)	1	[{"added": {}}]	14	1
117	2025-12-22 19:45:45.383033+00	55	Seat object (55)	1	[{"added": {}}]	14	1
118	2025-12-22 19:45:57.548309+00	56	Seat object (56)	1	[{"added": {}}]	14	1
119	2025-12-22 19:46:06.793402+00	57	Seat object (57)	1	[{"added": {}}]	14	1
120	2025-12-22 19:46:15.347799+00	58	Seat object (58)	1	[{"added": {}}]	14	1
121	2025-12-22 19:46:25.887563+00	59	Seat object (59)	1	[{"added": {}}]	14	1
122	2025-12-22 19:46:32.67442+00	60	Seat object (60)	1	[{"added": {}}]	14	1
123	2025-12-22 19:46:37.953325+00	61	Seat object (61)	1	[{"added": {}}]	14	1
124	2025-12-22 19:52:17.498169+00	1	Session object (1)	1	[{"added": {}}]	15	1
125	2025-12-24 18:09:05.574627+00	3	Movie object (3)	2	[{"changed": {"fields": ["Title"]}}]	10	1
126	2025-12-24 18:10:05.952615+00	3	Movie object (3)	2	[{"changed": {"fields": ["Title"]}}]	10	1
127	2026-01-05 09:26:43.067355+00	3	Movie object (3)	2	[{"added": {"name": "movie genre", "object": "MovieGenre object (3)"}}]	10	1
128	2026-01-05 09:26:57.318605+00	1	Genre object (1)	2	[]	8	1
129	2026-01-05 09:27:28.617018+00	2	Movie object (2)	2	[{"added": {"name": "movie genre", "object": "MovieGenre object (4)"}}]	10	1
130	2026-01-05 09:43:44.001886+00	2	Session object (2)	1	[{"added": {}}]	15	1
131	2026-01-06 22:35:53.168202+00	3	Movie object (3)	2	[{"changed": {"fields": ["Poster url"]}}]	10	1
132	2026-01-06 22:48:06.583767+00	1	Movie object (1)	2	[{"changed": {"fields": ["Poster url"]}}]	10	1
133	2026-01-08 16:36:20.579529+00	6	Genre object (6)	1	[{"added": {}}]	8	1
134	2026-01-08 16:37:31.922269+00	7	Genre object (7)	1	[{"added": {}}]	8	1
135	2026-01-08 16:37:39.031617+00	4	Movie object (4)	1	[{"added": {}}, {"added": {"name": "movie genre", "object": "MovieGenre object (5)"}}, {"added": {"name": "movie genre", "object": "MovieGenre object (6)"}}]	10	1
136	2026-01-08 16:43:59.976964+00	2	User object (2)	2	[{"changed": {"fields": ["Full name"]}}]	18	1
137	2026-01-08 16:46:38.825047+00	2	User object (2)	2	[{"changed": {"fields": ["Full name"]}}]	18	1
138	2026-01-08 16:50:14.0061+00	1	Session object (1)	2	[{"changed": {"fields": ["Session datetime", "End datetime"]}}]	15	1
139	2026-01-08 16:50:57.792691+00	2	Session object (2)	2	[{"changed": {"fields": ["Session datetime", "End datetime"]}}]	15	1
140	2026-01-08 16:57:01.585433+00	3	Ticket object (3)	3		17	1
141	2026-01-08 16:57:01.585467+00	2	Ticket object (2)	3		17	1
142	2026-01-08 16:57:01.585482+00	1	Ticket object (1)	3		17	1
143	2026-01-08 16:57:10.165475+00	8	Ticket object (8)	3		17	1
144	2026-01-08 16:57:10.165503+00	5	Ticket object (5)	3		17	1
145	2026-01-08 16:58:06.874037+00	8	SessionSeat object (8)	3		16	1
146	2026-01-08 16:58:06.874066+00	5	SessionSeat object (5)	3		16	1
147	2026-01-08 16:58:06.87408+00	3	SessionSeat object (3)	3		16	1
148	2026-01-08 16:58:06.874092+00	2	SessionSeat object (2)	3		16	1
149	2026-01-08 16:58:06.874104+00	1	SessionSeat object (1)	3		16	1
150	2026-01-08 16:58:36.020271+00	10	PointsTransaction object (10)	3		13	1
151	2026-01-08 16:58:36.020301+00	9	PointsTransaction object (9)	3		13	1
152	2026-01-08 16:58:36.020316+00	8	PointsTransaction object (8)	3		13	1
153	2026-01-08 16:58:36.020328+00	5	PointsTransaction object (5)	3		13	1
154	2026-01-08 16:58:36.020339+00	3	PointsTransaction object (3)	3		13	1
155	2026-01-08 16:58:36.020351+00	2	PointsTransaction object (2)	3		13	1
156	2026-01-08 16:58:36.020363+00	1	PointsTransaction object (1)	3		13	1
157	2026-01-08 16:58:46.240857+00	8	Order object (8)	3		12	1
158	2026-01-08 16:58:46.240888+00	5	Order object (5)	3		12	1
159	2026-01-08 16:58:46.240904+00	3	Order object (3)	3		12	1
160	2026-01-08 16:58:46.240917+00	2	Order object (2)	3		12	1
161	2026-01-08 16:58:46.240928+00	1	Order object (1)	3		12	1
162	2026-01-08 17:06:57.149503+00	1	Session object (1)	2	[{"changed": {"fields": ["Available seats"]}}]	15	1
163	2026-01-08 17:07:01.295293+00	2	Session object (2)	2	[{"changed": {"fields": ["Available seats"]}}]	15	1
164	2026-01-08 17:20:11.781728+00	9	Order object (9)	1	[{"added": {}}]	12	1
165	2026-01-08 17:20:53.882786+00	9	Ticket object (9)	1	[{"added": {}}]	17	1
166	2026-01-08 17:21:48.221571+00	9	Ticket object (9)	2	[{"changed": {"fields": ["Qr code"]}}]	17	1
167	2026-01-08 17:24:27.681561+00	9	Ticket object (9)	3		17	1
168	2026-01-08 17:29:15.192939+00	1	UserPointsBalance object (1)	2	[{"changed": {"fields": ["Current points"]}}]	19	1
169	2026-01-09 13:53:08.996721+00	62	Seat object (62)	1	[{"added": {}}]	14	1
170	2026-01-09 13:53:18.291794+00	62	Seat object (62)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
171	2026-01-09 13:53:23.48139+00	62	Seat object (62)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
172	2026-01-09 13:53:49.525669+00	57	Seat object (57)	2	[{"changed": {"fields": ["Row number", "Seat number", "Seat type"]}}]	14	1
173	2026-01-09 13:53:57.825639+00	58	Seat object (58)	2	[{"changed": {"fields": ["Row number", "Seat number", "Seat type"]}}]	14	1
174	2026-01-09 13:54:05.002288+00	59	Seat object (59)	2	[{"changed": {"fields": ["Row number", "Seat number", "Seat type"]}}]	14	1
175	2026-01-09 13:54:11.453913+00	60	Seat object (60)	2	[{"changed": {"fields": ["Row number", "Seat number", "Seat type"]}}]	14	1
176	2026-01-09 13:54:19.554641+00	61	Seat object (61)	2	[{"changed": {"fields": ["Row number", "Seat number", "Seat type"]}}]	14	1
177	2026-01-09 13:54:28.244789+00	62	Seat object (62)	2	[{"changed": {"fields": ["Seat number"]}}]	14	1
178	2026-01-09 13:54:37.254575+00	63	Seat object (63)	1	[{"added": {}}]	14	1
179	2026-01-09 13:54:47.318169+00	64	Seat object (64)	1	[{"added": {}}]	14	1
180	2026-01-09 13:54:53.371052+00	65	Seat object (65)	1	[{"added": {}}]	14	1
181	2026-01-09 13:54:57.685341+00	66	Seat object (66)	1	[{"added": {}}]	14	1
182	2026-01-09 13:55:02.726304+00	67	Seat object (67)	1	[{"added": {}}]	14	1
183	2026-01-09 13:55:10.365657+00	68	Seat object (68)	1	[{"added": {}}]	14	1
184	2026-01-09 13:55:16.796583+00	69	Seat object (69)	1	[{"added": {}}]	14	1
185	2026-01-09 13:55:24.021277+00	70	Seat object (70)	1	[{"added": {}}]	14	1
186	2026-01-09 13:55:29.298861+00	71	Seat object (71)	1	[{"added": {}}]	14	1
187	2026-01-09 13:55:35.854642+00	72	Seat object (72)	1	[{"added": {}}]	14	1
188	2026-01-09 13:55:41.406175+00	73	Seat object (73)	1	[{"added": {}}]	14	1
189	2026-01-09 13:55:46.490032+00	74	Seat object (74)	1	[{"added": {}}]	14	1
190	2026-01-09 13:55:50.779616+00	75	Seat object (75)	1	[{"added": {}}]	14	1
191	2026-01-09 13:55:55.927163+00	76	Seat object (76)	1	[{"added": {}}]	14	1
192	2026-01-09 13:56:00.235569+00	77	Seat object (77)	1	[{"added": {}}]	14	1
193	2026-01-09 13:56:04.89504+00	78	Seat object (78)	1	[{"added": {}}]	14	1
194	2026-01-09 13:56:09.477861+00	79	Seat object (79)	1	[{"added": {}}]	14	1
195	2026-01-09 13:56:14.302529+00	80	Seat object (80)	1	[{"added": {}}]	14	1
196	2026-01-09 13:56:21.68371+00	81	Seat object (81)	1	[{"added": {}}]	14	1
197	2026-01-09 13:56:27.631467+00	82	Seat object (82)	1	[{"added": {}}]	14	1
198	2026-01-09 13:56:32.062297+00	83	Seat object (83)	1	[{"added": {}}]	14	1
199	2026-01-09 13:56:36.471471+00	84	Seat object (84)	1	[{"added": {}}]	14	1
200	2026-01-09 13:56:41.326958+00	85	Seat object (85)	1	[{"added": {}}]	14	1
201	2026-01-09 13:56:46.521107+00	86	Seat object (86)	1	[{"added": {}}]	14	1
202	2026-01-09 13:56:51.557799+00	87	Seat object (87)	1	[{"added": {}}]	14	1
203	2026-01-09 13:56:57.878721+00	88	Seat object (88)	1	[{"added": {}}]	14	1
204	2026-01-09 13:57:02.285681+00	89	Seat object (89)	1	[{"added": {}}]	14	1
205	2026-01-09 13:57:08.061799+00	90	Seat object (90)	1	[{"added": {}}]	14	1
206	2026-01-09 13:57:12.688006+00	91	Seat object (91)	1	[{"added": {}}]	14	1
207	2026-01-09 13:57:18.685693+00	92	Seat object (92)	1	[{"added": {}}]	14	1
208	2026-01-09 13:57:22.944413+00	93	Seat object (93)	1	[{"added": {}}]	14	1
209	2026-01-09 13:57:27.397949+00	94	Seat object (94)	1	[{"added": {}}]	14	1
210	2026-01-09 13:57:34.329141+00	95	Seat object (95)	1	[{"added": {}}]	14	1
211	2026-01-09 13:57:39.43497+00	96	Seat object (96)	1	[{"added": {}}]	14	1
212	2026-01-09 13:57:43.697943+00	97	Seat object (97)	1	[{"added": {}}]	14	1
213	2026-01-09 13:57:54.169102+00	98	Seat object (98)	1	[{"added": {}}]	14	1
214	2026-01-09 13:58:00.476441+00	99	Seat object (99)	1	[{"added": {}}]	14	1
215	2026-01-09 13:58:04.26335+00	100	Seat object (100)	1	[{"added": {}}]	14	1
216	2026-01-09 13:58:09.263061+00	101	Seat object (101)	1	[{"added": {}}]	14	1
217	2026-01-09 13:58:30.928387+00	2	Hall object (2)	2	[{"changed": {"fields": ["Capacity"]}}]	9	1
218	2026-01-09 13:58:51.002085+00	2	Hall object (2)	2	[]	9	1
219	2026-01-09 14:10:25.026153+00	2	Session object (2)	2	[{"changed": {"fields": ["Available seats"]}}]	15	1
220	2026-01-09 14:17:36.375976+00	5	Movie object (5)	1	[{"added": {}}, {"added": {"name": "movie genre", "object": "MovieGenre object (7)"}}]	10	1
221	2026-01-09 14:17:52.238317+00	5	Movie object (5)	2	[{"changed": {"fields": ["Is active"]}}]	10	1
222	2026-01-09 14:18:10.905901+00	5	Movie object (5)	2	[{"changed": {"fields": ["Is active"]}}]	10	1
223	2026-01-09 14:18:28.129734+00	5	Movie object (5)	2	[{"changed": {"fields": ["Is active", "Poster url"]}}]	10	1
224	2026-01-09 14:18:42.374572+00	5	Movie object (5)	2	[{"changed": {"fields": ["Is active"]}}]	10	1
225	2026-01-09 14:21:27.584228+00	6	Movie object (6)	1	[{"added": {}}, {"added": {"name": "movie genre", "object": "MovieGenre object (8)"}}, {"added": {"name": "movie genre", "object": "MovieGenre object (9)"}}, {"added": {"name": "movie genre", "object": "MovieGenre object (10)"}}]	10	1
226	2026-01-09 14:24:54.787107+00	6	Movie object (6)	2	[{"changed": {"fields": ["Poster url"]}}]	10	1
227	2026-01-09 14:28:45.046391+00	7	Movie object (7)	1	[{"added": {}}, {"added": {"name": "movie genre", "object": "MovieGenre object (11)"}}]	10	1
228	2026-01-09 14:29:02.176776+00	8	Movie object (8)	1	[{"added": {}}, {"added": {"name": "movie genre", "object": "MovieGenre object (12)"}}]	10	1
229	2026-01-09 14:29:18.700941+00	9	Movie object (9)	1	[{"added": {}}, {"added": {"name": "movie genre", "object": "MovieGenre object (13)"}}]	10	1
230	2026-01-09 14:29:31.477214+00	10	Movie object (10)	1	[{"added": {}}, {"added": {"name": "movie genre", "object": "MovieGenre object (14)"}}]	10	1
231	2026-01-09 14:41:10.222696+00	7	Movie object (7)	2	[{"changed": {"fields": ["Age rating"]}}]	10	1
232	2026-01-09 15:54:36.637566+00	2	Hall object (2)	2	[]	9	1
233	2026-01-09 16:30:18.06731+00	1	Session object (1)	2	[{"changed": {"fields": ["Price"]}}]	15	1
234	2026-01-09 16:30:27.517519+00	2	Session object (2)	2	[{"changed": {"fields": ["Price"]}}]	15	1
235	2026-01-09 16:36:10.677204+00	3	Session object (3)	1	[{"added": {}}]	15	1
236	2026-01-09 16:36:36.694967+00	3	Session object (3)	2	[{"changed": {"fields": ["Hall"]}}]	15	1
237	2026-01-09 16:36:44.178257+00	3	Session object (3)	2	[{"changed": {"fields": ["Hall"]}}]	15	1
238	2026-01-09 19:49:11.831391+00	7	Movie object (7)	2	[{"changed": {"fields": ["Is active"]}}]	10	1
239	2026-01-09 19:49:15.189302+00	8	Movie object (8)	2	[{"changed": {"fields": ["Is active"]}}]	10	1
240	2026-01-09 19:49:18.23763+00	9	Movie object (9)	2	[{"changed": {"fields": ["Is active"]}}]	10	1
241	2026-01-09 19:49:20.850814+00	10	Movie object (10)	2	[{"changed": {"fields": ["Is active"]}}]	10	1
242	2026-01-09 20:00:03.225754+00	11	Movie object (11)	1	[{"added": {}}, {"added": {"name": "movie genre", "object": "MovieGenre object (15)"}}]	10	1
243	2026-01-09 20:02:18.849764+00	12	Movie object (12)	1	[{"added": {}}, {"added": {"name": "movie genre", "object": "MovieGenre object (16)"}}, {"added": {"name": "movie genre", "object": "MovieGenre object (17)"}}]	10	1
244	2026-01-09 20:07:17.697023+00	13	Movie object (13)	2	[{"changed": {"fields": ["Release date", "End date", "Poster url"]}}, {"added": {"name": "movie genre", "object": "MovieGenre object (18)"}}, {"added": {"name": "movie genre", "object": "MovieGenre object (19)"}}]	10	1
245	2026-01-09 20:10:52.143244+00	4	Session object (4)	1	[{"added": {}}]	15	1
246	2026-01-09 20:13:58.417793+00	2	Movie object (2)	2	[{"changed": {"fields": ["Poster url"]}}]	10	1
\.


--
-- Data for Name: django_content_type; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.django_content_type (id, app_label, model) FROM stdin;
1	admin	logentry
2	auth	group
3	auth	permission
4	auth	user
5	contenttypes	contenttype
6	sessions	session
7	cinema	cancellation
8	cinema	genre
9	cinema	hall
10	cinema	movie
11	cinema	moviegenre
12	cinema	order
13	cinema	pointstransaction
14	cinema	seat
15	cinema	session
16	cinema	sessionseat
17	cinema	ticket
18	cinema	user
19	cinema	userpointsbalance
\.


--
-- Data for Name: django_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.django_migrations (id, app, name, applied) FROM stdin;
1	contenttypes	0001_initial	2025-12-22 19:18:26.96179+00
2	auth	0001_initial	2025-12-22 19:18:27.02699+00
3	admin	0001_initial	2025-12-22 19:18:27.048449+00
4	admin	0002_logentry_remove_auto_add	2025-12-22 19:18:27.055962+00
5	admin	0003_logentry_add_action_flag_choices	2025-12-22 19:18:27.065764+00
6	contenttypes	0002_remove_content_type_name	2025-12-22 19:18:27.087299+00
7	auth	0002_alter_permission_name_max_length	2025-12-22 19:18:27.099119+00
8	auth	0003_alter_user_email_max_length	2025-12-22 19:18:27.117909+00
9	auth	0004_alter_user_username_opts	2025-12-22 19:18:27.126473+00
10	auth	0005_alter_user_last_login_null	2025-12-22 19:18:27.140036+00
11	auth	0006_require_contenttypes_0002	2025-12-22 19:18:27.144486+00
12	auth	0007_alter_validators_add_error_messages	2025-12-22 19:18:27.152318+00
13	auth	0008_alter_user_username_max_length	2025-12-22 19:18:27.166677+00
14	auth	0009_alter_user_last_name_max_length	2025-12-22 19:18:27.179318+00
15	auth	0010_alter_group_name_max_length	2025-12-22 19:18:27.190141+00
16	auth	0011_update_proxy_permissions	2025-12-22 19:18:27.201626+00
17	auth	0012_alter_user_first_name_max_length	2025-12-22 19:18:27.213441+00
18	cinema	0001_initial	2025-12-22 19:18:27.228027+00
19	sessions	0001_initial	2025-12-22 19:18:27.242266+00
\.


--
-- Data for Name: django_session; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.django_session (session_key, session_data, expire_date) FROM stdin;
a05r54lmqvg3u925s6jkoa0o4nfbma6p	.eJxVjEEOwiAQRe_C2pBS6sC4dN8zkAEGqRpISrsy3l1JutDdz38v7yUc7Vt2e-PVLVFchBKn389TeHDpIN6p3KoMtWzr4mVX5EGbnGvk5_Vw_wKZWu5Z0nEAQLRsUfEURo0jmYkiaR0MnxUkq1Vin0xCG-i7APyACsh7xeL9Ad62OG8:1vXlSj:xZpFzYPwVaMgYlI9mUHdHk9Dv3vkUR-Z9qjdXcxYtgk	2026-01-05 19:20:57.562403+00
am0svhbropx9do1g8ifd83w60s46378b	.eJxVjEEOwiAQRe_C2pBS6sC4dN8zkAEGqRpISrsy3l1JutDdz38v7yUc7Vt2e-PVLVFchBKn389TeHDpIN6p3KoMtWzr4mVX5EGbnGvk5_Vw_wKZWu5Z0nEAQLRsUfEURo0jmYkiaR0MnxUkq1Vin0xCG-i7APyACsh7xeL9Ad62OG8:1vXmqR:HkaBr2H6W8iBx23nqE8dkf9IJAwVvPI8XZ0YNMkbgN0	2026-01-05 20:49:31.880113+00
8tpqa80twsgscs131gxaz9i84p2vxvho	.eJxVjEEOwiAQRe_C2pBS6sC4dN8zkAEGqRpISrsy3l1JutDdz38v7yUc7Vt2e-PVLVFchBKn389TeHDpIN6p3KoMtWzr4mVX5EGbnGvk5_Vw_wKZWu5Z0nEAQLRsUfEURo0jmYkiaR0MnxUkq1Vin0xCG-i7APyACsh7xeL9Ad62OG8:1vY672:5U02LJsHMVVpbNZP7siyhMUlBTwAd-mH-kKhSt2uVY0	2026-01-06 17:23:56.346005+00
65xbahm220mjeom0advclpmq93vhclci	.eJxVjEEOwiAQRe_C2pBS6sC4dN8zkAEGqRpISrsy3l1JutDdz38v7yUc7Vt2e-PVLVFchBKn389TeHDpIN6p3KoMtWzr4mVX5EGbnGvk5_Vw_wKZWu5Z0nEAQLRsUfEURo0jmYkiaR0MnxUkq1Vin0xCG-i7APyACsh7xeL9Ad62OG8:1vcmUX:L2J9_tXSiahaalh8N7_pMnOLwaCHVo8DBEFrD1GH61k	2026-01-19 15:27:33.584559+00
6mzgcihq3yy9l0wsry3n179545csdibz	.eJxVjEEOwiAQRe_C2pBS6sC4dN8zkAEGqRpISrsy3l1JutDdz38v7yUc7Vt2e-PVLVFchBKn389TeHDpIN6p3KoMtWzr4mVX5EGbnGvk5_Vw_wKZWu5Z0nEAQLRsUfEURo0jmYkiaR0MnxUkq1Vin0xCG-i7APyACsh7xeL9Ad62OG8:1vdFVO:petcpUGxoLrG6n7FvbhCQfFPGnyzbF6EC5aTRSwxIGo	2026-01-20 22:26:22.777255+00
\.


--
-- Data for Name: genres; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.genres (genre_id, name, description) FROM stdin;
2	Драма	Акцент на глубоких душевных переживаниях, сложных жизненных ситуациях и конфликтах персонажей
3	Фантастика	Действие происходит в мирах, где существуют допущения, невозможные в реальности (технологии будущего, космос, иные измерения)
4	Мультфильм	Анимационное кино, созданное методом покадровой рисовки или компьютерной графики
5	Приключения	Сюжет строится на захватывающем путешествии, поиске чего-то ценного и преодолении опасностей в экзотических местах
1	Боевик	Упор на насилие, погони, драки и перестрелки; герой преодолевает препятствия силой
6	Хоррор	Жанр кино, цель которого вызвать у зрителя страх, тревогу и отвращение через создание напряженной атмосферы и демонстрацию жутких, сверхъестественных или шокирующих событий, часто с элементами фантастики, мистики, насилия.
7	Комедия	Это жанр, цель которого рассмешить зрителя, используя юмор, сатиру, нелепые ситуации и остроумные диалоги для изображения смешного или абсурдного, часто высмеивая человеческие пороки, но без трагического финала.
\.


--
-- Data for Name: halls; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.halls (hall_id, name, capacity, is_active, created_at) FROM stdin;
1	Зал №1	50	t	2025-12-22 19:29:44.620202
2	Зал №2	50	t	2025-12-21 08:30:31.548969
\.


--
-- Data for Name: movie_genres; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.movie_genres (id, movie_id, genre_id) FROM stdin;
1	1	2
2	2	3
3	3	4
4	2	1
5	4	6
6	4	7
7	5	3
8	6	1
9	6	7
10	6	4
11	7	2
12	8	2
13	9	2
14	10	2
15	11	2
16	12	3
17	12	5
18	13	1
19	13	3
\.


--
-- Data for Name: movies; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.movies (movie_id, title, description, director, duration_minutes, age_rating, release_date, end_date, poster_url, is_active, created_at, updated_at) FROM stdin;
6	Человек-бензопила. Фильм: История Резе	Дэндзи встречает загадочную девушку Резе, которая работает в кафе. Между ними завязывается роман, но вскоре выясняется, что Резе — опасная наёмница из СССР, обладающая силой Демона-Бомбы, и её цель — сердце Человека-бензопилы.	Рю Накаяма	100	18+	2026-01-01	2026-12-01	posters/REZE_hceeQai.jpg	t	2026-01-09 07:21:27.577388	2026-01-09 14:24:54.761315
3	Зверополис	Жизнерадостная зайчиха-полицейский и хитрый лис-аферист вынуждены работать вместе, чтобы раскрыть заговор, угрожающий всем жителям огромного города животных.	Байрон Ховард	108	6+	2020-01-01	\N	posters/Zveropolis_CCRY7WG.jpeg	t	2025-12-21 15:28:42.761459	2026-01-06 22:35:52.491644
1	Интерстеллар	Группа исследователей отправляется в космическое путешествие через пространственно-временной тоннель, чтобы найти для человечества новый дом, пока Земля погибает от засухи.	Кристофер Нолан	104	12+	2014-11-06	2025-12-31	posters/Interstellar_S4QbMrG.jpg	t	2025-12-22 05:25:54.469264	2026-01-06 22:48:06.523717
4	Очень страшное кино	Действие разворачивается вокруг группы подростков, которые случайно сбивают человека на машине и сбрасывают тело в воду, поклявшись никогда не рассказывать об этом. Ровно через год их начинает преследовать маньяк в белой маске (Крик), который знает их секрет и убивает их одного за другим самыми нелепыми способами. Главная героиня, Синди Кэмпбелл, пытается выжить и разгадать личность убийцы.	Кинен Айвори Уайанс	88	18+	2000-06-07	2027-01-01	posters/Scary_movie_MYZC3LF.jpg	t	2026-01-08 16:37:39.022047	2026-01-08 16:37:39.022055
5	Евангелион	В 2015 году человечество подвергается атакам гигантских существ — «Ангелов». Для защиты подростки пилотируют биомеханические машины «Евангелионы», сталкиваясь при этом с глубокими личными травмами и экзистенциальным кризисом.	Хидэаки Анно	480	18+	1995-10-04	2000-12-15	posters/Evangelion_5Pa0VsK.jpg	f	2026-01-08 10:17:36.370789	2026-01-09 14:18:42.361292
7	111	111	111	111	0+	2026-01-09	2026-12-01		f	2026-01-07 20:28:45.042958	2026-01-09 19:49:11.786
8	222	222	222	222	6+	2026-01-09	2026-12-01		f	2026-01-09 07:29:02.172876	2026-01-09 19:49:15.176736
9	333	333	333	333	6+	2026-01-09	2026-12-01		f	2026-01-09 07:29:18.697486	2026-01-09 19:49:18.224094
10	444	444	444	444	6+	2026-01-09	2026-12-01		f	2026-01-09 07:29:31.474348	2026-01-09 19:49:20.832383
11	Судья	Успешный адвокат возвращается в родной город на похороны матери и берется защищать своего отца-судью, обвиняемого в убийстве.	Дэвид Добкин	141	16+	2014-09-04	2026-12-01	posters/Judge_u9UlLYD.jpeg	t	2026-01-09 20:00:03.219714	2026-01-09 20:00:03.219725
12	Марсианин	Астронавт, оставленный командой на Марсе после бури, борется за выживание и пытается наладить связь с Землей.	Ридли Скотт	144	16+	2015-09-11	2026-12-01	posters/Martian_zNHlfNb.jpg	t	2026-01-09 20:02:18.8436	2026-01-09 20:02:18.84361
13	Терминатор	Киборг-убийца прибывает из будущего, чтобы устранить женщину, чей еще не рожденный сын станет лидером сопротивления в войне против машин.	Джеймс Кэмерон	107	16+	1984-10-26	2027-12-01	posters/Therminator_pPQQSEC.png	t	2026-01-09 13:04:56.172374	2026-01-09 20:07:17.670179
2	Дюна: Часть вторая	Пол Атрейдес объединяется с фременами, чтобы отомстить за гибель своей семьи и предотвратить ужасное будущее, которое может предсказать только он.	Дени Вильнёв	166	16+	2024-02-28	2025-06-01	posters/Dune_part2_lwXf81t.png	t	2025-12-22 05:27:33.1499	2026-01-09 20:13:58.393249
\.


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.orders (order_id, user_id, total_price, order_status, created_at, updated_at) FROM stdin;
9	1	100.00	completed	2026-01-08 17:20:11.779408	2026-01-08 17:20:11.779417
10	1	100.00	completed	2026-01-08 17:24:40.323045	2026-01-08 17:24:40.323053
11	1	100.00	completed	2026-01-08 17:28:05.535564	2026-01-08 17:28:05.535573
12	1	100.00	completed	2026-01-08 17:28:33.902677	2026-01-08 17:28:33.902684
13	1	100.00	completed	2026-01-09 13:47:46.465621	2026-01-09 13:47:46.46563
14	1	500.00	completed	2026-01-09 16:56:35.738032	2026-01-09 16:56:35.738042
15	3	500.00	completed	2026-01-10 11:00:43.891549	2026-01-10 11:00:43.891579
16	3	500.00	completed	2026-01-10 16:30:13.283491	2026-01-10 16:30:13.283499
\.


--
-- Data for Name: points_transactions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.points_transactions (transaction_id, user_id, order_id, points_amount, operation_type, expiry_date, description, created_at) FROM stdin;
11	1	10	10	earn	2026-02-08	Покупка билета на Интерстеллар	2026-01-08 17:24:40.332422
12	1	\N	10	refund	\N	Возврат баллов при отмене билета на Интерстеллар	2026-01-08 17:27:48.873807
13	1	11	10	earn	2026-02-08	Покупка билета на Интерстеллар	2026-01-08 17:28:05.544227
14	1	12	10	earn	2026-02-08	Покупка билета на Интерстеллар	2026-01-08 17:28:33.910901
15	1	\N	10	refund	\N	Возврат баллов при отмене билета на Интерстеллар	2026-01-08 17:28:45.300409
16	1	13	10	earn	2026-02-08	Покупка билета на Интерстеллар	2026-01-09 13:47:46.516213
17	1	\N	10	refund	\N	Отмена начисления за отмену билета на Интерстеллар	2026-01-09 13:50:27.176976
18	1	14	50	earn	2026-02-08	Покупка билета на Человек-бензопила. Фильм: История Резе	2026-01-09 16:56:35.751817
19	1	\N	50	refund	\N	Отмена начисления за отмену билета на Человек-бензопила. Фильм: История Резе	2026-01-09 17:05:40.912796
20	3	15	50	earn	2026-02-09	Покупка билета на Интерстеллар	2026-01-10 11:00:43.923225
21	3	\N	50	refund	\N	Отмена начисления за отмену билета на Интерстеллар	2026-01-10 11:01:37.335526
22	3	16	50	earn	2026-02-09	Покупка билета на Человек-бензопила. Фильм: История Резе	2026-01-10 16:30:13.305592
\.


--
-- Data for Name: seats; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.seats (seat_id, hall_id, row_number, seat_number, seat_type, created_at) FROM stdin;
1	1	A	1	standard	2025-12-22 19:32:46.663857
2	1	A	2	standard	2025-12-22 19:34:43.672961
3	1	A	3	standard	2025-12-22 19:35:20.801356
4	1	A	4	standard	2025-12-22 19:35:26.588931
5	1	A	5	standard	2025-12-22 19:35:32.733973
6	1	A	6	standard	2025-12-22 19:35:39.998154
7	1	A	7	standard	2025-12-22 19:35:51.953736
8	1	A	8	standard	2025-12-22 19:36:02.802469
9	1	A	9	standard	2025-12-22 19:36:12.822567
10	1	A	10	standard	2025-12-22 19:36:21.705791
11	1	B	1	standard	2025-12-22 19:39:47.802312
12	1	B	2	standard	2025-12-22 19:39:53.768599
13	1	B	3	standard	2025-12-22 19:39:58.37098
14	1	B	4	standard	2025-12-22 19:40:04.406582
15	1	B	5	standard	2025-12-22 19:40:10.885375
16	1	B	6	standard	2025-12-22 19:40:16.343895
17	1	B	7	standard	2025-12-22 19:40:24.995968
18	1	B	8	standard	2025-12-22 19:40:31.620624
19	1	B	9	standard	2025-12-22 19:40:37.916158
20	1	B	10	standard	2025-12-22 19:40:42.874598
21	1	C	1	standard	2025-12-22 19:41:01.432315
22	1	C	2	standard	2025-12-22 19:41:09.514151
23	1	C	3	standard	2025-12-22 19:41:12.960915
24	1	C	4	standard	2025-12-22 19:41:16.321507
25	1	C	5	standard	2025-12-22 19:41:19.048441
26	1	C	6	standard	2025-12-22 19:41:22.838676
27	1	C	7	standard	2025-12-22 19:41:30.60863
28	1	C	8	standard	2025-12-22 19:41:34.019131
29	1	C	9	standard	2025-12-22 19:41:37.026271
30	1	C	10	standard	2025-12-22 19:41:40.159947
31	1	D	1	standard	2025-12-22 19:41:55.697953
32	1	D	2	standard	2025-12-22 19:41:59.800491
33	1	D	3	standard	2025-12-22 19:42:02.356683
34	1	D	4	standard	2025-12-22 19:42:04.761154
35	1	D	5	standard	2025-12-22 19:42:07.174176
36	1	D	6	standard	2025-12-22 19:42:10.496797
37	1	D	7	standard	2025-12-22 19:42:14.048161
38	1	D	8	standard	2025-12-22 19:42:17.18699
39	1	D	9	standard	2025-12-22 19:42:20.090072
40	1	D	10	standard	2025-12-22 19:42:23.406917
41	1	E	1	standard	2025-12-22 19:42:27.113723
42	1	E	2	standard	2025-12-22 19:42:29.869004
43	1	E	3	standard	2025-12-22 19:42:32.899256
44	1	E	4	standard	2025-12-22 19:42:35.985388
45	1	E	5	standard	2025-12-22 19:42:39.245619
46	1	E	6	standard	2025-12-22 19:42:41.964904
47	1	E	7	standard	2025-12-22 19:42:45.225614
48	1	E	8	standard	2025-12-22 19:42:49.147147
49	1	E	9	standard	2025-12-22 19:42:51.991968
50	1	E	10	standard	2025-12-22 19:42:55.416435
52	2	A	1	vip	2025-12-22 19:44:55.751209
53	2	A	2	vip	2025-12-22 19:45:26.947394
54	2	A	3	vip	2025-12-22 19:45:38.491959
55	2	A	4	vip	2025-12-22 19:45:45.376232
56	2	A	5	vip	2025-12-22 19:45:57.540146
57	2	A	6	standard	2025-12-22 19:46:06.787367
58	2	A	7	standard	2025-12-22 19:46:15.341339
59	2	A	8	standard	2025-12-22 19:46:25.880471
60	2	A	9	standard	2025-12-22 19:46:32.66762
61	2	A	10	standard	2025-12-22 19:46:37.946551
62	2	B	1	standard	2026-01-09 13:53:08.988912
63	2	B	2	standard	2026-01-09 13:54:37.247566
64	2	B	3	standard	2026-01-09 13:54:47.310003
65	2	B	4	standard	2026-01-09 13:54:53.364794
66	2	B	5	standard	2026-01-09 13:54:57.678186
67	2	B	6	standard	2026-01-09 13:55:02.719857
68	2	B	7	standard	2026-01-09 13:55:10.360555
69	2	B	8	standard	2026-01-09 13:55:16.789242
70	2	B	9	standard	2026-01-09 13:55:24.013167
71	2	B	10	standard	2026-01-09 13:55:29.292211
72	2	C	1	standard	2026-01-09 13:55:35.847174
73	2	C	2	standard	2026-01-09 13:55:41.399671
74	2	C	3	standard	2026-01-09 13:55:46.48496
75	2	C	4	standard	2026-01-09 13:55:50.773748
76	2	C	5	standard	2026-01-09 13:55:55.922317
77	2	C	6	standard	2026-01-09 13:56:00.23011
78	2	C	7	standard	2026-01-09 13:56:04.888265
79	2	C	8	standard	2026-01-09 13:56:09.471997
80	2	C	9	standard	2026-01-09 13:56:14.293754
81	2	C	10	standard	2026-01-09 13:56:21.677667
82	2	D	1	standard	2026-01-09 13:56:27.625038
83	2	D	2	standard	2026-01-09 13:56:32.056265
84	2	D	3	standard	2026-01-09 13:56:36.465957
85	2	D	4	standard	2026-01-09 13:56:41.322422
86	2	D	5	standard	2026-01-09 13:56:46.514828
87	2	D	6	standard	2026-01-09 13:56:51.551283
88	2	D	7	standard	2026-01-09 13:56:57.872845
89	2	D	8	standard	2026-01-09 13:57:02.279973
90	2	D	9	standard	2026-01-09 13:57:08.056846
91	2	D	10	standard	2026-01-09 13:57:12.683527
92	2	E	1	standard	2026-01-09 13:57:18.678465
93	2	E	2	standard	2026-01-09 13:57:22.938547
94	2	E	3	standard	2026-01-09 13:57:27.391676
95	2	E	4	standard	2026-01-09 13:57:34.322818
96	2	E	5	standard	2026-01-09 13:57:39.428949
97	2	E	6	standard	2026-01-09 13:57:43.692712
98	2	E	7	standard	2026-01-09 13:57:54.164123
99	2	E	8	standard	2026-01-09 13:58:00.470842
100	2	E	9	standard	2026-01-09 13:58:04.256494
101	2	E	10	standard	2026-01-09 13:58:09.257383
\.


--
-- Data for Name: session_seats; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.session_seats (session_seat_id, session_id, seat_id, status, reserved_at, sold_at, created_at, updated_at) FROM stdin;
10	1	2	free	\N	\N	2026-01-08 10:28:33.906125	2026-01-08 17:28:45.276242
9	1	1	free	\N	\N	2026-01-06 16:24:40.326903	2026-01-10 11:01:37.299341
11	3	1	sold	\N	2026-01-10 16:30:13.291588	2026-01-09 02:56:35.744175	2026-01-10 16:30:13.274302
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sessions (session_id, movie_id, hall_id, session_datetime, end_datetime, available_seats, is_active, created_at, updated_at, price) FROM stdin;
2	1	2	2026-01-22 09:00:00	2026-01-22 12:00:00	50	t	2026-01-03 08:43:43.997969	2026-01-09 16:30:27.5054	600.00
4	11	1	2026-01-26 20:00:00	2026-01-26 23:00:00	50	t	2026-01-09 20:10:52.139928	2026-01-09 20:10:52.139933	650.00
1	1	1	2026-01-15 14:00:00	2026-01-15 17:00:00	50	t	2025-12-17 20:52:17.494544	2026-01-10 11:01:37.299341	500.00
3	6	1	2026-01-20 22:00:00	2026-01-21 01:00:00	49	t	2026-01-08 05:36:10.674398	2026-01-10 16:30:13.274302	500.00
\.


--
-- Data for Name: tickets; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tickets (ticket_id, order_id, session_id, seat_id, qr_code, ticket_status, is_valid, created_at, updated_at) FROM stdin;
10	10	1	1	0f7f6f62-fc97-4b31-a15a-b70119eb961f	cancelled	f	2026-01-08 10:24:40.324693	2026-01-08 17:27:48.853755
12	12	1	2	a1e8c9c7-4697-4958-b6c5-7012cebaf4ba	cancelled	f	2026-01-08 10:28:33.904396	2026-01-08 17:28:45.281104
11	11	1	1	6c27894e-3c34-4be1-a83c-f40e02127112	cancelled	f	2026-01-08 10:28:05.53726	2026-01-08 17:30:00.48482
13	13	1	1	5c31d356-613e-47e9-95b2-56b1cfa949e4	cancelled	f	2026-01-09 06:47:46.475225	2026-01-09 13:50:27.15297
14	14	3	1	5a937bcf-0b9e-489b-96b7-aee1d6ce7304	cancelled	f	2026-01-09 09:56:35.740373	2026-01-09 17:05:40.892834
15	15	1	1	5d0156d9-3d0a-4cd7-b97e-805492489fdc	cancelled	f	2026-01-10 04:00:43.901048	2026-01-10 11:01:37.305087
16	16	3	1	1d1a3fcf-de8f-4b7a-96cc-fccb44b9df85	valid	t	2026-01-10 16:30:13.288958	2026-01-10 16:30:13.288967
\.


--
-- Data for Name: user_points_balance; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_points_balance (balance_id, user_id, current_points, last_updated) FROM stdin;
2	2	0	2026-01-08 16:53:03.46863
1	1	0	2026-01-09 17:05:40.889666
3	3	50	2026-01-10 16:30:13.274302
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (user_id, email, password_hash, full_name, phone, birth_date, is_active, created_at, updated_at) FROM stdin;
1	ivan-ivanich@gmail.com	pbkdf2_sha256$1200000$5jftDYyAJlMIWcEzNCG3vz$csp+xsnBgRYmGMnKAFx1/J3SiGz37KVlYIIW/pYnWvw=	Иванов Иван Иванович	+7(913)505-22-22	2000-01-23	t	2025-12-22 19:57:20.157346	2025-12-22 19:57:20.157353
2	test@email.com	pbkdf2_sha256$1200000$YiFHvW4VqxFvG4192giGrJ$oGyi0dSH2+MoULHr9DxcP1uLgN3YZZRjfREQw/mERKE=	Test	+79135057389	2005-01-01	t	2026-01-08 02:30:21.085655	2026-01-08 16:46:38.817646
3	root@root.com	pbkdf2_sha256$1200000$nFl30Y2J9bFMG0yIkNIMnB$e3TcpTqRWzOP1w+ckm/nvQBxW8h5++DWzdd3oTOx5Gc=	Admin	+79139139191	1980-01-01	t	2026-01-09 14:44:38.476194	2026-01-09 14:44:38.476202
\.


--
-- Name: auth_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.auth_group_id_seq', 1, false);


--
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.auth_group_permissions_id_seq', 1, false);


--
-- Name: auth_permission_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.auth_permission_id_seq', 76, true);


--
-- Name: auth_user_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.auth_user_groups_id_seq', 1, false);


--
-- Name: auth_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.auth_user_id_seq', 1, true);


--
-- Name: auth_user_user_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.auth_user_user_permissions_id_seq', 1, false);


--
-- Name: cancellations_cancellation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.cancellations_cancellation_id_seq', 8, true);


--
-- Name: django_admin_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.django_admin_log_id_seq', 246, true);


--
-- Name: django_content_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.django_content_type_id_seq', 19, true);


--
-- Name: django_migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.django_migrations_id_seq', 19, true);


--
-- Name: genres_genre_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.genres_genre_id_seq', 7, true);


--
-- Name: halls_hall_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.halls_hall_id_seq', 2, true);


--
-- Name: movie_genres_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.movie_genres_id_seq', 19, true);


--
-- Name: movies_movie_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.movies_movie_id_seq', 13, true);


--
-- Name: orders_order_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.orders_order_id_seq', 16, true);


--
-- Name: points_transactions_transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.points_transactions_transaction_id_seq', 22, true);


--
-- Name: seats_seat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.seats_seat_id_seq', 101, true);


--
-- Name: session_seats_session_seat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.session_seats_session_seat_id_seq', 11, true);


--
-- Name: sessions_session_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sessions_session_id_seq', 4, true);


--
-- Name: tickets_ticket_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tickets_ticket_id_seq', 16, true);


--
-- Name: user_points_balance_balance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_points_balance_balance_id_seq', 3, true);


--
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.users_user_id_seq', 3, true);


--
-- Name: auth_group auth_group_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_name_key UNIQUE (name);


--
-- Name: auth_group_permissions auth_group_permissions_group_id_permission_id_0cd325b0_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_permission_id_0cd325b0_uniq UNIQUE (group_id, permission_id);


--
-- Name: auth_group_permissions auth_group_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_pkey PRIMARY KEY (id);


--
-- Name: auth_group auth_group_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_pkey PRIMARY KEY (id);


--
-- Name: auth_permission auth_permission_content_type_id_codename_01ab375a_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_codename_01ab375a_uniq UNIQUE (content_type_id, codename);


--
-- Name: auth_permission auth_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_pkey PRIMARY KEY (id);


--
-- Name: auth_user_groups auth_user_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_pkey PRIMARY KEY (id);


--
-- Name: auth_user_groups auth_user_groups_user_id_group_id_94350c0c_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_user_id_group_id_94350c0c_uniq UNIQUE (user_id, group_id);


--
-- Name: auth_user auth_user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_user
    ADD CONSTRAINT auth_user_pkey PRIMARY KEY (id);


--
-- Name: auth_user_user_permissions auth_user_user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permissions_pkey PRIMARY KEY (id);


--
-- Name: auth_user_user_permissions auth_user_user_permissions_user_id_permission_id_14a6b632_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permissions_user_id_permission_id_14a6b632_uniq UNIQUE (user_id, permission_id);


--
-- Name: auth_user auth_user_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_user
    ADD CONSTRAINT auth_user_username_key UNIQUE (username);


--
-- Name: cancellations cancellations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cancellations
    ADD CONSTRAINT cancellations_pkey PRIMARY KEY (cancellation_id);


--
-- Name: cancellations cancellations_ticket_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cancellations
    ADD CONSTRAINT cancellations_ticket_id_key UNIQUE (ticket_id);


--
-- Name: django_admin_log django_admin_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_pkey PRIMARY KEY (id);


--
-- Name: django_content_type django_content_type_app_label_model_76bd3d3b_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_app_label_model_76bd3d3b_uniq UNIQUE (app_label, model);


--
-- Name: django_content_type django_content_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_pkey PRIMARY KEY (id);


--
-- Name: django_migrations django_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_migrations
    ADD CONSTRAINT django_migrations_pkey PRIMARY KEY (id);


--
-- Name: django_session django_session_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_session
    ADD CONSTRAINT django_session_pkey PRIMARY KEY (session_key);


--
-- Name: genres genres_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_name_key UNIQUE (name);


--
-- Name: genres genres_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_pkey PRIMARY KEY (genre_id);


--
-- Name: halls halls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.halls
    ADD CONSTRAINT halls_pkey PRIMARY KEY (hall_id);


--
-- Name: movie_genres movie_genres_movie_id_genre_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movie_genres
    ADD CONSTRAINT movie_genres_movie_id_genre_id_key UNIQUE (movie_id, genre_id);


--
-- Name: movie_genres movie_genres_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movie_genres
    ADD CONSTRAINT movie_genres_pkey PRIMARY KEY (id);


--
-- Name: movies movies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movies
    ADD CONSTRAINT movies_pkey PRIMARY KEY (movie_id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (order_id);


--
-- Name: points_transactions points_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_transactions
    ADD CONSTRAINT points_transactions_pkey PRIMARY KEY (transaction_id);


--
-- Name: seats seats_hall_id_row_number_seat_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seats
    ADD CONSTRAINT seats_hall_id_row_number_seat_number_key UNIQUE (hall_id, row_number, seat_number);


--
-- Name: seats seats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seats
    ADD CONSTRAINT seats_pkey PRIMARY KEY (seat_id);


--
-- Name: session_seats session_seats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_seats
    ADD CONSTRAINT session_seats_pkey PRIMARY KEY (session_seat_id);


--
-- Name: session_seats session_seats_session_id_seat_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_seats
    ADD CONSTRAINT session_seats_session_id_seat_id_key UNIQUE (session_id, seat_id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (session_id);


--
-- Name: tickets tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_pkey PRIMARY KEY (ticket_id);


--
-- Name: tickets tickets_qr_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_qr_code_key UNIQUE (qr_code);


--
-- Name: user_points_balance user_points_balance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_points_balance
    ADD CONSTRAINT user_points_balance_pkey PRIMARY KEY (balance_id);


--
-- Name: user_points_balance user_points_balance_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_points_balance
    ADD CONSTRAINT user_points_balance_user_id_key UNIQUE (user_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: auth_group_name_a6ea08ec_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_group_name_a6ea08ec_like ON public.auth_group USING btree (name varchar_pattern_ops);


--
-- Name: auth_group_permissions_group_id_b120cbf9; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_group_permissions_group_id_b120cbf9 ON public.auth_group_permissions USING btree (group_id);


--
-- Name: auth_group_permissions_permission_id_84c5c92e; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_group_permissions_permission_id_84c5c92e ON public.auth_group_permissions USING btree (permission_id);


--
-- Name: auth_permission_content_type_id_2f476e4b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_permission_content_type_id_2f476e4b ON public.auth_permission USING btree (content_type_id);


--
-- Name: auth_user_groups_group_id_97559544; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_user_groups_group_id_97559544 ON public.auth_user_groups USING btree (group_id);


--
-- Name: auth_user_groups_user_id_6a12ed8b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_user_groups_user_id_6a12ed8b ON public.auth_user_groups USING btree (user_id);


--
-- Name: auth_user_user_permissions_permission_id_1fbb5f2c; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_user_user_permissions_permission_id_1fbb5f2c ON public.auth_user_user_permissions USING btree (permission_id);


--
-- Name: auth_user_user_permissions_user_id_a95ead1b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_user_user_permissions_user_id_a95ead1b ON public.auth_user_user_permissions USING btree (user_id);


--
-- Name: auth_user_username_6821ab7c_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_user_username_6821ab7c_like ON public.auth_user USING btree (username varchar_pattern_ops);


--
-- Name: django_admin_log_content_type_id_c4bce8eb; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX django_admin_log_content_type_id_c4bce8eb ON public.django_admin_log USING btree (content_type_id);


--
-- Name: django_admin_log_user_id_c564eba6; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX django_admin_log_user_id_c564eba6 ON public.django_admin_log USING btree (user_id);


--
-- Name: django_session_expire_date_a5c62663; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX django_session_expire_date_a5c62663 ON public.django_session USING btree (expire_date);


--
-- Name: django_session_session_key_c0390e0f_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX django_session_session_key_c0390e0f_like ON public.django_session USING btree (session_key varchar_pattern_ops);


--
-- Name: idx_cancellations_cancelled_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cancellations_cancelled_at ON public.cancellations USING btree (cancelled_at);


--
-- Name: idx_cancellations_ticket_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cancellations_ticket_id ON public.cancellations USING btree (ticket_id);


--
-- Name: idx_genres_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_genres_name ON public.genres USING btree (name);


--
-- Name: idx_halls_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_halls_is_active ON public.halls USING btree (is_active);


--
-- Name: idx_halls_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_halls_name ON public.halls USING btree (name);


--
-- Name: idx_movie_genres_genre_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_movie_genres_genre_id ON public.movie_genres USING btree (genre_id);


--
-- Name: idx_movie_genres_movie_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_movie_genres_movie_id ON public.movie_genres USING btree (movie_id);


--
-- Name: idx_movies_age_rating; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_movies_age_rating ON public.movies USING btree (age_rating);


--
-- Name: idx_movies_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_movies_is_active ON public.movies USING btree (is_active);


--
-- Name: idx_movies_release_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_movies_release_date ON public.movies USING btree (release_date);


--
-- Name: idx_movies_title; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_movies_title ON public.movies USING btree (title);


--
-- Name: idx_orders_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_created_at ON public.orders USING btree (created_at);


--
-- Name: idx_orders_order_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_order_status ON public.orders USING btree (order_status);


--
-- Name: idx_orders_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_user_id ON public.orders USING btree (user_id);


--
-- Name: idx_points_transactions_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_points_transactions_created_at ON public.points_transactions USING btree (created_at);


--
-- Name: idx_points_transactions_expiry_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_points_transactions_expiry_date ON public.points_transactions USING btree (expiry_date);


--
-- Name: idx_points_transactions_operation_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_points_transactions_operation_type ON public.points_transactions USING btree (operation_type);


--
-- Name: idx_points_transactions_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_points_transactions_order_id ON public.points_transactions USING btree (order_id);


--
-- Name: idx_points_transactions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_points_transactions_user_id ON public.points_transactions USING btree (user_id);


--
-- Name: idx_seats_hall_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_seats_hall_id ON public.seats USING btree (hall_id);


--
-- Name: idx_seats_row_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_seats_row_number ON public.seats USING btree (row_number);


--
-- Name: idx_session_seats_seat_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_session_seats_seat_id ON public.session_seats USING btree (seat_id);


--
-- Name: idx_session_seats_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_session_seats_session_id ON public.session_seats USING btree (session_id);


--
-- Name: idx_session_seats_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_session_seats_status ON public.session_seats USING btree (status);


--
-- Name: idx_sessions_datetime; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_datetime ON public.sessions USING btree (session_datetime);


--
-- Name: idx_sessions_hall_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_hall_id ON public.sessions USING btree (hall_id);


--
-- Name: idx_sessions_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_is_active ON public.sessions USING btree (is_active);


--
-- Name: idx_sessions_movie_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_movie_id ON public.sessions USING btree (movie_id);


--
-- Name: idx_tickets_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tickets_order_id ON public.tickets USING btree (order_id);


--
-- Name: idx_tickets_qr_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tickets_qr_code ON public.tickets USING btree (qr_code);


--
-- Name: idx_tickets_seat_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tickets_seat_id ON public.tickets USING btree (seat_id);


--
-- Name: idx_tickets_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tickets_session_id ON public.tickets USING btree (session_id);


--
-- Name: idx_tickets_ticket_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tickets_ticket_status ON public.tickets USING btree (ticket_status);


--
-- Name: idx_user_points_balance_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_points_balance_user_id ON public.user_points_balance USING btree (user_id);


--
-- Name: idx_users_birth_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_birth_date ON public.users USING btree (birth_date);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_is_active ON public.users USING btree (is_active);


--
-- Name: movies trigger_movies_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_movies_updated_at BEFORE UPDATE ON public.movies FOR EACH ROW EXECUTE FUNCTION public.update_movies_timestamp();


--
-- Name: user_points_balance trigger_points_balance_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_points_balance_timestamp BEFORE UPDATE ON public.user_points_balance FOR EACH ROW EXECUTE FUNCTION public.update_points_balance_timestamp();


--
-- Name: session_seats trigger_session_seats_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_session_seats_updated_at BEFORE UPDATE ON public.session_seats FOR EACH ROW EXECUTE FUNCTION public.update_session_seats_timestamp();


--
-- Name: sessions trigger_sessions_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_sessions_updated_at BEFORE UPDATE ON public.sessions FOR EACH ROW EXECUTE FUNCTION public.update_sessions_timestamp();


--
-- Name: users trigger_users_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_users_timestamp();


--
-- Name: TRIGGER trigger_users_updated_at ON users; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TRIGGER trigger_users_updated_at ON public.users IS 'Автоматически обновляет updated_at при изменении пользователя';


--
-- Name: auth_group_permissions auth_group_permissio_permission_id_84c5c92e_fk_auth_perm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissio_permission_id_84c5c92e_fk_auth_perm FOREIGN KEY (permission_id) REFERENCES public.auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_group_permissions auth_group_permissions_group_id_b120cbf9_fk_auth_group_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_b120cbf9_fk_auth_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_permission auth_permission_content_type_id_2f476e4b_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_2f476e4b_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_user_groups auth_user_groups_group_id_97559544_fk_auth_group_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_group_id_97559544_fk_auth_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_user_groups auth_user_groups_user_id_6a12ed8b_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_user_id_6a12ed8b_fk_auth_user_id FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_user_user_permissions auth_user_user_permi_permission_id_1fbb5f2c_fk_auth_perm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permi_permission_id_1fbb5f2c_fk_auth_perm FOREIGN KEY (permission_id) REFERENCES public.auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_user_user_permissions auth_user_user_permissions_user_id_a95ead1b_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permissions_user_id_a95ead1b_fk_auth_user_id FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: cancellations cancellations_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cancellations
    ADD CONSTRAINT cancellations_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(ticket_id) ON DELETE CASCADE;


--
-- Name: django_admin_log django_admin_log_content_type_id_c4bce8eb_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_content_type_id_c4bce8eb_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: django_admin_log django_admin_log_user_id_c564eba6_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_user_id_c564eba6_fk_auth_user_id FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: movie_genres movie_genres_genre_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movie_genres
    ADD CONSTRAINT movie_genres_genre_id_fkey FOREIGN KEY (genre_id) REFERENCES public.genres(genre_id) ON DELETE CASCADE;


--
-- Name: movie_genres movie_genres_movie_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movie_genres
    ADD CONSTRAINT movie_genres_movie_id_fkey FOREIGN KEY (movie_id) REFERENCES public.movies(movie_id) ON DELETE CASCADE;


--
-- Name: orders orders_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE RESTRICT;


--
-- Name: points_transactions points_transactions_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_transactions
    ADD CONSTRAINT points_transactions_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(order_id) ON DELETE SET NULL;


--
-- Name: points_transactions points_transactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_transactions
    ADD CONSTRAINT points_transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: seats seats_hall_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seats
    ADD CONSTRAINT seats_hall_id_fkey FOREIGN KEY (hall_id) REFERENCES public.halls(hall_id) ON DELETE CASCADE;


--
-- Name: session_seats session_seats_seat_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_seats
    ADD CONSTRAINT session_seats_seat_id_fkey FOREIGN KEY (seat_id) REFERENCES public.seats(seat_id) ON DELETE CASCADE;


--
-- Name: session_seats session_seats_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_seats
    ADD CONSTRAINT session_seats_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.sessions(session_id) ON DELETE CASCADE;


--
-- Name: sessions sessions_hall_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_hall_id_fkey FOREIGN KEY (hall_id) REFERENCES public.halls(hall_id) ON DELETE RESTRICT;


--
-- Name: sessions sessions_movie_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_movie_id_fkey FOREIGN KEY (movie_id) REFERENCES public.movies(movie_id) ON DELETE RESTRICT;


--
-- Name: tickets tickets_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(order_id) ON DELETE CASCADE;


--
-- Name: tickets tickets_seat_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_seat_id_fkey FOREIGN KEY (seat_id) REFERENCES public.seats(seat_id) ON DELETE RESTRICT;


--
-- Name: tickets tickets_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.sessions(session_id) ON DELETE RESTRICT;


--
-- Name: user_points_balance user_points_balance_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_points_balance
    ADD CONSTRAINT user_points_balance_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict jtVtRazTHEQSyvlZUk1RtQvxXiYlgSMGDixbdAyWtTSKZ7Nn9j2M1t18kbEmXph

