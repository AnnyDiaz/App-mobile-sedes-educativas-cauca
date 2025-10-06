import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/models/municipio.dart';
import 'package:frontend_visitas/models/institucion.dart';
import 'package:frontend_visitas/models/sede.dart';
import 'package:frontend_visitas/utils/responsive_utils.dart';

class AsignarVisitasScreen extends StatefulWidget {
  const AsignarVisitasScreen({super.key});

  @override
  State<AsignarVisitasScreen> createState() => _AsignarVisitasScreenState();
}

class _AsignarVisitasScreenState extends State<AsignarVisitasScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  List<Map<String, dynamic>> _municipios = [];
  List<Map<String, dynamic>> _instituciones = [];
  List<Map<String, dynamic>> _sedesDisponibles = [];
  List<Map<String, dynamic>> _visitadoresEquipo = [];
  List<Map<String, dynamic>> _tiposVisita = [];
  
  String? _municipioSeleccionado;
  String? _institucionSeleccionada;
  String? _sedeSeleccionada;
  String? _visitadorSeleccionado;
  String? _tipoVisitaSeleccionado;
  DateTime _fechaSeleccionada = DateTime.now();
  TimeOfDay _horaSeleccionada = const TimeOfDay(hour: 9, minute: 0);
  final TextEditingController _observacionesController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Cargar datos iniciales (municipios, visitadores y tipos de visita)
      final futures = await Future.wait([
        _apiService.getMunicipios(),
        _apiService.getVisitadoresEquipo(),
        _apiService.getTiposVisita(),
      ]);

      setState(() {
        final municipiosResult = futures[0] as List<Municipio>;
        _municipios = municipiosResult.map((m) => {
          'id': m.id,
          'nombre': m.nombre,
        }).toList();
        _visitadoresEquipo = futures[1] as List<Map<String, dynamic>>;
        _tiposVisita = futures[2] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _cargarInstituciones(int municipioId) async {
    try {
      final instituciones = await _apiService.getInstitucionesPorMunicipio(municipioId);
      setState(() {
        _instituciones = instituciones.map((i) => {
          'id': i.id,
          'nombre': i.nombre,
          'municipio_id': i.municipioId,
        }).toList();
        // Limpiar selecciones dependientes
        _institucionSeleccionada = null;
        _sedeSeleccionada = null;
        _sedesDisponibles = [];
      });
    } catch (e) {
      print('Error cargando instituciones: $e');
      setState(() {
        _instituciones = [];
        _institucionSeleccionada = null;
        _sedeSeleccionada = null;
        _sedesDisponibles = [];
      });
    }
  }

  Future<void> _cargarSedes(int institucionId) async {
    try {
      final sedes = await _apiService.getSedesPorInstitucion(institucionId);
      setState(() {
        _sedesDisponibles = sedes.map((s) => {
          'id': s.id,
          'nombre': s.nombre,
          'institucion_id': s.institucionId,
          'municipio_id': s.municipioId,
        }).toList();
        // Limpiar selección de sede
        _sedeSeleccionada = null;
      });
    } catch (e) {
      print('Error cargando sedes: $e');
      setState(() {
        _sedesDisponibles = [];
        _sedeSeleccionada = null;
      });
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
    }
  }

  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada,
    );
    
    if (hora != null) {
      setState(() {
        _horaSeleccionada = hora;
      });
    }
  }

  Future<void> _asignarVisita() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sedeSeleccionada == null || _visitadorSeleccionado == null || _tipoVisitaSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos obligatorios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isSaving = true;
      });

      // Combinar fecha y hora
      final fechaHora = DateTime(
        _fechaSeleccionada.year,
        _fechaSeleccionada.month,
        _fechaSeleccionada.day,
        _horaSeleccionada.hour,
        _horaSeleccionada.minute,
      );

      final datosVisita = {
        'sede_id': int.parse(_sedeSeleccionada!),
        'visitador_id': int.parse(_visitadorSeleccionado!),
        'tipo_visita': _tiposVisita[int.parse(_tipoVisitaSeleccionado!)]['id'],
        'fecha_programada': fechaHora.toIso8601String(),
        'observaciones': _observacionesController.text.trim(),
        'estado': 'pendiente',
      };

      await _apiService.asignarVisita(datosVisita);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visita asignada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Limpiar formulario
        _formKey.currentState!.reset();
        setState(() {
          _sedeSeleccionada = null;
          _visitadorSeleccionado = null;
          _tipoVisitaSeleccionado = null;
          _fechaSeleccionada = DateTime.now();
          _horaSeleccionada = const TimeOfDay(hour: 9, minute: 0);
          _observacionesController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar visita: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignar Visita'),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildForm(),
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

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
                         Text(
               'Asignar Nueva Visita',
               style: TextStyle(
                 fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                 fontWeight: FontWeight.bold,
               ),
             ),
             SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
             Text(
               'Completa los datos para asignar una visita a un miembro de tu equipo',
               style: TextStyle(
                 fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                 color: Colors.grey[600],
               ),
             ),
             SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 3),

            // Municipio
            _municipios.isEmpty 
                ? _buildInfoMessage('No hay municipios disponibles. Cargando...')
                : _buildDropdownField(
                    label: 'Municipio *',
                    value: _municipioSeleccionado,
                    items: _municipios.where((municipio) => municipio != null && municipio['nombre'] != null).map((municipio) {
                      return DropdownMenuItem<String>(
                        value: municipio!['id']?.toString() ?? '',
                        child: Text(municipio!['nombre'] ?? 'Sin nombre'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _municipioSeleccionado = value;
                        });
                        _cargarInstituciones(int.parse(value));
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor selecciona un municipio';
                      }
                      return null;
                    },
                  ),
            const SizedBox(height: 16),

            // Institución
            _instituciones.isEmpty 
                ? _buildInfoMessage('Selecciona primero un municipio')
                : _buildDropdownField(
                    label: 'Institución Educativa *',
                    value: _institucionSeleccionada,
                    items: _instituciones.where((institucion) => institucion != null && institucion['nombre'] != null).map((institucion) {
                      return DropdownMenuItem<String>(
                        value: institucion!['id']?.toString() ?? '',
                        child: Text(
                          institucion!['nombre'] ?? 'Sin nombre',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _institucionSeleccionada = value;
                        });
                        _cargarSedes(int.parse(value));
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor selecciona una institución';
                      }
                      return null;
                    },
                  ),
            const SizedBox(height: 16),

            // Sede educativa
            _sedesDisponibles.isEmpty 
                ? _buildInfoMessage('Selecciona primero una institución')
                : _buildDropdownField(
                    label: 'Sede Educativa *',
                    value: _sedeSeleccionada,
                    items: _sedesDisponibles.where((sede) => sede != null && sede['nombre'] != null).map((sede) {
                      return DropdownMenuItem<String>(
                        value: sede!['id']?.toString() ?? '',
                        child: Text(sede!['nombre'] ?? 'Sin nombre'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _sedeSeleccionada = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor selecciona una sede educativa';
                      }
                      return null;
                    },
                  ),
            const SizedBox(height: 16),

            // Visitador
            _visitadoresEquipo.isEmpty 
                ? _buildInfoMessage('No hay visitadores disponibles en tu equipo')
                : _buildDropdownField(
                    label: 'Visitador *',
                    value: _visitadorSeleccionado,
                    items: _visitadoresEquipo.where((visitador) => visitador != null && visitador['nombre'] != null).map((visitador) {
                      return DropdownMenuItem<String>(
                        value: visitador!['id']?.toString() ?? '',
                        child: Text(visitador!['nombre'] ?? 'Sin nombre'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _visitadorSeleccionado = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Selecciona un visitador';
                      }
                      return null;
                    },
                  ),
            const SizedBox(height: 16),

            // Tipo de visita
            _tiposVisita.isEmpty 
                ? _buildInfoMessage('No hay tipos de visita disponibles')
                : _buildDropdownField(
                    label: 'Tipo de Visita *',
                    value: _tipoVisitaSeleccionado,
                    items: _tiposVisita.where((tipo) => tipo != null && tipo['nombre'] != null).map((tipo) {
                      return DropdownMenuItem<String>(
                        value: tipo!['id']?.toString() ?? '',
                        child: Text(tipo!['nombre'] ?? 'Sin nombre'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _tipoVisitaSeleccionado = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Selecciona un tipo de visita';
                      }
                      return null;
                    },
                  ),
            const SizedBox(height: 16),

            // Fecha y hora
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    label: 'Fecha *',
                    value: '${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}',
                    onTap: _seleccionarFecha,
                    icon: Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeField(
                    label: 'Hora *',
                    value: '${_horaSeleccionada.hour.toString().padLeft(2, '0')}:${_horaSeleccionada.minute.toString().padLeft(2, '0')}',
                    onTap: _seleccionarHora,
                    icon: Icons.access_time,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Observaciones
            _buildTextField(
              label: 'Observaciones',
              controller: _observacionesController,
              maxLines: 3,
              hintText: 'Observaciones adicionales sobre la visita...',
            ),
            const SizedBox(height: 32),

            // Botón de asignar
                         SizedBox(
               width: double.infinity,
               height: ResponsiveUtils.getResponsiveSpacing(context) * 6,
               child: ElevatedButton(
                 onPressed: _isSaving ? null : _asignarVisita,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.indigo[600],
                   foregroundColor: Colors.white,
                 ),
                 child: _isSaving
                     ? SizedBox(
                         height: ResponsiveUtils.getResponsiveSpacing(context) * 2.5,
                         width: ResponsiveUtils.getResponsiveSpacing(context) * 2.5,
                         child: CircularProgressIndicator(
                           strokeWidth: 2,
                           valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                         ),
                       )
                     : Text(
                         'Asignar Visita',
                         style: TextStyle(
                           fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16), 
                           fontWeight: FontWeight.bold
                         ),
                       ),
               ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
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
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          validator: validator,
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

  Widget _buildTimeField({
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    String? hintText,
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
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            hintText: hintText,
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildInfoMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
