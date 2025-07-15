from sqlalchemy import Column, Integer, Float, String, Text, ForeignKey, Date, Time
from .database import Base
from sqlalchemy.orm import relationship
from datetime import date
from sqlalchemy import Column, Integer, String
from .database import Base




class Usuario(Base):
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, nullable=False)
    correo = Column(String, unique=True, index=True, nullable=False)
    contrasena = Column(String, nullable=False)

    rol_id = Column(Integer, ForeignKey("roles.id"), nullable=False)
    rol = relationship("Rol", back_populates="usuarios")

    visitas = relationship("Visita", back_populates="usuario")


class SedeEducativa(Base):
    __tablename__ = "sedes_educativas"

    id = Column(Integer, primary_key=True, index=True)
    due = Column(String, nullable=False)
    institucion = Column(String, nullable=False)
    sede = Column(String, nullable=False)
    municipio = Column(String, nullable=False)
    dane = Column(String, nullable=False)
    lat = Column(Float, nullable=True)
    lon = Column(Float, nullable=True)


class Visita(Base):
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
    estado = Column(String, default="pendiente")
    usuario_id = Column(Integer, ForeignKey("usuarios.id")) 
    usuario = relationship("Usuario", back_populates="visitas") 
    sede = relationship("SedeEducativa")


class Rol(Base):
    __tablename__ = "roles"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, unique=True, nullable=False)

    usuarios = relationship("Usuario", back_populates="rol")

