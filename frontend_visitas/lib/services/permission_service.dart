import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

/// Servicio para manejar permisos de la aplicación de forma centralizada
class PermissionService {
  /// Solicita permisos de almacenamiento para descargas
  /// Compatible con Android 11+ (API 30+)
  static Future<bool> requestStoragePermissions() async {
    if (!Platform.isAndroid) {
      return true; // iOS no requiere permisos especiales para descargas
    }

    try {
      // Verificar primero si ya tenemos permisos
      if (await hasStoragePermissions()) {
        print('✅ Permisos de almacenamiento ya otorgados');
        return true;
      }

      print('🔐 Solicitando permisos de almacenamiento...');
      
      // Primero intentar con permisos estándar de almacenamiento
      final storageStatus = await Permission.storage.request();
      print('📱 Estado de permisos storage: ${storageStatus.toString()}');
      
      if (storageStatus.isGranted) {
        print('✅ Permisos de storage otorgados');
        return true;
      }

      // Para Android 11+ (API 30+), intentar con manageExternalStorage
      if (await Permission.manageExternalStorage.isDenied) {
        print('🔐 Solicitando permisos de manageExternalStorage...');
        final manageStatus = await Permission.manageExternalStorage.request();
        print('📱 Estado de permisos manageExternalStorage: ${manageStatus.toString()}');
        
        if (manageStatus.isGranted) {
          print('✅ Permisos de manageExternalStorage otorgados');
          return true;
        }
      }

      print('❌ Permisos de almacenamiento denegados');
      return false;
    } catch (e) {
      print('❌ Error solicitando permisos de almacenamiento: $e');
      return false;
    }
  }

  /// Verifica si los permisos de almacenamiento están otorgados
  static Future<bool> hasStoragePermissions() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final storageStatus = await Permission.storage.status;
      print('📱 Estado actual de permisos storage: ${storageStatus.toString()}');
      
      if (storageStatus.isGranted) {
        print('✅ Permisos de storage ya otorgados');
        return true;
      }

      final manageStatus = await Permission.manageExternalStorage.status;
      print('📱 Estado actual de permisos manageExternalStorage: ${manageStatus.toString()}');
      
      if (manageStatus.isGranted) {
        print('✅ Permisos de manageExternalStorage ya otorgados');
        return true;
      }

      print('❌ No hay permisos de almacenamiento otorgados');
      return false;
    } catch (e) {
      print('❌ Error verificando permisos de almacenamiento: $e');
      return false;
    }
  }

  /// Muestra un diálogo informativo sobre permisos de almacenamiento
  static Future<void> showStoragePermissionDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.storage, color: Colors.orange[600]),
              const SizedBox(width: 8),
              const Text('Permisos de Almacenamiento'),
            ],
          ),
          content: const Text(
            'Para descargar archivos, la aplicación necesita acceso al almacenamiento del dispositivo.\n\n'
            'Por favor, habilita los permisos de almacenamiento en la configuración de la aplicación.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Ir a Configuración'),
            ),
          ],
        );
      },
    );
  }

  /// Solicita permisos de ubicación
  static Future<bool> requestLocationPermissions() async {
    try {
      final status = await Permission.location.request();
      return status.isGranted;
    } catch (e) {
      print('❌ Error solicitando permisos de ubicación: $e');
      return false;
    }
  }

  /// Verifica si los permisos de ubicación están otorgados
  static Future<bool> hasLocationPermissions() async {
    try {
      final status = await Permission.location.status;
      return status.isGranted;
    } catch (e) {
      print('❌ Error verificando permisos de ubicación: $e');
      return false;
    }
  }

  /// Solicita permisos de cámara
  static Future<bool> requestCameraPermissions() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      print('❌ Error solicitando permisos de cámara: $e');
      return false;
    }
  }

  /// Verifica si los permisos de cámara están otorgados
  static Future<bool> hasCameraPermissions() async {
    try {
      final status = await Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      print('❌ Error verificando permisos de cámara: $e');
      return false;
    }
  }

  /// Maneja la descarga con verificación de permisos
  static Future<bool> handleDownloadWithPermissions(
    BuildContext context,
    Future<void> Function() downloadFunction,
  ) async {
    try {
      // Verificar permisos existentes
      if (await hasStoragePermissions()) {
        await downloadFunction();
        return true;
      }

      // Solicitar permisos si no están otorgados
      final granted = await requestStoragePermissions();
      if (granted) {
        await downloadFunction();
        return true;
      } else {
        // Mostrar diálogo informativo si no se otorgaron permisos
        await showStoragePermissionDialog(context);
        return false;
      }
    } catch (e) {
      print('❌ Error en descarga con permisos: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar archivo: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return false;
    }
  }

  /// Verifica y solicita todos los permisos necesarios al iniciar la app
  static Future<Map<String, bool>> checkAndRequestPermissions() async {
    print('🔐 Iniciando verificación de permisos...');
    
    final results = <String, bool>{};
    
    try {
      // 1. Permisos de ubicación
      print('📍 Verificando permisos de ubicación...');
      if (await hasLocationPermissions()) {
        results['location'] = true;
        print('✅ Permisos de ubicación ya otorgados');
      } else {
        final locationGranted = await requestLocationPermissions();
        results['location'] = locationGranted;
        print(locationGranted ? '✅ Permisos de ubicación otorgados' : '❌ Permisos de ubicación denegados');
      }

      // 2. Permisos de cámara
      print('📷 Verificando permisos de cámara...');
      if (await hasCameraPermissions()) {
        results['camera'] = true;
        print('✅ Permisos de cámara ya otorgados');
      } else {
        final cameraGranted = await requestCameraPermissions();
        results['camera'] = cameraGranted;
        print(cameraGranted ? '✅ Permisos de cámara otorgados' : '❌ Permisos de cámara denegados');
      }

      // 3. Permisos de almacenamiento (solo Android)
      if (Platform.isAndroid) {
        print('💾 Verificando permisos de almacenamiento...');
        if (await hasStoragePermissions()) {
          results['storage'] = true;
          print('✅ Permisos de almacenamiento ya otorgados');
        } else {
          final storageGranted = await requestStoragePermissions();
          results['storage'] = storageGranted;
          print(storageGranted ? '✅ Permisos de almacenamiento otorgados' : '❌ Permisos de almacenamiento denegados');
        }
      } else {
        results['storage'] = true; // iOS no requiere permisos especiales
        print('✅ Permisos de almacenamiento no requeridos en iOS');
      }

      print('🔐 Verificación de permisos completada: $results');
      return results;
      
    } catch (e) {
      print('❌ Error verificando permisos: $e');
      return {
        'location': false,
        'camera': false,
        'storage': false,
      };
    }
  }

  /// Muestra un diálogo informativo sobre permisos denegados
  static Future<void> showPermissionDeniedDialog(
    BuildContext context,
    List<String> deniedPermissions,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[600]),
              const SizedBox(width: 8),
              const Text('Permisos Requeridos'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'La aplicación necesita los siguientes permisos para funcionar correctamente:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ...deniedPermissions.map((permission) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      _getPermissionIcon(permission),
                      size: 20,
                      color: Colors.red[600],
                    ),
                    const SizedBox(width: 8),
                    Text(_getPermissionDescription(permission)),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              const Text(
                'Por favor, habilita estos permisos en la configuración de la aplicación para continuar.',
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Ir a Configuración'),
            ),
          ],
        );
      },
    );
  }

  /// Obtiene el icono para un permiso específico
  static IconData _getPermissionIcon(String permission) {
    switch (permission) {
      case 'location':
        return Icons.location_on;
      case 'camera':
        return Icons.camera_alt;
      case 'storage':
        return Icons.storage;
      default:
        return Icons.warning;
    }
  }

  /// Obtiene la descripción para un permiso específico
  static String _getPermissionDescription(String permission) {
    switch (permission) {
      case 'location':
        return 'Ubicación - Para capturar coordenadas GPS en las visitas';
      case 'camera':
        return 'Cámara - Para tomar fotos de evidencias y firmas';
      case 'storage':
        return 'Almacenamiento - Para descargar reportes y guardar archivos';
      default:
        return 'Permiso requerido';
    }
  }
}
