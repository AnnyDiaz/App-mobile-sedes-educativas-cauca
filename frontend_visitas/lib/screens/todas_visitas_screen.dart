import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/models/visita.dart';
import 'package:frontend_visitas/models/municipio.dart';
import 'package:frontend_visitas/models/institucion.dart';

class TodasVisitasScreen extends StatefulWidget {
  const TodasVisitasScreen({super.key});

  @override
  State<TodasVisitasScreen> createState() => _TodasVisitasScreenState();
}

class _TodasVisitasScreenState extends State<TodasVisitasScreen> {
  final ApiService _apiService = ApiService();
  List<Visita> _visitas = [];
  List<Municipio> _municipios = [];
  List<Institucion> _instituciones = [];
  List<String> _estados = ['Todos', 'Pendiente', 'En Proceso', 'Completada', 'Cancelada'];
  
  String? _municipioSeleccionado;
  String? _institucionSeleccionada;
  String? _estadoSeleccionado;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  
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

      final futures = await Future.wait([
        _apiService.getTodasVisitas(),
        _apiService.getMunicipios(),
        _apiService.getInstituciones(),
      ]);

      setState(() {
        _visitas = futures[0] as List<Visita>;
        _municipios = futures[1] as List<Municipio>;
        _instituciones = futures[2] as List<Institucion>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Visita> _filtrarVisitas() {
    return _visitas.where((visita) {
      // Filtro por municipio
      if (_municipioSeleccionado != null && 
          visita.sede?.municipio?.nombre != _municipioSeleccionado) {
        return false;
      }
      
      // Filtro por institución
      if (_institucionSeleccionada != null && 
          visita.sede?.institucion?.nombre != _institucionSeleccionada) {
        return false;
      }
      
      // Filtro por estado
      if (_estadoSeleccionado != null && 
          _estadoSeleccionado != 'Todos' &&
          visita.estado != _estadoSeleccionado) {
        return false;
      }
      
      // Filtro por fecha
      if (_fechaInicio != null && visita.fechaCreacion != null) {
        if (visita.fechaCreacion!.isBefore(_fechaInicio!)) {
          return false;
        }
      }
      
      if (_fechaFin != null && visita.fechaCreacion != null) {
        if (visita.fechaCreacion!.isAfter(_fechaFin!)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todas las Visitas'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
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
            onPressed: _cargarDatos,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final visitasFiltradas = _filtrarVisitas();
    
    return Column(
      children: [
        // Filtros
        _buildFiltros(),
        
        // Contador de resultados
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.filter_list, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                '${visitasFiltradas.length} visitas encontradas',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        // Lista de visitas
        Expanded(
          child: visitasFiltradas.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: visitasFiltradas.length,
                  itemBuilder: (context, index) {
                    final visita = visitasFiltradas[index];
                    return _buildVisitaCard(visita);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFiltros() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Filtro por municipio
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Municipio',
                border: OutlineInputBorder(),
              ),
              value: _municipioSeleccionado,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                ..._municipios.map((municipio) => DropdownMenuItem(
                  value: municipio.nombre,
                  child: Text(municipio.nombre),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _municipioSeleccionado = value;
                });
              },
            ),
            const SizedBox(height: 12),
            
            // Filtro por institución
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Institución',
                border: OutlineInputBorder(),
              ),
              value: _institucionSeleccionada,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ..._instituciones.map((institucion) => DropdownMenuItem(
                  value: institucion.nombre,
                  child: Text(institucion.nombre),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _institucionSeleccionada = value;
                });
              },
            ),
            const SizedBox(height: 12),
            
            // Filtro por estado
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
              ),
              value: _estadoSeleccionado,
              items: _estados.map((estado) => DropdownMenuItem(
                value: estado == 'Todos' ? null : estado,
                child: Text(estado),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _estadoSeleccionado = value;
                });
              },
            ),
            const SizedBox(height: 12),
            
            // Botón para limpiar filtros
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _municipioSeleccionado = null;
                    _institucionSeleccionada = null;
                    _estadoSeleccionado = null;
                    _fechaInicio = null;
                    _fechaFin = null;
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text('Limpiar Filtros'),
              ),
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
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron visitas',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta ajustar los filtros',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitaCard(Visita visita) {
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
                  _getIconForEstado(visita.estado),
                  color: _getColorForEstado(visita.estado),
                  size: 24,
                ),
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
                          '${visita.sede!.nombre} - ${visita.sede!.municipio?.nombre ?? ''}',
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
                    color: _getColorForEstado(visita.estado).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    visita.estado ?? 'Sin estado',
                    style: TextStyle(
                      color: _getColorForEstado(visita.estado),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (visita.usuario != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Responsable: ${visita.usuario!.nombre}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            if (visita.fechaCreacion != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
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
          ],
        ),
      ),
    );
  }

  IconData _getIconForEstado(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'pendiente':
        return Icons.pending_actions;
      case 'en_proceso':
        return Icons.play_circle_outline;
      case 'completada':
        return Icons.check_circle;
      case 'cancelada':
        return Icons.cancel;
      default:
        return Icons.event;
    }
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 