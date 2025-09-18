import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/models/visita.dart';

class VisitasCompletasScreen extends StatefulWidget {
  const VisitasCompletasScreen({super.key});

  @override
  State<VisitasCompletasScreen> createState() => _VisitasCompletasScreenState();
}

class _VisitasCompletasScreenState extends State<VisitasCompletasScreen> {
  final ApiService _apiService = ApiService();
  List<Visita> _visitas = [];
  bool _isLoading = true;
  String? _error;
  
  // Filtros
  String? _contratoFiltro;
  String? _operadorFiltro;
  String? _estadoFiltro;
  String? _fechaInicioFiltro;
  String? _fechaFinFiltro;
  
  // Opciones de filtros
  List<String> _contratos = [];
  List<String> _operadores = [];
  List<String> _estados = [];
  bool _filtrosCargados = false;

  @override
  void initState() {
    super.initState();
    _cargarOpcionesFiltros();
    _cargarVisitasCompletas();
  }

  Future<void> _cargarOpcionesFiltros() async {
    try {
      final opciones = await _apiService.getOpcionesFiltrosVisitas();
      setState(() {
        _contratos = opciones['contratos'] ?? [];
        _operadores = opciones['operadores'] ?? [];
        _estados = opciones['estados'] ?? [];
        _filtrosCargados = true;
      });
    } catch (e) {
      print('Error al cargar opciones de filtros: $e');
    }
  }

  Future<void> _cargarVisitasCompletas() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Usar el endpoint con filtros
      final visitas = await _apiService.getVisitasCompletas(
        contrato: _contratoFiltro,
        operador: _operadorFiltro,
        estado: _estadoFiltro,
        fechaInicio: _fechaInicioFiltro,
        fechaFin: _fechaFinFiltro,
      );
      
      setState(() {
        _visitas = visitas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error al cargar visitas: $e';
      });
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _contratoFiltro = null;
      _operadorFiltro = null;
      _estadoFiltro = null;
      _fechaInicioFiltro = null;
      _fechaFinFiltro = null;
    });
    _cargarVisitasCompletas();
  }

  bool _tieneFiltrosActivos() {
    return _contratoFiltro != null ||
           _operadorFiltro != null ||
           _estadoFiltro != null ||
           _fechaInicioFiltro != null ||
           _fechaFinFiltro != null;
  }

  Future<void> _descargarExcel(int visitaId) async {
    try {
      await _apiService.descargarExcelVisita(visitaId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel descargado exitosamente para visita #$visitaId'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al descargar Excel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _descargarVisitasFiltradas() async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generando reporte con filtros...'),
            ],
          ),
        ),
      );

      // Generar reporte con los filtros aplicados
      final reporteData = {
        'fecha_inicio': _fechaInicioFiltro,
        'fecha_fin': _fechaFinFiltro,
        'municipio_id': null, // No implementado en filtros actuales
        'institucion_id': null, // No implementado en filtros actuales
        'estado': _estadoFiltro,
        'tipo_reporte': 'excel',
      };

      // Llamar al endpoint de reportes
      final response = await _apiService.generarReporte(reporteData);
      
      // Cerrar diálogo de carga
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Reporte descargado exitosamente con filtros aplicados'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Cerrar diálogo de carga si está abierto
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al descargar reporte: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitas Completas PAE'),
        centerTitle: true,
        actions: [
          // Botón para descargar visitas filtradas
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _descargarVisitasFiltradas,
            tooltip: 'Descargar visitas filtradas',
          ),
          
          if (_tieneFiltrosActivos())
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _limpiarFiltros,
              tooltip: 'Limpiar filtros',
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarFiltros,
            tooltip: 'Filtros',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarVisitasCompletas,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_tieneFiltrosActivos()) _buildFiltrosActivos(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  void _mostrarFiltros() {
    showDialog(
      context: context,
      builder: (context) => _buildFiltrosModal(),
    );
  }

  Widget _buildFiltrosModal() {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.search, color: Colors.blue[600]),
          const SizedBox(width: 8),
          const Text('Buscador de Visitas'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtra las visitas por contrato, operador, estado o fechas:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            
            // Filtro por Contrato
            DropdownButtonFormField<String>(
              value: _contratoFiltro,
              decoration: const InputDecoration(
                labelText: 'Contrato',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Todos los contratos'),
                ),
                ..._contratos.map((contrato) => DropdownMenuItem<String>(
                  value: contrato,
                  child: Text(contrato),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _contratoFiltro = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Filtro por Operador
            DropdownButtonFormField<String>(
              value: _operadorFiltro,
              decoration: const InputDecoration(
                labelText: 'Operador',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Todos los operadores'),
                ),
                ..._operadores.map((operador) => DropdownMenuItem<String>(
                  value: operador,
                  child: Text(operador),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _operadorFiltro = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Filtro por Estado
            DropdownButtonFormField<String>(
              value: _estadoFiltro,
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Todos los estados'),
                ),
                ..._estados.map((estado) => DropdownMenuItem<String>(
                  value: estado,
                  child: Text(estado),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _estadoFiltro = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Filtro por Fecha Inicio
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Fecha Inicio (YYYY-MM-DD)',
                border: OutlineInputBorder(),
                hintText: '2024-01-01',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              initialValue: _fechaInicioFiltro,
              onChanged: (value) {
                _fechaInicioFiltro = value.isEmpty ? null : value;
              },
            ),
            const SizedBox(height: 16),
            
            // Filtro por Fecha Fin
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Fecha Fin (YYYY-MM-DD)',
                border: OutlineInputBorder(),
                hintText: '2024-12-31',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              initialValue: _fechaFinFiltro,
              onChanged: (value) {
                _fechaFinFiltro = value.isEmpty ? null : value;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _limpiarFiltros,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[600],
            foregroundColor: Colors.white,
          ),
          child: const Text('Limpiar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _cargarVisitasCompletas();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
          ),
          child: const Text('Aplicar Filtros'),
        ),
      ],
    );
  }

  Widget _buildFiltrosActivos() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.blue.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros activos:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (_contratoFiltro != null)
                Chip(
                  label: Text('Contrato: $_contratoFiltro'),
                  onDeleted: () {
                    setState(() {
                      _contratoFiltro = null;
                    });
                    _cargarVisitasCompletas();
                  },
                ),
              if (_operadorFiltro != null)
                Chip(
                  label: Text('Operador: $_operadorFiltro'),
                  onDeleted: () {
                    setState(() {
                      _operadorFiltro = null;
                    });
                    _cargarVisitasCompletas();
                  },
                ),
              if (_estadoFiltro != null)
                Chip(
                  label: Text('Estado: $_estadoFiltro'),
                  onDeleted: () {
                    setState(() {
                      _estadoFiltro = null;
                    });
                    _cargarVisitasCompletas();
                  },
                ),
              if (_fechaInicioFiltro != null)
                Chip(
                  label: Text('Desde: $_fechaInicioFiltro'),
                  onDeleted: () {
                    setState(() {
                      _fechaInicioFiltro = null;
                    });
                    _cargarVisitasCompletas();
                  },
                ),
              if (_fechaFinFiltro != null)
                Chip(
                  label: Text('Hasta: $_fechaFinFiltro'),
                  onDeleted: () {
                    setState(() {
                      _fechaFinFiltro = null;
                    });
                    _cargarVisitasCompletas();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando visitas completas...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarVisitasCompletas,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_visitas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, color: Colors.grey, size: 64),
            SizedBox(height: 16),
            Text(
              'No hay visitas completas registradas',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _visitas.length,
      itemBuilder: (context, index) {
        final visita = _visitas[index];
        return _buildVisitaCard(visita);
      },
    );
  }

  Widget _buildVisitaCard(Visita visita) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Visita #${visita.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildEstadoChip(visita.estado ?? 'Sin estado'),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Fecha Visita', visita.fechaVisita != null ? _formatDate(visita.fechaVisita!.toIso8601String()) : 'Sin fecha'),
            _buildInfoRow('Contrato', visita.contrato ?? 'N/A'),
            _buildInfoRow('Operador', visita.operador ?? 'N/A'),
            _buildInfoRow('Caso Prioritaria', visita.casoAtencionPrioritaria ?? 'N/A'),
            _buildInfoRow('Municipio', visita.municipio?.nombre ?? 'N/A'),
            _buildInfoRow('Institución', visita.institucion?.nombre ?? 'N/A'),
            _buildInfoRow('Sede', visita.sede?.nombre ?? 'N/A'),
            _buildInfoRow('Profesional', visita.profesional?.nombre ?? 'N/A'),
            _buildInfoRow('Respuestas Checklist', '${visita.respuestasChecklist.length} items'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _verDetallesVisita(visita),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Ver Detalles'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _descargarExcel(visita.id),
                    icon: const Icon(Icons.download),
                    label: const Text('Descargar Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoChip(String estado) {
    Color color;
    String text;
    
    switch (estado.toLowerCase()) {
      case 'completada':
        color = Colors.green;
        text = 'Completada';
        break;
      case 'pendiente':
        color = Colors.orange;
        text = 'Pendiente';
        break;
      case 'cancelada':
        color = Colors.red;
        text = 'Cancelada';
        break;
      default:
        color = Colors.grey;
        text = estado;
    }

    return Chip(
      label: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _verDetallesVisita(Visita visita) {
    // Mostrar un diálogo con los detalles de la visita
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Detalles de Visita #${visita.id}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow('Fecha Visita', visita.fechaVisita != null ? _formatDate(visita.fechaVisita!.toIso8601String()) : 'Sin fecha'),
                _buildInfoRow('Contrato', visita.contrato ?? 'N/A'),
                _buildInfoRow('Operador', visita.operador ?? 'N/A'),
                _buildInfoRow('Caso Prioritaria', visita.casoAtencionPrioritaria ?? 'N/A'),
                _buildInfoRow('Municipio', visita.municipio?.nombre ?? 'N/A'),
                _buildInfoRow('Institución', visita.institucion?.nombre ?? 'N/A'),
                _buildInfoRow('Sede', visita.sede?.nombre ?? 'N/A'),
                _buildInfoRow('Profesional', visita.profesional?.nombre ?? 'N/A'),
                _buildInfoRow('Estado', visita.estado ?? 'Sin estado'),
                _buildInfoRow('Respuestas Checklist', '${visita.respuestasChecklist.length} items'),
                const SizedBox(height: 16),
                const Text(
                  'Respuestas del Checklist:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...visita.respuestasChecklist.map<Widget>((respuesta) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• Item ${respuesta.itemId}: ${respuesta.respuesta}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
} 