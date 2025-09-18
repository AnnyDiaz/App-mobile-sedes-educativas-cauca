import 'package:flutter/foundation.dart';
import 'dart:typed_data';

// Clase para manejar la compatibilidad entre web y móvil
class PlatformCompat {
  static bool get isWeb => kIsWeb;
  static bool get isMobile => !kIsWeb;
  
  // Método para descargar archivos
  static Future<void> downloadFile(List<int> bytes, String filename, String mimeType) async {
    if (isWeb) {
      // Implementación para web - temporalmente deshabilitada
      print('🌐 Funcionalidad de descarga web temporalmente deshabilitada');
      print('📄 Archivo: $filename (${bytes.length} bytes)');
    } else {
      // Implementación para móvil
      await _downloadFileMobile(bytes, filename, mimeType);
    }
  }
  
  static Future<void> _downloadFileMobile(List<int> bytes, String filename, String mimeType) async {
    // Implementación para móvil - guardar en almacenamiento local
    print('📱 Descarga en móvil: $filename (${bytes.length} bytes)');
    print('⚠️ Funcionalidad de descarga móvil pendiente de implementación');
    // TODO: Implementar guardado en almacenamiento local del móvil
  }
}