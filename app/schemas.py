# app/schemas.py

from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

# --- Schemas para Roles y Usuarios ---

class RolOut(BaseModel):
    id: int
    nombre: str

    class Config:
        from_attributes = True

class UsuarioOut(BaseModel):
    id: int
    nombre: str
    correo: str
    rol: RolOut # Anidamos el rol para ver su nombre

    class Config:
        from_attributes = True

# Schema compatible con el frontend
class UsuarioFrontendOut(BaseModel):
    id: int
    nombre: str
    apellido: Optional[str] = None
    correo: str
    rol: Optional[str] = None  # String directo para compatibilidad
    activo: Optional[bool] = True
    fechaCreacion: Optional[datetime] = None

    class Config:
        from_attributes = True

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

# --- Schemas para Estructura Educativa (NORMALIZADOS) ---

class MunicipioOut(BaseModel):
    id: int
    nombre: str

    class Config:
        from_attributes = True

# Alias para compatibilidad con el frontend
MunicipioResponse = MunicipioOut

class InstitucionOut(BaseModel):
    id: int
    nombre: str
    dane: Optional[str] = None
    municipio_id: Optional[int] = None

    class Config:
        from_attributes = True

# Alias para compatibilidad con el frontend
InstitucionResponse = InstitucionOut

# Schema completo para la sede
class SedeEducativaOut(BaseModel):
    id: int
    nombre: str
    dane: Optional[str] = ""  # Puede ser None, convertimos a string vacío
    due: Optional[str] = ""  # Puede ser None, convertimos a string vacío
    lat: Optional[float] = None
    lon: Optional[float] = None
    principal: bool = False
    # Anidamos los objetos completos para tener toda la info
    municipio: MunicipioOut
    institucion: InstitucionOut

    class Config:
        from_attributes = True

# Schema simplificado para listas
class SedeEducativaSimpleOut(BaseModel):
    id: int
    nombre: str

    class Config:
        from_attributes = True

# Schema simplificado para sedes con información básica
class SedeEducativaBasicaOut(BaseModel):
    id: int
    nombre: str
    dane: Optional[str] = ""  # Permitir None o string vacío
    due: Optional[str] = ""  # Permitir None o string vacío
    lat: Optional[float] = None
    lon: Optional[float] = None
    principal: bool = False
    municipio_id: int
    institucion_id: int

    class Config:
        from_attributes = True

# Schema para crear sedes educativas
class SedeEducativaCreate(BaseModel):
    nombre: str
    dane: str
    due: str
    lat: Optional[float] = None
    lon: Optional[float] = None
    principal: bool = False
    municipio_id: int
    institucion_id: int

# Schema para actualizar sedes educativas (campos opcionales)
class SedeEducativaUpdate(BaseModel):
    nombre: Optional[str] = None
    dane: Optional[str] = None
    due: Optional[str] = None
    lat: Optional[float] = None
    lon: Optional[float] = None
    principal: Optional[bool] = None
    municipio_id: Optional[int] = None
    institucion_id: Optional[int] = None

# Alias para compatibilidad con el frontend
SedeResponse = SedeEducativaOut

# --- Schemas para Visitas ---

class VisitaOut(BaseModel):
    id: int
    fecha_creacion: datetime
    estado: str
    observaciones: Optional[str]
    
    # Anidamos la información de la sede y el usuario
    sede: SedeEducativaOut
    usuario: UsuarioOut

    # Rutas a los archivos (opcionalmente puedes construir la URL completa aquí)
    foto_evidencia: Optional[str]
    video_evidencia: Optional[str]
    audio_evidencia: Optional[str]
    pdf_evidencia: Optional[str]
    foto_firma: Optional[str]

    class Config:
        from_attributes = True

class EstadoVisitaUpdate(BaseModel):
    estado: str 


    # --- Schemas para Guardar una Visita ---

class VisitaRespuestaCreate(BaseModel):
    item_id: int  # El ID de la pregunta
    respuesta: str  # "Cumple", "No Cumple", etc.
    observacion: Optional[str] = None

# NOTA: Los schemas de Cronograma PAE han sido reemplazados por VisitaCompletaPAE
# Se mantienen comentados por referencia histórica

# class EvaluacionPAECrear(BaseModel):
#     item: str
#     valor: str  # 1, 2, 0, N/A, N/O
# 
# class CronogramaPAECrear(BaseModel):
#     fecha_visita: datetime
#     contrato: str
#     operador: str
#     municipio_id: int
#     institucion_id: int
#     sede_id: int
#     profesional_id: int
#     caso_atencion_prioritaria: str  # SI, NO, NO HUBO SERVICIO, ACTA RAPIDA
#     evaluaciones: List[EvaluacionPAECrear] = []  # Lista vacía por defecto
#     respuestas_checklist: List[VisitaRespuestaCreate] = []  # Respuestas del checklist
#     
#     class Config:
#         json_encoders = {
#             datetime: lambda v: v.isoformat()
#         }

# --- Schemas para el Checklist ---

class ChecklistItemBase(BaseModel):
    id: int
    pregunta_texto: str

    class Config:
        from_attributes = True

class ChecklistCategoriaBase(BaseModel):
    id: int
    nombre: str
    items: List[ChecklistItemBase] = []  # Una lista de preguntas dentro de cada categoría

    class Config:
        from_attributes = True

# --- Schemas para Visitas Asignadas ---

class VisitaAsignadaCreate(BaseModel):
    sede_id: int
    visitador_id: int
    fecha_programada: datetime
    tipo_visita: str = "PAE"
    prioridad: str = "normal"
    contrato: Optional[str] = None
    operador: Optional[str] = None
    caso_atencion_prioritaria: Optional[str] = None
    municipio_id: int
    institucion_id: int
    observaciones: Optional[str] = None

class VisitaAsignadaUpdate(BaseModel):
    estado: Optional[str] = None
    fecha_inicio: Optional[datetime] = None
    fecha_completada: Optional[datetime] = None
    observaciones: Optional[str] = None

class VisitaAsignadaOut(BaseModel):
    id: int
    sede_id: int
    sede_nombre: str
    visitador_id: int
    visitador_nombre: str
    supervisor_id: int
    supervisor_nombre: str
    fecha_programada: datetime
    tipo_visita: str
    prioridad: str
    estado: str
    contrato: Optional[str]
    operador: Optional[str]
    caso_atencion_prioritaria: Optional[str]
    municipio_id: int
    municipio_nombre: str
    institucion_id: int
    institucion_nombre: str
    observaciones: Optional[str]
    fecha_creacion: datetime
    fecha_inicio: Optional[datetime]
    fecha_completada: Optional[datetime]

    class Config:
        from_attributes = True

# --- Schemas para Visita Completa PAE ---

class VisitaRespuestaCompletaCreate(BaseModel):
    item_id: int
    respuesta: str
    observacion: Optional[str] = None

class VisitaCompletaPAECreate(BaseModel):
    # Datos del cronograma PAE
    fecha_visita: datetime
    contrato: str
    operador: str
    caso_atencion_prioritaria: str
    municipio_id: int
    institucion_id: int
    sede_id: int
    profesional_id: int
    
    # Datos adicionales de la visita
    observaciones: Optional[str] = None
    
    # Respuestas del checklist
    respuestas_checklist: List[VisitaRespuestaCompletaCreate] = []
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }

class VisitaCompletaPAEOut(BaseModel):
    id: int
    fecha_visita: datetime
    contrato: str
    operador: str
    caso_atencion_prioritaria: str
    municipio_id: int
    institucion_id: int
    sede_id: int
    profesional_id: int
    fecha_creacion: datetime
    estado: str
    observaciones: Optional[str]
    numero_visita_usuario: Optional[int]
    
    # Información relacionada
    municipio: MunicipioOut
    institucion: InstitucionOut
    sede: SedeEducativaOut
    profesional: UsuarioOut
    
    # Respuestas del checklist
    respuestas_checklist: List[VisitaRespuestaCreate] = []
    
    class Config:
        from_attributes = True

# --- Schemas para Notificaciones Push ---

class DispositivoNotificacionCreate(BaseModel):
    token_dispositivo: str
    plataforma: str  # "android", "ios", "web"

class DispositivoNotificacionUpdate(BaseModel):
    activo: Optional[bool] = None
    ultima_actividad: Optional[datetime] = None

class DispositivoNotificacionOut(BaseModel):
    id: int
    usuario_id: int
    token_dispositivo: str
    plataforma: str
    activo: bool
    fecha_registro: datetime
    ultima_actividad: datetime

    class Config:
        from_attributes = True

class NotificacionCreate(BaseModel):
    usuario_id: int
    titulo: str
    mensaje: str
    tipo: str  # "visita_proxima", "visita_vencida", "recordatorio", "sistema"
    prioridad: str = "normal"  # "baja", "normal", "alta", "urgente"
    datos_adicionales: Optional[str] = None  # JSON string

class NotificacionUpdate(BaseModel):
    leida: Optional[bool] = None
    fecha_lectura: Optional[datetime] = None

class NotificacionOut(BaseModel):
    id: int
    usuario_id: int
    titulo: str
    mensaje: str
    tipo: str
    prioridad: str
    leida: bool
    fecha_envio: datetime
    fecha_lectura: Optional[datetime]
    datos_adicionales: Optional[str]

    class Config:
        from_attributes = True

class NotificacionPushRequest(BaseModel):
    """
    Schema para solicitar el envío de una notificación push
    """
    titulo: str
    mensaje: str
    tipo: str
    prioridad: str = "normal"
    usuario_ids: List[int]  # Lista de usuarios a notificar
    datos_adicionales: Optional[dict] = None

class NotificacionPushResponse(BaseModel):
    """
    Schema para la respuesta del envío de notificaciones push
    """
    exitosas: int
    fallidas: int
    detalles: List[dict]
    mensaje: str
