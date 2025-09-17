from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, Request, Query, status
from sqlalchemy.orm import Session, joinedload
from app import models, schemas
from app.database import get_db
from typing import Optional, List
from uuid import uuid4
import shutil
import os
from datetime import time as time_class
from app.dependencies import get_current_user

router = APIRouter(
    tags=["Visitas y Sedes"]
)

# --- UTILIDADES ---

def guardar_archivo(archivo: UploadFile, carpeta: str) -> Optional[str]:
    if not archivo:
        return None
    ext = archivo.filename.split(".")[-1]
    nombre_archivo = f"{uuid4()}.{ext}"
    ruta_directorio = os.path.join("media", carpeta)
    os.makedirs(ruta_directorio, exist_ok=True)
    ruta_completa = os.path.join(ruta_directorio, nombre_archivo)
    with open(ruta_completa, "wb") as buffer:
        shutil.copyfileobj(archivo.file, buffer)
    return ruta_completa

def _build_absolute_url(request: Request, file_path: str) -> Optional[str]:
    if not file_path:
        return None
    return str(request.base_url) + file_path.replace("\\", "/")

# --- ENDPOINTS BÁSICOS (de main) ---

@router.get("/ping")
async def ping():
    """Prueba de conexión."""
    return {"message": "pong"}

@router.get("/sedes", response_model=List[schemas.SedeEducativaOut])
def get_sedes(db: Session = Depends(get_db)):
    """Devuelve todas las sedes educativas (versión simple)."""
    return db.query(models.SedeEducativa).all()

@router.post("/visitas", response_model=schemas.VisitaOut, status_code=status.HTTP_201_CREATED)
def crear_visita_basica(
    sede_id: int = Form(...),
    tipo_asunto: str = Form(...),
    lat: float = Form(...),
    lon: float = Form(...),
    responsable: str = Form(None),
    observaciones: str = Form(None),
    prioridad: str = Form(None),
    hora: str = Form(None),
    foto: UploadFile = File(None),
    video: UploadFile = File(None),
    audio: UploadFile = File(None),
    pdf: UploadFile = File(None),
    firma: UploadFile = File(None),
    db: Session = Depends(get_db)
):
    """Crea una visita básica (usa modelo Visita)."""
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
    return nueva_visita

@router.get("/visitas", response_model=List[schemas.VisitaOut])
def listar_visitas_basicas(request: Request, db: Session = Depends(get_db)):
    """Lista todas las visitas básicas (usa modelo Visita)."""
    visitas = db.query(models.Visita).options(joinedload(models.Visita.sede)).all()
    for v in visitas:
        v.foto_evidencia = _build_absolute_url(request, v.foto_evidencia)
        v.video_evidencia = _build_absolute_url(request, v.video_evidencia)
        v.audio_evidencia = _build_absolute_url(request, v.audio_evidencia)
        v.pdf_evidencia = _build_absolute_url(request, v.pdf_evidencia)
        v.foto_firma = _build_absolute_url(request, v.foto_firma)
    return visitas

# --- ENDPOINTS AVANZADOS (de develop) ---
# Aquí van tal cual todos los que ya tenías:
# municipios, instituciones, sedes_por_municipio, sedes_por_institucion,
# visitas completas PAE, dashboard, checklist, perfil, cambiar contraseña, etc.
