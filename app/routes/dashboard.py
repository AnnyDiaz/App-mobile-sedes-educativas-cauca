from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session
from app.database import get_db
from app import models
from app.routes.auth import obtener_usuario_actual
router = APIRouter(prefix="/dashboard", tags=["Dashboard"])

@router.get("/visitas")
def dashboard_visitas(
    request: Request,
    db: Session = Depends(get_db),
    usuario: models.Usuario = Depends(obtener_usuario_actual)
):
    rol = usuario.rol.nombre

    if rol == "visitador":
        visitas = db.query(models.Visita).filter(models.Visita.usuario_id == usuario.id).all()
        return {
            "rol": rol,
            "total": len(visitas),
            "mensaje": f"Tus visitas registradas: {len(visitas)}",
            "visitas": [v.id for v in visitas]
        }

    elif rol == "supervisor":
        visitas = db.query(models.Visita).join(models.SedeEducativa)\
            .with_entities(models.SedeEducativa.municipio, models.Visita.id)\
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
        total = db.query(models.Visita).count()
        return {
            "rol": rol,
            "total_visitas": total,
            "mensaje": "Admin: acceso total al sistema"
        }

    return {"mensaje": "Rol no autorizado para este dashboard"}
