import 'package:flutter/material.dart';

class ModernColors {
  // Colores principales
  static const Color primary = Color(0xFF6366F1);      // Indigo suave
  static const Color primaryLight = Color(0xFF818CF8); // Indigo más claro
  static const Color primaryDark = Color(0xFF4F46E5);  // Indigo más oscuro
  
  // Colores de fondo
  static const Color background = Color(0xFFFAFAFA);   // Gris muy claro
  static const Color surface = Color(0xFFFFFFFF);      // Blanco puro
  static const Color surfaceVariant = Color(0xFFF8F9FA); // Gris muy suave
  
  // Colores de texto
  static const Color textPrimary = Color(0xFF1F2937);  // Gris oscuro
  static const Color textSecondary = Color(0xFF6B7280); // Gris medio
  static const Color textTertiary = Color(0xFF9CA3AF); // Gris claro
  
  // Colores de estado
  static const Color success = Color(0xFF10B981);      // Verde suave
  static const Color warning = Color(0xFFF59E0B);      // Naranja suave
  static const Color error = Color(0xFFEF4444);        // Rojo suave
  static const Color info = Color(0xFF3B82F6);        // Azul suave
  
  // Colores de estado con transparencia
  static Color successLight = success.withOpacity(0.1);
  static Color warningLight = warning.withOpacity(0.1);
  static Color errorLight = error.withOpacity(0.1);
  static Color infoLight = info.withOpacity(0.1);
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
  
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surface, surfaceVariant],
  );
  
  // Sombras
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 15,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 25,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> get strongShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
  ];
}
