# Sistema de Dashboard de Administración Comprensivo

## Índice
1. [Introducción](#introducción)
2. [Arquitectura del Sistema](#arquitectura-del-sistema)
3. [Módulos Implementados](#módulos-implementados)
4. [Instalación y Configuración](#instalación-y-configuración)
5. [API Endpoints](#api-endpoints)
6. [Frontend Flutter](#frontend-flutter)
7. [Seguridad y Auditoría](#seguridad-y-auditoría)
8. [Guía de Usuario](#guía-de-usuario)

## Introducción

El Sistema de Dashboard de Administración es una plataforma comprensiva diseñada para la gestión integral del sistema de visitas educativas del Cauca. Proporciona un control centralizado de usuarios, checklists, configuraciones y auditoría con funciones avanzadas de seguridad.

### Características Principales

- **Dashboard Ejecutivo**: Vista resumen con KPIs y gráficos en tiempo real
- **Gestión de Usuarios**: CRUD completo con roles y permisos granulares
- **Checklists Versionados**: Sistema de plantillas con control de versiones
- **Auditoría Completa**: Trazabilidad de todas las acciones del sistema
- **Exportaciones Seguras**: Sistema de exportación con 2FA obligatorio
- **Configuración Central**: Gestión de parámetros del sistema
- **Seguridad Reforzada**: 2FA, control de sesiones y políticas de seguridad

## Arquitectura del Sistema

### Backend (FastAPI)

```
app/
├── routes/
│   ├── admin.py              # Endpoints principales de administración
│   └── admin_extended.py     # Endpoints extendidos (checklists, config, etc.)
├── utils/
│   └── admin_auth.py         # Utilidades de autenticación y autorización
├── models.py                 # Modelos de base de datos extendidos
└── scripts/
    └── init_admin_system.py  # Script de inicialización
```

### Frontend (Flutter)

```
frontend_visitas/lib/screens/
├── admin_dashboard_executive.dart     # Dashboard principal
├── admin_user_management.dart         # Gestión de usuarios
└── admin_checklist_management.dart    # Gestión de checklists
```

### Base de Datos

El sistema extiende el modelo existente con nuevas tablas:

- **roles**: Roles del sistema con descripción y estado
- **permisos**: Permisos granulares por módulo
- **roles_permisos**: Relación many-to-many entre roles y permisos
- **usuarios**: Extendido con campos de seguridad y 2FA
- **sesiones_usuario**: Control de sesiones activas
- **auditoria_log**: Log completo de auditoría
- **tipos_visita**: Catálogo de tipos de visita
- **checklist_templates**: Templates versionados de checklists
- **export_jobs**: Cola de trabajos de exportación
- **configuracion_sistema**: Configuración centralizada

## Módulos Implementados

### 1. Inicio (Home) — Resumen Ejecutivo

**Objetivo**: Vista del estado del sistema en 10-30 segundos.

**Funcionalidades**:
- KPIs en tarjetas: usuarios activos, visitadores activos, visitas programadas
- Gráficos de tendencias: visitas por municipio, completadas vs pendientes
- Alertas del sistema: fallos, jobs pendientes, intentos de login fallidos
- Acciones rápidas: crear usuario, programar visitas, exportar datos

**Endpoint**: `GET /api/admin/dashboard/estadisticas`

### 2. Gestión de Usuarios

**Objetivo**: CRUD completo de usuarios con roles y permisos.

**Funcionalidades**:
- Lista con filtros: rol, estado, municipio, fecha de creación
- Crear/editar usuario con validaciones
- Activar/Desactivar (borrado lógico)
- Reset de 2FA con verificación de admin
- Asignación de jurisdicción/sedes
- Historial auditable

**Endpoints**:
- `GET /api/admin/usuarios` - Listar con filtros
- `POST /api/admin/usuarios` - Crear usuario
- `PUT /api/admin/usuarios/{id}` - Actualizar usuario
- `PATCH /api/admin/usuarios/{id}/activar` - Activar usuario
- `PATCH /api/admin/usuarios/{id}/desactivar` - Desactivar usuario
- `POST /api/admin/usuarios/{id}/reset-2fa` - Reset 2FA (requiere 2FA admin)

### 3. Tipos de Visita & Checklists

**Objetivo**: Gestión de plantillas con versionado.

**Funcionalidades**:
- Catálogo de tipos de visita con colores y orden
- Constructor de checklist con items tipados
- Versionado inmutable (v1.0, v1.1, v2.0)
- Publicación con control de versión activa
- Preview/simulación de checklist

**Endpoints**:
- `GET /api/admin/tipos-visita` - Listar tipos
- `POST /api/admin/tipos-visita` - Crear tipo
- `GET /api/admin/checklists` - Listar checklists
- `POST /api/admin/checklists` - Crear checklist
- `POST /api/admin/checklists/{id}/publicar` - Publicar (requiere 2FA)

### 4. Configuración General

**Objetivo**: Parámetros globales del sistema.

**Funcionalidades**:
- Criterios de evaluación y umbrales
- Catálogos: menús, operadores, contratistas
- Indicadores con fórmulas personalizables
- Políticas de seguridad y exportación

**Endpoints**:
- `GET /api/admin/config` - Obtener configuración
- `PUT /api/admin/config` - Actualizar configuración (requiere 2FA)

### 5. Exportaciones Seguras

**Objetivo**: Sistema de exportación con verificación 2FA.

**Funcionalidades**:
- Solicitud de exportación con filtros
- Cola de trabajos con progreso
- Expiración automática de archivos
- Auditoría completa de exportaciones

**Endpoints**:
- `POST /api/admin/exportaciones` - Solicitar exportación (requiere 2FA)
- `GET /api/admin/exportaciones` - Listar exportaciones
- `GET /api/admin/exportaciones/{id}/descargar` - Descargar archivo

### 6. Auditoría & Trazabilidad

**Objetivo**: Control completo de acciones del sistema.

**Funcionalidades**:
- Log de todas las acciones con diff antes/después
- Filtros por usuario, acción, recurso y fechas
- Vista de impacto de cambios
- Exportación de auditoría (solo admins con 2FA)

**Endpoints**:
- `GET /api/admin/auditoria` - Obtener registros de auditoría

### 7. Seguridad Reforzada

**Funcionalidades Implementadas**:
- 2FA TOTP obligatorio para acciones críticas
- Control de sesiones activas
- Políticas de contraseñas y expiración
- Bloqueo automático por intentos fallidos
- Registro de intentos de acceso

## Instalación y Configuración

### 1. Instalación de Dependencias

```bash
# Backend
pip install pyotp qrcode[pil] python-jose cryptography

# Frontend
flutter pub add fl_chart http shared_preferences
```

### 2. Configuración Inicial

```bash
# Ejecutar script de inicialización
cd app/scripts
python init_admin_system.py
```

Este script crea:
- Roles y permisos por defecto
- Usuario administrador inicial
- Configuración del sistema
- Tipos de visita básicos
- Template de checklist PAE

### 3. Credenciales Iniciales

```
Email: admin@educacion.cauca.gov.co
Password: Admin123!
```

**⚠️ IMPORTANTE**: Cambiar contraseña en el primer login.

### 4. Variables de Entorno

```env
SECRET_KEY=tu_clave_secreta_produccion
ADMIN_2FA_REQUIRED=true
MAX_LOGIN_ATTEMPTS=5
SESSION_TIMEOUT_HOURS=8
```

## API Endpoints

### Autenticación y Autorización

Todos los endpoints de admin requieren:
1. Token JWT válido
2. Rol de administrador
3. 2FA habilitado (para acciones críticas)

```python
# Verificación básica de admin
@router.get("/endpoint")
def endpoint(admin: models.Usuario = Depends(verificar_admin)):
    pass

# Verificación con 2FA requerido
@router.post("/endpoint-critico")
def endpoint_critico(admin: models.Usuario = Depends(verificar_admin_con_2fa)):
    pass

# Verificación de permiso específico
@router.get("/endpoint-especifico")
def endpoint_especifico(admin: models.Usuario = Depends(verificar_permiso("usuarios.crear"))):
    pass
```

### Formato de Respuesta

```json
{
  "mensaje": "Operación exitosa",
  "data": { ... },
  "total": 100,
  "pagina_actual": 1,
  "total_paginas": 10
}
```

### Manejo de Errores

```json
{
  "detail": "Mensaje de error descriptivo",
  "error_code": "PERMISSION_DENIED",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

## Frontend Flutter

### Estructura de Pantallas

#### 1. AdminDashboardExecutive

**Características**:
- KPIs en cards con iconos y colores
- Gráficos interactivos con fl_chart
- Acciones rápidas con navegación
- Refresh automático cada 30 segundos

**Widgets Principales**:
- `_buildKPICards()`: Tarjetas de indicadores
- `_buildChartsSection()`: Gráficos de tendencias
- `_buildAlertas()`: Lista de alertas del sistema

#### 2. AdminUserManagement

**Características**:
- TabView: Usuarios, Roles, Auditoría
- Filtros avanzados con chips
- Acciones contextuales por usuario
- Formularios modales para CRUD

**Funcionalidades**:
- Búsqueda en tiempo real
- Filtros por rol, estado, municipio
- Estados visuales (activo/inactivo, 2FA, bloqueado)
- Acciones: editar, activar/desactivar, reset 2FA

#### 3. AdminChecklistManagement

**Características**:
- Gestión de tipos de visita y templates
- Versionado visual de checklists
- Estado de publicación
- Constructor de checklists (en desarrollo)

### Navegación y Ruteo

```dart
// Navegación principal
Navigator.pushNamed(context, '/admin/dashboard');
Navigator.pushNamed(context, '/admin/usuarios');
Navigator.pushNamed(context, '/admin/checklists');
```

### Manejo de Estado

```dart
// Estado local para datos
bool _loading = true;
List<Map<String, dynamic>> _usuarios = [];
String? _error;

// Carga de datos con manejo de errores
Future<void> _cargarDatos() async {
  try {
    setState(() {
      _loading = true;
      _error = null;
    });
    
    // Llamadas a API
    
    setState(() {
      _loading = false;
    });
  } catch (e) {
    setState(() {
      _error = e.toString();
      _loading = false;
    });
  }
}
```

## Seguridad y Auditoría

### Sistema de Roles y Permisos

#### Jerarquía de Roles

1. **Super Administrador**
   - Acceso completo al sistema
   - Configuración de seguridad
   - Gestión de roles y permisos

2. **Administrador**
   - Gestión de usuarios y checklists
   - Exportaciones y reportes
   - Sin acceso a configuración crítica

3. **Supervisor**
   - Gestión de equipo de visitadores
   - Reportes de su jurisdicción
   - Programación de visitas

4. **Visitador**
   - Acceso a checklists asignados
   - Completar visitas
   - Solo lectura en configuración

#### Permisos Granulares

```python
# Ejemplos de permisos
"usuarios.crear"           # Crear usuarios
"usuarios.editar"          # Editar usuarios
"checklists.publicar"      # Publicar checklists (requiere 2FA)
"config.editar"           # Editar configuración (requiere 2FA)
"auditoria.exportar"      # Exportar auditoría (requiere 2FA)
```

### Autenticación de Dos Factores (2FA)

#### Configuración

```python
# Generar secreto TOTP
def generar_2fa_secret(usuario: models.Usuario, db: Session) -> dict:
    secret = pyotp.random_base32()
    totp = pyotp.TOTP(secret)
    
    # Generar QR code
    provisioning_uri = totp.provisioning_uri(
        name=usuario.correo,
        issuer_name="Visitas Educativas Cauca"
    )
    
    return {
        "secret": secret,
        "qr_code": "data:image/png;base64,...",
        "provisioning_uri": provisioning_uri
    }
```

#### Verificación

```python
# Verificar código TOTP
def verificar_2fa_code(usuario: models.Usuario, codigo: str) -> bool:
    if not usuario.twofa_secret:
        return False
    
    totp = pyotp.TOTP(usuario.twofa_secret)
    return totp.verify(codigo)
```

### Auditoría Completa

#### Registro Automático

```python
# Todas las acciones se registran automáticamente
registrar_auditoria(
    db=db,
    actor_id=usuario.id,
    accion="CREATE",
    recurso="Usuario",
    recurso_id=nuevo_usuario.id,
    diff_before=None,
    diff_after={"nombre": "...", "correo": "..."},
    ip_address=obtener_ip_request(request),
    user_agent=request.headers.get("User-Agent")
)
```

#### Campos de Auditoría

- **Actor**: Usuario que realizó la acción
- **Acción**: CREATE, UPDATE, DELETE, LOGIN, EXPORT, etc.
- **Recurso**: Tipo de entidad afectada
- **Diff**: Estado antes y después del cambio
- **Metadata**: IP, User-Agent, timestamp
- **Detalles**: Información adicional contextual

### Control de Sesiones

#### Gestión de Sesiones Activas

```python
# Registrar nueva sesión
def registrar_sesion(usuario, token_jti, ip, user_agent, fecha_exp, db):
    nueva_sesion = models.SesionUsuario(
        usuario_id=usuario.id,
        token_jti=token_jti,
        ip_address=ip,
        user_agent=user_agent,
        fecha_expiracion=fecha_exp
    )
    db.add(nueva_sesion)
    db.commit()

# Cerrar sesiones remotas
def cerrar_todas_sesiones_usuario(usuario_id, motivo, db, excepto_token=None):
    sesiones = db.query(models.SesionUsuario).filter(
        models.SesionUsuario.usuario_id == usuario_id,
        models.SesionUsuario.activa == True
    )
    
    if excepto_token:
        sesiones = sesiones.filter(models.SesionUsuario.token_jti != excepto_token)
    
    for sesion in sesiones:
        sesion.activa = False
        sesion.fecha_cierre = datetime.utcnow()
        sesion.motivo_cierre = motivo
    
    db.commit()
```

## Guía de Usuario

### Primer Acceso al Sistema

1. **Login Inicial**
   - Usar credenciales por defecto
   - Cambiar contraseña obligatoriamente

2. **Configurar 2FA**
   - Ir a Perfil > Seguridad
   - Escanear código QR con app autenticadora
   - Verificar código para activar

3. **Configuración Inicial**
   - Revisar configuración del sistema
   - Crear tipos de visita adicionales
   - Configurar plantillas de checklist

### Uso Diario

#### Dashboard Ejecutivo

1. **Revisar KPIs**
   - Usuarios activos últimos 30 días
   - Visitadores en campo
   - Visitas programadas hoy/semana
   - Porcentaje de cumplimiento

2. **Analizar Gráficos**
   - Tendencias semanales
   - Distribución por municipio
   - Cumplimiento de checklists

3. **Gestionar Alertas**
   - Revisar alertas críticas
   - Atender fallos del sistema
   - Monitorear jobs pendientes

#### Gestión de Usuarios

1. **Crear Usuario**
   - Botón "+" en la esquina
   - Llenar datos obligatorios
   - Asignar rol y jurisdicción
   - Usuario recibe email de bienvenida

2. **Filtrar y Buscar**
   - Usar filtros por rol/estado
   - Búsqueda por nombre/correo
   - Chips de filtros activos

3. **Acciones sobre Usuarios**
   - Editar información básica
   - Activar/Desactivar cuenta
   - Reset 2FA (requiere admin 2FA)
   - Ver historial de acciones

#### Gestión de Checklists

1. **Crear Tipo de Visita**
   - Definir nombre y descripción
   - Asignar color de identificación
   - Establecer orden de prioridad

2. **Diseñar Checklist**
   - Seleccionar tipo de visita
   - Agregar categorías e items
   - Definir tipos de respuesta
   - Especificar evidencias requeridas

3. **Publicar Checklist**
   - Verificar contenido
   - Confirmar con 2FA
   - Solo una versión activa por tipo
   - Versiones anteriores se archivan

#### Exportaciones

1. **Solicitar Exportación**
   - Seleccionar tipo de datos
   - Aplicar filtros necesarios
   - Confirmar con 2FA
   - Job se agrega a cola

2. **Monitorear Progreso**
   - Ver estado en tiempo real
   - Notificación al completar
   - Descarga disponible 7 días

3. **Descargar Archivo**
   - Link seguro con expiración
   - Registro en auditoría
   - Formato Excel/CSV/PDF

### Mantenimiento del Sistema

#### Configuración

1. **Políticas de Seguridad**
   - Intentos máximos de login
   - Duración de bloqueos
   - Expiración de contraseñas
   - Tamaños de archivos

2. **Parámetros Operativos**
   - Tiempos máximos de visita
   - Días de alerta de vencimiento
   - Configuración de notificaciones

#### Auditoría

1. **Revisión Periódica**
   - Filtrar por fechas recientes
   - Buscar acciones sospechosas
   - Verificar accesos de admin

2. **Exportación de Logs**
   - Solo super administradores
   - Requiere 2FA obligatorio
   - Para auditorías externas

#### Respaldo y Seguridad

1. **Gestión de Sesiones**
   - Cerrar sesiones remotas
   - Monitorear IPs sospechosas
   - Forzar logout masivo

2. **Usuarios Comprometidos**
   - Desactivar inmediatamente
   - Reset 2FA forzado
   - Revisar acciones recientes
   - Notificar al usuario

### Solución de Problemas

#### Errores Comunes

1. **"No hay token de autenticación"**
   - Volver a hacer login
   - Verificar conectividad
   - Limpiar caché del navegador

2. **"Acceso denegado: rol no autorizado"**
   - Verificar rol asignado
   - Contactar administrador
   - Verificar permisos específicos

3. **"Esta acción requiere 2FA"**
   - Configurar 2FA en perfil
   - Usar código de aplicación
   - Sincronizar tiempo del dispositivo

#### Contacto y Soporte

- **Administrador del Sistema**: admin@educacion.cauca.gov.co
- **Mesa de Ayuda**: soporte@educacion.cauca.gov.co
- **Emergencias**: +57 XXX XXX XXXX

---

## Conclusión

El Sistema de Dashboard de Administración proporciona una plataforma robusta y segura para la gestión integral del sistema de visitas educativas. Con sus funciones avanzadas de seguridad, auditoría completa y interfaz intuitiva, permite a los administradores mantener control total sobre el sistema mientras aseguran la trazabilidad y el cumplimiento de políticas.

Para más información o soporte técnico, consulte la documentación adicional en la carpeta `docs/` o contacte al equipo de desarrollo.
