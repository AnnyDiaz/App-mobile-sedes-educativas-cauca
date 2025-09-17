import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/models/municipio.dart';
import 'package:frontend_visitas/models/institucion.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final ApiService _apiService = ApiService();
  List<Municipio> _municipios = [];
  List<Institucion> _instituciones = [];
  List<String> _tiposReporte = [
    'Todas las visitas',
    'Visitas por fecha',
    'Visitas por municipio',
    'Visitas por institución',
    'Visitas por estado',
    'Visitas por visitador',
    'Resumen ejecutivo',
  ];
  
  String? _tipoReporteSeleccionado;
  String? _municipioSeleccionado;
  String? _institucionSeleccionada;
  String? _estadoSeleccionado;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _formatoSeleccionado = 'Excel';
  
  bool _isGenerando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final futures = await Future.wait([
        _apiService.getMunicipios(),
        _apiService.getInstituciones(),
      ]);

      setState(() {
        _municipios = futures[0] as List<Municipio>;
        _instituciones = futures[1] as List<Institucion>;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    }
  }

  Future<void> _generarReporte() async {
    if (_tipoReporteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un tipo de reporte')),
      );
      return;
    }

    setState(() {
      _isGenerando = true;
    });

    try {
      final parametros = {
        'tipo_reporte': _formatoSeleccionado.toLowerCase(), // Cambiado: enviar el formato como tipo_reporte
        'tipo_consulta': _tipoReporteSeleccionado, // Nuevo: el tipo de reporte real
        'municipio_id': _municipioSeleccionado != null ? int.tryParse(_municipioSeleccionado!) : null,
        'institucion_id': _institucionSeleccionada != null ? int.tryParse(_institucionSeleccionada!) : null,
        'estado': _estadoSeleccionado,
        'fecha_inicio': _fechaInicio?.toIso8601String(),
        'fecha_fin': _fechaFin?.toIso8601String(),
      };

      await _apiService.generarReporte(parametros);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reporte ${_formatoSeleccionado} generado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar reporte: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isGenerando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generar Reportes'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTipoReporte(),
            const SizedBox(height: 24),
            _buildFiltros(),
            const SizedBox(height: 24),
            _buildFormatoReporte(),
            const SizedBox(height: 32),
            _buildBotonGenerar(),
            const SizedBox(height: 24),
            _buildDescripcionReportes(),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoReporte() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipo de Reporte',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Selecciona el tipo de reporte',
                border: OutlineInputBorder(),
              ),
              value: _tipoReporteSeleccionado,
              items: _tiposReporte.map((tipo) => DropdownMenuItem(
                value: tipo,
                child: Text(tipo),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _tipoReporteSeleccionado = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros (Opcionales)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Filtro por municipio
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Municipio',
                border: OutlineInputBorder(),
              ),
              value: _municipioSeleccionado,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                ..._municipios.map((municipio) => DropdownMenuItem(
                  value: municipio.nombre,
                  child: Text(
                    municipio.nombre,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
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
SizedBox(
  width: double.infinity, // 👈 asegura que use todo el ancho disponible
  child: DropdownButtonFormField<String>(
    isExpanded: true,
    decoration: const InputDecoration(
      labelText: 'Institución',
      border: OutlineInputBorder(),
    ),
    value: _institucionSeleccionada,
    items: [
      const DropdownMenuItem(
        value: null,
        child: Text('Todas'),
      ),
      ..._instituciones.map(
        (institucion) => DropdownMenuItem(
          value: institucion.nombre,
          child: Text(
            institucion.nombre,
            overflow: TextOverflow.ellipsis, // 👈 evita desbordes
            maxLines: 1, // 👈 asegura que quede en una sola línea
          ),
        ),
      ),
    ],
    onChanged: (value) {
      setState(() {
        _institucionSeleccionada = value;
      });
    },
  ),
),
const SizedBox(height: 10),

            
            // Filtro por estado
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
              ),
              value: _estadoSeleccionado,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                const DropdownMenuItem(value: 'Pendiente', child: Text('Pendiente')),
                const DropdownMenuItem(value: 'En Proceso', child: Text('En Proceso')),
                const DropdownMenuItem(value: 'Completada', child: Text('Completada')),
                const DropdownMenuItem(value: 'Cancelada', child: Text('Cancelada')),
              ],
              onChanged: (value) {
                setState(() {
                  _estadoSeleccionado = value;
                });
              },
            ),
            const SizedBox(height: 12),
            
            // Filtro por fecha
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Fecha inicio',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final fecha = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(const Duration(days: 30)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (fecha != null) {
                        setState(() {
                          _fechaInicio = fecha;
                        });
                      }
                    },
                    controller: TextEditingController(
                      text: _fechaInicio != null 
                          ? '${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}'
                          : '',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Fecha fin',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final fecha = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (fecha != null) {
                        setState(() {
                          _fechaFin = fecha;
                        });
                      }
                    },
                    controller: TextEditingController(
                      text: _fechaFin != null 
                          ? '${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}'
                          : '',
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

  Widget _buildFormatoReporte() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Formato del Reporte',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Excel'),
                    subtitle: const Text('.xlsx'),
                    value: 'Excel',
                    groupValue: _formatoSeleccionado,
                    onChanged: (value) {
                      setState(() {
                        _formatoSeleccionado = value!;
                      });
                    },
                  ),
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonGenerar() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isGenerando ? null : _generarReporte,
        icon: _isGenerando 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(_formatoSeleccionado == 'Excel' ? Icons.table_chart : Icons.description),
        label: Text(_isGenerando ? 'Generando...' : 'Generar Reporte $_formatoSeleccionado'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDescripcionReportes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Descripción de Reportes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDescripcionItem(
              'Todas las visitas',
              'Reporte completo con todas las visitas del sistema',
              Icons.list_alt,
            ),
            _buildDescripcionItem(
              'Visitas por fecha',
              'Visitas filtradas por rango de fechas específico',
              Icons.calendar_today,
            ),
            _buildDescripcionItem(
              'Visitas por municipio',
              'Visitas realizadas en un municipio específico',
              Icons.location_city,
            ),
            _buildDescripcionItem(
              'Visitas por institución',
              'Visitas realizadas en una institución específica',
              Icons.school,
            ),
            _buildDescripcionItem(
              'Visitas por estado',
              'Visitas filtradas por estado (pendiente, completada, etc.)',
              Icons.assessment,
            ),
            _buildDescripcionItem(
              'Visitas por visitador',
              'Visitas realizadas por un visitador específico',
              Icons.person,
            ),
            _buildDescripcionItem(
              'Resumen ejecutivo',
              'Resumen estadístico de todas las visitas',
              Icons.analytics,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescripcionItem(String titulo, String descripcion, IconData icono) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icono, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  descripcion,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 