import 'package:flutter/material.dart';
import 'package:frontend_visitas/models/checklist_categoria.dart';
import 'package:frontend_visitas/models/checklist_item.dart';
import 'package:frontend_visitas/models/evidencia.dart';
import 'package:frontend_visitas/models/institucion.dart';
import 'package:frontend_visitas/models/item_pae.dart';
import 'package:frontend_visitas/models/municipio.dart';
import 'package:frontend_visitas/models/sede.dart';
import 'package:frontend_visitas/models/visita_programada.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/widgets/evidencias_widget.dart';

class CrearVisitaPAEScreen extends StatefulWidget {
  final VisitaProgramada? visitaProgramada;
  final Map<String, dynamic>? visitaProgramadaMap;

  const CrearVisitaPAEScreen({
    super.key,
    this.visitaProgramada,
    this.visitaProgramadaMap,
  });

  @override
  State<CrearVisitaPAEScreen> createState() => _CrearVisitaPAEScreenState();
}

class _CrearVisitaPAEScreenState extends State<CrearVisitaPAEScreen> {
  final ApiService _apiService = ApiService();
  
  // Variables de estado para el formulario
  DateTime _fechaVisita = DateTime.now();
  final TextEditingController _contratoController = TextEditingController();
  final TextEditingController _operadorController = TextEditingController();

  // Variables para ubicación
  Municipio? _municipioSeleccionado;
  Institucion? _institucionSeleccionada;
  Sede? _sedeSeleccionada;
  
  // Variables para las evaluaciones
  final Map<int, String> _evaluaciones = {};
  final Map<String, List<Evidencia>> _evidencias = {};
  bool _isLoading = false;
  
  // Futures para cargar datos
  late Future<List<Municipio>> _futureMunicipios;
  late Future<List<Institucion>> _futureInstituciones;
  late Future<List<Sede>> _futureSedes;
  late Future<List<ItemPAE>> _futureItemsPAE;

  @override
  void initState() {
    super.initState();
    _verificarAutenticacion();
    _inicializarFutures();
    _prellenarDatosVisitaProgramada();
  }

  void _prellenarDatosVisitaProgramada() {
    // Prioridad: visitaProgramada (modelo) > visitaProgramadaMap (Map)
    if (widget.visitaProgramada != null) {
      _prellenarDesdeVisitaProgramada(widget.visitaProgramada!);
    } else if (widget.visitaProgramadaMap != null) {
      _prellenarDesdeMap(widget.visitaProgramadaMap!);
    }
  }

  void _prellenarDesdeVisitaProgramada(VisitaProgramada visita) {
    _contratoController.text = visita.contrato ?? '';
    _operadorController.text = visita.operador ?? '';
    
    if (visita.fechaProgramada != null) {
      _fechaVisita = visita.fechaProgramada!;
    }
    
    // Solo pre-llenar datos básicos, no ubicación
    print('✅ Datos básicos pre-llenados desde VisitaProgramada');
  }

  void _prellenarDesdeMap(Map<String, dynamic> visita) {
    _contratoController.text = visita['contrato'] ?? '';
    _operadorController.text = visita['operador'] ?? '';
    
    if (visita['fecha_programada'] != null) {
      try {
        _fechaVisita = DateTime.parse(visita['fecha_programada']);
      } catch (e) {
        print('Error al parsear fecha: $e');
        _fechaVisita = DateTime.now();
      }
    }
    
    // Solo pre-llenar datos básicos, no ubicación
    print('✅ Datos básicos pre-llenados desde Map');
  }

  void _verificarAutenticacion() async {
    final isAuth = await _apiService.isAuthenticated();
    if (!isAuth) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    }
  }

  void _inicializarFutures() {
    _futureMunicipios = _apiService.getMunicipios();
    _futureInstituciones = Future.value([]); // Inicializar con lista vacía
    _futureSedes = Future.value([]); // Inicializar con lista vacía
    _futureItemsPAE = _apiService.getItemsPAE();
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

  void _actualizarEvaluacion(int itemId, String valor) {
    setState(() {
      _evaluaciones[itemId] = valor;
      // Inicializar lista de evidencias para este item si no existe
      if (!_evidencias.containsKey(itemId.toString())) {
        _evidencias[itemId.toString()] = [];
      }
    });
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
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

    setState(() {
      _isLoading = true;
    });

    try {
      // Aquí iría la lógica para guardar la visita PAE
      await Future.delayed(const Duration(seconds: 2)); // Simular guardado
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visita PAE guardada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al guardar la visita: $e');
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
        title: const Text('Crear Visita PAE'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSeccionDatosBasicos(),
            const SizedBox(height: 20),
            _buildSeccionUbicacion(),
            const SizedBox(height: 20),
            _buildSeccionEvaluaciones(),
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
            // Municipio
            FutureBuilder<List<Municipio>>(
              future: _futureMunicipios,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No hay municipios disponibles');
                }

                return DropdownButtonFormField<Municipio>(
                  value: _municipioSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Municipio',
                    border: OutlineInputBorder(),
                  ),
                  items: snapshot.data!.map((municipio) {
                    return DropdownMenuItem(
                      value: municipio,
                      child: Text(
                        municipio.nombre,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (Municipio? municipio) {
                    setState(() {
                      _municipioSeleccionado = municipio;
                      _institucionSeleccionada = null;
                      _sedeSeleccionada = null;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            // Institución
            if (_municipioSeleccionado != null)
              FutureBuilder<List<Institucion>>(
                future: _futureInstituciones,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No hay instituciones disponibles');
                  }

                  return DropdownButtonFormField<Institucion>(
                    value: _institucionSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Institución',
                      border: OutlineInputBorder(),
                    ),
                    items: snapshot.data!.map((institucion) {
                      return DropdownMenuItem(
                        value: institucion,
                        child: Text(
                          institucion.nombre,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (Institucion? institucion) {
                      setState(() {
                        _institucionSeleccionada = institucion;
                        _sedeSeleccionada = null;
                      });
                    },
                  );
                },
              ),
            const SizedBox(height: 16),
            // Sede
            if (_institucionSeleccionada != null)
              FutureBuilder<List<Sede>>(
                future: _futureSedes,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No hay sedes disponibles');
                  }

                  return DropdownButtonFormField<Sede>(
                    value: _sedeSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Sede',
                      border: OutlineInputBorder(),
                    ),
                    items: snapshot.data!.map((sede) {
                      return DropdownMenuItem(
                        value: sede,
                        child: Text(
                          sede.nombre,
                          overflow: TextOverflow.ellipsis,
                        ),
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

  Widget _buildSeccionEvaluaciones() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evaluación PAE 2025',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<ItemPAE>>(
              future: _futureItemsPAE,
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
                              _futureItemsPAE = _apiService.getItemsPAE();
                            });
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                
                final itemsPAE = snapshot.data ?? [];
                
                // Agrupar items por categoría (usando el nombre como categoría)
                final categorias = <String, List<ItemPAE>>{};
                
                for (final item in itemsPAE) {
                  // Usar el nombre del item como categoría
                  final categoria = item.nombre;
                  categorias.putIfAbsent(categoria, () => []).add(item);
                }

                return Column(
                  children: categorias.entries.map((categoria) {
                    return ExpansionTile(
                      title: Text(
                        categoria.key,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      children: categoria.value.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Mostrar las preguntas específicas del item
                              if (item.items != null && item.items!.isNotEmpty)
                                ...item.items!.map((subItem) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subItem.preguntaTexto,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      value: _evaluaciones[subItem.id],
                                      decoration: const InputDecoration(
                                        labelText: 'Respuesta',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: [
                                        '✅ Cumple',
                                        '✔️ Cumple Parcialmente',
                                        '❌ No Cumple',
                                        'N/A',
                                        'N/O',
                                      ].map((opcion) {
                                        return DropdownMenuItem(
                                          value: opcion,
                                          child: Text(opcion),
                                        );
                                      }).toList(),
                                      onChanged: (String? valor) {
                                        _actualizarEvaluacion(subItem.id, valor ?? '');
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Widget de evidencias para cada pregunta
                                    EvidenciasWidget(
                                      preguntaId: subItem.id.toString(),
                                      evidencias: _evidencias[subItem.id.toString()] ?? [],
                                      onEvidenciaAgregada: (evidencia) {
                                        print('📷 DEBUG: Evidencia agregada para pregunta ${subItem.id}: ${evidencia.nombreArchivo}');
                                        setState(() {
                                          if (_evidencias[subItem.id.toString()] == null) {
                                            _evidencias[subItem.id.toString()] = [];
                                          }
                                          _evidencias[subItem.id.toString()]!.add(evidencia);
                                        });
                                        print('📷 DEBUG: Total evidencias para pregunta ${subItem.id}: ${_evidencias[subItem.id.toString()]?.length}');
                                      },
                                      onEvidenciaEliminada: (evidencia) {
                                        print('🗑️ DEBUG: Evidencia eliminada para pregunta ${subItem.id}: ${evidencia.nombreArchivo}');
                                        setState(() {
                                          _evidencias[subItem.id.toString()]?.remove(evidencia);
                                        });
                                        print('🗑️ DEBUG: Total evidencias para pregunta ${subItem.id}: ${_evidencias[subItem.id.toString()]?.length}');
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                )).toList(),
                              
                              const Divider(),
                              const SizedBox(height: 16),
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
              'GUARDAR VISITA PAE',
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