from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List
from ..database import get_db
from ..models import Institucion
from ..schemas import InstitucionResponse

router = APIRouter(prefix="", tags=["instituciones"])

@router.get("/instituciones", response_model=List[InstitucionResponse])
def get_instituciones(db: Session = Depends(get_db)):
    """Obtener todas las instituciones desde instituciones_educativas"""
    try:
        # Obtener instituciones únicas desde instituciones_educativas
        sql = """
            SELECT DISTINCT 
                ie.institucion as nombre,
                m.id as municipio_id,
                ie.municipio
            FROM instituciones_educativas ie
            JOIN municipios m ON UPPER(m.nombre) = UPPER(ie.municipio)
            ORDER BY ie.institucion, ie.municipio
        """
        result = db.execute(text(sql)).fetchall()
        
        instituciones = []
        for idx, row in enumerate(result, 1):
            instituciones.append({
                "id": idx,  # ID secuencial
                "nombre": row.nombre,
                "dane": None,  # Campo opcional
                "municipio_id": row.municipio_id
            })
        return instituciones
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener instituciones: {str(e)}")

@router.get("/instituciones_por_municipio/{municipio_id}", response_model=List[InstitucionResponse])
def get_instituciones_por_municipio(municipio_id: int, db: Session = Depends(get_db)):
    """Obtener instituciones por municipio desde instituciones_educativas"""
    try:
        sql = """
            SELECT DISTINCT 
                ie.institucion as nombre,
                m.id as municipio_id,
                ie.municipio
            FROM instituciones_educativas ie
            JOIN municipios m ON UPPER(m.nombre) = UPPER(ie.municipio)
            WHERE m.id = :municipio_id
            ORDER BY ie.institucion
        """
        result = db.execute(text(sql), {"municipio_id": municipio_id}).fetchall()
        
        instituciones = []
        for idx, row in enumerate(result, 1):
            instituciones.append({
                "id": idx,  # ID secuencial
                "nombre": row.nombre,
                "dane": None,  # Campo opcional
                "municipio_id": row.municipio_id
            })
        return instituciones
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener instituciones por municipio: {str(e)}")

@router.get("/instituciones/{institucion_id}", response_model=InstitucionResponse)
def get_institucion(institucion_id: int, db: Session = Depends(get_db)):
    """Obtener una institución específica por ID desde la vista consolidada"""
    try:
        sql = """
            SELECT 
                ROW_NUMBER() OVER (ORDER BY nombre, municipio) as id,
                nombre,
                municipio_id
            FROM instituciones_consolidadas
            ORDER BY nombre, municipio
            LIMIT 1 OFFSET :offset
        """
        result = db.execute(text(sql), {"offset": institucion_id - 1}).first()
        if not result:
            raise HTTPException(status_code=404, detail="Institución no encontrada")
        
        return {
            "id": result.id,
            "nombre": result.nombre,
            "dane": None,  # Campo opcional
            "municipio_id": result.municipio_id
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener institución: {str(e)}") 