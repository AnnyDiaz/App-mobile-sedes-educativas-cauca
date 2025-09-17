import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/models/checklist_categoria.dart';
import 'package:frontend_visitas/models/checklist_item.dart';
import 'package:frontend_visitas/models/visita_respuesta.dart';
import 'package:frontend_visitas/models/municipio.dart';
import 'package:frontend_visitas/models/institucion.dart';
import 'package:frontend_visitas/models/sede.dart';

class CrearVisitaChecklistScreen extends StatefulWidget {
  const CrearVisitaChecklistScreen({super.key});

  @override
  State<CrearVisitaChecklistScreen> createState() => _CrearVisitaChecklistScreenState();
}

class _CrearVisitaChecklistScreenState extends State<CrearVisitaChecklistScreen> {
  final ApiService _apiService = ApiService();
  
  // Variables de estado para el formulario
  DateTime _fechaVisita = DateTime.now();
  final TextEditingController _contratoController = TextEditingController();
  final TextEditingController _operadorController = TextEditingController();

  // Variables para ubicación
  Municipio? _municipioSeleccionado;
  Institucion? _institucionSeleccionada;
  Sede? _sedeSeleccionada;
  
  // Variables para el checklist
  final Map<int, String> _respuestasChecklist = {};
  bool _isLoading = false;
  
  // Futures para cargar datos
  late Future<List<Municipio>> _futureMunicipios;
  late Future<List<Institucion>> _futureInstituciones;
  late Future<List<Sede>> _futureSedes;
  late Future<List<ChecklistCategoria>> _futureChecklist;

  @override
  void initState() {
    super.initState();
    _verificarAutenticacion();
    _inicializarFutures();
  }

  void _verificarAutenticacion() async {
    final isAuth = await _apiService.isAuthenticated();
    if (!isAuth) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  void _inicializarFutures() {
    _futureMunicipios = _apiService.getMunicipios();
    _futureChecklist = _apiService.getChecklist();
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

  void _actualizarRespuesta(int itemId, String respuesta) {
    setState(() {
      _respuestasChecklist[itemId] = respuesta;
    });
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaVisita,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (fechaSeleccionada != null) {
      setState(() {
        _fechaVisita = fechaSeleccionada;
      });
    }
  }

  Future<void> _guardarVisita() async {
    // Validaciones
    if (_contratoController.text.isEmpty) {
      _mostrarError('Por favor ingrese el contrato');
      return;
    }
    if (_operadorController.text.isEmpty) {
      _mostrarError('Por favor ingrese el operador');
      return;
    }
    if (_municipioSeleccionado == null) {
      _mostrarError('Por favor seleccione un municipio');
      return;
    }
    if (_institucionSeleccionada == null) {
      _mostrarError('Por favor seleccione una institución');
      return;
    }
    if (_sedeSeleccionada == null) {
      _mostrarError('Por favor seleccione una sede');
      return;
    }

    // Verificar que todas las respuestas del checklist estén completas
    final checklist = await _futureChecklist;
    final itemsRequeridos = <ChecklistItem>[];
    
    for (final categoria in checklist) {
      for (final item in categoria.items) {
        if (item.requerido) {
          itemsRequeridos.add(item);
        }
      }
    }
    
    final itemsFaltantes = itemsRequeridos.where((item) => !_respuestasChecklist.containsKey(item.id)).toList();
    
    if (itemsFaltantes.isNotEmpty) {
      _mostrarError('Por favor complete todas las evaluaciones requeridas del checklist');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Crear lista de respuestas
      final respuestas = _respuestasChecklist.entries.map((entry) {
        return VisitaRespuesta(
          visitaId: 0, // Se asignará en el backend
          itemId: entry.key,
          respuesta: entry.value,
        );
      }).toList();

      // Obtener ID del usuario
      final usuarioId = await _apiService.getUsuarioId();
      if (usuarioId == null) {
        throw Exception('No se pudo obtener el ID del usuario');
      }

      final resultado = await _apiService.guardarVisitaConChecklist(
        fechaVisita: _fechaVisita,
        contrato: _contratoController.text,
        operador: _operadorController.text,
        municipioId: _municipioSeleccionado!.id,
        institucionId: _institucionSeleccionada!.id,
        sedeId: _sedeSeleccionada!.id,
        profesionalId: usuarioId,
        respuestas: respuestas,
      );

      if (resultado) {
        _mostrarExito('Visita con checklist guardada exitosamente');
        Navigator.of(context).pop();
      } else {
        _mostrarError('Error al guardar la visita');
      }
    } catch (e) {
      _mostrarError('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Visita con Checklist'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSeccionDatosBasicos(),
                  const SizedBox(height: 20),
                  _buildSeccionUbicacion(),
                  const SizedBox(height: 20),
                  _buildSeccionChecklist(),
                  const SizedBox(height: 30),
                  _buildBotonGuardar(),
                ],
              ),
            ),
    );
  }

  Widget _buildSeccionDatosBasicos() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Datos de la Visita',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _contratoController,
                    decoration: const InputDecoration(
                      labelText: 'Contrato',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _operadorController,
                    decoration: const InputDecoration(
                      labelText: 'Operador',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _seleccionarFecha,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de Visita',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  '${_fechaVisita.day}/${_fechaVisita.month}/${_fechaVisita.year}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionUbicacion() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ubicación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Municipio>>(
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
                    labelText: 'Municipio',
                    border: OutlineInputBorder(),
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
                );
              },
            ),
            const SizedBox(height: 16),
            if (_municipioSeleccionado != null)
              FutureBuilder<List<Institucion>>(
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
                      labelText: 'Institución',
                      border: OutlineInputBorder(),
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
                  );
                },
              ),
            const SizedBox(height: 16),
            if (_institucionSeleccionada != null)
              FutureBuilder<List<Sede>>(
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
                      labelText: 'Sede',
                      border: OutlineInputBorder(),
                    ),
                    items: sedes.map((sede) {
                      return DropdownMenuItem(
                        value: sede,
                        child: Text(sede.nombreSede),
                      );
                    }).toList(),
                    onChanged: (Sede? sede) {
                      setState(() {
                        _sedeSeleccionada = sede;
                      });
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionChecklist() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Checklist de Evaluación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<ChecklistCategoria>>(
              future: _futureChecklist,
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
                              _futureChecklist = _apiService.getChecklist();
                            });
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                
                final categorias = snapshot.data ?? [];

                return Column(
                  children: categorias.map((categoria) {
                    return ExpansionTile(
                      title: Text(
                        categoria.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: categoria.descripcion.isNotEmpty 
                          ? Text(categoria.descripcion, style: const TextStyle(fontSize: 12))
                          : null,
                      children: categoria.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.nombre,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              if (item.descripcion.isNotEmpty)
                                Text(
                                  item.descripcion,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _respuestasChecklist[item.id],
                                decoration: InputDecoration(
                                  labelText: 'Seleccione una opción',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: item.requerido 
                                      ? const Icon(Icons.star, color: Colors.red, size: 16)
                                      : null,
                                ),
                                items: item.opciones.map((opcion) {
                                  return DropdownMenuItem(
                                    value: opcion,
                                    child: Text(opcion),
                                  );
                                }).toList(),
                                onChanged: (String? valor) {
                                  _actualizarRespuesta(item.id, valor ?? '');
                                },
                              ),
                              const Divider(),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonGuardar() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _guardarVisita,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
              'GUARDAR VISITA CON CHECKLIST',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  @override
  void dispose() {
    _contratoController.dispose();
    _operadorController.dispose();
    super.dispose();
  }
} 