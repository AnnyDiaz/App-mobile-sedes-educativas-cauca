import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/widgets/doble_autenticacion_widget.dart';

class ReportesSupervisorScreen extends StatefulWidget {
  const ReportesSupervisorScreen({super.key});

  @override
  State<ReportesSupervisorScreen> createState() => _ReportesSupervisorScreenState();
}

class _ReportesSupervisorScreenState extends State<ReportesSupervisorScreen> {
  final ApiService _apiService = ApiService();
  
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fechaFin = DateTime.now();
  String? _visitadorSeleccionado;
  String? _tipoVisitaSeleccionado;
  String? _estadoSeleccionado;
  
  List<Map<String, dynamic>> _visitadoresEquipo = [];
  List<Map<String, dynamic>> _tiposVisita = [];
  List<Map<String, dynamic>> _estados = [
    {'id': 'todos', 'nombre': 'Todos los estados'},
    {'id': 'pendiente', 'nombre': 'Pendiente'},
    {'id': 'en_proceso', 'nombre': 'En Proceso'},
    {'id': 'completada', 'nombre': 'Completada'},
    {'id': 'cancelada', 'nombre': 'Cancelada'},
  ];
  
  Map<String, dynamic>? _reporteGenerado;
  bool _isLoading = false;
  bool _isGenerandoReporte = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Cargar datos en paralelo
      final futures = await Future.wait([
        _apiService.getVisitadoresEquipo(),
        _apiService.getTiposVisita(),
      ]);

      if (mounted) {
        setState(() {
          _visitadoresEquipo = futures[0] as List<Map<String, dynamic>>;
          _tiposVisita = futures[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _seleccionarFechaInicio() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (fecha != null) {
      setState(() {
        _fechaInicio = fecha;
        if (_fechaInicio.isAfter(_fechaFin)) {
          _fechaFin = _fechaInicio;
        }
      });
    }
  }

  Future<void> _seleccionarFechaFin() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaFin,
      firstDate: _fechaInicio,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (fecha != null) {
      setState(() {
        _fechaFin = fecha;
      });
    }
  }

  Future<void> _generarReporte() async {
    // 🔒 DOBLE AUTENTICACIÓN REQUERIDA
    final contrasenaVerificada = await mostrarDobleAutenticacion(
      context: context,
      titulo: 'Autenticación Requerida',
      mensaje: 'Para generar reportes como supervisor, debe confirmar su identidad por motivos de seguridad.',
    );
    
    if (contrasenaVerificada == null) {
      // Usuario canceló la autenticación
      return;
    }
    
    try {
      setState(() {
        _isGenerandoReporte = true;
        _error = null;
      });

      final filtros = {
        'fecha_inicio': _fechaInicio.toIso8601String(),
        'fecha_fin': _fechaFin.toIso8601String(),
        'visitador_id': _visitadorSeleccionado != 'todos' ? int.parse(_visitadorSeleccionado!) : null,
        'tipo_visita': _tipoVisitaSeleccionado != 'todos' ? _tiposVisita[int.parse(_tipoVisitaSeleccionado!)]['id'] : null,
        'estado': _estadoSeleccionado != 'todos' ? _estadoSeleccionado : null,
      };

      final reporte = await _apiService.generarReporteEquipo(filtros);
      
      setState(() {
        _reporteGenerado = reporte;
        _isGenerandoReporte = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reporte generado exitosamente con autenticación verificada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isGenerandoReporte = false;
      });
    }
  }

  Future<void> _descargarReporte() async {
    if (_reporteGenerado == null) return;
    
    // 🔒 DOBLE AUTENTICACIÓN REQUERIDA PARA DESCARGA
    final contrasenaVerificada = await mostrarDobleAutenticacion(
      context: context,
      titulo: 'Autenticación para Descarga',
      mensaje: 'Para descargar reportes como supervisor, debe confirmar su identidad por motivos de seguridad.',
    );
    
    if (contrasenaVerificada == null) {
      // Usuario canceló la autenticación
      return;
    }
    
    try {
      await _apiService.descargarReporteEquipo(_reporteGenerado!['id']);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reporte descargado exitosamente con autenticación verificada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar reporte: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes del Equipo'),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
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
            'Error al cargar datos',
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
            onPressed: _cargarDatosIniciales,
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
          // Título
          Text(
            'Generar Reporte del Equipo',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configura los filtros para generar un reporte personalizado de tu equipo',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Filtros
          _buildFiltros(),
          const SizedBox(height: 24),

          // Botón generar reporte
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isGenerandoReporte ? null : _generarReporte,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[600],
                foregroundColor: Colors.white,
              ),
              child: _isGenerandoReporte
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Generar Reporte',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Resultado del reporte
          if (_reporteGenerado != null) _buildResultadoReporte(),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros del Reporte',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Fechas
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    label: 'Fecha Inicio',
                    value: '${_fechaInicio.day}/${_fechaInicio.month}/${_fechaInicio.year}',
                    onTap: _seleccionarFechaInicio,
                    icon: Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    label: 'Fecha Fin',
                    value: '${_fechaFin.day}/${_fechaFin.month}/${_fechaFin.year}',
                    onTap: _seleccionarFechaFin,
                    icon: Icons.calendar_today,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Visitador
            _buildDropdownField(
              label: 'Visitador',
              value: _visitadorSeleccionado ?? 'todos',
              items: [
                const DropdownMenuItem<String>(
                  value: 'todos',
                  child: Text('Todos los visitadores'),
                ),
                ..._visitadoresEquipo.map((visitador) {
                  return DropdownMenuItem<String>(
                    value: visitador['id'].toString(),
                    child: Text(visitador['nombre']),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _visitadorSeleccionado = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Tipo de visita
            _buildDropdownField(
              label: 'Tipo de Visita',
              value: _tipoVisitaSeleccionado ?? 'todos',
              items: [
                const DropdownMenuItem<String>(
                  value: 'todos',
                  child: Text('Todos los tipos'),
                ),
                ..._tiposVisita.map((tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo['id'].toString(),
                    child: Text(tipo['nombre']),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _tipoVisitaSeleccionado = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Estado
            _buildDropdownField(
              label: 'Estado',
              value: _estadoSeleccionado ?? 'todos',
              items: _estados.map((estado) {
                return DropdownMenuItem<String>(
                  value: estado['id'],
                  child: Text(estado['nombre']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _estadoSeleccionado = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
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

  Widget _buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultadoReporte() {
    final reporte = _reporteGenerado!;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Reporte Generado',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _descargarReporte,
                  icon: const Icon(Icons.download, color: Colors.indigo),
                  tooltip: 'Descargar Reporte',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Resumen del reporte
            _buildResumenReporte(reporte),
            
            const SizedBox(height: 16),
            
            // Detalles del reporte
            _buildDetallesReporte(reporte),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenReporte(Map<String, dynamic> reporte) {
    return Row(
      children: [
        Expanded(
          child: _buildResumenCard(
            title: 'Total Visitas',
            value: (reporte['total_visitas'] ?? 0).toString(),
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildResumenCard(
            title: 'Pendientes',
            value: (reporte['visitas_pendientes'] ?? 0).toString(),
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildResumenCard(
            title: 'Completadas',
            value: (reporte['visitas_completadas'] ?? 0).toString(),
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildResumenCard(
            title: 'Visitadores',
            value: (reporte['total_visitadores'] ?? 0).toString(),
            color: Colors.indigo,
          ),
        ),
      ],
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

  Widget _buildDetallesReporte(Map<String, dynamic> reporte) {
    final visitas = reporte['visitas'] as List<dynamic>? ?? [];
    
    if (visitas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No hay visitas que coincidan con los filtros seleccionados',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalle de Visitas (${visitas.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Lista de visitas
        ...visitas.take(5).map((visita) => _buildVisitaItem(visita)),
        
        if (visitas.length > 5) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              '... y ${visitas.length - 5} visitas más',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVisitaItem(dynamic visita) {
    final estado = visita['estado'] as String? ?? 'pendiente';
    final visitadorNombre = visita['visitador_nombre'] ?? 'Visitador';
    final sedeNombre = visita['sede_nombre'] ?? 'Sede';
    final fecha = DateTime.parse(visita['fecha_programada']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getColorEstado(estado),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sedeNombre,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Por: $visitadorNombre • ${fecha.day}/${fecha.month}/${fecha.year}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getColorEstado(estado).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              estado.toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getColorEstado(estado),
              ),
            ),
          ),
        ],
      ),
    );
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
}
