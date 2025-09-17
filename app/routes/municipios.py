from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from ..database import get_db
from ..models import Municipio
from ..schemas import MunicipioResponse

router = APIRouter(prefix="", tags=["municipios"])

@router.get("/municipios", response_model=List[MunicipioResponse])
def get_municipios(db: Session = Depends(get_db)):
    """Obtener todos los municipios"""
    try:
        municipios = db.query(Municipio).all()
        return municipios
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener municipios: {str(e)}")

@router.get("/municipios/{municipio_id}", response_model=MunicipioResponse)
def get_municipio(municipio_id: int, db: Session = Depends(get_db)):
    """Obtener un municipio específico por ID"""
    municipio = db.query(Municipio).filter(Municipio.id == municipio_id).first()
    if not municipio:
        raise HTTPException(status_code=404, detail="Municipio no encontrado")
    return municipio 