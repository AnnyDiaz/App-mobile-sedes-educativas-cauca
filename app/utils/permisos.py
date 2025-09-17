# app/utils/permisos.py

from fastapi import HTTPException
from app import models

def verificar_permiso_eliminar(usuario: models.Usuario):
    """
    Verifica si el usuario tiene permisos para eliminar registros.
    Los supervisores NO pueden eliminar registros por política de seguridad.
    """
    if usuario.rol.nombre == "supervisor":
        raise HTTPException(
            status_code=403,
            detail="Acceso denegado. Los supervisores no pueden eliminar registros por motivos de seguridad y auditoría."
        )
    
    return True

def verificar_permiso_modificar_historico(usuario: models.Usuario):
    """
    Verifica si el usuario puede modificar registros históricos.
    Los supervisores tienen limitaciones en modificaciones históricas.
    """
    if usuario.rol.nombre == "supervisor":
        raise HTTPException(
            status_code=403,
            detail="Acceso denegado. Los supervisores no pueden modificar registros históricos por motivos de auditoría."
        )
    
    return True

def es_supervisor(usuario: models.Usuario) -> bool:
    """Verifica si el usuario es supervisor"""
    return usuario.rol.nombre == "supervisor"

def es_administrador(usuario: models.Usuario) -> bool:
    """Verifica si el usuario es administrador"""
    return usuario.rol.nombre == "administrador"

def es_visitador(usuario: models.Usuario) -> bool:
    """Verifica si el usuario es visitador"""
    return usuario.rol.nombre.lower() == "visitador"

def puede_eliminar_registros(usuario: models.Usuario) -> bool:
    """Determina si el usuario puede eliminar registros"""
    return not es_supervisor(usuario)

def puede_modificar_historico(usuario: models.Usuario) -> bool:
    """Determina si el usuario puede modificar registros históricos"""
    return not es_supervisor(usuario)
