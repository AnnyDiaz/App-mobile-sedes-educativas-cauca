# app/models_clean.py
# Versión limpia con solo las tablas que existen en la BD actual

from sqlalchemy import Column, Integer, Float, String, Text, ForeignKey, DateTime, Boolean
from sqlalchemy.orm import relationship
from datetime import datetime
from .database import Base

# --- MODELOS DE AUTENTICACIÓN Y ROLES ---

class Rol(Base):
    """
    Define los roles de los usuarios en el sistema (ej. 'Administrador', 'Auditor').
    """
    __tablename__ = "roles"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, unique=True, nullable=False)
    
    # Relación para ver qué usuarios tienen este rol
    usuarios = relationship("Usuario", back_populates="rol")

class Usuario(Base):
    """
    Almacena la información de los usuarios que pueden iniciar sesión en la app.
    """
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, nullable=False)
    correo = Column(String, unique=True, index=True, nullable=False)
    contrasena = Column(String, nullable=False)  # Hash de la contraseña
    rol_id = Column(Integer, ForeignKey("roles.id"), nullable=False)
    
    # Relación con el rol
    rol = relationship("Rol", back_populates="usuarios")

# --- MODELO PARA VISITAS ASIGNADAS ---

class VisitaAsignada(Base):
    """
    Modelo para almacenar visitas asignadas por supervisores a visitadores.
    """
    __tablename__ = "visitas_asignadas"

    id = Column(Integer, primary_key=True, index=True)
    
    # --- DATOS DE ASIGNACIÓN ---
    sede_id = Column(Integer, ForeignKey("sedes_educativas.id"), nullable=False)
    visitador_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False)
    supervisor_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False)
    fecha_programada = Column(DateTime, nullable=False)
    
    # --- DATOS DE LA VISITA ---
    tipo_visita = Column(String, nullable=False, default="PAE")  # PAE, Mantenimiento, etc.
    prioridad = Column(String, nullable=False, default="normal")  # baja, normal, alta, urgente
    estado = Column(String, nullable=False, default="pendiente")  # pendiente, en_proceso, completada, cancelada
    
    # --- DATOS DEL CRONOGRAMA PAE ---
    contrato = Column(String, nullable=True)
    operador = Column(String, nullable=True)
    caso_atencion_prioritaria = Column(String, nullable=True)
    
    # --- DATOS DE UBICACIÓN ---
    municipio_id = Column(Integer, ForeignKey("municipios.id"), nullable=False)
    institucion_id = Column(Integer, ForeignKey("instituciones.id"), nullable=False)
    
    # --- METADATOS ---
    observaciones = Column(Text, nullable=True)
    fecha_creacion = Column(DateTime, default=datetime.utcnow)
    fecha_inicio = Column(DateTime, nullable=True)  # Cuando el visitador inicia la visita
    fecha_completada = Column(DateTime, nullable=True)
    
    # Relaciones
    sede = relationship("SedeEducativa", foreign_keys=[sede_id])
    visitador = relationship("Usuario", foreign_keys=[visitador_id])
    supervisor = relationship("Usuario", foreign_keys=[supervisor_id])
    municipio = relationship("Municipio")
    institucion = relationship("Institucion")

class VisitaProgramada(Base):
    """
    Modelo para almacenar visitas programadas por el sistema.
    """
    __tablename__ = "visitas_programadas"
    
    id = Column(Integer, primary_key=True, index=True)
    sede_id = Column(Integer, ForeignKey("sedes_educativas.id"), nullable=False)
    tipo_visita = Column(String, nullable=False, default="PAE")
    frecuencia = Column(String, nullable=False, default="mensual")  # semanal, quincenal, mensual
    fecha_inicio = Column(DateTime, nullable=False)
    fecha_fin = Column(DateTime, nullable=True)
    activa = Column(Boolean, default=True)
    
    # Relaciones
    sede = relationship("SedeEducativa")

class CodigoRecuperacion(Base):
    """
    Modelo para almacenar códigos de recuperación de contraseña.
    """
    __tablename__ = "codigos_recuperacion"
    
    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False)
    codigo = Column(String(6), nullable=False)
    email = Column(String, nullable=False)
    fecha_creacion = Column(DateTime, nullable=True)
    fecha_expiracion = Column(DateTime, nullable=False)
    usado = Column(Boolean, default=False)
    intentos = Column(Integer, nullable=True)
    expira = Column(DateTime, nullable=True)
    
    # Relaciones
    usuario = relationship("Usuario")

class Municipio(Base):
    __tablename__ = "municipios"
    
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, nullable=False)
    # departamento = Column(String, nullable=False, default="Cauca")  # Comentado hasta migración BD

class Institucion(Base):
    __tablename__ = "instituciones"
    
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, nullable=False)
    municipio_id = Column(Integer, ForeignKey("municipios.id"), nullable=False)
    
    # Relaciones
    municipio = relationship("Municipio")

class SedeEducativa(Base):
    __tablename__ = "sedes_educativas"
    
    id = Column(Integer, primary_key=True, index=True)
    nombre_sede = Column(String, nullable=False)
    institucion_id = Column(Integer, ForeignKey("instituciones.id"), nullable=False)
    municipio_id = Column(Integer, ForeignKey("municipios.id"), nullable=False)
    # direccion = Column(String, nullable=True)  # No existe en la tabla real
    # telefono = Column(String, nullable=True)  # No existe en la tabla real
    # email = Column(String, nullable=True)  # No existe en la tabla real
    # rector = Column(String, nullable=True)  # No existe en la tabla real
    # estado = Column(String, default="activa")  # No existe en la tabla real
    # zona = Column(String, nullable=True)  # urbana, rural - No existe en la tabla real
    # tipo_sede = Column(String, nullable=True)  # principal, anexa - No existe en la tabla real
    # latitud = Column(Float, nullable=True)  # No existe en la tabla real
    # longitud = Column(Float, nullable=True)  # No existe en la tabla real
    # nivel_educativo = Column(String, nullable=True)  # preescolar, primaria, secundaria, media - No existe en la tabla real
    # jornada = Column(String, nullable=True)  # mañana, tarde, noche, completa - No existe en la tabla real
    # modalidad = Column(String, nullable=True)  # presencial, virtual, mixta - No existe en la tabla real
    # total_estudiantes = Column(Integer, nullable=True)  # No existe en la tabla real
    # total_docentes = Column(Integer, nullable=True)  # No existe en la tabla real
    # infraestructura_pae = Column(Boolean, default=False)  # No existe en la tabla real
    # tiene_restaurante_escolar = Column(Boolean, default=False)  # No existe en la tabla real
    # numero_beneficiarios_pae = Column(Integer, nullable=True)  # No existe en la tabla real
    
    # Campos que SÍ existen (basado en SQL que funcionó)
    dane = Column(String, nullable=True)
    due = Column(String, nullable=True) 
    lat = Column(Float, nullable=True)
    lon = Column(Float, nullable=True)
    principal = Column(Boolean, default=False)
    
    # Alias para compatibilidad hacia atrás
    @property
    def nombre(self):
        """Alias para nombre_sede para mantener compatibilidad"""
        return self.nombre_sede
    
    # Relaciones
    institucion = relationship("Institucion")
    municipio = relationship("Municipio")

# Resto de modelos existentes...
class VisitaCompletaPAE(Base):
    __tablename__ = "visitas_completas_pae"
    
    id = Column(Integer, primary_key=True, index=True)
    profesional_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False)
    sede_id = Column(Integer, ForeignKey("sedes_educativas.id"), nullable=False)
    municipio_id = Column(Integer, ForeignKey("municipios.id"), nullable=False)
    institucion_id = Column(Integer, ForeignKey("instituciones.id"), nullable=False)
    
    fecha_visita = Column(DateTime, nullable=False)
    # tipo_visita = Column(String, default="PAE")  # No existe en la tabla real
    contrato = Column(String, nullable=True)
    operador = Column(String, nullable=True)
    # caso_atencion_prioritaria = Column(String, nullable=True)  # No existe en la tabla real
    observaciones = Column(Text, nullable=True)  # Cambio de observaciones_generales a observaciones
    
    # Propiedad para compatibilidad con código existente
    @property
    def caso_atencion_prioritaria(self):
        return getattr(self, '_caso_atencion_prioritaria', "NO")
    
    @caso_atencion_prioritaria.setter
    def caso_atencion_prioritaria(self, value):
        self._caso_atencion_prioritaria = value
    
    # latitud = Column(Float, nullable=True)  # No existe en la tabla real
    # longitud = Column(Float, nullable=True)  # No existe en la tabla real
    
    estado = Column(String, default="completada")
    fecha_creacion = Column(DateTime, default=datetime.utcnow)
    
    # Relaciones
    profesional = relationship("Usuario", foreign_keys=[profesional_id])
    sede = relationship("SedeEducativa")
    municipio = relationship("Municipio")
    institucion = relationship("Institucion")
    
    # Relación con respuestas del checklist
    respuestas_checklist = relationship("VisitaRespuestaCompleta", back_populates="visita")

class VisitaRespuestaCompleta(Base):
    __tablename__ = "visitas_respuestas_completas"
    
    id = Column(Integer, primary_key=True, index=True)
    visita_id = Column(Integer, ForeignKey("visitas_completas_pae.id"), nullable=False)
    categoria_id = Column(Integer, ForeignKey("checklist_categorias.id"), nullable=False)
    item_id = Column(Integer, ForeignKey("checklist_items.id"), nullable=False)
    
    respuesta = Column(String, nullable=False)  # si/no/na/observacion
    observacion = Column(Text, nullable=True)
    archivo_evidencia = Column(String, nullable=True)
    fecha_respuesta = Column(DateTime, default=datetime.utcnow)
    
    # Relaciones
    visita = relationship("VisitaCompletaPAE", back_populates="respuestas_checklist")
    categoria = relationship("ChecklistCategoria")
    item = relationship("ChecklistItem")

class ChecklistCategoria(Base):
    __tablename__ = "checklist_categorias"
    
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, nullable=False)
    # descripcion = Column(Text, nullable=True)  # No existe en BD
    # orden = Column(Integer, default=0)  # No existe en BD
    
    # Relación con los items
    items = relationship("ChecklistItem", back_populates="categoria")
    
    # Propiedades para compatibilidad
    @property
    def descripcion(self):
        return ""
    
    @property
    def orden(self):
        return 0

class ChecklistItem(Base):
    __tablename__ = "checklist_items"
    
    id = Column(Integer, primary_key=True, index=True)
    categoria_id = Column(Integer, ForeignKey("checklist_categorias.id"), nullable=False)
    pregunta_texto = Column(Text, nullable=False)  # Nombre real en BD
    orden = Column(Integer, default=1)  # Existe en BD
    # tipo_respuesta = Column(String, default="si_no")  # No existe en BD
    # obligatorio = Column(Boolean, default=True)  # No existe en BD
    
    # Propiedades para compatibilidad
    @property
    def texto(self):
        return self.pregunta_texto
    
    @property
    def tipo_respuesta(self):
        return "si_no"
    
    @property
    def obligatorio(self):
        return True
    
    # Relaciones
    categoria = relationship("ChecklistCategoria", back_populates="items")

class DispositivoNotificacion(Base):
    __tablename__ = "dispositivos_notificacion"
    
    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False)
    token_fcm = Column(String, nullable=False)
    plataforma = Column(String, nullable=False)  # android, ios, web
    activo = Column(Boolean, default=True)
    fecha_registro = Column(DateTime, default=datetime.utcnow)
    
    # Relaciones
    usuario = relationship("Usuario")

class Notificacion(Base):
    __tablename__ = "notificaciones"
    
    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False)
    titulo = Column(String, nullable=False)
    mensaje = Column(Text, nullable=False)
    tipo = Column(String, default="info")  # info, warning, error, success
    prioridad = Column(String, default="normal")  # baja, normal, alta, urgente
    leida = Column(Boolean, default=False)
    # Campos que no existen en la tabla real:
    # enviada_push = Column(Boolean, default=False)  
    # fecha_creacion = Column(DateTime, default=datetime.utcnow)
    # fecha_vencimiento = Column(DateTime, nullable=True)
    # datos_adicionales = Column(Text, nullable=True)
    
    # Relaciones
    usuario = relationship("Usuario")

class Reporte(Base):
    __tablename__ = "reportes"
    
    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False)
    nombre = Column(String, nullable=False)
    tipo_reporte = Column(String, nullable=False)  # "excel", "pdf", "csv"
    filtros_json = Column(Text, nullable=True)  # Filtros aplicados en formato JSON
    archivo_path = Column(String, nullable=True)
    fecha_creacion = Column(DateTime, default=datetime.utcnow)
    estado = Column(String, default="generado")  # "generado", "descargado", "error"
    
    # Relaciones
    usuario = relationship("Usuario")
