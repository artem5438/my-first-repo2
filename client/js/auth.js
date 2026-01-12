// ===== СКРИПТ АУТЕНТИФИКАЦИИ =====

// Инициализация при загрузке страницы
document.addEventListener('DOMContentLoaded', function() {
    console.log('Страница аутентификации загружена');
    
    // Настройка формы входа
    const loginForm = document.getElementById('login-form');
    if (loginForm) {
        console.log('Найдена форма входа');
        loginForm.addEventListener('submit', handleLoginSubmit);
    }
    
    // Настройка формы регистрации
    const registerForm = document.getElementById('register-form');
    if (registerForm) {
        console.log('Найдена форма регистрации');
        registerForm.addEventListener('submit', handleRegisterSubmit);
    }
    
    // Проверяем, авторизован ли пользователь (для страниц, где это необходимо)
    checkAuthRedirect();
});

// ===== ОБРАБОТЧИК ВХОДА =====
async function handleLoginSubmit(event) {
    event.preventDefault();
    console.log('Обработка входа...');
    
    const form = event.target;
    const email = form.querySelector('#email').value.trim();
    const password = form.querySelector('#password').value;
    
    const errorElement = document.getElementById('error-message');
    
    // Валидация
    if (!email || !password) {
        showError('Заполните все поля', errorElement);
        return;
    }
    
    try {
        // Показываем индикатор загрузки
        const submitBtn = form.querySelector('.btn-submit');
        const originalText = submitBtn.textContent;
        submitBtn.textContent = 'Вход...';
        submitBtn.disabled = true;
        
        // Выполняем вход
        const result = await api.login(email, password);
        console.log('Успешный вход:', result);
        
        // Показываем успешное сообщение
        showSuccess('Вход выполнен успешно! Перенаправление...', errorElement);
        
        // Перенаправляем через 1.5 секунды
        setTimeout(() => {
            window.location.href = 'index.html';
        }, 1500);
        
    } catch (error) {
        console.error('Ошибка входа:', error);
        showError(error.message || 'Ошибка входа. Проверьте email и пароль.', errorElement);
        
        // Восстанавливаем кнопку
        const submitBtn = form.querySelector('.btn-submit');
        submitBtn.textContent = 'Войти';
        submitBtn.disabled = false;
    }
}

// ===== ОБРАБОТЧИК РЕГИСТРАЦИИ =====
async function handleRegisterSubmit(event) {
    event.preventDefault();
    console.log('Обработка регистрации...');
    
    const form = event.target;
    const formData = new FormData(form);
    
    // Получаем значения полей
    const fullName = formData.get('full_name').trim();
    const email = formData.get('email').trim();
    const phone = formData.get('phone')?.trim() || '';
    const birthDate = formData.get('birth_date');
    const password = formData.get('password');
    const passwordConfirm = formData.get('password_confirm');
    
    const errorElement = document.getElementById('error-message');
    const successElement = document.getElementById('success-message');
    
    // Валидация
    if (!fullName || !email || !birthDate || !password || !passwordConfirm) {
        showError('Заполните все обязательные поля', errorElement);
        return;
    }
    
    if (password.length < 6) {
        showError('Пароль должен быть не менее 6 символов', errorElement);
        return;
    }
    
    if (password !== passwordConfirm) {
        showError('Пароли не совпадают', errorElement);
        return;
    }
    
    // Проверка email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
        showError('Введите корректный email адрес', errorElement);
        return;
    }
    
    try {
        // Показываем индикатор загрузки
        const submitBtn = form.querySelector('.btn-submit');
        const originalText = submitBtn.textContent;
        submitBtn.textContent = 'Регистрация...';
        submitBtn.disabled = true;
        
        // Подготавливаем данные
        const userData = {
            full_name: fullName,
            email: email,
            phone: phone,
            birth_date: birthDate,
            password: password
        };
        
        // Выполняем регистрацию
        const result = await api.register(userData);
        console.log('Успешная регистрация:', result);
        
        // Очищаем форму
        form.reset();
        
        // Показываем успешное сообщение
        if (successElement) {
            successElement.textContent = 'Регистрация успешна! Теперь вы можете войти.';
            successElement.style.display = 'block';
            errorElement.style.display = 'none';
        }
        
        // Перенаправляем на страницу входа через 3 секунды
        setTimeout(() => {
            window.location.href = 'login.html';
        }, 3000);
        
    } catch (error) {
        console.error('Ошибка регистрации:', error);
        showError(error.message || 'Ошибка регистрации. Попробуйте позже.', errorElement);
        
        // Восстанавливаем кнопку
        const submitBtn = form.querySelector('.btn-submit');
        submitBtn.textContent = 'Зарегистрироваться';
        submitBtn.disabled = false;
    }
}

// ===== ПРОВЕРКА РЕДИРЕКТА =====
function checkAuthRedirect() {
    // Если пользователь уже авторизован, перенаправляем с login/register страниц
    const token = localStorage.getItem('auth_token');
    const currentPage = window.location.pathname;
    
    if (token && (currentPage.includes('login.html') || currentPage.includes('register.html'))) {
        console.log('Пользователь уже авторизован, перенаправляем...');
        setTimeout(() => {
            window.location.href = 'index.html';
        }, 1000);
    }
}

// ===== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ =====
function showError(message, element) {
    if (!element) return;
    
    element.textContent = message;
    element.style.display = 'block';
    element.classList.remove('success');
    element.classList.add('error');
    
    // Автоматически скрываем через 5 секунд
    setTimeout(() => {
        element.style.display = 'none';
    }, 5000);
}

function showSuccess(message, element) {
    if (!element) return;
    
    element.textContent = message;
    element.style.display = 'block';
    element.classList.remove('error');
    element.classList.add('success');
    
    // Автоматически скрываем через 5 секунд
    setTimeout(() => {
        element.style.display = 'none';
    }, 5000);
}

// ===== ВЫХОД ИЗ СИСТЕМЫ =====
function logout() {
    if (confirm('Вы уверены, что хотите выйти?')) {
        api.logout();
        window.location.href = 'index.html';
    }
}

// ===== ГЛОБАЛЬНЫЕ ФУНКЦИИ =====
window.logout = logout;