import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';

class NotificacionesSupervisorScreen extends StatefulWidget {
  const NotificacionesSupervisorScreen({super.key});

  @override
  State<NotificacionesSupervisorScreen> createState() => _NotificacionesSupervisorScreenState();
}

class _NotificacionesSupervisorScreenState extends State<NotificacionesSupervisorScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _alertas = [];
  List<Map<String, dynamic>> _inconsistencias = [];
  List<Map<String, dynamic>> _vencimientos = [];
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

      final futures = await Future.wait([
        _apiService.getAlertasSistema(),
        _apiService.getInconsistenciasDatos(),
        _apiService.getVencimientosCronogramas(),
      ]);

      setState(() {
        _alertas = futures[0] as List<Map<String, dynamic>>;
        _inconsistencias = futures[1] as List<Map<String, dynamic>>;
        _vencimientos = futures[2] as List<Map<String, dynamic>>;
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
        title: const Text('Alertas del Sistema'),
        backgroundColor: Colors.purple[600],
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

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen de alertas
          _buildResumenAlertas(),
          const SizedBox(height: 24),
          
          // Alertas del sistema
          _buildAlertasSistema(),
          const SizedBox(height: 24),
          
          // Inconsistencias en datos
          _buildInconsistenciasDatos(),
          const SizedBox(height: 24),
          
          // Vencimientos de cronogramas
          _buildVencimientosCronogramas(),
        ],
      ),
    );
  }

  Widget _buildResumenAlertas() {
    final totalAlertas = _alertas.length + _inconsistencias.length + _vencimientos.length;
    final alertasUrgentes = _alertas.where((a) => a['prioridad'] == 'urgente').length;
    final alertasAltas = _alertas.where((a) => a['prioridad'] == 'alta').length;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, size: 32, color: Colors.red),
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
                        'Estado del sistema y alertas',
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
                  child: _buildStatItem('Total', totalAlertas.toString(), Colors.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem('Urgentes', alertasUrgentes.toString(), Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Altas', alertasAltas.toString(), Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem('Sistema', 'OK', Colors.green),
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

  Widget _buildAlertasSistema() {
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
                  'Alertas del Sistema',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_alertas.isEmpty)
              _buildEmptyState('No hay alertas del sistema', Icons.check_circle)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _alertas.length,
                itemBuilder: (context, index) {
                  final alerta = _alertas[index];
                  return _buildAlertaCard(alerta, 'sistema');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInconsistenciasDatos() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Inconsistencias en Datos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_inconsistencias.isEmpty)
              _buildEmptyState('No hay inconsistencias detectadas', Icons.check_circle)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _inconsistencias.length,
                itemBuilder: (context, index) {
                  final inconsistencia = _inconsistencias[index];
                  return _buildAlertaCard(inconsistencia, 'inconsistencia');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVencimientosCronogramas() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Vencimientos de Cronogramas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_vencimientos.isEmpty)
              _buildEmptyState('No hay vencimientos próximos', Icons.check_circle)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _vencimientos.length,
                itemBuilder: (context, index) {
                  final vencimiento = _vencimientos[index];
                  return _buildAlertaCard(vencimiento, 'vencimiento');
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

  Widget _buildAlertaCard(Map<String, dynamic> alerta, String tipo) {
    Color color;
    IconData icon;
    
    switch (tipo) {
      case 'sistema':
        color = Colors.red;
        icon = Icons.warning;
        break;
      case 'inconsistencia':
        color = Colors.orange;
        icon = Icons.error_outline;
        break;
      case 'vencimiento':
        color = Colors.purple;
        icon = Icons.schedule;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alerta['titulo'] ?? 'Alerta sin título',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    alerta['mensaje'] ?? 'Sin descripción',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (alerta['fecha'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatDateTime(DateTime.parse(alerta['fecha'])),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getPriorityColor(alerta['prioridad']).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                (alerta['prioridad'] ?? 'media').toUpperCase(),
                style: TextStyle(
                  color: _getPriorityColor(alerta['prioridad']),
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

  Color _getPriorityColor(String? prioridad) {
    switch (prioridad?.toLowerCase()) {
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
    final diferencia = ahora.difference(dateTime);
    
    if (diferencia.inDays > 0) {
      return 'Hace ${diferencia.inDays} días';
    } else if (diferencia.inHours > 0) {
      return 'Hace ${diferencia.inHours} horas';
    } else if (diferencia.inMinutes > 0) {
      return 'Hace ${diferencia.inMinutes} minutos';
    } else {
      return 'Ahora';
    }
  }
} 