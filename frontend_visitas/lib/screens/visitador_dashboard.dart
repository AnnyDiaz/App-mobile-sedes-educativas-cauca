import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/screens/calendario_visitas_screen.dart';
import 'package:frontend_visitas/screens/crear_cronograma_screen.dart';
import 'package:frontend_visitas/screens/visitas_completas_screen.dart';
import 'package:frontend_visitas/screens/visitas_pendientes_screen.dart';
import 'package:frontend_visitas/screens/perfil_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_visitas/providers/theme_provider.dart';
import 'package:frontend_visitas/theme/app_theme.dart';
import 'package:frontend_visitas/services/error_handler_service.dart';

class VisitadorDashboard extends StatefulWidget {
  const VisitadorDashboard({super.key});

  @override
  State<VisitadorDashboard> createState() => _VisitadorDashboardState();
}

class _VisitadorDashboardState extends State<VisitadorDashboard> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _perfilUsuario;
  List<Map<String, dynamic>> _visitasAsignadas = [];
  bool _isLoading = true;
  String? _error;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    print('🔄 === INICIANDO _cargarDatos ===');
    
    // Evitar múltiples llamadas simultáneas
    if (_isLoadingData || !mounted) {
      print('⚠️ _cargarDatos cancelado: _isLoadingData=$_isLoadingData, mounted=$mounted');
      return;
    }
    
    _isLoadingData = true;
    print('✅ Flag _isLoadingData establecido en true');
    
    try {
      // Solo un setState al inicio
      if (mounted) {
        print('🔄 Haciendo setState inicial...');
        setState(() {
          _isLoading = true;
          _error = null;
        });
        print('✅ setState inicial completado');
      }

      print('📡 Iniciando llamadas a API en paralelo...');
      
      // Cargar datos en paralelo
      final futures = await Future.wait([
        _apiService.getPerfilUsuario(),
        _apiService.getMisVisitasAsignadas(),
      ]);

      print(' Todas las llamadas a API completadas');
      print(' Perfil recibido: ${futures[0]}');
      print(' Visitas asignadas recibidas: ${(futures[1] as List<dynamic>).length} items');

      // Verificar si el widget sigue montado antes de actualizar
      if (mounted) {
        print('🔄 Haciendo setState final con datos actualizados...');
        setState(() {
          _perfilUsuario = futures[0] as Map<String, dynamic>;
          _visitasAsignadas = List<Map<String, dynamic>>.from(futures[1] as List<Map<String, dynamic>>);
          _isLoading = false;
        });
        print('✅ setState final completado');
      } else {
        print('⚠️ Widget no está montado, no se puede hacer setState');
      }
    } catch (e) {
      print('❌ Error en _cargarDatos: $e');
      // Manejo de errores más descriptivo
      if (mounted) {
        print('🔄 Haciendo setState con error...');
        setState(() {
          _error = _getErrorMessage(e);
          _isLoading = false;
        });
        print('✅ setState con error completado');
      }
    } finally {
      _isLoadingData = false;
      print('✅ Flag _isLoadingData establecido en false');
      print('🏁 === _cargarDatos FINALIZADO ===');
    }
  }



  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('connection') || errorStr.contains('timeout')) {
      return 'Error de conexión. Verifica tu conexión a internet.';
    } else if (errorStr.contains('401') || errorStr.contains('unauthorized')) {
      return 'Sesión expirada. Por favor, inicia sesión nuevamente.';
    } else if (errorStr.contains('500') || errorStr.contains('internal server')) {
      return 'Error del servidor. Intenta más tarde.';
    } else if (errorStr.contains('404') || errorStr.contains('not found')) {
      return 'Recurso no encontrado. Verifica la configuración.';
    } else {
      return 'Error inesperado: ${error.toString()}';
    }
  }

  Future<void> _cerrarSesion() async {
    await ErrorHandlerService.processLogout(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDark;
        final roleColor = AppTheme.getRoleColor('visitador', isDark);
        
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: AppBar(
            title: const Text('Mis Visitas'),
            backgroundColor: roleColor,
            foregroundColor: Colors.white,
            actions: [
              // Botón de cambio de tema
              IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
              ),
              
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _isLoadingData ? null : _cargarDatos,
                tooltip: _isLoadingData ? 'Actualizar' : 'Actualizar',
              ),
              
              // Menú de usuario
              PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle),
                tooltip: 'Menú de usuario',
                onSelected: (value) {
                  switch (value) {
                    case 'perfil':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PerfilScreen(),
                        ),
                      );
                      break;
                    case 'cerrar_sesion':
                      _cerrarSesion();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'perfil',
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Mi Perfil'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'cerrar_sesion',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Cerrar Sesión'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorWidget()
                  : RefreshIndicator(
                      onRefresh: _isLoadingData ? () async {} : _cargarDatos,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: _buildDashboardContent(),
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error al cargar datos',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoadingData ? null : _cargarDatos,
            child: _isLoadingData 
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Reintentando...'),
                  ],
                )
              : const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Saludo de bienvenida
        _buildWelcomeCard(),
        const SizedBox(height: 24),
        
        // Menú de acciones principales
        _buildActionMenu(),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    final nombre = _perfilUsuario?['nombre'] ?? 'Visitador';
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.person, size: 32, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido, $nombre',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Rol: ${_perfilUsuario?['rol'] ?? 'Visitador'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildActionMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones Principales',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // BOTÓN PRINCIPAL: Calendario de Visitas
        _buildActionButton(
          title: 'Mi Calendario de Visitas',
          subtitle: 'Ver visitas asignadas por tu supervisor y crear visitas PAE',
          icon: Icons.calendar_today,
          color: Colors.blue[600]!,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CalendarioVisitasScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        
        // BOTÓN: Crear Visita PAE (PRINCIPAL)
        _buildActionButton(
          title: ' Crear Visita PAE',
          subtitle: 'Evaluación completa con checklist, evidencias y observaciones',
          icon: Icons.checklist,
          color: Colors.orange[600]!,
          onTap: () async {
            print(' Navegando a CrearCronogramaScreen...');
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CrearCronogramaScreen(),
              ),
            );
            
            print('🔄 Resultado de navegación: $result');
            
            // Refrescar dashboard si se completó una visita
            if (result != null && result['refresh'] == true) {
              print('✅ === FLAG DE REFRESH DETECTADO ===');
              print('✅ Flag de refresh detectado, actualizando dashboard...');
              if (mounted) {
                print('🔄 Llamando a _cargarDatos()...');
                await _cargarDatos();
                print('✅ Dashboard actualizado correctamente');
                print('✅ === FIN REFRESH DASHBOARD ===');
              } else {
                print('⚠️ Widget no está montado, no se puede actualizar');
              }
            } else {
              print('⚠️ No se detectó flag de refresh o resultado es null');
              print('⚠️ Resultado recibido: $result');
            }
          },
        ),
        const SizedBox(height: 16),
        
        // BOTÓN: Visitas Asignadas (PRINCIPAL)
        _buildActionButton(
          title: ' Visitas Asignadas',
          subtitle: 'Gestionar visitas pendientes, en proceso y completadas',
          icon: Icons.assignment_turned_in,
          color: Colors.indigo[600]!,
          onTap: () {
            Navigator.pushNamed(context, '/visitas_asignadas');
          },
        ),
        const SizedBox(height: 10),
        
        _buildActionButton(
          title: 'Historial de Visitas',
          subtitle: 'Ver y descargar reportes',
          icon: Icons.assignment,
          color: Colors.purple[600]!,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VisitasCompletasScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.05),
                color.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(Icons.arrow_forward_ios, color: color, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
