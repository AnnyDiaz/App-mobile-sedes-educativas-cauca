import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_visitas/config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend_visitas/utils/platform_compat.dart';

class AdminExportsManagementScreen extends StatefulWidget {
  @override
  _AdminExportsManagementScreenState createState() => _AdminExportsManagementScreenState();
}

class _AdminExportsManagementScreenState extends State<AdminExportsManagementScreen> {
  List<Map<String, dynamic>> _plantillas = [];
  
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/exportaciones'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _plantillas = List<Map<String, dynamic>>.from(data['plantillas'] ?? []);
        });
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
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

  Future<void> _generarExportacion(String plantillaId, String formato) async {
    // Mostrar diálogo de configuración
    final configuracion = await _mostrarDialogoConfiguracion(plantillaId, formato);
    if (configuracion == null) return;

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Generando exportación...'),
          ],
        ),
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/exportaciones/generar'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'plantilla_id': plantillaId,
          'formato': formato,
          'filtros': configuracion,
        }),
      );

      Navigator.pop(context); // Cerrar indicador de carga

      if (response.statusCode == 200) {
        final resultado = jsonDecode(response.body);
        _mostrarResultadoExportacion(resultado);
        await _cargarDatos(); // Recargar datos
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

  Future<Map<String, dynamic>?> _mostrarDialogoConfiguracion(String plantillaId, String formato) async {
    DateTime? fechaInicio;
    DateTime? fechaFin;
    String? estadoSeleccionado;

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Configurar Exportación'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plantilla: ${_plantillas.firstWhere((p) => p['id'] == plantillaId)['nombre']}'),
                Text('Formato: ${formato.toUpperCase()}'),
                SizedBox(height: 16),
                
                // Filtros de fecha
                Text('Filtros de Fecha:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text('Fecha Inicio'),
                          TextButton(
                            onPressed: () async {
                              final fecha = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().subtract(Duration(days: 30)),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (fecha != null) {
                                setStateDialog(() => fechaInicio = fecha);
                              }
                            },
                            child: Text(fechaInicio?.toString().split(' ')[0] ?? 'Seleccionar'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          Text('Fecha Fin'),
                          TextButton(
                            onPressed: () async {
                              final fecha = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: fechaInicio ?? DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (fecha != null) {
                                setStateDialog(() => fechaFin = fecha);
                              }
                            },
                            child: Text(fechaFin?.toString().split(' ')[0] ?? 'Seleccionar'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // Filtro de estado (solo para visitas)
                if (plantillaId.contains('visitas')) ...[
                  Text('Estado:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: estadoSeleccionado,
                    hint: Text('Todos los estados'),
                    items: ['programada', 'completada', 'cancelada', 'en_proceso'].map((estado) =>
                      DropdownMenuItem(value: estado, child: Text(estado.toUpperCase()))
                    ).toList(),
                    onChanged: (value) => setStateDialog(() => estadoSeleccionado = value),
                    decoration: InputDecoration(border: OutlineInputBorder()),
                  ),
                ],
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
                final configuracion = <String, dynamic>{};
                if (fechaInicio != null) configuracion['fecha_inicio'] = fechaInicio!.toIso8601String();
                if (fechaFin != null) configuracion['fecha_fin'] = fechaFin!.toIso8601String();
                if (estadoSeleccionado != null) configuracion['estado'] = estadoSeleccionado;
                Navigator.pop(context, configuracion);
              },
              child: Text('Generar'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarResultadoExportacion(Map<String, dynamic> resultado) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exportación Completada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ ${resultado['message']}'),
            SizedBox(height: 8),
            Text('📄 Archivo: ${resultado['filename']}'),
            SizedBox(height: 8),
            Text('📊 Registros: ${resultado['registros']}'),
            SizedBox(height: 8),
            Text('📋 Formato: ${resultado['formato'].toUpperCase()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _descargarArchivo(resultado['filename']);
            },
            child: Text('Descargar'),
          ),
        ],
      ),
    );
  }

  Future<void> _descargarArchivo(String filename) async {
    try {
      // Mostrar indicador de descarga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
              SizedBox(width: 16),
              Text('Descargando archivo...'),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final url = '$baseUrl/api/admin/exportaciones/$filename/download';
      
      // Hacer petición HTTP con token de autorización
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Usar la clase de compatibilidad para descargar
        final bytes = response.bodyBytes;
        await PlatformCompat.downloadFile(bytes, filename, 'application/octet-stream');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Archivo descargado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al descargar: $e')),
      );
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'table_chart': return Icons.table_chart;
      case 'schedule': return Icons.schedule;
      case 'pie_chart': return Icons.pie_chart;
      case 'location_on': return Icons.location_on;
      case 'people': return Icons.people;
      default: return Icons.description;
    }
  }

  Color _getColorForType(String tipo) {
    switch (tipo) {
      case 'excel': return Colors.green;
      case 'pdf': return Colors.red;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exportaciones Avanzadas'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
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
              : _buildPlantillasTab(),
    );
  }

  Widget _buildPlantillasTab() {
    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _plantillas.length,
        itemBuilder: (context, index) {
          final plantilla = _plantillas[index];
          final color = _getColorForType(plantilla['tipo']);
          
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getIconData(plantilla['icono']),
                        color: color,
                        size: 32,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plantilla['nombre'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              plantilla['descripcion'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(
                          plantilla['tipo'].toUpperCase(),
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        backgroundColor: color,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Mostrar botones de Excel y PDF para todas las plantillas
                      OutlinedButton.icon(
                        onPressed: () => _generarExportacion(plantilla['id'], 'excel'),
                        icon: Icon(Icons.table_chart, color: Colors.green),
                        label: Text('Excel'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
                      ),
                      SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _generarExportacion(plantilla['id'], 'pdf'),
                        icon: Icon(Icons.picture_as_pdf, color: Colors.red),
                        label: Text('PDF'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
