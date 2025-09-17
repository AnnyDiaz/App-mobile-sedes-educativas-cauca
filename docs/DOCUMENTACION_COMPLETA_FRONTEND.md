# 📱 Documentación Completa del Frontend - Sistema PAE Cauca

## 🏗️ Arquitectura General

El frontend está construido con **Flutter** y utiliza una arquitectura modular con los siguientes componentes principales:

### Estructura de Directorios
```
frontend_visitas/
├── lib/
│   ├── main.dart                    # Punto de entrada de la aplicación
│   ├── config.dart                  # Configuración de URLs y constantes
│   ├── models/                      # Modelos de datos
│   │   ├── usuario.dart
│   │   ├── institucion.dart
│   │   ├── municipio.dart
│   │   ├── sede.dart
│   │   ├── visita.dart
│   │   └── ...
│   ├── screens/                     # Pantallas de la aplicación
│   │   ├── welcome_screen.dart
│   │   ├── login_screen.dart
│   │   ├── admin_dashboard_professional.dart
│   │   ├── visitador_dashboard.dart
│   │   ├── supervisor_dashboard_real.dart
│   │   └── ...
│   ├── services/                    # Servicios de API y datos
│   │   ├── api_service.dart
│   │   ├── sync_service.dart
│   │   ├── notificaciones_push_service.dart
│   │   └── evidencias_service.dart
│   ├── widgets/                     # Widgets reutilizables
│   ├── utils/                       # Utilidades y helpers
│   ├── theme/                       # Temas y estilos
│   └── providers/                   # Gestión de estado
├── assets/                          # Recursos estáticos
├── android/                         # Configuración Android
├── ios/                            # Configuración iOS
└── pubspec.yaml                    # Dependencias del proyecto
```

## 🎯 Funcionalidades Principales

### 1. **Sistema de Autenticación**
- Login con email y contraseña
- Registro de nuevos usuarios
- Recuperación de contraseña con código de verificación
- Gestión de tokens JWT (access + refresh)
- Almacenamiento seguro de credenciales

### 2. **Dashboard por Roles**

#### **Administrador**
- Gestión completa de usuarios
- Administración de roles y permisos
- Programación masiva de visitas
- Gestión de checklists
- Exportación de reportes
- Configuración de notificaciones
- Analytics y métricas

#### **Supervisor**
- Asignación de visitas a visitadores
- Seguimiento del equipo
- Generación de reportes
- Gestión de alertas
- Programación de visitas

#### **Visitador**
- Visualización de visitas asignadas
- Creación de cronogramas PAE
- Completado de checklists
- Captura de evidencias (fotos, GPS, firmas)
- Sincronización offline/online

### 3. **Gestión de Visitas PAE**

#### **Creación de Cronogramas**
- Selección de municipio, institución y sede
- Configuración de contrato y operador
- Programación de fechas
- Asignación de casos de atención prioritaria

#### **Checklist Dinámico**
- Categorías organizadas por temas
- Preguntas específicas por categoría
- Respuestas: Cumple/No Cumple/N/A
- Observaciones detalladas
- Captura de evidencias multimedia

#### **Sincronización Offline**
- Base de datos local SQLite
- Sincronización automática cuando hay conexión
- Gestión de conflictos de datos
- Indicadores de estado de sincronización

### 4. **Sistema de Notificaciones Push**
- Registro de dispositivos FCM
- Notificaciones de visitas próximas
- Alertas de visitas vencidas
- Recordatorios personalizados
- Gestión de prioridades

## 📱 Pantallas Principales

### **Pantallas de Autenticación**
- `welcome_screen.dart`: Pantalla de bienvenida
- `login_screen.dart`: Login de usuarios
- `register_screen.dart`: Registro de nuevos usuarios
- `olvidaste_contrasena_screen.dart`: Recuperación de contraseña

### **Dashboards por Rol**
- `admin_dashboard_professional.dart`: Dashboard administrativo completo
- `visitador_dashboard.dart`: Dashboard para visitadores
- `supervisor_dashboard_real.dart`: Dashboard para supervisores

### **Gestión de Visitas**
- `crear_cronograma_screen.dart`: Creación de cronogramas PAE
- `crear_visita_pae_screen.dart`: Formulario de visita PAE
- `calendario_visitas_screen.dart`: Vista de calendario
- `visitas_asignadas_screen.dart`: Lista de visitas asignadas
- `visitas_completas_screen.dart`: Historial de visitas completadas
- `visitas_pendientes_screen.dart`: Visitas pendientes

### **Administración**
- `admin_user_management_enhanced.dart`: Gestión de usuarios
- `admin_roles_management.dart`: Gestión de roles
- `admin_mass_scheduling.dart`: Programación masiva
- `admin_exports_management.dart`: Gestión de exportaciones
- `admin_notifications_management.dart`: Gestión de notificaciones
- `admin_checklist_management_enhanced.dart`: Gestión de checklists

## 🔧 Servicios y APIs

### **ApiService** (`services/api_service.dart`)
Servicio principal para comunicación con el backend:

#### **Autenticación**
```dart
Future<Map<String, dynamic>> login(String email, String password)
Future<Map<String, dynamic>> register(Map<String, dynamic> userData)
Future<bool> refreshAccessToken()
Future<void> logout()
Future<bool> isAuthenticated()
```

#### **Gestión de Datos**
```dart
Future<List<Municipio>> getMunicipios()
Future<List<Institucion>> getInstituciones(int municipioId)
Future<List<Sede>> getSedes(int institucionId)
Future<List<VisitaAsignada>> getVisitasAsignadas()
Future<Map<String, dynamic>> crearVisitaCompleta(Map<String, dynamic> data)
```

#### **Sincronización**
```dart
Future<void> sincronizarVisitas()
Future<void> sincronizarVisitasEnProceso()
Future<Map<String, dynamic>> sincronizarTodasLasVisitas()
```

### **SyncService** (`services/sync_service.dart`)
Maneja la sincronización offline/online:

```dart
Future<void> sincronizarDatos()
Future<void> sincronizarVisitasPendientes()
Future<void> sincronizarVisitasCompletadas()
Future<bool> hayDatosPendientes()
```

### **NotificacionesPushService** (`services/notificaciones_push_service.dart`)
Gestiona las notificaciones push:

```dart
Future<void> inicializarNotificaciones()
Future<void> registrarDispositivo(String token)
Future<void> enviarNotificacionLocal(String titulo, String mensaje)
Future<void> configurarNotificacionesProgramadas()
```

### **EvidenciasService** (`services/evidencias_service.dart`)
Maneja la captura y gestión de evidencias:

```dart
Future<String?> capturarFoto()
Future<String?> capturarVideo()
Future<String?> grabarAudio()
Future<String?> seleccionarArchivo()
Future<String?> capturarFirma()
```

## 🗄️ Base de Datos Local

### **SQLite Local**
La aplicación utiliza SQLite para almacenamiento local:

```dart
// Tablas principales
- usuarios
- municipios
- instituciones
- sedes
- visitas_asignadas
- visitas_completas
- checklist_items
- notificaciones
```

### **Sincronización**
- **Offline First**: La app funciona sin conexión
- **Sincronización Automática**: Cuando detecta conexión
- **Resolución de Conflictos**: Prioriza datos del servidor
- **Indicadores Visuales**: Estado de sincronización visible

## 🎨 Temas y Estilos

### **AppTheme** (`theme/app_theme.dart`)
Sistema de temas con soporte para modo oscuro:

```dart
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    // ... configuración del tema claro
  );
  
  static ThemeData darkTheme = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.dark,
    // ... configuración del tema oscuro
  );
}
```

### **ThemeProvider** (`providers/theme_provider.dart`)
Gestión de estado del tema:

```dart
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
```

## 📱 Configuración por Plataforma

### **Android** (`android/`)
- Configuración de permisos
- Configuración de FCM
- Iconos y splash screens
- Configuración de Gradle

### **iOS** (`ios/`)
- Configuración de Info.plist
- Configuración de FCM
- Iconos y splash screens
- Configuración de Xcode

### **Web** (`web/`)
- Configuración de index.html
- PWA support
- Configuración de manifest.json

## 🔐 Seguridad

### **Almacenamiento Seguro**
```dart
// Flutter Secure Storage para tokens
static const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
);
```

### **Validación de Tokens**
- Verificación automática de expiración
- Renovación automática de tokens
- Logout automático en caso de error

### **Permisos**
- Cámara para captura de fotos
- Micrófono para grabación de audio
- Ubicación para GPS
- Almacenamiento para archivos

## 📊 Gestión de Estado

### **Provider Pattern**
La aplicación utiliza Provider para gestión de estado:

```dart
ChangeNotifierProvider(
  create: (context) => ThemeProvider(),
  child: Consumer<ThemeProvider>(
    builder: (context, themeProvider, child) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeProvider.themeMode,
        // ...
      );
    },
  ),
)
```

### **Estado Local**
- SharedPreferences para configuraciones
- FlutterSecureStorage para datos sensibles
- SQLite para datos de aplicación

## 🚀 Despliegue

### **Configuración de URLs**
```dart
// lib/config.dart
const String baseUrl = 'http://192.168.1.83:8000';  // Desarrollo
// const String baseUrl = 'https://tu-servidor.com';  // Producción
```

### **Build para Producción**

#### **Android APK**
```bash
flutter build apk --release
```

#### **iOS**
```bash
flutter build ios --release
```

#### **Web**
```bash
flutter build web
```

#### **Windows**
```bash
flutter build windows
```

### **Variables de Entorno**
- Configuración de URLs de API
- Configuración de FCM
- Configuración de base de datos local

## 🧪 Testing

### **Widget Testing**
```dart
// test/widget_test.dart
testWidgets('Counter increments smoke test', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  // ... pruebas de widgets
});
```

### **Unit Testing**
- Pruebas de servicios
- Pruebas de modelos
- Pruebas de utilidades

## 📈 Performance

### **Optimizaciones**
- Lazy loading de pantallas
- Caching de datos
- Compresión de imágenes
- Sincronización eficiente

### **Monitoreo**
- Logging de errores
- Métricas de performance
- Tracking de uso

## 🔧 Configuración de Desarrollo

### **Dependencias Principales**
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.5.0
  shared_preferences: ^2.2.2
  image_picker: ^1.0.4
  jwt_decoder: ^2.0.1
  flutter_secure_storage: ^9.0.0
  sqflite: ^2.3.0
  connectivity_plus: ^6.1.4
  geolocator: ^10.1.0
  firebase_core: ^4.0.0
  firebase_messaging: ^16.0.0
  flutter_local_notifications: ^19.4.0
  signature: ^5.4.0
  provider: ^6.1.1
```

### **Comandos de Desarrollo**
```bash
# Instalar dependencias
flutter pub get

# Ejecutar en modo debug
flutter run

# Ejecutar en modo release
flutter run --release

# Limpiar proyecto
flutter clean
```

---

Esta documentación cubre los aspectos principales del frontend Flutter. Para información más específica sobre implementación de pantallas individuales o servicios, consultar el código fuente correspondiente.
