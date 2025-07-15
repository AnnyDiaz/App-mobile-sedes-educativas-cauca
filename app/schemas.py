from pydantic import BaseModel, Field
from typing import Optional
from datetime import date,time
from pydantic import BaseModel


class UsuarioCreate(BaseModel):
    nombre: str
    correo: str
    contrasena: str
    rol_id: int = 1  # por defecto 'visitador'

# schemas.py
class RolOut(BaseModel):
    id: int
    nombre: str

    class Config:
        from_attributes = True

class UsuarioOut(BaseModel):
    id: int
    nombre: str
    correo: str
    rol: str

    class Config:
        from_attributes = True



class Login(BaseModel):
    correo: str
    contrasena: str

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
    estado: str 
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



class CambioContrasena(BaseModel):
    actual: str
    nueva: str


class RecuperarContrasena(BaseModel):
    correo: str

class RestablecerContrasena(BaseModel):
    token: str
    nueva_contrasena: str

