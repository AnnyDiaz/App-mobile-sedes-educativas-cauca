import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';

class CronogramasSupervisorScreen extends StatefulWidget {
  const CronogramasSupervisorScreen({super.key});

  @override
  State<CronogramasSupervisorScreen> createState() => _CronogramasSupervisorScreenState();
}

class _CronogramasSupervisorScreenState extends State<CronogramasSupervisorScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _cronogramas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarCronogramas();
  }

  Future<void> _cargarCronogramas() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final cronogramas = await _apiService.getCronogramas();
      setState(() {
        _cronogramas = cronogramas;
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
        title: const Text('Cronogramas de Visitas'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarCronogramas,
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
            'Error al cargar cronogramas',
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
            onPressed: _cargarCronogramas,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Resumen de cronogramas
        _buildResumenCronogramas(),
        
        // Lista de cronogramas
        Expanded(
          child: _cronogramas.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cronogramas.length,
                  itemBuilder: (context, index) {
                    final cronograma = _cronogramas[index];
                    return _buildCronogramaCard(cronograma);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildResumenCronogramas() {
    final totalCronogramas = _cronogramas.length;
    final cronogramasActivos = _cronogramas.where((c) => c['estado'] == 'activo').length;
    final cronogramasCompletados = _cronogramas.where((c) => c['estado'] == 'completado').length;
    final cronogramasPendientes = _cronogramas.where((c) => c['estado'] == 'pendiente').length;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, size: 32, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen de Cronogramas',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Programación de visitas del sistema',
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
                  child: _buildStatItem('Total', totalCronogramas.toString(), Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem('Activos', cronogramasActivos.toString(), Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Completados', cronogramasCompletados.toString(), Colors.purple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem('Pendientes', cronogramasPendientes.toString(), Colors.orange),
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
        color: color.withOpacity(0.1),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay cronogramas registrados',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los cronogramas aparecerán aquí cuando se creen',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCronogramaCard(Map<String, dynamic> cronograma) {
    final fechaInicio = DateTime.parse(cronograma['fecha_inicio']);
    final fechaFin = DateTime.parse(cronograma['fecha_fin']);
    final estado = cronograma['estado'] ?? 'pendiente';
    final operador = cronograma['operador'] ?? 'Sin operador';
    final contrato = cronograma['contrato'] ?? 'Sin contrato';

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
                Icon(
                  _getIconForEstado(estado),
                  color: _getColorForEstado(estado),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cronograma ${cronograma['id']}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Operador: $operador',
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
                    color: _getColorForEstado(estado).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    estado.toUpperCase(),
                    style: TextStyle(
                      color: _getColorForEstado(estado),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contrato: $contrato',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Inicio: ${_formatDate(fechaInicio)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Fin: ${_formatDate(fechaFin)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Duración: ${_calcularDuracion(fechaInicio, fechaFin)} días',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (cronograma['visitas_programadas'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.assignment, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${cronograma['visitas_programadas']} visitas programadas',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            if (cronograma['visitas_completadas'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      '${cronograma['visitas_completadas']} visitas completadas',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green[600],
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

  IconData _getIconForEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return Icons.play_circle_outline;
      case 'completado':
        return Icons.check_circle;
      case 'pendiente':
        return Icons.schedule;
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }

  Color _getColorForEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return Colors.green;
      case 'completado':
        return Colors.blue;
      case 'pendiente':
        return Colors.orange;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  int _calcularDuracion(DateTime inicio, DateTime fin) {
    return fin.difference(inicio).inDays;
  }
} 