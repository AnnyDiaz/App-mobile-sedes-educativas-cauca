from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, Request, Query
from sqlalchemy.orm import Session, joinedload
from app import models, schemas
from app.database import get_db
from datetime import time as time_class
import os
import shutil
from typing import Optional
from app.routes.auth import verificar_rol_permitido
from uuid import uuid4
from app.dependencies import get_current_user
from app.routes.auth import obtener_usuario_actual
from app.routes.auth import verificar_rol_permitido 
from fastapi import Path

router = APIRouter()


@router.get("/ping")
async def ping():
    return {"message": "pong"}


@router.get("/sedes", response_model=list[schemas.SedeEducativaOut])
def get_sedes(db: Session = Depends(get_db)):
    return db.query(models.SedeEducativa).all()


@router.post("/crear_visita")
async def crear_visita(
    sede_id: int,
    tipo_asunto: str,
    lat: float,
    lon: float,
    responsable: str = "",
    observaciones: str = "",
    prioridad: str = "",
    hora: str = "",
    foto: UploadFile = File(None),
    video: UploadFile = File(None),
    audio: UploadFile = File(None),
    pdf: UploadFile = File(None),
    firma: UploadFile = File(None),
    db: Session = Depends(get_db),
    usuario: models.Usuario = Depends(obtener_usuario_actual)
):
    # Crear carpeta si no existe
    os.makedirs("media", exist_ok=True)

    # Función para guardar un archivo
    def guardar_archivo(file: UploadFile):
        if file:
            ruta = f"media/{file.filename}"
            with open(ruta, "wb") as f:
                f.write(file.file.read())
            return ruta
        return None

    nueva_visita = models.Visita(
        sede_id=sede_id,
        tipo_asunto=tipo_asunto,
        lat=lat,
        lon=lon,
        responsable=responsable,
        observaciones=observaciones,
        prioridad=prioridad,
        hora=hora,
        usuario_id=usuario.id,
        foto_evidencia=guardar_archivo(foto),
        video_evidencia=guardar_archivo(video),
        audio_evidencia=guardar_archivo(audio),
        pdf_evidencia=guardar_archivo(pdf),
        foto_firma=guardar_archivo(firma)
    )
    db.add(nueva_visita)
    db.commit()
    db.refresh(nueva_visita)

    return {
        "mensaje": "Visita registrada con éxito",
        "visita_id": nueva_visita.id
    }

@router.get("/visitas", response_model=list[schemas.VisitaOut])
def listar_visitas(request: Request, db: Session = Depends(get_db)):
    visitas = db.query(models.Visita).options(joinedload(models.Visita.sede)).all()

    def make_absolute_url(path):
        if path:
            return str(request.base_url) + path.replace("\\", "/")
        return None

    for visita in visitas:
        visita.foto_evidencia = make_absolute_url(visita.foto_evidencia)
        visita.video_evidencia = make_absolute_url(visita.video_evidencia)
        visita.audio_evidencia = make_absolute_url(visita.audio_evidencia)
        visita.pdf_evidencia = make_absolute_url(visita.pdf_evidencia)
        visita.foto_firma = make_absolute_url(visita.foto_firma)

    return visitas


@router.get("/visitas/usuario", response_model=schemas.UsuarioOut)
def obtener_usuario_de_visita(usuario: models.Usuario = Depends(obtener_usuario_actual)):
    return {
        "mensaje": f"Hola {usuario.nombre}, estas son tus visitas.",
        "rol": usuario.rol
    }


@router.get("/admin/usuarios")
def listar_usuarios(usuario=Depends(verificar_rol_permitido(["admin"]))):
    return {"mensaje": f"Hola {usuario.nombre}, solo los administradores pueden acceder a esta ruta."}



@router.get("/perfil", response_model=schemas.UsuarioOut)
def perfil(usuario=Depends(obtener_usuario_actual)):
    return schemas.UsuarioOut(
        id=usuario.id,
        nombre=usuario.nombre,
        correo=usuario.correo,
        rol=usuario.rol.nombre
    )



@router.put("/visitas/{id}/estado")
def actualizar_estado_visita(
    id: int = Path(..., description="ID de la visita"),
    nuevo_estado: str = Form(..., regex="^(pendiente|completada)$"),
    db: Session = Depends(get_db),
    usuario: models.Usuario = Depends(obtener_usuario_actual)
):
    visita = db.query(models.Visita).filter(models.Visita.id == id).first()
    if not visita:
        raise HTTPException(status_code=404, detail="Visita no encontrada")

    visita.estado = nuevo_estado
    db.commit()
    db.refresh(visita)

    return {
        "mensaje": f"Estado de la visita {id} actualizado a '{nuevo_estado}'",
        "visita_id": visita.id,
        "nuevo_estado": visita.estado
    }

@router.get("/visitas/mis-visitas", response_model=list[schemas.VisitaOut])
def listar_mis_visitas(
    request: Request,
    db: Session = Depends(get_db),
    usuario: models.Usuario = Depends(obtener_usuario_actual)
):
    visitas = db.query(models.Visita).options(joinedload(models.Visita.sede))\
        .filter(models.Visita.usuario_id == usuario.id).all()

    def make_absolute_url(path):
        if path:
            return str(request.base_url) + path.replace("\\", "/")
        return None

    for visita in visitas:
        visita.foto_evidencia = make_absolute_url(visita.foto_evidencia)
        visita.video_evidencia = make_absolute_url(visita.video_evidencia)
        visita.audio_evidencia = make_absolute_url(visita.audio_evidencia)
        visita.pdf_evidencia = make_absolute_url(visita.pdf_evidencia)
        visita.foto_firma = make_absolute_url(visita.foto_firma)

    return visitas


@router.get("/visitas/por-sede/{sede_id}", response_model=list[schemas.VisitaOut])
def listar_visitas_por_sede(
    sede_id: int,
    request: Request,
    db: Session = Depends(get_db),
    usuario: models.Usuario = Depends(obtener_usuario_actual)
):
    visitas = db.query(models.Visita).options(joinedload(models.Visita.sede))\
        .filter(models.Visita.sede_id == sede_id).all()

    if not visitas:
        raise HTTPException(status_code=404, detail="No se encontraron visitas para esta sede.")

    def make_absolute_url(path):
        if path:
            return str(request.base_url) + path.replace("\\", "/")
        return None

    for visita in visitas:
        visita.foto_evidencia = make_absolute_url(visita.foto_evidencia)
        visita.video_evidencia = make_absolute_url(visita.video_evidencia)
        visita.audio_evidencia = make_absolute_url(visita.audio_evidencia)
        visita.pdf_evidencia = make_absolute_url(visita.pdf_evidencia)
        visita.foto_firma = make_absolute_url(visita.foto_firma)

    return visitas



@router.get("/visitas", response_model=list[schemas.VisitaOut])
def listar_visitas_filtradas(
    request: Request,
    estado: Optional[str] = Query(None),
    desde: Optional[str] = Query(None),
    hasta: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    usuario: models.Usuario = Depends(obtener_usuario_actual)
):
    query = db.query(models.Visita).options(joinedload(models.Visita.sede))

    if estado:
        query = query.filter(models.Visita.estado == estado)
    
    if desde:
        fecha_desde = datetime.strptime(desde, "%Y-%m-%d").date()
        query = query.filter(models.Visita.fecha >= fecha_desde)

    if hasta:
        fecha_hasta = datetime.strptime(hasta, "%Y-%m-%d").date()
        query = query.filter(models.Visita.fecha <= fecha_hasta)

    visitas = query.all()

    def make_absolute_url(path):
        return str(request.base_url) + path.replace("\\", "/") if path else None

    for visita in visitas:
        visita.foto_evidencia = make_absolute_url(visita.foto_evidencia)
        visita.video_evidencia = make_absolute_url(visita.video_evidencia)
        visita.audio_evidencia = make_absolute_url(visita.audio_evidencia)
        visita.pdf_evidencia = make_absolute_url(visita.pdf_evidencia)
        visita.foto_firma = make_absolute_url(visita.foto_firma)

    return visitas



@router.get("/dashboard/visitas/resumen")
def resumen_visitas(
    db: Session = Depends(get_db),
    usuario: models.Usuario = Depends(obtener_usuario_actual)
):
    from sqlalchemy import func

    resumen = {}

    if usuario.rol.nombre == "admin":
        resumen["total_visitas"] = db.query(func.count(models.Visita.id)).scalar()

        resumen["por_sede"] = db.query(
            models.SedeEducativa.sede,
            func.count(models.Visita.id)
        ).join(models.Visita).group_by(models.SedeEducativa.sede).all()

        resumen["por_municipio"] = db.query(
            models.SedeEducativa.municipio,
            func.count(models.Visita.id)
        ).join(models.Visita).group_by(models.SedeEducativa.municipio).all()

        resumen["por_usuario"] = db.query(
            models.Usuario.nombre,
            func.count(models.Visita.id)
        ).join(models.Visita).group_by(models.Usuario.nombre).all()

    elif usuario.rol.nombre == "supervisor":
        # Filtrado por municipio si se desea
        resumen["por_municipio"] = db.query(
            models.SedeEducativa.municipio,
            func.count(models.Visita.id)
        ).join(models.Visita).group_by(models.SedeEducativa.municipio).all()

    elif usuario.rol.nombre == "visitador":
        resumen["mis_visitas"] = db.query(
            func.count(models.Visita.id)
        ).filter(models.Visita.usuario_id == usuario.id).scalar()

    return resumen
