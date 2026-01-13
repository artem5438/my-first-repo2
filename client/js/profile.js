// ===== ИНИЦИАЛИЗАЦИЯ =====
document.addEventListener('DOMContentLoaded', () => {
    console.log('Profile: DOM загружен, инициализация...');
    
    const isAuth = localStorage.getItem('authtoken');
    if (!isAuth) {
        console.log('❌ Нет авторизации, редирект на login');
        window.location.href = 'login.html';
        return;
    }
    
    console.log('✅ Авторизация найдена');
    loadProfileData();
    loadUserTickets();
    setupAdminButton();
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
    const userId = localStorage.getItem('userid');
    
    console.log('Загрузка профиля для userId:', userId);
    
    if (!userId) {
        console.error('❌ userId не найден в localStorage');
        showToast('Ошибка: не найден идентификатор пользователя', 'error');
        return;
    }
    
    try {
        const profile = await api.getProfile(userId);
        console.log('✅ Профиль загружен:', profile);
        
        document.getElementById('profile-name').textContent = profile.fullname || profile.full_name || 'Неизвестно';
        document.getElementById('profile-email').textContent = profile.email || 'Не указана';
        document.getElementById('profile-phone').textContent = profile.phone || 'Не указан';
        document.getElementById('profile-birth').textContent = formatDate(profile.birthdate || profile.birth_date) || 'Не указана';
        
        const pointsData = await api.getPointsBalance(userId);
        console.log('✅ Баланс баллов:', pointsData);
        document.getElementById('profile-points').textContent = pointsData.currentpoints || pointsData.current_points || 0;
    } catch (error) {
        console.error('❌ Ошибка загрузки профиля:', error);
        showToast(`Ошибка загрузки профиля: ${error.message}`, 'error');
    }
}




// ===== ЗАГРУЗКА КУПЛЕННЫХ БИЛЕТОВ =====
async function loadUserTickets() {
    const userId = localStorage.getItem('userid');
    const ticketsContainer = document.getElementById('tickets-list');
    const ticketsLoading = document.getElementById('tickets-loading');
    const ticketsEmpty = document.getElementById('tickets-empty');
    const ticketsError = document.getElementById('tickets-error');
    
    console.log('Загрузка билетов для userId:', userId);
    
    if (!userId) {
        console.error('❌ userId не найден в localStorage');
        ticketsError.style.display = 'block';
        ticketsError.textContent = 'Ошибка: не найден идентификатор пользователя';
        return;
    }
    
    try {
        ticketsLoading.style.display = 'block';
        ticketsEmpty.style.display = 'none';
        ticketsError.style.display = 'none';
        ticketsContainer.innerHTML = '';
        
        const tickets = await api.getUserTickets(userId);
        console.log('✅ Билеты загружены:', tickets);
        
        ticketsLoading.style.display = 'none';
        
        if (!Array.isArray(tickets) || tickets.length === 0) {
            console.log('ℹ️ Билеты не найдены');
            ticketsEmpty.style.display = 'block';
            return;
        }
        
        const validTickets = tickets.filter(t => {
    const status = t.ticketstatus || t.ticket_status || 'valid';
    return status === 'valid' || status === 'used';
});
        
        if (validTickets.length === 0) {
            console.log('ℹ️ Нет действительных билетов');
            ticketsEmpty.style.display = 'block';
            return;
        }
        
        validTickets.forEach(ticket => {
            const ticketCard = createTicketCard(ticket);
            ticketsContainer.appendChild(ticketCard);
        });
        
        console.log(`✅ Отображено ${validTickets.length} билетов`);
    } catch (error) {
        console.error('❌ Ошибка загрузки билетов:', error);
        ticketsLoading.style.display = 'none';
        ticketsError.style.display = 'block';
        ticketsError.textContent = `Ошибка загрузки: ${error.message}`;
    }
}



// ===== СОЗДАНИЕ КАРТОЧКИ БИЛЕТА ✨ С СВЁРТЫВАЕМЫМ QR-КОДОМ ✨ =====
function createTicketCard(ticket) {
    const div = document.createElement('div');
    div.className = 'ticket-card';
    
    const ticketId = ticket.ticketid || ticket.ticket_id || ticket.id;
    const status = ticket.ticketstatus || ticket.ticket_status || 'valid';
    
    const statusClass = `status-${status}`;
    const statusText = {
        'valid': 'Действителен',
        'used': 'Использован',
        'cancelled': 'Отменен'
    }[status] || status;
    
    const movieTitle = ticket.movietitle || ticket.movie_title || ticket.movie_name || 'Неизвестный фильм';
    const sessionDateTime = ticket.sessiondatetime || ticket.session_datetime || ticket.sessiontime || ticket.session_time || new Date().toISOString();
    const seatNumber = ticket.seat || ticket.seatnumber || ticket.seat_number || 'N/A';
    const qrCode = ticket.qrcode || ticket.qr_code || ticket.ticketcode || '';
    
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
                        ${qrCode ? qrCode.substring(0, 12) + '...' : 'Нет QR'} ▶
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
        console.log('Отмена билета:', ticketId);
        const result = await api.cancelTicket(ticketId);
        console.log('✅ Билет отменен:', result);
        showToast(result.message || 'Билет отменен', 'success');
        
        setTimeout(() => {
            loadUserTickets();
            loadProfileData();
        }, 500);
    } catch (error) {
        console.error('❌ Ошибка отмены билета:', error);
        showToast(`Ошибка: ${error.message}`, 'error');
    }
}





// ===== ФОРМАТИРОВАНИЕ ДАТЫ И ВРЕМЕНИ =====
function formatDateTime(dateTimeString) {
    if (!dateTimeString) return '';
    try {
        const date = new Date(dateTimeString);
        const options = {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        };
        return date.toLocaleDateString('ru-RU', options);
    } catch (e) {
        return '';
    }
}




function formatDate(dateString) {
    if (!dateString) return '';
    try {
        const date = new Date(dateString);
        return date.toLocaleDateString('ru-RU', {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    } catch (e) {
        return '';
    }
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
        localStorage.clear();
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
    
    const isAuth = localStorage.getItem('authtoken');
    const userEmail = localStorage.getItem('useremail');
    
    console.log('🔍 Проверка админа на профиле:', { isAuth: !!isAuth, userEmail });
    
    // Проверяем по email "root@root.com"
    if (isAuth && userEmail === 'root@root.com') {
        adminBtn.style.display = 'block';
        console.log('✅ Админ-панель доступна на профиле');
    } else {
        adminBtn.style.display = 'none';
        console.log('❌ Админ-панель скрыта на профиле');
    }
}




// ===== ЭКСПОРТ ФУНКЦИЙ ГЛОБАЛЬНО =====
window.switchTab = switchTab;
window.cancelTicketHandler = cancelTicketHandler;
window.logout = logout;
window.showToast = showToast;
window.setupAdminButton = setupAdminButton;
