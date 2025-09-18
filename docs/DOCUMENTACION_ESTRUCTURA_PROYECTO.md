# 📁 Documentación de Estructura del Proyecto - Sistema PAE Cauca

## 🏗️ Visión General de la Arquitectura

El Sistema PAE Cauca es una aplicación completa compuesta por:

- **Backend**: API REST desarrollada en Python con FastAPI
- **Frontend**: Aplicación móvil multiplataforma desarrollada en Flutter
- **Base de Datos**: PostgreSQL para datos persistentes
- **Notificaciones**: Firebase Cloud Messaging (FCM)
- **Almacenamiento**: Sistema de archivos local para evidencias

## 📂 Estructura Completa del Proyecto

```
App-mobile-sedes-educativas-cauca/
├── 📱 frontend_visitas/                    # Aplicación Flutter
│   ├── lib/                               # Código fuente Dart
│   │   ├── main.dart                      # Punto de entrada
│   │   ├── config.dart                    # Configuración de URLs
│   │   ├── models/                        # Modelos de datos
│   │   │   ├── usuario.dart
│   │   │   ├── institucion.dart
│   │   │   ├── municipio.dart
│   │   │   ├── sede.dart
│   │   │   ├── visita.dart
│   │   │   ├── visita_asignada.dart
│   │   │   ├── visita_programada.dart
│   │   │   ├── checklist_categoria.dart
│   │   │   ├── checklist_item.dart
│   │   │   ├── visita_respuesta.dart
│   │   │   ├── evidencia.dart
│   │   │   ├── evaluacion_item.dart
│   │   │   ├── item_pae.dart
│   │   │   └── rol.dart
│   │   ├── screens/                       # Pantallas de la aplicación
│   │   │   ├── welcome_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   ├── olvidaste_contrasena_screen.dart
│   │   │   ├── admin_dashboard_professional.dart
│   │   │   ├── admin_user_management_enhanced.dart
│   │   │   ├── admin_roles_management.dart
│   │   │   ├── admin_mass_scheduling.dart
│   │   │   ├── admin_exports_management.dart
│   │   │   ├── admin_2fa_settings.dart
│   │   │   ├── admin_analytics_dashboard.dart
│   │   │   ├── admin_notifications_management.dart
│   │   │   ├── admin_checklist_management_enhanced.dart
│   │   │   ├── visitador_dashboard.dart
│   │   │   ├── visitador_home.dart
│   │   │   ├── supervisor_dashboard_real.dart
│   │   │   ├── visitas_equipo_screen.dart
│   │   │   ├── asignar_visitas_screen.dart
│   │   │   ├── reportes_supervisor_screen.dart
│   │   │   ├── alertas_screen.dart
│   │   │   ├── perfil_screen.dart
│   │   │   ├── crear_cronograma_screen.dart
│   │   │   ├── crear_visita_pae_screen.dart
│   │   │   ├── calendario_visitas_screen.dart
│   │   │   ├── cronogramas_guardados_screen.dart
│   │   │   ├── visitas_completas_screen.dart
│   │   │   ├── visitas_pendientes_screen.dart
│   │   │   ├── visitas_asignadas_screen.dart
│   │   │   ├── gestion_sedes_screen.dart
│   │   │   ├── programar_visita_screen.dart
│   │   │   ├── programar_visita_visitador_screen.dart
│   │   │   ├── reportes_screen.dart
│   │   │   ├── gestion_usuarios_screen.dart
│   │   │   ├── todas_visitas_screen.dart
│   │   │   └── actividad_reciente_screen.dart
│   │   ├── services/                      # Servicios de API y datos
│   │   │   ├── api_service.dart           # Servicio principal de API
│   │   │   ├── sync_service.dart          # Servicio de sincronización
│   │   │   ├── notificaciones_push_service.dart
│   │   │   └── evidencias_service.dart
│   │   ├── widgets/                       # Widgets reutilizables
│   │   │   ├── custom_app_bar.dart
│   │   │   ├── custom_button.dart
│   │   │   ├── custom_text_field.dart
│   │   │   ├── loading_widget.dart
│   │   │   └── error_widget.dart
│   │   ├── utils/                         # Utilidades y helpers
│   │   │   ├── database_init.dart         # Inicialización de BD local
│   │   │   ├── responsive_theme.dart      # Tema responsivo
│   │   │   ├── auth_utils.dart           # Utilidades de autenticación
│   │   │   ├── permisos.dart             # Gestión de permisos
│   │   │   ├── platform_compat.dart      # Compatibilidad de plataformas
│   │   │   ├── date_utils.dart           # Utilidades de fechas
│   │   │   └── validation_utils.dart     # Utilidades de validación
│   │   ├── theme/                         # Temas y estilos
│   │   │   ├── app_theme.dart            # Tema principal
│   │   │   └── colors.dart               # Paleta de colores
│   │   ├── providers/                     # Gestión de estado
│   │   │   └── theme_provider.dart       # Provider del tema
│   │   └── local/                         # Configuración local
│   │       └── database_helper.dart      # Helper de base de datos
│   ├── assets/                            # Recursos estáticos
│   │   └── images/                        # Imágenes
│   │       ├── logo_cauca.png
│   │       ├── logo.png
│   │       └── logo_url.txt
│   ├── android/                           # Configuración Android
│   │   ├── app/
│   │   │   ├── build.gradle.kts
│   │   │   └── src/main/
│   │   │       ├── AndroidManifest.xml
│   │   │       ├── kotlin/
│   │   │       └── res/
│   │   ├── build.gradle.kts
│   │   ├── gradle.properties
│   │   ├── settings.gradle.kts
│   │   └── gradlew
│   ├── ios/                               # Configuración iOS
│   │   ├── Runner/
│   │   │   ├── Info.plist
│   │   │   ├── AppDelegate.swift
│   │   │   └── Assets.xcassets
│   │   ├── Runner.xcodeproj/
│   │   └── Runner.xcworkspace/
│   ├── web/                               # Configuración Web
│   │   ├── index.html
│   │   ├── manifest.json
│   │   └── icons/
│   ├── windows/                           # Configuración Windows
│   ├── linux/                             # Configuración Linux
│   ├── macos/                             # Configuración macOS
│   ├── test/                              # Pruebas
│   │   └── widget_test.dart
│   ├── build/                             # Archivos de build
│   ├── pubspec.yaml                       # Dependencias Flutter
│   ├── pubspec.lock                       # Lock de dependencias
│   ├── analysis_options.yaml             # Configuración de análisis
│   ├── devtools_options.yaml             # Configuración de DevTools
│   └── README.md                          # Documentación Flutter
├── 🔧 app/                                # Backend FastAPI
│   ├── main.py                           # Punto de entrada de la API
│   ├── config.py                         # Configuración de la aplicación
│   ├── database.py                       # Configuración de base de datos
│   ├── models.py                         # Modelos SQLAlchemy
│   ├── schemas.py                        # Schemas Pydantic
│   ├── crud.py                           # Operaciones CRUD
│   ├── dependencies.py                   # Dependencias de FastAPI
│   ├── routes/                           # Módulos de rutas API
│   │   ├── __init__.py
│   │   ├── auth.py                       # Autenticación y autorización
│   │   ├── usuarios.py                   # Gestión de usuarios
│   │   ├── municipios.py                 # Gestión de municipios
│   │   ├── instituciones.py              # Gestión de instituciones
│   │   ├── sedes.py                      # Gestión de sedes educativas
│   │   ├── visitas.py                    # Gestión básica de visitas
│   │   ├── visitas_completas.py          # Gestión de visitas PAE completas
│   │   ├── visitas_asignadas.py          # Gestión de visitas asignadas
│   │   ├── visitas_programadas.py        # Gestión de visitas programadas
│   │   ├── items_pae.py                  # Gestión de items PAE
│   │   ├── notificaciones.py             # Sistema de notificaciones
│   │   ├── dashboard.py                  # Dashboard y estadísticas
│   │   ├── reportes.py                   # Generación de reportes
│   │   ├── supervisor.py                 # Funcionalidades de supervisor
│   │   ├── admin.py                      # Funcionalidades de administrador
│   │   ├── admin_basic.py                # Administración básica
│   │   └── admin_extended.py             # Administración extendida
│   ├── services/                         # Servicios de negocio
│   │   ├── __init__.py
│   │   └── notificaciones_service.py     # Servicio de notificaciones
│   ├── utils/                            # Utilidades del backend
│   │   ├── __init__.py
│   │   ├── auth_utils.py                 # Utilidades de autenticación
│   │   ├── admin_auth.py                 # Autenticación de administrador
│   │   └── permisos.py                   # Gestión de permisos
│   ├── scripts/                          # Scripts de utilidad
│   │   └── init_admin_system.py          # Inicialización del sistema admin
│   └── templates/                        # Plantillas
│       └── plantilla_historial_visitas_checklist.xlsx
├── 📚 docs/                              # Documentación del proyecto
│   ├── DOCUMENTACION_COMPLETA_BACKEND.md
│   ├── DOCUMENTACION_COMPLETA_FRONTEND.md
│   ├── DOCUMENTACION_API_ENDPOINTS.md
│   ├── DOCUMENTACION_DESPLIEGUE.md
│   ├── DOCUMENTACION_ESTRUCTURA_PROYECTO.md
│   ├── ADMIN_DASHBOARD_COMPREHENSIVE.md
│   ├── DOCUMENTACION_EVIDENCIAS_MULTIPLES.md
│   ├── DOCUMENTACION_PASO3_SINCRONIZACION_OFFLINE.md
│   ├── DOCUMENTACION_PASO6_NOTIFICACIONES_PUSH.md
│   ├── GUIA_IMPLEMENTACION_RECUPERACION_CONTRASENA.md
│   ├── LIMPIEZA_Y_ORGANIZACION.md
│   ├── SOLUCION_INSTITUCIONES_NO_SALEN.md
│   └── SISTEMA_ADMIN_COMPLETO.md
├── 📧 templates/                         # Plantillas de email
│   └── emails/
│       ├── codigo_recuperacion.html
│       └── confirmacion_contrasena.html
├── 📁 media/                             # Archivos multimedia
│   ├── 2fa/                              # Archivos de 2FA
│   │   ├── 14_backup.txt
│   │   └── 14_secret.txt
│   ├── exports/                          # Archivos exportados
│   │   ├── [25 archivos .xlsx]
│   │   └── [8 archivos .pdf]
│   ├── firmas/                           # Firmas digitales
│   │   ├── 059c24a6-03cc-40d6-9f58-01454d989dee.png
│   │   └── c4620b46-50e7-4773-be47-906014adebd1.png
│   ├── fotos/                            # Fotos de evidencias
│   │   └── 77f734aa-aeea-4ffd-833f-aa9e11b7bf8f.jpeg
│   ├── notifications/                    # Configuración de notificaciones
│   │   ├── 14_config.json
│   │   ├── emails/                       # Templates de email
│   │   │   └── [46 archivos .html]
│   │   └── logs/                         # Logs de notificaciones
│   │       └── [40 archivos .json]
│   └── pdfs/                             # Documentos PDF
│       ├── 35ac72e7-14a6-432f-9d99-62d72766e321.pdf
│       └── 533dbf96-107b-422a-a016-592b25022197.docx
├── 🗄️ Base de Datos
│   ├── visitas_cauca.db                  # Base de datos SQLite (backup)
│   ├── visitas_cauca_backup.sql          # Backup SQL de la base de datos
│   ├── insert_data.sql                   # Script de inserción de datos
│   ├── insert_data_optimized.sql         # Script optimizado de inserción
│   ├── consolidate_institutions.sql      # Script de consolidación
│   └── cleanup_duplicate_tables.sql      # Script de limpieza
├── 🔧 Configuración y Scripts
│   ├── requirements.txt                  # Dependencias Python
│   ├── main.py                           # Script principal (legacy)
│   ├── process_data.py                   # Script de procesamiento de datos
│   ├── email_config.py                   # Configuración de email
│   ├── env_example.txt                   # Ejemplo de variables de entorno
│   ├── SECURITY_IMPLEMENTATION.md        # Documentación de seguridad
│   ├── SISTEMA_ADMIN_COMPLETO.md         # Documentación del sistema admin
│   └── venv/                             # Entorno virtual Python
│       ├── Include/
│       ├── Lib/
│       ├── Scripts/
│       └── pyvenv.cfg
└── 📖 README.md                          # Documentación principal del proyecto
```

## 🔍 Descripción Detallada de Componentes

### **Frontend Flutter (`frontend_visitas/`)**

#### **Estructura de Pantallas por Rol**

**🔐 Autenticación:**
- `welcome_screen.dart`: Pantalla de bienvenida
- `login_screen.dart`: Formulario de login
- `register_screen.dart`: Formulario de registro
- `olvidaste_contrasena_screen.dart`: Recuperación de contraseña

**👑 Administrador:**
- `admin_dashboard_professional.dart`: Dashboard principal
- `admin_user_management_enhanced.dart`: Gestión de usuarios
- `admin_roles_management.dart`: Gestión de roles
- `admin_mass_scheduling.dart`: Programación masiva
- `admin_exports_management.dart`: Gestión de exportaciones
- `admin_2fa_settings.dart`: Configuración 2FA
- `admin_analytics_dashboard.dart`: Analytics y métricas
- `admin_notifications_management.dart`: Gestión de notificaciones
- `admin_checklist_management_enhanced.dart`: Gestión de checklists

**👨‍💼 Supervisor:**
- `supervisor_dashboard_real.dart`: Dashboard de supervisor
- `visitas_equipo_screen.dart`: Visitas del equipo
- `asignar_visitas_screen.dart`: Asignación de visitas
- `reportes_supervisor_screen.dart`: Reportes del supervisor
- `alertas_screen.dart`: Gestión de alertas

**👨‍🔬 Visitador:**
- `visitador_dashboard.dart`: Dashboard de visitador
- `visitador_home.dart`: Pantalla principal
- `crear_cronograma_screen.dart`: Creación de cronogramas
- `crear_visita_pae_screen.dart`: Formulario de visita PAE
- `calendario_visitas_screen.dart`: Vista de calendario
- `visitas_asignadas_screen.dart`: Visitas asignadas
- `visitas_completas_screen.dart`: Visitas completadas
- `visitas_pendientes_screen.dart`: Visitas pendientes

**📊 Reportes y Gestión:**
- `reportes_screen.dart`: Generación de reportes
- `gestion_sedes_screen.dart`: Gestión de sedes
- `gestion_usuarios_screen.dart`: Gestión de usuarios
- `programar_visita_screen.dart`: Programación de visitas
- `programar_visita_visitador_screen.dart`: Programación para visitadores
- `cronogramas_guardados_screen.dart`: Cronogramas guardados
- `todas_visitas_screen.dart`: Todas las visitas
- `actividad_reciente_screen.dart`: Actividad reciente

#### **Servicios (`services/`)**

**`api_service.dart`**: Servicio principal de comunicación con el backend
- Autenticación y gestión de tokens
- CRUD de todas las entidades
- Sincronización de datos
- Manejo de errores y reintentos

**`sync_service.dart`**: Servicio de sincronización offline/online
- Sincronización automática
- Resolución de conflictos
- Gestión de estado de sincronización

**`notificaciones_push_service.dart`**: Servicio de notificaciones push
- Registro de dispositivos FCM
- Envío de notificaciones locales
- Configuración de notificaciones programadas

**`evidencias_service.dart`**: Servicio de gestión de evidencias
- Captura de fotos y videos
- Grabación de audio
- Captura de firmas
- Selección de archivos

#### **Modelos (`models/`)**

Cada modelo representa una entidad del sistema:
- **`usuario.dart`**: Información de usuarios
- **`institucion.dart`**: Instituciones educativas
- **`municipio.dart`**: Municipios del Cauca
- **`sede.dart`**: Sedes educativas
- **`visita.dart`**: Visitas básicas
- **`visita_asignada.dart`**: Visitas asignadas
- **`visita_programada.dart`**: Visitas programadas
- **`checklist_categoria.dart`**: Categorías del checklist
- **`checklist_item.dart`**: Items del checklist
- **`visita_respuesta.dart`**: Respuestas del checklist
- **`evidencia.dart`**: Evidencias multimedia
- **`evaluacion_item.dart`**: Items de evaluación
- **`item_pae.dart`**: Items específicos PAE
- **`rol.dart`**: Roles de usuario

### **Backend FastAPI (`app/`)**

#### **Estructura de Rutas (`routes/`)**

**`auth.py`**: Sistema de autenticación completo
- Login/logout con JWT
- Registro de usuarios
- Recuperación de contraseña
- Renovación de tokens
- Gestión de roles

**`usuarios.py`**: Gestión de usuarios
- CRUD de usuarios
- Gestión de perfiles
- Asignación de roles

**`municipios.py`**: Gestión de municipios
- Listado de municipios
- Búsqueda y filtrado

**`instituciones.py`**: Gestión de instituciones
- CRUD de instituciones
- Filtrado por municipio
- Validación de datos

**`sedes.py`**: Gestión de sedes educativas
- CRUD de sedes
- Filtrado por institución
- Validación de coordenadas GPS

**`visitas_completas.py`**: Gestión de visitas PAE
- Creación de visitas completas
- Gestión de checklist
- Sincronización automática
- Generación de reportes Excel

**`visitas_asignadas.py`**: Gestión de visitas asignadas
- Asignación de visitas
- Seguimiento de estados
- Sincronización con visitas completas

**`notificaciones.py`**: Sistema de notificaciones
- Registro de dispositivos FCM
- Envío de notificaciones push
- Gestión de notificaciones locales

**`dashboard.py`**: Dashboard y estadísticas
- Métricas generales
- Estadísticas por usuario
- Datos para gráficos

**`reportes.py`**: Generación de reportes
- Exportación a Excel
- Exportación a PDF
- Filtros avanzados

#### **Modelos (`models.py`)**

**Modelos de Autenticación:**
- `Rol`: Roles del sistema
- `Usuario`: Usuarios del sistema
- `CodigoRecuperacion`: Códigos de recuperación

**Modelos de Estructura Educativa:**
- `Municipio`: Municipios del Cauca
- `Institucion`: Instituciones educativas
- `SedeEducativa`: Sedes educativas

**Modelos de Visitas:**
- `VisitaAsignada`: Visitas asignadas por supervisores
- `VisitaProgramada`: Visitas programadas automáticamente
- `VisitaCompletaPAE`: Visitas completas con checklist
- `VisitaRespuestaCompleta`: Respuestas del checklist

**Modelos de Checklist:**
- `ChecklistCategoria`: Categorías del checklist
- `ChecklistItem`: Items específicos del checklist

**Modelos de Notificaciones:**
- `DispositivoNotificacion`: Dispositivos registrados para FCM
- `Notificacion`: Notificaciones del sistema

**Modelos de Reportes:**
- `Reporte`: Historial de reportes generados

#### **Schemas (`schemas.py`)**

Schemas Pydantic para validación y serialización:
- Schemas de entrada (Create)
- Schemas de salida (Out)
- Schemas de actualización (Update)
- Schemas de validación específicos

### **Base de Datos**

#### **PostgreSQL (Producción)**
- Base de datos principal
- Configuración optimizada para producción
- Backups automáticos
- Replicación (opcional)

#### **SQLite (Desarrollo/Backup)**
- Base de datos local para desarrollo
- Backup de respaldo
- Sincronización con PostgreSQL

### **Archivos de Configuración**

#### **`requirements.txt`**
Dependencias Python del backend:
- FastAPI
- SQLAlchemy
- PostgreSQL driver
- JWT handling
- Email support
- Excel generation

#### **`pubspec.yaml`**
Dependencias Flutter del frontend:
- HTTP client
- Local storage
- Image picker
- JWT decoder
- Secure storage
- SQLite
- Connectivity
- Geolocator
- Firebase
- Notifications
- Signature capture
- Charts

### **Documentación (`docs/`)**

#### **Documentación Técnica:**
- `DOCUMENTACION_COMPLETA_BACKEND.md`: Backend completo
- `DOCUMENTACION_COMPLETA_FRONTEND.md`: Frontend completo
- `DOCUMENTACION_API_ENDPOINTS.md`: API endpoints
- `DOCUMENTACION_DESPLIEGUE.md`: Guía de despliegue
- `DOCUMENTACION_ESTRUCTURA_PROYECTO.md`: Esta documentación

#### **Documentación de Funcionalidades:**
- `ADMIN_DASHBOARD_COMPREHENSIVE.md`: Dashboard administrativo
- `DOCUMENTACION_EVIDENCIAS_MULTIPLES.md`: Sistema de evidencias
- `DOCUMENTACION_PASO3_SINCRONIZACION_OFFLINE.md`: Sincronización offline
- `DOCUMENTACION_PASO6_NOTIFICACIONES_PUSH.md`: Notificaciones push
- `GUIA_IMPLEMENTACION_RECUPERACION_CONTRASENA.md`: Recuperación de contraseña
- `SOLUCION_INSTITUCIONES_NO_SALEN.md`: Solución de problemas
- `SISTEMA_ADMIN_COMPLETO.md`: Sistema administrativo

### **Archivos Multimedia (`media/`)**

#### **Estructura de Evidencias:**
- `fotos/`: Fotos de evidencias de visitas
- `firmas/`: Firmas digitales capturadas
- `pdfs/`: Documentos PDF generados
- `exports/`: Archivos exportados (Excel, PDF)

#### **Configuración:**
- `2fa/`: Archivos de autenticación de dos factores
- `notifications/`: Configuración y logs de notificaciones

### **Scripts y Utilidades**

#### **Scripts de Base de Datos:**
- `insert_data.sql`: Inserción inicial de datos
- `insert_data_optimized.sql`: Versión optimizada
- `consolidate_institutions.sql`: Consolidación de instituciones
- `cleanup_duplicate_tables.sql`: Limpieza de duplicados

#### **Scripts de Procesamiento:**
- `process_data.py`: Procesamiento de datos
- `main.py`: Script principal (legacy)

## 🔄 Flujo de Datos

### **1. Autenticación**
```
Usuario → Frontend → API Auth → JWT Token → Almacenamiento Seguro
```

### **2. Sincronización de Datos**
```
Frontend (SQLite) ↔ API Backend ↔ PostgreSQL
```

### **3. Creación de Visitas**
```
Visitador → Formulario → Validación → API → Base de Datos → Sincronización
```

### **4. Notificaciones**
```
Sistema → FCM → Dispositivo → Notificación Local
```

## 🛡️ Consideraciones de Seguridad

### **Frontend:**
- Almacenamiento seguro de tokens
- Validación de datos de entrada
- Cifrado de datos sensibles
- Gestión segura de permisos

### **Backend:**
- Autenticación JWT
- Rate limiting
- Validación de schemas
- CORS configurado
- Logs de seguridad

### **Base de Datos:**
- Conexiones cifradas
- Usuarios con permisos mínimos
- Backups encriptados
- Auditoría de cambios

## 📈 Escalabilidad

### **Frontend:**
- Arquitectura modular
- Lazy loading
- Caching eficiente
- Sincronización optimizada

### **Backend:**
- API REST stateless
- Base de datos optimizada
- Caching de consultas
- Load balancing ready

### **Base de Datos:**
- Índices optimizados
- Particionado por fechas
- Replicación de lectura
- Archiving de datos antiguos

---

Esta estructura del proyecto proporciona una base sólida para el desarrollo, mantenimiento y escalabilidad del Sistema PAE Cauca. Cada componente está claramente definido y documentado para facilitar la colaboración del equipo de desarrollo.
