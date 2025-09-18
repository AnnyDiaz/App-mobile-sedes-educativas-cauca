from fastapi import APIRouter, HTTPException, Depends, status, Request
from sqlalchemy.orm import Session, joinedload
from typing import List
from datetime import datetime
from .. import models, schemas
from ..database import get_db
from jose import JWTError, jwt
import os

router = APIRouter(prefix="/usuarios", tags=["Usuarios"])

# Configuración de JWT
SECRET_KEY = os.getenv("SECRET_KEY", "una_clave_secreta_por_defecto_solo_para_desarrollo")
ALGORITHM = "HS256"

def verificar_token_simple(request: Request, db: Session = Depends(get_db)):
    """Verificación simple del token para el endpoint de usuarios"""
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Not authenticated")
    
    token = auth_header.replace("Bearer ", "")
    
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        correo = payload.get("sub")
        if not correo:
            raise HTTPException(status_code=401, detail="Token inválido")
        
        usuario = db.query(models.Usuario).options(
            joinedload(models.Usuario.rol)
        ).filter(models.Usuario.correo == correo).first()
        
        if not usuario:
            raise HTTPException(status_code=401, detail="Usuario no encontrado")
        
        return usuario
    except JWTError:
        raise HTTPException(status_code=401, detail="Token inválido")

@router.get("/", response_model=List[schemas.UsuarioFrontendOut])
def listar_usuarios(
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(verificar_token_simple)
):
    """
    Lista todos los usuarios. Solo accesible para supervisores y administradores.
    """
    try:
        # Verificar permisos
        if usuario_actual.rol.nombre not in ['supervisor', 'admin']:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No tienes permiso para ver todos los usuarios."
            )
        
        # Obtener todos los usuarios con sus roles cargados
        usuarios = db.query(models.Usuario).options(
            joinedload(models.Usuario.rol)
        ).order_by(models.Usuario.nombre).all()
        
        print(f"🔍 Usuario {usuario_actual.id} ({usuario_actual.nombre}) - Encontrados {len(usuarios)} usuarios")
        for usuario in usuarios:
            print(f"   - Usuario ID: {usuario.id}, Nombre: {usuario.nombre}, Rol: {usuario.rol.nombre}")
        
        # Convertir a formato compatible con frontend
        usuarios_frontend = []
        for usuario in usuarios:
            usuario_frontend = schemas.UsuarioFrontendOut(
                id=usuario.id,
                nombre=usuario.nombre,
                apellido=None,  # No existe en el modelo actual
                correo=usuario.correo,
                rol=usuario.rol.nombre,  # Convertir objeto Rol a string
                activo=True,  # Por defecto activo
                fechaCreacion=datetime.utcnow(),  # Por defecto ahora
            )
            usuarios_frontend.append(usuario_frontend)
        
        return usuarios_frontend
    except Exception as e:
        print(f"❌ Error al listar usuarios: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al cargar usuarios: {str(e)}"
        )

@router.post("/", response_model=schemas.UsuarioOut)
def crear_usuario(
    usuario: schemas.UsuarioCreate, 
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(verificar_token_simple)
):
    """
    Crea un nuevo usuario. Solo accesible para administradores.
    """
    try:
        # Verificar permisos
        if usuario_actual.rol.nombre != 'admin':
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No tienes permiso para crear usuarios."
            )
        
        # Verificar si el correo ya existe
        db_usuario = db.query(models.Usuario).filter(models.Usuario.correo == usuario.correo).first()
        if db_usuario:
            raise HTTPException(status_code=400, detail="Correo ya registrado")
        
        # Verificar que el rol existe
        rol = db.query(models.Rol).filter(models.Rol.id == usuario.rol_id).first()
        if not rol:
            raise HTTPException(status_code=400, detail="Rol no encontrado")
        
        # Crear hash de la contraseña
        from passlib.context import CryptContext
        pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
        contrasena_hash = pwd_context.hash(usuario.contrasena)
        
        # Crear nuevo usuario
        nuevo_usuario = models.Usuario(
            nombre=usuario.nombre,
            correo=usuario.correo,
            contrasena=contrasena_hash,
            rol_id=usuario.rol_id
        )
        
        db.add(nuevo_usuario)
        db.commit()
        db.refresh(nuevo_usuario)
        
        print(f"✅ Usuario creado exitosamente: {nuevo_usuario.nombre} ({nuevo_usuario.correo})")
        return nuevo_usuario
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        print(f"❌ Error al crear usuario: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al crear usuario: {str(e)}"
        )

@router.get("/{usuario_id}", response_model=schemas.UsuarioOut)
def obtener_usuario(
    usuario_id: int,
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(verificar_token_simple)
):
    """
    Obtiene un usuario específico por ID. Solo accesible para supervisores y administradores.
    """
    try:
        # Verificar permisos
        if usuario_actual.rol.nombre not in ['supervisor', 'admin']:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No tienes permiso para ver usuarios."
            )
        
        # Obtener usuario con rol cargado
        usuario = db.query(models.Usuario).options(
            joinedload(models.Usuario.rol)
        ).filter(models.Usuario.id == usuario_id).first()
        
        if not usuario:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")
        
        return usuario
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error al obtener usuario: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al obtener usuario: {str(e)}"
        )

