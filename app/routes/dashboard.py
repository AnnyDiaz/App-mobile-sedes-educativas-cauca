from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session
from app.database import get_db
from app import models
from app.routes.auth import obtener_usuario_actual
from sqlalchemy import func

router = APIRouter(prefix="", tags=["Dashboard"])

@router.get("/visitas")
def dashboard_visitas(
    request: Request,
    db: Session = Depends(get_db),
    usuario: models.Usuario = Depends(obtener_usuario_actual)
):
    rol = usuario.rol.nombre

    if rol == "visitador":
        visitas = db.query(models.VisitaCompletaPAE).filter(models.VisitaCompletaPAE.profesional_id == usuario.id).all()
        return {
            "rol": rol,
            "total": len(visitas),
            "mensaje": f"Tus visitas registradas: {len(visitas)}",
            "visitas": [v.id for v in visitas]
        }

    elif rol == "supervisor":
        visitas = db.query(models.VisitaCompletaPAE).join(models.SedeEducativa)\
            .with_entities(models.SedeEducativa.municipio, models.VisitaCompletaPAE.id)\
            .all()
        conteo_por_municipio = {}
        for municipio, _ in visitas:
            conteo_por_municipio[municipio] = conteo_por_municipio.get(municipio, 0) + 1

        return {
            "rol": rol,
            "total_municipios": len(conteo_por_municipio),
            "visitas_por_municipio": conteo_por_municipio
        }

    elif rol == "admin":
        total = db.query(models.VisitaCompletaPAE).count()
        return {
            "rol": rol,
            "total_visitas": total,
            "mensaje": "Admin: acceso total al sistema"
        }

    return {"mensaje": "Rol no autorizado para este dashboard"}

@router.get("/supervisor/estadisticas")
def estadisticas_supervisor(
    request: Request,
    db: Session = Depends(get_db),
    usuario: models.Usuario = Depends(obtener_usuario_actual)
):
    """Obtiene estadísticas reales para el dashboard del supervisor"""
    
    # COMENTADO: Verificación de supervisor deshabilitada temporalmente
    # if usuario.rol.nombre != "supervisor":
    #     return {
    #         "error": "Acceso denegado. Solo supervisores pueden acceder a estas estadísticas."
    #     }
    
    try:
        # Contar total de visitas
        total_visitas = db.query(models.VisitaCompletaPAE).count()
        
        # Contar visitas pendientes
        visitas_pendientes = db.query(models.VisitaCompletaPAE).filter(
            models.VisitaCompletaPAE.estado == "pendiente"
        ).count()
        
        # Contar visitas completadas
        visitas_completadas = db.query(models.VisitaCompletaPAE).filter(
            models.VisitaCompletaPAE.estado == "completada"
        ).count()
        
        # Contar total de usuarios
        total_usuarios = db.query(models.Usuario).count()
        
        print(f"📊 Estadísticas del supervisor {usuario.nombre} (ID: {usuario.id}):")
        print(f"   - Total visitas: {total_visitas}")
        print(f"   - Pendientes: {visitas_pendientes}")
        print(f"   - Completadas: {visitas_completadas}")
        print(f"   - Total usuarios: {total_usuarios}")
        
        return {
            "total_visitas": total_visitas,
            "visitas_pendientes": visitas_pendientes,
            "visitas_completadas": visitas_completadas,
            "total_usuarios": total_usuarios,
        }
        
    except Exception as e:
        print(f"❌ Error al obtener estadísticas del supervisor: {str(e)}")
        return {
            "error": f"Error al obtener estadísticas: {str(e)}"
        }

@router.get("/actividad")
def obtener_actividad_reciente(
    request: Request,
    db: Session = Depends(get_db),
    usuario: models.Usuario = Depends(obtener_usuario_actual)
):
    """Obtiene la actividad reciente del sistema"""
    
    try:
        # Obtener las últimas 10 visitas
        ultimas_visitas = db.query(models.VisitaCompletaPAE)\
            .order_by(models.VisitaCompletaPAE.fecha_creacion.desc())\
            .limit(10)\
            .all()
        
        # Obtener estadísticas rápidas
        total_visitas = db.query(models.VisitaCompletaPAE).count()
        visitas_hoy = db.query(models.VisitaCompletaPAE)\
            .filter(func.date(models.VisitaCompletaPAE.fecha_creacion) == func.date(func.now()))\
            .count()
        
        # Obtener usuarios activos (que han creado visitas)
        usuarios_activos = db.query(models.Usuario)\
            .join(models.VisitaCompletaPAE, models.Usuario.id == models.VisitaCompletaPAE.profesional_id)\
            .distinct()\
            .count()
        
        return {
            "ultimas_visitas": [
                {
                    "id": visita.id,
                    "fecha_creacion": visita.fecha_creacion,
                    "estado": visita.estado,
                    "profesional": visita.profesional.nombre,
                    "sede": visita.sede.nombre,
                    "municipio": visita.municipio.nombre
                }
                for visita in ultimas_visitas
            ],
            "estadisticas": {
                "total_visitas": total_visitas,
                "visitas_hoy": visitas_hoy,
                "usuarios_activos": usuarios_activos
            }
        }
        
    except Exception as e:
        print(f"❌ Error al obtener actividad reciente: {str(e)}")
        return {
            "error": f"Error al obtener actividad: {str(e)}"
        }
