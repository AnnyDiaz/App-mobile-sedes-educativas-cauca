import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_visitas/config.dart';
import 'package:frontend_visitas/widgets/semaforo_progreso_widget.dart';
import 'package:frontend_visitas/widgets/semaforo_visitas_masivas.dart';
import 'package:frontend_visitas/widgets/selector_cascada_sedes.dart';
// Removed table_calendar import - calendar not needed for mass scheduling

class AdminMassSchedulingScreen extends StatefulWidget {
  @override
  _AdminMassSchedulingScreenState createState() => _AdminMassSchedulingScreenState();
}

class _AdminMassSchedulingScreenState extends State<AdminMassSchedulingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Removed calendar variables - not needed for mass scheduling
  
  // Data
  List<Map<String, dynamic>> _visitadores = [];
  List<Map<String, dynamic>> _sedes = [];
  List<Map<String, dynamic>> _municipios = [];
  List<Map<String, dynamic>> _instituciones = [];
  List<Map<String, dynamic>> _disponibilidad = [];
  
  // Form variables
  List<int> _sedesSeleccionadas = [];
  List<int> _visitadoresSeleccionados = [];
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _tipoVisita = 'PAE';
  String _distribucion = 'automatica';
  
  bool _isLoading = true;
  String _error = '';
  
  // Variables para el semáforo
  EstadoSemaforo _estadoSemaforo = EstadoSemaforo.preparando;
  String _mensajeSemaforo = 'Preparando programación masiva...';
  double _progreso = 0.0;
  bool _mostrarSemaforo = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      await Future.wait([
        _cargarVisitadores(),
        _cargarSedes(),
        _cargarMunicipios(),
        _cargarInstituciones(),
      ]);
    } catch (e) {
      setState(() {
        _error = 'Error al cargar datos: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Removed _cargarCalendario method - calendar not needed for mass scheduling

  Future<void> _cargarVisitadores() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/visitadores'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _visitadores = List<Map<String, dynamic>>.from(data);
      });
    }
  }

  Future<void> _cargarSedes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/api/sedes'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _sedes = List<Map<String, dynamic>>.from(data);
      });
    }
  }

  Future<void> _cargarMunicipios() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/municipios'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _municipios = List<Map<String, dynamic>>.from(data);
      });
    }
  }

  Future<void> _cargarInstituciones() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/instituciones'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _instituciones = List<Map<String, dynamic>>.from(data);
      });
    }
  }

  // Filtrar sedes basándose en el visitador seleccionado
  List<Map<String, dynamic>> _getSedesFiltradas() {
    if (_visitadoresSeleccionados.isEmpty) {
      return _sedes; // Mostrar todas las sedes si no hay visitadores seleccionados
    }

    // Filtrar sedes que estén en el mismo municipio que los visitadores seleccionados
    // Esto es una aproximación ya que no hay relación directa visitador-sede
    List<Map<String, dynamic>> sedesFiltradas = [];
    
    for (var visitadorId in _visitadoresSeleccionados) {
      final visitador = _visitadores.firstWhere(
        (v) => v['id'] == visitadorId,
        orElse: () => {},
      );
      
      if (visitador.isNotEmpty && visitador['municipio_id'] != null) {
        final municipioId = visitador['municipio_id'];
        final sedesDelMunicipio = _sedes.where(
          (sede) => sede['municipio_id'] == municipioId
        ).toList();
        
        // Agregar sedes que no estén ya en la lista
        for (var sede in sedesDelMunicipio) {
          if (!sedesFiltradas.any((s) => s['id'] == sede['id'])) {
            sedesFiltradas.add(sede);
          }
        }
      }
    }
    
    return sedesFiltradas.isNotEmpty ? sedesFiltradas : _sedes;
  }

  Future<void> _cargarDisponibilidad() async {
    if (_fechaInicio == null || _fechaFin == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/visitas/disponibilidad?fecha_inicio=${_fechaInicio!.toIso8601String()}&fecha_fin=${_fechaFin!.toIso8601String()}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _disponibilidad = List<Map<String, dynamic>>.from(data);
      });
    }
  }

  Future<void> _programarVisitasMasivo() async {
    if (_sedesSeleccionadas.isEmpty || _visitadoresSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debe seleccionar sedes y visitadores')),
      );
      return;
    }

    if (_fechaInicio == null || _fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debe seleccionar fechas de inicio y fin')),
      );
      return;
    }

    // Mostrar semáforo
    setState(() {
      _mostrarSemaforo = true;
      _estadoSemaforo = EstadoSemaforo.preparando;
      _mensajeSemaforo = 'Preparando datos para programación masiva...';
      _progreso = 0.0;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Actualizar semáforo - procesando
      setState(() {
        _estadoSemaforo = EstadoSemaforo.procesando;
        _mensajeSemaforo = 'Enviando datos al servidor...';
        _progreso = 0.3;
      });

      final programacionData = {
        'sedes_ids': _sedesSeleccionadas,
        'visitadores_ids': _visitadoresSeleccionados,
        'fecha_inicio': _fechaInicio!.toIso8601String(),
        'fecha_fin': _fechaFin!.toIso8601String(),
        'tipo_visita': _tipoVisita,
      };

      setState(() {
        _mensajeSemaforo = 'Procesando programación masiva...';
        _progreso = 0.6;
      });

      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/visitas/programar-masivo'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(programacionData),
      );

      setState(() {
        _progreso = 0.9;
      });

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        // Completado exitosamente
        setState(() {
          _estadoSemaforo = EstadoSemaforo.completado;
          _mensajeSemaforo = 'Programación masiva completada exitosamente';
          _progreso = 1.0;
        });

        // Mostrar resultado después de un breve delay
        await Future.delayed(const Duration(seconds: 2));
        _mostrarResultadoProgramacion(result);
        
        // Ocultar semáforo
        setState(() {
          _mostrarSemaforo = false;
        });

        // Redirigir al dashboard principal después de un breve delay
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/admin_dashboard');
        }
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // Error en el proceso
      setState(() {
        _estadoSemaforo = EstadoSemaforo.error;
        _mensajeSemaforo = 'Error en la programación masiva: $e';
        _progreso = 0.0;
      });
      
      // Mostrar error después de un breve delay
      await Future.delayed(const Duration(seconds: 2));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      
      // Ocultar semáforo después de mostrar error
      setState(() {
        _mostrarSemaforo = false;
      });
    }
  }

  void _mostrarResultadoProgramacion(Map<String, dynamic> resultado) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Resultado de Programación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ Visitas creadas: ${resultado['visitas_creadas']}'),
            SizedBox(height: 8),
            Text('❌ Errores: ${resultado['errores']}'),
            SizedBox(height: 16),
            if (resultado['detalles']['errores'].isNotEmpty) ...[
              Text('Errores:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...resultado['detalles']['errores'].map<Widget>((error) => 
                Text('• $error', style: TextStyle(color: Colors.red, fontSize: 12))
              ).toList(),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Programación Masiva de Visitas'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: Icon(Icons.assignment_add), text: 'Programar'),
            Tab(icon: Icon(Icons.people_outline), text: 'Disponibilidad'),
          ],
        ),
      ),
      body: Stack(
        children: [
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text(_error, textAlign: TextAlign.center),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _cargarDatos,
                            child: Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildProgramarTab(),
                        _buildDisponibilidadTab(),
                      ],
                    ),
          
          // Semáforo de progreso
          if (_mostrarSemaforo)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: SemaforoProgresoWidget(
                  estado: _estadoSemaforo,
                  mensaje: _mensajeSemaforo,
                  progreso: _progreso,
                  onReintentar: _estadoSemaforo == EstadoSemaforo.error 
                      ? () {
                          setState(() {
                            _mostrarSemaforo = false;
                          });
                          _programarVisitasMasivo();
                        }
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Removed _buildCalendarioTab method - calendar not needed for mass scheduling

  Widget _buildProgramarTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuración de Programación',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          
          
          // Tipo de visita
          Card(
            color: _getColorContenedor(_getEstadoCampo('tipoVisita')),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: _getColorBorde(_getEstadoCampo('tipoVisita')),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Tipo de Visita', style: TextStyle(fontWeight: FontWeight.bold)),
                      Spacer(),
                      Icon(
                        _getEstadoCampo('tipoVisita') == 'completado' 
                          ? Icons.check_circle 
                          : Icons.radio_button_unchecked,
                        color: _getColorBorde(_getEstadoCampo('tipoVisita')),
                        size: 20,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _tipoVisita,
                    items: ['PAE', 'Infraestructura', 'Supervisión'].map((tipo) =>
                      DropdownMenuItem(value: tipo, child: Text(tipo))
                    ).toList(),
                    onChanged: (value) => setState(() => _tipoVisita = value!),
                    decoration: InputDecoration(border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
          
          // Fechas
          Card(
            color: _getColorContenedor(_getEstadoCampo('fechas')),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: _getColorBorde(_getEstadoCampo('fechas')),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Rango de Fechas', style: TextStyle(fontWeight: FontWeight.bold)),
                      Spacer(),
                      Icon(
                        _getEstadoCampo('fechas') == 'completado' 
                          ? Icons.check_circle 
                          : Icons.radio_button_unchecked,
                        color: _getColorBorde(_getEstadoCampo('fechas')),
                        size: 20,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Fecha Inicio',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            TextButton(
                              onPressed: () async {
                                final fecha = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(Duration(days: 365)),
                                );
                                if (fecha != null) {
                                  setState(() => _fechaInicio = fecha);
                                  _cargarDisponibilidad();
                                }
                              },
                              child: Text(_fechaInicio?.toString().split(' ')[0] ?? 'Seleccionar'),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            Text('Fecha Fin'),
                            TextButton(
                              onPressed: () async {
                                final fecha = await showDatePicker(
                                  context: context,
                                  initialDate: _fechaInicio ?? DateTime.now(),
                                  firstDate: _fechaInicio ?? DateTime.now(),
                                  lastDate: DateTime.now().add(Duration(days: 365)),
                                );
                                if (fecha != null) {
                                  setState(() => _fechaFin = fecha);
                                  _cargarDisponibilidad();
                                }
                              },
                              child: Text(_fechaFin?.toString().split(' ')[0] ?? 'Seleccionar'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Visitadores
          Card(
            color: _getColorContenedor(_getEstadoCampo('visitadores')),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: _getColorBorde(_getEstadoCampo('visitadores')),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Visitadores (${_visitadoresSeleccionados.length} seleccionados)', 
                           style: TextStyle(fontWeight: FontWeight.bold)),
                      Spacer(),
                      Icon(
                        _getEstadoCampo('visitadores') == 'completado' 
                          ? Icons.check_circle 
                          : Icons.radio_button_unchecked,
                        color: _getColorBorde(_getEstadoCampo('visitadores')),
                        size: 20,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 200,
                    child: ListView.builder(
                      itemCount: _visitadores.length,
                      itemBuilder: (context, index) {
                        final visitador = _visitadores[index];
                        final isSelected = _visitadoresSeleccionados.contains(visitador['id']);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                _visitadoresSeleccionados.add(visitador['id']);
                              } else {
                                _visitadoresSeleccionados.remove(visitador['id']);
                                // Limpiar sedes seleccionadas que ya no están disponibles
                                _sedesSeleccionadas.removeWhere((sedeId) {
                                  final sede = _sedes.firstWhere(
                                    (s) => s['id'] == sedeId,
                                    orElse: () => {},
                                  );
                                  return sede.isNotEmpty && !_getSedesFiltradas().any((s) => s['id'] == sedeId);
                                });
                              }
                            });
                          },
                          title: Text(visitador['nombre']),
                          subtitle: Text(visitador['equipo'] ?? 'Sin equipo'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Selector en cascada de sedes
          Card(
            color: _getColorContenedor(_getEstadoCampo('sedes')),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: _getColorBorde(_getEstadoCampo('sedes')),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Sedes Educativas (${_sedesSeleccionadas.length} seleccionadas)', 
                           style: TextStyle(fontWeight: FontWeight.bold)),
                      Spacer(),
                      Icon(
                        _getEstadoCampo('sedes') == 'completado' 
                          ? Icons.check_circle 
                          : Icons.radio_button_unchecked,
                        color: _getColorBorde(_getEstadoCampo('sedes')),
                        size: 20,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  SelectorCascadaSedes(
                    municipios: _municipios,
                    instituciones: _instituciones,
                    sedes: _sedes,
                    sedesSeleccionadas: _sedesSeleccionadas,
                    onSedesChanged: (sedes) {
                      setState(() {
                        _sedesSeleccionadas = sedes;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          
          
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _puedeProgramar() ? _programarVisitasMasivo : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _puedeProgramar() ? Colors.deepPurple : Colors.grey,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _puedeProgramar() 
                  ? 'Programar Visitas Masivamente' 
                  : 'Complete todos los campos obligatorios',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisponibilidadTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _cargarDisponibilidad,
                  icon: Icon(Icons.refresh),
                  label: Text('Actualizar Disponibilidad'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _disponibilidad.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Selecciona un rango de fechas para ver la disponibilidad'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _disponibilidad.length,
                  itemBuilder: (context, index) {
                    final visitador = _disponibilidad[index];
                    final disponibilidad = visitador['disponibilidad_porcentaje'];
                    final color = disponibilidad > 70 
                        ? Colors.green 
                        : disponibilidad > 30 
                            ? Colors.orange 
                            : Colors.red;
                    
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color,
                          child: Text('${disponibilidad.round()}%', 
                               style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        title: Text(visitador['nombre']),
                        subtitle: Text(
                          '${visitador['visitas_programadas']} visitas programadas de ${visitador['capacidad_maxima']} posibles'
                        ),
                        trailing: Chip(
                          label: Text(visitador['estado']),
                          backgroundColor: color.withOpacity(0.2),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  bool _puedeProgramar() {
    return _sedesSeleccionadas.isNotEmpty &&
           _visitadoresSeleccionados.isNotEmpty &&
           _fechaInicio != null &&
           _fechaFin != null &&
           _tipoVisita.isNotEmpty;
  }

  // Función para determinar el estado de un campo
  String _getEstadoCampo(String campo) {
    switch (campo) {
      case 'tipoVisita':
        return _tipoVisita.isNotEmpty ? 'completado' : 'pendiente';
      case 'fechas':
        return (_fechaInicio != null && _fechaFin != null) ? 'completado' : 'pendiente';
      case 'visitadores':
        return _visitadoresSeleccionados.isNotEmpty ? 'completado' : 'pendiente';
      case 'sedes':
        return _sedesSeleccionadas.isNotEmpty ? 'completado' : 'pendiente';
      default:
        return 'pendiente';
    }
  }

  // Función para obtener el color del contenedor según el estado
  Color _getColorContenedor(String estado) {
    switch (estado) {
      case 'completado':
        return Colors.green.withOpacity(0.1);
      case 'en_curso':
        return Colors.blue.withOpacity(0.1);
      case 'pendiente':
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  // Función para obtener el color del borde según el estado
  Color _getColorBorde(String estado) {
    switch (estado) {
      case 'completado':
        return Colors.green;
      case 'en_curso':
        return Colors.blue;
      case 'pendiente':
      default:
        return Colors.grey;
    }
  }
}
