# 📚 Documentación Completa del Backend - Sistema PAE Cauca

## 🏗️ Arquitectura General

El backend está construido con **FastAPI** y utiliza una arquitectura modular con los siguientes componentes principales:

### Estructura de Directorios
```
app/
├── main.py                 # Punto de entrada de la aplicación
├── config.py              # Configuración de notificaciones y FCM
├── database.py            # Configuración de base de datos
├── models.py              # Modelos SQLAlchemy
├── schemas.py             # Schemas Pydantic para validación
├── crud.py                # Operaciones de base de datos
├── dependencies.py        # Dependencias de FastAPI
├── routes/                # Módulos de rutas API
│   ├── auth.py           # Autenticación y autorización
│   ├── visitas_completas.py # Gestión de visitas PAE
│   ├── sedes.py          # Gestión de sedes educativas
│   ├── instituciones.py  # Gestión de instituciones
│   ├── municipios.py     # Gestión de municipios
│   ├── usuarios.py       # Gestión de usuarios
│   ├── notificaciones.py # Sistema de notificaciones push
│   └── ...              # Otros módulos
├── services/             # Servicios de negocio
└── utils/               # Utilidades y helpers
```

## 🗄️ Modelos de Base de Datos

### Modelos Principales

#### 1. **Usuario y Roles**
```python
class Rol(Base):
    __tablename__ = "roles"
    id = Column(Integer, primary_key=True)
    nombre = Column(String, unique=True, nullable=False)

class Usuario(Base):
    __tablename__ = "usuarios"
    id = Column(Integer, primary_key=True)
    nombre = Column(String, nullable=False)
    correo = Column(String, unique=True, nullable=False)
    contrasena = Column(String, nullable=False)  # Hash bcrypt
    rol_id = Column(Integer, ForeignKey("roles.id"))
```

#### 2. **Estructura Educativa**
```python
class Municipio(Base):
    __tablename__ = "municipios"
    id = Column(Integer, primary_key=True)
    nombre = Column(String, nullable=False)

class Institucion(Base):
    __tablename__ = "instituciones"
    id = Column(Integer, primary_key=True)
    nombre = Column(String, nullable=False)
    municipio_id = Column(Integer, ForeignKey("municipios.id"))

class SedeEducativa(Base):
    __tablename__ = "sedes_educativas"
    id = Column(Integer, primary_key=True)
    nombre_sede = Column(String, nullable=False)
    institucion_id = Column(Integer, ForeignKey("instituciones.id"))
    municipio_id = Column(Integer, ForeignKey("municipios.id"))
    dane = Column(String, nullable=True)
    due = Column(String, nullable=True)
    lat = Column(Float, nullable=True)
    lon = Column(Float, nullable=True)
    principal = Column(Boolean, default=False)
```

#### 3. **Sistema de Visitas**
```python
class VisitaAsignada(Base):
    __tablename__ = "visitas_asignadas"
    id = Column(Integer, primary_key=True)
    sede_id = Column(Integer, ForeignKey("sedes_educativas.id"))
    visitador_id = Column(Integer, ForeignKey("usuarios.id"))
    supervisor_id = Column(Integer, ForeignKey("usuarios.id"))
    fecha_programada = Column(DateTime, nullable=False)
    tipo_visita = Column(String, default="PAE")
    prioridad = Column(String, default="normal")
    estado = Column(String, default="pendiente")
    contrato = Column(String, nullable=True)
    operador = Column(String, nullable=True)
    caso_atencion_prioritaria = Column(String, nullable=True)

class VisitaCompletaPAE(Base):
    __tablename__ = "visitas_completas_pae"
    id = Column(Integer, primary_key=True)
    profesional_id = Column(Integer, ForeignKey("usuarios.id"))
    sede_id = Column(Integer, ForeignKey("sedes_educativas.id"))
    municipio_id = Column(Integer, ForeignKey("municipios.id"))
    institucion_id = Column(Integer, ForeignKey("instituciones.id"))
    fecha_visita = Column(DateTime, nullable=False)
    contrato = Column(String, nullable=True)
    operador = Column(String, nullable=True)
    observaciones = Column(Text, nullable=True)
    estado = Column(String, default="completada")
```

#### 4. **Sistema de Checklist**
```python
class ChecklistCategoria(Base):
    __tablename__ = "checklist_categorias"
    id = Column(Integer, primary_key=True)
    nombre = Column(String, nullable=False)

class ChecklistItem(Base):
    __tablename__ = "checklist_items"
    id = Column(Integer, primary_key=True)
    categoria_id = Column(Integer, ForeignKey("checklist_categorias.id"))
    pregunta_texto = Column(Text, nullable=False)
    orden = Column(Integer, default=1)

class VisitaRespuestaCompleta(Base):
    __tablename__ = "visitas_respuestas_completas"
    id = Column(Integer, primary_key=True)
    visita_id = Column(Integer, ForeignKey("visitas_completas_pae.id"))
    categoria_id = Column(Integer, ForeignKey("checklist_categorias.id"))
    item_id = Column(Integer, ForeignKey("checklist_items.id"))
    respuesta = Column(String, nullable=False)
    observacion = Column(Text, nullable=True)
    archivo_evidencia = Column(String, nullable=True)
```

#### 5. **Sistema de Notificaciones**
```python
class DispositivoNotificacion(Base):
    __tablename__ = "dispositivos_notificacion"
    id = Column(Integer, primary_key=True)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"))
    token_fcm = Column(String, nullable=False)
    plataforma = Column(String, nullable=False)
    activo = Column(Boolean, default=True)

class Notificacion(Base):
    __tablename__ = "notificaciones"
    id = Column(Integer, primary_key=True)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"))
    titulo = Column(String, nullable=False)
    mensaje = Column(Text, nullable=False)
    tipo = Column(String, default="info")
    prioridad = Column(String, default="normal")
    leida = Column(Boolean, default=False)
```

## 🔐 Sistema de Autenticación

### Características
- **JWT Tokens**: Access tokens (15 min) + Refresh tokens (7 días)
- **Bcrypt**: Hash de contraseñas
- **Rate Limiting**: Protección contra ataques de fuerza bruta
- **Recuperación de contraseña**: Sistema con códigos de verificación por email

### Endpoints de Autenticación

#### POST `/api/auth/register`
Registra un nuevo usuario
```json
{
  "nombre": "string",
  "correo": "string",
  "contrasena": "string",
  "rol_id": 1
}
```

#### POST `/api/auth/login`
Inicia sesión
```json
{
  "correo": "string",
  "contrasena": "string"
}
```

#### POST `/api/auth/refresh`
Renueva access token usando refresh token
```json
{
  "refresh_token": "string"
}
```

#### POST `/api/auth/olvidaste-contrasena`
Solicita código de recuperación
```json
{
  "correo": "string"
}
```

#### POST `/api/auth/verificar-codigo`
Verifica código de recuperación
```json
{
  "correo": "string",
  "codigo": "string"
}
```

#### POST `/api/auth/cambiar-contrasena`
Cambia contraseña con código verificado
```json
{
  "correo": "string",
  "codigo": "string",
  "nueva_contrasena": "string"
}
```

## 📋 Sistema de Visitas PAE

### Flujo de Trabajo
1. **Asignación**: Supervisor asigna visitas a visitadores
2. **Programación**: Visitas se programan con fechas específicas
3. **Ejecución**: Visitador realiza la visita y completa el checklist
4. **Sincronización**: Sistema sincroniza automáticamente estados

### Endpoints Principales

#### POST `/api/visitas-completas-pae`
Crea una visita completa PAE con checklist
```json
{
  "fecha_visita": "2024-01-15T10:00:00",
  "contrato": "CONTRATO-001",
  "operador": "OPERADOR-ABC",
  "caso_atencion_prioritaria": "SI",
  "municipio_id": 1,
  "institucion_id": 1,
  "sede_id": 1,
  "profesional_id": 1,
  "observaciones": "Observaciones de la visita",
  "respuestas_checklist": [
    {
      "item_id": 1,
      "respuesta": "Cumple",
      "observacion": "Observación específica"
    }
  ]
}
```

#### GET `/api/visitas-completas-pae`
Lista todas las visitas completas

#### GET `/api/visitas-completas-pae/pendientes`
Lista visitas pendientes

#### GET `/api/visitas-completas-pae/{visita_id}/excel`
Genera reporte Excel de una visita específica

#### POST `/api/sincronizar-todas-las-visitas`
Sincroniza todas las visitas del usuario actual

## 🔔 Sistema de Notificaciones Push

### Configuración FCM
```python
# Variables de entorno requeridas
FCM_SERVER_KEY = "tu_server_key"
FCM_PROJECT_ID = "tu_project_id"
NOTIFICACIONES_ENABLED = "true"
```

### Tipos de Notificaciones
- **visita_proxima**: Recordatorio de visita próxima
- **visita_vencida**: Alerta de visita vencida
- **recordatorio**: Recordatorios generales
- **sistema**: Notificaciones del sistema

### Endpoints de Notificaciones

#### POST `/api/notificaciones/registrar-dispositivo`
Registra dispositivo para notificaciones push
```json
{
  "token_dispositivo": "fcm_token",
  "plataforma": "android"
}
```

#### POST `/api/notificaciones/enviar`
Envía notificación push
```json
{
  "titulo": "Título de la notificación",
  "mensaje": "Mensaje de la notificación",
  "tipo": "visita_proxima",
  "prioridad": "alta",
  "usuario_ids": [1, 2, 3]
}
```

## 🛡️ Seguridad

### Rate Limiting
- **Login**: 5 intentos por minuto
- **Registro**: 3 intentos por minuto
- **Recuperación**: 3 intentos por minuto

### Validaciones
- Tokens JWT con expiración
- Verificación de roles en endpoints protegidos
- Validación de datos con Pydantic schemas
- Sanitización de entradas

### CORS
Configuración segura de CORS para dominios específicos:
```python
allowed_origins = ["http://localhost:3000", "http://localhost:8080"]
```

## 📊 Reportes y Exportación

### Generación de Excel
- Plantilla personalizada en `app/templates/plantilla_historial_visitas_checklist.xlsx`
- Incluye información completa de la visita
- Respuestas del checklist organizadas por categorías
- Metadatos de ubicación y profesional

### Endpoints de Reportes
- `/api/reportes/visitas-excel`: Exporta visitas a Excel
- `/api/reportes/visitas-pdf`: Exporta visitas a PDF
- `/api/visitas-completas-pae/{id}/excel`: Reporte individual

## 🔧 Configuración y Despliegue

### Variables de Entorno Requeridas
```env
# Base de datos
DATABASE_URL=postgresql://usuario:password@localhost/visitas_cauca

# JWT
SECRET_KEY=tu_clave_secreta_muy_segura
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7

# Email
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=tu_email@gmail.com
EMAIL_PASSWORD=tu_contraseña_app

# Firebase
FCM_SERVER_KEY=tu_fcm_server_key
FCM_PROJECT_ID=tu_project_id

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

### Instalación
```bash
# Crear entorno virtual
python -m venv venv
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows

# Instalar dependencias
pip install -r requirements.txt

# Ejecutar servidor
cd app
uvicorn main:app --reload
```

### Producción
```bash
# Usar Gunicorn
pip install gunicorn
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker
```

## 🧪 Testing y Debugging

### Endpoints de Prueba
- `/api/test-crear-cronograma`: Crea cronograma sin autenticación
- `/api/test-sincronizacion`: Prueba sincronización de visitas
- `/api/sincronizar-visitas-en-proceso`: Sincroniza visitas en proceso

### Logging
El sistema incluye logging detallado para:
- Operaciones de autenticación
- Creación y sincronización de visitas
- Envío de notificaciones
- Errores y excepciones

## 📈 Monitoreo y Métricas

### Métricas Disponibles
- Número de visitas completadas por usuario
- Tiempo promedio de completado de visitas
- Estadísticas de notificaciones enviadas
- Uso de la API por endpoint

### Health Checks
- `/`: Endpoint de salud básico
- Verificación de conexión a base de datos
- Estado de servicios externos (FCM, Email)

---

Esta documentación cubre los aspectos principales del backend. Para información más específica sobre endpoints individuales, consultar la documentación automática de FastAPI en `/docs` cuando el servidor esté ejecutándose.
