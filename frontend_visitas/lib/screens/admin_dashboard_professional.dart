import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_visitas/config.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend_visitas/screens/perfil_screen.dart';
import 'package:frontend_visitas/utils/responsive_utils.dart';
import 'package:frontend_visitas/utils/modern_colors.dart';
import 'package:frontend_visitas/utils/modern_typography.dart';
import 'package:frontend_visitas/providers/theme_provider.dart';
import 'package:frontend_visitas/theme/app_theme.dart';

enum KPIStatus { good, warning, critical }

class AdminDashboardProfessional extends StatefulWidget {
  const AdminDashboardProfessional({super.key});

  @override
  State<AdminDashboardProfessional> createState() => _AdminDashboardProfessionalState();
}

class _AdminDashboardProfessionalState extends State<AdminDashboardProfessional> with TickerProviderStateMixin {
  bool _loading = true;
  // Removed _isDarkMode - using ThemeProvider instead
  Map<String, dynamic>? _estadisticas;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _cargarEstadisticas();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Theme management now handled by ThemeProvider

  KPIStatus _getKPIStatus(int value, String type) {
    switch (type) {
      case 'usuarios':
        if (value >= 10) return KPIStatus.good;
        if (value >= 5) return KPIStatus.warning;
        return KPIStatus.critical;
      case 'pendientes':
        if (value <= 2) return KPIStatus.good;
        if (value <= 5) return KPIStatus.warning;
        return KPIStatus.critical;
      case 'completadas':
        if (value >= 8) return KPIStatus.good;
        if (value >= 4) return KPIStatus.warning;
        return KPIStatus.critical;
      case 'alertas':
        if (value == 0) return KPIStatus.good;
        if (value <= 2) return KPIStatus.warning;
        return KPIStatus.critical;
      default:
        return KPIStatus.good;
    }
  }

  Future<void> _cargarEstadisticas() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        await _cerrarSesion();
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/dashboard/estadisticas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _estadisticas = data;
          _loading = false;
        });
        _animationController.forward();
      } else if (response.statusCode == 401) {
        await _cerrarSesion();
        return;
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('No hay token')) {
        await _cerrarSesion();
        return;
      }
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _navegarA(String ruta) {
    Navigator.pushNamed(context, ruta);
  }

  void _mostrarBusqueda() {
    showSearch(
      context: context,
      delegate: AdminSearchDelegate(),
    );
  }

  Future<void> _cerrarSesion() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesión expirada. Redirigiendo al login...'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      await Future.delayed(const Duration(seconds: 2));
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user_id');
      await prefs.remove('user_role');

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDark;
        final roleColor = AppTheme.getRoleColor('admin', isDark);
        
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorState()
                  : _buildDashboardContent(),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Text(_error ?? "Error desconocido"),
    );
  }

  Widget _buildDashboardContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
                         child: Padding(
               padding: ResponsiveUtils.getResponsivePadding(context) * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKPIsSection(),
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 4),
                  _buildChartsSection(),
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 4),
                  _buildQuickActionsOrganized(),
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 2.5),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildSliverAppBar() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDark;
        final roleColor = AppTheme.getRoleColor('admin', isDark);
        
        return SliverAppBar(
          // ✅ Navbar ampliado - con espacio para botones y título
          expandedHeight: 80,
          floating: false,
          pinned: true,
          elevation: 10,
          backgroundColor: roleColor,
          // ✅ Botones arriba en el AppBar
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white, size: 28),
              onPressed: _mostrarBusqueda,
              tooltip: 'Buscar',
            ),
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => themeProvider.toggleTheme(),
              tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
              onPressed: _cargarEstadisticas,
              tooltip: 'Actualizar',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle, color: Colors.white, size: 28),
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
          // ✅ Título abajo en la parte inferior del navbar
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: const Text(
                'Panel de Administración',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 🔹 KPIs (Estado del Sistema)
  Widget _buildKPIsSection() {
    final kpis = _estadisticas ?? {};
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Estado del Sistema",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16), // ✅ Letra más pequeña
                    color: themeProvider.isDark ? Colors.white : Colors.black87)),
        SizedBox(height: ResponsiveUtils.screenWidth(context) > 600 ? 12 : 8), // ✅ Espaciado responsivo
        GridView.count(
          crossAxisCount: ResponsiveUtils.screenWidth(context) > 900 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: ResponsiveUtils.screenWidth(context) > 600 ? 8 : 4, // ✅ Espaciado responsivo
          mainAxisSpacing: ResponsiveUtils.screenWidth(context) > 600 ? 8 : 4, // ✅ Espaciado responsivo
          childAspectRatio: ResponsiveUtils.screenWidth(context) > 900 ? 1.3 : 
                           ResponsiveUtils.screenWidth(context) > 600 ? 1.1 : 0.9, // ✅ Aspect ratio ultra responsivo para evitar overflow
          children: [
            _buildSemaphoreKPI(
              'Usuarios Totales', '${kpis['usuarios_activos'] ?? 0}', Icons.people, _getKPIStatus(kpis['usuarios_activos'] ?? 0, 'usuarios'), 'Activos'),
            _buildSemaphoreKPI(
              'Visitas Pendientes', '${kpis['visitas_programadas_hoy'] ?? 0}', Icons.pending_actions, _getKPIStatus(kpis['visitas_programadas_hoy'] ?? 0, 'pendientes'), 'Para hoy'),
            _buildSemaphoreKPI(
              'Visitas Programadas', '${kpis['visitas_programadas_semana'] ?? 0}', Icons.assignment, _getKPIStatus(kpis['visitas_programadas_semana'] ?? 0, 'completadas'), 'Esta semana'),
            _buildSemaphoreKPI(
              'Alertas Críticas', '${kpis['alertas_criticas'] ?? 0}', Icons.warning, _getKPIStatus(kpis['alertas_criticas'] ?? 0, 'alertas'), 'Requieren atención'),
          ],
        )
          ],
        );
      },
    );
  }

  // 🔹 Gráficos y Estadísticas
  Widget _buildChartsSection() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: themeProvider.isDark ? Colors.white : Colors.grey.shade800,
                  size: ResponsiveUtils.getIconSize(context),
                ),
                SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context) * 1.5),
                Text(
                  'Análisis y Tendencias',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 2),
        ResponsiveUtils.screenWidth(context) < 600
            ? Column(
                children: [
                  _buildVisitasChart(),
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 2),
                  _buildRolesDistributionChart(),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildVisitasChart(),
                  ),
                  SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context) * 2),
                  Expanded(
                    flex: 1,
                    child: _buildRolesDistributionChart(),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  // 🔹 Herramientas de Gestión
  Widget _buildQuickActionsOrganized() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Herramientas de Gestión",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16), // ✅ Letra más pequeña
                    color: themeProvider.isDark ? Colors.white : Colors.black87)),
        SizedBox(height: ResponsiveUtils.screenWidth(context) > 600 ? 12 : 8), // ✅ Espaciado responsivo
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              _buildCategoryCard('Gestión', 'Usuarios y permisos',
                  Icons.admin_panel_settings, Colors.blue, [
                {'title': 'Usuarios', 'route': '/admin_usuarios'},
                {'title': 'Roles', 'route': '/admin_roles'},
              ]),
              const SizedBox(width: 16),
              _buildCategoryCard('Operativo', 'Visitas y evaluaciones',
                  Icons.assignment, Colors.green, [
                {'title': 'Programar Visitas', 'route': '/admin_mass_scheduling'},
                {'title': 'Checklists', 'route': '/admin_checklists'},
              ]),
              const SizedBox(width: 16),
              _buildCategoryCard('Reportes', 'Analytics y datos',
                  Icons.bar_chart, Colors.purple, [
                {'title': 'Analytics', 'route': '/admin_analytics'},
                {'title': 'Exportar Datos', 'route': '/admin_exports'},
              ]),
              const SizedBox(width: 16),
              _buildCategoryCard('Configuración', 'Sistema y seguridad',
                  Icons.settings, Colors.orange, [
                {'title': '2FA', 'route': '/admin_2fa'},
                {'title': 'Notificaciones', 'route': '/admin_notifications'},
              ]),
            ],
          ),
        ),
          ],
        );
      },
    );
  }

    /// 🔹 KPI optimizado para evitar overflow
  Widget _buildSemaphoreKPI(String titulo, String valor, IconData icono, KPIStatus status, String subtitulo) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: themeProvider.isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8), // ✅ Padding reducido
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: Colors.blue, size: 20), // ✅ Icono azul original
            const SizedBox(height: 6), // ✅ Espaciado reducido
            Text(valor,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18), // ✅ Número 2 puntos más grande
                    color: Colors.blue)),
            const SizedBox(height: 2), // ✅ Espaciado mínimo
            Text(titulo,
                style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 10), // ✅ Título más pequeño y responsivo
                    fontWeight: FontWeight.w600,
                    color: Colors.black54)),
            Text(subtitulo,
                style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 10), // ✅ Subtítulo más pequeño y responsivo
                    color: Colors.grey)),
          ],
        ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(String titulo, String descripcion, IconData icono, Color color,
      List<Map<String, String>> acciones) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          width: 280,
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
            color: themeProvider.isDark ? const Color(0xFF1E1E1E) : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color),
          const SizedBox(height: 8),
          Text(titulo,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          Text(descripcion,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 12),
          ...acciones.map((accion) => TextButton(
                onPressed: () => _navegarA(accion['route']!),
                style: TextButton.styleFrom(
                  backgroundColor: color.withOpacity(0.1),
                  foregroundColor: color,
                ),
                child: Text(accion['title']!,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
              )),
        ],
          ),
        );
      },
    );
  }

  Widget _buildVisitasChart() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          height: ResponsiveUtils.screenHeight(context) * 0.35,
          padding: ResponsiveUtils.getResponsivePadding(context) * 1.25,
          decoration: BoxDecoration(
            color: themeProvider.isDark ? const Color(0xFF1E1E1E) : ModernColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ModernColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visitas por Semana',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
              fontWeight: FontWeight.bold,
              color: themeProvider.isDark ? Colors.white : Colors.grey.shade800,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 2),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 50,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(fontSize: 12);
                        Widget text;
                        switch (value.toInt()) {
                          case 0:
                            text = const Text('Lun', style: style);
                            break;
                          case 1:
                            text = const Text('Mar', style: style);
                            break;
                          case 2:
                            text = const Text('Mié', style: style);
                            break;
                          case 3:
                            text = const Text('Jue', style: style);
                            break;
                          case 4:
                            text = const Text('Vie', style: style);
                            break;
                          default:
                            text = const Text('', style: style);
                            break;
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: text,
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 25, color: ModernColors.primary)]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 35, color: ModernColors.success)]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 20, color: ModernColors.warning)]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 40, color: ModernColors.info)]),
                  BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 30, color: ModernColors.primaryLight)]),
                ],
              ),
            ),
          ),
        ],
          ),
        );
      },
    );
  }

  Widget _buildRolesDistributionChart() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          height: ResponsiveUtils.screenHeight(context) * 0.35,
          padding: ResponsiveUtils.getResponsivePadding(context) * 1.25,
          decoration: BoxDecoration(
            color: themeProvider.isDark ? const Color(0xFF1E1E1E) : ModernColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ModernColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribución por Rol',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
              fontWeight: FontWeight.bold,
              color: themeProvider.isDark ? Colors.white : Colors.grey.shade800,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 2),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: ModernColors.primary,
                    value: 60,
                    title: '60%',
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: ModernColors.success,
                    value: 25,
                    title: '25%',
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: ModernColors.warning,
                    value: 15,
                    title: '15%',
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 2),
          Column(
            children: [
              _buildLegendItem('Visitadores', ModernColors.primary),
              _buildLegendItem('Supervisores', ModernColors.success),
              _buildLegendItem('Admins', ModernColors.warning),
            ],
          ),
        ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: themeProvider.isDark ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
        ],
          ),
        );
      },
    );
  }

}

// Clase para la búsqueda en el dashboard de admin
class AdminSearchDelegate extends SearchDelegate {
  final List<Map<String, String>> searchItems = [
    {'title': 'Gestión de Usuarios', 'route': '/admin_usuarios'},
    {'title': 'Roles y Permisos', 'route': '/admin_roles'},
    {'title': 'Programar Visitas', 'route': '/admin_mass_scheduling'},
    {'title': 'Exportaciones', 'route': '/admin_exports'},
    {'title': 'Analytics', 'route': '/admin_analytics'},
    {'title': 'Checklists', 'route': '/admin_checklists'},
    {'title': 'Configuración 2FA', 'route': '/admin_2fa'},
    {'title': 'Notificaciones', 'route': '/admin_notifications'},
  ];

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = searchItems.where((item) {
      return item['title']!.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return ListTile(
          leading: const Icon(Icons.search),
          title: Text(suggestion['title']!),
          onTap: () {
            close(context, null);
            Future.delayed(Duration.zero,
                () => Navigator.pushNamed(context, suggestion['route']!));
          },
        );
      },
    );
  }
}
