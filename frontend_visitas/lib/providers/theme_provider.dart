import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.light;
  bool _isDark = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _isDark;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = prefs.getString(_themeKey);
      
      if (themeString != null) {
        switch (themeString) {
          case 'light':
            _themeMode = ThemeMode.light;
            _isDark = false;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            _isDark = true;
            break;
          case 'system':
          default:
            _themeMode = ThemeMode.system;
            _isDark = _getSystemTheme();
            break;
        }
      } else {
        // Por defecto usar modo claro
        _themeMode = ThemeMode.light;
        _isDark = false;
      }
      notifyListeners();
    } catch (e) {
      // En caso de error, usar modo claro por defecto
      _themeMode = ThemeMode.light;
      _isDark = false;
      notifyListeners();
    }
  }

  bool _getSystemTheme() {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    
    switch (mode) {
      case ThemeMode.light:
        _isDark = false;
        break;
      case ThemeMode.dark:
        _isDark = true;
        break;
      case ThemeMode.system:
        _isDark = _getSystemTheme();
        break;
    }

    // Guardar preferencia
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeString;
      switch (mode) {
        case ThemeMode.light:
          themeString = 'light';
          break;
        case ThemeMode.dark:
          themeString = 'dark';
          break;
        case ThemeMode.system:
          themeString = 'system';
          break;
      }
      await prefs.setString(_themeKey, themeString);
    } catch (e) {
      // Ignorar errores de persistencia
    }

    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.system) {
      // Si está en modo sistema, cambiar a modo manual
      await setThemeMode(_isDark ? ThemeMode.light : ThemeMode.dark);
    } else {
      // Si está en modo manual, alternar
      await setThemeMode(_themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
    }
  }

  // Método para obtener el tema actual basado en el modo
  ThemeData getCurrentTheme(ThemeData lightTheme, ThemeData darkTheme) {
    switch (_themeMode) {
      case ThemeMode.light:
        return lightTheme;
      case ThemeMode.dark:
        return darkTheme;
      case ThemeMode.system:
        return _isDark ? darkTheme : lightTheme;
    }
  }

  // Método para escuchar cambios en el tema del sistema
  void updateSystemTheme() {
    if (_themeMode == ThemeMode.system) {
      final newIsDark = _getSystemTheme();
      if (newIsDark != _isDark) {
        _isDark = newIsDark;
        notifyListeners();
      }
    }
  }
}
