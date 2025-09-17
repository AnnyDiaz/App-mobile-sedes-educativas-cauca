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
    registrar_auditoria, obtener_ip_request, generar_2fa_secret,
    verificar_2fa_code, habilitar_2fa
)

router = APIRouter(prefix="/admin", tags=["Administración"])

# --- DASHBOARD EJECUTIVO ---

@router.get("/dashboard/estadisticas")
def obtener_estadisticas_ejecutivas(
    request: Request,
    db: Session = Depends(get_db),
    admin: models.Usuario = Depends(verificar_admin)
):
    """
    Obtiene las estadísticas del dashboard ejecutivo.
    KPIs principales para vista de 10-30 segundos.
    """
    try:
        ip_address = obtener_ip_request(request)
        
        # --- KPIs PRINCIPALES ---
        
        # Usuarios activos (últimos 30 días)
        fecha_limite = datetime.utcnow() - timedelta(days=30)
        usuarios_activos = db.query(models.Usuario).filter(
            models.Usuario.activo == True,
            models.Usuario.ultimo_acceso >= fecha_limite
        ).count()
        
        # Visitadores activos
        visitadores_activos = db.query(models.Usuario).join(models.Rol).filter(
            models.Rol.nombre == "Visitador",
            models.Usuario.activo == True,
            models.Usuario.ultimo_acceso >= fecha_limite
        ).count()
        
        # Visitas programadas hoy/semana
        hoy = datetime.utcnow().date()
        inicio_semana = hoy - timedelta(days=hoy.weekday())
        fin_semana = inicio_semana + timedelta(days=6)
        
        visitas_hoy = db.query(models.VisitaAsignada).filter(
            func.date(models.VisitaAsignada.fecha_programada) == hoy
        ).count()
        
        visitas_semana = db.query(models.VisitaAsignada).filter(
            func.date(models.VisitaAsignada.fecha_programada).between(inicio_semana, fin_semana)
        ).count()
        
        # Porcentaje de visitas completadas (últimos 30 días)
        visitas_periodo = db.query(models.VisitaAsignada).filter(
            models.VisitaAsignada.fecha_programada >= fecha_limite
        )
        total_visitas_periodo = visitas_periodo.count()
        visitas_completadas = visitas_periodo.filter(
            models.VisitaAsignada.estado == "completada"
        ).count()
        
        porcentaje_completadas = (
            (visitas_completadas / total_visitas_periodo * 100) 
            if total_visitas_periodo > 0 else 0
        )
        
        # Alertas críticas
        alertas_criticas = db.query(models.Notificacion).filter(
            models.Notificacion.prioridad == "urgente",
            models.Notificacion.leida == False
        ).count()
        
        # --- DATOS PARA GRÁFICOS ---
        
        # Visitas por municipio (últimos 30 días)
        visitas_por_municipio = db.query(
            models.Municipio.nombre,
            func.count(models.VisitaAsignada.id).label('total')
        ).join(
            models.VisitaAsignada, models.Municipio.id == models.VisitaAsignada.municipio_id
        ).filter(
            models.VisitaAsignada.fecha_programada >= fecha_limite
        ).group_by(models.Municipio.nombre).order_by(desc('total')).limit(10).all()
        

        
        # Cumplimiento promedio del checklist
        # (Esto requeriría análisis de las respuestas del checklist)
        cumplimiento_promedio = 85.4  # Placeholder - implementar lógica real
        
        # --- ALERTAS DEL SISTEMA (últimas 5) ---
        alertas_sistema = db.query(models.AuditoriaLog).filter(
            models.AuditoriaLog.accion.in_(["ERROR", "EXPORT_FAILED", "LOGIN_FAILED"])
        ).order_by(desc(models.AuditoriaLog.timestamp)).limit(5).all()
        
        # Registrar acceso en auditoría
        registrar_auditoria(
            db=db,
            actor_id=admin.id,
            accion="VIEW_DASHBOARD",
            recurso="Dashboard",
            ip_address=ip_address,
            user_agent=request.headers.get("User-Agent")
        )
        
        return {
            "kpis": {
                "usuarios_activos": usuarios_activos,
                "visitadores_activos": visitadores_activos,
                "visitas_hoy": visitas_hoy,
                "visitas_semana": visitas_semana,
                "porcentaje_completadas": round(porcentaje_completadas, 1),
                "alertas_criticas": alertas_criticas
            },
            "graficos": {
                "visitas_por_municipio": [
                    {"municipio": m.nombre, "total": m.total} 
                    for m in visitas_por_municipio
                ],

                "cumplimiento_promedio": cumplimiento_promedio
            },
            "alertas_sistema": [
                {
                    "id": a.id,
                    "accion": a.accion,
                    "recurso": a.recurso,
                    "timestamp": a.timestamp.isoformat(),
                    "detalles": a.detalles_adicionales
                }
                for a in alertas_sistema
            ]
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error al obtener estadísticas del dashboard: {str(e)}"
        )

# --- GESTIÓN DE USUARIOS ---

@router.get("/usuarios")
def listar_usuarios(
    request: Request,
    db: Session = Depends(get_db),
    admin: models.Usuario = Depends(verificar_permiso("usuarios.listar")),
    rol: Optional[str] = Query(None),
    estado: Optional[bool] = Query(None),
    municipio_id: Optional[int] = Query(None),
    fecha_desde: Optional[str] = Query(None),
    search: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, le=100)
):
    """
    Lista usuarios con filtros avanzados.
    """
    try:
        query = db.query(models.Usuario).options(
            joinedload(models.Usuario.rol),
            joinedload(models.Usuario.jurisdiccion)
        )
        
        # Aplicar filtros
        if rol:
            query = query.join(models.Rol).filter(models.Rol.nombre == rol)
        
        if estado is not None:
            query = query.filter(models.Usuario.activo == estado)
        
        if municipio_id:
            query = query.filter(models.Usuario.jurisdiccion_id == municipio_id)
        
        if fecha_desde:
            fecha_dt = datetime.fromisoformat(fecha_desde.replace('Z', '+00:00'))
            query = query.filter(models.Usuario.fecha_creacion >= fecha_dt)
        
        if search:
            query = query.filter(
                or_(
                    models.Usuario.nombre.ilike(f"%{search}%"),
                    models.Usuario.correo.ilike(f"%{search}%")
                )
            )
        
        # Contar total
        total = query.count()
        
        # Paginar
        usuarios = query.offset(skip).limit(limit).all()
        
        # Registrar acceso
        registrar_auditoria(
            db=db,
            actor_id=admin.id,
            accion="LIST_USERS",
            recurso="Usuario",
            ip_address=obtener_ip_request(request),
            detalles_adicionales={"filtros": {"rol": rol, "estado": estado, "search": search}}
        )
        
        return {
            "usuarios": [
                {
                    "id": u.id,
                    "nombre": u.nombre,
                    "correo": u.correo,
                    "rol": u.rol.nombre if u.rol else None,
                    "activo": u.activo,
                    "twofa_enabled": u.twofa_enabled,
                    "ultimo_acceso": u.ultimo_acceso.isoformat() if u.ultimo_acceso else None,
                    "fecha_creacion": u.fecha_creacion.isoformat(),
                    "jurisdiccion": u.jurisdiccion.nombre if u.jurisdiccion else None,
                    "intentos_fallidos": u.intentos_fallidos,
                    "fecha_bloqueo": u.fecha_bloqueo.isoformat() if u.fecha_bloqueo else None
                }
                for u in usuarios
            ],
            "total": total,
            "pagina_actual": skip // limit + 1,
            "total_paginas": (total + limit - 1) // limit
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error al listar usuarios: {str(e)}"
        )

@router.post("/usuarios")
def crear_usuario(
    request: Request,
    datos_usuario: dict,
    db: Session = Depends(get_db),
    admin: models.Usuario = Depends(verificar_permiso("usuarios.crear"))
):
    """
    Crea un nuevo usuario en el sistema.
    """
    from passlib.context import CryptContext
    
    try:
        pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
        
        # Validar datos requeridos
        campos_requeridos = ["nombre", "correo", "contrasena", "rol_id"]
        for campo in campos_requeridos:
            if campo not in datos_usuario:
                raise HTTPException(
                    status_code=400,
                    detail=f"Campo requerido faltante: {campo}"
                )
        
        # Verificar que el correo no existe
        usuario_existente = db.query(models.Usuario).filter(
            models.Usuario.correo == datos_usuario["correo"]
        ).first()
        
        if usuario_existente:
            raise HTTPException(
                status_code=400,
                detail="Ya existe un usuario con este correo electrónico"
            )
        
        # Verificar que el rol existe
        rol = db.query(models.Rol).filter(
            models.Rol.id == datos_usuario["rol_id"]
        ).first()
        
        if not rol:
            raise HTTPException(
                status_code=400,
                detail="Rol no válido"
            )
        
        # Hash de la contraseña
        contrasena_hash = pwd_context.hash(datos_usuario["contrasena"])
        
        # Crear usuario
        nuevo_usuario = models.Usuario(
            nombre=datos_usuario["nombre"],
            correo=datos_usuario["correo"],
            contrasena=contrasena_hash,
            rol_id=datos_usuario["rol_id"],
            activo=datos_usuario.get("activo", True),
            jurisdiccion_id=datos_usuario.get("jurisdiccion_id"),
            created_by=admin.id,
            fecha_creacion=datetime.utcnow()
        )
        
        db.add(nuevo_usuario)
        db.commit()
        db.refresh(nuevo_usuario)
        
        # Registrar en auditoría
        registrar_auditoria(
            db=db,
            actor_id=admin.id,
            accion="CREATE",
            recurso="Usuario",
            recurso_id=nuevo_usuario.id,
            diff_after={
                "nombre": nuevo_usuario.nombre,
                "correo": nuevo_usuario.correo,
                "rol_id": nuevo_usuario.rol_id,
                "activo": nuevo_usuario.activo
            },
            ip_address=obtener_ip_request(request)
        )
        
        return {
            "mensaje": "Usuario creado exitosamente",
            "usuario_id": nuevo_usuario.id,
            "nombre": nuevo_usuario.nombre,
            "correo": nuevo_usuario.correo
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error al crear usuario: {str(e)}"
        )

@router.put("/usuarios/{usuario_id}")
def actualizar_usuario(
    usuario_id: int,
    request: Request,
    datos_usuario: dict,
    db: Session = Depends(get_db),
    admin: models.Usuario = Depends(verificar_permiso("usuarios.editar"))
):
    """
    Actualiza un usuario existente.
    """
    try:
        # Obtener usuario
        usuario = db.query(models.Usuario).filter(
            models.Usuario.id == usuario_id
        ).first()
        
        if not usuario:
            raise HTTPException(
                status_code=404,
                detail="Usuario no encontrado"
            )
        
        # Guardar estado anterior para auditoría
        estado_anterior = {
            "nombre": usuario.nombre,
            "correo": usuario.correo,
            "rol_id": usuario.rol_id,
            "activo": usuario.activo,
            "jurisdiccion_id": usuario.jurisdiccion_id
        }
        
        # Actualizar campos permitidos
        campos_actualizables = ["nombre", "correo", "rol_id", "activo", "jurisdiccion_id"]
        cambios = {}
        
        for campo in campos_actualizables:
            if campo in datos_usuario:
                valor_anterior = getattr(usuario, campo)
                valor_nuevo = datos_usuario[campo]
                
                if valor_anterior != valor_nuevo:
                    setattr(usuario, campo, valor_nuevo)
                    cambios[campo] = {"anterior": valor_anterior, "nuevo": valor_nuevo}
        
        # Verificar correo único si cambió
        if "correo" in cambios:
            usuario_existente = db.query(models.Usuario).filter(
                models.Usuario.correo == datos_usuario["correo"],
                models.Usuario.id != usuario_id
            ).first()
            
            if usuario_existente:
                raise HTTPException(
                    status_code=400,
                    detail="Ya existe otro usuario con este correo electrónico"
                )
        
        # Verificar rol válido si cambió
        if "rol_id" in cambios:
            rol = db.query(models.Rol).filter(
                models.Rol.id == datos_usuario["rol_id"]
            ).first()
            
            if not rol:
                raise HTTPException(
                    status_code=400,
                    detail="Rol no válido"
                )
        
        if cambios:
            db.commit()
            
            # Registrar en auditoría
            registrar_auditoria(
                db=db,
                actor_id=admin.id,
                accion="UPDATE",
                recurso="Usuario",
                recurso_id=usuario.id,
                diff_before=estado_anterior,
                diff_after={
                    "nombre": usuario.nombre,
                    "correo": usuario.correo,
                    "rol_id": usuario.rol_id,
                    "activo": usuario.activo,
                    "jurisdiccion_id": usuario.jurisdiccion_id
                },
                ip_address=obtener_ip_request(request),
                detalles_adicionales={"cambios": cambios}
            )
            
            return {
                "mensaje": "Usuario actualizado exitosamente",
                "cambios_realizados": list(cambios.keys())
            }
        else:
            return {"mensaje": "No se detectaron cambios"}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error al actualizar usuario: {str(e)}"
        )

@router.patch("/usuarios/{usuario_id}/activar")
def activar_usuario(
    usuario_id: int,
    request: Request,
    db: Session = Depends(get_db),
    admin: models.Usuario = Depends(verificar_permiso("usuarios.activar"))
):
    """
    Activa un usuario desactivado.
    """
    return _cambiar_estado_usuario(usuario_id, True, request, db, admin)

@router.patch("/usuarios/{usuario_id}/desactivar")
def desactivar_usuario(
    usuario_id: int,
    request: Request,
    db: Session = Depends(get_db),
    admin: models.Usuario = Depends(verificar_permiso("usuarios.desactivar"))
):
    """
    Desactiva un usuario (borrado lógico).
    """
    return _cambiar_estado_usuario(usuario_id, False, request, db, admin)

def _cambiar_estado_usuario(usuario_id: int, nuevo_estado: bool, request: Request, db: Session, admin: models.Usuario):
    """
    Función auxiliar para cambiar el estado activo/inactivo de un usuario.
    """
    try:
        usuario = db.query(models.Usuario).filter(
            models.Usuario.id == usuario_id
        ).first()
        
        if not usuario:
            raise HTTPException(
                status_code=404,
                detail="Usuario no encontrado"
            )
        
        estado_anterior = usuario.activo
        usuario.activo = nuevo_estado
        
        # Si se desactiva, cerrar todas sus sesiones
        if not nuevo_estado:
            from app.utils.admin_auth import cerrar_todas_sesiones_usuario
            sesiones_cerradas = cerrar_todas_sesiones_usuario(
                usuario_id=usuario_id,
                motivo="usuario_desactivado",
                db=db
            )
        
        db.commit()
        
        # Registrar en auditoría
        accion = "ACTIVATE_USER" if nuevo_estado else "DEACTIVATE_USER"
        registrar_auditoria(
            db=db,
            actor_id=admin.id,
            accion=accion,
            recurso="Usuario",
            recurso_id=usuario.id,
            diff_before={"activo": estado_anterior},
            diff_after={"activo": nuevo_estado},
            ip_address=obtener_ip_request(request)
        )
        
        estado_texto = "activado" if nuevo_estado else "desactivado"
        return {
            "mensaje": f"Usuario {estado_texto} exitosamente",
            "usuario_id": usuario_id,
            "nuevo_estado": nuevo_estado
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error al cambiar estado del usuario: {str(e)}"
        )

@router.post("/usuarios/{usuario_id}/reset-2fa")
def reset_2fa_usuario(
    usuario_id: int,
    request: Request,
    db: Session = Depends(get_db),
    admin: models.Usuario = Depends(verificar_admin_con_2fa)  # Requiere 2FA del admin
):
    """
    Resetea el 2FA de un usuario (requiere 2FA del admin).
    """
    try:
        usuario = db.query(models.Usuario).filter(
            models.Usuario.id == usuario_id
        ).first()
        
        if not usuario:
            raise HTTPException(
                status_code=404,
                detail="Usuario no encontrado"
            )
        
        # Resetear 2FA
        usuario.twofa_enabled = False
        usuario.twofa_secret = None
        
        db.commit()
        
        # Registrar en auditoría
        registrar_auditoria(
            db=db,
            actor_id=admin.id,
            accion="RESET_2FA",
            recurso="Usuario",
            recurso_id=usuario.id,
            ip_address=obtener_ip_request(request),
            detalles_adicionales={"admin_2fa_required": True}
        )
        
        return {
            "mensaje": "2FA reseteado exitosamente",
            "usuario_id": usuario_id
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error al resetear 2FA: {str(e)}"
        )

# Continuaré con más endpoints en el siguiente mensaje...
