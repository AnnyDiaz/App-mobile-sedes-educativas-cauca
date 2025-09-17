# app/routes/notificaciones.py

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from ..database import get_db
from ..dependencies import get_current_user
from ..models import Usuario
from ..schemas import (
    DispositivoNotificacionCreate, DispositivoNotificacionOut,
    NotificacionOut, NotificacionPushRequest, NotificacionPushResponse,
    NotificacionUpdate
)
from ..services.notificaciones_service import NotificacionesService

router = APIRouter(prefix="/api/notificaciones", tags=["notificaciones"])

@router.post("/dispositivos/registrar", response_model=DispositivoNotificacionOut)
async def registrar_dispositivo(
    request: DispositivoNotificacionCreate,
    current_user: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Registra o actualiza un token de dispositivo para el usuario autenticado
    """
    try:
        service = NotificacionesService(db)
        dispositivo = await service.registrar_dispositivo(
            usuario_id=current_user.id,
            token_dispositivo=request.token_dispositivo,
            plataforma=request.plataforma
        )
        return dispositivo
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al registrar dispositivo: {str(e)}"
        )

@router.delete("/dispositivos/desactivar/{token}")
async def desactivar_dispositivo(
    token: str,
    current_user: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Desactiva un dispositivo por su token
    """
    try:
        service = NotificacionesService(db)
        exito = await service.desactivar_dispositivo(token)
        
        if exito:
            return {"mensaje": "Dispositivo desactivado exitosamente"}
        else:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Token de dispositivo no encontrado"
            )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al desactivar dispositivo: {str(e)}"
        )

@router.post("/enviar", response_model=NotificacionPushResponse)
async def enviar_notificacion_push(
    request: NotificacionPushRequest,
    current_user: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Envía notificaciones push a múltiples usuarios
    Solo usuarios con rol de administrador o supervisor pueden enviar notificaciones
    """
    # Verificar permisos
    if current_user.rol.nombre not in ["Administrador", "Supervisor"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permisos para enviar notificaciones push"
        )
    
    try:
        service = NotificacionesService(db)
        resultado = await service.enviar_notificacion_push(request)
        
        return NotificacionPushResponse(
            exitosas=resultado["exitosas"],
            fallidas=resultado["fallidas"],
            detalles=resultado["detalles"],
            mensaje=resultado["mensaje"]
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al enviar notificaciones: {str(e)}"
        )

@router.get("/usuario", response_model=List[NotificacionOut])
async def obtener_notificaciones_usuario(
    limit: int = 50,
    offset: int = 0,
    current_user: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Obtiene las notificaciones del usuario autenticado
    """
    try:
        service = NotificacionesService(db)
        notificaciones = await service.obtener_notificaciones_usuario(
            usuario_id=current_user.id,
            limit=limit,
            offset=offset
        )
        return notificaciones
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al obtener notificaciones: {str(e)}"
        )

@router.put("/{notificacion_id}/leer")
async def marcar_notificacion_leida(
    notificacion_id: int,
    current_user: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Marca una notificación como leída
    """
    try:
        service = NotificacionesService(db)
        exito = await service.marcar_notificacion_leida(
            notificacion_id=notificacion_id,
            usuario_id=current_user.id
        )
        
        if exito:
            return {"mensaje": "Notificación marcada como leída"}
        else:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Notificación no encontrada"
            )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al marcar notificación como leída: {str(e)}"
        )

@router.post("/recordatorios/automaticos")
async def generar_recordatorios_automaticos(
    current_user: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Genera y envía recordatorios automáticos basados en visitas programadas
    Solo usuarios con rol de administrador pueden ejecutar esta acción
    """
    if current_user.rol.nombre != "Administrador":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo los administradores pueden generar recordatorios automáticos"
        )
    
    try:
        service = NotificacionesService(db)
        resultado = await service.generar_recordatorios_automaticos()
        
        return {
            "mensaje": "Recordatorios automáticos generados",
            "enviados": resultado["enviadas"],
            "fallidos": resultado["fallidas"]
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al generar recordatorios automáticos: {str(e)}"
        )

@router.delete("/limpiar-antiguas")
async def limpiar_notificaciones_antiguas(
    dias: int = 30,
    current_user: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Limpia notificaciones antiguas de la base de datos
    Solo usuarios con rol de administrador pueden ejecutar esta acción
    """
    if current_user.rol.nombre != "Administrador":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo los administradores pueden limpiar notificaciones antiguas"
        )
    
    try:
        service = NotificacionesService(db)
        count = await service.limpiar_notificaciones_antiguas(dias)
        
        return {
            "mensaje": f"Notificaciones antiguas limpiadas",
            "eliminadas": count,
            "dias_limite": dias
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al limpiar notificaciones antiguas: {str(e)}"
        )

@router.get("/estadisticas")
async def obtener_estadisticas_notificaciones(
    current_user: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Obtiene estadísticas de notificaciones del usuario autenticado
    """
    try:
        service = NotificacionesService(db)
        
        # Obtener notificaciones del usuario
        notificaciones = await service.obtener_notificaciones_usuario(
            usuario_id=current_user.id,
            limit=1000  # Obtener todas para estadísticas
        )
        
        # Calcular estadísticas
        total = len(notificaciones)
        leidas = len([n for n in notificaciones if n.leida])
        no_leidas = total - leidas
        
        # Contar por tipo
        tipos = {}
        for notif in notificaciones:
            tipo = notif.tipo
            if tipo not in tipos:
                tipos[tipo] = 0
            tipos[tipo] += 1
        
        # Contar por prioridad
        prioridades = {}
        for notif in notificaciones:
            prioridad = notif.prioridad
            if prioridad not in prioridades:
                prioridades[prioridad] = 0
            prioridades[prioridad] += 1
        
        return {
            "total": total,
            "leidas": leidas,
            "no_leidas": no_leidas,
            "por_tipo": tipos,
            "por_prioridad": prioridades
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al obtener estadísticas: {str(e)}"
        )
