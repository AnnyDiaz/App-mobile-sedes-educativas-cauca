from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
from app import models, schemas
from app.database import get_db

router = APIRouter()

# Configuración JWT y seguridad
SECRET_KEY = "clave-secreta"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60
bearer_scheme = HTTPBearer()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# --------------------------
# REGISTRO
# --------------------------
@router.post("/register")
def register(usuario: schemas.UsuarioCreate, db: Session = Depends(get_db)):
    usuario_existente = db.query(models.Usuario).filter(models.Usuario.correo == usuario.correo).first()
    if usuario_existente:
        raise HTTPException(status_code=400, detail="El correo ya está registrado")

    nuevo_usuario = models.Usuario(
        nombre=usuario.nombre,
        correo=usuario.correo,
        contrasena=pwd_context.hash(usuario.contrasena),
        rol_id=usuario.rol_id
    )
    db.add(nuevo_usuario)
    db.commit()
    db.refresh(nuevo_usuario)

    expiration = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    token_data = {
        "sub": nuevo_usuario.correo,
        "rol": nuevo_usuario.rol.nombre,
        "exp": expiration
    }
    token = jwt.encode(token_data, SECRET_KEY, algorithm=ALGORITHM)

    usuario_out = schemas.UsuarioOut(
        id=nuevo_usuario.id,
        nombre=nuevo_usuario.nombre,
        correo=nuevo_usuario.correo,
        rol=nuevo_usuario.rol.nombre
    )

    return {
        "access_token": token,
        "token_type": "bearer",
        "usuario": usuario_out
    }

# --------------------------
# LOGIN
# --------------------------
@router.post("/login")
def login(user: schemas.Login, db: Session = Depends(get_db)):
    usuario = db.query(models.Usuario).filter(models.Usuario.correo == user.correo).first()
    if not usuario or not pwd_context.verify(user.contrasena, usuario.contrasena):
        raise HTTPException(status_code=401, detail="Credenciales inválidas")

    expiration = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    token_data = {
        "sub": usuario.correo,
        "rol": usuario.rol.nombre,
        "exp": expiration
    }
    token = jwt.encode(token_data, SECRET_KEY, algorithm=ALGORITHM)

    usuario_out = schemas.UsuarioOut(
        id=usuario.id,
        nombre=usuario.nombre,
        correo=usuario.correo,
        rol=usuario.rol.nombre
    )

    return {
        "access_token": token,
        "token_type": "bearer",
        "usuario": usuario_out
    }

# --------------------------
# OBTENER USUARIO ACTUAL
# --------------------------
def obtener_usuario_actual(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db)
):
    token = credentials.credentials

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        correo = payload.get("sub")
        if correo is None:
            raise HTTPException(status_code=401, detail="Token inválido")
    except JWTError:
        raise HTTPException(status_code=401, detail="Token inválido")

    usuario = db.query(models.Usuario).filter(models.Usuario.correo == correo).first()
    if usuario is None:
        raise HTTPException(status_code=401, detail="Usuario no encontrado")

    return usuario

# --------------------------
# VERIFICAR ROL PERMITIDO
# --------------------------
def verificar_rol_permitido(roles_permitidos: list):
    def validador(credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme), db: Session = Depends(get_db)):
        token = credentials.credentials
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            correo = payload.get("sub")
            rol = payload.get("rol")
            if correo is None or rol is None:
                raise HTTPException(status_code=401, detail="Token inválido")
            if rol not in roles_permitidos:
                raise HTTPException(status_code=403, detail="Acceso denegado: rol no autorizado")
        except JWTError:
            raise HTTPException(status_code=401, detail="Token inválido")

        usuario = db.query(models.Usuario).filter(models.Usuario.correo == correo).first()
        if usuario is None:
            raise HTTPException(status_code=401, detail="Usuario no encontrado")

        return usuario
    return validador

# --------------------------
# CAMBIAR CONTRASEÑA
# --------------------------
@router.put("/cambiar-contrasena")
def cambiar_contrasena(
    datos: schemas.CambioContrasena,
    db: Session = Depends(get_db),
    usuario: models.Usuario = Depends(obtener_usuario_actual)
):
    if not pwd_context.verify(datos.actual, usuario.contrasena):
        raise HTTPException(status_code=400, detail="Contraseña actual incorrecta")

    usuario.contrasena = pwd_context.hash(datos.nueva)
    db.commit()
    return {"mensaje": "Contraseña actualizada correctamente"}

# --------------------------
# RECUPERAR CONTRASEÑA
# --------------------------
@router.post("/recuperar")
def recuperar_contrasena(datos: schemas.RecuperarContrasena, db: Session = Depends(get_db)):
    usuario = db.query(models.Usuario).filter(models.Usuario.correo == datos.correo).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Correo no encontrado")

    expiration = datetime.utcnow() + timedelta(minutes=15)
    token_data = {
        "sub": usuario.correo,
        "exp": expiration,
        "tipo": "recuperacion"
    }
    token = jwt.encode(token_data, SECRET_KEY, algorithm=ALGORITHM)

    print(f"Token de recuperación para {usuario.correo}: {token}")

    return {
        "mensaje": "Se ha generado un token de recuperación. Revise su correo (simulado).",
        "token": token
    }

# --------------------------
# RESTABLECER CONTRASEÑA
# --------------------------
@router.post("/restablecer-contrasena")
def restablecer_contrasena(datos: schemas.RestablecerContrasena, db: Session = Depends(get_db)):
    try:
        payload = jwt.decode(datos.token, SECRET_KEY, algorithms=[ALGORITHM])
        correo = payload.get("sub")
        tipo = payload.get("tipo")
        if tipo != "recuperacion":
            raise HTTPException(status_code=400, detail="Token inválido para esta acción")
    except JWTError:
        raise HTTPException(status_code=400, detail="Token inválido o expirado")

    usuario = db.query(models.Usuario).filter(models.Usuario.correo == correo).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    usuario.contrasena = pwd_context.hash(datos.nueva_contrasena)
    db.commit()
    return {"mensaje": "Contraseña restablecida exitosamente"}
