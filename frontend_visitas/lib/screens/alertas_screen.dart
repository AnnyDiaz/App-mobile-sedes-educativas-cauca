import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';

class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  final ApiService _apiService = ApiService();
  
  List<Map<String, dynamic>> _alertas = [];
  bool _isLoading = true;
  String? _error;
  String _filtroTipo = 'todos';

  @override
  void initState() {
    super.initState();
    _cargarAlertas();
  }

  Future<void> _cargarAlertas() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final alertas = await _apiService.getAlertasEquipo();
      
      setState(() {
        _alertas = alertas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _alertasFiltradas {
    if (_filtroTipo == 'todos') {
      return _alertas;
    }
    return _alertas.where((alerta) => (alerta['tipo'] as String? ?? '') == _filtroTipo).toList();
  }

  Color _getColorTipo(String tipo) {
    switch (tipo) {
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'info':
        return Colors.blue;
      case 'success':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconTipo(String tipo) {
    switch (tipo) {
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      case 'info':
        return Icons.info;
      case 'success':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  String _getTituloTipo(String tipo) {
    switch (tipo) {
      case 'warning':
        return 'Advertencia';
      case 'error':
        return 'Error';
      case 'info':
        return 'Información';
      case 'success':
        return 'Éxito';
      default:
        return 'Alerta';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas y Notificaciones'),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarAlertas,
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
            'Error al cargar alertas',
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
            onPressed: _cargarAlertas,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Filtros
        _buildFiltros(),
        
        // Resumen
        _buildResumen(),
        
        // Lista de alertas
        Expanded(
          child: _alertasFiltradas.isEmpty
              ? _buildEmptyState()
              : _buildListaAlertas(),
        ),
      ],
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _filtroTipo,
            items: [
              const DropdownMenuItem<String>(
                value: 'todos',
                child: Text('Todas las alertas'),
              ),
              const DropdownMenuItem<String>(
                value: 'warning',
                child: Text('Advertencias'),
              ),
              const DropdownMenuItem<String>(
                value: 'error',
                child: Text('Errores'),
              ),
              const DropdownMenuItem<String>(
                value: 'info',
                child: Text('Información'),
              ),
              const DropdownMenuItem<String>(
                value: 'success',
                child: Text('Éxitos'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _filtroTipo = value!;
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildResumen() {
    final totalAlertas = _alertasFiltradas.length;
    final alertasCriticas = _alertasFiltradas.where((a) => (a['tipo'] as String? ?? '') == 'error').length;
    final alertasAdvertencia = _alertasFiltradas.where((a) => (a['tipo'] as String? ?? '') == 'warning').length;
    final recordatorios = _alertasFiltradas.where((a) => (a['tipo'] as String? ?? '') == 'info').length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildResumenCard(
              title: 'Total',
              value: totalAlertas.toString(),
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildResumenCard(
              title: 'Críticas',
              value: alertasCriticas.toString(),
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildResumenCard(
              title: 'Atrasadas',
              value: alertasAdvertencia.toString(),
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildResumenCard(
              title: 'Recordatorios',
              value: recordatorios.toString(),
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay alertas para mostrar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta cambiar los filtros o no hay alertas activas',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListaAlertas() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _alertasFiltradas.length,
      itemBuilder: (context, index) {
        final alerta = _alertasFiltradas[index];
        return _buildAlertaCard(alerta);
      },
    );
  }

  Widget _buildAlertaCard(Map<String, dynamic> alerta) {
    final tipo = alerta['tipo'] as String? ?? 'info';
    final titulo = alerta['titulo'] as String? ?? 'Alerta';
    final descripcion = alerta['mensaje'] as String? ?? 'Sin descripción'; // Cambio: usar 'mensaje' en lugar de 'descripcion'
    
    // Parsear fecha de manera segura
    DateTime fecha;
    try {
      String? fechaStr = alerta['fecha_envio'] as String?; // Cambio: usar 'fecha_envio' en lugar de 'fecha_creacion'
      if (fechaStr != null) {
        fecha = DateTime.parse(fechaStr);
      } else {
        fecha = DateTime.now();
      }
    } catch (e) {
      fecha = DateTime.now();
    }
    
    final visitadorNombre = alerta['usuario']?['nombre'] as String? ?? 'Usuario'; // Cambio: acceder a usuario anidado
    final sedeNombre = 'Sistema'; // Cambio: simplificar ya que no viene del backend
    final prioridad = alerta['prioridad'] as String? ?? 'normal';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: _getColorTipo(tipo),
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con tipo y prioridad
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getColorTipo(tipo).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconTipo(tipo),
                          size: 16,
                          color: _getColorTipo(tipo),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getTituloTipo(tipo),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getColorTipo(tipo),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getColorPrioridad(prioridad).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      prioridad.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getColorPrioridad(prioridad),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Título de la alerta
              Text(
                titulo,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Descripción
              Text(
                descripcion,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Información adicional
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    visitadorNombre,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    sedeNombre,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              // Acciones
              if (alerta['acciones'] != null) ...[
                const SizedBox(height: 12),
                _buildAcciones(alerta['acciones']),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAcciones(List<dynamic> acciones) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones disponibles:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: acciones.map((accion) {
            return ActionChip(
              label: Text(accion['nombre']),
              onPressed: () => _ejecutarAccion(accion),
              backgroundColor: Colors.indigo[100],
              labelStyle: TextStyle(
                color: Colors.indigo[700],
                fontWeight: FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _ejecutarAccion(Map<String, dynamic> accion) {
    // Aquí se implementaría la lógica para ejecutar la acción
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ejecutando acción: ${accion['nombre']}'),
        backgroundColor: Colors.indigo[600],
      ),
    );
  }

  Color _getColorPrioridad(String prioridad) {
    switch (prioridad) {
      case 'alta':
        return Colors.red;
      case 'media':
        return Colors.orange;
      case 'baja':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
