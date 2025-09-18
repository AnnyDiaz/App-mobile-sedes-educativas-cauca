import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_visitas/config.dart';
import 'package:frontend_visitas/widgets/semaforo_progreso_widget.dart';
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
        'distribucion': _distribucion,
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
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tipo de Visita', style: TextStyle(fontWeight: FontWeight.bold)),
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
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rango de Fechas', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text('Fecha Inicio'),
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
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Visitadores (${_visitadoresSeleccionados.length} seleccionados)', 
                       style: TextStyle(fontWeight: FontWeight.bold)),
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
          
          // Sedes
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Sedes Educativas (${_sedesSeleccionadas.length} seleccionadas)', 
                             style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      if (_visitadoresSeleccionados.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Filtradas por visitadores',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 200,
                    child: ListView.builder(
                      itemCount: _getSedesFiltradas().length,
                      itemBuilder: (context, index) {
                        final sede = _getSedesFiltradas()[index];
                        final isSelected = _sedesSeleccionadas.contains(sede['id']);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                _sedesSeleccionadas.add(sede['id']);
                              } else {
                                _sedesSeleccionadas.remove(sede['id']);
                              }
                            });
                          },
                          title: Text(sede['nombre']),
                          subtitle: Text(sede['direccion'] ?? 'Sin dirección'),
                        );
                      },
                    ),
                  ),
                  if (_getSedesFiltradas().isEmpty && _visitadoresSeleccionados.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange, size: 32),
                          SizedBox(height: 8),
                          Text(
                            'No hay sedes disponibles para los visitadores seleccionados',
                            style: TextStyle(color: Colors.orange[700]),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Selecciona visitadores de diferentes municipios para ver más opciones',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Distribución
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tipo de Distribución', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  RadioListTile<String>(
                    value: 'automatica',
                    groupValue: _distribucion,
                    onChanged: (value) => setState(() => _distribucion = value!),
                    title: Text('Automática'),
                    subtitle: Text('El sistema distribuye equitativamente'),
                  ),
                  RadioListTile<String>(
                    value: 'equilibrada',
                    groupValue: _distribucion,
                    onChanged: (value) => setState(() => _distribucion = value!),
                    title: Text('Equilibrada'),
                    subtitle: Text('Considera la carga actual de cada visitador'),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _programarVisitasMasivo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Programar Visitas Masivamente', style: TextStyle(fontSize: 16)),
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
}
