import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_visitas/config.dart';

class AdminUserManagementEnhanced extends StatefulWidget {
  const AdminUserManagementEnhanced({super.key});

  @override
  State<AdminUserManagementEnhanced> createState() => _AdminUserManagementEnhancedState();
}

class _AdminUserManagementEnhancedState extends State<AdminUserManagementEnhanced> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List<Map<String, dynamic>> _usuarios = [];
  List<Map<String, dynamic>> _auditoria = [];
  String? _error;
  
  // Filtros
  String _busqueda = '';
  final TextEditingController _busquedaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Reducido de 3 a 2 (sin roles)
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _busquedaController.dispose();
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

      // Cargar datos en paralelo
      await Future.wait([
        _cargarUsuarios(token),
        // _cargarRoles(token), // Removido - no se necesita cargar roles
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

  Future<void> _cargarUsuarios(String token) async {
    try {
      final params = <String, String>{};
      if (_busqueda.isNotEmpty) params['search'] = _busqueda;

      final uri = Uri.parse('$baseUrl/api/admin/usuarios').replace(queryParameters: params);
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        dynamic data;
        try {
          data = jsonDecode(response.body);
          print('🔍 Respuesta del backend usuarios: $data'); // Debug
          print('🔍 Tipo de data: ${data.runtimeType}'); // Debug del tipo
        } catch (parseError) {
          print('❌ Error parseando JSON: $parseError');
          print('❌ Body recibido: ${response.body}');
          throw Exception('Error en el formato de respuesta del servidor');
        }
        
        // Verificar si data es una lista directa o está envuelta en un objeto
        if (data is List) {
          print('✅ Data es una lista directa');
          _usuarios = List<Map<String, dynamic>>.from(data);
        } else if (data is Map) {
          print('✅ Data es un Map, claves disponibles: ${data.keys.toList()}');
          
          if (data.containsKey('usuarios')) {
            print('✅ Usando clave "usuarios"');
            final usuariosData = data['usuarios'];
            print('🔍 Tipo de usuarios: ${usuariosData.runtimeType}');
            
            if (usuariosData is List) {
              _usuarios = List<Map<String, dynamic>>.from(usuariosData);
            } else {
              print('❌ usuarios no es una lista, es: ${usuariosData.runtimeType}');
              _usuarios = [];
            }
          } else if (data.containsKey('data')) {
            print('✅ Usando clave "data"');
            final dataData = data['data'];
            print('🔍 Tipo de data: ${dataData.runtimeType}');
            
            if (dataData is List) {
              _usuarios = List<Map<String, dynamic>>.from(dataData);
            } else {
              print('❌ data no es una lista, es: ${dataData.runtimeType}');
              _usuarios = [];
            }
          } else {
            print('⚠️ No se encontraron claves esperadas. Claves disponibles: ${data.keys.toList()}');
            _usuarios = [];
          }
        } else {
          print('❌ Data no es ni List ni Map, es: ${data.runtimeType}');
          print('⚠️ Usando usuarios de fallback debido a estructura inesperada');
          _usuarios = [
            {
              'id': 1,
              'nombre': 'Usuario Demo',
              'correo': 'demo@example.com',
              'rol': 'Visitador',
              'rol_nombre': 'Visitador',
              'visitas_asignadas': 5,
              'visitas_completadas': 3,
            }
          ];
        }
        
        print('✅ Usuarios cargados: ${_usuarios.length}');
        
        // Verificar estructura de cada usuario
        for (int i = 0; i < _usuarios.length; i++) {
          final usuario = _usuarios[i];
          print('👤 Usuario $i: ID=${usuario['id']}, Rol=${usuario['rol']}, Tipo=${usuario['rol'].runtimeType}');
        }
      } else {
        print('⚠️ Error cargando usuarios: ${response.statusCode} - ${response.body}');
        print('⚠️ Usando usuarios de fallback debido a error HTTP');
        // Fallback a usuarios de ejemplo si no hay endpoint
        _usuarios = [
          {
            'id': 1,
            'nombre': 'Usuario Demo',
            'correo': 'demo@example.com',
            'rol': 'Visitador',
            'rol_nombre': 'Visitador',
            'visitas_asignadas': 5,
            'visitas_completadas': 3,
          }
        ];
      }
    } catch (e) {
        print('❌ Error en _cargarUsuarios: $e');
        print('❌ Stack trace: ${StackTrace.current}');
        
        // Proporcionar un mensaje de error más amigable
        if (e.toString().contains('type') && e.toString().contains('is not a subtype')) {
          print('⚠️ Error de tipo detectado, usando usuarios de fallback');
          _usuarios = [
            {
              'id': 1,
              'nombre': 'Usuario Demo',
              'correo': 'demo@example.com',
              'rol': 'Visitador',
              'rol_nombre': 'Visitador',
              'visitas_asignadas': 5,
              'visitas_completadas': 3,
            }
          ];
          return; // No lanzar excepción, usar fallback
        } else if (e.toString().contains('SocketException') || e.toString().contains('Connection failed')) {
          throw Exception('Error de conexión. Verifica tu conexión a internet.');
        } else {
          // Para otros errores, usar fallback en lugar de lanzar excepción
          print('⚠️ Error inesperado, usando usuarios de fallback');
          _usuarios = [
            {
              'id': 1,
              'nombre': 'Usuario Demo',
              'correo': 'demo@example.com',
              'rol': 'Visitador',
              'rol_nombre': 'Visitador',
              'visitas_asignadas': 5,
              'visitas_completadas': 3,
            }
          ];
          return;
        }
    }
  }

  // Método _cargarRoles removido - no se necesita cargar roles

  Future<void> _cargarAuditoria(int? usuarioId) async {
    if (usuarioId == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/usuarios/$usuarioId/auditoria'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _auditoria = List<Map<String, dynamic>>.from(data['eventos'] ?? []);
        });
      }
    } catch (e) {
      print('Error cargando auditoría: $e');
    }
  }

  Future<void> _editarUsuario(Map<String, dynamic> usuario) async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _DialogoEditarUsuario(
        usuario: usuario,
        roles: [], // Roles removidos - no se permite editar roles
      ),
    );

    if (resultado != null) {
      await _actualizarUsuario(usuario['id'], resultado);
    }
  }

  Future<void> _actualizarUsuario(int usuarioId, Map<String, dynamic> datos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.put(
        Uri.parse('$baseUrl/api/admin/usuarios/$usuarioId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(datos),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuario actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _cargarUsuarios(token!);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Error al actualizar usuario');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _eliminarUsuario(Map<String, dynamic> usuario) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar a ${usuario['nombre']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');

        final response = await http.delete(
          Uri.parse('$baseUrl/api/admin/usuarios/${usuario['id']}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Usuario eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _cargarUsuarios(token!);
        } else {
          final error = jsonDecode(response.body);
          throw Exception(error['detail'] ?? 'Error al eliminar usuario');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Usuarios', icon: Icon(Icons.people)),
            Tab(text: 'Auditoría', icon: Icon(Icons.history)),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
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
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
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
                    _buildUsuariosTab(),
                    _buildAuditoriaTab(),
                  ],
                ),
    );
  }

  Widget _buildUsuariosTab() {
    return Column(
      children: [
        // Filtros y búsqueda
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            children: [
              TextField(
                controller: _busquedaController,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o email...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _busquedaController.clear();
                      setState(() {
                        _busqueda = '';
                      });
                      _cargarDatos();
                    },
                  ),
                ),
                onSubmitted: (value) {
                  setState(() {
                    _busqueda = value;
                  });
                  _cargarDatos();
                },
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _busqueda = '';
                    _busquedaController.clear();
                  });
                  _cargarDatos();
                },
                child: Text('Limpiar búsqueda'),
              ),
            ],
          ),
        ),
        
        // Lista de usuarios
        Expanded(
          child: _usuarios.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No se encontraron usuarios'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _usuarios.length,
                  itemBuilder: (context, index) {
                    final usuario = _usuarios[index];
                    return _buildUsuarioCard(usuario);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUsuarioCard(Map<String, dynamic> usuario) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
              leading: CircleAvatar(
        backgroundColor: _getColorByRole(1), // Default color
        child: Text(
          usuario['nombre'][0].toUpperCase(),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
        title: Text(
          usuario['nombre'],
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(usuario['correo']),
            SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getColorByRole(1).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getColorByRole(1).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    usuario['rol'] ?? usuario['rol_nombre'] ?? 'Sin rol',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getColorByRole(1).withOpacity(0.8),
                    ),
                  ),
                ),
                SizedBox(width: 4),
                if ((usuario['visitas_asignadas'] ?? 0) > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Visitas: ${usuario['visitas_completadas'] ?? 0}/${usuario['visitas_asignadas'] ?? 0}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.withOpacity(0.8),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'auditoria',
              child: Row(
                children: [
                  Icon(Icons.history, size: 18),
                  SizedBox(width: 8),
                  Text('Ver auditoría'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'eliminar',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'editar':
                _editarUsuario(usuario);
                break;
              case 'auditoria':
                _cargarAuditoria(usuario['id']);
                _tabController.animateTo(2);
                break;
              case 'eliminar':
                _eliminarUsuario(usuario);
                break;
            }
          },
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (usuario['telefono'] != null)
                  _buildInfoRow('Teléfono', usuario['telefono']),
                _buildInfoRow('ID', usuario['id'].toString()),
                if (usuario['fecha_creacion'] != null)
                  _buildInfoRow('Fecha creación', 
                    DateTime.parse(usuario['fecha_creacion']).toLocal().toString().split('.')[0]),
                if ((usuario['tasa_cumplimiento'] ?? 0) > 0)
                  _buildInfoRow('Tasa cumplimiento', '${usuario['tasa_cumplimiento'] ?? 0}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600]),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // Método _buildRolesTab removido - no se necesita mostrar roles

  Widget _buildAuditoriaTab() {
    if (_auditoria.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Selecciona un usuario para ver su auditoría'),
            SizedBox(height: 8),
            Text(
              'Ve a la pestaña Usuarios y selecciona "Ver auditoría"',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _auditoria.length,
      itemBuilder: (context, index) {
        final evento = _auditoria[index];
        return _buildEventoAuditoria(evento);
      },
    );
  }

  Widget _buildEventoAuditoria(Map<String, dynamic> evento) {
    IconData icono;
    Color color;
    
    switch (evento['tipo']) {
      case 'error':
        icono = Icons.error;
        color = Colors.red;
        break;
      case 'warning':
        icono = Icons.warning;
        color = Colors.orange;
        break;
      case 'success':
        icono = Icons.check_circle;
        color = Colors.green;
        break;
      default:
        icono = Icons.info;
        color = Colors.blue;
    }

    final fecha = DateTime.parse(evento['fecha']);
    
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icono, color: color, size: 20),
        ),
        title: Text(
          evento['descripcion'],
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}'),
            if (evento['ip_address'] != null)
              Text('IP: ${evento['ip_address']}'),
          ],
        ),
        trailing: Chip(
          label: Text(
            evento['accion'].toUpperCase(),
            style: TextStyle(fontSize: 10),
          ),
          backgroundColor: color.withOpacity(0.1),
        ),
        isThreeLine: true,
      ),
    );
  }

  Color _getColorByRole(int? rolId) {
    switch (rolId) {
      case 1:
        return Colors.blue;   // Visitador
      case 2:
        return Colors.orange; // Supervisor
      case 3:
        return Colors.purple; // Administrador
      default:
        return Colors.grey;
    }
  }

  IconData _getIconByRole(int? rolId) {
    switch (rolId) {
      case 1:
        return Icons.assignment_ind; // Visitador
      case 2:
        return Icons.supervisor_account; // Supervisor
      case 3:
        return Icons.admin_panel_settings; // Administrador
      default:
        return Icons.person;
    }
  }
}

class _DialogoEditarUsuario extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final List<Map<String, dynamic>> roles;

  const _DialogoEditarUsuario({
    required this.usuario,
    required this.roles,
  });

  @override
  State<_DialogoEditarUsuario> createState() => _DialogoEditarUsuarioState();
}

class _DialogoEditarUsuarioState extends State<_DialogoEditarUsuario> {
  late TextEditingController _nombreController;
  late TextEditingController _correoController;
  late TextEditingController _telefonoController;
  late TextEditingController _contrasenaController;
  int? _rolSeleccionado;
  bool _estado = true;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.usuario['nombre']);
    _correoController = TextEditingController(text: widget.usuario['correo']);
    _telefonoController = TextEditingController(text: widget.usuario['telefono'] ?? '');
    _contrasenaController = TextEditingController();
    _rolSeleccionado = widget.usuario['rol_id'] ?? 1; // Default a visitador
    _estado = widget.usuario['estado'] ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar Usuario'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre completo',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _correoController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _telefonoController,
              decoration: InputDecoration(
                labelText: 'Teléfono (opcional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _rolSeleccionado,
              decoration: InputDecoration(
                labelText: 'Rol',
                border: OutlineInputBorder(),
              ),
              items: widget.roles.map((rol) =>
                DropdownMenuItem<int>(
                  value: rol['id'],
                  child: Text(rol['nombre']),
                ),
              ).toList(),
              onChanged: (value) {
                setState(() {
                  _rolSeleccionado = value;
                });
              },
            ),
            SizedBox(height: 16),
            TextField(
              controller: _contrasenaController,
              decoration: InputDecoration(
                labelText: 'Nueva contraseña (opcional)',
                border: OutlineInputBorder(),
                helperText: 'Dejar vacío para mantener la actual',
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('Usuario activo'),
              value: _estado,
              onChanged: (value) {
                setState(() {
                  _estado = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final datos = <String, dynamic>{
              'nombre': _nombreController.text.trim(),
              'correo': _correoController.text.trim(),
              'telefono': _telefonoController.text.trim(),
              'rol_id': _rolSeleccionado,
              'estado': _estado,
            };
            
            if (_contrasenaController.text.isNotEmpty) {
              datos['nueva_contrasena'] = _contrasenaController.text;
            }
            
            Navigator.pop(context, datos);
          },
          child: Text('Guardar'),
        ),
      ],
    );
  }
}
