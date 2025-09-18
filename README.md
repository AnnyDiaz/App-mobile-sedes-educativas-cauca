# 🏫 **Aplicación de Visitas PAE - Sedes Educativas del Cauca**

## 📱 **Descripción General**

Aplicación móvil completa para la gestión de visitas PAE (Programa de Alimentación Escolar) en las sedes educativas del departamento del Cauca. Permite a visitadores y supervisores crear, gestionar y sincronizar visitas con funcionalidades offline.

## 🏗️ **Arquitectura del Sistema**

### **Backend (FastAPI)**
- **Ubicación**: `app/`
- **Base de datos**: PostgreSQL
- **API REST**: Endpoints para gestión de visitas, instituciones, usuarios y notificaciones
- **Autenticación**: JWT con roles de usuario

### **Frontend (Flutter)**
- **Ubicación**: `frontend_visitas/`
- **Plataformas**: Android, iOS, Web, Windows, macOS, Linux
- **Base de datos local**: SQLite para sincronización offline
- **Notificaciones**: Firebase Cloud Messaging (FCM)

## 🚀 **Funcionalidades Principales**

### **Gestión de Visitas**
- ✅ Crear cronogramas de visitas PAE
- ✅ Checklist completo con evidencias
- ✅ Captura de GPS y fotos
- ✅ Sincronización offline/online
- ✅ Historial de visitas

### **Gestión de Ubicaciones**
- ✅ 42 municipios del Cauca
- ✅ 453 instituciones educativas
- ✅ Sedes por institución
- ✅ Validación de datos

### **Sistema de Usuarios**
- ✅ Roles: Visitador, Supervisor, Administrador
- ✅ Autenticación JWT
- ✅ Gestión de perfiles
- ✅ Recuperación de contraseñas

### **Notificaciones Push**
- ✅ Recordatorios de visitas
- ✅ Notificaciones en tiempo real
- ✅ Gestión de dispositivos
- ✅ Prioridades y estados

## 📁 **Estructura del Proyecto**

```
App-mobile-sedes-educativas-cauca/
├── 📱 frontend_visitas/          # Aplicación Flutter
├── 🔧 app/                      # Backend FastAPI
├── 📚 docs/                     # Documentación
├── 📧 templates/                # Plantillas de email
├── 📁 media/                    # Archivos multimedia
├── 📋 requirements.txt          # Dependencias Python
└── 📖 README.md                 # Este archivo
```

## 🛠️ **Instalación y Configuración**

### **Backend**
```bash
# Crear entorno virtual
python -m venv venv
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows

# Instalar dependencias
pip install -r requirements.txt

# Configurar variables de entorno
cp env_example.txt .env
# Editar .env con tus configuraciones

# Ejecutar servidor
cd app
uvicorn main:app --reload
```

### **Frontend**
```bash
cd frontend_visitas

# Instalar dependencias
flutter pub get

# Configurar URL del backend
# Editar lib/config.dart

# Ejecutar aplicación
flutter run
```

## 🔧 **Configuración del Backend**

### **Variables de Entorno Requeridas**
```env
# Base de datos
DATABASE_URL=postgresql://usuario:contraseña@localhost/visitas_cauca

# JWT
SECRET_KEY=tu_clave_secreta_aqui
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Email (opcional)
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=tu_email@gmail.com
SMTP_PASSWORD=tu_contraseña_app

# Firebase (opcional)
FIREBASE_CREDENTIALS_PATH=path/to/firebase-credentials.json
```

## 📱 **Configuración del Frontend**

### **URL del Backend**
```dart
// lib/config.dart

// 🏠 DESARROLLO LOCAL (Emulador Android)
const String baseUrl = 'http://10.0.2.2:8000';

// 🖥️ DESARROLLO LOCAL (Dispositivo real)
const String baseUrl = 'http://TU_IP_LOCAL:8000';

// 🌐 PRODUCCIÓN
const String baseUrl = 'https://tu-servidor.com';
```

## 🗄️ **Base de Datos**

### **Tablas Principales**
- **usuarios**: Gestión de usuarios y roles
- **municipios**: 42 municipios del Cauca
- **instituciones**: 453 instituciones educativas
- **sedes_educativas**: Sedes por institución
- **visitas_completas_pae**: Visitas realizadas
- **checklist_items**: Items del checklist PAE
- **evidencias**: Archivos multimedia de las visitas

## 📚 **Documentación**

### **Guías de Implementación**
- [Solución: Instituciones no aparecen en el frontend](docs/SOLUCION_INSTITUCIONES_NO_SALEN.md)
- [Sincronización Offline](docs/DOCUMENTACION_PASO3_SINCRONIZACION_OFFLINE.md)
- [Notificaciones Push](docs/DOCUMENTACION_PASO6_NOTIFICACIONES_PUSH.md)
- [Recuperación de Contraseñas](docs/GUIA_IMPLEMENTACION_RECUPERACION_CONTRASENA.md)

## 🚀 **Despliegue**

### **Backend en Producción**
```bash
# Usar Gunicorn para producción
pip install gunicorn
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker
```

### **Frontend en Producción**
```bash
# Generar APK para Android
flutter build apk --release

# Generar para Web
flutter build web

# Generar para Windows
flutter build windows
```

## 🤝 **Contribución**

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 **Licencia**

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 📞 **Contacto**

- **Desarrollador**: Equipo de Desarrollo
- **Proyecto**: Visitas PAE - Sedes Educativas del Cauca
- **Año**: 2024

---

## 🎯 **Estado del Proyecto**

- ✅ **Backend**: Completamente funcional
- ✅ **Frontend**: Completamente funcional
- ✅ **Base de datos**: Configurada y poblada
- ✅ **Sincronización offline**: Implementada
- ✅ **Notificaciones push**: Implementadas
- ✅ **Autenticación**: Implementada
- ✅ **Documentación**: Completa

**La aplicación está lista para uso en producción.** 🚀
