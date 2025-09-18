import 'package:flutter/material.dart';
import 'package:frontend_visitas/models/sede.dart';
import 'package:frontend_visitas/models/usuario.dart';
import 'package:frontend_visitas/models/municipio.dart';
import 'package:frontend_visitas/models/institucion.dart';
import 'package:frontend_visitas/services/api_service.dart';


class ProgramarVisitaScreen extends StatefulWidget {
  const ProgramarVisitaScreen({super.key});

  @override
  State<ProgramarVisitaScreen> createState() => _ProgramarVisitaScreenState();
}

class _ProgramarVisitaScreenState extends State<ProgramarVisitaScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _contratoController = TextEditingController();
  final _operadorController = TextEditingController();
  final _fechaController = TextEditingController();
  final _horaController = TextEditingController();
  final _observacionesController = TextEditingController();
  
  // Variables de estado
  Usuario? _visitadorSeleccionado;
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  bool _isLoading = false;
  
  // Variables para ubicación
  Municipio? _municipioSeleccionado;
  Institucion? _institucionSeleccionada;
  Sede? _sedeSeleccionada;
  
  // Futures para cargar datos
  late Future<List<Municipio>> _futureMunicipios;
  late Future<List<Institucion>> _futureInstituciones;
  late Future<List<Sede>> _futureSedes;
  late Future<List<Usuario>> _futureVisitadores;

  @override
  void initState() {
    super.initState();
    _inicializarFutures();
  }

  @override
  void dispose() {
    _contratoController.dispose();
    _operadorController.dispose();
    _fechaController.dispose();
    _horaController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  void _inicializarFutures() {
    print('🚀 Inicializando futures...');
    _futureMunicipios = _apiService.getMunicipios();
    _futureVisitadores = _apiService.getTodosUsuarios();
    print('✅ Futures inicializados');
  }

  void _cargarInstituciones() {
    if (_municipioSeleccionado != null) {
      setState(() {
        _futureInstituciones = _apiService.getInstitucionesPorMunicipio(_municipioSeleccionado!.id);
        _institucionSeleccionada = null;
        _sedeSeleccionada = null;
      });
    }
  }

    void _cargarSedes() {
    if (_institucionSeleccionada != null) {
      setState(() {
        _futureSedes = _apiService.getSedesPorInstitucion(_institucionSeleccionada!.id);
        _sedeSeleccionada = null;
      });
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
        _fechaController.text = '${fecha.day}/${fecha.month}/${fecha.year}';
      });
    }
  }

  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    
    if (hora != null) {
      setState(() {
        _horaSeleccionada = hora;
        _horaController.text = '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _programarVisita() async {
    if (!_formKey.currentState!.validate()) return;
    if (_municipioSeleccionado == null || _institucionSeleccionada == null || 
        _sedeSeleccionada == null || _visitadorSeleccionado == null || 
        _fechaSeleccionada == null || _horaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete todos los campos obligatorios (municipio, institución, sede, visitador, fecha y hora)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Crear fecha y hora combinadas
      final fechaHora = DateTime(
        _fechaSeleccionada!.year,
        _fechaSeleccionada!.month,
        _fechaSeleccionada!.day,
        _horaSeleccionada!.hour,
        _horaSeleccionada!.minute,
      );

      // Crear la visita programada
      final visitaProgramada = {
        'sede_id': _sedeSeleccionada!.id,
        'visitador_id': _visitadorSeleccionado!.id,
        'fecha_programada': fechaHora.toIso8601String(),
        'contrato': _contratoController.text.trim(),
        'operador': _operadorController.text.trim(),
        'observaciones': _observacionesController.text.trim(),
        'estado': 'programada',
        'municipio_id': _municipioSeleccionado!.id,
        'institucion_id': _institucionSeleccionada!.id,
      };

      await _apiService.asignarVisitaAVisitador(
        contrato: visitaProgramada['contrato'] as String,
        operador: visitaProgramada['operador'] as String,
        fechaProgramada: DateTime.parse(visitaProgramada['fecha_programada'] as String),
        municipioId: visitaProgramada['municipio_id'] as int,
        institucionId: visitaProgramada['institucion_id'] as int,
        sedeId: visitaProgramada['sede_id'] as int,
        visitadorId: visitaProgramada['visitador_id'] as int,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visita asignada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retornar true para indicar éxito
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al programar visita: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Programar Visita'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
      ),
      body: _buildForm(),
    );
  }



  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información de ubicación
            _buildSectionTitle('Ubicación'),
            
            // Municipio
            _buildDropdownMunicipio(),
            const SizedBox(height: 16),
            
            // Institución
            if (_municipioSeleccionado != null) ...[
              _buildDropdownInstitucion(),
              const SizedBox(height: 16),
            ],
            
            // Sede
            if (_institucionSeleccionada != null) ...[
              _buildDropdownSede(),
              const SizedBox(height: 16),
            ],
            
            const SizedBox(height: 24),
            
            // Información del visitador
            _buildSectionTitle('Visitador Asignado'),
            _buildDropdownVisitador(),
            const SizedBox(height: 24),
            
            // Información de la visita
            _buildSectionTitle('Detalles de la Visita'),
            
            // Contrato y Operador en fila
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _contratoController,
                    label: 'Contrato',
                    hint: 'Ingrese el número de contrato',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El contrato es obligatorio';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _operadorController,
                    label: 'Operador',
                    hint: 'Ingrese el nombre del operador',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El operador es obligatorio';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Fecha y Hora en fila
            Row(
              children: [
                Expanded(
                  child: _buildDateField(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeField(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Observaciones
            _buildSectionTitle('Observaciones (Opcional)'),
            _buildTextField(
              controller: _observacionesController,
              label: 'Observaciones',
              hint: 'Agregue observaciones adicionales si es necesario',
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            
            // Botón de programar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _programarVisita,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_isLoading ? 'Programando...' : 'Programar Visita'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.purple[700],
        ),
      ),
    );
  }

  Widget _buildDropdownMunicipio() {
    return FutureBuilder<List<Municipio>>(
      future: _futureMunicipios,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              children: [
                Text('Error: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _futureMunicipios = _apiService.getMunicipios();
                    });
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        final municipios = snapshot.data ?? [];
        return DropdownButtonFormField<Municipio>(
          value: _municipioSeleccionado,
          decoration: const InputDecoration(
            labelText: 'Seleccionar Municipio *',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: municipios.map((municipio) {
            return DropdownMenuItem(
              value: municipio,
              child: Text(municipio.nombre),
            );
          }).toList(),
          onChanged: (Municipio? municipio) {
            setState(() {
              _municipioSeleccionado = municipio;
              _institucionSeleccionada = null;
              _sedeSeleccionada = null;
            });
            if (municipio != null) {
              _cargarInstituciones();
            }
          },
          validator: (value) {
            if (value == null) {
              return 'Por favor seleccione un municipio';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildDropdownInstitucion() {
    return FutureBuilder<List<Institucion>>(
      future: _futureInstituciones,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              children: [
                Text('Error: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: _cargarInstituciones,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        final instituciones = snapshot.data ?? [];
        return DropdownButtonFormField<Institucion>(
          value: _institucionSeleccionada,
          decoration: const InputDecoration(
            labelText: 'Seleccionar Institución *',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: instituciones.map((institucion) {
            return DropdownMenuItem(
              value: institucion,
              child: Text(institucion.nombre),
            );
          }).toList(),
          onChanged: (Institucion? institucion) {
            setState(() {
              _institucionSeleccionada = institucion;
              _sedeSeleccionada = null;
            });
            if (institucion != null) {
              _cargarSedes();
            }
          },
          validator: (value) {
            if (value == null) {
              return 'Por favor seleccione una institución';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildDropdownSede() {
    return FutureBuilder<List<Sede>>(
      future: _futureSedes,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              children: [
                Text('Error: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: _cargarSedes,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        final sedes = snapshot.data ?? [];
        return DropdownButtonFormField<Sede>(
          value: _sedeSeleccionada,
          decoration: const InputDecoration(
            labelText: 'Seleccionar Sede *',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: sedes.map((sede) {
            return DropdownMenuItem(
              value: sede,
              child: Text(sede.nombre),
            );
          }).toList(),
          onChanged: (Sede? sede) {
            setState(() {
              _sedeSeleccionada = sede;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Por favor seleccione una sede';
            }
            return null;
          },
        );
      },
    );
  }

    Widget _buildDropdownVisitador() {
    return FutureBuilder<List<Usuario>>(
      future: _futureVisitadores,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print('❌ Error en dropdown visitador: ${snapshot.error}');
          return Center(
            child: Column(
              children: [
                Text('Error: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _futureVisitadores = _apiService.getTodosUsuarios();
                    });
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        final usuarios = snapshot.data ?? [];
        print('🔍 Usuarios recibidos: ${usuarios.length}');
        print('🔍 Roles encontrados: ${usuarios.map((u) => u.rol).toSet()}');
        print('🔍 Usuarios completos: ${usuarios.map((u) => '${u.nombre} (${u.rol})').toList()}');
        
        // Debug detallado de cada usuario
        for (int i = 0; i < usuarios.length; i++) {
          final u = usuarios[i];
          print('🔍 Usuario $i: ID=${u.id}, Nombre=${u.nombre}, Rol=${u.rol}, Activo=${u.activo}');
        }
        
        // Filtrar solo visitadores (case-insensitive)
        final visitadores = usuarios.where((u) {
          final rol = u.rol;
          if (rol == null) {
            print('🔍 Usuario ${u.nombre}: rol es null');
            return false;
          }
          final rolLower = rol.toLowerCase();
          final esVisitador = rolLower == 'visitador';
          print('🔍 Usuario ${u.nombre}: rol="$rol" -> rolLower="$rolLower" -> esVisitador=$esVisitador');
          return esVisitador;
        }).toList();
        print('🔍 Visitadores filtrados: ${visitadores.length}');
        print('🔍 Visitadores encontrados: ${visitadores.map((u) => '${u.nombre} ${u.apellido ?? ''}').toList()}');
        
        // Debug adicional para entender el filtro
        print('🔍 Filtro aplicado: u.rol != null && u.rol.toLowerCase() == "visitador"');
        for (int i = 0; i < usuarios.length; i++) {
          final u = usuarios[i];
          final rolLower = u.rol?.toLowerCase();
          final cumpleFiltro = u.rol != null && rolLower == 'visitador';
          print('🔍 Usuario $i: Rol="${u.rol}" -> RolLower="$rolLower" -> CumpleFiltro=$cumpleFiltro');
        }
        
        if (visitadores.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<Usuario>(
                value: null,
                decoration: const InputDecoration(
                  labelText: 'Seleccionar Visitador *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: const [],
                onChanged: null,
              ),
              const SizedBox(height: 8),
              Text(
                'No hay visitadores disponibles',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                'Total usuarios: ${usuarios.length}',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
              Text(
                'Roles disponibles: ${usuarios.map((u) => u.rol ?? 'sin rol').toSet().join(', ')}',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          );
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<Usuario>(
              value: _visitadorSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Seleccionar Visitador *',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: visitadores.map((visitador) {
                return DropdownMenuItem(
                  value: visitador,
                  child: Text('${visitador.nombre} ${visitador.apellido ?? ''}'),
                );
              }).toList(),
              onChanged: (Usuario? visitador) {
                print('🔍 Visitador seleccionado: ${visitador?.nombre} (${visitador?.rol})');
                setState(() {
                  _visitadorSeleccionado = visitador;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Por favor seleccione un visitador';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Visitadores disponibles: ${visitadores.length}',
              style: TextStyle(color: Colors.green, fontSize: 12),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator,
      maxLines: maxLines,
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _fechaController,
      decoration: InputDecoration(
        labelText: 'Fecha de la Visita *',
        hintText: 'Seleccione la fecha',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: _seleccionarFecha,
        ),
      ),
      readOnly: true,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'La fecha es obligatoria';
        }
        return null;
      },
    );
  }

  Widget _buildTimeField() {
    return TextFormField(
      controller: _horaController,
      decoration: InputDecoration(
        labelText: 'Hora de la Visita *',
        hintText: 'Seleccione la hora',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixIcon: IconButton(
          icon: const Icon(Icons.access_time),
          onPressed: _seleccionarHora,
        ),
      ),
      readOnly: true,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'La hora es obligatoria';
        }
        return null;
      },
    );
  }
}
