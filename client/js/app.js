document.addEventListener('DOMContentLoaded', function() {
    console.log('DOM загружен, инициализация...');
    
    setupNavigation();
    setupModal();
    loadPopularMovies();
    setupLoginButton();
    setupAdminButton();
});




// ===== ПЕРЕМЕННЫЕ СОСТОЯНИЯ =====
let selectedSeats = [];
let currentSessionId = null;




// ===== ЗАГРУЗКА ПОПУЛЯРНЫХ ФИЛЬМОВ =====
async function loadPopularMovies() {
    console.log('Загрузка популярных фильмов...');
    const container = document.getElementById('popular-movies');
    
    if (!container) {
        console.error('Контейнер popular-movies не найден!');
        return;
    }
    
    try {
        container.innerHTML = `
            <div class="skeleton"></div>
            <div class="skeleton"></div>
            <div class="skeleton"></div>
            <div class="skeleton"></div>
        `;

        const moviesData = await api.getMovies();
        
        let movies = [];
        if (Array.isArray(moviesData)) {
            movies = moviesData;
        } else if (moviesData.results) {
            movies = moviesData.results;
        } else if (moviesData.movies) {
            movies = moviesData.movies;
        } else {
            movies = moviesData;
        }
        
        console.log('Фильмы загружены:', movies.length);
        container.innerHTML = '';
        
        if (!movies || movies.length === 0) {
            container.innerHTML = '<div class="empty-message">Фильмы не найдены</div>';
            return;
        }
        
        const popularMovies = movies.slice(0, 4);
        
        popularMovies.forEach(movie => {
            try {
                const movieCard = createMovieCard(movie);
                container.appendChild(movieCard);
            } catch (error) {
                console.error('Ошибка создания карточки фильма:', error, movie);
            }
        });
        
    } catch (error) {
        console.error('Ошибка загрузки фильмов:', error);
        const container = document.getElementById('popular-movies');
        if (container) {
            container.innerHTML = `
                <div class="error-message">
                    <p>Ошибка загрузки фильмов: ${error.message}</p>
                    <button onclick="loadPopularMovies()" class="btn-primary" style="margin-top: 1rem;">
                        Повторить попытку
                    </button>
                </div>
            `;
        }
    }
}




// ===== СОЗДАНИЕ КАРТОЧКИ ФИЛЬМА =====
function createMovieCard(movie) {
    const card = document.createElement('div');
    card.className = 'movie-card';
    card.dataset.movieId = movie.id || movie.movie_id;
    
    const title = movie.title || movie.name || 'Неизвестный фильм';
    const director = movie.director || movie.director_name || 'Неизвестно';
    const duration = movie.duration || movie.duration_minutes || movie.runtime || 0;
    const ageRating = movie.age_restriction || movie.age_rating || movie.rating || '0+';
    const description = movie.description || movie.overview || '';
    const posterUrl = movie.poster_url || null;
    
    let genres = 'Неизвестно';
    if (movie.genres) {
        genres = Array.isArray(movie.genres) ? movie.genres.join(', ') : movie.genres;
    } else if (movie.genre) {
        genres = movie.genre;
    }
    
    const shortTitle = title.length > 45 ? title.substring(0, 45) + '...' : title;
    const shortDirector = director.length > 25 ? director.substring(0, 25) + '...' : director;
    
    card.innerHTML = `
        <div class="movie-poster">
            ${posterUrl ? `<img src="${posterUrl}" alt="${title}" style="width: 100%; height: 100%; object-fit: cover;">` : '🎬'}
        </div>
        <div class="movie-info">
            <div class="movie-title" title="${title}">${shortTitle}</div>
            <div class="movie-rating">${ageRating}</div>
            <div class="movie-director"><strong>Режиссер:</strong> ${shortDirector}</div>
            <div class="movie-duration"><strong>Длительность:</strong> ${duration} мин</div>
            <button class="btn-sessions" onclick="handleSelectSession(event, ${movie.id || movie.movie_id})">
                Выбрать сеанс
            </button>
        </div>
    `;
    
    card.addEventListener('click', function(e) {
        if (!e.target.classList.contains('btn-sessions')) {
            showMovieModal(movie);
        }
    });
    
    return card;
}




// ===== ПОКАЗ ИНФОРМАЦИИ О ФИЛЬМЕ =====
function showMovieModal(movie) {
    const modal = document.getElementById('movie-modal');
    const modalBody = document.getElementById('modal-body');
    
    if (!modal || !modalBody) return;
    
    const title = movie.title || movie.name || 'Неизвестный фильм';
    const description = movie.description || movie.overview || 'Описание недоступно';
    const director = movie.director || movie.director_name || 'Неизвестно';
    const duration = movie.duration || movie.duration_minutes || movie.runtime || 0;
    const ageRating = movie.age_restriction || movie.age_rating || movie.rating || '0+';
    const posterUrl = movie.poster_url || null;
    
    // Получаем жанры как строки
    let genresText = 'Неизвестно';
    if (Array.isArray(movie.genres) && movie.genres.length > 0) {
        genresText = movie.genres.map(g => g.name).join(', ');
    } else if (typeof movie.genres === 'string') {
        genresText = movie.genres;
    } else if (movie.genre) {
        genresText = movie.genre;
    }
    
    modalBody.innerHTML = `
        <div class="movie-detail">
            <div class="movie-detail-poster">
                ${posterUrl ? `<img src="${posterUrl}" alt="${title}" style="width: 100%; height: 100%; object-fit: cover;">` : '🎬'}
            </div>
            <h3>${title}</h3>
            <p style="color: #6b7280; font-size: 0.95rem; margin-bottom: 1.5rem;">
                ${description}
            </p>
            
            <div class="movie-meta">
                <div class="movie-meta-item">
                    <strong>Рейтинг:</strong>
                    <span>${ageRating}</span>
                </div>
                <div class="movie-meta-item">
                    <strong>Режиссер:</strong>
                    <span>${director}</span>
                </div>
                <div class="movie-meta-item">
                    <strong>Длительность:</strong>
                    <span>${duration} мин</span>
                </div>
                <div class="movie-meta-item">
                    <strong>Жанр:</strong>
                    <span>${genresText}</span>
                </div>
            </div>
            
            <button class="btn-sessions" style="margin-top: 1.5rem;" onclick="handleSelectSession(event, ${movie.id || movie.movie_id})">
                Выбрать сеанс
            </button>
        </div>
    `;
    
    modal.classList.add('show');
}




// ===== ОБРАБОТЧИК ВЫБОРА СЕАНСА =====
async function handleSelectSession(event, movieId) {
    event.stopPropagation();
    event.preventDefault();
    
    const token = localStorage.getItem('authtoken');
    if (!token) {
        alert('Для бронирования необходимо войти в систему');
        window.location.href = 'login.html';
        return;
    }
    
    try {
        const sessions = await api.getSessions(movieId);
        showSessionsModal(movieId, sessions);
    } catch (error) {
        console.error('Ошибка загрузки сеансов:', error);
        alert('Ошибка загрузки сеансов: ' + error.message);
    }
}




// ===== МОДАЛЬНОЕ ОКНО С СЕАНСАМИ =====
function showSessionsModal(movieId, sessionsData) {
    const modal = document.getElementById('movie-modal');
    const modalBody = document.getElementById('modal-body');

    if (!modal || !modalBody) return;

    let sessions;
    if (Array.isArray(sessionsData)) {
        sessions = sessionsData;
    } else if (sessionsData.results) {
        sessions = sessionsData.results;
    } else if (sessionsData.sessions) {
        sessions = sessionsData.sessions;
    } else {
        sessions = sessionsData;
    }

    if (!Array.isArray(sessions) || sessions.length === 0) {
        modalBody.innerHTML = `<div class="empty-message">Нет доступных сеансов.</div>`;
        modal.classList.add('show');
        return;
    }

    let sessionsHTML = `<h3 style="color: var(--primary-color); margin-bottom: 1.5rem;">Выберите сеанс</h3>`;
    sessionsHTML += `<div class="sessions-list">`;

    sessions.forEach(session => {
        const time = session.sessiontime || session.sessiondatetime || session.session_datetime || session.starttime;
        const hall = (session.hall && session.hall.name) ? session.hall.name : (session.hallnumber || session.hallid || session.cinemahall || "1");
        const seats = session.availableseats || session.freeseats || 50;
        const sessionId = session.id || session.sessionid || session.session_id;
        const price = session.price != null ? parseFloat(session.price).toFixed(2) : '—';

        sessionsHTML += `
            <div class="session-card">
                <div class="session-info">
                    <div class="session-time">${formatTime(time)}</div>
                    <div class="session-date">${formatDate(time)}</div>
                    <div class="session-hall">Зал: ${hall}</div>
                    <div class="session-seats">Свободных мест: ${seats}</div>
                    <div class="session-price" style="font-weight: bold; color: var(--primary-color); margin-top: 0.5rem;">
                        Цена: ${price} ₽
                    </div>
                </div>
                <div>
                    <button class="btn-sessions" onclick="handleSelectSeats(event, ${sessionId})">
                        Выбрать места
                    </button>
                </div>
            </div>
        `;
    });

    sessionsHTML += `</div>`;

    modalBody.innerHTML = sessionsHTML;
    modal.classList.add('show');
}




// ===== ВЫБОР МЕСТ =====
async function handleSelectSeats(event, sessionId) {
    event.stopPropagation();
    event.preventDefault();
    
    try {
        const seatsData = await api.getSessionSeats(sessionId);
        showSeatsModal(sessionId, seatsData);
    } catch (error) {
        console.error('Ошибка загрузки мест:', error);
        alert('Ошибка загрузки мест: ' + error.message);
    }
}




// ===== МОДАЛЬНОЕ ОКНО С МЕСТАМИ =====
function showSeatsModal(sessionId, seatsData) {
    const modal = document.getElementById('movie-modal');
    const modalBody = document.getElementById('modal-body');
    
    if (!modal || !modalBody) return;
    
    currentSessionId = sessionId;
    selectedSeats = [];
    
    let seats = [];
    if (Array.isArray(seatsData)) {
        seats = seatsData;
    } else if (seatsData.results) {
        seats = seatsData.results;
    } else if (seatsData.seats) {
        seats = seatsData.seats;
    } else {
        seats = seatsData;
    }
    
    if (!Array.isArray(seats) || seats.length === 0) {
        modalBody.innerHTML = '<div class="empty-message">Места не найдены</div>';
        modal.classList.add('show');
        return;
    }
    
    // ===== ИСПРАВЛЕННЫЙ ДИЗАЙН - ПРАВИЛЬНАЯ НУМЕРАЦИЯ МЕСТ =====
    let seatsHTML = `<h3 style="color: var(--primary-color); margin-bottom: 1.5rem;">Выберите место</h3>`;
    
    // Легенда
    seatsHTML += `
        <div style="display: flex; justify-content: center; gap: 2rem; margin-bottom: 1.5rem; flex-wrap: wrap;">
            <p style="margin: 0; font-size: 0.9rem;">
                <span style="display: inline-block; width: 16px; height: 16px; background: #0284c7; border: 1px solid #0284c7; border-radius: 3px; margin-right: 0.5rem;"></span>
                Свободно
            </p>
            <p style="margin: 0; font-size: 0.9rem;">
                <span style="display: inline-block; width: 16px; height: 16px; background: #ef4444; border: 1px solid #ef4444; border-radius: 3px; margin-right: 0.5rem;"></span>
                Куплено
            </p>
        </div>
    `;
    
    // Красивая линия экрана как в кинотеатре
    seatsHTML += `
        <div style="position: relative; text-align: center; margin: 2rem 0 2.5rem 0; padding: 0.5rem 0;">
            <div style="height: 4px; background: linear-gradient(90deg, transparent, #dc2626, transparent); border-radius: 2px; margin-bottom: 0.75rem;"></div>
            <div style="font-size: 1rem; color: #9ca3af; font-weight: 700; letter-spacing: 3px; text-shadow: 0 1px 2px rgba(0,0,0,0.1);">🎬 ЭКРАН 🎬</div>
            <div style="height: 4px; background: linear-gradient(90deg, transparent, #dc2626, transparent); border-radius: 2px; margin-top: 0.75rem;"></div>
        </div>
    `;
    
    // ===== ИСПРАВЛЕННАЯ ЛОГИКА РАСПРЕДЕЛЕНИЯ МЕСТ ПО РЯДАМ =====
    const seatsPerRow = 10; // стандартное количество мест в ряду
    const seatsPerColumn = 5; // стандартное количество рядов (A-E)
    const seatsByRow = {};
    
    // Создаем пустые ряды (A, B, C, D, E)
    for (let i = 0; i < seatsPerColumn; i++) {
        const rowLetter = String.fromCharCode(65 + i);
        seatsByRow[rowLetter] = [];
        for (let j = 0; j < seatsPerRow; j++) {
            seatsByRow[rowLetter].push(null);
        }
    }
    
    // Распределяем места по рядам
    seats.forEach((seat, index) => {
        let row = seat.row || seat.row_number || seat.rowId;
        let seatNumber = seat.number || seat.seat_number;
        
        // Если нет информации о ряде, вычисляем по индексу
        if (!row) {
            row = String.fromCharCode(65 + Math.floor(index / seatsPerRow)); // A, B, C, D, E
        }
        
        // Если нет номера места, вычисляем по позиции в ряду
        if (!seatNumber) {
            seatNumber = (index % seatsPerRow) + 1; // 1-10
        }
        
        // Преобразуем букву в индекс (A → 0, B → 1, и т.д.)
        const rowIndex = row.charCodeAt(0) - 65;
        const positionIndex = seatNumber - 1;
        
        // Проверяем границы и размещаем место
        if (rowIndex >= 0 && rowIndex < seatsPerColumn) {
            if (positionIndex >= 0 && positionIndex < seatsPerRow) {
                seatsByRow[row][positionIndex] = seat;
            }
        }
    });
    
    // Выводим сетку мест по рядам с правильной нумерацией
    seatsHTML += `<div style="max-width: 900px; margin: 2rem auto; padding: 1.5rem; background: white; border-radius: 8px;">`;
    
    // Выводим рядами (A, B, C, D, E)
    ['A', 'B', 'C', 'D', 'E'].forEach(rowLetter => {
        seatsHTML += `
            <div style="display: flex; gap: 8px; margin-bottom: 12px; align-items: center; justify-content: center;">
                <div style="font-weight: 700; min-width: 30px; text-align: center;">${rowLetter}</div>
        `;
        
        seatsByRow[rowLetter].forEach((seat, index) => {
            const seatNumber = index + 1; // 1, 2, 3, ..., 10
            const seatId = seat ? (seat.id || seat.seat_id || seat.seatId) : '';
            const seatStatus = seat ? (seat.status || seat.availability || seat.seat_status || 'available') : 'available';
            
            let seatColor = '#0284c7'; // свободное
            let isDisabled = false;
            
            if (seatStatus === 'booked' || seatStatus === 'sold' || seatStatus === 'occupied') {
                seatColor = '#ef4444'; // куплено
                isDisabled = true;
            }
            seatsHTML += `
                <button 
                    onclick="${isDisabled ? '' : `toggleSeat('${seatId}', '${rowLetter}${seatNumber}')`}"
                    style="
                        width: 45px;
                        height: 45px;
                        background: ${seatColor};
                        color: white;
                        border: 2px solid ${seatColor};
                        border-radius: 6px;
                        cursor: ${isDisabled ? 'not-allowed' : 'pointer'};
                        font-weight: 700;
                        font-size: 0.85rem;
                        transition: all 0.2s ease;
                        ${isDisabled ? 'opacity: 0.5;' : ''}
                    "
                    id="seat-${seatId}"
                    data-seat-id="${seatId}"
                    data-seat-row="${rowLetter}"
                    data-seat-number="${seatNumber}"
                    ${isDisabled ? 'disabled' : ''}
                    title="Место ${rowLetter}${seatNumber}"
                >
                    ${seatNumber}
                </button>
            `;
        });
        
        seatsHTML += `</div>`;
    });
    
    seatsHTML += `</div>`;
    
    // Информация о выборе
    seatsHTML += `
        <div style="text-align: center; margin: 2rem 0;">
            <p style="color: #6b7280; margin-bottom: 1rem; font-size: 0.95rem;">
                <strong>Выбранные места:</strong> <span id="selected-display" style="color: var(--primary-color); font-weight: 700;">Не выбраны</span>
            </p>
            <button 
                id="buy-btn"
                onclick="buyTickets(${sessionId})"
                style="
                    padding: 0.75rem 2rem;
                    background: var(--primary-color);
                    color: white;
                    border: none;
                    border-radius: 6px;
                    font-weight: 600;
                    font-size: 1rem;
                    cursor: pointer;
                    transition: all 0.2s ease;
                "
                disabled
            >
                Оформить билет(ы)
            </button>
        </div>
    `;
    
    modalBody.innerHTML = seatsHTML;
    modal.classList.add('show');
}



// ===== ПЕРЕКЛЮЧЕНИЕ ВЫБРАННОГО МЕСТА =====
function toggleSeat(seatId, displayName) {
    const button = document.getElementById(`seat-${seatId}`);
    if (!button || button.disabled) return;
    
    const index = selectedSeats.findIndex(s => s.id === seatId);
    
    if (index >= 0) {
        // Убираем место
        selectedSeats.splice(index, 1);
        button.style.background = '#0284c7';
        button.style.borderColor = '#0284c7';
        button.style.boxShadow = 'none';
    } else {
        // Добавляем место
        selectedSeats.push({id: seatId, display: displayName});
        button.style.background = '#1e40af';
        button.style.borderColor = '#1e40af';
        button.style.boxShadow = '0 0 8px rgba(30, 58, 138, 0.5)';
    }
    
    updateSeatsDisplay();
}




// ===== ОБНОВЛЕНИЕ ОТОБРАЖЕНИЯ ВЫБРАННЫХ МЕСТ =====
function updateSeatsDisplay() {
    const display = document.getElementById('selected-display');
    const buyBtn = document.getElementById('buy-btn');
    
    if (selectedSeats.length === 0) {
        display.textContent = 'Не выбраны';
        buyBtn.disabled = true;
    } else {
        display.textContent = selectedSeats.map(s => s.display).join(', ');
        buyBtn.disabled = false;
    }
}




// ===== ПОКУПКА БИЛЕТОВ (БЕЗ БРОНИРОВАНИЯ) =====
async function buyTickets(sessionId) {
    if (selectedSeats.length === 0) {
        alert('Выберите хотя бы одно место');
        return;
    }

    const userId = localStorage.getItem('userid');
    if (!userId) {
        alert('Необходимо авторизоваться');
        window.location.href = 'login.html';
        return;
    }

    try {
        let successCount = 0;
        let errorCount = 0;
        const errors = [];

        for (const seat of selectedSeats) {
            try {
                const result = await api.buyTicket(userId, sessionId, seat.id);
                successCount++;
                console.log(`✅ Билет на место ${seat.display} куплен:`, result);
            } catch (error) {
                errorCount++;
                errors.push(`Место ${seat.display}: ${error.message}`);
                console.error(`❌ Ошибка для места ${seat.display}:`, error);
            }
        }

        if (successCount > 0 && errorCount === 0) {
            alert(`✅ Успешно куплено ${successCount} билет(ов)!`);
            closeModal();
            setTimeout(() => {
                window.location.href = 'profile.html';
            }, 1000);
        } else if (successCount > 0 && errorCount > 0) {
            alert(`⚠️ Куплено ${successCount}, ошибок ${errorCount}\n${errors.join('\n')}`);
        } else {
            alert(`❌ Ошибка:\n${errors.join('\n')}`);
        }

    } catch (error) {
        console.error('Ошибка:', error);
        alert('❌ Ошибка: ' + error.message);
    }
}



// ===== ФОРМАТИРОВАНИЕ ДАТЫ И ВРЕМЕНИ =====
function formatTime(dateTimeString) {
    if (!dateTimeString) return '--:--';
    try {
        const date = new Date(dateTimeString);
        const hours = String(date.getHours()).padStart(2, '0');
        const minutes = String(date.getMinutes()).padStart(2, '0');
        return `${hours}:${minutes}`;
    } catch (e) {
        return '--:--';
    }
}



function formatDate(dateTimeString) {
    if (!dateTimeString) return '';
    try {
        const date = new Date(dateTimeString);
        return date.toLocaleDateString('ru-RU', {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    } catch (e) {
        return '';
    }
}



// ===== УПРАВЛЕНИЕ МОДАЛЬНЫМ ОКНОМ =====
function setupModal() {
    const modal = document.getElementById('movie-modal');
    const closeBtn = document.getElementById('modal-close');
    
    if (!modal || !closeBtn) return;
    
    closeBtn.addEventListener('click', closeModal);
    
    modal.addEventListener('click', (e) => {
        if (e.target === modal) {
            closeModal();
        }
    });
    
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && modal.classList.contains('show')) {
            closeModal();
        }
    });
}



function closeModal() {
    const modal = document.getElementById('movie-modal');
    if (modal) {
        modal.classList.remove('show');
    }
    selectedSeats = [];
    currentSessionId = null;
}



// ===== НАСТРОЙКА НАВИГАЦИИ =====
function setupNavigation() {
    const navLinks = document.querySelectorAll('.nav-link');
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            if (this.href) return;
            e.preventDefault();
            navLinks.forEach(l => l.classList.remove('active'));
            this.classList.add('active');
        });
    });
}



// ===== НАСТРОЙКА КНОПКИ ЛОГИНА =====
function setupLoginButton() {
    const loginBtn = document.getElementById('login-btn');
    if (!loginBtn) return;
    
    if (api.isAuthenticated()) {
        loginBtn.textContent = 'Профиль';  // ✅ ТОЛЬКО "Профиль"
        loginBtn.href = 'profile.html';
    } else {
        loginBtn.textContent = 'Вход';
        loginBtn.href = 'login.html';
    }
}



// ===== НАСТРОЙКА АДМИН КНОПКИ =====
function setupAdminButton() {
    const adminBtn = document.getElementById('admin-btn');
    if (!adminBtn) {
        console.warn('Админ-кнопка не найдена в DOM');
        return;
    }
    
    const isAuth = localStorage.getItem('authtoken');
    const userEmail = localStorage.getItem('useremail');
    
    console.log('🔍 Проверка админа:', { isAuth: !!isAuth, userEmail });
    
    // Проверяем по email "root@root.com"
    if (isAuth && userEmail === 'root@root.com') {
        adminBtn.style.display = 'block';
        console.log('✅ Админ-панель доступна');
    } else {
        adminBtn.style.display = 'none';
        console.log('❌ Админ-панель скрыта');
    }
}



// ===== ЭКСПОРТ ФУНКЦИЙ ГЛОБАЛЬНО =====
window.handleSelectSession = handleSelectSession;
window.handleSelectSeats = handleSelectSeats;
window.toggleSeat = toggleSeat;
window.buyTickets = buyTickets;
window.closeModal = closeModal;
window.loadPopularMovies = loadPopularMovies;