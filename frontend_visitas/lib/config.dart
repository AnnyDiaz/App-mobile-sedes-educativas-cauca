// lib/config.dart

import 'package:flutter/foundation.dart';

/// Configuración de URL base según plataforma
/// En web: usa la IP del servidor backend
/// En móvil: usa configuración específica para cada plataforma
String getBaseUrl() {
  // SIEMPRE usar la IP del backend para web y pruebas
  // Para web, móvil o desktop, todos usan la misma IP del servidor
  return 'http://192.168.1.87:8000';
}

// URL base configurada automáticamente según plataforma
final String baseUrl = getBaseUrl();

// 📱 DISPOSITIVO REAL (IP de Windows - obtener con 'ipconfig' en PowerShell)
//const String baseUrl = 'http://192.168.1.XXX:8000';

// 🐳 WSL2 (para pruebas desde WSL2)
//const String baseUrl = 'http://172.25.232.170:8000';

// 🌐 PRODUCCIÓN
//const String baseUrl = 'http://138.0.90.98:1912';

// 📱 NOTAS IMPORTANTES:
// 1. Para EMULADOR: usa 10.0.2.2:8000
// 2. Para DISPOSITIVO REAL: usa la IP de tu computadora (192.168.1.83)
// 3. Para obtener tu IP: ejecuta 'ipconfig' en Windows
// 4. Asegúrate de que el firewall permita conexiones al puerto 8000
// 5. Para DOCKER: usa localhost:8000 si Docker está mapeado al puerto 8000