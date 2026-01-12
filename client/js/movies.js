// ===== КИНОТЕАТР - АФИША (ИСПРАВЛЕНЫ РЯДЫ) =====
// Новый дизайн с красивым экраном и растянутыми местами
// ИСПРАВЛЕНО: Правильная нумерация мест по рядам (A:1-10, B:11-20 и т.д.)


document.addEventListener('DOMContentLoaded', function() {
  // Настройка кнопок входа/профиля и админ-панели (должно работать на всех страницах)
  setupLoginButton();
  setupAdminButton();

  // Проверяем, что мы находимся на странице афиши
  if (document.querySelector('.movies-section')) {
    console.log('DOM загружен, инициализация афиши...');
    setupNavigation();
    setupModal();
    setupFilters();
    loadAllMovies();
  }
});


// ===== ПЕРЕМЕННЫЕ СОСТОЯНИЯ (БЕЗ ДУБЛЕЙ) =====
let allMovies = [];
let selectedSeatsCarousel = [];
// currentSessionId объявлен в app.js, не дублируем!


// ===== ЗАГРУЗКА ВСЕХ ФИЛЬМОВ =====
async function loadAllMovies() {
    console.log('Загрузка всех фильмов...');
    const container = document.getElementById('movies-list');
    
    if (!container) {
        console.error('Контейнер movies-list не найден!');
        return;
    }
    
    try {
        // Показываем скелет загрузки
        container.innerHTML = `
            <div class="skeleton"></div>
            <div class="skeleton"></div>
            <div class="skeleton"></div>
            <div class="skeleton"></div>
        `;


        console.log('Отправляем запрос API...');
        const moviesData = await api.getMovies();
        console.log('Ответ API получен:', moviesData);
        
        let movies = [];
        
        // Гибкая обработка ответа
        if (Array.isArray(moviesData)) {
            movies = moviesData;
            console.log('Структура: массив, количество:', movies.length);
        } else if (moviesData && typeof moviesData === 'object') {
            // Проверяем разные возможные структуры ответа
            if (moviesData.results && Array.isArray(moviesData.results)) {
                movies = moviesData.results;
                console.log('Структура: .results, количество:', movies.length);
            } else if (moviesData.movies && Array.isArray(moviesData.movies)) {
                movies = moviesData.movies;
                console.log('Структура: .movies, количество:', movies.length);
            } else if (moviesData.data && Array.isArray(moviesData.data)) {
                movies = moviesData.data;
                console.log('Структура: .data, количество:', movies.length);
            } else if (moviesData.items && Array.isArray(moviesData.items)) {
                movies = moviesData.items;
                console.log('Структура: .items, количество:', movies.length);
            } else {
                // Попробуем найти первый массив в объекте
                for (const key in moviesData) {
                    if (Array.isArray(moviesData[key])) {
                        movies = moviesData[key];
                        console.log(`Структура: .${key}, количество:`, movies.length);
                        break;
                    }
                }
            }
        }
        
        console.log('✅ Финальное количество фильмов:', movies.length);
        allMovies = movies || [];
        container.innerHTML = '';
        
        if (!movies || movies.length === 0) {
            console.warn('⚠️ Фильмы не найдены или пустой массив');
            container.innerHTML = '<div class="empty-message" style="padding: 2rem; text-align: center;">Фильмы не загружены</div>';
            return;
        }
        
        // Отображаем все фильмы
        let successCount = 0;
        movies.forEach((movie, index) => {
            try {
                if (movie && (movie.id || movie.movie_id)) {
                    const movieCard = createMovieCard(movie);
                    container.appendChild(movieCard);
                    successCount++;
                }
            } catch (error) {
                console.error(`❌ Ошибка создания карточки фильма ${index}:`, error, movie);
            }
        });
        
        console.log(`✅ Успешно загружено фильмов: ${successCount}/${movies.length}`);
        
        if (successCount === 0) {
            container.innerHTML = '<div class="empty-message">Не удалось загрузить фильмы</div>';
        }
        
    } catch (error) {
        console.error('❌ Критическая ошибка при загрузке фильмов:', error);
        const container = document.getElementById('movies-list');
        if (container) {
            container.innerHTML = `
                <div class="error-message" style="padding: 2rem; text-align: center; margin: 2rem;">
                    <p style="font-size: 1.2rem; color: red; margin-bottom: 1rem;">❌ Ошибка загрузки</p>
                    <p style="color: #6b7280;">${error.message || 'Неизвестная ошибка'}</p>
                    <p style="color: #9ca3af; font-size: 0.9rem; margin-top: 1rem;">Проверьте консоль (F12) для деталей</p>
                    <button onclick="loadAllMovies()" class="btn-primary" style="margin-top: 1.5rem; padding: 0.75rem 1.5rem;">
                        ↻ Повторить
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
    
    const shortTitle = title.length > 45 ? title.substring(0, 35) + '...' : title;
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
            <button class="btn-sessions" onclick="viewMovieSessions(event, ${movie.id || movie.movie_id}, '${title}')">
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
    
    let genresText = 'Неизвестно';
    if (Array.isArray(movie.genres) && movie.genres.length > 0) {
        genresText = movie.genres.map(g => g.name).join(', ');
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
            
            <button class="btn-sessions" style="margin-top: 1.5rem;" onclick="viewMovieSessions(event, ${movie.id || movie.movie_id}, '${title}')">
                Выбрать сеанс
            </button>
        </div>
    `;
    
    modal.classList.add('show');
}


// ===== ПОКАЗ СЕАНСОВ ФИЛЬМА =====
async function viewMovieSessions(event, movieId, movieTitle) {
    event.stopPropagation();
    event.preventDefault();
    
    const token = localStorage.getItem('auth_token');
    if (!token) {
        alert('Для покупки билетов необходимо войти в систему');
        window.location.href = 'login.html';
        return;
    }
    
    try {
        const sessionsData = await api.getSessions(movieId);
        
        let sessions = [];
        if (Array.isArray(sessionsData)) {
            sessions = sessionsData;
        } else if (sessionsData.results) {
            sessions = sessionsData.results;
        } else if (sessionsData.sessions) {
            sessions = sessionsData.sessions;
        } else if (sessionsData.data) {
            sessions = sessionsData.data;
        } else {
            sessions = sessionsData;
        }
        
        const modal = document.getElementById('movie-modal');
        const modalBody = document.getElementById('modal-body');
        
        if (!sessions || sessions.length === 0) {
            modalBody.innerHTML = '<div class="empty-message">Сеансы не найдены. Загляните сюда чуть позже :)</div>';
            modal.classList.add('show');
            return;
        }
        
        let sessionsHTML = `<h3 style="color: var(--primary-color); margin-bottom: 1.5rem;">${movieTitle} - Выберите сеанс</h3>`;
        sessionsHTML += '<div class="sessions-list">';
        
        sessions.forEach(session => {
        const time = session.session_time || session.session_datetime || session.start_time;
        const hall = session.hall_number || session.hall || session.hall_id || session.cinema_hall || '1';
        const seats = session.available_seats || session.free_seats || 50;
        const sessionId = session.id || session.session_id;
        const price = session.price != null ? `${parseFloat(session.price).toFixed(2)} ₽` : '—';

        sessionsHTML += `
            <div class="session-card">
                <div class="session-info">
                    <div class="session-time">${formatTime(time)}</div>
                    <div class="session-date">${formatDate(time)}</div>
                    <div class="session-hall">Зал: ${hall}</div>
                    <div class="session-seats">Свободных мест: ${seats}</div>
                    <div class="session-price" style="font-weight: bold; color: var(--primary-color); margin-top: 0.5rem;">
                        Цена: ${price}
                    </div>
                </div>
                <button class="btn-sessions" onclick="selectSeatsForSession(${sessionId}, '${movieTitle.replace(/'/g, "\\'")}')">
                    Выбрать места
                </button>
            </div>
        `;
        });
        
        sessionsHTML += '</div>';
        modalBody.innerHTML = sessionsHTML;
        modal.classList.add('show');
        
    } catch (error) {
        console.error('Ошибка загрузки сеансов:', error);
        alert('Ошибка загрузки сеансов: ' + error.message);
    }
}


// ===== ВЫБОР МЕСТ ДЛЯ СЕАНСА =====
async function selectSeatsForSession(sessionId, movieTitle) {
    try {
        const seatsData = await api.getSessionSeats(sessionId);
        showSeatsSelectionModal(sessionId, movieTitle, seatsData);
    } catch (error) {
        console.error('Ошибка загрузки мест:', error);
        alert('Ошибка загрузки мест: ' + error.message);
    }
}


// ===== МОДАЛЬНОЕ ОКНО С МЕСТАМИ (НОВЫЙ ДИЗАЙН, ИСПРАВЛЕНЫ РЯДЫ) =====
function showSeatsSelectionModal(sessionId, movieTitle, seatsData) {
    const modal = document.getElementById('movie-modal');
    const modalBody = document.getElementById('modal-body');
    
    if (!modal || !modalBody) return;
    
    currentSessionId = sessionId;
    selectedSeatsCarousel = [];
    
    let seats = [];
    if (Array.isArray(seatsData)) {
        seats = seatsData;
    } else if (seatsData.results) {
        seats = seatsData.results;
    } else if (seatsData.seats) {
        seats = seatsData.seats;
    } else if (seatsData.data) {
        seats = seatsData.data;
    } else {
        seats = seatsData;
    }
    
    if (!Array.isArray(seats) || seats.length === 0) {
        modalBody.innerHTML = '<div class="empty-message">Места не найдены</div>';
        modal.classList.add('show');
        return;
    }
    
    // ===== ИСПРАВЛЕННЫЙ ДИЗАЙН С ПРАВИЛЬНОЙ НУМЕРАЦИЕЙ МЕСТ =====
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
                    onclick="${isDisabled ? '' : `selectSeatCarousel(event, '${seatId}', ${sessionId})`}"
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
                <strong>Выбранные места:</strong> <span id="selected-seats-count" style="color: var(--primary-color); font-weight: 700;">0</span>
            </p>
            <button 
                onclick="confirmSeatsSelectionCarousel(${sessionId})"
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
            >
                Оформить билет(ы)
            </button>
        </div>
    `;
    
    modalBody.innerHTML = seatsHTML;
    modal.classList.add('show');
}


// ===== ВЫБОР МЕСТА =====
function selectSeatCarousel(event, seatId, sessionId) {
    event.preventDefault();
    event.stopPropagation();
    
    const seatButton = document.querySelector(`[data-seat-id="${seatId}"]`);
    
    if (seatButton.disabled) return;
    
    // Переключаем выбор места
    if (selectedSeatsCarousel.includes(seatId)) {
        selectedSeatsCarousel = selectedSeatsCarousel.filter(id => id !== seatId);
        seatButton.style.backgroundColor = '#0284c7';
        seatButton.style.color = 'white';
        seatButton.style.boxShadow = 'none';
    } else {
        selectedSeatsCarousel.push(seatId);
        seatButton.style.backgroundColor = '#1e40af';
        seatButton.style.color = 'white';
        seatButton.style.boxShadow = '0 0 8px rgba(30, 58, 138, 0.5)';
    }
    
    updateSelectedSeatsCount();
}


// ===== ОБНОВЛЕНИЕ СЧЕТЧИКА МЕСТ =====
function updateSelectedSeatsCount() {
    const counter = document.getElementById('selected-seats-count');
    if (counter) {
        counter.textContent = selectedSeatsCarousel.length;
    }
}


// ===== ПОДТВЕРЖДЕНИЕ ВЫБОРА МЕСТ =====
async function confirmSeatsSelectionCarousel(sessionId) {
    if (selectedSeatsCarousel.length === 0) {
        alert('Выберите хотя бы одно место');
        return;
    }


    const userId = localStorage.getItem('user_id');
    if (!userId) {
        alert('Необходимо авторизоваться');
        window.location.href = 'login.html';
        return;
    }


    try {
        let successCount = 0;
        let errorCount = 0;
        const errors = [];


        for (const seatId of selectedSeatsCarousel) {
            try {
                const result = await api.buyTicket(userId, sessionId, seatId);
                successCount++;
                console.log(`✅ Билет куплен для места ${seatId}:`, result);
            } catch (error) {
                errorCount++;
                errors.push(`Место ${seatId}: ${error.message}`);
                console.error(`❌ Ошибка для места ${seatId}:`, error);
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
    selectedSeatsCarousel = [];
    currentSessionId = null;
}


// ===== ФИЛЬТРАЦИЯ ФИЛЬМОВ =====
function setupFilters() {
    const searchInput = document.getElementById('search-input');
    const ratingFilter = document.getElementById('rating-filter');
    
    if (searchInput) {
        searchInput.addEventListener('input', filterMovies);
    }
    
    if (ratingFilter) {
        ratingFilter.addEventListener('change', filterMovies);
    }
}


function filterMovies() {
    const searchInput = document.getElementById('search-input');
    const ratingFilter = document.getElementById('rating-filter');
    const container = document.getElementById('movies-list');
    
    if (!container) return;
    
    const searchTerm = searchInput ? searchInput.value.toLowerCase() : '';
    const selectedRating = ratingFilter ? ratingFilter.value : '';
    
    const filteredMovies = allMovies.filter(movie => {
        const title = (movie.title || movie.name || '').toLowerCase();
        const rating = movie.age_restriction || movie.age_rating || movie.rating || '0+';
        
        const matchesSearch = title.includes(searchTerm);
        const matchesRating = !selectedRating || rating === selectedRating;
        
        return matchesSearch && matchesRating;
    });
    
    container.innerHTML = '';
    
    if (filteredMovies.length === 0) {
        container.innerHTML = '<div class="empty-message">Фильмы не найдены</div>';
        return;
    }
    
    filteredMovies.forEach(movie => {
        try {
            const movieCard = createMovieCard(movie);
            container.appendChild(movieCard);
        } catch (error) {
            console.error('Ошибка создания карточки фильма:', error, movie);
        }
    });
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


function setupLoginButton() {
    const loginBtn = document.getElementById('login-btn');
    if (!loginBtn) return;
    
    const isAuth = localStorage.getItem('auth_token');
    
    if (isAuth) {
        const userName = localStorage.getItem('user_fullname') || 'Профиль';
        loginBtn.textContent = userName;
        loginBtn.onclick = (e) => {
            e.preventDefault();
            window.location.href = 'profile.html';
        };
    } else {
        loginBtn.textContent = 'Вход';
        loginBtn.onclick = (e) => {
            e.preventDefault();
            window.location.href = 'login.html';
        };
    }
}

// ===== НАСТРОЙКА АДМИН КНОПКИ =====
function setupAdminButton() {
    const adminBtn = document.getElementById('admin-btn');
    if (!adminBtn) {
        console.warn('Админ-кнопка не найдена в DOM');
        return;
    }
    
    const isAuth = localStorage.getItem('auth_token');
    const userEmail = localStorage.getItem('user_email'); // ✅ ПРОВЕРЯЕМ EMAIL
    
    console.log('🔍 Проверка админа:', { isAuth: !!isAuth, userEmail });
    
    // Проверяем по email "root@root"
    if (isAuth && userEmail === 'root@root.com') {
        adminBtn.style.display = 'block';
        console.log('✅ Админ-панель доступна');
    } else {
        adminBtn.style.display = 'none';
        console.log('❌ Админ-панель скрыта');
    }
}

// ===== ЭКСПОРТ ФУНКЦИЙ ГЛОБАЛЬНО =====
window.viewMovieSessions = viewMovieSessions;
window.selectSeatsForSession = selectSeatsForSession;
window.selectSeatCarousel = selectSeatCarousel;
window.confirmSeatsSelectionCarousel = confirmSeatsSelectionCarousel;
window.closeModal = closeModal;
window.filterMovies = filterMovies;
window.loadAllMovies = loadAllMovies;
