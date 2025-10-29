# app/services/notificaciones_service.py

import json
import logging
import requests
from typing import List, Dict, Optional, Tuple
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_

from ..models import DispositivoNotificacion, Notificacion, Usuario, VisitaAsignada
from ..schemas import NotificacionCreate, NotificacionPushRequest
from ..config import (
    FCM_SEND_URL, FCM_HEADERS, NOTIFICACIONES_ENABLED, 
    NOTIFICACIONES_MAX_RETRY, NOTIFICACIONES_TIMEOUT,
    RECORDATORIOS_VISITA_PROXIMA_HORAS, RECORDATORIOS_VISITA_VENCIDA_DIAS
)

logger = logging.getLogger(__name__)

class NotificacionesService:
    """
    Servicio para manejar notificaciones push usando Firebase Cloud Messaging
    """
    
    def __init__(self, db: Session):
        self.db = db
    
    async def registrar_dispositivo(
        self, 
        usuario_id: int, 
        token_dispositivo: str, 
        plataforma: str
    ) -> DispositivoNotificacion:
        """
        Registra o actualiza un token de dispositivo para un usuario
        """
        try:
            # Verificar si el usuario existe
            usuario = self.db.query(Usuario).filter(Usuario.id == usuario_id).first()
            if not usuario:
                raise ValueError(f"Usuario con ID {usuario_id} no encontrado")
            
            # Verificar si ya existe un dispositivo con este token
            dispositivo_existente = self.db.query(DispositivoNotificacion).filter(
                DispositivoNotificacion.token_dispositivo == token_dispositivo
            ).first()
            
            if dispositivo_existente:
                # Actualizar dispositivo existente
                dispositivo_existente.usuario_id = usuario_id
                dispositivo_existente.plataforma = plataforma
                dispositivo_existente.activo = True
                dispositivo_existente.ultima_actividad = datetime.utcnow()
                self.db.commit()
                logger.info(f"Dispositivo actualizado para usuario {usuario_id}")
                return dispositivo_existente
            else:
                # Crear nuevo dispositivo
                nuevo_dispositivo = DispositivoNotificacion(
                    usuario_id=usuario_id,
                    token_dispositivo=token_dispositivo,
                    plataforma=plataforma,
                    activo=True,
                    fecha_registro=datetime.utcnow(),
                    ultima_actividad=datetime.utcnow()
                )
                self.db.add(nuevo_dispositivo)
                self.db.commit()
                self.db.refresh(nuevo_dispositivo)
                logger.info(f"Nuevo dispositivo registrado para usuario {usuario_id}")
                return nuevo_dispositivo
                
        except Exception as e:
            self.db.rollback()
            logger.error(f"Error al registrar dispositivo: {str(e)}")
            raise
    
    async def desactivar_dispositivo(self, token_dispositivo: str) -> bool:
        """
        Desactiva un dispositivo por su token
        """
        try:
            dispositivo = self.db.query(DispositivoNotificacion).filter(
                DispositivoNotificacion.token_dispositivo == token_dispositivo
            ).first()
            
            if dispositivo:
                dispositivo.activo = False
                dispositivo.ultima_actividad = datetime.utcnow()
                self.db.commit()
                logger.info(f"Dispositivo {token_dispositivo} desactivado")
                return True
            return False
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Error al desactivar dispositivo: {str(e)}")
            raise
    
    async def enviar_notificacion_push(
        self, 
        request: NotificacionPushRequest
    ) -> Dict[str, any]:
        """
        Envía notificaciones push a múltiples usuarios
        """
        if not NOTIFICACIONES_ENABLED:
            logger.warning("Notificaciones push deshabilitadas")
            return {
                "exitosas": 0,
                "fallidas": len(request.usuario_ids),
                "detalles": [],
                "mensaje": "Notificaciones push deshabilitadas"
            }
        
        resultados = {
            "exitosas": 0,
            "fallidas": 0,
            "detalles": []
        }
        
        for usuario_id in request.usuario_ids:
            try:
                # Obtener dispositivos activos del usuario
                dispositivos = self.db.query(DispositivoNotificacion).filter(
                    and_(
                        DispositivoNotificacion.usuario_id == usuario_id,
                        DispositivoNotificacion.activo == True
                    )
                ).all()
                
                if not dispositivos:
                    resultados["fallidas"] += 1
                    resultados["detalles"].append({
                        "usuario_id": usuario_id,
                        "estado": "fallido",
                        "razon": "No hay dispositivos activos"
                    })
                    continue
                
                # Enviar notificación a cada dispositivo
                for dispositivo in dispositivos:
                    exito = await self._enviar_fcm(
                        token=dispositivo.token_dispositivo,
                        titulo=request.titulo,
                        mensaje=request.mensaje,
                        datos=request.datos_adicionales
                    )
                    
                    if exito:
                        resultados["exitosas"] += 1
                        # Guardar notificación en base de datos
                        await self._guardar_notificacion(
                            usuario_id=usuario_id,
                            titulo=request.titulo,
                            mensaje=request.mensaje,
                            tipo=request.tipo,
                            prioridad=request.prioridad,
                            datos_adicionales=json.dumps(request.datos_adicionales) if request.datos_adicionales else None
                        )
                    else:
                        resultados["fallidas"] += 1
                    
                    resultados["detalles"].append({
                        "usuario_id": usuario_id,
                        "dispositivo_id": dispositivo.id,
                        "estado": "exitoso" if exito else "fallido"
                    })
                    
            except Exception as e:
                logger.error(f"Error al enviar notificación a usuario {usuario_id}: {str(e)}")
                resultados["fallidas"] += 1
                resultados["detalles"].append({
                    "usuario_id": usuario_id,
                    "estado": "fallido",
                    "razon": str(e)
                })
        
        resultados["mensaje"] = f"Enviadas: {resultados['exitosas']}, Fallidas: {resultados['fallidas']}"
        return resultados
    
    async def _enviar_fcm(
        self, 
        token: str, 
        titulo: str, 
        mensaje: str, 
        datos: Optional[Dict] = None
    ) -> bool:
        """
        Envía una notificación push usando Firebase Cloud Messaging
        """
        try:
            payload = {
                "to": token,
                "notification": {
                    "title": titulo,
                    "body": mensaje,
                    "sound": "default",
                    "badge": "1"
                },
                "data": datos or {},
                "priority": "high",
                "content_available": True
            }
            
            response = requests.post(
                FCM_SEND_URL,
                headers=FCM_HEADERS,
                json=payload,
                timeout=NOTIFICACIONES_TIMEOUT
            )
            
            if response.status_code == 200:
                result = response.json()
                if result.get("success") == 1:
                    logger.info(f"Notificación FCM enviada exitosamente a {token}")
                    return True
                else:
                    logger.error(f"Error FCM: {result}")
                    return False
            else:
                logger.error(f"Error HTTP FCM: {response.status_code} - {response.text}")
                return False
                
        except requests.exceptions.Timeout:
            logger.error(f"Timeout al enviar notificación FCM a {token}")
            return False
        except Exception as e:
            logger.error(f"Error al enviar notificación FCM: {str(e)}")
            return False
    
    async def _guardar_notificacion(
        self,
        usuario_id: int,
        titulo: str,
        mensaje: str,
        tipo: str,
        prioridad: str,
        datos_adicionales: Optional[str] = None
    ) -> Notificacion:
        """
        Guarda una notificación en la base de datos
        """
        try:
            notificacion = Notificacion(
                usuario_id=usuario_id,
                titulo=titulo,
                mensaje=mensaje,
                tipo=tipo,
                prioridad=prioridad,
                datos_adicionales=datos_adicionales,
                fecha_envio=datetime.utcnow()
            )
            
            self.db.add(notificacion)
            self.db.commit()
            self.db.refresh(notificacion)
            
            return notificacion
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Error al guardar notificación: {str(e)}")
            raise
    
    async def generar_recordatorios_automaticos(self) -> Dict[str, int]:
        """
        Genera y envía recordatorios automáticos basados en visitas programadas
        """
        if not NOTIFICACIONES_ENABLED:
            return {"enviadas": 0, "fallidas": 0}
        
        ahora = datetime.utcnow()
        recordatorios_enviados = 0
        recordatorios_fallidos = 0
        
        try:
            # Buscar visitas próximas (dentro de las próximas horas)
            visitas_proximas = self.db.query(VisitaAsignada).filter(
                and_(
                    VisitaAsignada.estado == "pendiente",
                    VisitaAsignada.fecha_programada > ahora,
                    VisitaAsignada.fecha_programada <= ahora + timedelta(hours=RECORDATORIOS_VISITA_PROXIMA_HORAS)
                )
            ).all()
            
            # Buscar visitas vencidas (hace algunos días)
            visitas_vencidas = self.db.query(VisitaAsignada).filter(
                and_(
                    VisitaAsignada.estado == "pendiente",
                    VisitaAsignada.fecha_programada < ahora,
                    VisitaAsignada.fecha_programada >= ahora - timedelta(days=RECORDATORIOS_VISITA_VENCIDA_DIAS)
                )
            ).all()
            
            # Enviar recordatorios para visitas próximas
            for visita in visitas_proximas:
                try:
                    horas_restantes = int((visita.fecha_programada - ahora).total_seconds() / 3600)
                    
                    request = NotificacionPushRequest(
                        titulo="Visita Próxima",
                        mensaje=f"Tienes una visita programada en {horas_restantes} horas en {visita.sede.nombre_sede}",
                        tipo="visita_proxima",
                        prioridad="alta",
                        usuario_ids=[visita.visitador_id],
                        datos_adicionales={
                            "visita_id": visita.id,
                            "sede_nombre": visita.sede.nombre_sede,
                            "fecha_programada": visita.fecha_programada.isoformat()
                        }
                    )
                    
                    resultado = await self.enviar_notificacion_push(request)
                    if resultado["exitosas"] > 0:
                        recordatorios_enviados += 1
                    else:
                        recordatorios_fallidos += 1
                        
                except Exception as e:
                    logger.error(f"Error al enviar recordatorio de visita próxima: {str(e)}")
                    recordatorios_fallidos += 1
            
            # Enviar recordatorios para visitas vencidas
            for visita in visitas_vencidas:
                try:
                    dias_vencida = int((ahora - visita.fecha_programada).total_seconds() / 86400)
                    
                    request = NotificacionPushRequest(
                        titulo="Visita Vencida",
                        mensaje=f"Tienes una visita vencida hace {dias_vencida} días en {visita.sede.nombre_sede}",
                        tipo="visita_vencida",
                        prioridad="urgente",
                        usuario_ids=[visita.visitador_id],
                        datos_adicionales={
                            "visita_id": visita.id,
                            "sede_nombre": visita.sede.nombre_sede,
                            "fecha_programada": visita.fecha_programada.isoformat(),
                            "dias_vencida": dias_vencida
                        }
                    )
                    
                    resultado = await self.enviar_notificacion_push(request)
                    if resultado["exitosas"] > 0:
                        recordatorios_enviados += 1
                    else:
                        recordatorios_fallidos += 1
                        
                except Exception as e:
                    logger.error(f"Error al enviar recordatorio de visita vencida: {str(e)}")
                    recordatorios_fallidos += 1
            
            logger.info(f"Recordatorios automáticos enviados: {recordatorios_enviados}, Fallidos: {recordatorios_fallidos}")
            
        except Exception as e:
            logger.error(f"Error al generar recordatorios automáticos: {str(e)}")
        
        return {
            "enviadas": recordatorios_enviados,
            "fallidas": recordatorios_fallidos
        }
    
    async def obtener_notificaciones_usuario(
        self, 
        usuario_id: int, 
        limit: int = 50, 
        offset: int = 0
    ) -> List[Notificacion]:
        """
        Obtiene las notificaciones de un usuario
        """
        try:
            notificaciones = self.db.query(Notificacion).filter(
                Notificacion.usuario_id == usuario_id
            ).order_by(Notificacion.fecha_envio.desc()).offset(offset).limit(limit).all()
            
            return notificaciones
            
        except Exception as e:
            logger.error(f"Error al obtener notificaciones del usuario {usuario_id}: {str(e)}")
            raise
    
    async def marcar_notificacion_leida(
        self, 
        notificacion_id: int, 
        usuario_id: int
    ) -> bool:
        """
        Marca una notificación como leída
        """
        try:
            notificacion = self.db.query(Notificacion).filter(
                and_(
                    Notificacion.id == notificacion_id,
                    Notificacion.usuario_id == usuario_id
                )
            ).first()
            
            if notificacion:
                notificacion.leida = True
                notificacion.fecha_lectura = datetime.utcnow()
                self.db.commit()
                logger.info(f"Notificación {notificacion_id} marcada como leída")
                return True
            return False
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Error al marcar notificación como leída: {str(e)}")
            raise
    
    async def limpiar_notificaciones_antiguas(self, dias: int = 30) -> int:
        """
        Limpia notificaciones antiguas de la base de datos
        """
        try:
            fecha_limite = datetime.utcnow() - timedelta(days=dias)
            
            # Contar notificaciones a eliminar
            count = self.db.query(Notificacion).filter(
                Notificacion.fecha_envio < fecha_limite
            ).count()
            
            # Eliminar notificaciones antiguas
            self.db.query(Notificacion).filter(
                Notificacion.fecha_envio < fecha_limite
            ).delete()
            
            self.db.commit()
            logger.info(f"Eliminadas {count} notificaciones antiguas")
            return count
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Error al limpiar notificaciones antiguas: {str(e)}")
            raise
