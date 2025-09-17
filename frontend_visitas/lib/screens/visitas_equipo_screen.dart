import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';

class VisitasEquipoScreen extends StatefulWidget {
  const VisitasEquipoScreen({super.key});

  @override
  State<VisitasEquipoScreen> createState() => _VisitasEquipoScreenState();
}

class _VisitasEquipoScreenState extends State<VisitasEquipoScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _visitasEquipo = [];
  bool _isLoading = true;
  String? _error;
  String _filtroEstado = 'todos';
  String _filtroVisitador = 'todos';

  @override
  void initState() {
    super.initState();
    _cargarVisitasEquipo();
  }

  Future<void> _cargarVisitasEquipo() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final visitas = await _apiService.getVisitasEquipo();
      
      setState(() {
        _visitasEquipo = visitas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _visitasFiltradas {
    List<Map<String, dynamic>> visitas = _visitasEquipo;

    // Filtrar por estado
    if (_filtroEstado != 'todos') {
      visitas = visitas.where((visita) => visita['estado'] == _filtroEstado).toList();
    }

    // Filtrar por visitador
    if (_filtroVisitador != 'todos') {
      visitas = visitas.where((visita) => visita['visitador_id'] == int.parse(_filtroVisitador)).toList();
    }

    return visitas;
  }

  List<String> get _estadosUnicos {
    final estados = _visitasEquipo.map((visita) => visita['estado'] as String).toSet().toList();
    estados.sort();
    return ['todos', ...estados];
  }

  List<Map<String, dynamic>> get _visitadoresUnicos {
    final visitadores = <Map<String, dynamic>>[];
    final idsVisitadores = <int>{};

    for (final visita in _visitasEquipo) {
      final visitadorId = visita['visitador_id'];
      if (visitadorId != null && visitadorId is int && !idsVisitadores.contains(visitadorId)) {
        idsVisitadores.add(visitadorId);
        visitadores.add({
          'id': visitadorId,
          'nombre': visita['visitador_nombre'] ?? 'Visitador $visitadorId',
        });
      }
    }

    visitadores.sort((a, b) => (a['nombre'] as String).compareTo(b['nombre'] as String));
    return [{'id': 'todos', 'nombre': 'Todos'}, ...visitadores];
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
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

  IconData _getIconEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Icons.pending_actions;
      case 'en_proceso':
        return Icons.play_circle_outline;
      case 'completada':
        return Icons.check_circle;
      case 'cancelada':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitas de mi Equipo'),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarVisitasEquipo,
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
            'Error al cargar visitas',
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
            onPressed: _cargarVisitasEquipo,
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
        
        // Lista de visitas
        Expanded(
          child: _visitasFiltradas.isEmpty
              ? _buildEmptyState()
              : _buildListaVisitas(),
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
          Row(
            children: [
              Expanded(
                child: _buildDropdownFiltro(
                  label: 'Estado',
                  value: _filtroEstado,
                  items: _estadosUnicos.map((estado) {
                    return DropdownMenuItem<String>(
                      value: estado,
                      child: Text(estado == 'todos' ? 'Todos los estados' : estado),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _filtroEstado = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownFiltro(
                  label: 'Visitador',
                  value: _filtroVisitador,
                  items: _visitadoresUnicos.map((visitador) {
                    return DropdownMenuItem<String>(
                      value: visitador['id'].toString(),
                      child: Text(visitador['nombre']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _filtroVisitador = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFiltro({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildResumen() {
    final totalVisitas = _visitasFiltradas.length;
    final visitasPendientes = _visitasFiltradas.where((v) => v['estado'] == 'pendiente').length;
    final visitasEnProceso = _visitasFiltradas.where((v) => v['estado'] == 'en_proceso').length;
    final visitasCompletadas = _visitasFiltradas.where((v) => v['estado'] == 'completada').length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildResumenCard(
              title: 'Total',
              value: totalVisitas.toString(),
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildResumenCard(
              title: 'Pendientes',
              value: visitasPendientes.toString(),
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildResumenCard(
              title: 'En Proceso',
              value: visitasEnProceso.toString(),
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildResumenCard(
              title: 'Completadas',
              value: visitasCompletadas.toString(),
              color: Colors.green,
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
          Icon(Icons.group, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay visitas para mostrar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta cambiar los filtros o no hay visitas asignadas a tu equipo',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListaVisitas() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _visitasFiltradas.length,
      itemBuilder: (context, index) {
        final visita = _visitasFiltradas[index];
        return _buildVisitaCard(visita);
      },
    );
  }

  Widget _buildVisitaCard(Map<String, dynamic> visita) {
    final estado = visita['estado'] as String;
    final fechaProgramada = DateTime.parse(visita['fecha_programada']);
    final visitadorNombre = visita['visitador_nombre'] ?? 'Visitador';
    final sedeNombre = visita['sede_nombre'] ?? 'Sede';
    final municipioNombre = visita['municipio_nombre'] ?? 'Municipio';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estado y visitador
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getColorEstado(estado).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getColorEstado(estado)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getIconEstado(estado),
                        size: 16,
                        color: _getColorEstado(estado),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        estado.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getColorEstado(estado),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Por: $visitadorNombre',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Información de la visita
            Text(
              sedeNombre,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  municipioNombre,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                  'Programada: ${fechaProgramada.day}/${fechaProgramada.month}/${fechaProgramada.year}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            if (visita['observaciones'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Observaciones: ${visita['observaciones']}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
