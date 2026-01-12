// API Клиент для работы с бэкендом
class MovieAPI {
    constructor(baseURL = 'http://localhost:8000/api') {
        this.baseURL = baseURL;
    }

    // ===== Вспомогательные методы =====
    getAuthHeaders() {
        const token = localStorage.getItem('auth_token');
        const headers = {
            'Content-Type': 'application/json',
        };
        if (token) {
            headers['Authorization'] = `Bearer ${token}`;
        }
        return headers;
    }

    async handleResponse(response) {
        const data = await response.json();
        if (!response.ok) {
            throw new Error(data.error || data.message || 'An error occurred');
        }
        return data;
    }

    // ===== ФИЛЬМЫ =====
    async getMovies() {
        try {
            const response = await fetch(`${this.baseURL}/movies/`, {
                method: 'GET',
                headers: this.getAuthHeaders(),
            });
            return await this.handleResponse(response);
        } catch (error) {
            console.error('Error fetching movies:', error);
            throw error;
        }
    }

    // ===== СЕАНСЫ =====
    async getSessions(movieId = null) {
        try {
            let url = `${this.baseURL}/sessions/`;
            if (movieId) {
                url += `?movie_id=${movieId}`;
            }
            const response = await fetch(url, {
                method: 'GET',
                headers: this.getAuthHeaders(),
            });
            return await this.handleResponse(response);
        } catch (error) {
            console.error('Error fetching sessions:', error);
            throw error;
        }
    }

    // ===== МЕСТА НА СЕАНС =====
    async getSessionSeats(sessionId) {
        try {
            const response = await fetch(`${this.baseURL}/session/${sessionId}/seats/`, {
                method: 'GET',
                headers: this.getAuthHeaders(),
            });
            return await this.handleResponse(response);
        } catch (error) {
            console.error(`Error fetching seats for session ${sessionId}:`, error);
            throw error;
        }
    }

    // ===== РЕГИСТРАЦИЯ =====
    async register(userData) {
        try {
            const response = await fetch(`${this.baseURL}/register/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(userData),
            });
            return await this.handleResponse(response);
        } catch (error) {
            console.error('Error registering:', error);
            throw error;
        }
    }

    // ===== ВХОД =====
    async login(email, password) {
        try {
            const response = await fetch(`${this.baseURL}/login/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ email, password }),
            });
            const data = await this.handleResponse(response);
            if (data.token) {
                localStorage.setItem('auth_token', data.token);
                localStorage.setItem('user_id', data.user_id);
                localStorage.setItem('user_email', data.email);
                localStorage.setItem('user_full_name', data.full_name);
            }
            return data;
        } catch (error) {
            console.error('Error logging in:', error);
            throw error;
        }
    }

    // ===== ВЫХОД =====
    logout() {
        localStorage.removeItem('auth_token');
        localStorage.removeItem('user_id');
        localStorage.removeItem('user_email');
        localStorage.removeItem('user_full_name');
    }

    // ===== ПРОФИЛЬ =====
    async getProfile(userId) {
        try {
            const response = await fetch(`${this.baseURL}/profile/?user_id=${userId}`, {
                method: 'GET',
                headers: this.getAuthHeaders(),
            });
            return await this.handleResponse(response);
        } catch (error) {
            console.error('Error fetching profile:', error);
            throw error;
        }
    }

    // ===== КУПИТЬ БИЛЕТ (Прямая покупка) =====
    async buyTicket(userId, sessionId, seatId) {
        try {
            const response = await fetch(`${this.baseURL}/tickets/buy/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    ...this.getAuthHeaders(),
                },
                body: JSON.stringify({
                    user_id: parseInt(userId),
                    session_id: parseInt(sessionId),
                    seat_id: parseInt(seatId),
                }),
            });
            return await this.handleResponse(response);
        } catch (error) {
            console.error('Error buying ticket:', error);
            throw error;
        }
    }

    // ===== ЗАБРОНИРОВАТЬ МЕСТО =====
    async bookSeat(userId, sessionId, seatId) {
        try {
            const response = await fetch(`${this.baseURL}/reservations/create/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    ...this.getAuthHeaders(),
                },
                body: JSON.stringify({
                    user_id: parseInt(userId),
                    session_id: parseInt(sessionId),
                    seat_id: parseInt(seatId),
                }),
            });
            return await this.handleResponse(response);
        } catch (error) {
            console.error('Error booking seat:', error);
            throw error;
        }
    }

    // ===== ПОДТВЕРДИТЬ БРОНЬ (Купить зарезервированное место) =====
    async confirmReservation(reservationId) {
        try {
            const response = await fetch(`${this.baseURL}/reservations/confirm/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    ...this.getAuthHeaders(),
                },
                body: JSON.stringify({ reservation_id: parseInt(reservationId) }),
            });
            return await this.handleResponse(response);
        } catch (error) {
            console.error('Error confirming reservation:', error);
            throw error;
        }
    }

    // ===== ОТМЕНИТЬ БРОНЬ =====
    async cancelReservation(reservationId) {
        try {
            const response = await fetch(`${this.baseURL}/reservations/cancel/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    ...this.getAuthHeaders(),
                },
                body: JSON.stringify({ reservation_id: parseInt(reservationId) }),
            });
            return await this.handleResponse(response);
        } catch (error) {
            console.error('Error canceling reservation:', error);
            throw error;
        }
    }

    // ===== ПОЛУЧИТЬ МОИ БРОНИ =====
    async getUserReservations(userId) {
        try {
            const response = await fetch(`${this.baseURL}/reservations/user/?user_id=${userId}`, {
                method: 'GET',
                headers: this.getAuthHeaders(),
            });
            return await this.handleResponse(response);
        } catch (error) {
            console.error('Error fetching reservations:', error);
            throw error;
        }
    }

    // ===== ПОЛУЧИТЬ БИЛЕТЫ ПОЛЬЗОВАТЕЛЯ =====
    async getUserTickets(userId) {
        try {
            const response = await fetch(`${this.baseURL}/tickets/user/?user_id=${userId}`, {
                method: 'GET',
                headers: this.getAuthHeaders(),
            });
            return await this.handleResponse(response);
        } catch (error) {
            console.error('Error fetching user tickets:', error);
            throw error;
        }
    }

    // ===== ОТМЕНИТЬ КУПЛЕННЫЙ БИЛЕТ =====
    async cancelTicket(ticketId) {
        try {
            const response = await fetch(`${this.baseURL}/tickets/cancel/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    ...this.getAuthHeaders(),
                },
                body: JSON.stringify({ ticket_id: parseInt(ticketId) }),
            });
            return await this.handleResponse(response);
        } catch (error) {
            console.error(`Error canceling ticket ${ticketId}:`, error);
            throw error;
        }
    }

    // ===== ПОЛУЧИТЬ БАЛАНС БАЛЛОВ =====
    async getPointsBalance(userId) {
        try {
            const response = await fetch(`${this.baseURL}/points/?user_id=${userId}`, {
                method: 'GET',
                headers: this.getAuthHeaders(),
            });
            return await this.handleResponse(response);
        } catch (error) {
            console.error('Error fetching points balance:', error);
            throw error;
        }
    }

    // ===== ПРОВЕРКА АУТЕНТИФИКАЦИИ =====
    isAuthenticated() {
        return !!localStorage.getItem('auth_token');
    }

    getCurrentUserId() {
        return localStorage.getItem('user_id');
    }
}

// Глобальный экземпляр API
const api = new MovieAPI();