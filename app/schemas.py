from pydantic import BaseModel, Field
from typing import Optional
from datetime import date,time

class SedeEducativaOut(BaseModel):
    id: int
    due: str
    institucion: str
    sede: str
    municipio: str
    dane: str
    lat: Optional[float]
    lon: Optional[float]

    class Config:
        from_attributes = True 


class VisitaOut(BaseModel):
    id: int
    sede_id: int
    tipo_asunto: str
    foto_evidencia: Optional[str]
    video_evidencia: Optional[str]
    audio_evidencia: Optional[str]
    pdf_evidencia: Optional[str]
    foto_firma: Optional[str]
    lat: Optional[float]
    lon: Optional[float]
    fecha: date
    sede: Optional[SedeEducativaOut]

    class Config:
        from_attributes = True


class VisitaCreate(BaseModel):
    id: int
    tipo_asunto: str
    lat: Optional[float]
    lon: Optional[float]
    fecha: date
    responsable: Optional[str]
    observaciones: Optional[str]
    prioridad: Optional[str]
    hora: Optional[time]
    sede: Optional[SedeEducativaOut]

    class Config:
        from_attributes = True