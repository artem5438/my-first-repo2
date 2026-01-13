// ===== ИНИЦИАЛИЗАЦИЯ =====
document.addEventListener('DOMContentLoaded', () => {
    const isAuth = localStorage.getItem('auth_token');
    if (!isAuth) {
        window.location.href = 'login.html';
        return;
    }
    
    loadProfileData();
    loadUserTickets();
});

// ===== ПЕРЕКЛЮЧЕНИЕ ВКЛАДОК =====
function switchTab(tabName) {
    // Скрыть все вкладки
    document.querySelectorAll('.tab-content').forEach(tab => {
        tab.classList.remove('active');
    });
    
    // Удалить активный класс со всех кнопок
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    
    // Показать выбранную вкладку
    document.getElementById(`${tabName}-tab`).classList.add('active');
    
    // Добавить активный класс к нажатой кнопке
    event.target.classList.add('active');
}



// ===== ЗАГРУЗКА ДАННЫХ ПРОФИЛЯ =====
async function loadProfileData() {
    const userId = localStorage.getItem('user_id');
    
    try {
        const profile = await api.getProfile(userId);
        
        document.getElementById('profile-name').textContent = profile.full_name;
        document.getElementById('profile-email').textContent = profile.email;
        document.getElementById('profile-phone').textContent = profile.phone || 'Не указан';
        document.getElementById('profile-birth').textContent = formatDate(profile.birth_date);
        
        const pointsData = await api.getPointsBalance(userId);
        document.getElementById('profile-points').textContent = pointsData.current_points;
    } catch (error) {
        console.error('Error loading profile:', error);
        showToast(`Ошибка загрузки профиля: ${error.message}`, 'error');
    }
}



// ===== ЗАГРУЗКА КУПЛЕННЫХ БИЛЕТОВ =====
async function loadUserTickets() {
    const userId = localStorage.getItem('user_id');
    const ticketsContainer = document.getElementById('tickets-list');
    const ticketsLoading = document.getElementById('tickets-loading');
    const ticketsEmpty = document.getElementById('tickets-empty');
    const ticketsError = document.getElementById('tickets-error');
    
    try {
        ticketsLoading.style.display = 'block';
        ticketsEmpty.style.display = 'none';
        ticketsError.style.display = 'none';
        ticketsContainer.innerHTML = '';
        
        const tickets = await api.getUserTickets(userId);
        
        ticketsLoading.style.display = 'none';
        
        if (!Array.isArray(tickets) || tickets.length === 0) {
            ticketsEmpty.style.display = 'block';
            return;
        }
        
        const validTickets = tickets.filter(t => 
            t.ticket_status === 'valid' || 
            t.ticket_status === 'used' || 
            !t.ticket_status
        );
        
        if (validTickets.length === 0) {
            ticketsEmpty.style.display = 'block';
            return;
        }
        
        validTickets.forEach(ticket => {
            const ticketCard = createTicketCard(ticket);
            ticketsContainer.appendChild(ticketCard);
        });
    } catch (error) {
        console.error('Error loading tickets:', error);
        ticketsLoading.style.display = 'none';
        ticketsError.style.display = 'block';
        ticketsError.textContent = `Ошибка загрузки: ${error.message}`;
    }
}


// ===== СОЗДАНИЕ КАРТОЧКИ БИЛЕТА ✨ С СВЁРТЫВАЕМЫМ QR-КОДОМ ✨ =====
function createTicketCard(ticket) {
    const div = document.createElement('div');
    div.className = 'ticket-card';
    
    const ticketId = ticket.ticket_id || ticket.id;
    const status = ticket.ticket_status || 'valid';
    
    const statusClass = `status-${status}`;
    const statusText = {
        'valid': 'Действителен',
        'used': 'Использован',
        'cancelled': 'Отменен'
    }[status] || status;
    
    const movieTitle = ticket.movie_title || ticket.movie_name || 'Неизвестный фильм';
    const sessionDateTime = ticket.session_datetime || ticket.session_time || new Date().toISOString();
    const seatNumber = ticket.seat || ticket.seat_number || 'N/A';
    const qrCode = ticket.qr_code || ticket.ticket_code || '';
    
    const canCancel = status === 'valid';
    
    div.innerHTML = `
        <div class="card-info">
            <div class="card-title">${escapeHtml(movieTitle)}</div>
            <div class="card-meta">
                <div class="card-meta-item">
                    <span class="card-meta-label">📅 Дата & время:</span>
                    <span>${formatDateTime(sessionDateTime)}</span>
                </div>
                <div class="card-meta-item">
                    <span class="card-meta-label">🪑 Место:</span>
                    <span>${seatNumber}</span>
                </div>
                <div class="card-meta-item">
                    <span class="card-meta-label">🎫 Билет:</span>
                    <span 
                        class="ticket-qr-toggle" 
                        onclick="toggleQRCode(this)"
                        style="cursor: pointer; color: #1e3a8a; text-decoration: underline; font-weight: 500;"
                        data-ticket-id="${ticketId}"
                    >
                        ${qrCode.substring(0, 12)}... ▶
                    </span>
                </div>
            </div>
        </div>
        <div class="card-status">
            <span class="status-badge ${statusClass}">${statusText}</span>
        </div>
        <div class="card-actions">
            ${canCancel ? `
                <button class="btn-small btn-cancel" onclick="cancelTicketHandler(${ticketId})">
                    ❌ Отменить
                </button>
            ` : ''}
        </div>
        <!-- ✨ СВЁРТЫВАЕМЫЙ QR-КОД ✨ -->
        <div class="ticket-qr-container" style="display: none;" data-qr-code="${qrCode}">
            <div class="ticket-qr">
                <div class="qr-box">
                    ${qrCode ? `
                        <img 
                            src="http://localhost:8000/qr/${qrCode}/" 
                            alt="QR-код билета ${ticketId}"
                            class="ticket-qr-img"
                        >
                    ` : '<p>QR недоступен</p>'}
                </div>
                <p class="qr-label">QR-код</p>
                <p class="qr-hint">Покажите в кинотеатре</p>
            </div>
        </div>
    `;
    
    return div;
}



// ===== ПЕРЕКЛЮЧЕНИЕ QR-КОДА =====
function toggleQRCode(element) {
    const qrContainer = element.closest('.card-meta-item').parentElement.parentElement.parentElement.querySelector('.ticket-qr-container');
    
    if (!qrContainer) return;
    
    const isHidden = qrContainer.style.display === 'none';
    qrContainer.style.display = isHidden ? 'block' : 'none';
    
    // Изменяем стрелку
    element.textContent = element.textContent.split(' ')[0] + ' ' + (isHidden ? '▼' : '▶');
}

// Экспортируем функцию глобально
window.toggleQRCode = toggleQRCode;


// ===== ОТМЕНА БИЛЕТА =====
async function cancelTicketHandler(ticketId) {
    if (!confirm('Вы уверены? Это действие нельзя отменить.')) {
        return;
    }
    
    try {
        const result = await api.cancelTicket(ticketId);
        showToast(result.message || 'Билет отменен', 'success');
        
        setTimeout(() => {
            loadUserTickets();
            loadProfileData();
        }, 500);
    } catch (error) {
        console.error('Error canceling ticket:', error);
        showToast(`Ошибка: ${error.message}`, 'error');
    }
}




// ===== ФОРМАТИРОВАНИЕ ДАТЫ И ВРЕМЕНИ =====
function formatDateTime(dateTimeString) {
    const date = new Date(dateTimeString);
    const options = {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    };
    return date.toLocaleDateString('ru-RU', options);
}



function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('ru-RU', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });
}



// ===== ЭКРАНИРОВАНИЕ HTML =====
function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, m => map[m]);
}



// ===== ВЫХОД =====
function logout() {
    if (confirm('Вы уверены, что хотите выйти?')) {
        api.logout();
        window.location.href = 'index.html';
    }
}



// ===== ТОСТЕР (УВЕДОМЛЕНИЕ) =====
function showToast(message, type = 'info') {
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.textContent = message;
    
    document.body.appendChild(toast);
    
    setTimeout(() => {
        toast.classList.add('show');
    }, 10);
    
    setTimeout(() => {
        toast.classList.remove('show');
        setTimeout(() => {
            toast.remove();
        }, 300);
    }, 3000);
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