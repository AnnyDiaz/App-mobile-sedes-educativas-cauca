import 'package:flutter/material.dart';
import 'package:frontend_visitas/utils/responsive_utils.dart';

class ResponsiveTheme {
  static ThemeData getTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.light,
      ),
      
      // Configuración de texto responsive
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 32),
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 28),
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 24),
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 22),
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
        ),
        bodyMedium: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
        ),
        bodySmall: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
        ),
        labelLarge: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 10),
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Configuración de iconos responsive
      iconTheme: IconThemeData(
        size: ResponsiveUtils.getIconSize(context),
        color: Colors.indigo.shade700,
      ),
      
      // Configuración de botones responsive
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
            vertical: ResponsiveUtils.getResponsiveSpacing(context),
          ),
          textStyle: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Configuración de tarjetas responsive
      cardTheme: CardThemeData(
        margin: ResponsiveUtils.getResponsiveMargin(context),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Configuración de AppBar responsive
      appBarTheme: AppBarTheme(
        titleTextStyle: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        toolbarHeight: ResponsiveUtils.getResponsiveSpacing(context) * 3,
        elevation: 0,
      ),
      
      // Configuración de input fields responsive
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
        ),
        hintStyle: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
        ),
      ),
    );
  }
}
