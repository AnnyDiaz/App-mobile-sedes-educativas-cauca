import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_visitas/config.dart';

class AdminChecklistManagementEnhanced extends StatefulWidget {
  const AdminChecklistManagementEnhanced({super.key});

  @override
  State<AdminChecklistManagementEnhanced> createState() => _AdminChecklistManagementEnhancedState();
}

class _AdminChecklistManagementEnhancedState extends State<AdminChecklistManagementEnhanced> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List<Map<String, dynamic>> _categorias = [];
  Map<String, dynamic>? _estadisticas;
  String? _error;
  int? _categoriaSeleccionada;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      await Future.wait([
        _cargarCategorias(token),
        _cargarEstadisticas(token),
      ]);

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _cargarCategorias(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/checklists'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _categorias = List<Map<String, dynamic>>.from(data['categorias'] ?? []);
      });
    } else {
      throw Exception('Error al cargar categorías: ${response.statusCode}');
    }
  }

  Future<void> _cargarEstadisticas(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/checklists/estadisticas'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _estadisticas = data;
      });
    } else {
      print('Error al cargar estadísticas: ${response.statusCode}');
    }
  }

  // ==================== CRUD CATEGORÍAS ====================

  Future<void> _mostrarDialogoCrearCategoria() async {
    final TextEditingController nombreController = TextEditingController();
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Nueva Categoría'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la categoría',
                    hintText: 'Ej: Higiene y Seguridad',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Text(
                  'La categoría se creará con orden automático y podrás agregar items después.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nombreController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  await _crearCategoria(nombreController.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Crear', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _crearCategoria(String nombre) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/checklists/categorias'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'nombre': nombre}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Categoría "$nombre" creada exitosamente'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Ver',
              textColor: Colors.white,
              onPressed: () => _cargarDatos(),
            ),
          ),
        );
        await _cargarDatos();
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear categoría: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _mostrarDialogoEditarCategoria(Map<String, dynamic> categoria) async {
    final TextEditingController nombreController = TextEditingController(text: categoria['nombre']);
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit, color: Colors.orange),
              SizedBox(width: 8),
              Text('Editar Categoría'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la categoría',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'Esta categoría tiene ${categoria['total_items']} items asociados.',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nombreController.text.trim().isNotEmpty && 
                    nombreController.text.trim() != categoria['nombre']) {
                  Navigator.of(context).pop();
                  await _editarCategoria(categoria['id'], nombreController.text.trim());
                } else {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editarCategoria(int id, String nuevoNombre) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final response = await http.put(
        Uri.parse('$baseUrl/api/admin/checklists/categorias/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'nombre': nuevoNombre}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Categoría actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        await _cargarDatos();
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar categoría: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmarEliminarCategoria(Map<String, dynamic> categoria) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Confirmar Eliminación'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¿Estás seguro de que deseas eliminar la categoría?'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📁 ${categoria['nombre']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('📋 ${categoria['total_items']} items asociados'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '⚠️ Esta acción eliminará también TODOS los items de esta categoría y no se puede deshacer.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _eliminarCategoria(categoria['id'], categoria['nombre']);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _eliminarCategoria(int id, String nombre) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final response = await http.delete(
        Uri.parse('$baseUrl/api/admin/checklists/categorias/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Categoría "$nombre" eliminada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        await _cargarDatos();
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar categoría: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==================== CRUD ITEMS ====================

  Future<void> _mostrarDialogoCrearItem(int categoriaId, String categoriaNombre) async {
    final TextEditingController textoController = TextEditingController();
    final TextEditingController ordenController = TextEditingController(text: '1');
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.add_task, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nuevo Item - $categoriaNombre',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textoController,
                  decoration: const InputDecoration(
                    labelText: 'Pregunta/Criterio de evaluación',
                    hintText: 'Ej: ¿El área de cocina está limpia?',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.help_outline),
                  ),
                  maxLines: 3,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ordenController,
                  decoration: const InputDecoration(
                    labelText: 'Orden (número)',
                    hintText: '1, 2, 3...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.sort),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Text(
                  'El item se creará como obligatorio y con tipo de respuesta Sí/No.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (textoController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  await _crearItem(
                    categoriaId,
                    textoController.text.trim(),
                    int.tryParse(ordenController.text) ?? 1,
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Crear', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _crearItem(int categoriaId, String texto, int orden) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/checklists/items'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'categoria_id': categoriaId,
          'texto': texto,
          'orden': orden,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        await _cargarDatos();
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _mostrarDialogoEditarItem(Map<String, dynamic> item) async {
    final TextEditingController textoController = TextEditingController(text: item['texto']);
    final TextEditingController ordenController = TextEditingController(text: item['orden'].toString());
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit_note, color: Colors.orange),
              SizedBox(width: 8),
              Text('Editar Item'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textoController,
                  decoration: const InputDecoration(
                    labelText: 'Pregunta/Criterio de evaluación',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.help_outline),
                  ),
                  maxLines: 3,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ordenController,
                  decoration: const InputDecoration(
                    labelText: 'Orden (número)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.sort),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (textoController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  await _editarItem(
                    item['id'],
                    textoController.text.trim(),
                    int.tryParse(ordenController.text) ?? item['orden'],
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editarItem(int id, String texto, int orden) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final response = await http.put(
        Uri.parse('$baseUrl/api/admin/checklists/items/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'texto': texto,
          'orden': orden,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        await _cargarDatos();
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmarEliminarItem(Map<String, dynamic> item) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Confirmar Eliminación'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¿Estás seguro de que deseas eliminar este item?'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  item['texto'],
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _eliminarItem(item['id']);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _eliminarItem(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final response = await http.delete(
        Uri.parse('$baseUrl/api/admin/checklists/items/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        await _cargarDatos();
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==================== UI BUILDERS ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Checklists'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Categorías', icon: Icon(Icons.category)),
            Tab(text: 'Items', icon: Icon(Icons.checklist)),
            Tab(text: 'Estadísticas', icon: Icon(Icons.analytics)),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error: $_error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarDatos,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCategoriasTab(),
                    _buildItemsTab(),
                    _buildEstadisticasTab(),
                  ],
                ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    int tabIndex = _tabController.index;
    
    if (tabIndex == 0) {
      // Tab de categorías
      return FloatingActionButton.extended(
        onPressed: _mostrarDialogoCrearCategoria,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Categoría'),
      );
    } else if (tabIndex == 1 && _categoriaSeleccionada != null) {
      // Tab de items con categoría seleccionada
      final categoria = _categorias.firstWhere(
        (cat) => cat['id'] == _categoriaSeleccionada,
        orElse: () => {'nombre': 'Categoría'},
      );
      return FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoCrearItem(_categoriaSeleccionada!, categoria['nombre']),
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add_task),
        label: const Text('Nuevo Item'),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildCategoriasTab() {
    if (_categorias.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay categorías creadas',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Presiona el botón + para crear la primera categoría',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _categorias.length,
      itemBuilder: (context, index) {
        final categoria = _categorias[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple.shade100,
              child: Text(
                categoria['total_items'].toString(),
                style: TextStyle(
                  color: Colors.purple.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              categoria['nombre'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${categoria['total_items']} items • Orden: ${categoria['orden']}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _mostrarDialogoEditarCategoria(categoria);
                    break;
                  case 'items':
                    setState(() {
                      _categoriaSeleccionada = categoria['id'];
                      _tabController.animateTo(1);
                    });
                    break;
                  case 'delete':
                    _confirmarEliminarCategoria(categoria);
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'items',
                  child: Row(
                    children: [
                      Icon(Icons.list, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Ver Items'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemsTab() {
    if (_categorias.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Primero crea categorías',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Ve a la pestaña Categorías para empezar',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Selector de categoría
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecciona una categoría:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _categoriaSeleccionada,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: const Text('Elige una categoría para ver sus items'),
                items: _categorias.map((categoria) {
                  return DropdownMenuItem<int>(
                    value: categoria['id'],
                    child: Text(
                      '${categoria['nombre']} (${categoria['total_items']} items)',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoriaSeleccionada = value;
                  });
                },
              ),
            ],
          ),
        ),
        // Lista de items
        Expanded(
          child: _categoriaSeleccionada == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_upward, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Selecciona una categoría',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : _buildListaItems(),
        ),
      ],
    );
  }

  Widget _buildListaItems() {
    final categoria = _categorias.firstWhere(
      (cat) => cat['id'] == _categoriaSeleccionada,
      orElse: () => {'items': []},
    );
    
    final items = List<Map<String, dynamic>>.from(categoria['items'] ?? []);
    
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.checklist, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No hay items en "${categoria['nombre']}"',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Presiona el botón + para agregar el primer item',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Ordenar items por orden
    items.sort((a, b) => (a['orden'] ?? 0).compareTo(b['orden'] ?? 0));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                item['orden'].toString(),
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              item['texto'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                Icon(
                  item['obligatorio'] ? Icons.star : Icons.star_border,
                  size: 16,
                  color: item['obligatorio'] ? Colors.orange : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(item['tipo_respuesta']),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item['obligatorio'] ? Colors.red.shade100 : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item['obligatorio'] ? 'Obligatorio' : 'Opcional',
                    style: TextStyle(
                      fontSize: 10,
                      color: item['obligatorio'] ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _mostrarDialogoEditarItem(item);
                    break;
                  case 'delete':
                    _confirmarEliminarItem(item);
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEstadisticasTab() {
    if (_estadisticas == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estadísticas del Sistema',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Cards de estadísticas
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Categorías',
                  _estadisticas!['total_categorias'].toString(),
                  Icons.category,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Items',
                  _estadisticas!['total_items'].toString(),
                  Icons.checklist,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Promedio Items',
                  _estadisticas!['promedio_items_por_categoria'].toString(),
                  Icons.analytics,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Respuestas',
                  _estadisticas!['total_respuestas'].toString(),
                  Icons.assignment_turned_in,
                  Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Text(
            'Distribución por Categoría',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          // Lista de categorías con barras de progreso
          ..._categorias.map((categoria) => _buildCategoriaBar(categoria)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriaBar(Map<String, dynamic> categoria) {
    final totalItems = _estadisticas!['total_items'] as int;
    final itemsCategoria = categoria['total_items'] as int;
    final porcentaje = totalItems > 0 ? (itemsCategoria / totalItems) : 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  categoria['nombre'],
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$itemsCategoria items',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: porcentaje,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade400),
          ),
          const SizedBox(height: 4),
          Text(
            '${(porcentaje * 100).toStringAsFixed(1)}% del total',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
