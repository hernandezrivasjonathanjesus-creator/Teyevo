import os
import re
import base64
import smtplib
import logging
import threading
import time
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime, timedelta, timezone, date
from functools import wraps

from flask import Flask, request, jsonify, render_template, session
from flask_cors import CORS
from dotenv import load_dotenv
from supabase import create_client, Client

# ============================================
# CONFIGURACIÓN INICIAL
# ============================================
load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.secret_key = os.getenv('SECRET_KEY', 'teyevo-secret-key-2024')
app.config['PERMANENT_SESSION_LIFETIME'] = timedelta(hours=24)
app.config['MAX_CONTENT_LENGTH'] = 10 * 1024 * 1024
app.config['SESSION_REFRESH_EACH_REQUEST'] = True

CORS(app, supports_credentials=True)

# ============================================
# SUPABASE - DOS CLIENTES
# ============================================
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_ANON_KEY = os.getenv('SUPABASE_ANON_KEY') or os.getenv('SUPABASE_KEY')
SUPABASE_SERVICE_KEY = os.getenv('SUPABASE_SERVICE_KEY')

if not SUPABASE_URL or not SUPABASE_ANON_KEY:
    raise RuntimeError("Faltan SUPABASE_URL o SUPABASE_ANON_KEY en el archivo .env")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)

supabase_admin: Client = (
    create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
    if SUPABASE_SERVICE_KEY else None
)

# ============================================
# CONFIG SMTP
# ============================================
SMTP_HOST = os.getenv('SMTP_HOST')
SMTP_PORT = int(os.getenv('SMTP_PORT', 587))
SMTP_USER = os.getenv('SMTP_USER')
SMTP_PASS = os.getenv('SMTP_PASS')
SMTP_FROM = os.getenv('SMTP_FROM', SMTP_USER)
SMTP_FROM_NAME = os.getenv('SMTP_FROM_NAME', 'Teyevo')

# ============================================
# CONSTANTES
# ============================================
EMAIL_REGEX = re.compile(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
CI_REGEX = re.compile(r'^\d{6,8}$')
PHONE_REGEX = re.compile(r'^\d{7,11}$')
DATE_REGEX = re.compile(r'^\d{4}-\d{2}-\d{2}$')
PASSWORD_MIN = 6

ROLES_VALIDOS = {'pasajero', 'conductor'}

ID_ROL_ADMIN = 1
ID_ROL_CONDUCTOR = 4
ID_ROL_PASAJERO = 5

ROL_MAP = {
    ID_ROL_ADMIN: 'admin',
    ID_ROL_CONDUCTOR: 'conductor',
    ID_ROL_PASAJERO: 'pasajero',
}

ESTADOS_VALIDOS_CONDUCTOR = ['disponible', 'en_viaje', 'descanso', 'desconectado']


# ============================================
# HELPERS DE VALIDACIÓN
# ============================================
def _safe_str(value, default=''):
    if value is None:
        return default
    return str(value).strip()


def validar_email(email: str) -> bool:
    return bool(EMAIL_REGEX.match(email or ''))


def validar_password(password: str) -> bool:
    return isinstance(password, str) and len(password) >= PASSWORD_MIN


def validar_ci(ci: str) -> bool:
    return bool(CI_REGEX.match(ci or ''))


def validar_telefono(tel: str) -> bool:
    return bool(PHONE_REGEX.match(re.sub(r'\D', '', tel or '')))


def validar_fecha(iso: str) -> bool:
    if not DATE_REGEX.match(iso or ''):
        return False
    try:
        datetime.strptime(iso, '%Y-%m-%d')
        return True
    except ValueError:
        return False


def decode_base64_image(data_url: str):
    if not data_url or ',' not in data_url:
        return None
    try:
        _, encoded = data_url.split(',', 1)
        return base64.b64decode(encoded)
    except Exception as e:
        logger.error(f"Error decodificando imagen: {e}")
        return None


def is_mobile(user_agent: str) -> bool:
    ua = (user_agent or '').lower()
    return any(k in ua for k in ('mobile', 'android', 'iphone', 'ipad'))


def detectar_navegador(user_agent: str) -> str:
    ua = (user_agent or '').lower()
    if 'edg' in ua: return 'Edge'
    if 'opr' in ua or 'opera' in ua: return 'Opera'
    if 'chrome' in ua: return 'Chrome'
    if 'firefox' in ua: return 'Firefox'
    if 'safari' in ua: return 'Safari'
    return 'Desconocido'


def detectar_so(user_agent: str) -> str:
    ua = (user_agent or '').lower()
    if 'windows' in ua: return 'Windows'
    if 'android' in ua: return 'Android'
    if 'iphone' in ua or 'ipad' in ua or 'ios' in ua: return 'iOS'
    if 'mac' in ua: return 'macOS'
    if 'linux' in ua: return 'Linux'
    return 'Desconocido'


def get_client_ip() -> str:
    forwarded = request.headers.get('X-Forwarded-For')
    if forwarded:
        return forwarded.split(',')[0].strip()
    return request.remote_addr or 'desconocida'


def formatear_tiempo_relativo(fecha_iso):
    if not fecha_iso:
        return '—'
    try:
        fecha = datetime.fromisoformat(fecha_iso.replace('Z', '+00:00'))
        ahora = datetime.now(timezone.utc) if fecha.tzinfo else datetime.now()
        diff = ahora - fecha
        segundos = diff.total_seconds()

        if segundos < 60:
            return 'hace unos segundos'
        elif segundos < 3600:
            return f'hace {int(segundos // 60)} min'
        elif segundos < 86400:
            return f'hace {int(segundos // 3600)} h'
        else:
            return f'hace {int(segundos // 86400)} días'
    except Exception:
        return '—'


# ============================================
# HELPERS DE BASE DE DATOS
# ============================================
def registrar_intento(email: str, exito: bool, motivo: str = None):
    try:
        supabase.table('intentos_acceso').insert({
            'email': email,
            'ip_origen': get_client_ip(),
            'exito': exito,
            'motivo_fallo': motivo,
            'user_agent': (request.headers.get('User-Agent') or '')[:500]
        }).execute()
    except Exception as e:
        logger.warning(f"No se pudo registrar intento: {e}")


def crear_sesion_activa(user_id, token: str, ip: str, user_agent: str):
    try:
        ahora = datetime.now(timezone.utc)
        supabase.table('sesiones_activas').insert({
            'id_usuario': user_id,
            'token_jti': token[:500] if token else None,
            'fecha_inicio': ahora.isoformat(),
            'fecha_expiracion': (ahora + timedelta(hours=24)).isoformat(),
            'fecha_ultima_actividad': ahora.isoformat(),
            'ip_origen': ip,
            'dispositivo': (user_agent or 'Desconocido')[:500],
            'navegador': detectar_navegador(user_agent),
            'sistema_operativo': detectar_so(user_agent),
            'es_movil': is_mobile(user_agent),
            'activa': True
        }).execute()
    except Exception as e:
        logger.warning(f"No se pudo crear sesión activa: {e}")


def registrar_log(user_id, accion: str, ip: str, detalles: dict = None):
    try:
        supabase.table('logs_actividad').insert({
            'id_usuario': user_id,
            'accion': accion,
            'ip_origen': ip,
            'detalles': detalles or {}
        }).execute()
    except Exception as e:
        logger.warning(f"No se pudo registrar log: {e}")


def crear_usuario_from_auth(auth_user):
    try:
        meta = auth_user.user_metadata or {}
        nuevo = {
            'auth_user_id': auth_user.id,
            'id_rol': ID_ROL_PASAJERO,
            'nombre_completo': meta.get('nombre_completo', 'Usuario'),
            'email': auth_user.email,
            'telefono': meta.get('telefono', '0000000000'),
            'numero_identidad': meta.get('numero_identidad', '00000000'),
            'fecha_nacimiento': meta.get('fecha_nacimiento', '1990-01-01'),
            'estado_cuenta': 'Activo',
            'metodo_autenticacion': 'Email/Password'
        }
        return supabase.table('usuarios').insert(nuevo).execute()
    except Exception as e:
        logger.error(f"Error creando usuario desde auth: {e}")
        return None


# ============================================
# ENVÍO DE CORREOS (SMTP)
# ============================================
def _send_email_sync(email: str, nombre: str) -> bool:
    if not all([SMTP_HOST, SMTP_USER, SMTP_PASS]):
        logger.warning("SMTP no configurado. Se omite envío de correo.")
        return False
    try:
        msg = MIMEMultipart('alternative')
        msg['Subject'] = '¡Bienvenido a Teyevo! 🚀'
        msg['From'] = f"{SMTP_FROM_NAME} <{SMTP_FROM}>"
        msg['To'] = email

        html = f"""
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;
                    padding: 30px; border: 2px solid #1A3C8A; border-radius: 12px;">
            <h1 style="color: #1e88e5; margin: 0 0 10px 0;">
                Tey<span style="color:#e53935;">evo</span>
            </h1>
            <h2 style="color: #E31E24;">¡Hola, {nombre}!</h2>
            <p style="font-size: 16px; color: #333;">
                Nos alegra que te unas a la familia <strong>Teyevo</strong>.
            </p>
            <p style="font-size: 16px; color: #333;">
                Tu cuenta ha sido creada exitosamente.
            </p>
            <p style="font-size: 16px; color: #333; font-style: italic;">A dónde quieras.</p>
            <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;">
            <p style="font-size: 12px; color: #999;">
                Este es un correo automático, por favor no respondas.
            </p>
        </div>
        """
        msg.attach(MIMEText(html, 'html', 'utf-8'))

        with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=15) as server:
            server.starttls()
            server.login(SMTP_USER, SMTP_PASS)
            server.sendmail(SMTP_FROM, [email], msg.as_string())

        logger.info(f"Correo de bienvenida enviado a {email}")
        return True
    except Exception as e:
        logger.error(f"Error enviando correo: {e}")
        return False


def send_welcome_email(email: str, nombre: str):
    threading.Thread(
        target=_send_email_sync,
        args=(email, nombre),
        daemon=True
    ).start()


# ============================================
# DECORADORES
# ============================================
def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if not session.get('user_id'):
            return jsonify({'success': False, 'message': 'No autenticado'}), 401
        return f(*args, **kwargs)
    return decorated


def admin_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if not session.get('user_id'):
            return jsonify({'success': False, 'message': 'No autenticado'}), 401

        try:
            user = supabase.table('usuarios')\
                .select('id_rol')\
                .eq('id_usuario', session.get('user_id'))\
                .single()\
                .execute()

            if not user.data or user.data.get('id_rol') != ID_ROL_ADMIN:
                return jsonify({
                    'success': False,
                    'message': 'Acceso denegado. Se requieren permisos de administrador.'
                }), 403
        except Exception as e:
            logger.warning(f"Error verificando admin: {e}")
            return jsonify({'success': False, 'message': 'Error verificando permisos'}), 500

        return f(*args, **kwargs)
    return decorated


# ============================================
# RUTAS PÚBLICAS
# ============================================
@app.route('/')
def index():
    return render_template('login.html')


@app.route('/api/login', methods=['POST'])
def login():
    try:
        data = request.get_json(silent=True) or {}
        email = _safe_str(data.get('email')).lower()
        password = data.get('password', '')
        role = _safe_str(data.get('role'), 'pasajero').lower()

        if not email or not password:
            return jsonify({'success': False, 'message': 'Complete todos los campos'}), 400

        if not validar_email(email):
            return jsonify({'success': False, 'message': 'Correo electrónico inválido'}), 400

        if role not in ROLES_VALIDOS:
            role = 'pasajero'

        try:
            auth_response = supabase.auth.sign_in_with_password({
                "email": email,
                "password": password
            })
        except Exception as auth_error:
            logger.warning(f"Error de autenticación para {email}: {auth_error}")
            registrar_intento(email, False, str(auth_error))
            return jsonify({'success': False, 'message': 'Credenciales incorrectas'}), 401

        if not auth_response.session or not auth_response.user:
            return jsonify({
                'success': False,
                'message': 'Debes confirmar tu correo electrónico antes de iniciar sesión.'
            }), 403

        try:
            user_query = supabase.table('usuarios')\
                .select('*')\
                .eq('auth_user_id', auth_response.user.id)\
                .execute()
        except Exception as db_error:
            logger.error(f"Error consultando tabla usuarios: {db_error}")
            return jsonify({
                'success': False,
                'message': 'Error consultando la base de datos. Verifica RLS.'
            }), 500

        logger.info(f"Usuarios encontrados: {len(user_query.data or [])}")

        if not user_query.data:
            logger.info("Usuario no encontrado en tabla, creando desde auth...")
            created = crear_usuario_from_auth(auth_response.user)
            if created and created.data:
                user_query = created
            else:
                return jsonify({
                    'success': False,
                    'message': 'Tu cuenta existe en Auth pero no en la base de datos.'
                }), 500

        user = user_query.data[0]
        logger.info(f"Usuario: {user.get('email')} | Rol: {user.get('id_rol')}")

        estado = user.get('estado_cuenta', 'Activo')
        if estado == 'Bloqueado':
            return jsonify({'success': False, 'message': 'Cuenta bloqueada.', 'blocked': True}), 403
        if estado == 'Suspendido':
            return jsonify({'success': False, 'message': 'Cuenta suspendida temporalmente.'}), 403

        registrar_intento(email, True)
        crear_sesion_activa(
            user['id_usuario'],
            auth_response.session.access_token,
            get_client_ip(),
            request.headers.get('User-Agent', '')
        )
        registrar_log(user['id_usuario'], 'LOGIN_EXITOSO',
                      get_client_ip(), {'email': email, 'role': role})

        session['user_id'] = str(user['id_usuario'])
        session['email'] = email
        session['nombre'] = user.get('nombre_completo', '')
        session['id_rol'] = user.get('id_rol')
        session.permanent = True

        id_rol = user.get('id_rol')
        tipo_usuario = ROL_MAP.get(id_rol, 'pasajero')

        if id_rol == ID_ROL_ADMIN:
            redirect_to = '/dashboard'
        elif id_rol == ID_ROL_CONDUCTOR:
            redirect_to = '/conductor'
        else:
            redirect_to = '/pasajero'

        return jsonify({
            'success': True,
            'message': 'Inicio de sesión exitoso',
            'user': {
                'id': user['id_usuario'],
                'nombre': user.get('nombre_completo', ''),
                'email': user.get('email', email),
                'rol': id_rol,
                'tipo': tipo_usuario,
                'role': role
            },
            'redirect_to': redirect_to,
            'access_token': auth_response.session.access_token
        })

    except Exception:
        logger.exception("Error en login")
        return jsonify({'success': False, 'message': 'Error en el servidor.'}), 500


@app.route('/api/register', methods=['POST'])
def register():
    try:
        data = request.get_json(silent=True) or {}

        nombre = _safe_str(data.get('nombre'))
        email = _safe_str(data.get('email')).lower()
        password = data.get('password', '')
        telefono = re.sub(r'\D', '', _safe_str(data.get('telefono')))
        numero_identidad = re.sub(r'\D', '', _safe_str(data.get('numero_identidad')))
        fecha_nacimiento = _safe_str(data.get('fecha_nacimiento'), '1990-01-01')
        foto_ci = data.get('foto_ci', '')
        foto_selfie = data.get('foto_selfie', '')
        tipo_registro = _safe_str(data.get('tipo'), 'pasajero').lower()

        if not all([nombre, email, password, telefono, numero_identidad]):
            return jsonify({'success': False, 'message': 'Todos los campos son obligatorios'}), 400

        if not validar_email(email):
            return jsonify({'success': False, 'message': 'Correo electrónico inválido'}), 400

        if not validar_password(password):
            return jsonify({
                'success': False,
                'message': f'La contraseña debe tener al menos {PASSWORD_MIN} caracteres'
            }), 400

        if not validar_ci(numero_identidad):
            return jsonify({'success': False, 'message': 'Cédula inválida (6-8 dígitos)'}), 400

        if not validar_telefono(telefono):
            return jsonify({'success': False, 'message': 'Teléfono inválido'}), 400

        if not validar_fecha(fecha_nacimiento):
            return jsonify({'success': False, 'message': 'Fecha de nacimiento inválida'}), 400

        if not foto_ci or not foto_selfie:
            return jsonify({'success': False, 'message': 'Debes subir las fotos de verificación'}), 400

        existente = supabase.table('usuarios')\
            .select('id_usuario')\
            .eq('email', email)\
            .limit(1)\
            .execute()
        if existente.data:
            return jsonify({'success': False, 'message': 'El email ya está registrado'}), 409

        cedula_existente = supabase.table('usuarios')\
            .select('id_usuario')\
            .eq('numero_identidad', numero_identidad)\
            .limit(1)\
            .execute()
        if cedula_existente.data:
            return jsonify({'success': False, 'message': 'La cédula ya está registrada'}), 409

        try:
            auth_response = supabase.auth.sign_up({
                "email": email,
                "password": password,
                "options": {
                    "data": {
                        "nombre_completo": nombre,
                        "telefono": telefono,
                        "numero_identidad": numero_identidad,
                        "fecha_nacimiento": fecha_nacimiento
                    }
                }
            })
        except Exception as e:
            logger.error(f"Error sign_up: {e}")
            return jsonify({'success': False, 'message': 'Error al crear cuenta. Verifica los datos.'}), 400

        if not auth_response.user:
            return jsonify({'success': False, 'message': 'Error creando cuenta de autenticación'}), 500

        auth_user_id = auth_response.user.id
        id_rol = ID_ROL_CONDUCTOR if tipo_registro == 'conductor' else ID_ROL_PASAJERO

        nuevo_usuario = {
            'auth_user_id': auth_user_id,
            'id_rol': id_rol,
            'nombre_completo': nombre,
            'email': email,
            'telefono': telefono,
            'numero_identidad': numero_identidad,
            'fecha_nacimiento': fecha_nacimiento,
            'estado_cuenta': 'Pendiente' if tipo_registro == 'conductor' else 'Activo',
            'metodo_autenticacion': 'Email/Password'
        }

        result = supabase.table('usuarios').insert(nuevo_usuario).execute()

        if not result.data:
            if supabase_admin:
                try:
                    supabase_admin.auth.admin.delete_user(auth_user_id)
                except Exception as rollback_err:
                    logger.error(f"Rollback fallido: {rollback_err}")
            return jsonify({'success': False, 'message': 'Error creando usuario en BD'}), 500

        id_usuario = result.data[0]['id_usuario']

        fotos_ok = True
        try:
            ci_bytes = decode_base64_image(foto_ci)
            selfie_bytes = decode_base64_image(foto_selfie)

            if ci_bytes:
                supabase.storage.from_('identificaciones').upload(
                    path=f'{auth_user_id}/ci.jpg',
                    file=ci_bytes,
                    file_options={"content-type": "image/jpeg", "upsert": "true"}
                )
            if selfie_bytes:
                supabase.storage.from_('identificaciones').upload(
                    path=f'{auth_user_id}/selfie.jpg',
                    file=selfie_bytes,
                    file_options={"content-type": "image/jpeg", "upsert": "true"}
                )
        except Exception as e:
            logger.error(f"Error subiendo fotos: {e}")
            fotos_ok = False

        try:
            supabase.table('billetera_puntos').insert({
                'id_usuario': id_usuario,
                'saldo_puntos': 0,
                'puntos_acumulados_vida': 0,
                'puntos_canjeados': 0
            }).execute()

            supabase.table('preferencias_pasajero').insert({
                'id_usuario': id_usuario
            }).execute()
        except Exception as e:
            logger.warning(f"Error creando billetera/preferencias: {e}")

        send_welcome_email(email, nombre)

        return jsonify({
            'success': True,
            'message': 'Usuario registrado exitosamente.' + (
                '' if fotos_ok else ' (Algunas fotos no se pudieron subir)'
            ),
            'user': {
                'id': id_usuario,
                'nombre': nombre,
                'email': email,
                'tipo': tipo_registro
            }
        }), 201

    except Exception:
        logger.exception("Error en registro")
        return jsonify({'success': False, 'message': 'Error en el servidor.'}), 500


@app.route('/api/logout', methods=['POST'])
def logout():
    try:
        user_id = session.get('user_id')
        if user_id:
            try:
                supabase.table('sesiones_activas')\
                    .update({'activa': False})\
                    .eq('id_usuario', user_id)\
                    .eq('activa', True)\
                    .execute()
                registrar_log(user_id, 'LOGOUT', get_client_ip(), {'user_id': user_id})
            except Exception as e:
                logger.warning(f"Error cerrando sesión en BD: {e}")

        session.clear()
        return jsonify({'success': True, 'message': 'Sesión cerrada'})
    except Exception:
        logger.exception("Error en logout")
        return jsonify({'success': False, 'message': 'Error al cerrar sesión'}), 500


@app.route('/api/forgot-password', methods=['POST'])
def forgot_password():
    try:
        data = request.get_json(silent=True) or {}
        email = _safe_str(data.get('email')).lower()

        if not email or not validar_email(email):
            return jsonify({'success': False, 'message': 'Email inválido'}), 400

        try:
            supabase.auth.reset_password_for_email(
                email,
                {"redirect_to": os.getenv('APP_URL', 'http://localhost:5000')}
            )
        except Exception as e:
            logger.warning(f"reset_password: {e}")

        return jsonify({
            'success': True,
            'message': 'Si el correo existe, recibirás un enlace de recuperación.'
        })
    except Exception:
        logger.exception("Error en forgot_password")
        return jsonify({'success': False, 'message': 'Error en el servidor.'}), 500


@app.route('/api/check-session', methods=['GET'])
def check_session():
    try:
        user_id = session.get('user_id')
        if not user_id:
            return jsonify({'authenticated': False})

        sesion = supabase.table('sesiones_activas')\
            .select('id_sesion')\
            .eq('id_usuario', user_id)\
            .eq('activa', True)\
            .limit(1)\
            .execute()

        if not sesion.data:
            session.clear()
            return jsonify({'authenticated': False})

        id_rol = session.get('id_rol')
        return jsonify({
            'authenticated': True,
            'user': {
                'id': session.get('user_id'),
                'nombre': session.get('nombre'),
                'email': session.get('email'),
                'id_rol': id_rol,
                'tipo': ROL_MAP.get(id_rol, 'desconocido')
            }
        })
    except Exception as e:
        logger.exception("Error en check_session")
        return jsonify({'authenticated': False, 'error': str(e)}), 500


# ============================================
# TARIFAS PÚBLICAS
# ============================================
@app.route('/api/tariffs', methods=['GET'])
def public_tariffs():
    try:
        result = supabase.table('tarifas')\
            .select('*')\
            .eq('activa', True)\
            .order('tipo_servicio')\
            .execute()
        return jsonify({'success': True, 'tariffs': result.data or []})
    except Exception as e:
        logger.exception("Error en public_tariffs")
        return jsonify({'success': False, 'message': str(e)}), 500


# ============================================
# ESTADOS DE VENEZUELA
# ============================================
@app.route('/api/estados', methods=['GET'])
def obtener_estados():
    """Lista de los 23 estados de Venezuela + Distrito Capital"""
    try:
        result = supabase.table('estados_venezuela')\
            .select('*')\
            .order('nombre')\
            .execute()
        return jsonify({'success': True, 'estados': result.data or []})
    except Exception as e:
        logger.warning(f"Error obteniendo estados (¿existe tabla estados_venezuela?): {e}")
        return jsonify({
            'success': True,
            'estados': [],
            'warning': 'Tabla estados_venezuela no encontrada'
        })


# ============================================
# USUARIO LOGUEADO
# ============================================
@app.route('/api/me', methods=['GET'])
@login_required
def get_me():
    try:
        user_id = session.get('user_id')

        user = supabase.table('usuarios')\
            .select('*')\
            .eq('id_usuario', user_id)\
            .single()\
            .execute()

        if not user.data:
            return jsonify({'success': False, 'message': 'Usuario no encontrado'}), 404

        user_data = user.data
        user_data['tipo'] = ROL_MAP.get(user_data.get('id_rol'), 'desconocido')

        if user_data.get('id_rol') == ID_ROL_CONDUCTOR:
            vehiculo = supabase.table('vehiculos')\
                .select('*')\
                .eq('id_conductor', user_id)\
                .execute()
            user_data['vehiculo'] = vehiculo.data[0] if vehiculo.data else None

        return jsonify({'success': True, 'user': user_data})
    except Exception as e:
        logger.exception("Error en get_me")
        return jsonify({'success': False, 'message': str(e)}), 500


# ============================================
# PANELES
# ============================================
@app.route('/conductor')
@login_required
def panel_conductor():
    return render_template('conductor.html')


@app.route('/pasajero')
@login_required
def panel_pasajero():
    return render_template('pasajero.html')


@app.route('/dashboard')
def dashboard():
    return render_template('dashboard.html')


# ============================================
# VEHÍCULOS DEL CONDUCTOR
# ============================================
@app.route('/api/vehicles', methods=['POST'])
@login_required
def create_vehicle():
    try:
        user_id = session.get('user_id')

        user = supabase.table('usuarios')\
            .select('id_rol')\
            .eq('id_usuario', user_id)\
            .single()\
            .execute()

        if not user.data or user.data.get('id_rol') != ID_ROL_CONDUCTOR:
            return jsonify({'success': False, 'message': 'Solo conductores pueden registrar vehículos'}), 403

        data = request.get_json(silent=True) or {}

        fotos_paths = {}
        for campo in ['foto_frente', 'foto_lateral', 'foto_interior', 'foto_placa']:
            foto_data = data.get(campo, '')
            if foto_data and ',' in foto_data:
                try:
                    img_bytes = decode_base64_image(foto_data)
                    if img_bytes:
                        path = f'{user_id}/{campo}.jpg'
                        supabase.storage.from_('vehiculos').upload(
                            path=path,
                            file=img_bytes,
                            file_options={"content-type": "image/jpeg", "upsert": "true"}
                        )
                        fotos_paths[campo] = path
                except Exception as e:
                    logger.warning(f"Error subiendo {campo}: {e}")

        vehiculo = {
            'id_conductor': user_id,
            'marca': _safe_str(data.get('marca')),
            'modelo': _safe_str(data.get('modelo')),
            'anio': int(data.get('anio', 2020)),
            'color': _safe_str(data.get('color')),
            'placa': _safe_str(data.get('placa')).upper(),
            'tipo_servicio': _safe_str(data.get('tipo_servicio'), 'Taxi Urbano'),
            'capacidad_pasajeros': int(data.get('capacidad_pasajeros', 4)),
            'estado_vehiculo': 'Pendiente',
            **fotos_paths
        }

        result = supabase.table('vehiculos').insert(vehiculo).execute()

        return jsonify({
            'success': True,
            'message': 'Vehículo registrado. Esperando aprobación.',
            'vehicle': result.data[0] if result.data else None
        }), 201
    except Exception as e:
        logger.exception("Error creando vehículo")
        return jsonify({'success': False, 'message': str(e)}), 500


# ============================================
# GPS - UBICACIONES
# ============================================
@app.route('/api/conductor/actualizar-ubicacion', methods=['POST'])
@login_required
def actualizar_ubicacion():
    try:
        user_id = session.get('user_id')

        user = supabase.table('usuarios')\
            .select('id_rol')\
            .eq('id_usuario', user_id)\
            .single()\
            .execute()

        if not user.data or user.data.get('id_rol') != ID_ROL_CONDUCTOR:
            return jsonify({'success': False, 'message': 'Solo conductores'}), 403

        data = request.get_json(silent=True) or {}
        lat = data.get('latitud')
        lng = data.get('longitud')

        if lat is None or lng is None:
            return jsonify({'success': False, 'message': 'Faltan coordenadas'}), 400

        estado = data.get('estado', 'disponible')
        if estado not in ESTADOS_VALIDOS_CONDUCTOR:
            estado = 'disponible'

        ubicacion = {
            'id_conductor': user_id,
            'latitud': float(lat),
            'longitud': float(lng),
            'precision_metros': float(data.get('precision', 0) or 0),
            'velocidad_kmh': float(data.get('velocidad', 0) or 0),
            'direccion_grados': int(data.get('direccion', 0) or 0),
            'bateria_porcentaje': int(data.get('bateria', 0) or 0),
            'estado': estado,
            'fecha_actualizacion': datetime.now(timezone.utc).isoformat()
        }

        if data.get('estado_venezuela'):
            ubicacion['estado_venezuela'] = data['estado_venezuela']

        existing = supabase.table('ubicaciones_conductores')\
            .select('id_ubicacion')\
            .eq('id_conductor', user_id)\
            .execute()

        if existing.data:
            supabase.table('ubicaciones_conductores')\
                .update(ubicacion)\
                .eq('id_conductor', user_id)\
                .execute()
        else:
            supabase.table('ubicaciones_conductores').insert(ubicacion).execute()

        return jsonify({
            'success': True,
            'message': 'Ubicación actualizada',
            'timestamp': ubicacion['fecha_actualizacion']
        })
    except Exception as e:
        logger.exception("Error actualizando ubicación")
        return jsonify({'success': False, 'message': str(e)}), 500


@app.route('/api/conductor/actualizar-estado', methods=['POST'])
@login_required
def actualizar_estado_conductor():
    """Actualiza SOLO el estado del conductor (sin coordenadas)"""
    try:
        user_id = session.get('user_id')

        user = supabase.table('usuarios')\
            .select('id_rol')\
            .eq('id_usuario', user_id)\
            .single()\
            .execute()

        if not user.data or user.data.get('id_rol') != ID_ROL_CONDUCTOR:
            return jsonify({'success': False, 'message': 'Solo conductores'}), 403

        data = request.get_json(silent=True) or {}
        estado = _safe_str(data.get('estado'), 'desconectado')

        if estado not in ESTADOS_VALIDOS_CONDUCTOR:
            estado = 'desconectado'

        existing = supabase.table('ubicaciones_conductores')\
            .select('id_ubicacion')\
            .eq('id_conductor', user_id)\
            .execute()

        if existing.data:
            supabase.table('ubicaciones_conductores')\
                .update({
                    'estado': estado,
                    'fecha_actualizacion': datetime.now(timezone.utc).isoformat()
                })\
                .eq('id_conductor', user_id)\
                .execute()
        else:
            supabase.table('ubicaciones_conductores').insert({
                'id_conductor': user_id,
                'latitud': 10.4806,
                'longitud': -66.9036,
                'estado': estado,
                'fecha_actualizacion': datetime.now(timezone.utc).isoformat()
            }).execute()

        return jsonify({'success': True, 'estado': estado})
    except Exception as e:
        logger.exception("Error actualizando estado")
        return jsonify({'success': False, 'message': str(e)}), 500


@app.route('/api/conductor/actualizar-estado-venezuela', methods=['POST'])
@login_required
def actualizar_estado_venezuela():
    try:
        user_id = session.get('user_id')

        user = supabase.table('usuarios')\
            .select('id_rol')\
            .eq('id_usuario', user_id)\
            .single()\
            .execute()

        if not user.data or user.data.get('id_rol') != ID_ROL_CONDUCTOR:
            return jsonify({'success': False, 'message': 'Solo conductores'}), 403

        data = request.get_json(silent=True) or {}
        codigo_estado = _safe_str(data.get('estado')).upper()
        ciudad = _safe_str(data.get('ciudad'))

        if not codigo_estado:
            return jsonify({'success': False, 'message': 'Falta el código del estado'}), 400

        try:
            estado = supabase.table('estados_venezuela')\
                .select('nombre, capital')\
                .eq('codigo', codigo_estado)\
                .single()\
                .execute()
        except Exception:
            estado = None

        if not estado or not estado.data:
            return jsonify({'success': False, 'message': 'Estado no válido'}), 400

        supabase.table('usuarios')\
            .update({
                'estado_operacion': codigo_estado,
                'ciudad_operacion': ciudad or estado.data.get('capital')
            })\
            .eq('id_usuario', user_id)\
            .execute()

        try:
            supabase.table('ubicaciones_conductores')\
                .update({
                    'estado_venezuela': codigo_estado,
                    'fecha_actualizacion': datetime.now(timezone.utc).isoformat()
                })\
                .eq('id_conductor', user_id)\
                .execute()
        except Exception as e:
            logger.warning(f"No se pudo actualizar estado_venezuela en ubicaciones: {e}")

        return jsonify({
            'success': True,
            'message': f'Ubicación actualizada a {estado.data.get("nombre")}',
            'estado': codigo_estado,
            'nombre': estado.data.get('nombre')
        })
    except Exception as e:
        logger.exception("Error actualizando estado de Venezuela")
        return jsonify({'success': False, 'message': str(e)}), 500


# ============================================
# DASHBOARD ADMIN - STATS
# ============================================
@app.route('/api/admin/stats', methods=['GET'])
@admin_required
def admin_stats():
    try:
        hoy = date.today().isoformat()

        total_usuarios = supabase.table('usuarios')\
            .select('*', count='exact')\
            .execute()

        conductores = supabase.table('usuarios')\
            .select('*', count='exact')\
            .eq('id_rol', ID_ROL_CONDUCTOR)\
            .eq('estado_cuenta', 'Activo')\
            .execute()

        try:
            viajes_hoy = supabase.table('viajes')\
                .select('*', count='exact')\
                .gte('fecha', hoy)\
                .execute()
            total_viajes_hoy = viajes_hoy.count or 0
        except Exception:
            total_viajes_hoy = 0

        try:
            viajes_data = supabase.table('viajes')\
                .select('tarifa')\
                .gte('fecha', hoy)\
                .eq('estado', 'Completado')\
                .execute()
            ingresos = sum(float(v.get('tarifa', 0) or 0) for v in (viajes_data.data or []))
        except Exception:
            ingresos = 0

        try:
            logs = supabase.table('logs_actividad')\
                .select('*')\
                .order('fecha', desc=True)\
                .limit(10)\
                .execute()
        except Exception:
            logs = None

        actividad = []
        iconos = {
            'LOGIN_EXITOSO': '🔓', 'LOGOUT': '🔒', 'REGISTRO': '👤',
            'VIAJE_COMPLETADO': '🚗', 'PAGO': '💰', 'USUARIO_BLOQUEADO': '🚫',
            'CONDUCTOR_APROBADO': '✅', 'CONDUCTOR_RECHAZADO': '❌',
            'VEHICULO_APROBADO': '🚙', 'VEHICULO_RECHAZADO': '🚫'
        }
        if logs:
            for log in (logs.data or []):
                accion = log.get('accion', '')
                actividad.append({
                    'icon': iconos.get(accion, '📌'),
                    'title': accion.replace('_', ' ').title(),
                    'time': formatear_tiempo_relativo(log.get('fecha'))
                })

        return jsonify({
            'success': True,
            'stats': {
                'total_usuarios': total_usuarios.count or 0,
                'conductores_activos': conductores.count or 0,
                'viajes_hoy': total_viajes_hoy,
                'ingresos_hoy': ingresos,
                'trend_usuarios': 12,
                'trend_conductores': 5,
                'trend_viajes': 18,
                'trend_ingresos': 8,
                'viajes_semana': [12, 19, 15, 22, 28, 24, 31],
                'distribucion_servicios': [
                    {'label': 'Viajes urbanos', 'value': 45},
                    {'label': 'Delivery', 'value': 30},
                    {'label': 'Envíos', 'value': 15},
                    {'label': 'Especiales', 'value': 10}
                ],
                'actividad_reciente': actividad
            }
        })
    except Exception as e:
        logger.exception("Error en admin_stats")
        return jsonify({'success': False, 'message': 'Error cargando estadísticas'}), 500


# ============================================
# ADMIN - USUARIOS
# ============================================
@app.route('/api/admin/users', methods=['GET'])
@admin_required
def admin_users():
    try:
        query = supabase.table('usuarios').select('*')

        estado = request.args.get('status')
        if estado:
            query = query.eq('estado_cuenta', estado)

        busqueda = request.args.get('q')
        if busqueda:
            query = query.or_(f'nombre_completo.ilike.%{busqueda}%,email.ilike.%{busqueda}%')

        result = query.limit(100).execute()

        return jsonify({'success': True, 'users': result.data or []})
    except Exception as e:
        logger.exception("Error en admin_users")
        return jsonify({'success': False, 'message': 'Error cargando usuarios'}), 500


@app.route('/api/admin/users/<int:user_id>', methods=['GET'])
@admin_required
def admin_user_detail(user_id):
    try:
        result = supabase.table('usuarios')\
            .select('*')\
            .eq('id_usuario', user_id)\
            .single()\
            .execute()

        return jsonify({'success': True, 'user': result.data})
    except Exception:
        return jsonify({'success': False, 'message': 'Usuario no encontrado'}), 404


@app.route('/api/admin/users/<int:user_id>/block', methods=['POST'])
@admin_required
def admin_block_user(user_id):
    try:
        supabase.table('usuarios')\
            .update({'estado_cuenta': 'Bloqueado'})\
            .eq('id_usuario', user_id)\
            .execute()

        registrar_log(user_id, 'USUARIO_BLOQUEADO', get_client_ip())

        return jsonify({'success': True, 'message': 'Usuario bloqueado'})
    except Exception as e:
        logger.exception("Error bloqueando usuario")
        return jsonify({'success': False, 'message': 'Error bloqueando usuario'}), 500


# ============================================
# ADMIN - CONDUCTORES
# ============================================
@app.route('/api/admin/drivers', methods=['GET'])
@admin_required
def admin_drivers():
    try:
        estado = request.args.get('status', 'pending')

        estado_map = {
            'pending': 'Pendiente',
            'approved': 'Activo',
            'rejected': 'Rechazado'
        }
        estado_db = estado_map.get(estado, 'Pendiente')

        result = supabase.table('usuarios')\
            .select('*')\
            .eq('id_rol', ID_ROL_CONDUCTOR)\
            .eq('estado_cuenta', estado_db)\
            .execute()

        return jsonify({'success': True, 'drivers': result.data or []})
    except Exception as e:
        logger.exception("Error en admin_drivers")
        return jsonify({'success': False, 'message': 'Error cargando conductores'}), 500


@app.route('/api/admin/drivers/<int:user_id>/approve', methods=['POST'])
@admin_required
def admin_approve_driver(user_id):
    try:
        supabase.table('usuarios')\
            .update({'estado_cuenta': 'Activo'})\
            .eq('id_usuario', user_id)\
            .execute()
        registrar_log(user_id, 'CONDUCTOR_APROBADO', get_client_ip())
        return jsonify({'success': True})
    except Exception:
        logger.exception("Error aprobando conductor")
        return jsonify({'success': False, 'message': 'Error aprobando conductor'}), 500


@app.route('/api/admin/drivers/<int:user_id>/reject', methods=['POST'])
@admin_required
def admin_reject_driver(user_id):
    try:
        supabase.table('usuarios')\
            .update({'estado_cuenta': 'Rechazado'})\
            .eq('id_usuario', user_id)\
            .execute()
        registrar_log(user_id, 'CONDUCTOR_RECHAZADO', get_client_ip())
        return jsonify({'success': True})
    except Exception:
        logger.exception("Error rechazando conductor")
        return jsonify({'success': False, 'message': 'Error rechazando conductor'}), 500


# ============================================
# ADMIN - UBICACIONES GPS
# ============================================
@app.route('/api/admin/drivers/locations', methods=['GET'])
@admin_required
def admin_driver_locations():
    try:
        result = supabase.table('ubicaciones_conductores')\
            .select('*, usuarios(nombre_completo, email, telefono)')\
            .order('fecha_actualizacion', desc=True)\
            .execute()

        conductores = []
        for u in (result.data or []):
            usuarios = u.get('usuarios', {}) or {}
            conductores.append({
                'id_conductor': u['id_conductor'],
                'nombre': usuarios.get('nombre_completo', 'Conductor'),
                'email': usuarios.get('email', ''),
                'telefono': usuarios.get('telefono', ''),
                'calificacion': 5.0,
                'total_viajes': 0,
                'latitud': float(u['latitud']),
                'longitud': float(u['longitud']),
                'precision': float(u.get('precision_metros', 0) or 0),
                'velocidad': float(u.get('velocidad_kmh', 0) or 0),
                'direccion': u.get('direccion_grados', 0),
                'bateria': u.get('bateria_porcentaje', 0),
                'estado': u.get('estado', 'desconectado'),
                'estado_venezuela': u.get('estado_venezuela'),
                'ultima_actualizacion': u.get('fecha_actualizacion')
            })

        return jsonify({
            'success': True,
            'total': len(conductores),
            'conductores': conductores
        })
    except Exception as e:
        logger.exception("Error obteniendo ubicaciones")
        return jsonify({'success': False, 'message': str(e)}), 500


# ============================================
# ADMIN - VIAJES
# ============================================
@app.route('/api/admin/trips', methods=['GET'])
@admin_required
def admin_trips():
    try:
        result = supabase.table('viajes')\
            .select('*')\
            .order('fecha', desc=True)\
            .limit(100)\
            .execute()
        return jsonify({'success': True, 'trips': result.data or []})
    except Exception:
        logger.exception("Error en admin_trips")
        return jsonify({'success': False, 'message': 'Error cargando viajes'}), 500


# ============================================
# ADMIN - TICKETS
# ============================================
@app.route('/api/admin/tickets', methods=['GET'])
@admin_required
def admin_tickets():
    try:
        result = supabase.table('tickets_soporte')\
            .select('*')\
            .order('fecha', desc=True)\
            .limit(50)\
            .execute()
        return jsonify({'success': True, 'tickets': result.data or []})
    except Exception as e:
        logger.warning(f"No se pudieron cargar tickets: {e}")
        return jsonify({'success': True, 'tickets': []})


# ============================================
# ADMIN - VEHÍCULOS
# ============================================
@app.route('/api/admin/vehicles', methods=['GET'])
@admin_required
def admin_vehicles():
    try:
        result = supabase.table('vehiculos')\
            .select('*, usuarios(nombre_completo, email, telefono)')\
            .execute()

        vehiculos = []
        for v in (result.data or []):
            fotos = {}
            for campo in ['foto_frente', 'foto_lateral', 'foto_interior', 'foto_placa']:
                if v.get(campo):
                    try:
                        url = supabase.storage.from_('vehiculos').get_public_url(v[campo])
                        fotos[campo] = url
                    except Exception:
                        fotos[campo] = None
                else:
                    fotos[campo] = None
            v['fotos'] = fotos
            vehiculos.append(v)

        return jsonify({'success': True, 'vehicles': vehiculos})
    except Exception as e:
        logger.exception("Error en admin_vehicles")
        return jsonify({'success': False, 'message': str(e)}), 500


@app.route('/api/admin/vehicles/<int:vehicle_id>/approve', methods=['POST'])
@admin_required
def admin_approve_vehicle(vehicle_id):
    try:
        supabase.table('vehiculos')\
            .update({'estado_vehiculo': 'Aprobado'})\
            .eq('id_vehiculo', vehicle_id)\
            .execute()
        registrar_log(None, 'VEHICULO_APROBADO', get_client_ip(), {'id_vehiculo': vehicle_id})
        return jsonify({'success': True, 'message': 'Vehículo aprobado'})
    except Exception as e:
        logger.exception("Error aprobando vehículo")
        return jsonify({'success': False, 'message': str(e)}), 500


@app.route('/api/admin/vehicles/<int:vehicle_id>/reject', methods=['POST'])
@admin_required
def admin_reject_vehicle(vehicle_id):
    try:
        supabase.table('vehiculos')\
            .update({'estado_vehiculo': 'Rechazado'})\
            .eq('id_vehiculo', vehicle_id)\
            .execute()
        registrar_log(None, 'VEHICULO_RECHAZADO', get_client_ip(), {'id_vehiculo': vehicle_id})
        return jsonify({'success': True, 'message': 'Vehículo rechazado'})
    except Exception as e:
        logger.exception("Error rechazando vehículo")
        return jsonify({'success': False, 'message': str(e)}), 500


# ============================================
# ADMIN - TARIFAS
# ============================================
@app.route('/api/admin/tariffs', methods=['GET'])
@admin_required
def admin_tariffs():
    try:
        result = supabase.table('tarifas')\
            .select('*')\
            .order('tipo_servicio')\
            .execute()
        return jsonify({'success': True, 'tariffs': result.data or []})
    except Exception as e:
        logger.exception("Error en admin_tariffs")
        return jsonify({'success': False, 'message': str(e)}), 500


@app.route('/api/admin/tariffs', methods=['POST'])
@admin_required
def admin_create_tariff():
    try:
        data = request.get_json(silent=True) or {}

        nueva = {
            'nombre': _safe_str(data.get('nombre')),
            'tipo_servicio': _safe_str(data.get('tipo_servicio')),
            'zona': _safe_str(data.get('zona'), 'General'),
            'precio_base': float(data.get('precio_base', 0)),
            'precio_por_km': float(data.get('precio_por_km', 0)),
            'precio_por_minuto': float(data.get('precio_por_minuto', 0)),
            'tarifa_minima': float(data.get('tarifa_minima', 0)),
            'activa': True
        }

        result = supabase.table('tarifas').insert(nueva).execute()
        return jsonify({'success': True, 'tariff': result.data[0] if result.data else None})
    except Exception as e:
        logger.exception("Error creando tarifa")
        return jsonify({'success': False, 'message': str(e)}), 500


@app.route('/api/admin/tariffs/<int:tariff_id>', methods=['PUT'])
@admin_required
def admin_update_tariff(tariff_id):
    try:
        data = request.get_json(silent=True) or {}

        actualizacion = {}
        for campo in ['nombre', 'tipo_servicio', 'zona', 'precio_base',
                      'precio_por_km', 'precio_por_minuto', 'tarifa_minima', 'activa']:
            if campo in data:
                actualizacion[campo] = data[campo]

        actualizacion['fecha_actualizacion'] = datetime.now(timezone.utc).isoformat()

        supabase.table('tarifas')\
            .update(actualizacion)\
            .eq('id_tarifa', tariff_id)\
            .execute()

        return jsonify({'success': True, 'message': 'Tarifa actualizada'})
    except Exception as e:
        logger.exception("Error actualizando tarifa")
        return jsonify({'success': False, 'message': str(e)}), 500


@app.route('/api/admin/tariffs/<int:tariff_id>', methods=['DELETE'])
@admin_required
def admin_delete_tariff(tariff_id):
    try:
        supabase.table('tarifas')\
            .delete()\
            .eq('id_tarifa', tariff_id)\
            .execute()
        return jsonify({'success': True, 'message': 'Tarifa eliminada'})
    except Exception as e:
        logger.exception("Error eliminando tarifa")
        return jsonify({'success': False, 'message': str(e)}), 500


# ============================================
# VERIFICACIÓN AUTOMÁTICA DE DOCUMENTOS
# ============================================
def verificar_documentos_conductor(user_id):
    """Verifica TODOS los documentos. Si alguno está vencido → RECHAZA."""
    try:
        try:
            docs = supabase.table('documentos_conductor')\
                .select('*')\
                .eq('id_usuario', user_id)\
                .execute()
        except Exception:
            return {'verificado': True, 'motivo': 'Sin sistema de documentos', 'docs_vencidos': []}

        if not docs.data:
            return {'verificado': False, 'motivo': 'Sin documentos cargados', 'docs_vencidos': []}

        hoy = date.today()
        docs_vencidos = []
        docs_rechazados = []
        docs_pendientes = []

        for doc in docs.data:
            fecha_venc = doc.get('fecha_vencimiento')
            estado = doc.get('estado', 'Pendiente')
            tipo = doc.get('tipo_documento', '')

            if fecha_venc:
                try:
                    fecha_venc_date = datetime.strptime(fecha_venc, '%Y-%m-%d').date()
                    if fecha_venc_date < hoy:
                        docs_vencidos.append({
                            'tipo': tipo,
                            'vencimiento': fecha_venc,
                            'dias_vencido': (hoy - fecha_venc_date).days
                        })
                        continue
                except Exception:
                    pass

            if estado == 'Rechazado':
                docs_rechazados.append(tipo)
            elif estado == 'Pendiente':
                docs_pendientes.append(tipo)

        if docs_vencidos:
            motivo = "Documentos VENCIDOS: " + ", ".join([
                f"{d['tipo']} (venció {d['vencimiento']})" for d in docs_vencidos
            ])
            return {'verificado': False, 'motivo': motivo, 'docs_vencidos': docs_vencidos}

        if docs_rechazados:
            return {
                'verificado': False,
                'motivo': f"Documentos rechazados: {', '.join(docs_rechazados)}",
                'docs_vencidos': []
            }

        if docs_pendientes:
            return {
                'verificado': False,
                'motivo': f"Pendientes: {', '.join(docs_pendientes)}",
                'docs_vencidos': []
            }

        return {'verificado': True, 'motivo': 'Todo OK', 'docs_vencidos': []}

    except Exception as e:
        logger.exception("Error verificando documentos")
        return {'verificado': False, 'motivo': str(e), 'docs_vencidos': []}


def actualizar_estado_conductor_automatico(user_id):
    try:
        resultado = verificar_documentos_conductor(user_id)

        if resultado['verificado']:
            supabase.table('usuarios')\
                .update({
                    'documentos_verificados': True,
                    'estado_cuenta': 'Activo',
                    'motivo_rechazo': None,
                    'fecha_ultima_verificacion': datetime.now(timezone.utc).isoformat()
                })\
                .eq('id_usuario', user_id)\
                .execute()
        else:
            motivo = resultado['motivo']
            nuevo_estado = 'Rechazado' if resultado['docs_vencidos'] or 'rechazado' in motivo.lower() else 'Pendiente'

            supabase.table('usuarios')\
                .update({
                    'documentos_verificados': False,
                    'estado_cuenta': nuevo_estado,
                    'motivo_rechazo': motivo
                })\
                .eq('id_usuario', user_id)\
                .execute()

        return resultado
    except Exception as e:
        logger.exception("Error actualizando estado")
        return {'verificado': False, 'motivo': str(e), 'docs_vencidos': []}


@app.route('/api/admin/drivers/<int:user_id>/verify', methods=['POST'])
@admin_required
def admin_verify_driver(user_id):
    try:
        resultado = actualizar_estado_conductor_automatico(user_id)
        registrar_log(user_id, 'CONDUCTOR_REVERIFICADO', get_client_ip(), resultado)
        return jsonify({
            'success': True,
            'message': 'Verificación completada',
            'verificacion': resultado
        })
    except Exception as e:
        logger.exception("Error verificando conductor")
        return jsonify({'success': False, 'message': str(e)}), 500


# ============================================
# DISPONIBILIDAD POR ESTADO DE VENEZUELA
# ============================================
@app.route('/api/admin/disponibilidad-por-estado', methods=['GET'])
@admin_required
def admin_disponibilidad_por_estado():
    """
    Devuelve cuántos conductores hay por estado de Venezuela,
    separados por estado de trabajo (disponible, en_viaje, etc.)
    """
    try:
        # 1. Obtener TODOS los estados de Venezuela
        estados = supabase.table('estados_venezuela')\
            .select('codigo, nombre, capital')\
            .order('nombre')\
            .execute()

        estados_lista = estados.data or []

        # 2. Obtener TODAS las ubicaciones con info del conductor
        ubicaciones = supabase.table('ubicaciones_conductores')\
            .select('*, usuarios(nombre_completo, email, telefono, estado_operacion, ciudad_operacion)')\
            .execute()

        # 3. Obtener vehículos aprobados por conductor
        vehiculos = supabase.table('vehiculos')\
            .select('id_conductor, marca, modelo, placa, color, tipo_servicio')\
            .eq('estado_vehiculo', 'Aprobado')\
            .execute()

        vehiculos_por_conductor = {}
        for v in (vehiculos.data or []):
            vehiculos_por_conductor[v['id_conductor']] = v

        # 4. Agrupar por estado de Venezuela
        por_estado = {}
        for est in estados_lista:
            por_estado[est['codigo']] = {
                'codigo': est['codigo'],
                'nombre': est['nombre'],
                'capital': est.get('capital', ''),
                'total': 0,
                'disponibles': 0,
                'en_viaje': 0,
                'descanso': 0,
                'desconectados': 0,
                'conductores': []
            }

        # 5. Clasificar cada conductor
        for u in (ubicaciones.data or []):
            usuario = u.get('usuarios', {}) or {}
            codigo_estado = u.get('estado_venezuela') or usuario.get('estado_operacion')

            if not codigo_estado or codigo_estado not in por_estado:
                continue

            estado_trabajo = u.get('estado', 'desconectado')
            conductor_id = u['id_conductor']
            vehiculo = vehiculos_por_conductor.get(conductor_id, {})

            info_conductor = {
                'id_conductor': conductor_id,
                'nombre': usuario.get('nombre_completo', 'Conductor'),
                'email': usuario.get('email', ''),
                'telefono': usuario.get('telefono', ''),
                'estado_trabajo': estado_trabajo,
                'latitud': float(u['latitud']),
                'longitud': float(u['longitud']),
                'velocidad': float(u.get('velocidad_kmh', 0) or 0),
                'bateria': u.get('bateria_porcentaje', 0),
                'ultima_actualizacion': u.get('fecha_actualizacion'),
                'vehiculo': {
                    'marca': vehiculo.get('marca', 'Sin vehículo'),
                    'modelo': vehiculo.get('modelo', ''),
                    'placa': vehiculo.get('placa', ''),
                    'color': vehiculo.get('color', ''),
                    'tipo_servicio': vehiculo.get('tipo_servicio', '')
                } if vehiculo else None
            }

            por_estado[codigo_estado]['conductores'].append(info_conductor)
            por_estado[codigo_estado]['total'] += 1

            if estado_trabajo == 'disponible':
                por_estado[codigo_estado]['disponibles'] += 1
            elif estado_trabajo == 'en_viaje':
                por_estado[codigo_estado]['en_viaje'] += 1
            elif estado_trabajo == 'descanso':
                por_estado[codigo_estado]['descanso'] += 1
            else:
                por_estado[codigo_estado]['desconectados'] += 1

        resultado = list(por_estado.values())
        resultado.sort(key=lambda x: x['disponibles'], reverse=True)

        total_disponibles = sum(e['disponibles'] for e in resultado)
        total_en_viaje = sum(e['en_viaje'] for e in resultado)
        total_general = sum(e['total'] for e in resultado)

        return jsonify({
            'success': True,
            'resumen': {
                'total_conductores': total_general,
                'total_disponibles': total_disponibles,
                'total_en_viaje': total_en_viaje,
                'estados_con_conductores': len([e for e in resultado if e['total'] > 0])
            },
            'estados': resultado
        })
    except Exception as e:
        logger.exception("Error en admin_disponibilidad_por_estado")
        return jsonify({'success': False, 'message': str(e)}), 500


# ============================================
# TASA DE CAMBIO BCV
# ============================================
@app.route('/api/exchange-rate', methods=['GET'])
def exchange_rate():
    try:
        import urllib.request
        import json as json_lib

        url = 'https://ve.dolarapi.com/v1/dolares/oficial'
        req = urllib.request.Request(url, headers={'User-Agent': 'Teyevo/1.0'})
        with urllib.request.urlopen(req, timeout=5) as response:
            data = json_lib.loads(response.read().decode())

        return jsonify({'success': True, 'rate': data.get('promedio', 0), 'source': 'BCV'})
    except Exception as e:
        logger.warning(f"No se pudo obtener tasa BCV: {e}")
        return jsonify({'success': True, 'rate': 849.56, 'source': 'fallback'})


# ============================================
# MANEJO GLOBAL DE ERRORES
# ============================================
@app.errorhandler(404)
def not_found(e):
    if request.path.startswith('/api/'):
        return jsonify({'success': False, 'message': 'Recurso no encontrado'}), 404
    return render_template('login.html'), 404


@app.errorhandler(405)
def method_not_allowed(e):
    return jsonify({'success': False, 'message': 'Método no permitido'}), 405


@app.errorhandler(500)
def server_error(e):
    return jsonify({'success': False, 'message': 'Error interno del servidor'}), 500


# ============================================
# CRON: Verificación automática cada hora
# ============================================
def cron_verificacion_automatica():
    """Verifica todos los conductores cada hora"""
    time.sleep(60)

    while True:
        try:
            logger.info("🔄 Ejecutando verificación automática de documentos...")

            conductores = supabase.table('usuarios')\
                .select('id_usuario')\
                .eq('id_rol', ID_ROL_CONDUCTOR)\
                .neq('estado_cuenta', 'Bloqueado')\
                .execute()

            for c in (conductores.data or []):
                try:
                    actualizar_estado_conductor_automatico(c['id_usuario'])
                except Exception as e:
                    logger.warning(f"Error verificando conductor {c['id_usuario']}: {e}")

            logger.info(f"✅ Verificación completada para {len(conductores.data or [])} conductores")
        except Exception as e:
            logger.exception("Error en cron de verificación")

        time.sleep(3600)
# ============================================
# RUTAS DE VIAJES (Tracking GPS)
# ============================================

@app.route('/api/admin/trips/<int:trip_id>/route', methods=['GET'])
@admin_required
def admin_trip_route(trip_id):
    """Obtiene la ruta completa de un viaje (todos los puntos GPS)"""
    try:
        # Info del viaje
        viaje = supabase.table('viajes')\
            .select('*')\
            .eq('id_viaje', trip_id)\
            .single()\
            .execute()
        
        if not viaje.data:
            return jsonify({'success': False, 'message': 'Viaje no encontrado'}), 404
        
        # Puntos GPS de la ruta
        ruta = supabase.table('rutas_viajes')\
            .select('*')\
            .eq('id_viaje', trip_id)\
            .order('orden')\
            .execute()
        
        return jsonify({
            'success': True,
            'viaje': viaje.data,
            'ruta': ruta.data or []
        })
    except Exception as e:
        logger.exception("Error obteniendo ruta del viaje")
        return jsonify({'success': False, 'message': str(e)}), 500


@app.route('/api/admin/trips/<int:trip_id>/detail', methods=['GET'])
@admin_required
def admin_trip_detail(trip_id):
    """Info completa de un viaje con conductor, pasajero y ruta"""
    try:
        # Info del viaje
        viaje = supabase.table('viajes')\
            .select('*')\
            .eq('id_viaje', trip_id)\
            .single()\
            .execute()
        
        if not viaje.data:
            return jsonify({'success': False, 'message': 'Viaje no encontrado'}), 404
        
        v = viaje.data
        
        # Info del conductor
        conductor = None
        if v.get('id_conductor'):
            c = supabase.table('usuarios')\
                .select('nombre_completo, email, telefono, calificacion_promedio')\
                .eq('id_usuario', v['id_conductor'])\
                .single()\
                .execute()
            conductor = c.data
        
        # Info del pasajero
        pasajero = None
        if v.get('id_pasajero'):
            p = supabase.table('usuarios')\
                .select('nombre_completo, email, telefono')\
                .eq('id_usuario', v['id_pasajero'])\
                .single()\
                .execute()
            pasajero = p.data
        
        # Puntos GPS
        ruta = supabase.table('rutas_viajes')\
            .select('*')\
            .eq('id_viaje', trip_id)\
            .order('orden')\
            .execute()
        
        return jsonify({
            'success': True,
            'viaje': v,
            'conductor': conductor,
            'pasajero': pasajero,
            'ruta': ruta.data or []
        })
    except Exception as e:
        logger.exception("Error obteniendo detalle del viaje")
        return jsonify({'success': False, 'message': str(e)}), 500


@app.route('/api/conductor/viaje/<int:trip_id>/punto', methods=['POST'])
@login_required
def agregar_punto_ruta(trip_id):
    """El conductor agrega un punto GPS a la ruta activa del viaje"""
    try:
        user_id = session.get('user_id')
        data = request.get_json(silent=True) or {}
        
        lat = data.get('latitud')
        lng = data.get('longitud')
        
        if lat is None or lng is None:
            return jsonify({'success': False, 'message': 'Faltan coordenadas'}), 400
        
        # Obtener el orden actual (último punto + 1)
        ultimo = supabase.table('rutas_viajes')\
            .select('orden')\
            .eq('id_viaje', trip_id)\
            .order('orden', desc=True)\
            .limit(1)\
            .execute()
        
        orden_actual = (ultimo.data[0]['orden'] + 1) if ultimo.data else 1
        
        # Insertar punto
        supabase.table('rutas_viajes').insert({
            'id_viaje': trip_id,
            'id_conductor': user_id,
            'latitud': float(lat),
            'longitud': float(lng),
            'velocidad_kmh': float(data.get('velocidad', 0) or 0),
            'direccion_grados': int(data.get('direccion', 0) or 0),
            'orden': orden_actual,
            'fecha': datetime.now(timezone.utc).isoformat()
        }).execute()
        
        return jsonify({
            'success': True,
            'message': 'Punto agregado',
            'orden': orden_actual
        })
    except Exception as e:
        logger.exception("Error agregando punto")
        return jsonify({'success': False, 'message': str(e)}), 500

# ============================================
# MAIN
# ============================================
if __name__ == '__main__':
    debug = os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
    port = int(os.getenv('PORT', 5000))

    if not debug or os.environ.get('WERKZEUG_RUN_MAIN') == 'true':
        threading.Thread(target=cron_verificacion_automatica, daemon=True).start()
        logger.info("🔄 Cron de verificación automática iniciado")

    logger.info(f"🚀 Teyevo iniciando en puerto {port} (debug={debug})")
    app.run(debug=debug, host='0.0.0.0', port=port)