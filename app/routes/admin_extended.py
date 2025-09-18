from fastapi import APIRouter, Depends, HTTPException, Request, Query, BackgroundTasks
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func, and_, or_, desc, asc
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any
import json

from app.database import get_db
from app import models, schemas
from app.utils.admin_auth import (
    verificar_admin, verificar_admin_con_2fa, verificar_permiso,
    registrar_auditoria, obtener_ip_request
)

router = APIRouter(prefix="/admin", tags=["Administración Extendida"])

# --- GESTIÓN DE TIPOS DE VISITA Y CHECKLISTS ---

@router.get("/tipos-visita")
def listar_tipos_visita(
    request: Request,
    db: Session = Depends(get_db),
    admin: models.Usuario = Depends(verificar_permiso("checklists.listar"))
):
    """Lista todos los tipos de visita disponibles."""
    try:
        tipos = db.query(models.TipoVisita).filter(
            models.TipoVisita.activo == True
        ).order_by(models.TipoVisita.orden, models.TipoVisita.nombre).all()
        
        return {
            "tipos_visita": [
                {
                    "id": t.id,
                    "nombre": t.nombre,
                    "descripcion": t.descripcion,
                    "color_codigo": t.color_codigo,
                    "orden": t.orden,
                    "fecha_creacion": t.fecha_creacion.isoformat(),
                    "templates_count": len(t.templates_checklist)
                }
                for t in tipos
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al listar tipos de visita: {str(e)}")

@router.post("/tipos-visita")
def crear_tipo_visita(
    request: Request,
    datos_tipo: dict,
    db: Session = Depends(get_db),
    admin: models.Usuario = Depends(verificar_permiso("checklists.crear"))
):
    """Crea un nuevo tipo de visita."""
    try:
        if not datos_tipo.get("nombre"):
            raise HTTPException(status_code=400, detail="El nombre es requerido")
        
        tipo_existente = db.query(models.TipoVisita).filter(
            models.TipoVisita.nombre == datos_tipo["nombre"]
        ).first()
        
        if tipo_existente:
            raise HTTPException(status_code=400, detail="Ya existe un tipo de visita con este nombre")
        
        nuevo_tipo = models.TipoVisita(
            nombre=datos_tipo["nombre"],
            descripcion=datos_tipo.get("descripcion"),
            color_codigo=datos_tipo.get("color_codigo"),
            orden=datos_tipo.get("orden", 0),
            created_by=admin.id
        )
        
        db.add(nuevo_tipo)
        db.commit()
        db.refresh(nuevo_tipo)
        
        registrar_auditoria(
            db=db, actor_id=admin.id, accion="CREATE", recurso="TipoVisita",
            recurso_id=nuevo_tipo.id, diff_after={"nombre": nuevo_tipo.nombre},
            ip_address=obtener_ip_request(request)
        )
        
        return {"mensaje": "Tipo de visita creado exitosamente", "tipo_id": nuevo_tipo.id}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error al crear tipo de visita: {str(e)}")

@router.get("/checklists")
def listar_checklists(
    request: Request,
    db: Session = Depends(get_db),
    admin: models.Usuario = Depends(verificar_permiso("checklists.listar")),
    tipo_id: Optional[int] = Query(None),
    version: Optional[str] = Query(None),
    solo_publicados: bool = Query(False)
):
    """Lista checklists con filtros opcionales."""
    try:
        query = db.query(models.ChecklistTemplate).options(
            joinedload(models.ChecklistTemplate.tipo_visita),
            joinedload(models.ChecklistTemplate.creador)
        )
        
        if tipo_id:
            query = query.filter(models.ChecklistTemplate.tipo_visita_id == tipo_id)
        if version:
            query = query.filter(models.ChecklistTemplate.version == version)
        if solo_publicados:
            query = query.filter(models.ChecklistTemplate.publicado == True)
        
        checklists = query.order_by(
            models.ChecklistTemplate.tipo_visita_id,
            desc(models.ChecklistTemplate.fecha_creacion)
        ).all()
        
        return {
            "checklists": [
                {
                    "id": c.id,
                    "tipo_visita": c.tipo_visita.nombre if c.tipo_visita else None,
                    "version": c.version,
                    "nombre": c.nombre,
                    "descripcion": c.descripcion,
                    "publicado": c.publicado,
                    "activo": c.activo,
                    "fecha_creacion": c.fecha_creacion.isoformat(),
                    "creado_por": c.creador.nombre if c.creador else None,
                    "publicado_en": c.publicado_en.isoformat() if c.publicado_en else None
                }
                for c in checklists
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al listar checklists: {str(e)}")

@router.post("/checklists")
def crear_checklist(
    request: Request,
    datos_checklist: dict,
    db: Session = Depends(get_db),
    admin: models.Usuario = Depends(verificar_permiso("checklists.crear"))
):
    """Crea una nueva versión de checklist."""
    try:
        campos_requeridos = ["tipo_visita_id", "version", "nombre", "json_schema"]
        for campo in campos_requeridos:
            if campo not in datos_checklist:
                raise HTTPException(status_code=400, detail=f"Campo requerido faltante: {campo}")
        
        tipo_visita = db.query(models.TipoVisita).filter(
            models.TipoVisita.id == datos_checklist["tipo_visita_id"]
        ).first()
        
        if not tipo_visita:
            raise HTTPException(status_code=400, detail="Tipo de visita no válido")
        
        checklist_existente = db.query(models.ChecklistTemplate).filter(
            models.ChecklistTemplate.tipo_visita_id == datos_checklist["tipo_visita_id"],
            models.ChecklistTemplate.version == datos_checklist["version"]
        ).first()
        
        if checklist_existente:
            raise HTTPException(
                status_code=400,
                detail=f"Ya existe la versión {datos_checklist['version']} para este tipo de visita"
            )
        
        try:
            json.loads(datos_checklist["json_schema"])
        except json.JSONDecodeError:
            raise HTTPException(status_code=400, detail="El schema JSON no es válido")
        
        nuevo_checklist = models.ChecklistTemplate(
            tipo_visita_id=datos_checklist["tipo_visita_id"],
            version=datos_checklist["version"],
            nombre=datos_checklist["nombre"],
            descripcion=datos_checklist.get("descripcion"),
            json_schema=datos_checklist["json_schema"],
            creado_por=admin.id
        )
        
        db.add(nuevo_checklist)
        db.commit()
        db.refresh(nuevo_checklist)
        
        registrar_auditoria(
            db=db, actor_id=admin.id, accion="CREATE", recurso="ChecklistTemplate",
            recurso_id=nuevo_checklist.id,
            diff_after={"tipo_visita_id": nuevo_checklist.tipo_visita_id, "version": nuevo_checklist.version},
            ip_address=obtener_ip_request(request)
        )
        
        return {"mensaje": "Checklist creado exitosamente", "checklist_id": nuevo_checklist.id}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error al crear checklist: {str(e)}")

@router.post("/checklists/{checklist_id}/publicar")
def publicar_checklist(
    checklist_id: int,
    request: Request,
    db: Session = Depends(get_db),
    admin: models.Usuario = Depends(verificar_admin_con_2fa)
):
    """Publica una versión de checklist (requiere 2FA)."""
    try:
        checklist = db.query(models.ChecklistTemplate).filter(
            models.ChecklistTemplate.id == checklist_id
        ).first()
        
        if not checklist:
            raise HTTPException(status_code=404, detail="Checklist no encontrado")
        
        if checklist.publicado:
            raise HTTPException(status_code=400, detail="Este checklist ya está publicado")
        
        # Desactivar versión activa anterior del mismo tipo
        db.query(models.ChecklistTemplate).filter(
            models.ChecklistTemplate.tipo_visita_id == checklist.tipo_visita_id,
            models.ChecklistTemplate.activo == True
        ).update({"activo": False})
        
        # Publicar nueva versión
        checklist.publicado = True
        checklist.publicado_en = datetime.utcnow()
        checklist.publicado_por = admin.id
        checklist.activo = True
        
        db.commit()
        
        registrar_auditoria(
            db=db, actor_id=admin.id, accion="PUBLISH_CHECKLIST", recurso="ChecklistTemplate",
            recurso_id=checklist.id, ip_address=obtener_ip_request(request),
            detalles_adicionales={"admin_2fa_required": True, "version": checklist.version}
        )
        
        return {"mensaje": "Checklist publicado exitosamente", "checklist_id": checklist_id}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error al publicar checklist: {str(e)}")

# --- CONFIGURACIÓN DEL SISTEMA ---

@router.get("/config")
def obtener_configuracion(
    request: Request,
    db: Session = Depends(get_db),
    admin: models.Usuario = Depends(verificar_permiso("config.listar")),
    categoria: Optional[str] = Query(None)
):
    """Obtiene la configuración del sistema."""
    try:
        query = db.query(models.ConfiguracionSistema)
        
        if categoria:
            query = query.filter(models.ConfiguracionSistema.categoria == categoria)
        
        configuraciones = query.order_by(
            models.ConfiguracionSistema.categoria,
            models.ConfiguracionSistema.clave
        ).all()
        
        return {
            "configuracion": [
                {
                    "id": c.id,
                    "clave": c.clave,
                    "valor": json.loads(c.valor_json),
                    "descripcion": c.descripcion,
                    "categoria": c.categoria,
                    "tipo_dato": c.tipo_dato,
                    "fecha_modificacion": c.fecha_modificacion.isoformat()
                }
                for c in configuraciones
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener configuración: {str(e)}")

@router.put("/config")
def actualizar_configuracion(
    request: Request,
    configuraciones: List[dict],
    db: Session = Depends(get_db),
    admin: models.Usuario = Depends(verificar_admin_con_2fa)
):
    """Actualiza múltiples configuraciones del sistema (requiere 2FA)."""
    try:
        cambios_realizados = []
        
        for config_data in configuraciones:
            clave = config_data.get("clave")
            nuevo_valor = config_data.get("valor")
            
            if not clave:
                continue
            
            config = db.query(models.ConfiguracionSistema).filter(
                models.ConfiguracionSistema.clave == clave
            ).first()
            
            if config:
                valor_anterior = json.loads(config.valor_json)
                config.valor_json = json.dumps(nuevo_valor)
                config.modificado_por = admin.id
                config.fecha_modificacion = datetime.utcnow()
                
                cambios_realizados.append({
                    "clave": clave,
                    "valor_anterior": valor_anterior,
                    "valor_nuevo": nuevo_valor
                })
        
        db.commit()
        
        registrar_auditoria(
            db=db, actor_id=admin.id, accion="UPDATE_CONFIG", recurso="ConfiguracionSistema",
            ip_address=obtener_ip_request(request),
            detalles_adicionales={"admin_2fa_required": True, "cambios": cambios_realizados}
        )
        
        return {"mensaje": "Configuración actualizada exitosamente", "cambios_realizados": len(cambios_realizados)}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error al actualizar configuración: {str(e)}")

# --- EXPORTACIONES ---

@router.post("/exportaciones")
def solicitar_exportacion(
    request: Request,
    datos_exportacion: dict,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    admin: models.Usuario = Depends(verificar_admin_con_2fa)
):
    """Solicita una nueva exportación (requiere 2FA)."""
    try:
        if not datos_exportacion.get("tipo_exportacion"):
            raise HTTPException(status_code=400, detail="Tipo de exportación requerido")
        
        export_job = models.ExportJob(
            actor_id=admin.id,
            tipo_exportacion=datos_exportacion["tipo_exportacion"],
            filtros_json=json.dumps(datos_exportacion.get("filtros", {})),
            expires_at=datetime.utcnow() + timedelta(days=7)
        )
        
        db.add(export_job)
        db.commit()
        db.refresh(export_job)
        
        registrar_auditoria(
            db=db, actor_id=admin.id, accion="REQUEST_EXPORT", recurso="ExportJob",
            recurso_id=export_job.id, ip_address=obtener_ip_request(request),
            detalles_adicionales={"admin_2fa_required": True, "tipo_exportacion": datos_exportacion["tipo_exportacion"]}
        )
        
        return {"mensaje": "Exportación solicitada exitosamente", "job_id": export_job.id, "estado": "pendiente"}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error al solicitar exportación: {str(e)}")

@router.get("/exportaciones")
def listar_exportaciones(
    request: Request,
    db: Session = Depends(get_db),
    admin: models.Usuario = Depends(verificar_permiso("exportaciones.listar")),
    estado: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, le=50)
):
    """Lista las exportaciones del usuario."""
    try:
        query = db.query(models.ExportJob).options(joinedload(models.ExportJob.usuario))
        
        if admin.rol.nombre != "Super Administrador":
            query = query.filter(models.ExportJob.actor_id == admin.id)
        
        if estado:
            query = query.filter(models.ExportJob.estado == estado)
        
        total = query.count()
        exportaciones = query.order_by(desc(models.ExportJob.timestamp_creado)).offset(skip).limit(limit).all()
        
        return {
            "exportaciones": [
                {
                    "id": e.id,
                    "tipo_exportacion": e.tipo_exportacion,
                    "estado": e.estado,
                    "progreso": e.progreso,
                    "archivo_nombre": e.archivo_nombre,
                    "timestamp_creado": e.timestamp_creado.isoformat(),
                    "timestamp_fin": e.timestamp_fin.isoformat() if e.timestamp_fin else None,
                    "expires_at": e.expires_at.isoformat() if e.expires_at else None,
                    "usuario": e.usuario.nombre if e.usuario else None,
                    "error_mensaje": e.error_mensaje
                }
                for e in exportaciones
            ],
            "total": total,
            "pagina_actual": skip // limit + 1
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al listar exportaciones: {str(e)}")

# --- AUDITORÍA ---

@router.get("/auditoria")
def obtener_auditoria(
    request: Request,
    db: Session = Depends(get_db),
    admin: models.Usuario = Depends(verificar_permiso("auditoria.listar")),
    actor_id: Optional[int] = Query(None),
    accion: Optional[str] = Query(None),
    recurso: Optional[str] = Query(None),
    fecha_desde: Optional[str] = Query(None),
    fecha_hasta: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, le=100)
):
    """Obtiene registros de auditoría con filtros."""
    try:
        query = db.query(models.AuditoriaLog).options(joinedload(models.AuditoriaLog.actor))
        
        if actor_id:
            query = query.filter(models.AuditoriaLog.actor_id == actor_id)
        if accion:
            query = query.filter(models.AuditoriaLog.accion == accion)
        if recurso:
            query = query.filter(models.AuditoriaLog.recurso == recurso)
        if fecha_desde:
            fecha_dt = datetime.fromisoformat(fecha_desde.replace('Z', '+00:00'))
            query = query.filter(models.AuditoriaLog.timestamp >= fecha_dt)
        if fecha_hasta:
            fecha_dt = datetime.fromisoformat(fecha_hasta.replace('Z', '+00:00'))
            query = query.filter(models.AuditoriaLog.timestamp <= fecha_dt)
        
        total = query.count()
        registros = query.order_by(desc(models.AuditoriaLog.timestamp)).offset(skip).limit(limit).all()
        
        registrar_auditoria(
            db=db, actor_id=admin.id, accion="VIEW_AUDIT", recurso="AuditoriaLog",
            ip_address=obtener_ip_request(request),
            detalles_adicionales={"filtros_aplicados": {"actor_id": actor_id, "accion": accion, "recurso": recurso}}
        )
        
        return {
            "registros": [
                {
                    "id": r.id,
                    "actor": r.actor.nombre if r.actor else "Sistema",
                    "rol_actor": r.rol_actor,
                    "accion": r.accion,
                    "recurso": r.recurso,
                    "recurso_id": r.recurso_id,
                    "timestamp": r.timestamp.isoformat(),
                    "ip_address": r.ip_address,
                    "diff_before": json.loads(r.diff_before) if r.diff_before else None,
                    "diff_after": json.loads(r.diff_after) if r.diff_after else None,
                    "detalles_adicionales": json.loads(r.detalles_adicionales) if r.detalles_adicionales else None
                }
                for r in registros
            ],
            "total": total,
            "pagina_actual": skip // limit + 1,
            "total_paginas": (total + limit - 1) // limit
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener auditoría: {str(e)}")

# --- PROGRAMACIÓN MASIVA DE VISITAS ---

@router.post("/visitas/programar/previsualizar")
def previsualizar_programacion_masiva(
    request: Request,
    datos_programacion: dict,
    db: Session = Depends(get_db),
    admin: models.Usuario = Depends(verificar_permiso("visitas.programar_masivo"))
):
    """Previsualiza las visitas a programar masivamente."""
    try:
        # Implementar lógica de previsualización
        # Esto retornaría una lista de visitas que se van a crear
        # con posibles conflictos detectados
        
        return {
            "mensaje": "Previsualización generada",
            "total_visitas": 0,
            "conflictos": [],
            "visitas_previstas": []
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error en previsualización: {str(e)}")

@router.post("/visitas/programar/confirmar")
def confirmar_programacion_masiva(
    request: Request,
    datos_confirmacion: dict,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    admin: models.Usuario = Depends(verificar_admin_con_2fa)
):
    """Confirma y ejecuta la programación masiva de visitas (requiere 2FA)."""
    try:
        # Crear job de programación masiva
        # background_tasks.add_task(procesar_programacion_masiva, datos_confirmacion)
        
        return {"mensaje": "Programación masiva iniciada", "job_id": "temp_id"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error en programación masiva: {str(e)}")
