from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List
from ..database import get_db
from ..models import SedeEducativa, Institucion, Municipio, Usuario
from .. import models
from ..schemas import SedeResponse, SedeEducativaCreate, SedeEducativaUpdate, SedeEducativaBasicaOut
from ..routes.auth import obtener_usuario_actual, verificar_rol_permitido

router = APIRouter(prefix="", tags=["sedes"])

@router.get("/sedes", response_model=List[SedeEducativaBasicaOut])
def get_sedes(db: Session = Depends(get_db)):
    """Obtener todas las sedes desde la tabla sedes_educativas"""
    try:
        sedes_db = db.query(models.SedeEducativa).order_by(models.SedeEducativa.nombre_sede).all()
        
        sedes = []
        for sede in sedes_db:
            sedes.append({
                "id": sede.id,
                "nombre": sede.nombre_sede,
                "dane": sede.dane,
                "due": sede.due,
                "municipio_id": sede.municipio_id,
                "institucion_id": sede.institucion_id,
                "principal": sede.principal,
                "lat": sede.lat,
                "lon": sede.lon
            })
        return sedes
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener sedes: {str(e)}")

@router.get("/test_sedes")
def test_sedes():
    """Endpoint de prueba para sedes"""
    return {"message": "Test endpoint funciona", "sedes": []}

@router.get("/sedes_institucion/{institucion_id}", response_model=List[SedeEducativaBasicaOut])
def get_sedes_institucion(institucion_id: int, db: Session = Depends(get_db)):
    """Obtener sedes por institución desde la base de datos"""
    try:
        # Consultar sedes directamente desde la tabla sedes_educativas
        sedes = db.query(models.SedeEducativa).filter(
            models.SedeEducativa.institucion_id == institucion_id
        ).all()
        
        resultado = []
        for sede in sedes:
            resultado.append({
                "id": sede.id,
                "nombre": sede.nombre_sede,
                "dane": sede.dane,
                "due": sede.due,
                "municipio_id": sede.municipio_id,
                "institucion_id": sede.institucion_id,
                "principal": sede.principal,
                "lat": sede.lat,
                "lon": sede.lon
            })
        
        return resultado
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener sedes por institución: {str(e)}")

@router.get("/sedes_por_institucion/{institucion_id}", response_model=List[SedeEducativaBasicaOut])
def get_sedes_por_institucion(institucion_id: int, db: Session = Depends(get_db)):
    """Obtener sedes por institución desde la base de datos"""
    try:
        # Consultar sedes directamente desde la tabla sedes_educativas
        sedes = db.query(models.SedeEducativa).filter(
            models.SedeEducativa.institucion_id == institucion_id
        ).all()
        
        resultado = []
        for sede in sedes:
            resultado.append({
                "id": sede.id,
                "nombre": sede.nombre_sede,
                "dane": sede.dane,
                "due": sede.due,
                "municipio_id": sede.municipio_id,
                "institucion_id": sede.institucion_id,
                "principal": sede.principal,
                "lat": sede.lat,
                "lon": sede.lon
            })
        
        return resultado
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener sedes por institución: {str(e)}")

@router.get("/sedes_por_municipio/{municipio_id}", response_model=List[SedeEducativaBasicaOut])
def get_sedes_por_municipio(municipio_id: int, db: Session = Depends(get_db)):
    """Obtener sedes por municipio desde la vista consolidada"""
    try:
        sedes_db = db.query(models.SedeEducativa).filter(
            models.SedeEducativa.municipio_id == municipio_id
        ).order_by(models.SedeEducativa.nombre_sede).all()
        
        sedes = []
        for sede in sedes_db:
            sedes.append({
                "id": sede.id,
                "nombre": sede.nombre_sede,
                "dane": sede.dane,
                "due": sede.due,
                "municipio_id": sede.municipio_id,
                "institucion_id": sede.institucion_id,
                "principal": sede.principal,
                "lat": sede.lat,
                "lon": sede.lon
            })
        return sedes
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener sedes por municipio: {str(e)}")

@router.get("/sedes/{sede_id}", response_model=SedeEducativaBasicaOut)
def get_sede(sede_id: int, db: Session = Depends(get_db)):
    """Obtener una sede específica por ID desde la vista consolidada"""
    try:
        sede = db.query(models.SedeEducativa).filter(models.SedeEducativa.id == sede_id).first()
        if not sede:
            raise HTTPException(status_code=404, detail="Sede no encontrada")
        
        return {
            "id": sede.id,
            "nombre": sede.nombre_sede,
            "dane": sede.dane,
            "due": sede.due,
            "municipio_id": sede.municipio_id,
            "institucion_id": sede.institucion_id,
            "principal": sede.principal,
            "lat": sede.lat,
            "lon": sede.lon
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener sede: {str(e)}")

@router.post("/sedes", response_model=SedeResponse)
def crear_sede(
    sede_data: SedeEducativaCreate, 
    db: Session = Depends(get_db),
    usuario: Usuario = Depends(verificar_rol_permitido(["supervisor", "admin"]))
):
    """Crear una nueva sede educativa (solo supervisores y admins)"""
    try:
        # Verificar que el municipio existe
        municipio = db.query(Municipio).filter(Municipio.id == sede_data.municipio_id).first()
        if not municipio:
            raise HTTPException(status_code=404, detail="Municipio no encontrado")
        
        # Verificar que la institución existe
        institucion = db.query(Institucion).filter(Institucion.id == sede_data.institucion_id).first()
        if not institucion:
            raise HTTPException(status_code=404, detail="Institución no encontrada")
        
        # Verificar que la institución pertenece al municipio especificado
        if institucion.municipio_id != sede_data.municipio_id:
            raise HTTPException(
                status_code=400, 
                detail="La institución no pertenece al municipio especificado"
            )
        
        # Verificar que el código DANE no esté duplicado
        sede_existente_dane = db.query(SedeEducativa).filter(SedeEducativa.dane == sede_data.dane).first()
        if sede_existente_dane:
            raise HTTPException(
                status_code=400, 
                detail=f"Ya existe una sede con el código DANE: {sede_data.dane}"
            )
        
        # Verificar que el código DUE no esté duplicado
        sede_existente_due = db.query(SedeEducativa).filter(SedeEducativa.due == sede_data.due).first()
        if sede_existente_due:
            raise HTTPException(
                status_code=400, 
                detail=f"Ya existe una sede con el código DUE: {sede_data.due}"
            )
        
        # Crear la nueva sede
        nueva_sede = SedeEducativa(
            nombre=sede_data.nombre,
            dane=sede_data.dane,
            due=sede_data.due,
            lat=sede_data.lat,
            lon=sede_data.lon,
            principal=sede_data.principal,
            municipio_id=sede_data.municipio_id,
            institucion_id=sede_data.institucion_id
        )
        
        db.add(nueva_sede)
        db.commit()
        db.refresh(nueva_sede)
        
        print(f"✅ Nueva sede creada por {usuario.nombre} ({usuario.rol.nombre}): {nueva_sede.nombre} (ID: {nueva_sede.id})")
        print(f"   - DANE: {nueva_sede.dane}")
        print(f"   - DUE: {nueva_sede.due}")
        print(f"   - Municipio: {municipio.nombre}")
        print(f"   - Institución: {institucion.nombre}")
        
        return nueva_sede
        
    except HTTPException:
        # Re-lanzar las excepciones HTTP que ya fueron creadas
        raise
    except Exception as e:
        db.rollback()
        print(f"❌ Error al crear sede: {str(e)}")
        raise HTTPException(
            status_code=500, 
            detail=f"Error interno al crear la sede: {str(e)}"
        )

@router.put("/sedes/{sede_id}", response_model=SedeResponse)
def actualizar_sede(
    sede_id: int, 
    sede_data: SedeEducativaUpdate, 
    db: Session = Depends(get_db),
    usuario: Usuario = Depends(verificar_rol_permitido(["supervisor", "admin"]))
):
    """Actualizar una sede educativa existente (solo supervisores y admins)"""
    try:
        # Buscar la sede existente
        sede = db.query(SedeEducativa).filter(SedeEducativa.id == sede_id).first()
        if not sede:
            raise HTTPException(status_code=404, detail="Sede no encontrada")
        
        # Verificar que el municipio existe (si se está actualizando)
        if sede_data.municipio_id is not None:
            municipio = db.query(Municipio).filter(Municipio.id == sede_data.municipio_id).first()
            if not municipio:
                raise HTTPException(status_code=404, detail="Municipio no encontrado")
        
        # Verificar que la institución existe (si se está actualizando)
        if sede_data.institucion_id is not None:
            institucion = db.query(Institucion).filter(Institucion.id == sede_data.institucion_id).first()
            if not institucion:
                raise HTTPException(status_code=404, detail="Institución no encontrada")
            
            # Verificar que la institución pertenece al municipio especificado
            if sede_data.municipio_id is not None and institucion.municipio_id != sede_data.municipio_id:
                raise HTTPException(
                    status_code=400, 
                    detail="La institución no pertenece al municipio especificado"
                )
        
        # Verificar que el código DANE no esté duplicado (si se está actualizando)
        if sede_data.dane is not None and sede_data.dane != sede.dane:
            sede_existente_dane = db.query(SedeEducativa).filter(
                SedeEducativa.dane == sede_data.dane,
                SedeEducativa.id != sede_id
            ).first()
            if sede_existente_dane:
                raise HTTPException(
                    status_code=400, 
                    detail=f"Ya existe una sede con el código DANE: {sede_data.dane}"
                )
        
        # Verificar que el código DUE no esté duplicado (si se está actualizando)
        if sede_data.due is not None and sede_data.due != sede.due:
            sede_existente_due = db.query(SedeEducativa).filter(
                SedeEducativa.due == sede_data.due,
                SedeEducativa.id != sede_id
            ).first()
            if sede_existente_due:
                raise HTTPException(
                    status_code=400, 
                    detail=f"Ya existe una sede con el código DUE: {sede_data.due}"
                )
        
        # Actualizar los campos proporcionados
        if sede_data.nombre is not None:
            sede.nombre = sede_data.nombre
        if sede_data.dane is not None:
            sede.dane = sede_data.dane
        if sede_data.due is not None:
            sede.due = sede_data.due
        if sede_data.lat is not None:
            sede.lat = sede_data.lat
        if sede_data.lon is not None:
            sede.lon = sede_data.lon
        if sede_data.principal is not None:
            sede.principal = sede_data.principal
        if sede_data.municipio_id is not None:
            sede.municipio_id = sede_data.municipio_id
        if sede_data.institucion_id is not None:
            sede.institucion_id = sede_data.institucion_id
        
        db.commit()
        db.refresh(sede)
        
        print(f"✅ Sede actualizada por {usuario.nombre} ({usuario.rol.nombre}): {sede.nombre} (ID: {sede.id})")
        print(f"   - DANE: {sede.dane}")
        print(f"   - DUE: {sede.due}")
        
        return sede
        
    except HTTPException:
        # Re-lanzar las excepciones HTTP que ya fueron creadas
        raise
    except Exception as e:
        db.rollback()
        print(f"❌ Error al actualizar sede: {str(e)}")
        raise HTTPException(
            status_code=500, 
            detail=f"Error interno al actualizar la sede: {str(e)}"
        )

@router.delete("/sedes/{sede_id}")
def eliminar_sede(
    sede_id: int, 
    db: Session = Depends(get_db),
    usuario: Usuario = Depends(verificar_rol_permitido(["admin"]))  # 🚫 SOLO ADMIN PUEDE ELIMINAR
):
    """Eliminar una sede educativa (solo administradores)"""
    # 🚫 Verificación adicional: Los supervisores NO pueden eliminar registros
    from app.utils.permisos import verificar_permiso_eliminar
    verificar_permiso_eliminar(usuario)
    
    try:
        sede = db.query(SedeEducativa).filter(SedeEducativa.id == sede_id).first()
        if not sede:
            raise HTTPException(status_code=404, detail="Sede no encontrada")
        
        # Verificar si hay visitas asociadas a esta sede
        from ..models import Visita, VisitaCompletaPAE
        visitas_count = db.query(Visita).filter(Visita.sede_id == sede_id).count()
        visitas_pae_count = db.query(VisitaCompletaPAE).filter(VisitaCompletaPAE.sede_id == sede_id).count()
        
        if visitas_count > 0 or visitas_pae_count > 0:
            raise HTTPException(
                status_code=400, 
                detail=f"No se puede eliminar la sede porque tiene {visitas_count + visitas_pae_count} visita(s) asociada(s)"
            )
        
        nombre_sede = sede.nombre
        db.delete(sede)
        db.commit()
        
        print(f"✅ Sede eliminada por {usuario.nombre} ({usuario.rol.nombre}): {nombre_sede} (ID: {sede_id})")
        
        return {"mensaje": f"Sede '{nombre_sede}' eliminada correctamente"}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        print(f"❌ Error al eliminar sede: {str(e)}")
        raise HTTPException(
            status_code=500, 
            detail=f"Error interno al eliminar la sede: {str(e)}"
        )
