import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/models/visita.dart';

class ActividadRecienteScreen extends StatefulWidget {
  const ActividadRecienteScreen({super.key});

  @override
  State<ActividadRecienteScreen> createState() => _ActividadRecienteScreenState();
}

class _ActividadRecienteScreenState extends State<ActividadRecienteScreen> {
  final ApiService _apiService = ApiService();
  List<Visita> _ultimasVisitas = [];
  List<Visita> _visitasPendientes = [];
  List<Visita> _visitasSinEvidencia = [];
  Map<String, dynamic>? _estadisticas;
  List<Map<String, dynamic>> _actividadReciente = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarActividad();
  }

  Future<void> _cargarActividad() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Cargar datos de forma individual para manejar errores específicos
      try {
        _ultimasVisitas = await _apiService.getUltimasVisitas();
      } catch (e) {
        print('Error cargando últimas visitas: $e');
        _ultimasVisitas = [];
      }

      try {
        _visitasPendientes = await _apiService.getVisitasPendientes();
      } catch (e) {
        print('Error cargando visitas pendientes: $e');
        _visitasPendientes = [];
      }

      try {
        _visitasSinEvidencia = await _apiService.getVisitasSinEvidencia();
      } catch (e) {
        print('Error cargando visitas sin evidencia: $e');
        _visitasSinEvidencia = [];
      }

      try {
        final estadisticasData = await _apiService.getEstadisticasActividad();
        _estadisticas = estadisticasData['estadisticas'] as Map<String, dynamic>?;
        _actividadReciente = (estadisticasData['ultimas_visitas'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ?? [];
      } catch (e) {
        print('Error cargando estadísticas: $e');
        _estadisticas = {
          'total_visitas': 0,
          'visitas_hoy': 0,
          'usuarios_activos': 0,
        };
        _actividadReciente = [];
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actividad Reciente'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarActividad,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildContent(),
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
            'Error al cargar actividad',
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
            onPressed: _cargarActividad,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen de actividad
          _buildResumenActividad(),
          const SizedBox(height: 24),
          
          // Actividad reciente del sistema
          _buildActividadReciente(),
          const SizedBox(height: 24),
          
          // Últimas visitas iniciadas
          _buildUltimasVisitas(),
          const SizedBox(height: 24),
          
          // Visitas pendientes
          _buildVisitasPendientes(),
          const SizedBox(height: 24),
          
          // Visitas sin evidencia
          _buildVisitasSinEvidencia(),
        ],
      ),
    );
  }

  Widget _buildResumenActividad() {
    final totalVisitas = _estadisticas?['total_visitas'] ?? 0;
    final visitasHoy = _estadisticas?['visitas_hoy'] ?? 0;
    final usuariosActivos = _estadisticas?['usuarios_activos'] ?? 0;
    final visitasPendientes = _visitasPendientes.length;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline, size: 32, color: Colors.purple),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen de Actividad',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Actividad reciente del sistema',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Total', totalVisitas.toString(), Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem('Hoy', visitasHoy.toString(), Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Usuarios Activos', usuariosActivos.toString(), Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem('Pendientes', visitasPendientes.toString(), Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActividadReciente() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Actividad Reciente del Sistema',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_actividadReciente.isEmpty)
              _buildEmptyState('No hay actividad reciente', Icons.history)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _actividadReciente.length,
                itemBuilder: (context, index) {
                  final visita = _actividadReciente[index];
                  return _buildVisitaItemFromMap(visita, 'reciente');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUltimasVisitas() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.recent_actors, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Últimas Visitas Iniciadas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_ultimasVisitas.isEmpty)
              _buildEmptyState('No hay visitas recientes', Icons.history)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _ultimasVisitas.length,
                itemBuilder: (context, index) {
                  final visita = _ultimasVisitas[index];
                  return _buildVisitaItemFromModel(visita, 'reciente');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitasPendientes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pending_actions, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Visitas Pendientes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_visitasPendientes.isEmpty)
              _buildEmptyState('No hay visitas pendientes', Icons.check_circle)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _visitasPendientes.length,
                itemBuilder: (context, index) {
                  final visita = _visitasPendientes[index];
                  return _buildVisitaItemFromModel(visita, 'pendiente');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitasSinEvidencia() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Visitas Sin Evidencia',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_visitasSinEvidencia.isEmpty)
              _buildEmptyState('Todas las visitas tienen evidencia', Icons.check_circle)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _visitasSinEvidencia.length,
                itemBuilder: (context, index) {
                  final visita = _visitasSinEvidencia[index];
                  return _buildVisitaItemFromModel(visita, 'sin-evidencia');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitaItemFromModel(Visita visita, String tipo) {
    Color color;
    IconData icon;

    switch (tipo) {
      case 'reciente':
        color = Colors.blue;
        icon = Icons.access_time;
        break;
      case 'pendiente':
        color = Colors.orange;
        icon = Icons.pending_actions;
        break;
      case 'sin-evidencia':
        color = Colors.red;
        icon = Icons.warning;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visita.tipoAsunto ?? 'Visita sin tipo',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (visita.sede != null)
                  Text(
                    visita.sede!.nombre,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                if (visita.usuario != null)
                  Text(
                    'Por: ${visita.usuario!.nombre}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getColorForEstado(visita.estado).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  visita.estado ?? 'Sin estado',
                  style: TextStyle(
                    color: _getColorForEstado(visita.estado),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (visita.fechaCreacion != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTimeAgo(visita.fechaCreacion!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisitaItemFromMap(Map<String, dynamic> visita, String tipo) {
    Color color;
    IconData icon;

    switch (tipo) {
      case 'reciente':
        color = Colors.blue;
        icon = Icons.access_time;
        break;
      case 'pendiente':
        color = Colors.orange;
        icon = Icons.pending_actions;
        break;
      case 'sin-evidencia':
        color = Colors.red;
        icon = Icons.warning;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visita['tipo_asunto'] ?? 'Visita sin tipo',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (visita['sede'] != null)
                  Text(
                    visita['sede'] is String 
                        ? visita['sede'] 
                        : (visita['sede'] is Map ? visita['sede']['nombre'] ?? '' : ''),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                if (visita['profesional'] != null)
                  Text(
                    'Por: ${visita['profesional'] is String 
                        ? visita['profesional'] 
                        : (visita['profesional'] is Map ? visita['profesional']['nombre'] ?? '' : '')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getColorForEstado(visita['estado']).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  visita['estado'] ?? 'Sin estado',
                  style: TextStyle(
                    color: _getColorForEstado(visita['estado']),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (visita['fecha_creacion'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTimeAgo(visita['fecha_creacion']),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColorForEstado(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'en_proceso':
        return Colors.blue;
      case 'completada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTimeAgo(dynamic dateTime) {
    if (dateTime == null) return 'Sin fecha';
    
    DateTime date;
    if (dateTime is DateTime) {
      date = dateTime;
    } else if (dateTime is String) {
      try {
        date = DateTime.parse(dateTime);
      } catch (e) {
        return 'Fecha inválida';
      }
    } else {
      return 'Sin fecha';
    }
    
    final ahora = DateTime.now();
    final diferencia = ahora.difference(date);
    
    if (diferencia.inDays > 0) {
      return '${diferencia.inDays} día${diferencia.inDays > 1 ? 's' : ''}';
    } else if (diferencia.inHours > 0) {
      return '${diferencia.inHours} hora${diferencia.inHours > 1 ? 's' : ''}';
    } else if (diferencia.inMinutes > 0) {
      return '${diferencia.inMinutes} minuto${diferencia.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Ahora';
    }
  }
} 