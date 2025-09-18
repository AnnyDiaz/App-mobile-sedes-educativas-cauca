import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:frontend_visitas/models/municipio.dart';
import 'package:frontend_visitas/models/institucion.dart';
import 'package:frontend_visitas/models/sede.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/local/db_helper.dart';
import 'package:frontend_visitas/widgets/evidencias_widget.dart';
import 'package:frontend_visitas/widgets/firma_digital_widget.dart';
import 'package:frontend_visitas/models/evidencia.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class CrearCronogramaScreen extends StatefulWidget {
  final dynamic? visitaExistente; // Visita completa PAE existente para editar
  final Map<String, dynamic>? visitaProgramadaMap; // Datos de visita programada desde calendario
  
  const CrearCronogramaScreen({
    super.key,
    this.visitaExistente,
    this.visitaProgramadaMap,
  });

  @override
  State<CrearCronogramaScreen> createState() => _CrearCronogramaScreenState();
}

class _CrearCronogramaScreenState extends State<CrearCronogramaScreen> {
  int _currentStep = 0;

  // Claves y Controladores
  final _formKey = GlobalKey<FormState>();
  final _observacionesController = TextEditingController();

  // --- Estado del Formulario ---
  DateTime? _fechaVisita;
  TimeOfDay? _horaVisita;
  String _contrato = '';
  String _operador = '';
  int? _municipioId;
  int? _institucionId;
  int? _sedeId;
  int? _profesionalId;
  String? _casoAtencionPrioritaria;
  String _tipoVisita = 'PAE';
  String _prioridad = 'normal';
  String _observaciones = '';
  
  // --- Variables para GPS ---
  Position? _ubicacionGPS;
  bool _isLoadingGPS = false;
  String? _errorGPS;

  // --- Variables para el Checklist ---
  List<dynamic>? _checklist;
  Map<int, String> _respuestasChecklist = {};
  Map<int, String> _observacionesChecklist = {};
  Map<int, List<Evidencia>> _evidenciasChecklist = {};

  // --- Variables para Firma Digital ---
  Uint8List? _firmaUsuario;
  String _nombreUsuario = '';
  String _cargoUsuario = '';
  Uint8List? _imagenAdicional;

  // --- Estados de carga ---
  bool _isLoading = false;
  bool _isLoadingData = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _inicializarValoresPorDefecto();
    _inicializarFutures();
    _verificarPermisosGPS();
  }

  /// Inicializar valores por defecto para evitar errores de null
  void _inicializarValoresPorDefecto() {
    // Valores por defecto básicos
    _fechaVisita = DateTime.now();
    _horaVisita = TimeOfDay.now();
    _tipoVisita = 'PAE';
    _prioridad = 'normal';
    _contrato = '';
    _operador = '';
    _observaciones = '';
    _respuestasChecklist = {};
    _observacionesChecklist = {};
    _evidenciasChecklist = {};
    
    // Valores por defecto para firma
    _firmaUsuario = null;
    _nombreUsuario = '';
    _cargoUsuario = '';
    _imagenAdicional = null;
  }

  Future<void> _verificarPermisosGPS() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _errorGPS = 'Los servicios de ubicación están deshabilitados';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _errorGPS = 'Permisos de ubicación denegados';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _errorGPS = 'Permisos de ubicación denegados permanentemente';
      });
      return;
    }
  }

  Future<void> _capturarGPS() async {
    setState(() {
      _isLoadingGPS = true;
      _errorGPS = null;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _ubicacionGPS = position;
        _isLoadingGPS = false;
      });
    } catch (e) {
      setState(() {
        _errorGPS = 'Error al obtener ubicación: $e';
        _isLoadingGPS = false;
      });
    }
  }

  void _inicializarFutures() {
    _verificarAutenticacion();
    _cargarChecklist();
    _cargarPerfilUsuario();
    if (widget.visitaExistente != null) {
      _cargarDatosVisitaExistente();
    }
    if (widget.visitaProgramadaMap != null) {
      _cargarDatosVisitaProgramada();
    }
  }

  /// Carga el perfil del usuario para la firma
  Future<void> _cargarPerfilUsuario() async {
    try {
      final apiService = ApiService();
      final perfil = await apiService.getPerfilUsuario();
      
      if (mounted) {
        setState(() {
          _nombreUsuario = perfil['nombre'] ?? 'Usuario';
          _cargoUsuario = perfil['rol'] ?? 'Visitador';
        });
      }
    } catch (e) {
      print('⚠️ Error al cargar perfil de usuario: $e');
      // Usar valores por defecto
      setState(() {
        _nombreUsuario = 'Usuario';
        _cargoUsuario = 'Visitador';
      });
    }
  }

  /// Maneja la captura de firma del usuario
  void _onFirmaCapturada(Uint8List? firma) {
    setState(() {
      _firmaUsuario = firma;
    });
    
    if (firma != null) {
      print('✅ Firma capturada: ${firma.length} bytes');
    } else {
      print('🗑️ Firma eliminada');
    }
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  /// Carga los datos de una visita existente
  void _cargarDatosVisitaExistente() {
    if (widget.visitaExistente != null) {
      final visita = widget.visitaExistente;
      setState(() {
        _fechaVisita = visita['fecha_visita'] != null 
            ? DateTime.parse(visita['fecha_visita']) 
            : null;
        _horaVisita = visita['hora_visita'] != null 
            ? TimeOfDay.fromDateTime(DateTime.parse(visita['hora_visita']))
            : null;
        _contrato = visita['contrato'] ?? '';
        _operador = visita['operador'] ?? '';
        _municipioId = visita['municipio_id'];
        _institucionId = visita['institucion_id'];
        _sedeId = visita['sede_id'];
        _casoAtencionPrioritaria = visita['caso_atencion_prioritaria'];
        _tipoVisita = visita['tipo_visita'] ?? 'PAE';
        _prioridad = visita['prioridad'] ?? 'normal';
        _observaciones = visita['observaciones'] ?? '';
        
        _observacionesController.text = _observaciones;
      });
    }
  }

  /// Carga los datos de una visita programada desde el calendario
  void _cargarDatosVisitaProgramada() {
    if (widget.visitaProgramadaMap != null) {
      final visita = widget.visitaProgramadaMap!;
      setState(() {
        // Cargar datos básicos
        _fechaVisita = visita['fecha_programada'] != null 
            ? DateTime.parse(visita['fecha_programada']) 
            : DateTime.now();
        _horaVisita = TimeOfDay.now();
        _municipioId = visita['municipio_id'];
        _institucionId = visita['institucion_id'];
        _sedeId = visita['sede_id'];
        _observaciones = visita['observaciones'] ?? '';
        _tipoVisita = visita['tipo_visita'] ?? 'PAE';
        _prioridad = visita['prioridad'] ?? 'normal';
        
        // Actualizar el controlador de observaciones
        _observacionesController.text = _observaciones;
        
        print('📅 Datos de visita programada cargados exitosamente');
        print('   - Fecha: $_fechaVisita');
        print('   - Municipio: $_municipioId');
        print('   - Institución: $_institucionId');
        print('   - Sede: $_sedeId');
        print('   - Observaciones: $_observaciones');
      });
    }
  }

  void _verificarAutenticacion() async {
    final apiService = ApiService();
    final isAuth = await apiService.isAuthenticated();
    
    if (!isAuth) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesión expirada. Por favor, inicie sesión nuevamente.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pushReplacementNamed(context, '/auth');
        return;
      }
    }
    
    _setProfesionalId();
  }

  void _setProfesionalId() async {
    final id = await ApiService().getUsuarioId();
    if (mounted) {
      setState(() {
        _profesionalId = id;
        _isLoadingData = false;
      });
    }
  }

  void _cargarChecklist() async {
    try {
      final checklist = await ApiService().getChecklist();
      if (mounted) {
        setState(() {
          _checklist = checklist;
          
          // Inicializar todas las respuestas del checklist con "N/A" por defecto
          _respuestasChecklist.clear();
          for (var categoria in checklist) {
            if (categoria['items'] != null) {
              for (var item in categoria['items']) {
                int itemId = item['id'] ?? 0;
                if (itemId > 0) {
                  _respuestasChecklist[itemId] = "N/A";
                }
              }
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar checklist: $e';
        });
      }
    }
  }

  void _cargarInstituciones(int municipioId) async {
    try {
      final instituciones = await ApiService().getInstitucionesPorMunicipio(municipioId);
      if (mounted) {
        setState(() {
          // Las instituciones se cargan dinámicamente en el FutureBuilder
        });
      }
    } catch (e) {
      print('Error al cargar instituciones: $e');
    }
  }

  void _cargarSedes(int municipioId, int institucionId) async {
    try {
      final sedes = await ApiService().getSedesPorInstitucion(institucionId);
      if (mounted) {
        setState(() {
          // Las sedes se cargan dinámicamente en el FutureBuilder
        });
        
        // Mostrar información útil sobre las sedes disponibles
        if (sedes.isEmpty) {
          print('⚠️ No hay sedes disponibles para la institución ID: $institucionId');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ No hay sedes disponibles para esta institución. Esto puede indicar un problema con los datos.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          print('✅ Sedes cargadas: ${sedes.length} disponibles');
          print('📋 IDs de sedes: ${sedes.map((s) => s.id).toList()}');
        }
      }
    } catch (e) {
      print('Error al cargar sedes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al cargar sedes: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
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
                  _cargarChecklist();
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
        title: Text(widget.visitaExistente != null ? 'Editar Visita PAE' : 'Crear Visita PAE 2025'),
        centerTitle: true,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: _nextStep,
          onStepCancel: _prevStep,
          steps: _buildSteps(),
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : details.onStepContinue,
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
                              Text('Guardando...'),
                            ],
                          )
                        : Text(_currentStep == _buildSteps().length - 1 ? '🚀 GUARDAR CRONOGRAMA' : 'SIGUIENTE'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (_currentStep != 0)
                    Expanded(
                      child: TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('ANTERIOR'),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text('📋 Datos del Cronograma'),
        content: _buildStep1(),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('📍 Ubicación'),
        content: _buildStep2(),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('⚡ Caso de Atención Prioritaria'),
        content: _buildStep3(),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('📝 Observaciones Generales'),
        content: _buildStep4(),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('✅ Checklist PAE'),
        content: _buildStep5(),
        isActive: _currentStep >= 4,
        state: _currentStep > 4 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('✍️ Firma Digital'),
        content: _buildStep6(),
        isActive: _currentStep >= 5,
        state: _currentStep > 5 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('🎯 Finalizar'),
        content: _buildStep7(),
        isActive: _currentStep >= 6,
      ),
    ];
  }

  void _nextStep() {
    // Validar campos del paso actual antes de avanzar
    if (!_validarPasoActual()) return;
    
    if (_currentStep < _buildSteps().length - 1) {
      setState(() => _currentStep += 1);
    } else {
      _guardarVisita();
    }
  }

  /// Validar los campos del paso actual antes de avanzar
  bool _validarPasoActual() {
    print('🔍 Validando paso $_currentStep');
    
    switch (_currentStep) {
      case 0: // Datos del Cronograma
        print('📅 Fecha: $_fechaVisita');
        print('⏰ Hora: $_horaVisita');
        print('📋 Contrato: "$_contrato"');
        print('👤 Operador: "$_operador"');
        
        if (!_formKey.currentState!.validate()) {
          print('❌ Validación del formulario falló');
          return false;
        }
        
        if (_fechaVisita == null) {
          print('❌ Fecha de visita es null');
          _mostrarError('Debes seleccionar una fecha de visita.');
          return false;
        }
        
        if (_horaVisita == null) {
          print('❌ Hora de visita es null');
          _mostrarError('Debes seleccionar una hora de visita.');
          return false;
        }
        
        if (_contrato.trim().isEmpty) {
          print('❌ Contrato está vacío');
          _mostrarError('Debes ingresar el número de contrato.');
          return false;
        }
        
        if (_operador.trim().isEmpty) {
          print('❌ Operador está vacío');
          _mostrarError('Debes ingresar el nombre del operador.');
          return false;
        }
        
        print('✅ Paso 0 validado correctamente');
        return true;
        
      case 1: // Ubicación
        print('🏘️ Municipio ID: $_municipioId');
        print('🏫 Institución ID: $_institucionId');
        print('📍 Sede ID: $_sedeId');
        
        if (_municipioId == null || _institucionId == null || _sedeId == null) {
          print('❌ Ubicación incompleta');
          _mostrarError('Debes seleccionar la ubicación completa (Municipio, Institución y Sede).');
          return false;
        }
        
        // Validar que los IDs sean válidos (no sean 0 o negativos)
        if (_municipioId! <= 0 || _institucionId! <= 0 || _sedeId! <= 0) {
          print('❌ IDs inválidos detectados');
          _mostrarError('Error: Se detectaron IDs inválidos. Por favor, recarga la página y selecciona nuevamente la ubicación.');
          return false;
        }
        
        print('✅ Paso 1 validado correctamente');
        return true;
        
      case 2: // Caso de Atención
        print('⚡ Caso de atención: $_casoAtencionPrioritaria');
        
        if (_casoAtencionPrioritaria == null) {
          print('❌ Caso de atención no seleccionado');
          _mostrarError('Debes seleccionar el caso de atención prioritaria.');
          return false;
        }
        
        print('✅ Paso 2 validado correctamente');
        return true;
        
      case 3: // Observaciones (opcional)
        print('✅ Paso 3 (opcional) - siempre válido');
        return true;
        
      case 4: // Checklist
        print('📋 Checklist: ${_checklist?.length ?? 0} items');
        print('📝 Respuestas: ${_respuestasChecklist.length} respuestas');
        
        if (_checklist == null || _checklist!.isEmpty) {
          print('❌ Checklist no cargado');
          _mostrarError('El checklist aún se está cargando. Por favor, espera un momento.');
          return false;
        }
        
        // Las evidencias son opcionales, solo validamos que el checklist esté cargado
        print('✅ Paso 4 validado correctamente (evidencias opcionales)');
        return true;
        
      case 5: // Firma Digital
        print('✍️ Firma: ${_firmaUsuario != null ? "Capturada" : "No capturada"}');
        print('👤 Usuario: $_nombreUsuario');
        
        if (_firmaUsuario == null) {
          print('❌ Firma no capturada');
          _mostrarError('Debes capturar tu firma digital antes de continuar.');
          return false;
        }
        
        if (_nombreUsuario.trim().isEmpty) {
          print('❌ Nombre de usuario vacío');
          _mostrarError('Error: No se pudo cargar tu información de usuario.');
          return false;
        }
        
        print('✅ Paso 5 validado correctamente');
        return true;
        
      default:
        print('✅ Paso $_currentStep - siempre válido');
        return true;
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  Widget _buildStep1() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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
          const SizedBox(height: 16),
          
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Contrato *',
              border: OutlineInputBorder(),
              hintText: 'Número o nombre del contrato',
            ),
            onChanged: (value) => _contrato = value,
            validator: (value) => value!.isEmpty ? 'El contrato es requerido' : null,
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Operador *',
              border: OutlineInputBorder(),
              hintText: 'Nombre del operador',
            ),
            onChanged: (value) => _operador = value,
            validator: (value) => value!.isEmpty ? 'El operador es requerido' : null,
          ),
          const SizedBox(height: 16),
          
          // FECHA Y HORA SEPARADAS CON ICONOS
          const Text(
            'Fecha y Hora',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              // FECHA
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.red[600]),
                            const SizedBox(width: 8),
                            const Text(
                              'Fecha',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _fechaVisita != null
                              ? DateFormat('dd/MM/yyyy').format(_fechaVisita!)
                              : 'Seleccionar fecha',
                          style: TextStyle(
                            fontSize: 16,
                            color: _fechaVisita != null ? Colors.black : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Seleccionar'),
                          onPressed: _pickFechaVisita,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // HORA
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.blue[600]),
                            const SizedBox(width: 8),
                            const Text(
                              'Hora',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _horaVisita != null
                              ? '${_horaVisita!.hour.toString().padLeft(2, '0')}:${_horaVisita!.minute.toString().padLeft(2, '0')}'
                              : 'Seleccionar hora',
                          style: TextStyle(
                            fontSize: 16,
                            color: _horaVisita != null ? Colors.black : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.access_time),
                          label: const Text('Seleccionar'),
                          onPressed: _pickHoraVisita,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        // CAPTURA DE GPS
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    const Text(
                      'Ubicación GPS',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (_ubicacionGPS != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[600]),
                            const SizedBox(width: 8),
                            const Text(
                              'Ubicación capturada',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Latitud: ${_ubicacionGPS!.latitude.toStringAsFixed(6)}'),
                        Text('Longitud: ${_ubicacionGPS!.longitude.toStringAsFixed(6)}'),
                        Text('Precisión: ${_ubicacionGPS!.accuracy.toStringAsFixed(2)}m'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange[600]),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Ubicación GPS no capturada. Usa el botón para capturar tu ubicación actual.',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                if (_errorGPS != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorGPS!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: _isLoadingGPS 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location),
                        label: Text(_isLoadingGPS ? 'Capturando...' : 'Capturar GPS'),
                        onPressed: _isLoadingGPS ? null : _capturarGPS,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_ubicacionGPS != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Actualizar'),
                          onPressed: _capturarGPS,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // SELECCIÓN DE UBICACIÓN
        const Text(
          'Selecciona la ubicación de la visita:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        // Información sobre IDs válidos
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  const Text(
                    'Información de IDs válidos:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('• Municipios válidos: ID ≥ 2', style: TextStyle(fontSize: 12)),
              Text('• Instituciones válidas: ID ≥ 29', style: TextStyle(fontSize: 12)),
              Text('• Sedes válidas: ID ≥ 3', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        FutureBuilder<List<Municipio>>(
          future: ApiService().getMunicipios(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text('Error al cargar municipios: ${snapshot.error}'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }
            
            final municipios = snapshot.data ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<int>(
                  value: _municipioId,
                  decoration: const InputDecoration(
                    labelText: 'Municipio *',
                    border: OutlineInputBorder(),
                  ),
                  items: municipios.map((municipio) {
                    return DropdownMenuItem(
                      value: municipio.id,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: Text(
                          '${municipio.nombre} (ID: ${municipio.id})',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (int? value) {
                    setState(() {
                      _municipioId = value;
                      _institucionId = null;
                      _sedeId = null;
                    });
                    if (value != null) {
                      print('🏘️ Municipio seleccionado: ID $value');
                      _cargarInstituciones(value);
                    }
                  },
                ),
                if (_municipioId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Municipio seleccionado: ID $_municipioId',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        
        if (_municipioId != null)
          FutureBuilder<List<Institucion>>(
            future: ApiService().getInstitucionesPorMunicipio(_municipioId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final instituciones = snapshot.data ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<int>(
                    value: _institucionId,
                    decoration: const InputDecoration(
                      labelText: 'Institución *',
                      border: OutlineInputBorder(),
                    ),
                    items: instituciones.map((institucion) {
                      return DropdownMenuItem(
                        value: institucion.id,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Text(
                            '${institucion.nombre} (ID: ${institucion.id})',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (int? value) {
                      setState(() {
                        _institucionId = value;
                        _sedeId = null;
                      });
                      if (value != null) {
                        print('📚 Institución seleccionada: ID $value');
                        _cargarSedes(_municipioId!, value);
                      }
                    },
                  ),
                  if (_institucionId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Institución seleccionada: ID $_institucionId',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                ],
              );
            },
          ),
        const SizedBox(height: 16),
        
        if (_institucionId != null)
          FutureBuilder<List<Sede>>(
            future: ApiService().getSedesPorInstitucion(_institucionId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final sedes = snapshot.data ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<int>(
                    value: _sedeId,
                    decoration: const InputDecoration(
                      labelText: 'Sede *',
                      border: OutlineInputBorder(),
                    ),
                    items: sedes.map((sede) {
                      return DropdownMenuItem(
                        value: sede.id,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Text(
                            '${sede.nombre} (ID: ${sede.id})',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (int? value) {
                      setState(() {
                        _sedeId = value;
                      });
                      if (value != null) {
                        print('🏫 Sede seleccionada: ID $value');
                      }
                    },
                  ),
                  if (_sedeId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Sede seleccionada: ID $_sedeId',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  if (sedes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          border: Border.all(color: Colors.orange),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange[600], size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '⚠️ No hay sedes disponibles para esta institución. Esto puede indicar un problema con los datos.',
                                style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildStep3() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ApiService().getCasosAtencionPrioritaria(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cargando casos de atención prioritaria...'),
              ],
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text('Error al cargar casos: ${snapshot.error}'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        
        final casos = snapshot.data ?? [];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona el caso de atención prioritaria:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (casos.isEmpty)
              const Center(
                child: Text(
                  'No hay casos de atención prioritaria disponibles',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...casos.map((caso) => RadioListTile<String>(
                title: Text(caso['nombre']),
                subtitle: Text(_getSubtitleCaso(caso['id'])),
                value: caso['id'],
                groupValue: _casoAtencionPrioritaria,
                onChanged: (value) => setState(() => _casoAtencionPrioritaria = value),
              )),
          ],
        );
      },
    );
  }

  String _getSubtitleCaso(String id) {
    switch (id) {
      case 'SI':
        return 'Servicio funcionando correctamente';
      case 'NO':
        return 'Servicio no funcionando';
      case 'NO HUBO SERVICIO':
        return 'No se prestó el servicio';
      case 'ACTA RAPIDA':
        return 'Acta de verificación rápida';
      default:
        return '';
    }
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Observaciones Generales:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _observacionesController,
          decoration: const InputDecoration(
            labelText: 'Observaciones',
            border: OutlineInputBorder(),
            hintText: 'Observaciones generales sobre la visita, condiciones especiales, etc.',
          ),
          maxLines: 4,
          onChanged: (value) => _observaciones = value,
        ),
      ],
    );
  }

  Widget _buildStep5() {
    if (_checklist == null) {
      return const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando checklist PAE...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✅ CHECKLIST PAE - EVALUACIÓN COMPLETA',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
                     const Text(
             'Evalúa cada ítem y adjunta evidencias según sea necesario (opcional):',
             style: TextStyle(fontSize: 14, color: Colors.grey),
           ),
          const SizedBox(height: 16),
          ..._checklist!.map((categoria) => _buildCategoriaChecklist(categoria)),
        ],
      ),
    );
  }

  Widget _buildCategoriaChecklist(dynamic categoria) {
    if (categoria == null) return const SizedBox.shrink();
    
    // Manejar tanto Map como objetos ItemPAE
    String nombre;
    List<dynamic> items;
    
    if (categoria is Map<String, dynamic>) {
      nombre = categoria['nombre']?.toString() ?? 'Sin nombre';
      items = categoria['items'] ?? [];
    } else {
      // Si es un objeto ItemPAE
      try {
        nombre = categoria.nombre?.toString() ?? 'Sin nombre';
        items = categoria.items ?? [];
      } catch (e) {
        print('Error accediendo a propiedades de categoria: $e');
        nombre = 'Error en categoría';
        items = [];
      }
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: (items as List).map((item) => _buildItemChecklist(item)).toList(),
      ),
    );
  }

  Widget _buildItemChecklist(dynamic item) {
    if (item == null) return const SizedBox.shrink();
    
    // Manejar tanto Map como objetos SubItemPAE
    String pregunta;
    int id;
    
    if (item is Map<String, dynamic>) {
      pregunta = item['pregunta_texto']?.toString() ?? 'Sin pregunta';
      id = item['id'] ?? 0;
    } else {
      // Si es un objeto SubItemPAE
      try {
        pregunta = item.preguntaTexto?.toString() ?? 'Sin pregunta';
        id = item.id ?? 0;
      } catch (e) {
        print('Error accediendo a propiedades de item: $e');
        pregunta = 'Error en pregunta';
        id = 0;
      }
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pregunta,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          
          // Dropdown de respuesta
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Respuesta *',
              border: OutlineInputBorder(),
            ),
            value: _respuestasChecklist[id] ?? "N/A",
            items: const [
              DropdownMenuItem(value: "Cumple", child: Text("✅ Cumple")),
              DropdownMenuItem(value: "Cumple Parcialmente", child: Text("✔️ Cumple Parcialmente")),
              DropdownMenuItem(value: "No Cumple", child: Text("❌ No Cumple")),
              DropdownMenuItem(value: "N/A", child: Text("N/A")),
              DropdownMenuItem(value: "N/O", child: Text("N/O")),
            ],
            onChanged: (value) {
              setState(() {
                _respuestasChecklist[id] = value ?? "N/A";
              });
            },
          ),
          const SizedBox(height: 8),
          
          // Campo de observaciones
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Observaciones',
              border: OutlineInputBorder(),
              hintText: 'Observaciones específicas para este ítem',
            ),
            maxLines: 2,
            onChanged: (value) {
              setState(() {
                _observacionesChecklist[id] = value;
              });
            },
          ),
          const SizedBox(height: 8),
          
          // Widget de evidencias
          EvidenciasWidget(
            preguntaId: id.toString(),
            evidencias: _evidenciasChecklist[id] ?? [],
            onEvidenciaAgregada: (evidencia) {
              setState(() {
                if (!_evidenciasChecklist.containsKey(id)) {
                  _evidenciasChecklist[id] = [];
                }
                _evidenciasChecklist[id]!.add(evidencia);
              });
            },
            onEvidenciaEliminada: (evidencia) {
              setState(() {
                if (_evidenciasChecklist.containsKey(id)) {
                  _evidenciasChecklist[id]!.removeWhere((e) => e.id == evidencia.id);
                }
              });
            },
          ),
          
          const Divider(),
        ],
      ),
    );
  }



  Widget _buildStep6() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del usuario
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue[600], size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Información del Usuario',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Datos del profesional que realiza la visita',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Campo de nombre (solo lectura)
                  TextFormField(
                    initialValue: _nombreUsuario,
                    decoration: InputDecoration(
                      labelText: 'Nombre del Profesional *',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    readOnly: true,
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  
                  // Campo de cargo (solo lectura)
                  TextFormField(
                    initialValue: _cargoUsuario,
                    decoration: InputDecoration(
                      labelText: 'Cargo/Rol *',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    readOnly: true,
                    enabled: false,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Widget de firma digital
          FirmaDigitalWidget(
            titulo: 'Firma Digital del Profesional',
            subtitulo: 'Captura tu firma para validar la visita',
            onFirmaCapturada: _onFirmaCapturada,
            firmaExistente: _firmaUsuario,
            esEditable: true,
          ),
          
          const SizedBox(height: 20),
          
          // Campo para subir foto/evidencia adicional
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.photo_camera, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Foto de Firma Adicional',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Toma una foto de la firma o evidencia adicional relacionada con la visita (opcional)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[600],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Botón para seleccionar imagen
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _seleccionarImagenAdicional,
                      icon: Icon(Icons.camera_alt, size: 18),
                      label: Text('Tomar Foto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_imagenAdicional != null)
                      ElevatedButton.icon(
                        onPressed: _eliminarImagenAdicional,
                        icon: Icon(Icons.delete, size: 18),
                        label: Text('Eliminar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                  ],
                ),
                
                // Vista previa de la imagen seleccionada
                if (_imagenAdicional != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _imagenAdicional!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, color: Colors.grey[400], size: 48),
                                Text(
                                  'Error al cargar imagen',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Instrucciones adicionales
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Tu firma digital es obligatoria para completar la visita. Asegúrate de que sea clara y legible.',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep7() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🎯 Resumen del Cronograma PAE',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        _buildResumenItem('📅 Fecha', _fechaVisita != null 
            ? DateFormat('dd/MM/yyyy').format(_fechaVisita!)
            : 'No seleccionada'),
        _buildResumenItem('🕐 Hora', _horaVisita != null 
            ? '${_horaVisita!.hour.toString().padLeft(2, '0')}:${_horaVisita!.minute.toString().padLeft(2, '0')}'
            : 'No seleccionada'),
        _buildResumenItem('📍 GPS', _ubicacionGPS != null 
            ? 'Capturado (${_ubicacionGPS!.latitude.toStringAsFixed(6)}, ${_ubicacionGPS!.longitude.toStringAsFixed(6)})'
            : 'No capturado'),
        _buildResumenItem('📋 Tipo', _tipoVisita),
        _buildResumenItem('⚡ Prioridad', _prioridad),
        _buildResumenItem('📝 Contrato', _contrato),
        _buildResumenItem('👤 Operador', _operador),
        _buildResumenItem('🏛️ Municipio', _municipioId != null ? 'ID: $_municipioId' : 'No seleccionado'),
        _buildResumenItem('🏫 Institución', _institucionId != null ? 'ID: $_institucionId' : 'No seleccionada'),
        _buildResumenItem('📍 Sede', _sedeId != null ? 'ID: $_sedeId' : 'No seleccionado'),
        
        // Validación de IDs
        const SizedBox(height: 16),
        _buildValidacionIds(),
        _buildResumenItem('🚨 Caso', _casoAtencionPrioritaria ?? 'No seleccionado'),
        _buildResumenItem('📝 Observaciones', _observaciones.isNotEmpty ? _observaciones : 'Sin observaciones'),
        _buildResumenItem('✅ Checklist', '${_respuestasChecklist.length} ítems evaluados'),
        _buildResumenItem('🆔 IDs Checklist', _getIdsChecklistResumen()),
        _buildResumenItem('📸 Evidencias', '${_evidenciasChecklist.values.fold(0, (sum, list) => sum + list.length)} archivos'),
        _buildResumenItem('✍️ Firma Digital', _firmaUsuario != null ? 'Capturada' : 'No capturada'),
        _buildResumenItem('📸 Imagen Adicional', _imagenAdicional != null ? 'Seleccionada' : 'No seleccionada'),
        _buildResumenItem('👤 Profesional', _nombreUsuario.isNotEmpty ? _nombreUsuario : 'No especificado'),
        
        const SizedBox(height: 16),
        const Text(
          'Revise todos los datos antes de guardar. Presione "GUARDAR CRONOGRAMA" para finalizar.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
          
        // Botón de depuración temporal
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _mostrarEstadoDepuracion,
          icon: const Icon(Icons.bug_report),
          label: const Text('🐛 DEPURAR ESTADO'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildResumenItem(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidacionIds() {
    bool municipioValido = _municipioId != null && _municipioId! >= 2;
    bool institucionValida = _institucionId != null && _institucionId! >= 29;
    bool sedeValida = _sedeId != null && _sedeId! >= 3;
    
    bool todosValidos = municipioValido && institucionValida && sedeValida;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: todosValidos ? Colors.green[50] : Colors.red[50],
        border: Border.all(
          color: todosValidos ? Colors.green : Colors.red,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                todosValidos ? Icons.check_circle : Icons.error,
                color: todosValidos ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                todosValidos ? '✅ IDs de ubicación válidos' : '❌ IDs de ubicación inválidos',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: todosValidos ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Validación de municipio
          Row(
            children: [
              Icon(
                municipioValido ? Icons.check : Icons.close,
                color: municipioValido ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Municipio ID $_municipioId: ${municipioValido ? 'Válido' : 'Inválido (debe ser ≥ 2)'}',
                style: TextStyle(
                  color: municipioValido ? Colors.green : Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          // Validación de institución
          Row(
            children: [
              Icon(
                institucionValida ? Icons.check : Icons.close,
                color: institucionValida ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Institución ID $_institucionId: ${institucionValida ? 'Válida' : 'Inválida (debe ser ≥ 29)'}',
                style: TextStyle(
                  color: institucionValida ? Colors.green : Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          // Validación de sede
          Row(
            children: [
              Icon(
                sedeValida ? Icons.check : Icons.close,
                color: sedeValida ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Sede ID $_sedeId: ${sedeValida ? 'Válida' : 'Inválida (debe ser ≥ 3)'}',
                style: TextStyle(
                  color: sedeValida ? Colors.green : Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          if (!todosValidos) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '⚠️ No podrás guardar el cronograma hasta que todos los IDs sean válidos. Recarga la página y selecciona nuevamente la ubicación.',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _pickFechaVisita() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaVisita ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );
    if (picked != null && mounted) {
      setState(() => _fechaVisita = picked);
    }
  }

  void _pickHoraVisita() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaVisita ?? TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() => _horaVisita = picked);
    }
  }

  bool _validarCampos() {
    print('🔍 === INICIANDO VALIDACIÓN COMPLETA ===');
    print('📅 Fecha visita: $_fechaVisita');
    print('⏰ Hora visita: $_horaVisita');
    print('🏘️ Municipio ID: $_municipioId');
    print('🏫 Institución ID: $_institucionId');
    print('📍 Sede ID: $_sedeId');
    print('⚡ Caso atención: $_casoAtencionPrioritaria');
    print('👤 Profesional ID: $_profesionalId');
    print('📋 Checklist cargado: ${_checklist != null}');
    print('📝 Respuestas checklist: ${_respuestasChecklist.length}');
    
    if (_fechaVisita == null) {
      print('❌ FALLA: Fecha de visita es null');
      _mostrarError('Debes seleccionar una fecha de visita.');
      return false;
    }
    if (_horaVisita == null) {
      print('❌ FALLA: Hora de visita es null');
      _mostrarError('Debes seleccionar una hora de visita.');
      return false;
    }
    if (_municipioId == null || _institucionId == null || _sedeId == null) {
      print('❌ FALLA: Ubicación incompleta - Municipio: $_municipioId, Institución: $_institucionId, Sede: $_sedeId');
      _mostrarError('Debes seleccionar la ubicación completa (Municipio, Institución y Sede).');
      return false;
    }
    
    // Validar que los IDs de ubicación sean válidos
    if (_municipioId! <= 0 || _institucionId! <= 0 || _sedeId! <= 0) {
      print('❌ FALLA: IDs de ubicación inválidos - Municipio: $_municipioId, Institución: $_institucionId, Sede: $_sedeId');
      _mostrarError('Error: Se detectaron IDs de ubicación inválidos. Por favor, recarga la página y selecciona nuevamente la ubicación.');
      return false;
    }
    
    // Validar que el municipio ID sea al menos 2 (según la base de datos)
    if (_municipioId! < 2) {
      print('❌ FALLA: ID de municipio inválido: $_municipioId (debe ser >= 2)');
      _mostrarError('Error: ID de municipio inválido. Los municipios válidos empiezan desde ID 2.');
      return false;
    }
    
    // Validar que la institución ID sea al menos 29 (según la base de datos)
    if (_institucionId! < 29) {
      print('❌ FALLA: ID de institución inválido: $_institucionId (debe ser >= 29)');
      _mostrarError('Error: ID de institución inválido. Las instituciones válidas empiezan desde ID 29.');
      return false;
    }
    
    // Validar que la sede ID sea al menos 3 (según la base de datos)
    if (_sedeId! < 3) {
      print('❌ FALLA: ID de sede inválido: $_sedeId (debe ser >= 3)');
      _mostrarError('Error: ID de sede inválido. Las sedes válidas empiezan desde ID 3.');
      return false;
    }
    
    if (_casoAtencionPrioritaria == null) {
      print('❌ FALLA: Caso de atención prioritaria no seleccionado');
      _mostrarError('Debes seleccionar el caso de atención prioritaria.');
      return false;
    }
    if (_profesionalId == null) {
      print('❌ FALLA: Profesional ID es null');
      _mostrarError('No se pudo identificar al usuario. Intenta reiniciar sesión.');
      return false;
    }
    if (_checklist == null) {
      print('❌ FALLA: Checklist no está cargado');
      _mostrarError('El checklist aún se está cargando. Por favor, espera un momento.');
      return false;
    }
    if (_respuestasChecklist.isEmpty) {
      print('❌ FALLA: No hay respuestas en el checklist');
      _mostrarError('Debes completar al menos un ítem del checklist.');
      return false;
    }
    
    // Validar IDs del checklist
    if (!_validarChecklistIds()) {
      print('❌ FALLA: Validación del checklist falló');
      return false;
    }
    
    print('✅ === VALIDACIÓN COMPLETA EXITOSA ===');
    return true;
  }
  
  /// Validar que los IDs del checklist sean válidos
  bool _validarChecklistIds() {
    if (_checklist == null || _respuestasChecklist.isEmpty) {
      return true; // No hay nada que validar
    }
    
    // Extraer todos los IDs válidos del checklist
    Set<int> idsValidos = {};
    for (var categoria in _checklist!) {
      if (categoria['items'] != null) {
        for (var item in categoria['items']) {
          idsValidos.add(item['id']);
        }
      }
    }
    
    // Validar cada respuesta del checklist
    List<int> idsInvalidos = [];
    for (int id in _respuestasChecklist.keys) {
      if (!idsValidos.contains(id)) {
        idsInvalidos.add(id);
      }
    }
    
    if (idsInvalidos.isNotEmpty) {
      _mostrarError('❌ Se detectaron IDs del checklist inválidos: $idsInvalidos\n\nPor favor, recarga la página y vuelve a completar el checklist.');
      return false;
    }
    
    return true;
  }
  
  /// Obtener resumen de IDs del checklist para mostrar en el resumen
  String _getIdsChecklistResumen() {
    if (_respuestasChecklist.isEmpty) {
      return 'Sin respuestas';
    }
    
    List<String> ids = _respuestasChecklist.keys.map((id) => id.toString()).toList();
    return 'IDs: ${ids.join(', ')}';
  }

  /// Función de depuración para mostrar el estado actual
  void _mostrarEstadoDepuracion() {
    String estado = '''
🔍 === ESTADO ACTUAL DEL CRONOGRAMA ===

📅 Fecha visita: ${_fechaVisita?.toIso8601String() ?? 'NULL'}
⏰ Hora visita: ${_horaVisita?.toString() ?? 'NULL'}
📋 Contrato: "$_contrato"
👤 Operador: "$_operador"

🏘️ Municipio ID: $_municipioId
🏫 Institución ID: $_institucionId
📍 Sede ID: $_sedeId

⚡ Caso atención: $_casoAtencionPrioritaria
👤 Profesional ID: $_profesionalId

📋 Checklist cargado: ${_checklist != null}
📝 Respuestas checklist: ${_respuestasChecklist.length}
📸 Evidencias: ${_evidenciasChecklist.values.fold(0, (sum, list) => sum + list.length)}

🔍 === VALIDACIONES ===
✅ Formulario válido: ${_formKey.currentState?.validate() ?? false}
✅ Fecha válida: ${_fechaVisita != null}
✅ Hora válida: ${_horaVisita != null}
✅ Contrato válido: ${_contrato.trim().isNotEmpty}
✅ Operador válido: ${_operador.trim().isNotEmpty}
✅ Municipio válido: ${_municipioId != null && _municipioId! >= 2}
✅ Institución válida: ${_institucionId != null && _institucionId! >= 29}
✅ Sede válida: ${_sedeId != null && _sedeId! >= 3}
✅ Caso válido: ${_casoAtencionPrioritaria != null}
✅ Profesional válido: ${_profesionalId != null}
✅ Checklist válido: ${_checklist != null}
✅ Respuestas válidas: ${_respuestasChecklist.isNotEmpty}

🔍 === PROBLEMAS DETECTADOS ===
''';

    // Identificar problemas específicos
    List<String> problemas = [];
    
    if (_fechaVisita == null) problemas.add('❌ Fecha de visita es NULL');
    if (_horaVisita == null) problemas.add('❌ Hora de visita es NULL');
    if (_contrato.trim().isEmpty) problemas.add('❌ Contrato está vacío');
    if (_operador.trim().isEmpty) problemas.add('❌ Operador está vacío');
    if (_municipioId == null) problemas.add('❌ Municipio ID es NULL');
    if (_institucionId == null) problemas.add('❌ Institución ID es NULL');
    if (_sedeId == null) problemas.add('❌ Sede ID es NULL');
    if (_casoAtencionPrioritaria == null) problemas.add('❌ Caso de atención es NULL');
    if (_profesionalId == null) problemas.add('❌ Profesional ID es NULL');
    if (_checklist == null) problemas.add('❌ Checklist no está cargado');
    if (_respuestasChecklist.isEmpty) problemas.add('❌ No hay respuestas en el checklist');
    
    if (_municipioId != null && _municipioId! < 2) {
      problemas.add('❌ Municipio ID $_municipioId es menor que 2');
    }
    if (_institucionId != null && _institucionId! < 29) {
      problemas.add('❌ Institución ID $_institucionId es menor que 29');
    }
    if (_sedeId != null && _sedeId! < 3) {
      problemas.add('❌ Sede ID $_sedeId es menor que 3');
    }
    
    if (problemas.isEmpty) {
      problemas.add('✅ No se detectaron problemas');
    }
    
    estado += problemas.join('\n');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🐛 Estado de Depuración'),
        content: SingleChildScrollView(
          child: Text(estado, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  String _timeOfDayToIso8601String(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return dateTime.toIso8601String();
  }

  Future<void> _guardarVisita() async {
    print('🚀 === INICIANDO GUARDADO DE CRONOGRAMA ===');
    print('🔍 Validando formulario...');
    
    if (!_formKey.currentState!.validate()) {
      print('❌ Validación del formulario falló');
      return;
    }
    
    print('🔍 Validando campos...');
    if (!_validarCampos()) {
      print('❌ Validación de campos falló');
      return;
    }
    
    print('✅ Validaciones exitosas, procediendo con el guardado...');

    setState(() {
      _isLoading = true;
    });

    try {
      final data = {
        "fecha_visita": _fechaVisita!.toIso8601String(),
        "hora_visita": _timeOfDayToIso8601String(_horaVisita!),
        "contrato": _contrato,
        "operador": _operador,
        "municipio_id": _municipioId,
        "institucion_id": _institucionId,
        "sede_id": _sedeId,
        "caso_atencion_prioritaria": _casoAtencionPrioritaria,
        "tipo_visita": _tipoVisita,
        "prioridad": _prioridad,
        "observaciones": _observaciones,
        "lat": _ubicacionGPS?.latitude,
        "lon": _ubicacionGPS?.longitude,
        "precision_gps": _ubicacionGPS?.accuracy,
      };

      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult.contains(ConnectivityResult.none)) {
        print("🔌 Sin conexión. Guardando localmente...");
        
        // Guardar visita localmente
        final visitaId = await LocalDB.guardarVisitaLocal(data);
        
        // Guardar checklist localmente si existe
        if (_respuestasChecklist.isNotEmpty) {
          await LocalDB.guardarChecklistLocal(visitaId, _respuestasChecklist);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Cronograma guardado localmente. Se sincronizará cuando haya conexión.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        try {
          print("☁️ Conexión detectada. Enviando al servidor...");
          
          // Verificar autenticación antes de enviar
          final isAuthenticated = await ApiService().isAuthenticated();
          if (!isAuthenticated) {
            print("❌ Usuario no autenticado. Redirigiendo al login...");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('❌ Sesión expirada. Por favor, inicia sesión nuevamente.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 4),
                ),
              );
              // Redirigir al login en lugar de cerrar la app
              Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
            }
            return;
          }
          
          // Crear la visita completa
          final visitaCreada = await ApiService().crearVisitaCompletaPAE(
            fechaVisita: _fechaVisita!,
            horaVisita: _horaVisita!,
            contrato: _contrato,
            operador: _operador,
            municipioId: _municipioId!,
            institucionId: _institucionId!,
            sedeId: _sedeId!,
            profesionalId: _profesionalId,
            casoAtencionPrioritaria: _casoAtencionPrioritaria!,
            tipoVisita: _tipoVisita,
            prioridad: _prioridad,
            observaciones: _observaciones,
            lat: _ubicacionGPS?.latitude,
            lon: _ubicacionGPS?.longitude,
            precisionGps: _ubicacionGPS?.accuracy,
            respuestasChecklist: _respuestasChecklist,
          );
          
          // NUEVO: Actualizar el estado a completada después de crear la visita
          if (visitaCreada) {
            print('🔄 Actualizando estado de la visita a completada...');
            // Buscar la visita recién creada por contrato y actualizar su estado
            final visitas = await ApiService().getVisitasCompletas();
            final visitasPendientes = visitas.where(
              (v) => v.contrato == _contrato && v.estado == 'pendiente',
            ).toList();
            
            if (visitasPendientes.isNotEmpty) {
              final visitaRecienCreada = visitasPendientes.first;
              final visitaId = visitaRecienCreada.id;
              print('✅ Visita encontrada con ID: $visitaId, actualizando a completada...');
              await ApiService().actualizarEstadoVisita(visitaId, 'completada');
              print('✅ Estado de visita actualizado a completada');
            } else {
              print('⚠️ No se pudo encontrar la visita recién creada para actualizar estado');
            }
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🚀 Cronograma PAE enviado al servidor con éxito.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            
            // NUEVO: Refrescar el dashboard después de guardar
            print('🔄 Refrescando dashboard después de guardar visita...');
            await _refrescarDashboard();
          }
        } catch (e) {
          print("⚠️ Error al enviar al servidor: $e");
          
          // Verificar si es un error de autenticación
          if (e.toString().contains('401') || e.toString().contains('403') || e.toString().contains('Unauthorized')) {
            print("❌ Error de autenticación detectado. Redirigiendo al login...");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('❌ Sesión expirada. Por favor, inicia sesión nuevamente.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 4),
                ),
              );
              // Redirigir al login en lugar de cerrar la app
              Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
            }
            return;
          }
          
          // Para otros errores, guardar localmente como respaldo
          print("💾 Guardando localmente como respaldo...");
          try {
            final visitaId = await LocalDB.guardarVisitaLocal(data);
            
            if (_respuestasChecklist.isNotEmpty) {
              await LocalDB.guardarChecklistLocal(visitaId, _respuestasChecklist);
            }
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('⚠️ Error al enviar. Se guardó localmente para intentarlo después: $e'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          } catch (localError) {
            print("❌ Error al guardar localmente: $localError");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Error crítico: No se pudo guardar localmente: $localError'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      print("❌ Error inesperado en _guardarVisita: $e");
      _mostrarError('Error inesperado: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
      
      // NO cerrar la pantalla aquí - se cerrará desde _refrescarDashboard
      // o desde el manejo de errores específicos
    }
  }
  
  /// Refresca el dashboard después de guardar una visita
  Future<void> _refrescarDashboard() async {
    try {
      print('🔄 === INICIANDO REFRESH DEL DASHBOARD ===');
      
      // Esperar más tiempo para que la sincronización del backend se complete
      print('⏳ Esperando 5 segundos para sincronización del backend...');
      await Future.delayed(const Duration(milliseconds: 5000));
      print('✅ Tiempo de espera completado');
      
      // Navegar de vuelta al dashboard con flag de refresh
      if (mounted) {
        print('✅ Widget montado, navegando de vuelta al dashboard con flag de refresh');
        Navigator.pop(context, {'refresh': true});
        print('✅ Navegación completada con flag de refresh');
      } else {
        print('⚠️ Widget no está montado, no se puede navegar');
      }
      
      print('✅ Dashboard marcado para refresh');
      print('🏁 === REFRESH DEL DASHBOARD FINALIZADO ===');
    } catch (e) {
      print('❌ Error al refrescar dashboard: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      // En caso de error, cerrar la pantalla de todas formas
      if (mounted) {
        print('⚠️ Cerrando pantalla debido a error en refresh');
        Navigator.pop(context);
      }
    }
  }

  /// Toma una foto adicional para la visita
  Future<void> _seleccionarImagenAdicional() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera, // Cambiado de gallery a camera
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imagenAdicional = bytes;
        });
        print('📸 Imagen adicional seleccionada: ${image.name}');
      }
    } catch (e) {
      print('❌ Error al seleccionar imagen adicional: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Elimina la imagen adicional seleccionada
  void _eliminarImagenAdicional() {
    setState(() {
      _imagenAdicional = null;
    });
    print('🗑️ Imagen adicional eliminada');
  }
}