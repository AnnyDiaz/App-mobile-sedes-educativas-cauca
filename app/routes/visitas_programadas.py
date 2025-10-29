# app/routes/visitas_programadas.py

from fastapi import APIRouter, HTTPException, Depends, status, Request
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional
from datetime import datetime
from .. import models, schemas
from ..database import get_db
from jose import JWTError, jwt
import os
from pydantic import BaseModel

router = APIRouter(prefix="/visitas-programadas", tags=["Visitas Programadas"])

# Configuración de JWT
SECRET_KEY = os.getenv("SECRET_KEY", "una_clave_secreta_por_defecto_solo_para_desarrollo")
ALGORITHM = "HS256"

def verificar_token_simple(request: Request, db: Session = Depends(get_db)):
    """Verificación simple del token para el endpoint de visitas programadas"""
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

# Schema para visitas programadas
class VisitaProgramadaCreate(BaseModel):
    sede_id: int
    visitador_id: int
    fecha_programada: datetime
    contrato: str
    operador: str
    observaciones: Optional[str] = None
    estado: str = "programada"
    municipio_id: int
    institucion_id: int

class VisitaProgramadaOut(BaseModel):
    id: int
    sede_id: int
    sede_nombre: str
    visitador_id: int
    visitador_nombre: str
    fecha_programada: datetime
    contrato: str
    operador: str
    observaciones: Optional[str] = None
    estado: str
    municipio_id: int
    municipio_nombre: str
    institucion_id: int
    institucion_nombre: str
    fecha_creacion: datetime

    class Config:
        from_attributes = True

@router.get("/", response_model=List[VisitaProgramadaOut])
def obtener_visitas_programadas(
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(verificar_token_simple)
):
    """
    Obtiene todas las visitas programadas del usuario autenticado.
    Para visitadores: solo sus propias visitas
    Para supervisores: todas las visitas
    """
    try:
        if usuario_actual.rol.nombre == 'visitador':
            # Para visitadores, solo sus propias visitas
            visitas = db.query(models.VisitaProgramada).options(
                joinedload(models.VisitaProgramada.sede),
                joinedload(models.VisitaProgramada.visitador),
                joinedload(models.VisitaProgramada.municipio),
                joinedload(models.VisitaProgramada.institucion)
            ).filter(
                models.VisitaProgramada.visitador_id == usuario_actual.id
            ).all()
        else:
            # Para supervisores, todas las visitas
            visitas = db.query(models.VisitaProgramada).options(
                joinedload(models.VisitaProgramada.sede),
                joinedload(models.VisitaProgramada.visitador),
                joinedload(models.VisitaProgramada.municipio),
                joinedload(models.VisitaProgramada.institucion)
            ).all()
        
        # Convertir a formato de salida
        resultado = []
        for visita in visitas:
            resultado.append(VisitaProgramadaOut(
                id=visita.id,
                sede_id=visita.sede_id,
                sede_nombre=visita.sede.nombre_sede if visita.sede else "N/A",
                visitador_id=visita.visitador_id,
                visitador_nombre=visita.visitador.nombre if visita.visitador else "N/A",
                fecha_programada=visita.fecha_programada,
                contrato=visita.contrato,
                operador=visita.operador,
                observaciones=visita.observaciones,
                estado=visita.estado,
                municipio_id=visita.municipio_id,
                municipio_nombre=visita.municipio.nombre if visita.municipio else "N/A",
                institucion_id=visita.institucion_id,
                institucion_nombre=visita.institucion.nombre if visita.institucion else "N/A",
                fecha_creacion=visita.fecha_creacion
            ))
        
        return resultado
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error interno del servidor: {str(e)}")

@router.post("/", response_model=VisitaProgramadaOut)
def crear_visita_programada(
    visita: VisitaProgramadaCreate,
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(verificar_token_simple)
):
    """
    Crea una nueva visita programada. Solo accesible para supervisores.
    """
    try:
        # Verificar permisos
        if usuario_actual.rol.nombre != 'supervisor':
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No tienes permiso para programar visitas."
            )
        
        # Verificar que la sede existe
        sede = db.query(models.SedeEducativa).filter(models.SedeEducativa.id == visita.sede_id).first()
        if not sede:
            raise HTTPException(status_code=404, detail="Sede no encontrada")
        
        # Verificar que el visitador existe y tiene rol de visitador
        visitador = db.query(models.Usuario).options(
            joinedload(models.Usuario.rol)
        ).filter(models.Usuario.id == visita.visitador_id).first()
        if not visitador:
            raise HTTPException(status_code=404, detail="Visitador no encontrado")
        if visitador.rol.nombre.lower() != 'visitador':
            raise HTTPException(status_code=400, detail="El usuario seleccionado no es un visitador")
        
        # Verificar que el municipio existe
        municipio = db.query(models.Municipio).filter(models.Municipio.id == visita.municipio_id).first()
        if not municipio:
            raise HTTPException(status_code=404, detail="Municipio no encontrado")
        
        # Verificar que la institución existe
        institucion = db.query(models.Institucion).filter(models.Institucion.id == visita.institucion_id).first()
        if not institucion:
            raise HTTPException(status_code=404, detail="Institución no encontrada")
        
        # Crear la visita programada
        nueva_visita = models.VisitaProgramada(
            sede_id=visita.sede_id,
            visitador_id=visita.visitador_id,
            fecha_programada=visita.fecha_programada,
            contrato=visita.contrato,
            operador=visita.operador,
            observaciones=visita.observaciones,
            estado=visita.estado,
            municipio_id=visita.municipio_id,
            institucion_id=visita.institucion_id,
            fecha_creacion=datetime.utcnow()
        )
        
        db.add(nueva_visita)
        db.commit()
        db.refresh(nueva_visita)
        
        print(f"✅ Visita programada creada exitosamente: ID={nueva_visita.id}")
        
        # Retornar la visita programada con información completa
        return VisitaProgramadaOut(
            id=nueva_visita.id,
            sede_id=nueva_visita.sede_id,
            sede_nombre=sede.nombre_sede,
            visitador_id=nueva_visita.visitador_id,
            visitador_nombre=visitador.nombre,
            fecha_programada=nueva_visita.fecha_programada,
            contrato=nueva_visita.contrato,
            operador=nueva_visita.operador,
            observaciones=nueva_visita.observaciones,
            estado=nueva_visita.estado,
            municipio_id=nueva_visita.municipio_id,
            municipio_nombre=municipio.nombre,
            institucion_id=nueva_visita.institucion_id,
            institucion_nombre=institucion.nombre,
            fecha_creacion=nueva_visita.fecha_creacion
        )
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        print(f"❌ Error al crear visita programada: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al crear visita programada: {str(e)}"
        )

@router.get("/mis-visitas", response_model=List[VisitaProgramadaOut])
def obtener_mis_visitas_programadas(
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(verificar_token_simple)
):
    """
    Obtiene las visitas programadas asignadas al usuario actual (visitador).
    """
    try:
        # Verificar que el usuario es un visitador
        if usuario_actual.rol.nombre.lower() != 'visitador':
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Solo los visitadores pueden ver sus visitas programadas."
            )
        
        # Obtener las visitas programadas del visitador
        visitas = db.query(models.VisitaProgramada).filter(
            models.VisitaProgramada.visitador_id == usuario_actual.id
        ).order_by(models.VisitaProgramada.fecha_programada).all()
        
        print(f"🔍 Visitador {usuario_actual.id} ({usuario_actual.nombre}) - Encontradas {len(visitas)} visitas programadas")
        
        # Convertir a formato de salida
        visitas_out = []
        for visita in visitas:
            # Obtener información relacionada
            sede = db.query(models.SedeEducativa).filter(models.SedeEducativa.id == visita.sede_id).first()
            municipio = db.query(models.Municipio).filter(models.Municipio.id == visita.municipio_id).first()
            institucion = db.query(models.Institucion).filter(models.Institucion.id == visita.institucion_id).first()
            
            visita_out = VisitaProgramadaOut(
                id=visita.id,
                sede_id=visita.sede_id,
                sede_nombre=sede.nombre_sede if sede else "Sede no encontrada",
                visitador_id=visita.visitador_id,
                visitador_nombre=usuario_actual.nombre,
                fecha_programada=visita.fecha_programada,
                contrato=visita.contrato,
                operador=visita.operador,
                observaciones=visita.observaciones,
                estado=visita.estado,
                municipio_id=visita.municipio_id,
                municipio_nombre=municipio.nombre if municipio else "Municipio no encontrado",
                institucion_id=visita.institucion_id,
                institucion_nombre=institucion.nombre if institucion else "Institución no encontrada",
                fecha_creacion=visita.fecha_creacion
            )
            visitas_out.append(visita_out)
        
        return visitas_out
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error al obtener visitas programadas: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al obtener visitas programadas: {str(e)}"
        )

@router.put("/{visita_id}/estado")
def actualizar_estado_visita_programada(
    visita_id: int,
    estado: str,
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(verificar_token_simple)
):
    """
    Actualiza el estado de una visita programada.
    """
    try:
        # Buscar la visita programada
        visita = db.query(models.VisitaProgramada).filter(
            models.VisitaProgramada.id == visita_id
        ).first()
        
        if not visita:
            raise HTTPException(status_code=404, detail="Visita programada no encontrada")
        
        # Verificar permisos (solo el visitador asignado o un supervisor puede cambiar el estado)
        if usuario_actual.rol.nombre.lower() == 'visitador' and visita.visitador_id != usuario_actual.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No tienes permiso para cambiar el estado de esta visita."
            )
        
        # Actualizar el estado
        visita.estado = estado
        db.commit()
        
        print(f"✅ Estado de visita programada {visita_id} actualizado a: {estado}")
        
        return {"mensaje": f"Estado actualizado a: {estado}"}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        print(f"❌ Error al actualizar estado: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al actualizar estado: {str(e)}"
        )

@router.get("/todas-visitas-usuario", response_model=List[VisitaProgramadaOut])
def obtener_todas_visitas_usuario(
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(verificar_token_simple)
):
    """
    Obtiene todas las visitas del usuario autenticado (programadas + asignadas)
    Para el calendario y vista general
    """
    try:
        # Cargar el rol del usuario
        usuario_con_rol = db.query(models.Usuario).options(
            joinedload(models.Usuario.rol)
        ).filter(models.Usuario.id == usuario_actual.id).first()
        
        if not usuario_con_rol:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")
        
        resultado = []
        
        # Obtener visitas programadas
        visitas_programadas = db.query(models.VisitaProgramada).options(
            joinedload(models.VisitaProgramada.sede),
            joinedload(models.VisitaProgramada.visitador),
            joinedload(models.VisitaProgramada.municipio),
            joinedload(models.VisitaProgramada.institucion)
        ).filter(
            models.VisitaProgramada.visitador_id == usuario_actual.id
        ).all()

        # Convertir visitas programadas
        for visita in visitas_programadas:
            resultado.append(VisitaProgramadaOut(
                id=visita.id,
                sede_id=visita.sede_id,
                sede_nombre=visita.sede.nombre_sede if visita.sede else "N/A",
                visitador_id=visita.visitador_id,
                visitador_nombre=visita.visitador.nombre if visita.visitador else "N/A",
                fecha_programada=visita.fecha_programada,
                contrato=visita.contrato,
                operador=visita.operador,
                observaciones=visita.observaciones,
                estado=visita.estado,
                municipio_id=visita.municipio_id,
                municipio_nombre=visita.municipio.nombre if visita.municipio else "N/A",
                institucion_id=visita.institucion_id,
                institucion_nombre=visita.institucion.nombre if visita.institucion else "N/A",
                fecha_creacion=visita.fecha_creacion
            ))

        # Solo obtener visitas asignadas si es visitador
        if usuario_con_rol.rol.nombre.lower() == 'visitador':
            # Obtener visitas asignadas
            visitas_asignadas = db.query(models.VisitaAsignada).options(
                joinedload(models.VisitaAsignada.sede),
                joinedload(models.VisitaAsignada.visitador),
                joinedload(models.VisitaAsignada.municipio),
                joinedload(models.VisitaAsignada.institucion)
            ).filter(
                models.VisitaAsignada.visitador_id == usuario_actual.id
            ).all()

            # Convertir visitas asignadas
            for visita in visitas_asignadas:
                resultado.append(VisitaProgramadaOut(
                    id=visita.id,
                    sede_id=visita.sede_id,
                    sede_nombre=visita.sede.nombre_sede if visita.sede else "N/A",
                    visitador_id=visita.visitador_id,
                    visitador_nombre=visita.visitador.nombre if visita.visitador else "N/A",
                    fecha_programada=visita.fecha_programada,
                    contrato=visita.contrato or "N/A",
                    operador=visita.operador or "N/A",
                    observaciones=visita.observaciones,
                    estado=visita.estado,
                    municipio_id=visita.municipio_id,
                    municipio_nombre=visita.municipio.nombre if visita.municipio else "N/A",
                    institucion_id=visita.institucion_id,
                    institucion_nombre=visita.institucion.nombre if visita.institucion else "N/A",
                    fecha_creacion=visita.fecha_creacion
                ))

        return resultado

    except Exception as e:
        print(f"❌ Error en obtener_todas_visitas_usuario: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error interno del servidor: {str(e)}")
