from fastapi import Depends, HTTPException, Request
from sqlalchemy.orm import Session
from jose import jwt, JWTError
from datetime import datetime
import pyotp
import qrcode
import io
import base64
from typing import List, Optional

from app.database import get_db
from app import models
from app.dependencies import get_current_user
from app.utils.auth_utils import SECRET_KEY, ALGORITHM

def verificar_admin(usuario: models.Usuario = Depends(get_current_user)):
    """
    Verifica que el usuario tenga rol de administrador.
    """
    if usuario.rol.nombre.lower() != "administrador":
        raise HTTPException(
            status_code=403,
            detail="Acceso denegado. Solo administradores pueden acceder a esta funcionalidad."
        )
    
    if not usuario.activo:
        raise HTTPException(
            status_code=403,
            detail="Usuario desactivado. Contacte al administrador."
        )
    
    return usuario

def verificar_admin_con_2fa(
    usuario: models.Usuario = Depends(verificar_admin),
    require_2fa: bool = True
):
    """
    Verifica que el usuario sea admin y tenga 2FA habilitado si es requerido.
    """
    if require_2fa and not usuario.twofa_enabled:
        raise HTTPException(
            status_code=403,
            detail="Esta acción requiere autenticación de dos factores (2FA) habilitada."
        )
    
    return usuario

def verificar_permiso(permiso_requerido: str):
    """
    Decorator para verificar que el usuario tenga un permiso específico.
    """
    def validador(
        usuario: models.Usuario = Depends(verificar_admin),
        db: Session = Depends(get_db)
    ):
        # Verificar si el usuario tiene el permiso específico
        tiene_permiso = db.query(models.RolPermiso).join(
            models.Permiso
        ).filter(
            models.RolPermiso.rol_id == usuario.rol_id,
            models.Permiso.clave == permiso_requerido,
            models.Permiso.activo == True
        ).first()
        
        if not tiene_permiso:
            raise HTTPException(
                status_code=403,
                detail=f"Acceso denegado. Se requiere el permiso: {permiso_requerido}"
            )
        
        return usuario
    
    return validador

def generar_2fa_secret(usuario: models.Usuario, db: Session) -> dict:
    """
    Genera un secreto TOTP para el usuario y devuelve el QR code.
    """
    # Generar secreto único
    secret = pyotp.random_base32()
    
    # Crear URI para TOTP
    totp = pyotp.TOTP(secret)
    provisioning_uri = totp.provisioning_uri(
        name=usuario.correo,
        issuer_name="Visitas Educativas Cauca"
    )
    
    # Generar QR code
    qr = qrcode.QRCode(version=1, box_size=10, border=5)
    qr.add_data(provisioning_uri)
    qr.make(fit=True)
    
    img = qr.make_image(fill_color="black", back_color="white")
    
    # Convertir imagen a base64
    img_buffer = io.BytesIO()
    img.save(img_buffer, format='PNG')
    img_str = base64.b64encode(img_buffer.getvalue()).decode()
    
    # Guardar secreto en BD (temporalmente, hasta que se confirme)
    usuario.twofa_secret = secret
    db.commit()
    
    return {
        "secret": secret,
        "qr_code": f"data:image/png;base64,{img_str}",
        "provisioning_uri": provisioning_uri
    }

def verificar_2fa_code(usuario: models.Usuario, codigo: str) -> bool:
    """
    Verifica un código TOTP contra el secreto del usuario.
    """
    if not usuario.twofa_secret:
        return False
    
    totp = pyotp.TOTP(usuario.twofa_secret)
    return totp.verify(codigo)

def habilitar_2fa(usuario: models.Usuario, codigo: str, db: Session) -> bool:
    """
    Habilita 2FA para un usuario después de verificar el código.
    """
    if verificar_2fa_code(usuario, codigo):
        usuario.twofa_enabled = True
        db.commit()
        return True
    return False

def registrar_sesion(
    usuario: models.Usuario,
    token_jti: str,
    ip_address: str,
    user_agent: str,
    fecha_expiracion: datetime,
    db: Session
):
    """
    Registra una nueva sesión de usuario.
    """
    nueva_sesion = models.SesionUsuario(
        usuario_id=usuario.id,
        token_jti=token_jti,
        ip_address=ip_address,
        user_agent=user_agent,
        fecha_expiracion=fecha_expiracion
    )
    
    db.add(nueva_sesion)
    db.commit()
    db.refresh(nueva_sesion)
    
    return nueva_sesion

def cerrar_sesion(
    token_jti: str,
    motivo: str,
    db: Session
):
    """
    Cierra una sesión específica.
    """
    sesion = db.query(models.SesionUsuario).filter(
        models.SesionUsuario.token_jti == token_jti,
        models.SesionUsuario.activa == True
    ).first()
    
    if sesion:
        sesion.activa = False
        sesion.fecha_cierre = datetime.utcnow()
        sesion.motivo_cierre = motivo
        db.commit()

def cerrar_todas_sesiones_usuario(
    usuario_id: int,
    motivo: str,
    db: Session,
    excepto_token: str = None
):
    """
    Cierra todas las sesiones activas de un usuario.
    """
    query = db.query(models.SesionUsuario).filter(
        models.SesionUsuario.usuario_id == usuario_id,
        models.SesionUsuario.activa == True
    )
    
    if excepto_token:
        query = query.filter(models.SesionUsuario.token_jti != excepto_token)
    
    sesiones = query.all()
    
    for sesion in sesiones:
        sesion.activa = False
        sesion.fecha_cierre = datetime.utcnow()
        sesion.motivo_cierre = motivo
    
    db.commit()
    
    return len(sesiones)

def registrar_auditoria(
    db: Session,
    actor_id: Optional[int],
    accion: str,
    recurso: str,
    recurso_id: Optional[str] = None,
    diff_before: Optional[dict] = None,
    diff_after: Optional[dict] = None,
    ip_address: Optional[str] = None,
    user_agent: Optional[str] = None,
    detalles_adicionales: Optional[dict] = None
):
    """
    Registra una entrada en el log de auditoría.
    """
    import json
    
    log_entry = models.AuditoriaLog(
        actor_id=actor_id,
        rol_actor=None,  # Se puede llenar después si es necesario
        accion=accion,
        recurso=recurso,
        recurso_id=str(recurso_id) if recurso_id else None,
        diff_before=json.dumps(diff_before) if diff_before else None,
        diff_after=json.dumps(diff_after) if diff_after else None,
        ip_address=ip_address,
        user_agent=user_agent,
        detalles_adicionales=json.dumps(detalles_adicionales) if detalles_adicionales else None
    )
    
    db.add(log_entry)
    db.commit()
    db.refresh(log_entry)
    
    return log_entry

def obtener_ip_request(request: Request) -> str:
    """
    Obtiene la IP real del request considerando proxies.
    """
    # Verificar headers de proxy
    forwarded_for = request.headers.get("X-Forwarded-For")
    if forwarded_for:
        return forwarded_for.split(",")[0].strip()
    
    real_ip = request.headers.get("X-Real-IP")
    if real_ip:
        return real_ip
    
    # Fallback a la IP del cliente directo
    return request.client.host if request.client else "unknown"

def verificar_politicas_seguridad(usuario: models.Usuario) -> List[str]:
    """
    Verifica las políticas de seguridad para un usuario.
    Retorna una lista de alertas/advertencias.
    """
    alertas = []
    
    # Verificar expiración de contraseña
    if usuario.fecha_expiracion_contrasena:
        if datetime.utcnow() > usuario.fecha_expiracion_contrasena:
            alertas.append("Contraseña expirada. Debe cambiarla.")
        elif (usuario.fecha_expiracion_contrasena - datetime.utcnow()).days <= 7:
            dias_restantes = (usuario.fecha_expiracion_contrasena - datetime.utcnow()).days
            alertas.append(f"Su contraseña expira en {dias_restantes} días.")
    
    # Verificar intentos fallidos
    if usuario.intentos_fallidos >= 3:
        alertas.append("Múltiples intentos de acceso fallidos detectados.")
    
    # Verificar si está bloqueado
    if usuario.fecha_bloqueo:
        alertas.append(f"Cuenta bloqueada: {usuario.motivo_bloqueo}")
    
    return alertas
