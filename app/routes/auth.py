# auth.py

from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
from app import models, schemas
from app.database import get_db
import os # NUEVO: Para leer variables de entorno
from fastapi import APIRouter
from app.schemas import Login 
import random
import string
from fastapi.responses import HTMLResponse
from jinja2 import Template
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

router = APIRouter(
    prefix="/auth", # MEJORADO: Agrupar todas las rutas de auth bajo un prefijo
    tags=["Autenticación"]
)

# Configurar Rate Limiter
limiter = Limiter(key_func=get_remote_address)

# --- CONFIGURACIÓN ---

# MEJORADO: Cargar la clave secreta desde variables de entorno para mayor seguridad
SECRET_KEY = os.getenv("SECRET_KEY", "una_clave_secreta_por_defecto_solo_para_desarrollo")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "15"))
REFRESH_TOKEN_EXPIRE_DAYS = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "7"))

bearer_scheme = HTTPBearer()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# --- CONFIGURACIÓN DE EMAIL ---

EMAIL_HOST = os.getenv("EMAIL_HOST", "smtp.gmail.com")
EMAIL_PORT = int(os.getenv("EMAIL_PORT", "587"))
EMAIL_USER = os.getenv("EMAIL_USER", "tu-email@gmail.com")
EMAIL_PASSWORD = os.getenv("EMAIL_PASSWORD", "tu-contraseña-de-aplicacion")
EMAIL_USE_TLS = True

# --- FUNCIONES AUXILIARES ---

def _validar_seguridad_contrasena(contrasena: str) -> str:
    """
    Valida que la contraseña cumpla con los requisitos de seguridad.
    Retorna un mensaje de error si no cumple, o None si es válida.
    """
    if len(contrasena) < 8:
        return "La contraseña debe tener al menos 8 caracteres"
    
    if not any(c.isupper() for c in contrasena):
        return "La contraseña debe contener al menos una letra mayúscula"
    
    if not any(c.islower() for c in contrasena):
        return "La contraseña debe contener al menos una letra minúscula"
    
    if not any(c.isdigit() for c in contrasena):
        return "La contraseña debe contener al menos un número"
    
    caracteres_especiales = "!@#$%^&*()_+-=[]{}|;:,.<>?"
    if not any(c in caracteres_especiales for c in contrasena):
        return "La contraseña debe contener al menos un carácter especial (!@#$%^&*()_+-=[]{}|;:,.<>?)"
    
    return None

def _crear_token_acceso(usuario: models.Usuario) -> str:
    """Crea un token de acceso con fecha_expiracionción corta (15 min)"""
    fecha_expiraciontion = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    token_data = {
        "sub": usuario.correo,
        "rol": usuario.rol.nombre,
        "id": usuario.id,
        "type": "access",
        "exp": fecha_expiraciontion
    }
    return jwt.encode(token_data, SECRET_KEY, algorithm=ALGORITHM)

def _crear_refresh_token(usuario: models.Usuario) -> str:
    """Crea un refresh token con fecha_expiracionción larga (7 días)"""
    fecha_expiraciontion = datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    token_data = {
        "sub": usuario.correo,
        "id": usuario.id,
        "type": "refresh",
        "exp": fecha_expiraciontion
    }
    return jwt.encode(token_data, SECRET_KEY, algorithm=ALGORITHM)

# NUEVO: Función centralizada para decodificar tokens y obtener el usuario
def _obtener_usuario_por_token(token: str, db: Session) -> models.Usuario:
    """Decodifica un token, valida su payload y devuelve el usuario correspondiente."""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        correo: str = payload.get("sub")
        if correo is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token inválido (sin 'sub')")
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token inválido o fecha_expiraciondo")

    usuario = db.query(models.Usuario).filter(models.Usuario.correo == correo).first()
    if usuario is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Usuario del token no encontrado")
    
    return usuario

# --- FUNCIONES DE RECUPERACIÓN DE CONTRASEÑA ---

def generar_codigo_recuperacion() -> str:
    """Genera un código de 6 dígitos aleatorio"""
    return ''.join(random.choices(string.digits, k=6))

def enviar_email_codigo(email: str, codigo: str, username: str):
    """Envía email con código de recuperación"""
    try:
        # Verificar configuración de email
        if not EMAIL_USER or EMAIL_USER == "tu-email@gmail.com" or not EMAIL_PASSWORD or EMAIL_PASSWORD == "tu-contraseña-de-aplicacion":
            print(f"⚠️ Configuración de email no válida. Simulando envío para desarrollo.")
            print(f"📧 Email simulado para {email}:")
            print(f"   Código: {codigo}")
            print(f"   Usuario: {username}")
            return  # No lanzar error, solo simular
        
        # Leer template HTML
        with open('templates/emails/codigo_recuperacion.html', 'r', encoding='utf-8') as f:
            template_html = f.read()
        
        # Renderizar template
        template = Template(template_html)
        html_content = template.render(
            username=username,
            codigo=codigo,
            fecha=datetime.now().strftime('%d/%m/%Y %H:%M')
        )
        
        # Crear mensaje
        msg = MIMEMultipart('alternative')
        msg['Subject'] = 'Código de Recuperación - Sistema PAE'
        msg['From'] = EMAIL_USER
        msg['To'] = email
        
        # Versión HTML
        html_part = MIMEText(html_content, 'html')
        msg.attach(html_part)
        
        # Enviar email
        with smtplib.SMTP(EMAIL_HOST, EMAIL_PORT) as server:
            if EMAIL_USE_TLS:
                server.starttls()
            server.login(EMAIL_USER, EMAIL_PASSWORD)
            server.send_message(msg)
            
        print(f"✅ Email de código enviado a {email}")
        
    except Exception as e:
        print(f"❌ Error al enviar email: {str(e)}")
        # En modo desarrollo, no lanzar error para no bloquear la funcionalidad
        print(f"📧 Modo desarrollo - Código generado: {codigo}")
        print(f"   Usuario: {username}")
        print(f"   Email: {email}")
        # No lanzar la excepción para permitir que la funcionalidad continúe

def enviar_email_confirmacion(email: str, username: str):
    """Envía email de confirmación de cambio de contraseña"""
    try:
        # Verificar configuración de email
        if not EMAIL_USER or EMAIL_USER == "tu-email@gmail.com" or not EMAIL_PASSWORD or EMAIL_PASSWORD == "tu-contraseña-de-aplicacion":
            print(f"⚠️ Configuración de email no válida. Simulando envío para desarrollo.")
            print(f"📧 Email de confirmación simulado para {email}:")
            print(f"   Usuario: {username}")
            return  # No lanzar error, solo simular
        
        # Leer template HTML
        with open('templates/emails/confirmacion_contrasena.html', 'r', encoding='utf-8') as f:
            template_html = f.read()
        
        # Renderizar template
        template = Template(template_html)
        html_content = template.render(
            username=username,
            fecha=datetime.now().strftime('%d/%m/%Y %H:%M')
        )
        
        # Crear mensaje
        msg = MIMEMultipart('alternative')
        msg['Subject'] = 'Contraseña Cambiada - Sistema PAE'
        msg['From'] = EMAIL_USER
        msg['To'] = email
        
        # Versión HTML
        html_part = MIMEText(html_content, 'html')
        msg.attach(html_part)
        
        # Enviar email
        with smtplib.SMTP(EMAIL_HOST, EMAIL_PORT) as server:
            if EMAIL_USE_TLS:
                server.starttls()
            server.login(EMAIL_USER, EMAIL_PASSWORD)
            server.send_message(msg)
            
        print(f"✅ Email de confirmación enviado a {email}")
        
    except Exception as e:
        print(f"❌ Error al enviar email: {str(e)}")
        # En modo desarrollo, no lanzar error para no bloquear la funcionalidad
        print(f"📧 Modo desarrollo - Confirmación simulado para {email}")
        print(f"   Usuario: {username}")
        # No lanzar la excepción para permitir que la funcionalidad continúe

# --- DEPENDENCIAS DE FASTAPI ---

def obtener_usuario_actual(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db)
) -> models.Usuario:
    """Dependencia para obtener el usuario autenticado en rutas protegidas."""
    return _obtener_usuario_por_token(credentials.credentials, db)

def verificar_rol_permitido(roles_permitidos: list):
    """
    Dependencia que verifica si el rol del usuario autenticado está en la lista de roles permitidos.
    """
    def validador(usuario: models.Usuario = Depends(obtener_usuario_actual)):
        if usuario.rol.nombre not in roles_permitidos:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Acceso denegado. Rol '{usuario.rol.nombre}' no autorizado."
            )
        return usuario
    return validador

# --- RUTAS DE LA API ---

@router.post("/register", response_model=schemas.TokenData, status_code=status.HTTP_201_CREATED)
@limiter.limit("3/minute")
def register(request: Request, usuario: schemas.UsuarioCreate, db: Session = Depends(get_db)):
    # Validar que el correo no esté registrado
    if db.query(models.Usuario).filter(models.Usuario.correo == usuario.correo).first():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="El correo ya está registrado")

    # Validar seguridad de la contraseña
    error_validacion = _validar_seguridad_contrasena(usuario.contrasena)
    if error_validacion:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=error_validacion)

    nuevo_usuario = models.Usuario(
        nombre=usuario.nombre,
        correo=usuario.correo,
        contrasena=pwd_context.hash(usuario.contrasena),
        rol_id=usuario.rol_id
    )
    db.add(nuevo_usuario)
    db.commit()
    db.refresh(nuevo_usuario)

    access_token = _crear_token_acceso(nuevo_usuario)
    refresh_token = _crear_refresh_token(nuevo_usuario)
    
    # --- MEJORADO: Devolvemos ambos tokens para mayor seguridad ---
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "usuario": nuevo_usuario 
    }


@router.post("/login", response_model=schemas.TokenData)
@limiter.limit("5/minute")
def login(request: Request, form_data: schemas.Login, db: Session = Depends(get_db)):
    """Inicia sesión y devuelve un token de acceso Y la información del usuario."""
    usuario = db.query(models.Usuario).filter(models.Usuario.correo == form_data.correo).first()
    if not usuario or not pwd_context.verify(form_data.contrasena, usuario.contrasena):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Credenciales inválidas"
        )

    access_token = _crear_token_acceso(usuario)
    refresh_token = _crear_refresh_token(usuario)
    
    # MEJORADO: Devolvemos ambos tokens para mayor seguridad
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "usuario": usuario  
    }

@router.post("/refresh")
def refresh_token(refresh_data: dict, db: Session = Depends(get_db)):
    """Renueva un token de acceso usando un refresh token válido"""
    try:
        refresh_token = refresh_data.get("refresh_token")
        if not refresh_token:
            raise HTTPException(status_code=400, detail="Refresh token requerido")
        
        # Decodificar el refresh token
        payload = jwt.decode(refresh_token, SECRET_KEY, algorithms=[ALGORITHM])
        
        # Verificar que es un refresh token
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=400, detail="Token inválido")
        
        # Obtener el usuario
        correo = payload.get("sub")
        usuario = db.query(models.Usuario).filter(models.Usuario.correo == correo).first()
        if not usuario:
            raise HTTPException(status_code=401, detail="Usuario no encontrado")
        
        # Generar nuevo access token
        new_access_token = _crear_token_acceso(usuario)
        
        return {
            "access_token": new_access_token,
            "token_type": "bearer"
        }
        
    except JWTError:
        raise HTTPException(status_code=401, detail="Refresh token inválido o fecha_expiraciondo")

@router.get("/me", response_model=schemas.UsuarioOut)
def read_users_me(usuario: models.Usuario = Depends(obtener_usuario_actual)):
    """Devuelve la información del usuario actualmente autenticado."""
    return usuario


@router.put("/me/cambiar-contrasena")
def cambiar_contrasena(
    datos: schemas.CambioContrasena,
    db: Session = Depends(get_db),
    usuario: models.Usuario = Depends(obtener_usuario_actual)
):
    """Permite al usuario autenticado cambiar su propia contraseña."""
    if not pwd_context.verify(datos.actual, usuario.contrasena):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Contraseña actual incorrecta")

    usuario.contrasena = pwd_context.hash(datos.nueva)
    db.commit()
    return {"mensaje": "Contraseña actualizada correctamente"}

# --- RUTAS DE RECUPERACIÓN DE CONTRASEÑA ---

@router.post("/olvidaste-contrasena")
def enviar_codigo_recuperacion(datos: dict, db: Session = Depends(get_db)):
    """Envía un código de recuperación por email"""
    try:
        email = datos.get("correo")
        if not email:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Correo electrónico requerido")
        
        # Verificar que el usuario existe
        usuario = db.query(models.Usuario).filter(models.Usuario.correo == email).first()
        if not usuario:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No existe una cuenta registrada con este correo electrónico")
        
        # Eliminar códigos anteriores del usuario
        db.query(models.CodigoRecuperacion).filter(
            models.CodigoRecuperacion.usuario_id == usuario.id,
            models.CodigoRecuperacion.usado == False
        ).update({"usado": True})
        
        # Generar nuevo código
        codigo = generar_codigo_recuperacion()
        while db.query(models.CodigoRecuperacion).filter(
            models.CodigoRecuperacion.codigo == codigo,
            models.CodigoRecuperacion.usado == False
        ).first():
            codigo = generar_codigo_recuperacion()
        
        # Crear código con expiración de 30 minutos
        fecha_expiracion = datetime.utcnow() + timedelta(minutes=30)
        
        codigo_recuperacion = models.CodigoRecuperacion(
            usuario_id=usuario.id,
            codigo=codigo,
            email=email,
            fecha_creacion=datetime.utcnow(),
            fecha_expiracion=fecha_expiracion,
            intentos=0
        )
        
        db.add(codigo_recuperacion)
        db.commit()
        
        # Enviar email
        enviar_email_codigo(email, codigo, usuario.nombre)
        
        return {
            "mensaje": "Código de verificación enviado exitosamente",
            "email": email
        }
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error al enviar código de recuperación: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Error al enviar código de recuperación")

@router.post("/verificar-codigo")
def verificar_codigo(datos: dict, db: Session = Depends(get_db)):
    """Verifica el código de recuperación"""
    try:
        email = datos.get("correo")
        codigo = datos.get("codigo")
        
        if not email or not codigo:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Correo y código requeridos")
        
        # Buscar usuario
        usuario = db.query(models.Usuario).filter(models.Usuario.correo == email).first()
        if not usuario:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No existe una cuenta registrada con este correo electrónico")
        
        # Buscar código de recuperación
        codigo_recuperacion = db.query(models.CodigoRecuperacion).filter(
            models.CodigoRecuperacion.usuario_id == usuario.id,
            models.CodigoRecuperacion.codigo == codigo,
            models.CodigoRecuperacion.usado == False
        ).first()
        
        if not codigo_recuperacion:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Código de verificación incorrecto")
        
        # Verificar si el código ha fecha_expiraciondo
        if datetime.utcnow() > codigo_recuperacion.fecha_expiracion:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="El código de verificación ha fecha_expiraciondo. Solicita uno nuevo")
        
        # Verificar intentos
        if codigo_recuperacion.intentos >= 3:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Se han excedido los intentos permitidos. Solicita un nuevo código")
        
        # Incrementar intentos
        codigo_recuperacion.intentos += 1
        db.commit()
        
        return {
            "mensaje": "Código verificado correctamente",
            "valido": True,
            "email": email
        }
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error al verificar código: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Error al verificar código")

@router.post("/cambiar-contrasena")
def cambiar_contrasena_recuperacion(datos: dict, db: Session = Depends(get_db)):
    """Cambia la contraseña usando el código de verificación"""
    try:
        email = datos.get("correo")
        codigo = datos.get("codigo")
        nueva_contrasena = datos.get("nueva_contrasena")
        
        if not email or not codigo or not nueva_contrasena:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Correo, código y nueva contraseña requeridos")
        
        # Validar seguridad de la contraseña
        error_validacion = _validar_seguridad_contrasena(nueva_contrasena)
        if error_validacion:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=error_validacion)
        
        # Buscar usuario
        usuario = db.query(models.Usuario).filter(models.Usuario.correo == email).first()
        if not usuario:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No existe una cuenta registrada con este correo electrónico")
        
        # Buscar código de recuperación
        codigo_recuperacion = db.query(models.CodigoRecuperacion).filter(
            models.CodigoRecuperacion.usuario_id == usuario.id,
            models.CodigoRecuperacion.codigo == codigo,
            models.CodigoRecuperacion.usado == False
        ).first()
        
        if not codigo_recuperacion:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Código de verificación incorrecto")
        
        # Verificar si el código ha fecha_expiraciondo
        if datetime.utcnow() > codigo_recuperacion.fecha_expiracion:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="El código de verificación ha fecha_expiraciondo. Solicita uno nuevo")
        
        # Verificar si ya fue usado
        if codigo_recuperacion.usado:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Este código ya ha sido utilizado. Solicita uno nuevo")
        
        # Cambiar contraseña
        usuario.contrasena = pwd_context.hash(nueva_contrasena)
        
        # Marcar código como usado
        codigo_recuperacion.usado = True
        
        db.commit()
        
        # Enviar email de confirmación
        enviar_email_confirmacion(email, usuario.nombre)
        
        return {
            "mensaje": "Contraseña cambiada exitosamente"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error al cambiar contraseña: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Error al cambiar contraseña")