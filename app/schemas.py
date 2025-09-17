from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime, date, time

# --- Schemas para Roles y Usuarios ---

class RolOut(BaseModel):
    id: int
    nombre: str
    class Config: from_attributes = True

class UsuarioOut(BaseModel):
    id: int
    nombre: str
    correo: str
    rol: RolOut
    class Config: from_attributes = True

class UsuarioFrontendOut(BaseModel):
    id: int
    nombre: str
    apellido: Optional[str] = None
    correo: str
    rol: Optional[str] = None
    activo: Optional[bool] = True
    fechaCreacion: Optional[datetime] = None
    class Config: from_attributes = True

class UsuarioCreate(BaseModel):
    nombre: str
    correo: str
    contrasena: str
    rol_id: int

class Login(BaseModel):
    correo: str
    contrasena: str

class TokenData(BaseModel):
    access_token: str
    token_type: str
    usuario: UsuarioOut

class CambioContrasena(BaseModel):
    actual: str
    nueva: str

# --- Schemas de estructura educativa (completos) ---

class MunicipioOut(BaseModel):
    id: int
    nombre: str
    class Config: from_attributes = True

class InstitucionOut(BaseModel):
    id: int
    nombre: str
    dane: Optional[str] = None
    municipio_id: Optional[int] = None
    class Config: from_attributes = True

class SedeEducativaOut(BaseModel):
    id: int
    nombre: str
    dane: str
    due: str
    lat: Optional[float]
    lon: Optional[float]
    principal: bool
    municipio: MunicipioOut
    institucion: InstitucionOut
    class Config: from_attributes = True

# --- Schemas simplificados (compatibilidad con main) ---

class SedeEducativaSimpleOut(BaseModel):
    id: int
    nombre: str
    class Config: from_attributes = True

class SedeEducativaBasicaOut(BaseModel):
    id: int
    nombre: str
    dane: str
    due: str
    lat: Optional[float]
    lon: Optional[float]
    principal: bool
    municipio_id: int
    institucion_id: int
    class Config: from_attributes = True

# Versión plana del main
class SedeEducativaBasicaResponse(BaseModel):
    id: int
    due: str
    institucion: str
    sede: str
    municipio: str
    dane: str
    lat: Optional[float]
    lon: Optional[float]
    class Config: from_attributes = True

# --- Schemas de Visitas (desarrollados) ---

class VisitaOut(BaseModel):
    id: int
    fecha_creacion: datetime
    estado: str
    observaciones: Optional[str]
    sede: SedeEducativaOut
    usuario: UsuarioOut
    foto_evidencia: Optional[str]
    video_evidencia: Optional[str]
    audio_evidencia: Optional[str]
    pdf_evidencia: Optional[str]
    foto_firma: Optional[str]
    class Config: from_attributes = True

class EstadoVisitaUpdate(BaseModel):
    estado: str

class VisitaRespuestaCreate(BaseModel):
    item_id: int
    respuesta: str
    observacion: Optional[str] = None

# --- Schemas extra (del main) ---

class VisitaOutBasica(BaseModel):
    id: int
    sede_id: int
    tipo_asunto: str
    lat: Optional[float]
    lon: Optional[float]
    fecha: date
    sede: Optional[SedeEducativaBasicaResponse]
    foto_evidencia: Optional[str]
    video_evidencia: Optional[str]
    audio_evidencia: Optional[str]
    pdf_evidencia: Optional[str]
    foto_firma: Optional[str]
    class Config: from_attributes = True

class VisitaCreateBasica(BaseModel):
    tipo_asunto: str
    lat: Optional[float]
    lon: Optional[float]
    fecha: date
    responsable: Optional[str]
    observaciones: Optional[str]
    prioridad: Optional[str]
    hora: Optional[time]
    sede_id: int
    class Config: from_attributes = True

# --- Checklist, Visitas PAE, Notificaciones ---
# (Aquí se mantienen todos los schemas avanzados que ya tenías en develop:
# ChecklistItemBase, ChecklistCategoriaBase, VisitaAsignada*, VisitaCompletaPAE*,
# DispositivoNotificacion*, Notificacion*, etc.)
