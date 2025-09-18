import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_visitas/config.dart';

class AdminRolesManagementScreen extends StatefulWidget {
  @override
  _AdminRolesManagementScreenState createState() => _AdminRolesManagementScreenState();
}

class _AdminRolesManagementScreenState extends State<AdminRolesManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _roles = [];
  List<Map<String, dynamic>> _permisos = [];
  bool _isLoading = true;
  String _error = '';

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
        _cargarRoles(),
        _cargarPermisos(),
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

  Future<void> _cargarRoles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/roles'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        dynamic data;
        try {
          data = jsonDecode(response.body);
          print('🔍 Respuesta del backend roles: $data'); // Debug
          print('🔍 Tipo de data roles: ${data.runtimeType}'); // Debug del tipo
        } catch (parseError) {
          print('❌ Error parseando JSON roles: $parseError');
          print('❌ Body recibido roles: ${response.body}');
          throw Exception('Error en el formato de respuesta del servidor para roles');
        }
        
        // Verificar si data es una lista directa o está envuelta en un objeto
        if (data is List) {
          print('✅ Roles data es una lista directa');
          setState(() {
            _roles = List<Map<String, dynamic>>.from(data);
          });
        } else if (data is Map) {
          print('✅ Roles data es un Map, claves disponibles: ${data.keys.toList()}');
          
          if (data.containsKey('roles')) {
            print('✅ Usando clave "roles"');
            final rolesData = data['roles'];
            print('🔍 Tipo de roles: ${rolesData.runtimeType}');
            
            if (rolesData is List) {
              setState(() {
                _roles = List<Map<String, dynamic>>.from(rolesData);
              });
            } else {
              print('❌ roles no es una lista, es: ${rolesData.runtimeType}');
              setState(() {
                _roles = [];
              });
            }
          } else if (data.containsKey('data')) {
            print('✅ Usando clave "data"');
            final dataData = data['data'];
            print('🔍 Tipo de data: ${dataData.runtimeType}');
            
            if (dataData is List) {
              setState(() {
                _roles = List<Map<String, dynamic>>.from(dataData);
              });
            } else {
              print('❌ data no es una lista, es: ${dataData.runtimeType}');
              setState(() {
                _roles = [];
              });
            }
          } else {
            print('⚠️ No se encontraron claves esperadas. Claves disponibles: ${data.keys.toList()}');
            setState(() {
              _roles = [];
            });
          }
        } else {
          print('❌ Roles data no es ni List ni Map, es: ${data.runtimeType}');
          print('⚠️ Usando roles de fallback debido a estructura inesperada');
          setState(() {
            _roles = [
              {'id': 1, 'nombre': 'Visitador', 'descripcion': 'Rol para visitadores'},
              {'id': 2, 'nombre': 'Supervisor', 'descripcion': 'Rol para supervisores'}, 
              {'id': 3, 'nombre': 'Administrador', 'descripcion': 'Rol para administradores'},
            ];
          });
        }
        
        print('✅ Roles cargados: ${_roles.length}');
      } else {
        print('⚠️ Error cargando roles: ${response.statusCode} - ${response.body}');
        print('⚠️ Usando roles de fallback debido a error HTTP');
        // Fallback a roles por defecto si no hay endpoint
        setState(() {
          _roles = [
            {'id': 1, 'nombre': 'Visitador', 'descripcion': 'Rol para visitadores'},
            {'id': 2, 'nombre': 'Supervisor', 'descripcion': 'Rol para supervisores'}, 
            {'id': 3, 'nombre': 'Administrador', 'descripcion': 'Rol para administradores'},
          ];
        });
      }
    } catch (e) {
      print('❌ Error en _cargarRoles: $e');
      print('❌ Stack trace roles: ${StackTrace.current}');
      
      // Proporcionar un mensaje de error más amigable
      if (e.toString().contains('type') && e.toString().contains('is not a subtype')) {
        print('⚠️ Error de tipo detectado en roles, usando roles de fallback');
        setState(() {
          _roles = [
            {'id': 1, 'nombre': 'Visitador', 'descripcion': 'Rol para visitadores'},
            {'id': 2, 'nombre': 'Supervisor', 'descripcion': 'Rol para supervisores'}, 
            {'id': 3, 'nombre': 'Administrador', 'descripcion': 'Rol para administradores'},
          ];
        });
        return; // No lanzar excepción, usar fallback
      } else {
        // Para otros errores, usar fallback en lugar de lanzar excepción
        print('⚠️ Error inesperado en roles, usando roles de fallback');
        setState(() {
          _roles = [
            {'id': 1, 'nombre': 'Visitador', 'descripcion': 'Rol para visitadores'},
            {'id': 2, 'nombre': 'Supervisor', 'descripcion': 'Rol para supervisores'}, 
            {'id': 3, 'nombre': 'Administrador', 'descripcion': 'Rol para administradores'},
          ];
        });
        return;
      }
    }
  }

  Future<void> _cargarPermisos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/permisos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        dynamic data;
        try {
          data = jsonDecode(response.body);
          print('🔍 Respuesta del backend permisos: $data'); // Debug
          print('🔍 Tipo de data permisos: ${data.runtimeType}'); // Debug del tipo
        } catch (parseError) {
          print('❌ Error parseando JSON permisos: $parseError');
          print('❌ Body recibido permisos: ${response.body}');
          throw Exception('Error en el formato de respuesta del servidor para permisos');
        }
        
        // Verificar si data es una lista directa o está envuelta en un objeto
        if (data is List) {
          print('✅ Permisos data es una lista directa');
          setState(() {
            _permisos = List<Map<String, dynamic>>.from(data);
          });
        } else if (data is Map) {
          print('✅ Permisos data es un Map, claves disponibles: ${data.keys.toList()}');
          
          if (data.containsKey('permisos')) {
            print('✅ Usando clave "permisos"');
            final permisosData = data['permisos'];
            print('🔍 Tipo de permisos: ${permisosData.runtimeType}');
            
            if (permisosData is List) {
              setState(() {
                _permisos = List<Map<String, dynamic>>.from(permisosData);
              });
            } else {
              print('❌ permisos no es una lista, es: ${permisosData.runtimeType}');
              setState(() {
                _permisos = [];
              });
            }
          } else if (data.containsKey('data')) {
            print('✅ Usando clave "data"');
            final dataData = data['data'];
            print('🔍 Tipo de data: ${dataData.runtimeType}');
            
            if (dataData is List) {
              setState(() {
                _permisos = List<Map<String, dynamic>>.from(dataData);
              });
            } else {
              print('❌ data no es una lista, es: ${dataData.runtimeType}');
              setState(() {
                _permisos = [];
              });
            }
          } else {
            print('⚠️ No se encontraron claves esperadas. Claves disponibles: ${data.keys.toList()}');
            setState(() {
              _permisos = [];
            });
          }
        } else {
          print('❌ Permisos data no es ni List ni Map, es: ${data.runtimeType}');
          print('⚠️ Usando permisos de fallback debido a estructura inesperada');
          setState(() {
            _permisos = [
              {'id': 1, 'nombre': 'crear_usuarios', 'descripcion': 'Crear usuarios'},
              {'id': 2, 'nombre': 'editar_usuarios', 'descripcion': 'Editar usuarios'},
              {'id': 3, 'nombre': 'eliminar_usuarios', 'descripcion': 'Eliminar usuarios'},
              {'id': 4, 'nombre': 'gestionar_visitas', 'descripcion': 'Gestionar visitas'},
              {'id': 5, 'nombre': 'ver_reportes', 'descripcion': 'Ver reportes'},
            ];
          });
        }
        
        print('✅ Permisos cargados: ${_permisos.length}');
      } else {
        print('⚠️ Error cargando permisos: ${response.statusCode} - ${response.body}');
        print('⚠️ Usando permisos de fallback debido a error HTTP');
        // Fallback a permisos por defecto si no hay endpoint
        setState(() {
          _permisos = [
            {'id': 1, 'nombre': 'crear_usuarios', 'descripcion': 'Crear usuarios'},
            {'id': 2, 'nombre': 'editar_usuarios', 'descripcion': 'Editar usuarios'},
            {'id': 3, 'nombre': 'eliminar_usuarios', 'descripcion': 'Eliminar usuarios'},
            {'id': 4, 'nombre': 'gestionar_visitas', 'descripcion': 'Gestionar visitas'},
            {'id': 5, 'nombre': 'ver_reportes', 'descripcion': 'Ver reportes'},
          ];
        });
      }
    } catch (e) {
      print('❌ Error en _cargarPermisos: $e');
      print('❌ Stack trace permisos: ${StackTrace.current}');
      
      // Proporcionar un mensaje de error más amigable
      if (e.toString().contains('type') && e.toString().contains('is not a subtype')) {
        print('⚠️ Error de tipo detectado en permisos, usando permisos de fallback');
        setState(() {
          _permisos = [
            {'id': 1, 'nombre': 'crear_usuarios', 'descripcion': 'Crear usuarios'},
            {'id': 2, 'nombre': 'editar_usuarios', 'descripcion': 'Editar usuarios'},
            {'id': 3, 'nombre': 'eliminar_usuarios', 'descripcion': 'Eliminar usuarios'},
            {'id': 4, 'nombre': 'gestionar_visitas', 'descripcion': 'Gestionar visitas'},
            {'id': 5, 'nombre': 'ver_reportes', 'descripcion': 'Ver reportes'},
          ];
        });
        return; // No lanzar excepción, usar fallback
      } else {
        // Para otros errores, usar fallback en lugar de lanzar excepción
        print('⚠️ Error inesperado en permisos, usando permisos de fallback');
        setState(() {
          _permisos = [
            {'id': 1, 'nombre': 'crear_usuarios', 'descripcion': 'Crear usuarios'},
            {'id': 2, 'nombre': 'editar_usuarios', 'descripcion': 'Editar usuarios'},
            {'id': 3, 'nombre': 'eliminar_usuarios', 'descripcion': 'Eliminar usuarios'},
            {'id': 4, 'nombre': 'gestionar_visitas', 'descripcion': 'Gestionar visitas'},
            {'id': 5, 'nombre': 'ver_reportes', 'descripcion': 'Ver reportes'},
          ];
        });
        return;
      }
    }
  }

  Future<void> _crearRol(String nombre, String descripcion) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/roles'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nombre': nombre,
        'descripcion': descripcion,
      }),
    );

    if (response.statusCode == 200) {
      await _cargarRoles();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rol creado exitosamente')),
      );
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error al crear rol');
    }
  }

  Future<void> _eliminarRol(int rolId, String nombreRol) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('$baseUrl/api/admin/roles/$rolId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      await _cargarRoles();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rol "$nombreRol" eliminado exitosamente')),
      );
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error al eliminar rol');
    }
  }

  void _mostrarDialogoCrearRol() {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Crear Nuevo Rol'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre del rol',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: descripcionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nombreController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('El nombre del rol es obligatorio')),
                );
                return;
              }

              try {
                await _crearRol(
                  nombreController.text.trim(),
                  descripcionController.text.trim(),
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEliminarRol(Map<String, dynamic> rol) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Rol'),
        content: Text(
          '¿Está seguro de que desea eliminar el rol "${rol['nombre']}"?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _eliminarRol(rol['id'], rol['nombre']);
                Navigator.pop(context);
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _mostrarPermisosRol(Map<String, dynamic> rol) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RolePermissionsScreen(
          rol: rol,
          permisos: _permisos,
          onPermisosActualizados: _cargarRoles,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Roles y Permisos'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: Icon(Icons.admin_panel_settings), text: 'Roles'),
            Tab(icon: Icon(Icons.security), text: 'Permisos'),
          ],
        ),
      ),
      body: _isLoading
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
                    _buildRolesTab(),
                    _buildPermisosTab(),
                  ],
                ),
      // floatingActionButton removido - no se permite crear roles
    );
  }

  Widget _buildRolesTab() {
    return RefreshIndicator(
      onRefresh: _cargarRoles,
      child: ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: _roles.length,
        itemBuilder: (context, index) {
          final rol = _roles[index];
          return Card(
            margin: EdgeInsets.only(bottom: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.indigo,
                child: Icon(Icons.account_circle, color: Colors.white, size: 20),
              ),
              title: Text(
                rol['nombre'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 2),
                  Text(
                    rol['descripcion'] ?? 'Sin descripción',
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 2),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${rol['usuarios_count'] ?? 0} usuario(s)',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: PopupMenuButton(
                icon: Icon(Icons.more_vert, size: 20),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'permisos',
                    child: Row(
                      children: [
                        Icon(Icons.security, size: 18),
                        SizedBox(width: 8),
                        Text('Gestionar Permisos'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'eliminar',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'permisos') {
                    _mostrarPermisosRol(rol);
                  } else if (value == 'eliminar') {
                    _mostrarDialogoEliminarRol(rol);
                  }
                },
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermisosTab() {
    // Agrupar permisos por módulo
    Map<String, List<Map<String, dynamic>>> permisosPorModulo = {};
    for (var permiso in _permisos) {
      String modulo = permiso['modulo'] ?? 'General';
      if (!permisosPorModulo.containsKey(modulo)) {
        permisosPorModulo[modulo] = [];
      }
      permisosPorModulo[modulo]!.add(permiso);
    }

    return RefreshIndicator(
      onRefresh: _cargarPermisos,
      child: ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: permisosPorModulo.keys.length,
        itemBuilder: (context, index) {
          String modulo = permisosPorModulo.keys.elementAt(index);
          List<Map<String, dynamic>> permisosModulo = permisosPorModulo[modulo]!;

          return Card(
            margin: EdgeInsets.only(bottom: 10),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.indigo.withOpacity(0.1),
                child: Icon(Icons.folder_outlined, color: Colors.indigo, size: 18),
              ),
              title: Text(
                modulo,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Container(
                margin: EdgeInsets.only(top: 4),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${permisosModulo.length} permiso(s)',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              children: permisosModulo.map((permiso) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: Icon(Icons.vpn_key, color: Colors.blue.shade700, size: 16),
                    ),
                    title: Text(
                      permiso['nombre'],
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      permiso['descripcion'] ?? 'Sin descripción',
                      style: TextStyle(fontSize: 12),
                    ),
                    dense: true,
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

// Pantalla para gestionar permisos de un rol específico
class RolePermissionsScreen extends StatefulWidget {
  final Map<String, dynamic> rol;
  final List<Map<String, dynamic>> permisos;
  final VoidCallback onPermisosActualizados;

  RolePermissionsScreen({
    required this.rol,
    required this.permisos,
    required this.onPermisosActualizados,
  });

  @override
  _RolePermissionsScreenState createState() => _RolePermissionsScreenState();
}

class _RolePermissionsScreenState extends State<RolePermissionsScreen> {
  Set<int> _permisosAsignados = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarPermisosRol();
  }

  Future<void> _cargarPermisosRol() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/roles/${widget.rol['id']}/permisos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _permisosAsignados = Set<int>.from(data['permisos_ids'] ?? []);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar permisos: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _guardarPermisos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/roles/${widget.rol['id']}/permisos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'permisos_ids': _permisosAsignados.toList(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permisos actualizados exitosamente')),
        );
        widget.onPermisosActualizados();
        Navigator.pop(context);
      } else {
        throw Exception('Error al guardar permisos');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Agrupar permisos por módulo
    Map<String, List<Map<String, dynamic>>> permisosPorModulo = {};
    for (var permiso in widget.permisos) {
      String modulo = permiso['modulo'] ?? 'General';
      if (!permisosPorModulo.containsKey(modulo)) {
        permisosPorModulo[modulo] = [];
      }
      permisosPorModulo[modulo]!.add(permiso);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Permisos - ${widget.rol['nombre']}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isLoading ? null : _guardarPermisos,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: permisosPorModulo.keys.length,
              itemBuilder: (context, index) {
                String modulo = permisosPorModulo.keys.elementAt(index);
                List<Map<String, dynamic>> permisosModulo = permisosPorModulo[modulo]!;

                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    leading: Icon(Icons.folder_outlined, color: Colors.indigo),
                    title: Text(
                      modulo,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${permisosModulo.length} permiso(s)'),
                    initiallyExpanded: true,
                    children: permisosModulo.map((permiso) {
                      final permisoId = permiso['id'];
                      final isAsignado = _permisosAsignados.contains(permisoId);

                      return CheckboxListTile(
                        value: isAsignado,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _permisosAsignados.add(permisoId);
                            } else {
                              _permisosAsignados.remove(permisoId);
                            }
                          });
                        },
                        title: Text(permiso['nombre']),
                        subtitle: Text(permiso['descripcion']),
                        secondary: Icon(Icons.vpn_key, color: Colors.grey[600]),
                        dense: true,
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }
}
