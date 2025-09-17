import 'package:flutter/material.dart';

class ResponsiveUtils {
  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;
  
  // Factores de escala basados en el tamaño de pantalla
  static double getScaleFactor(BuildContext context) {
    double width = screenWidth(context);
    if (width < 360) return 0.8;      // Pantallas muy pequeñas
    if (width < 400) return 0.9;      // Pantallas pequeñas
    if (width < 450) return 1.0;      // Pantallas medianas
    if (width < 500) return 1.1;      // Pantallas grandes
    return 1.2;                       // Pantallas muy grandes
  }
  
  // Tamaños de texto responsivos
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    return baseSize * getScaleFactor(context);
  }
  
  // Padding responsivo
  static EdgeInsets getResponsivePadding(BuildContext context) {
    double scale = getScaleFactor(context);
    return EdgeInsets.all(16.0 * scale);
  }
  
  // Margen responsivo
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    double scale = getScaleFactor(context);
    return EdgeInsets.all(8.0 * scale);
  }
  
  // Tamaño de tarjetas responsivo
  static double getCardHeight(BuildContext context) {
    double height = screenHeight(context);
    if (height < 600) return 120.0;    // Pantallas muy pequeñas
    if (height < 700) return 140.0;    // Pantallas pequeñas
    if (height < 800) return 160.0;    // Pantallas medianas
    return 180.0;                      // Pantallas grandes
  }
  
  // Espaciado entre elementos responsivo
  static double getResponsiveSpacing(BuildContext context) {
    return 12.0 * getScaleFactor(context);
  }
  
  // Tamaño de iconos responsivo
  static double getIconSize(BuildContext context) {
    return 24.0 * getScaleFactor(context);
  }
  
  // Tamaño de gráficos responsivo
  static double getChartHeight(BuildContext context) {
    double height = screenHeight(context);
    if (height < 600) return 200.0;    // Pantallas muy pequeñas
    if (height < 700) return 250.0;    // Pantallas pequeñas
    if (height < 800) return 300.0;    // Pantallas medianas
    return 350.0;                      // Pantallas grandes
  }
}
