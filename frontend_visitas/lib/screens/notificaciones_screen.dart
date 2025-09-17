import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/models/visita.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  final ApiService _apiService = ApiService();
  List<Visita> _visitasPendientes = [];
  List<Map<String, dynamic>> _recordatorios = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Cargar visitas pendientes
      final visitasPendientes = await _apiService.getMisVisitasPorEstado('pendiente');
      
      // Generar recordatorios basados en las visitas
      final recordatorios = _generarRecordatorios(visitasPendientes);

      setState(() {
        _visitasPendientes = visitasPendientes;
        _recordatorios = recordatorios;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _generarRecordatorios(List<Visita> visitas) {
    final recordatorios = <Map<String, dynamic>>[];
    final ahora = DateTime.now();

    for (final visita in visitas) {
      if (visita.fechaCreacion != null) {
        final diferencia = visita.fechaCreacion!.difference(ahora);
        
        // Recordatorio para visitas próximas (dentro de 24 horas)
        if (diferencia.inHours <= 24 && diferencia.inHours > 0) {
          recordatorios.add({
            'tipo': 'visita_proxima',
            'titulo': 'Visita próxima',
            'mensaje': 'Tienes una visita programada en ${diferencia.inHours} horas',
            'visita': visita,
            'prioridad': 'alta',
            'icono': Icons.schedule,
            'color': Colors.orange,
          });
        }
        
        // Recordatorio para visitas vencidas
        if (diferencia.isNegative && diferencia.inDays.abs() <= 7) {
          recordatorios.add({
            'tipo': 'visita_vencida',
            'titulo': 'Visita vencida',
            'mensaje': 'Visita vencida hace ${diferencia.inDays.abs()} días',
            'visita': visita,
            'prioridad': 'urgente',
            'icono': Icons.warning,
            'color': Colors.red,
          });
        }
      }
    }

    // Recordatorios generales
    if (visitas.isEmpty) {
      recordatorios.add({
        'tipo': 'sin_visitas',
        'titulo': 'Sin visitas pendientes',
        'mensaje': 'No tienes visitas pendientes en este momento',
        'prioridad': 'info',
        'icono': Icons.check_circle,
        'color': Colors.green,
      });
    } else {
      recordatorios.add({
        'tipo': 'resumen',
        'titulo': 'Resumen de visitas',
        'mensaje': 'Tienes ${visitas.length} visita(s) pendiente(s)',
        'prioridad': 'info',
        'icono': Icons.assessment,
        'color': Colors.blue,
      });
    }

    return recordatorios;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarNotificaciones,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildNotificationsContent(),
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
            'Error al cargar notificaciones',
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
            onPressed: _cargarNotificaciones,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen de alertas
          _buildAlertSummary(),
          const SizedBox(height: 24),
          
          // Lista de recordatorios
          _buildRemindersList(),
          const SizedBox(height: 24),
          
          // Lista de visitas pendientes
          _buildPendingVisitsList(),
        ],
      ),
    );
  }

  Widget _buildAlertSummary() {
    final urgentes = _recordatorios.where((r) => r['prioridad'] == 'urgente').length;
    final altas = _recordatorios.where((r) => r['prioridad'] == 'alta').length;
    final total = _recordatorios.length;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active, size: 32, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen de Alertas',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$total notificación(es)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildAlertStat('Urgentes', urgentes, Colors.red),
                const SizedBox(width: 16),
                _buildAlertStat('Altas', altas, Colors.orange),
                const SizedBox(width: 16),
                _buildAlertStat('Total', total, Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertStat(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recordatorios',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recordatorios.length,
          itemBuilder: (context, index) {
            final recordatorio = _recordatorios[index];
            return _buildReminderCard(recordatorio);
          },
        ),
      ],
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> recordatorio) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: recordatorio['color'].withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                recordatorio['icono'],
                color: recordatorio['color'],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recordatorio['titulo'],
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recordatorio['mensaje'],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPriorityColor(recordatorio['prioridad']).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                recordatorio['prioridad'].toUpperCase(),
                style: TextStyle(
                  color: _getPriorityColor(recordatorio['prioridad']),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingVisitsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visitas Pendientes',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_visitasPendientes.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 64,
                      color: Colors.green[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay visitas pendientes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¡Excelente trabajo!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _visitasPendientes.length,
            itemBuilder: (context, index) {
              final visita = _visitasPendientes[index];
              return _buildPendingVisitCard(visita);
            },
          ),
      ],
    );
  }

  Widget _buildPendingVisitCard(Visita visita) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pending_actions, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visita.tipoAsunto ?? 'Visita sin tipo',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (visita.sede != null)
                        Text(
                          visita.sede!.nombre,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PENDIENTE',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (visita.observaciones != null && visita.observaciones!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  visita.observaciones!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            if (visita.fechaCreacion != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(visita.fechaCreacion!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  Color _getPriorityColor(String prioridad) {
    switch (prioridad) {
      case 'urgente':
        return Colors.red;
      case 'alta':
        return Colors.orange;
      case 'media':
        return Colors.yellow[700]!;
      case 'baja':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final ahora = DateTime.now();
    final diferencia = dateTime.difference(ahora);
    
    if (diferencia.isNegative) {
      return 'Vencida hace ${diferencia.inDays.abs()} días';
    } else if (diferencia.inDays > 0) {
      return 'En ${diferencia.inDays} días';
    } else if (diferencia.inHours > 0) {
      return 'En ${diferencia.inHours} horas';
    } else {
      return 'Próximamente';
    }
  }
} 