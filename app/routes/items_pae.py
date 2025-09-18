# app/routes/items_pae.py

from fastapi import APIRouter, HTTPException, Depends, status, Request
from sqlalchemy.orm import Session, joinedload
from typing import List
from .. import models, schemas
from ..database import get_db
from jose import JWTError, jwt
import os

router = APIRouter(prefix="/items-pae", tags=["Items PAE"])

# Configuración de JWT
SECRET_KEY = os.getenv("SECRET_KEY", "una_clave_secreta_por_defecto_solo_para_desarrollo")
ALGORITHM = "HS256"

def verificar_token_simple(request: Request, db: Session = Depends(get_db)):
    """Verificación simple del token para el endpoint de items PAE"""
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

@router.get("/", response_model=List[schemas.ChecklistCategoriaBase])
def listar_items_pae(
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(verificar_token_simple)
):
    """
    Lista todos los items del checklist PAE organizados por categorías.
    """
    try:
        # Obtener todas las categorías con sus items
        categorias = db.query(models.ChecklistCategoria).options(
            joinedload(models.ChecklistCategoria.items)
        ).order_by(models.ChecklistCategoria.id).all()
        
        print(f"🔍 Usuario {usuario_actual.id} ({usuario_actual.nombre}) - Encontradas {len(categorias)} categorías de checklist")
        
        return categorias
        
    except Exception as e:
        print(f"❌ Error al listar items PAE: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al cargar items PAE: {str(e)}"
        )
