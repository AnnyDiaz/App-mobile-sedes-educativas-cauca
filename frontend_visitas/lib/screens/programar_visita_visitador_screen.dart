import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/models/municipio.dart';
import 'package:frontend_visitas/models/institucion.dart';
import 'package:frontend_visitas/models/sede.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProgramarVisitaVisitadorScreen extends StatefulWidget {
  const ProgramarVisitaVisitadorScreen({super.key});

  @override
  State<ProgramarVisitaVisitadorScreen> createState() => _ProgramarVisitaVisitadorScreenState();
}

class _ProgramarVisitaVisitadorScreenState extends State<ProgramarVisitaVisitadorScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _contratoController = TextEditingController();
  final _operadorController = TextEditingController();
  final _observacionesController = TextEditingController();
  
  // Variables de estado
  Municipio? _municipioSeleccionado;
  Institucion? _institucionSeleccionada;
  Sede? _sedeSeleccionada;
  String _tipoVisita = 'PAE';
  String _prioridad = 'normal';
  DateTime _fechaVisita = DateTime.now();
  TimeOfDay _horaVisita = TimeOfDay.now();
  Position? _ubicacionGPS;
  List<File> _evidencias = [];
  
  // Futures para cargar datos
  late Future<List<Municipio>> _futureMunicipios;
  late Future<List<Institucion>> _futureInstituciones;
  late Future<List<Sede>> _futureSedes;
  
  // Estados de carga
  bool _isLoadingGPS = false;
  bool _isLoading = false;
  bool _isLoadingData = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _inicializarFutures();
    _verificarPermisosGPS();
  }

  @override
  void dispose() {
    _contratoController.dispose();
    _operadorController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  void _inicializarFutures() {
    _futureMunicipios = _apiService.getMunicipios();
    _futureInstituciones = Future.value([]);
    _futureSedes = Future.value([]);
    
    _futureMunicipios.then((_) {
      setState(() {
        _isLoadingData = false;
      });
    }).catchError((error) {
      setState(() {
        _error = error.toString();
        _isLoadingData = false;
      });
    });
  }

  Future<void> _verificarPermisosGPS() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _mostrarError('Los servicios de ubicación están deshabilitados');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _mostrarError('Permisos de ubicación denegados');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _mostrarError('Los permisos de ubicación están permanentemente denegados');
      return;
    }
  }

  Future<void> _capturarUbicacionGPS() async {
    setState(() {
      _isLoadingGPS = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _ubicacionGPS = position;
        _isLoadingGPS = false;
      });
      
      _mostrarExito('Ubicación GPS capturada exitosamente');
    } catch (e) {
      setState(() {
        _isLoadingGPS = false;
      });
      _mostrarError('Error al capturar ubicación GPS: $e');
    }
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
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaVisita,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (fechaSeleccionada != null) {
      setState(() {
        _fechaVisita = fechaSeleccionada;
      });
    }
  }

  Future<void> _seleccionarHora() async {
    final TimeOfDay? horaSeleccionada = await showTimePicker(
      context: context,
      initialTime: _horaVisita,
    );
    
    if (horaSeleccionada != null) {
      setState(() {
        _horaVisita = horaSeleccionada;
      });
    }
  }

  Future<void> _tomarFoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? foto = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (foto != null) {
        setState(() {
          _evidencias.add(File(foto.path));
        });
        _mostrarExito('Foto agregada exitosamente');
      }
    } catch (e) {
      _mostrarError('Error al tomar foto: $e');
    }
  }

  Future<void> _seleccionarArchivo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? archivo = await picker.pickMedia();
      
      if (archivo != null) {
        setState(() {
          _evidencias.add(File(archivo.path));
        });
        _mostrarExito('Archivo agregado exitosamente');
      }
    } catch (e) {
      _mostrarError('Error al seleccionar archivo: $e');
    }
  }

  Future<void> _programarVisita() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_municipioSeleccionado == null || 
        _institucionSeleccionada == null || 
        _sedeSeleccionada == null) {
      _mostrarError('Debe seleccionar municipio, institución y sede');
      return;
    }

    if (_ubicacionGPS == null) {
      _mostrarError('Debe capturar la ubicación GPS');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Combinar fecha y hora
      final fechaHora = DateTime(
        _fechaVisita.year,
        _fechaVisita.month,
        _fechaVisita.day,
        _horaVisita.hour,
        _horaVisita.minute,
      );

      // Crear la visita
      final visitaData = {
        'sede_id': _sedeSeleccionada!.id,
        'fecha_programada': fechaHora.toIso8601String(),
        'tipo_visita': _tipoVisita,
        'prioridad': _prioridad,
        'contrato': _contratoController.text,
        'operador': _operadorController.text,
        'observaciones': _observacionesController.text,
        'municipio_id': _municipioSeleccionado!.id,
        'institucion_id': _institucionSeleccionada!.id,
        'latitud': _ubicacionGPS!.latitude,
        'longitud': _ubicacionGPS!.longitude,
        'evidencias': _evidencias.map((e) => e.path).toList(),
      };

      // Aquí se enviaría al backend
      print('🚀 Visita a programar: $visitaData');
      
      // Simular envío exitoso
      await Future.delayed(const Duration(seconds: 2));
      
      _mostrarExito('Visita programada exitosamente');
      
      // Navegar de vuelta
      if (mounted) {
        Navigator.of(context).pop();
      }
      
    } catch (e) {
      _mostrarError('Error al programar visita: $e');
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
    if (_isLoadingData) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isLoadingData = true;
                  });
                  _inicializarFutures();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Programar Nueva Visita'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSeccionUbicacion(),
              const SizedBox(height: 24),
              _buildSeccionTipoVisita(),
              const SizedBox(height: 24),
              _buildSeccionFechaHora(),
              const SizedBox(height: 24),
              _buildSeccionDetalles(),
              const SizedBox(height: 24),
              _buildSeccionEvidencias(),
              const SizedBox(height: 32),
              _buildBotonProgramar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionUbicacion() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📍 Ubicación',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Municipio
            FutureBuilder<List<Municipio>>(
              future: _futureMunicipios,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                
                final municipios = snapshot.data ?? [];
                
                return DropdownButtonFormField<Municipio>(
                  value: _municipioSeleccionado,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Municipio *',
                    border: OutlineInputBorder(),
                  ),
                  items: municipios.map((municipio) {
                    return DropdownMenuItem(
                      value: municipio,
                      child: Text(
                        municipio.nombre,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
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
                    if (value == null) return 'Seleccione un municipio';
                    return null;
                  },
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Institución
            FutureBuilder<List<Institucion>>(
              future: _futureInstituciones,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                
                final instituciones = snapshot.data ?? [];
                
                return DropdownButtonFormField<Institucion>(
                  value: _institucionSeleccionada,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Institución Educativa *',
                    border: OutlineInputBorder(),
                  ),
                  items: instituciones.map((institucion) {
                    return DropdownMenuItem(
                      value: institucion,
                      child: Text(
                        institucion.nombre,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
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
                    if (value == null) return 'Seleccione una institución';
                    return null;
                  },
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Sede
            FutureBuilder<List<Sede>>(
              future: _futureSedes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                
                final sedes = snapshot.data ?? [];
                
                return DropdownButtonFormField<Sede>(
                  value: _sedeSeleccionada,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Sede Educativa *',
                    border: OutlineInputBorder(),
                  ),
                  items: sedes.map((sede) {
                    return DropdownMenuItem(
                      value: sede,
                      child: Text(
                        sede.nombre,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: (Sede? sede) {
                    setState(() {
                      _sedeSeleccionada = sede;
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'Seleccione una sede';
                    return null;
                  },
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // GPS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingGPS ? null : _capturarUbicacionGPS,
                    icon: _isLoadingGPS 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.gps_fixed),
                    label: Text(_isLoadingGPS ? 'Capturando...' : 'Capturar GPS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _ubicacionGPS != null ? Colors.green : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                if (_ubicacionGPS != null)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        border: Border.all(color: Colors.green.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📍 GPS Capturado',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Lat: ${_ubicacionGPS!.latitude.toStringAsFixed(6)}',
                            style: TextStyle(fontSize: 12, color: Colors.green.shade600),
                          ),
                          Text(
                            'Lng: ${_ubicacionGPS!.longitude.toStringAsFixed(6)}',
                            style: TextStyle(fontSize: 12, color: Colors.green.shade600),
                          ),
                        ],
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

  Widget _buildSeccionTipoVisita() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📋 Tipo de Visita',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Tipo de visita
            DropdownButtonFormField<String>(
              value: _tipoVisita,
              decoration: const InputDecoration(
                labelText: 'Tipo de Visita *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'PAE', child: Text('PAE - Programa de Alimentación Escolar')),
                DropdownMenuItem(value: 'infraestructura', child: Text('Infraestructura')),
                DropdownMenuItem(value: 'mantenimiento', child: Text('Mantenimiento')),
                DropdownMenuItem(value: 'seguridad', child: Text('Seguridad')),
                DropdownMenuItem(value: 'otro', child: Text('Otro')),
              ],
              onChanged: (String? value) {
                setState(() {
                  _tipoVisita = value!;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Prioridad
            DropdownButtonFormField<String>(
              value: _prioridad,
              decoration: const InputDecoration(
                labelText: 'Nivel de Prioridad *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'baja', child: Text('🟢 Baja')),
                DropdownMenuItem(value: 'normal', child: Text('🟡 Normal')),
                DropdownMenuItem(value: 'alta', child: Text('🟠 Alta')),
                DropdownMenuItem(value: 'urgente', child: Text('🔴 Urgente')),
              ],
              onChanged: (String? value) {
                setState(() {
                  _prioridad = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionFechaHora() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📅 Fecha y Hora',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Fecha'),
                    subtitle: Text(
                      '${_fechaVisita.day}/${_fechaVisita.month}/${_fechaVisita.year}',
                    ),
                    onTap: _seleccionarFecha,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Hora'),
                    subtitle: Text(
                      '${_horaVisita.hour.toString().padLeft(2, '0')}:${_horaVisita.minute.toString().padLeft(2, '0')}',
                    ),
                    onTap: _seleccionarHora,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionDetalles() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📝 Detalles de la Visita',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _contratoController,
              decoration: const InputDecoration(
                labelText: 'Contrato *',
                border: OutlineInputBorder(),
                hintText: 'Número o nombre del contrato',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese el número de contrato';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _operadorController,
              decoration: const InputDecoration(
                labelText: 'Operador *',
                border: OutlineInputBorder(),
                hintText: 'Nombre del operador',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese el nombre del operador';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _observacionesController,
              decoration: const InputDecoration(
                labelText: 'Observaciones',
                border: OutlineInputBorder(),
                hintText: 'Observaciones adicionales sobre la visita',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionEvidencias() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📸 Evidencias',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _tomarFoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Tomar Foto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _seleccionarArchivo,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Archivo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            if (_evidencias.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Evidencias agregadas: ${_evidencias.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _evidencias.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          Image.file(
                            _evidencias[index],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _evidencias.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBotonProgramar() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _programarVisita,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Programando...'),
              ],
            )
          : const Text(
              '🚀 Programar Visita',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
      ),
    );
  }
}
