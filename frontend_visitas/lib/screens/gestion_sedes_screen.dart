import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:frontend_visitas/config.dart';
import 'package:frontend_visitas/models/sede.dart';
import 'package:frontend_visitas/models/municipio.dart';
import 'package:frontend_visitas/models/institucion.dart';

class GestionSedesScreen extends StatefulWidget {
  const GestionSedesScreen({super.key});

  @override
  State<GestionSedesScreen> createState() => _GestionSedesScreenState();
}

class _GestionSedesScreenState extends State<GestionSedesScreen> {
  List<Sede> _sedes = [];
  List<Municipio> _municipios = [];
  List<Institucion> _instituciones = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await Future.wait([
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
        _cargando = false;
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
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _sedes = data.map((json) => Sede.fromJson(json)).toList();
      });
    } else {
      throw Exception('Error al cargar sedes: ${response.statusCode}');
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
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _municipios = data.map((json) => Municipio.fromJson(json)).toList();
      });
    } else {
      throw Exception('Error al cargar municipios: ${response.statusCode}');
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
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _instituciones = data.map((json) => Institucion.fromJson(json)).toList();
      });
    } else {
      throw Exception('Error al cargar instituciones: ${response.statusCode}');
    }
  }

  Future<void> _eliminarSede(Sede sede) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar la sede "${sede.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmacion != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.delete(
        Uri.parse('$baseUrl/api/sedes/${sede.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sede "${sede.nombre}" eliminada correctamente')),
        );
        _cargarSedes();
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error['detail']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar sede: $e')),
      );
    }
  }

  void _mostrarFormularioSede([Sede? sede]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioSedeScreen(
          sede: sede,
          municipios: _municipios,
          instituciones: _instituciones,
          onSedeGuardada: () {
            _cargarSedes();
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Sedes'),
        backgroundColor: const Color(0xFF008BE8),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarDatos,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarDatos,
                  child: ListView.builder(
                    itemCount: _sedes.length,
                    itemBuilder: (context, index) {
                      final sede = _sedes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text(sede.nombre),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('DANE: ${sede.dane}'),
                              Text('DUE: ${sede.due}'),
                              Text('Municipio: ${sede.municipio.nombre}'),
                              Text('Institución: ${sede.institucion.nombre}'),
                              if (sede.principal)
                                const Chip(
                                  label: Text('Sede Principal'),
                                  backgroundColor: Colors.green,
                                  labelStyle: TextStyle(color: Colors.white),
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'editar',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'eliminar',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'editar') {
                                _mostrarFormularioSede(sede);
                              } else if (value == 'eliminar') {
                                _eliminarSede(sede);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioSede(),
        backgroundColor: const Color(0xFF008BE8),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class FormularioSedeScreen extends StatefulWidget {
  final Sede? sede;
  final List<Municipio> municipios;
  final List<Institucion> instituciones;
  final VoidCallback onSedeGuardada;

  const FormularioSedeScreen({
    super.key,
    this.sede,
    required this.municipios,
    required this.instituciones,
    required this.onSedeGuardada,
  });

  @override
  State<FormularioSedeScreen> createState() => _FormularioSedeScreenState();
}

class _FormularioSedeScreenState extends State<FormularioSedeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _daneController = TextEditingController();
  final _dueController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  
  Municipio? _municipioSeleccionado;
  Institucion? _institucionSeleccionada;
  bool _esPrincipal = false;
  bool _guardando = false;

  List<Institucion> _institucionesFiltradas = [];

  @override
  void initState() {
    super.initState();
    if (widget.sede != null) {
      _nombreController.text = widget.sede!.nombre;
      _daneController.text = widget.sede!.dane;
      _dueController.text = widget.sede!.due;
      _latController.text = widget.sede!.lat?.toString() ?? '';
      _lonController.text = widget.sede!.lon?.toString() ?? '';
      _esPrincipal = widget.sede!.principal;
      _municipioSeleccionado = widget.sede!.municipio;
      _institucionSeleccionada = widget.sede!.institucion;
      _filtrarInstituciones();
    }
  }

  void _filtrarInstituciones() {
    if (_municipioSeleccionado != null) {
      setState(() {
        _institucionesFiltradas = widget.instituciones
            .where((inst) => inst.municipioId == _municipioSeleccionado!.id)
            .toList();
      });
    } else {
      setState(() {
        _institucionesFiltradas = [];
      });
    }
  }

  Future<void> _guardarSede() async {
    if (!_formKey.currentState!.validate()) return;
    if (_municipioSeleccionado == null || _institucionSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona municipio e institución')),
      );
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final data = {
        'nombre': _nombreController.text.trim(),
        'dane': _daneController.text.trim(),
        'due': _dueController.text.trim(),
        'lat': _latController.text.isNotEmpty ? double.parse(_latController.text) : null,
        'lon': _lonController.text.isNotEmpty ? double.parse(_lonController.text) : null,
        'principal': _esPrincipal,
        'municipio_id': _municipioSeleccionado!.id,
        'institucion_id': _institucionSeleccionada!.id,
      };

      final url = widget.sede != null
          ? '$baseUrl/api/sedes/${widget.sede!.id}'
          : '$baseUrl/api/sedes';

      final response = widget.sede != null
          ? await http.put(
              Uri.parse(url),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(data),
            )
          : await http.post(
              Uri.parse(url),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(data),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.sede != null
                ? 'Sede actualizada correctamente'
                : 'Sede creada correctamente'),
          ),
        );
        widget.onSedeGuardada();
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error['detail']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar sede: $e')),
      );
    } finally {
      setState(() {
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sede != null ? 'Editar Sede' : 'Nueva Sede'),
        backgroundColor: const Color(0xFF008BE8),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la sede',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _daneController,
                  decoration: const InputDecoration(
                    labelText: 'Código DANE',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dueController,
                  decoration: const InputDecoration(
                    labelText: 'Código DUE',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        decoration: const InputDecoration(
                          labelText: 'Latitud',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _lonController,
                        decoration: const InputDecoration(
                          labelText: 'Longitud',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Municipio>(
                  value: _municipioSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Municipio',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.municipios.map((municipio) {
                    return DropdownMenuItem(
                      value: municipio,
                      child: Text(
                        municipio.nombre,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: (municipio) {
                    setState(() {
                      _municipioSeleccionado = municipio;
                      _institucionSeleccionada = null;
                    });
                    _filtrarInstituciones();
                  },
                  validator: (value) => value == null ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Institucion>(
                  value: _institucionSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Institución',
                    border: OutlineInputBorder(),
                  ),
                  items: _institucionesFiltradas.map((institucion) {
                    return DropdownMenuItem(
                      value: institucion,
                      child: Text(
                        institucion.nombre,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: (institucion) {
                    setState(() {
                      _institucionSeleccionada = institucion;
                    });
                  },
                  validator: (value) => value == null ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Sede Principal'),
                  value: _esPrincipal,
                  onChanged: (value) {
                    setState(() {
                      _esPrincipal = value ?? false;
                    });
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _guardando ? null : _guardarSede,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008BE8),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _guardando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.sede != null ? 'Actualizar Sede' : 'Crear Sede',
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _daneController.dispose();
    _dueController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }
} 