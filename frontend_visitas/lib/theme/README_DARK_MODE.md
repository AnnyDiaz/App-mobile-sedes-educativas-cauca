# 🌙 Implementación de Modo Oscuro

Este documento explica cómo implementar y usar el modo oscuro en toda la aplicación SMC VS.

## 📁 Estructura de Archivos

```
lib/
├── theme/
│   ├── app_theme.dart              # Definición de temas claro y oscuro
│   └── README_DARK_MODE.md        # Este archivo
├── providers/
│   └── theme_provider.dart         # Provider para manejar el estado del tema
└── widgets/
    └── theme_toggle_button.dart    # Widgets reutilizables para temas
```

## 🚀 Implementación Básica

### 1. Envolver la App con ThemeProvider

```dart
// main.dart
import 'package:provider/provider.dart';
import 'package:frontend_visitas/providers/theme_provider.dart';
import 'package:frontend_visitas/theme/app_theme.dart';

class SMCApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            // ... resto de la configuración
          );
        },
      ),
    );
  }
}
```

### 2. Usar Consumer en Pantallas

```dart
// Cualquier pantalla
import 'package:provider/provider.dart';
import 'package:frontend_visitas/providers/theme_provider.dart';
import 'package:frontend_visitas/theme/app_theme.dart';

class MiPantalla extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDark;
        final roleColor = AppTheme.getRoleColor('admin', isDark); // Cambiar según el rol
        
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: AppBar(
            backgroundColor: roleColor,
            // ... resto de la configuración
          ),
          // ... resto del contenido
        );
      },
    );
  }
}
```

## 🎨 Colores del Tema

### Colores por Rol

```dart
// Obtener color específico del rol
final roleColor = AppTheme.getRoleColor('admin', isDark);      // Púrpura
final roleColor = AppTheme.getRoleColor('supervisor', isDark);  // Índigo
final roleColor = AppTheme.getRoleColor('visitador', isDark);   // Verde azulado
final roleColor = AppTheme.getRoleColor('visitante', isDark);   // Naranja
```

### Colores de Estado

```dart
// Obtener color según el estado
final statusColor = AppTheme.getStatusColor('success', isDark);   // Verde
final statusColor = AppTheme.getStatusColor('warning', isDark);   // Naranja
final statusColor = AppTheme.getStatusColor('error', isDark);     // Rojo
final statusColor = AppTheme.getStatusColor('info', isDark);      // Azul
```

### Colores de Fondo

```dart
// Obtener colores de fondo
final cardColor = AppTheme.getCardBackgroundColor(isDark);
final surfaceColor = AppTheme.getSurfaceColor(isDark);
final textColor = AppTheme.getTextColor(isDark);
final secondaryTextColor = AppTheme.getTextColor(isDark, isPrimary: false);
```

## 🔧 Widgets Reutilizables

### ThemeToggleButton

```dart
// Botón simple para alternar tema
ThemeToggleButton(
  tooltip: 'Cambiar tema',
  backgroundColor: Colors.blue,
  foregroundColor: Colors.white,
)
```

### ThemeModeSelector

```dart
// Selector completo de modo de tema
ThemeModeSelector(
  showLabel: true,  // Mostrar texto junto a iconos
)
```

### ThemeAwareContainer

```dart
// Container que se adapta al tema
ThemeAwareContainer(
  lightColor: Colors.grey.shade100,
  darkColor: Colors.grey.shade800,
  padding: EdgeInsets.all(16),
  child: Text('Contenido'),
)
```

## 📱 Ejemplos por Rol

### Admin Dashboard

```dart
@override
Widget build(BuildContext context) {
  return Consumer<ThemeProvider>(
    builder: (context, themeProvider, child) {
      final isDark = themeProvider.isDark;
      final roleColor = AppTheme.getRoleColor('admin', isDark);
      
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          backgroundColor: roleColor,
          foregroundColor: Colors.white,
          actions: [
            // Botón de cambio de tema
            IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => themeProvider.toggleTheme(),
              tooltip: isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
            ),
            // ... otros botones
          ],
        ),
        // ... resto del contenido
      );
    },
  );
}
```

### Supervisor Dashboard

```dart
@override
Widget build(BuildContext context) {
  return Consumer<ThemeProvider>(
    builder: (context, themeProvider, child) {
      final isDark = themeProvider.isDark;
      final roleColor = AppTheme.getRoleColor('supervisor', isDark);
      
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          backgroundColor: roleColor,
          foregroundColor: Colors.white,
          actions: [
            // Botón de cambio de tema
            IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => themeProvider.toggleTheme(),
              tooltip: isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
            ),
            // ... otros botones
          ],
        ),
        // ... resto del contenido
      );
    },
  );
}
```

### Visitador Dashboard

```dart
@override
Widget build(BuildContext context) {
  return Consumer<ThemeProvider>(
    builder: (context, themeProvider, child) {
      final isDark = themeProvider.isDark;
      final roleColor = AppTheme.getRoleColor('visitador', isDark);
      
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          backgroundColor: roleColor,
          foregroundColor: Colors.white,
          actions: [
            // Botón de cambio de tema
            IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => themeProvider.toggleTheme(),
              tooltip: isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
            ),
            // ... otros botones
          ],
        ),
        // ... resto del contenido
      );
    },
  );
}
```

## 🎯 Mejores Prácticas

### 1. Siempre usar Consumer<ThemeProvider>

```dart
// ✅ Correcto
return Consumer<ThemeProvider>(
  builder: (context, themeProvider, child) {
    final isDark = themeProvider.isDark;
    // ... usar isDark
  },
);

// ❌ Incorrecto
final isDark = context.read<ThemeProvider>().isDark;
```

### 2. Usar colores del tema en lugar de colores hardcodeados

```dart
// ✅ Correcto
backgroundColor: Theme.of(context).colorScheme.background,
color: AppTheme.getTextColor(isDark),

// ❌ Incorrecto
backgroundColor: Colors.white,
color: Colors.black,
```

### 3. Implementar botón de cambio de tema en AppBar

```dart
actions: [
  IconButton(
    icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
    onPressed: () => themeProvider.toggleTheme(),
    tooltip: isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
  ),
  // ... otros botones
],
```

### 4. Usar colores específicos del rol

```dart
// ✅ Correcto
final roleColor = AppTheme.getRoleColor('admin', isDark);
backgroundColor: roleColor,

// ❌ Incorrecto
backgroundColor: Colors.purple,
```

## 🔄 Persistencia del Tema

El tema se guarda automáticamente en SharedPreferences y se restaura al reiniciar la app.

### Modos Disponibles

- **Light**: Tema claro fijo
- **Dark**: Tema oscuro fijo  
- **System**: Sigue el tema del sistema operativo

### Cambiar Modo

```dart
// Cambiar a modo específico
themeProvider.setThemeMode(ThemeMode.dark);
themeProvider.setThemeMode(ThemeMode.light);
themeProvider.setThemeMode(ThemeMode.system);

// Alternar entre claro y oscuro
themeProvider.toggleTheme();
```

## 🐛 Solución de Problemas

### Error: "ThemeProvider not found"

```dart
// Asegúrate de que la app esté envuelta en ChangeNotifierProvider
return ChangeNotifierProvider(
  create: (context) => ThemeProvider(),
  child: MaterialApp(...),
);
```

### Error: "Consumer not working"

```dart
// Verifica que estés usando Consumer correctamente
return Consumer<ThemeProvider>(
  builder: (context, themeProvider, child) {
    // ... tu código aquí
  },
);
```

### Colores no se actualizan

```dart
// Asegúrate de usar Theme.of(context) o AppTheme.get*Color()
backgroundColor: Theme.of(context).colorScheme.background,
color: AppTheme.getTextColor(isDark),
```

## 📚 Recursos Adicionales

- [Flutter Theme Documentation](https://docs.flutter.dev/cookbook/design/themes)
- [Provider Package](https://pub.dev/packages/provider)
- [Material Design 3](https://m3.material.io/)

## 🤝 Contribución

Para agregar nuevos temas o modificar colores existentes:

1. Edita `app_theme.dart`
2. Actualiza `theme_provider.dart` si es necesario
3. Prueba en diferentes pantallas
4. Actualiza este README

---

**Nota**: Este sistema de modo oscuro es compatible con Material Design 3 y se adapta automáticamente a todos los dispositivos y orientaciones.
