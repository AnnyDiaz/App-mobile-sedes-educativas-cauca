from sqlalchemy import Column, Integer, Float, String, Text, ForeignKey, DateTime, Boolean, Date, Time
from sqlalchemy.orm import relationship
from datetime import datetime, date
from .database import Base

# --- MODELOS DE AUTENTICACIÓN Y ROLES ---

class Rol(Base):
    __tablename__ = "roles"
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, unique=True, nullable=False)
    usuarios = relationship("Usuario", back_populates="rol")

class Usuario(Base):
    __tablename__ = "usuarios"
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, nullable=False)
    correo = Column(String, unique=True, index=True, nullable=False)
    contrasena = Column(String, nullable=False)
    rol_id = Column(Integer, ForeignKey("roles.id"), nullable=False)
    rol = relationship("Rol", back_populates="usuarios")

# --- MODELOS DE VISITAS ---

class SedeEducativa(Base):
    __tablename__ = "sedes_educativas"
    id = Column(Integer, primary_key=True, index=True)
    nombre_sede = Column(String, nullable=False)
    institucion_id = Column(Integer, ForeignKey("instituciones.id"), nullable=False)
    municipio_id = Column(Integer, ForeignKey("municipios.id"), nullable=False)
    dane = Column(String, nullable=True)
    due = Column(String, nullable=True)
    lat = Column(Float, nullable=True)
    lon = Column(Float, nullable=True)
    principal = Column(Boolean, default=False)

    @property
    def nombre(self):
        return self.nombre_sede

    institucion = relationship("Institucion")
    municipio = relationship("Municipio")

class Visita(Base):
    """
    Tabla de visitas generales con evidencias (de main).
    """
    __tablename__ = "visitas"

    id = Column(Integer, primary_key=True, index=True)
    sede_id = Column(Integer, ForeignKey("sedes_educativas.id"), nullable=False)
    tipo_asunto = Column(Text, nullable=False)
    foto_evidencia = Column(String, nullable=True)
    video_evidencia = Column(String, nullable=True)
    pdf_evidencia = Column(String, nullable=True)
    audio_evidencia = Column(String, nullable=True)
    foto_firma = Column(String, nullable=True)
    lat = Column(Float, nullable=True)
    lon = Column(Float, nullable=True)
    fecha = Column(Date, default=date.today)
    responsable = Column(String, nullable=True)
    observaciones = Column(Text, nullable=True)
    prioridad = Column(String, nullable=True)
    hora = Column(Time, nullable=True)

    sede = relationship("SedeEducativa")

# --- Visitas Asignadas, Programadas, Cronogramas, Checklists ---
# (Aquí dejas tal cual lo que ya tenías en develop: VisitaAsignada, VisitaProgramada, VisitaCompletaPAE, ChecklistCategoria, ChecklistItem, etc.)
# --- Notificaciones y Reportes ---
# (Igual, se mantienen los modelos de develop para no perder funcionalidades.)
