from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, Request
from sqlalchemy.orm import Session, joinedload
from app import models, schemas
from app.database import get_db
from datetime import time as time_class
import os
import shutil
from uuid import uuid4

router = APIRouter()


@router.get("/ping")
async def ping():
    return {"message": "pong"}


@router.get("/sedes", response_model=list[schemas.SedeEducativaOut])
def get_sedes(db: Session = Depends(get_db)):
    return db.query(models.SedeEducativa).all()


@router.post("/visitas")
def crear_visita(
    sede_id: int = Form(...),
    tipo_asunto: str = Form(...),
    lat: float = Form(...),
    lon: float = Form(...),
    responsable: str = Form(None),
    observaciones: str = Form(None),
    prioridad: str = Form(None),
    hora: str = Form(None),  # Formato HH:MM o HH:MM:SS
    foto: UploadFile = File(None),
    video: UploadFile = File(None),
    audio: UploadFile = File(None),
    pdf: UploadFile = File(None),
    firma: UploadFile = File(None),
    db: Session = Depends(get_db)
):
    def guardar_archivo(archivo: UploadFile, carpeta: str):
        if archivo:
            ext = archivo.filename.split(".")[-1]
            nombre_archivo = f"{uuid4()}.{ext}"
            ruta = os.path.join("media", carpeta)
            os.makedirs(ruta, exist_ok=True)
            ruta_archivo = os.path.join(ruta, nombre_archivo)
            with open(ruta_archivo, "wb") as buffer:
                shutil.copyfileobj(archivo.file, buffer)
            return ruta_archivo
        return None

    hora_obj = time_class.fromisoformat(hora) if hora else None

    nueva_visita = models.Visita(
        sede_id=sede_id,
        tipo_asunto=tipo_asunto,
        lat=lat,
        lon=lon,
        responsable=responsable,
        observaciones=observaciones,
        prioridad=prioridad,
        hora=hora_obj,
        foto_evidencia=guardar_archivo(foto, "fotos"),
        video_evidencia=guardar_archivo(video, "videos"),
        audio_evidencia=guardar_archivo(audio, "audios"),
        pdf_evidencia=guardar_archivo(pdf, "pdfs"),
        foto_firma=guardar_archivo(firma, "firmas")
    )

    db.add(nueva_visita)
    db.commit()
    db.refresh(nueva_visita)

    return {"mensaje": "Visita registrada exitosamente", "id": nueva_visita.id}


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
