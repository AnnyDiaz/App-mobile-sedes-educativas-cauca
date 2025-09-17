import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_visitas/config.dart';

class AdminNotificationsManagement extends StatefulWidget {
  @override
  _AdminNotificationsManagementState createState() => _AdminNotificationsManagementState();
}

class _AdminNotificationsManagementState extends State<AdminNotificationsManagement>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Data variables
  Map<String, dynamic>? _configuracion;
  List<Map<String, dynamic>> _categorias = [];
  List<Map<String, dynamic>> _historial = [];
  Map<String, dynamic>? _estadisticas;
  
  // UI state
  bool _isLoading = true;
  String _error = '';
  
  // Form controllers
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _mensajeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tituloController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Cargar configuración y historial en paralelo
      final futures = await Future.wait([
        _cargarConfiguracion(token!),
        _cargarHistorial(token),
      ]);

      setState(() {
        // Los datos ya se establecen en cada función individual
      });
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

  Future<void> _cargarConfiguracion(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/notificaciones/configuracion'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _configuracion = data['configuracion'];
      _categorias = List<Map<String, dynamic>>.from(data['categorias'] ?? []);
    } else {
      throw Exception('Error al cargar configuración: ${response.statusCode}');
    }
  }

  Future<void> _cargarHistorial(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/notificaciones/historial?limite=20'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _historial = List<Map<String, dynamic>>.from(data['notificaciones'] ?? []);
      _estadisticas = data['estadisticas'];
    } else {
      throw Exception('Error al cargar historial: ${response.statusCode}');
    }
  }

  Future<void> _actualizarConfiguracion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.put(
        Uri.parse('$baseUrl/api/admin/notificaciones/configuracion'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'configuracion': _configuracion,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Configuración actualizada exitosamente')),
        );
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _enviarNotificacion() async {
    if (_tituloController.text.isEmpty || _mensajeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Título y mensaje son requeridos')),
      );
      return;
    }

    // Mostrar diálogo de configuración de envío
    final configuracionEnvio = await _mostrarDialogoEnvio();
    if (configuracionEnvio == null) return;

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Enviando notificación...'),
          ],
        ),
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/notificaciones/enviar'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'titulo': _tituloController.text,
          'mensaje': _mensajeController.text,
          'tipo': configuracionEnvio['tipo'],
          'categoria': configuracionEnvio['categoria'],
          'destinatarios': configuracionEnvio['destinatarios'],
          'canales': configuracionEnvio['canales'],
        }),
      );

      Navigator.pop(context); // Cerrar indicador de carga

      if (response.statusCode == 200) {
        final resultado = jsonDecode(response.body);
        _mostrarResultadoEnvio(resultado);
        
        // Limpiar formulario
        _tituloController.clear();
        _mensajeController.clear();
        
        // Recargar historial
        await _cargarDatos();
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      Navigator.pop(context); // Cerrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<Map<String, dynamic>?> _mostrarDialogoEnvio() async {
    String tipoSeleccionado = 'info';
    String categoriaSeleccionada = 'alertas_sistema';
    String destinatariosSeleccionados = 'all';
    List<String> canalesSeleccionados = ['push'];

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Configurar Envío'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tipo de notificación
                Text('Tipo:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: tipoSeleccionado,
                  items: [
                    DropdownMenuItem(value: 'info', child: Row(children: [Icon(Icons.info, color: Colors.blue), SizedBox(width: 8), Text('Información')])),
                    DropdownMenuItem(value: 'warning', child: Row(children: [Icon(Icons.warning, color: Colors.orange), SizedBox(width: 8), Text('Advertencia')])),
                    DropdownMenuItem(value: 'error', child: Row(children: [Icon(Icons.error, color: Colors.red), SizedBox(width: 8), Text('Error')])),
                    DropdownMenuItem(value: 'success', child: Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('Éxito')])),
                  ],
                  onChanged: (value) => setStateDialog(() => tipoSeleccionado = value!),
                  decoration: InputDecoration(border: OutlineInputBorder()),
                ),
                
                SizedBox(height: 16),
                
                // Categoría
                Text('Categoría:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: categoriaSeleccionada,
                  items: _categorias.map<DropdownMenuItem<String>>((categoria) =>
                    DropdownMenuItem<String>(
                      value: categoria['id'],
                      child: Text(categoria['nombre']),
                    )
                  ).toList(),
                  onChanged: (value) => setStateDialog(() => categoriaSeleccionada = value!),
                  decoration: InputDecoration(border: OutlineInputBorder()),
                ),
                
                SizedBox(height: 16),
                
                // Destinatarios
                Text('Destinatarios:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: destinatariosSeleccionados,
                  items: [
                    DropdownMenuItem(value: 'all', child: Text('Todos los usuarios')),
                    DropdownMenuItem(value: 'admins', child: Text('Solo administradores')),
                    DropdownMenuItem(value: 'supervisores', child: Text('Solo supervisores')),
                    DropdownMenuItem(value: 'visitadores', child: Text('Solo visitadores')),
                  ],
                  onChanged: (value) => setStateDialog(() => destinatariosSeleccionados = value!),
                  decoration: InputDecoration(border: OutlineInputBorder()),
                ),
                
                SizedBox(height: 16),
                
                // Canales
                Text('Canales:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Text('Push'),
                      selected: canalesSeleccionados.contains('push'),
                      onSelected: (selected) {
                        setStateDialog(() {
                          if (selected) {
                            canalesSeleccionados.add('push');
                          } else {
                            canalesSeleccionados.remove('push');
                          }
                        });
                      },
                    ),
                    FilterChip(
                      label: Text('Email'),
                      selected: canalesSeleccionados.contains('email'),
                      onSelected: (selected) {
                        setStateDialog(() {
                          if (selected) {
                            canalesSeleccionados.add('email');
                          } else {
                            canalesSeleccionados.remove('email');
                          }
                        });
                      },
                    ),
                    FilterChip(
                      label: Text('SMS'),
                      selected: canalesSeleccionados.contains('sms'),
                      onSelected: (selected) {
                        setStateDialog(() {
                          if (selected) {
                            canalesSeleccionados.add('sms');
                          } else {
                            canalesSeleccionados.remove('sms');
                          }
                        });
                      },
                    ),
                  ],
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
              onPressed: canalesSeleccionados.isNotEmpty
                  ? () => Navigator.pop(context, {
                      'tipo': tipoSeleccionado,
                      'categoria': categoriaSeleccionada,
                      'destinatarios': destinatariosSeleccionados,
                      'canales': canalesSeleccionados,
                    })
                  : null,
              child: Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarResultadoEnvio(Map<String, dynamic> resultado) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Resultado del Envío'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ ${resultado['message']}'),
            SizedBox(height: 8),
            Text('📤 Enviadas: ${resultado['resultados']['enviadas']}'),
            SizedBox(height: 4),
            Text('❌ Fallidas: ${resultado['resultados']['fallidas']}'),
            SizedBox(height: 4),
            Text('📱 Canales: ${resultado['resultados']['canales_usados'].join(', ')}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _procesarNotificacionesAutomaticas() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Procesando notificaciones automáticas...'),
          ],
        ),
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/notificaciones/automaticas/procesar'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      Navigator.pop(context); // Cerrar indicador de carga

      if (response.statusCode == 200) {
        final resultado = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${resultado['notificaciones_enviadas']} notificaciones automáticas enviadas'),
            backgroundColor: Colors.green,
          ),
        );
        await _cargarDatos(); // Recargar historial
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      Navigator.pop(context); // Cerrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Notificaciones'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.auto_awesome),
            onPressed: _procesarNotificacionesAutomaticas,
            tooltip: 'Procesar notificaciones automáticas',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: Icon(Icons.send), text: 'Enviar'),
            Tab(icon: Icon(Icons.settings), text: 'Configuración'),
            Tab(icon: Icon(Icons.history), text: 'Historial'),
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
                    _buildEnviarTab(),
                    _buildConfiguracionTab(),
                    _buildHistorialTab(),
                  ],
                ),
    );
  }

  Widget _buildEnviarTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enviar Notificación Manual',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            TextField(
              controller: _tituloController,
              decoration: InputDecoration(
                labelText: 'Título de la notificación',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              maxLength: 100,
            ),
            SizedBox(height: 16),
            
            TextField(
              controller: _mensajeController,
              decoration: InputDecoration(
                labelText: 'Mensaje',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.message),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _enviarNotificacion,
                icon: Icon(Icons.send),
                label: Text('Configurar y Enviar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            SizedBox(height: 32),
            
            // Plantillas rápidas
            Text(
              'Plantillas Rápidas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            _buildPlantillaRapida(
              '⚠️ Visitas Vencidas',
              'Hay visitas programadas que requieren atención inmediata.',
              Colors.orange,
            ),
            SizedBox(height: 8),
            _buildPlantillaRapida(
              '📅 Recordatorio de Reunión',
              'Recordatorio: Reunión de coordinación mañana a las 9:00 AM.',
              Colors.blue,
            ),
            SizedBox(height: 8),
            _buildPlantillaRapida(
              '📊 Reporte Disponible',
              'Tu reporte mensual está listo para revisar y descargar.',
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantillaRapida(String titulo, String mensaje, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(Icons.copy, color: color),
        ),
        title: Text(titulo, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(mensaje),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          _tituloController.text = titulo;
          _mensajeController.text = mensaje;
        },
      ),
    );
  }

  Widget _buildConfiguracionTab() {
    if (_configuracion == null) return Center(child: CircularProgressIndicator());

    return Padding(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuración de Notificaciones',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            ..._categorias.map((categoria) => _buildCategoriaConfig(categoria)).toList(),
            
            SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _actualizarConfiguracion,
                icon: Icon(Icons.save),
                label: Text('Guardar Configuración'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriaConfig(Map<String, dynamic> categoria) {
    final config = _configuracion![categoria['id']] ?? {'enabled': false, 'tipo': 'push'};
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoria['nombre'],
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        categoria['descripcion'],
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: config['enabled'] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _configuracion![categoria['id']]['enabled'] = value;
                    });
                  },
                ),
              ],
            ),
            if (config['enabled']) ...[
              SizedBox(height: 12),
              Text('Canal de notificación:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: config['tipo'],
                items: [
                  DropdownMenuItem(value: 'push', child: Text('Push Notification')),
                  DropdownMenuItem(value: 'email', child: Text('Email')),
                  DropdownMenuItem(value: 'sms', child: Text('SMS')),
                ],
                onChanged: (value) {
                  setState(() {
                    _configuracion![categoria['id']]['tipo'] = value;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistorialTab() {
    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Estadísticas
          if (_estadisticas != null) ...[
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Estadísticas (Últimos 30 días)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildEstadistica(
                            'Enviadas',
                            _estadisticas!['total_enviadas'].toString(),
                            Icons.send,
                            Colors.green,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildEstadistica(
                            'Fallidas',
                            _estadisticas!['total_fallidas'].toString(),
                            Icons.error,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
          
          // Lista de notificaciones
          Text(
            'Historial de Notificaciones',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          
          if (_historial.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No hay notificaciones en el historial'),
                ],
              ),
            )
          else
            ..._historial.map((notif) => _buildNotificacionHistorial(notif)).toList(),
        ],
      ),
    );
  }

  Widget _buildEstadistica(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icono, color: color),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(valor, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(titulo, style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificacionHistorial(Map<String, dynamic> notifData) {
    final notif = notifData['notificacion'];
    final resultados = notifData['resultados'];
    final fecha = DateTime.parse(notif['fecha_creacion']);
    
    IconData icono;
    Color color;
    
    switch (notif['tipo']) {
      case 'warning':
        icono = Icons.warning;
        color = Colors.orange;
        break;
      case 'error':
        icono = Icons.error;
        color = Colors.red;
        break;
      case 'success':
        icono = Icons.check_circle;
        color = Colors.green;
        break;
      default:
        icono = Icons.info;
        color = Colors.blue;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icono, color: color),
        ),
        title: Text(
          notif['titulo'],
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notif['mensaje'], maxLines: 2, overflow: TextOverflow.ellipsis),
            SizedBox(height: 4),
            Text(
              '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('✅ ${resultados['enviadas']}', style: TextStyle(color: Colors.green, fontSize: 12)),
            Text('❌ ${resultados['fallidas']}', style: TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
