import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ErrorHandlerService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Maneja errores 401 Unauthorized mostrando un diálogo amigable
  static Future<void> handleUnauthorizedError(BuildContext context) async {
    if (!context.mounted) return;

    // Mostrar diálogo de sesión expirada
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[600]),
            const SizedBox(width: 8),
            const Text('Sesión expirada'),
          ],
        ),
        content: const Text(
          'Tu sesión ha caducado, por favor inicia sesión nuevamente.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await _clearSessionData();
              if (context.mounted) {
                // Usar pushReplacementNamed en lugar de pushNamedAndRemoveUntil
                Navigator.of(context).pushReplacementNamed('/auth');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Iniciar sesión'),
          ),
        ],
      ),
    );
  }

  /// Limpia todos los datos de sesión
  static Future<void> _clearSessionData() async {
    try {
      // Limpiar tokens del almacenamiento seguro
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      
      // Limpiar datos de SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      // Ignorar errores al limpiar datos
    }
  }

  /// Muestra diálogo de confirmación para cerrar sesión
  static Future<bool> showLogoutConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Cerrar sesión'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión?\n\nTendrás que iniciar sesión nuevamente para continuar.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Procesa el cierre de sesión con confirmación
  static Future<void> processLogout(BuildContext context) async {
    final confirmed = await showLogoutConfirmation(context);
    if (confirmed) {
      await _clearSessionData();
      if (context.mounted) {
        // Usar pushReplacementNamed en lugar de pushNamedAndRemoveUntil
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    }
  }
}
