import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_visitas/config.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

class AdminAnalyticsDashboard extends StatefulWidget {
  @override
  _AdminAnalyticsDashboardState createState() => _AdminAnalyticsDashboardState();
}

class _AdminAnalyticsDashboardState extends State<AdminAnalyticsDashboard> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;
  
  // Data variables
  Map<String, dynamic>? _kpis;
  List<Map<String, dynamic>> _rankingVisitadores = [];
  Map<String, dynamic>? _distribucionGeografica;
  List<Map<String, dynamic>> _alertas = [];
  
  // UI state
  bool _isLoading = true;
  String _error = '';
  String _periodoSeleccionado = 'mes';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarDatos();
    _iniciarRefreshAutomatico();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _iniciarRefreshAutomatico() {
    _refreshTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      _cargarDatos();
    });
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Cargar datos en paralelo
      final futures = await Future.wait([
        _cargarKPIs(token!),
        _cargarRankingVisitadores(token),
        _cargarDistribucionGeografica(token),
        _cargarAlertas(token),
      ]);

      setState(() {
        // Los datos ya se establecen en cada función individual
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar datos: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cargarKPIs(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/analytics/kpis?periodo=$_periodoSeleccionado'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      _kpis = jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar KPIs: ${response.statusCode}');
    }
  }



  Future<void> _cargarRankingVisitadores(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/analytics/graficos/rendimiento-visitadores?limit=10'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _rankingVisitadores = List<Map<String, dynamic>>.from(data['ranking'] ?? []);
    } else {
      throw Exception('Error al cargar ranking: ${response.statusCode}');
    }
  }

  Future<void> _cargarDistribucionGeografica(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/analytics/graficos/distribucion-geografica'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      _distribucionGeografica = jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar distribución: ${response.statusCode}');
    }
  }

  Future<void> _cargarAlertas(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/analytics/alertas'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _alertas = List<Map<String, dynamic>>.from(data['alertas'] ?? []);
    } else {
      throw Exception('Error al cargar alertas: ${response.statusCode}');
    }
  }

  Color _getColorByTendencia(String tendencia) {
    return tendencia == 'up' ? Colors.green : Colors.red;
  }

  IconData _getIconByTendencia(String tendencia) {
    return tendencia == 'up' ? Icons.trending_up : Icons.trending_down;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel de Análisis'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // Selector de período
          PopupMenuButton<String>(
            onSelected: (periodo) {
              setState(() {
                _periodoSeleccionado = periodo;
              });
              _cargarDatos();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'dia', child: Text('Hoy')),
              PopupMenuItem(value: 'semana', child: Text('Esta semana')),
              PopupMenuItem(value: 'mes', child: Text('Este mes')),
              PopupMenuItem(value: 'trimestre', child: Text('Trimestre')),
              PopupMenuItem(value: 'ano', child: Text('Año')),
            ],
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _periodoSeleccionado.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: Icon(Icons.dashboard), text: 'KPIs'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Ranking'),
            Tab(icon: Icon(Icons.notifications), text: 'Alertas'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(_error, textAlign: TextAlign.center),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarDatos,
                        child: Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildKPIsTab(),
                    _buildRankingTab(),
                    _buildAlertasTab(),
                  ],
                ),
    );
  }

  Widget _buildKPIsTab() {
    if (_kpis == null) return Center(child: Text('No hay datos de KPIs'));

    final kpis = _kpis!['kpis'] as Map<String, dynamic>;

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Header con período
          Card(
            color: Colors.deepPurple.shade50,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Período Analizado',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _kpis!['fecha_inicio'] != null && _kpis!['fecha_fin'] != null
                        ? '${DateTime.parse(_kpis!['fecha_inicio']).day}/${DateTime.parse(_kpis!['fecha_inicio']).month} - ${DateTime.parse(_kpis!['fecha_fin']).day}/${DateTime.parse(_kpis!['fecha_fin']).month}'
                        : 'Período no disponible',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Grid de KPIs
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildKPICard(
                'Visitas Programadas',
                (kpis['visitas_programadas']?['valor'] ?? 0).toString(),
                (kpis['visitas_programadas']?['cambio'] ?? 0).toDouble(),
                kpis['visitas_programadas']?['tendencia'] ?? 'estable',
                Icons.schedule,
                Colors.blue,
              ),
              _buildKPICard(
                'Visitas Completadas',
                (kpis['visitas_completadas']?['valor'] ?? 0).toString(),
                (kpis['visitas_completadas']?['cambio'] ?? 0).toDouble(),
                kpis['visitas_completadas']?['tendencia'] ?? 'estable',
                Icons.check_circle,
                Colors.green,
              ),
              _buildKPICard(
                'Tasa Cumplimiento',
                '${kpis['tasa_cumplimiento']?['valor'] ?? 0}%',
                (kpis['tasa_cumplimiento']?['cambio'] ?? 0).toDouble(),
                kpis['tasa_cumplimiento']?['tendencia'] ?? 'estable',
                Icons.trending_up,
                Colors.orange,
              ),
              _buildKPICard(
                'Sedes Activas',
                (kpis['sedes_activas']?['valor'] ?? 0).toString(),
                (kpis['sedes_activas']?['cambio'] ?? 0).toDouble(),
                kpis['sedes_activas']?['tendencia'] ?? 'estable',
                Icons.location_on,
                Colors.purple,
              ),
              _buildKPICard(
                'Visitadores Activos',
                (kpis['visitadores_activos']?['valor'] ?? 0).toString(),
                (kpis['visitadores_activos']?['cambio'] ?? 0).toDouble(),
                kpis['visitadores_activos']?['tendencia'] ?? 'estable',
                Icons.people,
                Colors.teal,
              ),
              _buildKPICard(
                'Promedio por Visitador',
                (kpis['promedio_visitas_visitador']?['valor'] ?? 0).toString(),
                (kpis['promedio_visitas_visitador']?['cambio'] ?? 0).toDouble(),
                kpis['promedio_visitas_visitador']?['tendencia'] ?? 'estable',
                Icons.person,
                Colors.indigo,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(String titulo, String valor, double cambio, String tendencia, IconData icono, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: color, size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              valor,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _getIconByTendencia(tendencia),
                  size: 16,
                  color: _getColorByTendencia(tendencia),
                ),
                SizedBox(width: 4),
                Text(
                  '${cambio >= 0 ? '+' : ''}${cambio.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getColorByTendencia(tendencia),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildRankingTab() {
    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ranking de Visitadores',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Últimos 30 días',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  _rankingVisitadores.isNotEmpty
                      ? ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _rankingVisitadores.length,
                          itemBuilder: (context, index) {
                            final visitador = _rankingVisitadores[index];
                            return Container(
                              margin: EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                                color: index < 3 ? Colors.yellow[50] : null,
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index < 3 ? Colors.yellow : Colors.grey[300],
                                  ),
                                  child: Center(
                                    child: Text(
                                      visitador['badge'] ?? '?',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  visitador['nombre'] ?? 'Sin nombre',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${visitador['visitas_completadas'] ?? 0}/${visitador['visitas_programadas'] ?? 0} visitas',
                                ),
                                trailing: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (visitador['tasa_cumplimiento'] ?? 0) > 80 
                                        ? Colors.green[100] 
                                        : Colors.orange[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${visitador['tasa_cumplimiento'] ?? 0}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: (visitador['tasa_cumplimiento'] ?? 0) > 80 
                                          ? Colors.green[800] 
                                          : Colors.orange[800],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : Center(child: Text('No hay datos de ranking')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertasTab() {
    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          if (_alertas.isEmpty)
            Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, size: 64, color: Colors.green),
                    SizedBox(height: 16),
                    Text(
                      '¡Todo en orden!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('No hay alertas críticas en este momento'),
                  ],
                ),
              ),
            )
          else
            ...(_alertas.map((alerta) => _buildAlertaCard(alerta)).toList()),
        ],
      ),
    );
  }

  Widget _buildAlertaCard(Map<String, dynamic> alerta) {
    Color color;
    IconData icono;

    switch (alerta['tipo']) {
      case 'critica':
        color = Colors.red;
        icono = Icons.error;
        break;
      case 'advertencia':
        color = Colors.orange;
        icono = Icons.warning;
        break;
      default:
        color = Colors.blue;
        icono = Icons.info;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icono, color: color),
        ),
        title: Text(
          alerta['titulo'] ?? 'Sin título',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(alerta['mensaje'] ?? 'Sin mensaje'),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Acción: ${alerta['accion'] ?? 'Sin acción'}'),
              backgroundColor: color,
            ),
          );
        },
      ),
    );
  }


}
