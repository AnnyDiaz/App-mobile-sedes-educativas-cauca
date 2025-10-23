import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/screens/visitas_equipo_screen.dart';
import 'package:frontend_visitas/screens/alertas_screen.dart';
import 'package:frontend_visitas/screens/perfil_screen.dart';
import 'package:frontend_visitas/screens/programar_visita_screen.dart';
import 'package:frontend_visitas/screens/reportes_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_visitas/providers/theme_provider.dart';
import 'package:frontend_visitas/theme/app_theme.dart';

class SupervisorDashboardReal extends StatefulWidget {
  const SupervisorDashboardReal({super.key});

  @override
  State<SupervisorDashboardReal> createState() => _SupervisorDashboardRealState();
}

class _SupervisorDashboardRealState extends State<SupervisorDashboardReal> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _estadisticas;
  Map<String, dynamic>? _perfilUsuario;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Cargar estadísticas específicas del supervisor y perfil en paralelo
      final futures = await Future.wait([
        _apiService.getEstadisticasSupervisor(),
        _apiService.getPerfilUsuario(),
      ]);

      setState(() {
        _estadisticas = futures[0] as Map<String, dynamic>;
        _perfilUsuario = futures[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _cerrarSesion() async {
    try {
      // Limpiar token almacenado
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user_id');
      await prefs.remove('user_role');
      
      // Navegar al login
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    } catch (e) {
      // En caso de error, también navegar al login
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDark;
        final roleColor = AppTheme.getRoleColor('supervisor', isDark);
        
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: AppBar(
            title: const Text('Dashboard Supervisor'),
            backgroundColor: roleColor,
            foregroundColor: Colors.white,
            actions: [
              // Botón de cambio de tema
              IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
              ),
              
              // Botón de actualizar
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _cargarDatos,
                tooltip: 'Actualizar',
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
                    Icon(Icons.person, color: Colors.indigo),
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
              : _buildDashboardContent(),
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
            onPressed: _cargarDatos,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saludo de bienvenida
          _buildWelcomeCard(),
          const SizedBox(height: 24),
          
          // Resumen rápido - Tarjetas de estadísticas del equipo
          _buildTeamStatisticsCards(),
          const SizedBox(height: 24),
          
          // Menú de acciones principales del supervisor
          _buildSupervisorActionMenu(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final nombre = _perfilUsuario?['nombre'] ?? 'Supervisor';
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.supervisor_account, size: 32, color: Colors.indigo),
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
                        'Rol: Supervisor de Equipo',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gestiona tu equipo de visitadores y supervisa el progreso de las visitas',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamStatisticsCards() {
    final totalVisitas = _estadisticas?['total_visitas'] ?? 0;
    final visitasPendientes = _estadisticas?['visitas_pendientes'] ?? 0;
    final visitasCompletadas = _estadisticas?['visitas_completadas'] ?? 0;
    final totalVisitadores = _estadisticas?['total_visitadores'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estadísticas de tu Equipo',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Visitas',
                value: totalVisitas.toString(),
                icon: Icons.assessment,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Pendientes',
                value: visitasPendientes.toString(),
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Completadas',
                value: visitasCompletadas.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Visitadores',
                value: totalVisitadores.toString(),
                icon: Icons.people,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupervisorActionMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Funciones de Supervisión',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Ver visitas de mi equipo
        _buildActionButton(
          title: 'Visitas de mi Equipo',
          subtitle: 'Consultar visitas realizadas por tu equipo de visitadores',
          icon: Icons.group,
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VisitasEquipoScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        
        // Programar visita (usando la funcionalidad del dashboard principal)
        _buildActionButton(
          title: 'Programar Visita',
          subtitle: 'Programar y asignar visitas a los visitadores de tu equipo',
          icon: Icons.assignment,
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProgramarVisitaScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        
        // Generar reportes (usando la funcionalidad del dashboard principal)
        _buildActionButton(
          title: 'Generar Reportes',
          subtitle: 'Generar reportes completos del sistema con filtros avanzados',
          icon: Icons.analytics,
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReportesScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        
        // Sistema de alertas
        _buildActionButton(
          title: 'Alertas y Notificaciones',
          subtitle: 'Ver alertas de visitas atrasadas y hallazgos críticos',
          icon: Icons.notifications_active,
          color: Colors.red,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AlertasScreen(),
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
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
