// frontend_visitas/lib/utils/permisos_helper.dart

import 'package:frontend_visitas/services/api_service.dart';

class PermisosHelper {
  static const String _ROL_SUPERVISOR = 'supervisor';
  static const String _ROL_ADMINISTRADOR = 'administrador';
  static const String _ROL_VISITADOR = 'visitador';

  /// Verifica si el usuario actual es supervisor
  static Future<bool> esSupervisor() async {
    try {
      final apiService = ApiService();
      final perfil = await apiService.getPerfilUsuario();
      final rol = perfil['rol']?.toString().toLowerCase() ?? '';
      return rol == _ROL_SUPERVISOR;
    } catch (e) {
      return false;
    }
  }

  /// Verifica si el usuario actual es administrador
  static Future<bool> esAdministrador() async {
    try {
      final apiService = ApiService();
      final perfil = await apiService.getPerfilUsuario();
      final rol = perfil['rol']?.toString().toLowerCase() ?? '';
      return rol == _ROL_ADMINISTRADOR;
    } catch (e) {
      return false;
    }
  }

  /// Verifica si el usuario actual es visitador
  static Future<bool> esVisitador() async {
    try {
      final apiService = ApiService();
      final perfil = await apiService.getPerfilUsuario();
      final rol = perfil['rol']?.toString().toLowerCase() ?? '';
      return rol == _ROL_VISITADOR;
    } catch (e) {
      return false;
    }
  }

  /// Verifica si el usuario puede eliminar registros
  /// Los supervisores NO pueden eliminar registros
  static Future<bool> puedeEliminarRegistros() async {
    final supervisor = await esSupervisor();
    return !supervisor; // Los supervisores NO pueden eliminar
  }

  /// Verifica si el usuario puede modificar registros históricos
  /// Los supervisores tienen limitaciones en modificaciones históricas
  static Future<bool> puedeModificarHistorico() async {
    final supervisor = await esSupervisor();
    return !supervisor; // Los supervisores NO pueden modificar histórico
  }

  /// Verifica si debe mostrar funcionalidades de eliminación
  static Future<bool> mostrarOpcionesEliminacion() async {
    return await puedeEliminarRegistros();
  }

  /// Obtiene el rol actual del usuario
  static Future<String> getRolActual() async {
    try {
      final apiService = ApiService();
      final perfil = await apiService.getPerfilUsuario();
      return perfil['rol']?.toString() ?? 'desconocido';
    } catch (e) {
      return 'desconocido';
    }
  }

  /// Obtiene información detallada de permisos
  static Future<Map<String, bool>> getPermisos() async {
    final esSup = await esSupervisor();
    final esAdmin = await esAdministrador();
    final esVis = await esVisitador();

    return {
      'es_supervisor': esSup,
      'es_administrador': esAdmin,
      'es_visitador': esVis,
      'puede_eliminar': !esSup,
      'puede_modificar_historico': !esSup,
      'requiere_2fa_reportes': esSup, // Solo supervisores requieren 2FA para reportes
      'puede_gestionar_usuarios': esAdmin,
      'puede_asignar_visitas': esSup || esAdmin,
    };
  }
}
