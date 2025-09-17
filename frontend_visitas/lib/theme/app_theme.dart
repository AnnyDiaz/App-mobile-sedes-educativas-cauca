import 'package:flutter/material.dart';

class AppTheme {
  static const Color _primaryColor = Colors.purple;
  static const Color _primaryVariant = Color(0xFF6A1B9A);
  static const Color _secondaryColor = Colors.teal;
  static const Color _secondaryVariant = Color(0xFF00695C);

  // Tema Claro
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: _primaryColor,
      primaryContainer: _primaryVariant,
      secondary: _secondaryColor,
      secondaryContainer: _secondaryVariant,
      surface: Colors.white,
      background: Colors.grey.shade50,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      onBackground: Colors.black87,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: true,
    ),
         cardTheme: CardThemeData(
       elevation: 2,
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(12),
       ),
     ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  // Tema Oscuro
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: _primaryColor,
      primaryContainer: _primaryVariant,
      secondary: _secondaryColor,
      secondaryContainer: _secondaryVariant,
      surface: const Color(0xFF1E1E1E),
      background: const Color(0xFF121212),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
         cardTheme: CardThemeData(
       elevation: 1,
       color: const Color(0xFF2D2D2D),
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(12),
       ),
     ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 1,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: const Color(0xFF2D2D2D),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 2,
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade700,
      thickness: 1,
    ),
    listTileTheme: ListTileThemeData(
      tileColor: const Color(0xFF2D2D2D),
      selectedTileColor: _primaryColor.withOpacity(0.1),
    ),
  );

  // Colores específicos para roles
  static Color getRoleColor(String role, bool isDark) {
    switch (role.toLowerCase()) {
      case 'admin':
        return isDark ? Colors.purple.shade300 : Colors.purple.shade600;
      case 'supervisor':
        return isDark ? Colors.indigo.shade300 : Colors.indigo.shade600;
      case 'visitador':
        return isDark ? Colors.teal.shade300 : Colors.teal.shade600;
      case 'visitante':
        return isDark ? Colors.orange.shade300 : Colors.orange.shade600;
      default:
        return isDark ? Colors.grey.shade300 : Colors.grey.shade600;
    }
  }

  // Colores de estado
  static Color getStatusColor(String status, bool isDark) {
    switch (status.toLowerCase()) {
      case 'completada':
      case 'success':
        return isDark ? Colors.green.shade300 : Colors.green.shade600;
      case 'pendiente':
      case 'warning':
        return isDark ? Colors.orange.shade300 : Colors.orange.shade600;
      case 'cancelada':
      case 'error':
        return isDark ? Colors.red.shade300 : Colors.red.shade600;
      case 'en_proceso':
      case 'info':
        return isDark ? Colors.blue.shade300 : Colors.blue.shade600;
      default:
        return isDark ? Colors.grey.shade300 : Colors.grey.shade600;
    }
  }

  // Colores de fondo para cards
  static Color getCardBackgroundColor(bool isDark) {
    return isDark ? const Color(0xFF2D2D2D) : Colors.white;
  }

  // Colores de texto
  static Color getTextColor(bool isDark, {bool isPrimary = true}) {
    if (isDark) {
      return isPrimary ? Colors.white : Colors.grey.shade300;
    } else {
      return isPrimary ? Colors.black87 : Colors.grey.shade600;
    }
  }

  // Colores de superficie
  static Color getSurfaceColor(bool isDark) {
    return isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50;
  }
}
