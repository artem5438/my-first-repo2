document.addEventListener('DOMContentLoaded', async () => {
    const isAuth = localStorage.getItem('auth_token');
    const userEmail = localStorage.getItem('user_email');
    
    if (!isAuth || userEmail !== 'root@root.com') {
        window.location.href = 'login.html';
        return;
    }
    
    const savedPass = localStorage.getItem('admin_pass_ok');
    if (!savedPass) {
        const pass = prompt('Введите пароль администратора:');
        if (!pass) {
            alert('Доступ запрещён');
            window.location.href = 'index.html';
            return;
        }

        const res = await fetch('http://localhost:8000/api/admin-check/', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ password: pass })
        });

        if (res.ok) {
            localStorage.setItem('admin_pass_ok', 'true');
        } else {
            alert('Неверный пароль!');
            window.location.href = 'index.html';
            return;
        }
    }

    console.log('✅ Админ-панель: доступ для', userEmail);
    loadMovies();
    loadSessions();
    populateMovieSelect();
    populateHallSelect(); 
    setupFormHandlers();
    
    // Обработчик предпросмотра изображения
    const posterInput = document.getElementById('movie-poster');
    if (posterInput) {
        posterInput.addEventListener('change', function() {
            const preview = document.getElementById('poster-preview');
            const previewImg = document.getElementById('poster-preview-img');
            
            if (this.files && this.files[0]) {
                const reader = new FileReader();
                
                reader.onload = function(e) {
                    previewImg.src = e.target.result;
                    preview.style.display = 'block';
                };
                
                reader.readAsDataURL(this.files[0]);
            } else {
                preview.style.display = 'none';
            }
        });
    }
});

// ===== ПЕРЕКЛЮЧЕНИЕ ВКЛАДОК =====
function switchAdminTab(tabName) {
    document.querySelectorAll('.admin-section').forEach(s => s.classList.remove('active'));
    document.querySelectorAll('.admin-menu-btn').forEach(b => b.classList.remove('active'));
    
    document.getElementById(`${tabName}-section`).classList.add('active');
    event.target.classList.add('active');
}

// ===== ЗАГРУЗКА ФИЛЬМОВ =====
async function loadMovies() {
    try {
        console.log('📽️ Загрузка фильмов...');
        const response = await fetch('http://localhost:8000/api/movies/', {
            headers: { 'Authorization': `Bearer ${localStorage.getItem('auth_token')}` }
        });
        console.log('🚀 Ответ сервера:', response.status, response.statusText);
        
        const data = await response.json();
        console.log('✅ Ответ API:', data);
        
        // Гибкая обработка ответа (как в movies.js)
        let movies = [];
        if (Array.isArray(data)) {
            movies = data;
            console.log('Структура: массив, количество:', movies.length);
        } else if (data && typeof data === 'object') {
            if (data.results && Array.isArray(data.results)) {
                movies = data.results;
                console.log('Структура: .results, количество:', movies.length);
            } else if (data.movies && Array.isArray(data.movies)) {
                movies = data.movies;
                console.log('Структура: .movies, количество:', movies.length);
            } else if (data.data && Array.isArray(data.data)) {
                movies = data.data;
                console.log('Структура: .data, количество:', movies.length);
            } else if (data.items && Array.isArray(data.items)) {
                movies = data.items;
                console.log('Структура: .items, количество:', movies.length);
            } else {
                // Попробуем найти первый массив в объекте
                for (const key in data) {
                    if (Array.isArray(data[key])) {
                        movies = data[key];
                        console.log(`Структура: .${key}, количество:`, movies.length);
                        break;
                    }
                }
            }
        }
        
        const list = document.getElementById('movies-list');
        list.innerHTML = '';
        
        if (!movies || movies.length === 0) {
            list.innerHTML = '<p style="grid-column: 1/-1; color: #6b7280;">Фильмы не найдены</p>';
            return;
        }
        
        movies.forEach(movie => {
            // 🔍 ВАЖНО: проверяем какое поле используется как ID
            const movieId = movie.id || movie.movie_id;
            console.log('🎬 Фильм:', movie.title, 'ID:', movieId);
            
            const card = document.createElement('div');
            card.className = 'item-card';
            
            // Получаем правильное название постера
            const posterUrl = movie.poster_url || movie.poster || movie.poster_image || '';
            
            // Получаем правильное название длительности
            const duration = movie.duration || movie.duration_minutes || movie.runtime || 0;
            
            // Получаем правильное название рейтинга
            const ageRating = movie.age_restriction || movie.age_rating || movie.rating || '0+';
            
            card.innerHTML = `
                <div class="movie-poster">
                    ${posterUrl ? `<img src="${posterUrl}" alt="${movie.title || 'Без названия'}" style="width: 100%; height: 100%; object-fit: cover;">` : '🎬'}
                </div>
                <h4>${escapeHtml(movie.title || 'Без названия')}</h4>
                <div class="item-meta">👤 ${escapeHtml(movie.director || 'Неизвестно')}</div>
                <div class="item-meta">⏱️ ${duration} мин</div>
                <div class="item-meta">🎯 ${ageRating}</div>
                <div class="item-actions">
                    <button class="btn-edit" onclick="editMovie(${movieId})">✏️ Редактировать</button>
                    <button class="btn-delete" onclick="deleteMovie(${movieId})">🗑️ Удалить</button>
                </div>
            `;
            list.appendChild(card);
        });
    } catch (error) {
        console.error('❌ Ошибка загрузки:', error);
        document.getElementById('movies-list').innerHTML = `<p style="color: red; grid-column: 1/-1;">Ошибка: ${error.message}</p>`;
    }
}

// ===== ЗАГРУЗКА СЕАНСОВ =====
async function loadSessions() {
  try {
    console.log('🎬 Загрузка сеансов...');
    const response = await fetch('http://localhost:8000/api/sessions/', {
      headers: { 'Authorization': `Bearer ${localStorage.getItem('auth_token')}` }
    });
    const data = await response.json();
    let sessions = [];
    if (Array.isArray(data)) {
      sessions = data;
    } else if (data.results) {
      sessions = data.results;
    } else if (data.sessions) {
      sessions = data.sessions;
    }
    const list = document.getElementById('sessions-list');
    list.innerHTML = '';
    if (!sessions || sessions.length === 0) {
      list.innerHTML = '<p style="grid-column: 1/-1; color: #6b7280;">Сеансы не найдены</p>';
      return;
    }
    sessions.forEach(session => {
      const sessionId = session.id || session.session_id;
      const card = document.createElement('div');
      card.className = 'item-card';
      
      // Правильная обработка зала
      let hallName = 'Неизвестный';
      if (session.hall) {
        // Если hall - объект
        if (typeof session.hall === 'object') {
          hallName = session.hall.name || session.hall.id || 'Зал без названия';
        } 
        // Если hall - строка или число
        else {
          hallName = session.hall;
        }
      } 
      // Если есть hall_id, но нет hall
      else if (session.hall_id) {
        hallName = `Зал ${session.hall_id}`;
      }
      
      card.innerHTML = `
        <h4>${escapeHtml(session.movie?.title || 'Неизвестный фильм')}</h4>
        <div class="item-meta">📅 ${formatDateTime(session.session_datetime)}</div>
        <div class="item-meta">⏰ ${formatDateTime(session.end_datetime)}</div>
        <div class="item-meta">🎪 Зал ${hallName}</div>
        <div class="item-actions">
          <button class="btn-edit" onclick="editSession(${sessionId})">✏️ Редактировать</button>
          <button class="btn-delete" onclick="deleteSession(${sessionId})">🗑️ Удалить</button>
        </div>
      `;
      list.appendChild(card);
    });
  } catch (error) {
    console.error('❌ Ошибка загрузки:', error);
    document.getElementById('sessions-list').innerHTML = `<p style="color: red; grid-column: 1/-1;">Ошибка: ${error.message}</p>`;
  }
}
// ===== ЗАПОЛНЕНИЕ ФИЛЬМОВ =====
async function populateMovieSelect() {
    try {
        const response = await fetch('http://localhost:8000/api/movies/', {
            headers: { 'Authorization': `Bearer ${localStorage.getItem('auth_token')}` }
        });
        const data = await response.json();
        
        let movies = [];
        if (Array.isArray(data)) {
            movies = data;
        } else if (data.results) {
            movies = data.results;
        } else if (data.movies) {
            movies = data.movies;
        }
        
        const select = document.getElementById('session-movie');
        select.innerHTML = '<option value="">Выберите фильм</option>';
        
        movies.forEach(movie => {
            const movieId = movie.id || movie.movie_id;
            const option = document.createElement('option');
            option.value = movieId;
            option.textContent = `${movie.title || 'Без названия'} (${movieId})`;
            select.appendChild(option);
        });
    } catch (error) {
        console.error('Error loading movies:', error);
        const select = document.getElementById('session-movie');
        select.innerHTML = `
            <option value="">Ошибка загрузки фильмов</option>
            <option value="1">Фильм 1</option>
            <option value="2">Фильм 2</option>
            <option value="3">Фильм 3</option>
        `;
    }
}

// ===== ЗАПОЛНЕНИЕ ЗАЛОВ =====
async function populateHallSelect() {
  try {
    const response = await fetch('http://localhost:8000/api/halls/', {
      headers: { 'Authorization': `Bearer ${localStorage.getItem('auth_token')}` }
    });
    const data = await response.json();
    let halls = [];
    if (Array.isArray(data)) {
      halls = data;
    } else if (data.results) {
      halls = data.results;
    } else if (data.halls) {
      halls = data.halls;
    }
    const select = document.getElementById('session-hall');
    select.innerHTML = '<option value="">Выберите зал</option>';
    halls.forEach(hall => {
      const hallId = hall.id || hall.hall_id;
      const option = document.createElement('option');
      option.value = hallId;
      option.textContent = `Зал ${hall.name || hallId}`;
      select.appendChild(option);
    });
  } catch (error) {
    console.error('Error loading halls:', error);
    const select = document.getElementById('session-hall');
    select.innerHTML = `
      <option value="">Ошибка загрузки залов</option>
      <option value="1">Зал 1</option>
      <option value="2">Зал 2</option>
    `;
  }
}

// ===== ОБРАБОТЧИК ФОРМ =====
function setupFormHandlers() {
    // ФИЛЬМЫ
    const movieForm = document.getElementById('movie-form');
    movieForm?.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        // Исправленная обработка дат
        const releaseDate = document.getElementById('movie-release-date').value || null;
        const endDate = document.getElementById('movie-end-date').value || null;

        // Создаем FormData для загрузки файлов
        const formData = new FormData();
        formData.append('title', document.getElementById('movie-title').value);
        formData.append('description', document.getElementById('movie-description').value);
        formData.append('director', document.getElementById('movie-director').value);
        formData.append('duration_minutes', parseInt(document.getElementById('movie-duration').value));
        formData.append('age_rating', document.getElementById('movie-rating').value);
        formData.append('release_date', releaseDate);
        formData.append('end_date', endDate);
        formData.append('is_active', 'true');
        
        // Добавляем файл постера, если он выбран
        const posterInput = document.getElementById('movie-poster');
        if (posterInput.files && posterInput.files[0]) {
            formData.append('poster_url', posterInput.files[0]);
        }

        try {
            const movieId = movieForm.dataset.movieId;
            const token = localStorage.getItem('auth_token');
            
            let response;
            if (movieId && movieId !== 'undefined') {
                // РЕДАКТИРОВАНИЕ - PUT запрос
                response = await fetch(`http://localhost:8000/api/movies/${movieId}/`, {
                    method: 'PUT',
                    headers: {
                        'Authorization': `Bearer ${token}`
                    },
                    body: formData
                });
            } else {
                // СОЗДАНИЕ - POST запрос
                response = await fetch('http://localhost:8000/api/movies/create/', {
                    method: 'POST',
                    headers: {
                        'Authorization': `Bearer ${token}`
                    },
                    body: formData
                });
            }
            
            const responseText = await response.text();
            console.log('📥 Ответ:', response.status, responseText);
            
            if (!response.ok) {
                throw new Error(`Ошибка ${response.status}: ${responseText}`);
            }
            
            showAlert(movieId ? '✅ Фильм обновлен!' : '✅ Фильм добавлен!', 'success');
            movieForm.reset();
            delete movieForm.dataset.movieId;
            loadMovies();
        } catch (error) {
            console.error('❌ Ошибка:', error);
            showAlert(`❌ Ошибка: ${error.message}`, 'error');
        }
    }); 
    
    // СЕАНСЫ
    const sessionForm = document.getElementById('session-form');
    sessionForm?.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        // Добавляем проверку на выбор фильма
        const movieId = document.getElementById('session-movie').value;
        const hallId = document.getElementById('session-hall').value;
        const sessionStart = document.getElementById('session-start').value;
        const sessionEnd = document.getElementById('session-end').value;
        const sessionPrice = document.getElementById('session-price') ? document.getElementById('session-price').value : '100';
        
        // Проверяем обязательные поля
        if (!movieId || movieId === '' || movieId === 'undefined') {
            showAlert('❌ Выберите фильм из списка', 'error');
            return;
        }
        if (!hallId || hallId === '' || hallId === 'undefined') {
            showAlert('❌ Выберите зал', 'error');
            return;
        }
        if (!sessionStart || sessionStart === '') {
            showAlert('❌ Укажите дату и время начала сеанса', 'error');
            return;
        }
        if (!sessionEnd || sessionEnd === '') {
            showAlert('❌ Укажите дату и время окончания сеанса', 'error');
            return;
        }
        if (!sessionPrice || sessionPrice === '' || sessionPrice === '0') {
            showAlert('❌ Укажите цену билета', 'error');
            return;
        }

        const formData = new FormData();
        formData.append('movie_id', movieId);
        formData.append('hall_id', hallId);
        formData.append('session_datetime', sessionStart);
        formData.append('end_datetime', sessionEnd);
        formData.append('price', sessionPrice); // Добавляем цену
        formData.append('is_active', 'true');
        formData.append('available_seats', '100');

        try {
            const sessionId = sessionForm.dataset.sessionId;
            const token = localStorage.getItem('auth_token');
            let response;
            
            if (sessionId && sessionId !== 'undefined') {
                response = await fetch(`http://localhost:8000/api/sessions/${sessionId}/`, {
                    method: 'PUT',
                    headers: {
                        'Authorization': `Bearer ${token}`
                    },
                    body: formData
                });
            } else {
                response = await fetch('http://localhost:8000/api/sessions/create/', {
                    method: 'POST',
                    headers: {
                        'Authorization': `Bearer ${token}`
                    },
                    body: formData
                });
            }

            if (!response.ok) {
                const errorText = await response.text();
                throw new Error(`Ошибка ${response.status}: ${errorText}`);
            }

            showAlert(sessionId ? '✅ Сеанс обновлен!' : '✅ Сеанс добавлен!', 'success');
            sessionForm.reset();
            delete sessionForm.dataset.sessionId;
            loadSessions();
        } catch (error) {
            console.error('❌ Ошибка:', error);
            showAlert(`❌ Ошибка: ${error.message}`, 'error');
        }
    });
}

// ===== РЕДАКТИРОВАНИЕ ФИЛЬМА =====
async function editMovie(movieId) {
    if (!movieId || movieId === 'undefined') {
        console.error('❌ ID фильма не определен:', movieId);
        showAlert('❌ Ошибка: не удалось получить ID фильма', 'error');
        return;
    }
    
    try {
        console.log('📥 Загрузка фильма #' + movieId);
        const response = await fetch(`http://localhost:8000/api/movies/${movieId}/`, {
            headers: { 'Authorization': `Bearer ${localStorage.getItem('auth_token')}` }
        });
        
        if (!response.ok) {
            throw new Error(`Ошибка ${response.status}`);
        }
        
        const movie = await response.json();
        console.log('✅ Фильм загружен:', movie);
        
        // Установка значений с обработкой null → пустая строка
        document.getElementById('movie-title').value = movie.title || '';
        document.getElementById('movie-description').value = movie.description || '';
        document.getElementById('movie-director').value = movie.director || '';
        document.getElementById('movie-duration').value = movie.duration_minutes || '';
        document.getElementById('movie-rating').value = movie.age_rating || '';
        
        // 🔑 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: преобразуем null в пустую строку для input[type="date"]
        document.getElementById('movie-release-date').value = movie.release_date || '';
        document.getElementById('movie-end-date').value = movie.end_date || '';
        
        document.getElementById('movie-form').dataset.movieId = movieId;
        document.querySelector('.form-group').scrollIntoView({ behavior: 'smooth' });
    } catch (error) {
        console.error('❌ Ошибка загрузки:', error);
        showAlert('❌ Ошибка загрузки фильма', 'error');
    }
}

// ===== РЕДАКТИРОВАНИЕ СЕАНСА =====
async function editSession(sessionId) {
    if (!sessionId || sessionId === 'undefined') {
        showAlert('❌ Ошибка: не удалось получить ID сеанса', 'error');
        return;
    }
    
    try {
        const response = await fetch(`http://localhost:8000/api/sessions/${sessionId}/`, {
            headers: { 'Authorization': `Bearer ${localStorage.getItem('auth_token')}` }
        });
        
        if (!response.ok) throw new Error(`Ошибка ${response.status}`);
        
        const session = await response.json();
        
        // Устанавливаем значения
        document.getElementById('session-movie').value = session.movie_id || session.movie?.id || '';
        document.getElementById('session-hall').value = session.hall_id || session.hall?.id || '';
        document.getElementById('session-start').value = formatDateTimeForInput(session.session_datetime);
        document.getElementById('session-end').value = formatDateTimeForInput(session.end_datetime);
        document.getElementById('session-price').value = session.price ? session.price : '100'; // Устанавливаем цену
        
        // Дополнительная проверка для выпадающих списков
        const movieSelect = document.getElementById('session-movie');
        const hallSelect = document.getElementById('session-hall');
        
        if (movieSelect) {
            const options = movieSelect.querySelectorAll('option');
            for (let i = 0; i < options.length; i++) {
                if (options[i].value == (session.movie_id || session.movie?.id)) {
                    options[i].selected = true;
                    break;
                }
            }
        }
        
        if (hallSelect) {
            const options = hallSelect.querySelectorAll('option');
            for (let i = 0; i < options.length; i++) {
                if (options[i].value == (session.hall_id || session.hall?.id)) {
                    options[i].selected = true;
                    break;
                }
            }
        }
        
        document.getElementById('session-form').dataset.sessionId = sessionId;
        document.querySelector('form').scrollIntoView({ behavior: 'smooth' });
    } catch (error) {
        console.error('❌ Ошибка:', error);
        showAlert('❌ Ошибка загрузки сеанса', 'error');
    }
}

// ===== УДАЛЕНИЕ =====
async function deleteMovie(movieId) {
    if (!movieId || movieId === 'undefined') {
        showAlert('❌ Ошибка: не удалось получить ID фильма', 'error');
        return;
    }
    
    if (!confirm('Удалить фильм?')) return;
    
    try {
        const response = await fetch(`http://localhost:8000/api/movies/${movieId}/`, {
            method: 'DELETE',
            headers: { 'Authorization': `Bearer ${localStorage.getItem('auth_token')}` }
        });
        
        if (!response.ok) throw new Error('Ошибка удаления');
        showAlert('✅ Фильм удален!', 'success');
        loadMovies();
    } catch (error) {
        console.error('❌ Ошибка:', error);
        showAlert(`❌ ${error.message}`, 'error');
    }
}

async function deleteSession(sessionId) {
    if (!sessionId || sessionId === 'undefined') {
        showAlert('❌ Ошибка: не удалось получить ID сеанса', 'error');
        return;
    }
    
    if (!confirm('Удалить сеанс?')) return;
    
    try {
        const response = await fetch(`http://localhost:8000/api/sessions/${sessionId}/`, {
            method: 'DELETE',
            headers: { 'Authorization': `Bearer ${localStorage.getItem('auth_token')}` }
        });
        
        if (!response.ok) throw new Error('Ошибка удаления');
        showAlert('✅ Сеанс удален!', 'success');
        loadSessions();
    } catch (error) {
        console.error('❌ Ошибка:', error);
        showAlert(`❌ ${error.message}`, 'error');
    }
}

// ===== УТИЛИТЫ =====
function formatDateTime(dateTimeString) {
    if (!dateTimeString) return '--';
    const date = new Date(dateTimeString);
    return date.toLocaleDateString('ru-RU', {
        year: 'numeric', month: 'long', day: 'numeric',
        hour: '2-digit', minute: '2-digit'
    });
}

function formatDateTimeForInput(dateTimeString) {
    if (!dateTimeString) return '';
    return new Date(dateTimeString).toISOString().slice(0, 16);
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function showAlert(message, type) {
    const alertDiv = document.createElement('div');
    alertDiv.className = `alert alert-${type}`;
    alertDiv.textContent = message;
    
    const content = document.querySelector('.admin-content');
    if (content) {
        content.insertBefore(alertDiv, content.firstChild);
        setTimeout(() => alertDiv.remove(), 4000);
    }
}

function resetMovieForm() {
    document.getElementById('movie-form').reset();
    delete document.getElementById('movie-form').dataset.movieId;
}

function resetSessionForm() {
    document.getElementById('session-form').reset();
    delete document.getElementById('session-form').dataset.sessionId;
}

// Export
window.switchAdminTab = switchAdminTab;
window.editMovie = editMovie;
window.deleteMovie = deleteMovie;
window.editSession = editSession;
window.deleteSession = deleteSession;
window.resetMovieForm = resetMovieForm;
window.resetSessionForm = resetSessionForm;