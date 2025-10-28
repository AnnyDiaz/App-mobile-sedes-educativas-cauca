# app/routes/visitas_asignadas.py

from fastapi import APIRouter, HTTPException, Depends, status, Request, Query
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional
from datetime import datetime
from .. import models, schemas
from ..database import get_db
from jose import JWTError, jwt
import os

router = APIRouter(prefix="/visitas-asignadas", tags=["Visitas Asignadas"])

# Configuración de JWT
SECRET_KEY = os.getenv("SECRET_KEY", "una_clave_secreta_por_defecto_solo_para_desarrollo")
ALGORITHM = "HS256"

def verificar_token_simple(request: Request, db: Session = Depends(get_db)):
    """Verificación simple del token para el endpoint de visitas asignadas"""
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

@router.post("/", response_model=schemas.VisitaAsignadaOut)
def asignar_visita(
    visita: schemas.VisitaAsignadaCreate,
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(verificar_token_simple)
):
    """
    Asigna una nueva visita a un visitador. Solo accesible para supervisores.
    """
    try:
        # Verificar permisos
        if usuario_actual.rol.nombre.lower() != 'supervisor':
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No tienes permiso para asignar visitas."
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
        
        # Crear la visita asignada
        nueva_visita = models.VisitaAsignada(
            sede_id=visita.sede_id,
            visitador_id=visita.visitador_id,
            supervisor_id=usuario_actual.id,
            fecha_programada=visita.fecha_programada,
            tipo_visita=visita.tipo_visita,
            prioridad=visita.prioridad,
            contrato=visita.contrato,
            operador=visita.operador,
            caso_atencion_prioritaria=visita.caso_atencion_prioritaria,
            municipio_id=visita.municipio_id,
            institucion_id=visita.institucion_id,
            observaciones=visita.observaciones,
            estado="pendiente",
            fecha_creacion=datetime.utcnow()
        )
        
        db.add(nueva_visita)
        db.commit()
        db.refresh(nueva_visita)
        
        print(f"✅ Visita asignada exitosamente: ID={nueva_visita.id} a {visitador.nombre}")
        
        # Retornar la visita asignada con información completa
        return schemas.VisitaAsignadaOut(
            id=nueva_visita.id,
            sede_id=nueva_visita.sede_id,
            sede_nombre=sede.nombre,
            visitador_id=nueva_visita.visitador_id,
            visitador_nombre=visitador.nombre,
            supervisor_id=nueva_visita.supervisor_id,
            supervisor_nombre=usuario_actual.nombre,
            fecha_programada=nueva_visita.fecha_programada,
            tipo_visita=nueva_visita.tipo_visita,
            prioridad=nueva_visita.prioridad,
            estado=nueva_visita.estado,
            contrato=nueva_visita.contrato,
            operador=nueva_visita.operador,
            caso_atencion_prioritaria=nueva_visita.caso_atencion_prioritaria,
            municipio_id=nueva_visita.municipio_id,
            municipio_nombre=municipio.nombre,
            institucion_id=nueva_visita.institucion_id,
            institucion_nombre=institucion.nombre,
            observaciones=nueva_visita.observaciones,
            fecha_creacion=nueva_visita.fecha_creacion,
            fecha_inicio=nueva_visita.fecha_inicio,
            fecha_completada=nueva_visita.fecha_completada
        )
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        print(f"❌ Error al asignar visita: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al asignar visita: {str(e)}"
        )

@router.get("/mis-visitas", response_model=List[schemas.VisitaAsignadaOut])
def obtener_mis_visitas_asignadas(
    estado: Optional[str] = Query(None, description="Filtrar por estado: pendiente, en_proceso, completada, cancelada"),
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(verificar_token_simple)
):
    """
    Obtiene las visitas asignadas al usuario actual.
    Accesible para todos los usuarios autenticados.
    """
    try:
        print(f"🔍 Usuario solicitando visitas asignadas: {usuario_actual.correo}, Rol: {usuario_actual.rol.nombre if usuario_actual.rol else 'Sin rol'}")
        
        # Construir la consulta base
        query = db.query(models.VisitaAsignada).filter(
            models.VisitaAsignada.visitador_id == usuario_actual.id
        )
        
        # Aplicar filtro de estado si se especifica
        if estado:
            query = query.filter(models.VisitaAsignada.estado == estado)
        
        # Obtener las visitas ordenadas por fecha
        visitas = query.order_by(models.VisitaAsignada.fecha_programada).all()
        
        print(f"🔍 Visitador {usuario_actual.id} ({usuario_actual.nombre}) - Encontradas {len(visitas)} visitas asignadas")
        
        # Convertir a formato de salida
        visitas_out = []
        for visita in visitas:
            # Obtener información relacionada
            sede = db.query(models.SedeEducativa).filter(models.SedeEducativa.id == visita.sede_id).first()
            municipio = db.query(models.Municipio).filter(models.Municipio.id == visita.municipio_id).first()
            institucion = db.query(models.Institucion).filter(models.Institucion.id == visita.institucion_id).first()
            supervisor = db.query(models.Usuario).filter(models.Usuario.id == visita.supervisor_id).first()
            
            visita_out = schemas.VisitaAsignadaOut(
                id=visita.id,
                sede_id=visita.sede_id,
                sede_nombre=sede.nombre_sede if sede else "Sede no encontrada",
                visitador_id=visita.visitador_id,
                visitador_nombre=usuario_actual.nombre,
                supervisor_id=visita.supervisor_id,
                supervisor_nombre=supervisor.nombre if supervisor else "Supervisor no encontrado",
                fecha_programada=visita.fecha_programada,
                tipo_visita=visita.tipo_visita,
                prioridad=visita.prioridad,
                estado=visita.estado,
                contrato=visita.contrato,
                operador=visita.operador,
                caso_atencion_prioritaria=visita.caso_atencion_prioritaria,
                municipio_id=visita.municipio_id,
                municipio_nombre=municipio.nombre if municipio else "Municipio no encontrado",
                institucion_id=visita.institucion_id,
                institucion_nombre=institucion.nombre if institucion else "Institución no encontrada",
                observaciones=visita.observaciones,
                fecha_creacion=visita.fecha_creacion,
                fecha_inicio=visita.fecha_inicio,
                fecha_completada=visita.fecha_completada
            )
            visitas_out.append(visita_out)
        
        return visitas_out
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error al obtener visitas asignadas: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al obtener visitas asignadas: {str(e)}"
        )

@router.get("/supervisor", response_model=List[schemas.VisitaAsignadaOut])
def obtener_visitas_asignadas_por_supervisor(
    visitador_id: Optional[int] = Query(None, description="Filtrar por visitador específico"),
    estado: Optional[str] = Query(None, description="Filtrar por estado"),
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(verificar_token_simple)
):
    """
    Obtiene las visitas asignadas por el supervisor actual.
    """
    try:
        # Verificar permisos
        if usuario_actual.rol.nombre.lower() != 'supervisor':
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Solo los supervisores pueden ver las visitas asignadas."
            )
        
        # Construir la consulta base
        query = db.query(models.VisitaAsignada).filter(
            models.VisitaAsignada.supervisor_id == usuario_actual.id
        )
        
        # Aplicar filtros si se especifican
        if visitador_id:
            query = query.filter(models.VisitaAsignada.visitador_id == visitador_id)
        if estado:
            query = query.filter(models.VisitaAsignada.estado == estado)
        
        # Obtener las visitas ordenadas por fecha
        visitas = query.order_by(models.VisitaAsignada.fecha_programada).all()
        
        print(f"🔍 Supervisor {usuario_actual.id} ({usuario_actual.nombre}) - Encontradas {len(visitas)} visitas asignadas")
        
        # Convertir a formato de salida
        visitas_out = []
        for visita in visitas:
            # Obtener información relacionada
            sede = db.query(models.SedeEducativa).filter(models.SedeEducativa.id == visita.sede_id).first()
            municipio = db.query(models.Municipio).filter(models.Municipio.id == visita.municipio_id).first()
            institucion = db.query(models.Institucion).filter(models.Institucion.id == visita.institucion_id).first()
            visitador = db.query(models.Usuario).filter(models.Usuario.id == visita.visitador_id).first()
            
            visita_out = schemas.VisitaAsignadaOut(
                id=visita.id,
                sede_id=visita.sede_id,
                sede_nombre=sede.nombre if sede else "Sede no encontrada",
                visitador_id=visita.visitador_id,
                visitador_nombre=visitador.nombre if visitador else "Visitador no encontrado",
                supervisor_id=visita.supervisor_id,
                supervisor_nombre=usuario_actual.nombre,
                fecha_programada=visita.fecha_programada,
                tipo_visita=visita.tipo_visita,
                prioridad=visita.prioridad,
                estado=visita.estado,
                contrato=visita.contrato,
                operador=visita.operador,
                caso_atencion_prioritaria=visita.caso_atencion_prioritaria,
                municipio_id=visita.municipio_id,
                municipio_nombre=municipio.nombre if municipio else "Municipio no encontrado",
                institucion_id=visita.institucion_id,
                institucion_nombre=institucion.nombre if institucion else "Institución no encontrada",
                observaciones=visita.observaciones,
                fecha_creacion=visita.fecha_creacion,
                fecha_inicio=visita.fecha_inicio,
                fecha_completada=visita.fecha_completada
            )
            visitas_out.append(visita_out)
        
        return visitas_out
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error al obtener visitas asignadas por supervisor: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al obtener visitas asignadas por supervisor: {str(e)}"
        )

@router.put("/{visita_id}/estado")
def actualizar_estado_visita(
    visita_id: int,
    actualizacion: schemas.VisitaAsignadaUpdate,
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(verificar_token_simple)
):
    """
    Actualiza el estado de una visita asignada.
    """
    try:
        # Buscar la visita asignada
        visita = db.query(models.VisitaAsignada).filter(
            models.VisitaAsignada.id == visita_id
        ).first()
        
        if not visita:
            raise HTTPException(status_code=404, detail="Visita asignada no encontrada")
        
        # Verificar permisos (solo el visitador asignado o el supervisor pueden cambiar el estado)
        if usuario_actual.rol.nombre.lower() == 'visitador' and visita.visitador_id != usuario_actual.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No tienes permiso para cambiar el estado de esta visita."
            )
        
        # Actualizar campos si se proporcionan
        if actualizacion.estado is not None:
            visita.estado = actualizacion.estado
            
            # Actualizar fechas según el estado
            if actualizacion.estado == "en_proceso" and visita.fecha_inicio is None:
                visita.fecha_inicio = datetime.utcnow()
            elif actualizacion.estado == "completada" and visita.fecha_completada is None:
                visita.fecha_completada = datetime.utcnow()
            
            # 🔄 SINCRONIZACIÓN AUTOMÁTICA: Actualizar visita completa correspondiente
            if actualizacion.estado in ["completada", "pendiente", "en_proceso"]:
                visita_completa = db.query(models.VisitaCompletaPAE).filter(
                    models.VisitaCompletaPAE.sede_id == visita.sede_id,
                    models.VisitaCompletaPAE.profesional_id == visita.visitador_id,
                    models.VisitaCompletaPAE.contrato == visita.contrato
                ).first()
                
                if visita_completa:
                    print(f"🔄 Sincronizando visita completa {visita_completa.id} con estado: {actualizacion.estado}")
                    visita_completa.estado = actualizacion.estado
                else:
                    print(f"⚠️ No se encontró visita completa correspondiente para sincronizar")
        
        if actualizacion.fecha_inicio is not None:
            visita.fecha_inicio = actualizacion.fecha_inicio
        if actualizacion.fecha_completada is not None:
            visita.fecha_completada = actualizacion.fecha_completada
        if actualizacion.observaciones is not None:
            visita.observaciones = actualizacion.observaciones
        
        db.commit()
        
        print(f"✅ Estado de visita asignada {visita_id} actualizado a: {visita.estado}")
        
        return {"mensaje": f"Visita actualizada exitosamente. Estado: {visita.estado}"}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        print(f"❌ Error al actualizar estado: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al actualizar estado: {str(e)}"
        )

@router.put("/{visita_id}/completar")
def completar_visita_asignada(
    visita_id: int,
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(verificar_token_simple)
):
    """
    Endpoint simplificado para completar una visita asignada.
    Cambia el estado a 'completada' y sincroniza automáticamente con la visita completa.
    """
    try:
        # Buscar la visita asignada
        visita = db.query(models.VisitaAsignada).filter(
            models.VisitaAsignada.id == visita_id
        ).first()
        
        if not visita:
            raise HTTPException(status_code=404, detail="Visita asignada no encontrada")
        
        # Verificar permisos
        if usuario_actual.rol.nombre.lower() == 'visitador' and visita.visitador_id != usuario_actual.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No tienes permiso para completar esta visita."
            )
        
        # Cambiar estado a completada
        visita.estado = "completada"
        if visita.fecha_completada is None:
            visita.fecha_completada = datetime.utcnow()
        
        # 🔄 SINCRONIZACIÓN AUTOMÁTICA: Actualizar visita completa correspondiente
        visita_completa = db.query(models.VisitaCompletaPAE).filter(
            models.VisitaCompletaPAE.sede_id == visita.sede_id,
            models.VisitaCompletaPAE.profesional_id == visita.visitador_id,
            models.VisitaCompletaPAE.contrato == visita.contrato
        ).first()
        
        if visita_completa:
            print(f"🔄 Sincronizando visita completa {visita_completa.id} con estado: completada")
            visita_completa.estado = "completada"
        else:
            print(f"⚠️ No se encontró visita completa correspondiente para sincronizar")
        
        db.commit()
        
        print(f"✅ Visita asignada {visita_id} completada y sincronizada")
        
        return {
            "mensaje": f"Visita {visita_id} completada exitosamente",
            "visita_id": visita_id,
            "estado": "completada",
            "sincronizada": visita_completa is not None
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        print(f"❌ Error al completar visita: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al completar visita: {str(e)}"
        )

@router.get("/{visita_id}", response_model=schemas.VisitaAsignadaOut)
def obtener_visita_asignada(
    visita_id: int,
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(verificar_token_simple)
):
    """
    Obtiene una visita asignada específica por ID.
    """
    try:
        # Buscar la visita asignada
        visita = db.query(models.VisitaAsignada).filter(
            models.VisitaAsignada.id == visita_id
        ).first()
        
        if not visita:
            raise HTTPException(status_code=404, detail="Visita asignada no encontrada")
        
        # Verificar permisos (solo el visitador asignado o el supervisor pueden ver la visita)
        if (usuario_actual.rol.nombre.lower() == 'visitador' and visita.visitador_id != usuario_actual.id) and \
           (usuario_actual.rol.nombre.lower() == 'supervisor' and visita.supervisor_id != usuario_actual.id):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No tienes permiso para ver esta visita."
            )
        
        # Obtener información relacionada
        sede = db.query(models.SedeEducativa).filter(models.SedeEducativa.id == visita.sede_id).first()
        municipio = db.query(models.Municipio).filter(models.Municipio.id == visita.municipio_id).first()
        institucion = db.query(models.Institucion).filter(models.Institucion.id == visita.institucion_id).first()
        visitador = db.query(models.Usuario).filter(models.Usuario.id == visita.visitador_id).first()
        supervisor = db.query(models.Usuario).filter(models.Usuario.id == visita.supervisor_id).first()
        
        return schemas.VisitaAsignadaOut(
            id=visita.id,
            sede_id=visita.sede_id,
            sede_nombre=sede.nombre if sede else "Sede no encontrada",
            visitador_id=visita.visitador_id,
            visitador_nombre=visitador.nombre if visitador else "Visitador no encontrado",
            supervisor_id=visita.supervisor_id,
            supervisor_nombre=supervisor.nombre if supervisor else "Supervisor no encontrado",
            fecha_programada=visita.fecha_programada,
            tipo_visita=visita.tipo_visita,
            prioridad=visita.prioridad,
            estado=visita.estado,
            contrato=visita.contrato,
            operador=visita.operador,
            caso_atencion_prioritaria=visita.caso_atencion_prioritaria,
            municipio_id=visita.municipio_id,
            municipio_nombre=municipio.nombre if municipio else "Municipio no encontrado",
            institucion_id=visita.institucion_id,
            institucion_nombre=institucion.nombre if institucion else "Institución no encontrada",
            observaciones=visita.observaciones,
            fecha_creacion=visita.fecha_creacion,
            fecha_inicio=visita.fecha_inicio,
            fecha_completada=visita.fecha_completada
        )
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error al obtener visita asignada: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al obtener visita asignada: {str(e)}"
        )
