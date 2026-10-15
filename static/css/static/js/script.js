// ============================================
// CONFIGURACIÓN
// ============================================

const API_URL = window.location.origin;

// ============================================
// ELEMENTOS DOM
// ============================================

// Login
const loginForm = document.getElementById('loginForm');
const emailInput = document.getElementById('email');
const passwordInput = document.getElementById('password');
const btnLogin = document.getElementById('btnLogin');
const btnText = document.getElementById('btnText');
const btnLoader = document.getElementById('btnLoader');
const togglePassword = document.getElementById('togglePassword');

// Modales
const registerModal = document.getElementById('registerModal');
const forgotModal = document.getElementById('forgotModal');
const btnRegister = document.getElementById('btnRegister');
const closeModal = document.getElementById('closeModal');
const closeForgotModal = document.getElementById('closeForgotModal');
const forgotPassword = document.getElementById('forgotPassword');
const backToLogin = document.getElementById('backToLogin');

// Registro
const registerForm = document.getElementById('registerForm');
const regNombre = document.getElementById('regNombre');
const regCi = document.getElementById('regCi');
const regFechaNac = document.getElementById('regFechaNac');
const regEmail = document.getElementById('regEmail');
const regTelefono = document.getElementById('regTelefono');
const regPassword = document.getElementById('regPassword');
const btnRegisterSubmit = document.getElementById('btnRegisterSubmit');
const regBtnText = document.getElementById('regBtnText');
const regBtnLoader = document.getElementById('regBtnLoader');

// Recuperación
const forgotForm = document.getElementById('forgotForm');
const forgotEmail = document.getElementById('forgotEmail');
const btnForgotSubmit = document.getElementById('btnForgotSubmit');
const forgotBtnText = document.getElementById('forgotBtnText');
const forgotBtnLoader = document.getElementById('forgotBtnLoader');

// ============================================
// FUNCIONES DE UTILIDAD
// ============================================

function showMessage(containerId, message, type = 'error') {
    const container = document.getElementById(containerId);
    if (!container) return;

    const existing = container.querySelector('.message');
    if (existing) existing.remove();

    if (!message) return;

    const messageDiv = document.createElement('div');
    messageDiv.className = `message ${type}`;
    messageDiv.textContent = message;
    container.appendChild(messageDiv);

    if (type === 'success') {
        setTimeout(() => {
            if (messageDiv.parentNode) {
                messageDiv.style.opacity = '0';
                messageDiv.style.transition = 'opacity 0.3s';
                setTimeout(() => messageDiv.remove(), 300);
            }
        }, 5000);
    }
}

function setLoading(button, textElement, loaderElement, isLoading) {
    if (isLoading) {
        button.disabled = true;
        textElement.style.display = 'none';
        loaderElement.style.display = 'inline-block';
    } else {
        button.disabled = false;
        textElement.style.display = 'inline';
        loaderElement.style.display = 'none';
    }
}

// ============================================
// LOGIN
// ============================================

loginForm.addEventListener('submit', async (e) => {
    e.preventDefault();

    const email = emailInput.value.trim();
    const password = passwordInput.value;

    if (!email || !password) {
        showMessage('messageContainer', 'Por favor complete todos los campos', 'error');
        return;
    }

    setLoading(btnLogin, btnText, btnLoader, true);

    try {
        const response = await fetch('/api/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, password })
        });

        const data = await response.json();

        if (data.success) {
            showMessage('messageContainer', `¡Bienvenido ${data.user.nombre}!`, 'success');
            setTimeout(() => {
                window.location.href = '/dashboard';
            }, 1500);
        } else {
            showMessage('messageContainer', data.message || 'Error al iniciar sesión', 'error');
        }
    } catch (error) {
        showMessage('messageContainer', 'Error de conexión. Intente más tarde.', 'error');
        console.error('Login error:', error);
    } finally {
        setLoading(btnLogin, btnText, btnLoader, false);
    }
});

// ============================================
// REGISTRO (CON FOTOS Y FECHA DE NACIMIENTO)
// ============================================

btnRegister.addEventListener('click', () => {
    registerModal.classList.add('show');
    showMessage('registerMessage', '');
});

closeModal.addEventListener('click', () => {
    registerModal.classList.remove('show');
});

registerForm.addEventListener('submit', async (e) => {
    e.preventDefault();

    const nombre = regNombre.value.trim();
    const email = regEmail.value.trim();
    const telefono = regTelefono.value.trim();
    const numero_identidad = regCi.value.trim();
    const fecha_nacimiento = regFechaNac.value;
    const password = regPassword.value;

    // Obtener fotos en Base64 (de los img dentro del modal)
    const ciImage = document.getElementById('ciImage');
    const selfieImage = document.getElementById('selfieImage');
    
    const foto_ci = ciImage && ciImage.src.includes('base64') ? ciImage.src : '';
    const foto_selfie = selfieImage && selfieImage.src.includes('base64') ? selfieImage.src : '';

    // Validaciones
    if (!nombre || !email || !telefono || !numero_identidad || !password || !fecha_nacimiento) {
        showMessage('registerMessage', 'Todos los campos son obligatorios', 'error');
        return;
    }

    if (password.length < 6) {
        showMessage('registerMessage', 'La contraseña debe tener al menos 6 caracteres', 'error');
        return;
    }

    if (!foto_ci || !foto_selfie) {
        showMessage('registerMessage', 'Debe tomar la foto de su CI y su Selfie', 'error');
        return;
    }

    setLoading(btnRegisterSubmit, regBtnText, regBtnLoader, true);

    try {
        const response = await fetch('/api/register', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ 
                nombre, email, telefono, numero_identidad, password, fecha_nacimiento, foto_ci, foto_selfie 
            })
        });

        const data = await response.json();

        if (data.success) {
            showMessage('registerMessage', '¡Registro exitoso! Ya puedes iniciar sesión.', 'success');
            setTimeout(() => {
                registerModal.classList.remove('show');
                emailInput.value = email;
                showMessage('messageContainer', 'Cuenta creada. Inicia sesión con tus credenciales.', 'success');
            }, 2000);
        } else {
            showMessage('registerMessage', data.message || 'Error al registrarse', 'error');
        }
    } catch (error) {
        showMessage('registerMessage', 'Error de conexión. Intente más tarde.', 'error');
        console.error('Register error:', error);
    } finally {
        setLoading(btnRegisterSubmit, regBtnText, regBtnLoader, false);
    }
});

// Cerrar modal al hacer clic fuera
registerModal.addEventListener('click', (e) => {
    if (e.target === registerModal) {
        registerModal.classList.remove('show');
    }
});

// ============================================
// RECUPERACIÓN DE CONTRASEÑA
// ============================================

forgotPassword.addEventListener('click', () => {
    forgotModal.classList.add('show');
});

closeForgotModal.addEventListener('click', () => {
    forgotModal.classList.remove('show');
});

backToLogin.addEventListener('click', () => {
    forgotModal.classList.remove('show');
});

forgotForm.addEventListener('submit', async (e) => {
    e.preventDefault();

    const email = forgotEmail.value.trim();

    if (!email) {
        showMessage('forgotMessage', 'Por favor ingrese su correo electrónico', 'error');
        return;
    }

    setLoading(btnForgotSubmit, forgotBtnText, forgotBtnLoader, true);

    try {
        const response = await fetch('/api/forgot-password', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email })
        });

        const data = await response.json();

        if (data.success) {
            showMessage('forgotMessage', data.message, 'success');
            setTimeout(() => {
                forgotModal.classList.remove('show');
            }, 3000);
        } else {
            showMessage('forgotMessage', data.message || 'Error al enviar el correo', 'error');
        }
    } catch (error) {
        showMessage('forgotMessage', 'Error de conexión. Intente más tarde.', 'error');
        console.error('Forgot password error:', error);
    } finally {
        setLoading(btnForgotSubmit, forgotBtnText, forgotBtnLoader, false);
    }
});

forgotModal.addEventListener('click', (e) => {
    if (e.target === forgotModal) {
        forgotModal.classList.remove('show');
    }
});

// ============================================
// ENTER PARA ENVIAR FORMULARIOS
// ============================================

document.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
        if (registerModal.classList.contains('show')) {
            registerForm.dispatchEvent(new Event('submit'));
        }
        else if (forgotModal.classList.contains('show')) {
            forgotForm.dispatchEvent(new Event('submit'));
        }
    }
});

// ============================================
// VERIFICAR SESIÓN AL CARGAR
// ============================================

async function checkSession() {
    try {
        const response = await fetch('/api/check-session');
        const data = await response.json();
        
        if (data.authenticated) {
            window.location.href = '/dashboard';
        }
    } catch (error) {
        console.error('Session check error:', error);
    }
}

checkSession();

// ============================================
// ⭐ ANIMACIÓN DE TEYEVO LETRA POR LETRA ⭐
// ============================================

const logoText = document.querySelector('.logo-text');
if (logoText) {
    logoText.style.opacity = '0';
    
    const fullText = 'Teyevo';
    const redPart = 'Tey';
    const bluePart = 'evo';

    let currentIndex = 0;
    
    function typeWriter() {
        if (currentIndex <= fullText.length) {
            let currentText = fullText.substring(0, currentIndex);
            
            let redText = '';
            let blueText = '';
            
            if (currentIndex <= redPart.length) {
                redText = currentText;
                blueText = '';
            } else {
                redText = redPart;
                blueText = currentText.substring(redPart.length);
            }
            
            logoText.innerHTML = `<span class="logo-red">${redText}</span><span class="logo-blue">${blueText}</span>`;
            logoText.style.opacity = '1';
            logoText.style.borderRight = '3px solid #E31E24';
            
            currentIndex++;
            setTimeout(typeWriter, 150);
        } else {
            logoText.style.borderRight = 'none';
            const slogan = document.querySelector('.slogan');
            if (slogan) slogan.style.opacity = '1';
        }
    }
    
    window.addEventListener('load', typeWriter);
}