import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/models/visita.dart';
import 'package:frontend_visitas/utils/permisos_helper.dart';
import 'package:app_settings/app_settings.dart';

class VisitasCompletasScreen extends StatefulWidget {
  const VisitasCompletasScreen({super.key});

  @override
  State<VisitasCompletasScreen> createState() => _VisitasCompletasScreenState();
}

class _VisitasCompletasScreenState extends State<VisitasCompletasScreen> {
  final ApiService _apiService = ApiService();
  List<Visita> _visitas = [];
  bool _isLoading = true;
  String? _error;
  
  // Buscador único
  String _terminoBusqueda = '';
  final TextEditingController _busquedaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarVisitasCompletas();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarVisitasCompletas() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Verificar el rol del usuario para determinar si filtrar por usuario
      final permisos = await PermisosHelper.getPermisos();
      final esVisitador = permisos['es_visitador'] ?? false;
      
      // Si es visitador, solo cargar sus propias visitas
      final visitas = await _apiService.getVisitasCompletas(
        soloDelUsuario: esVisitador,
      );
      
      setState(() {
        _visitas = visitas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error al cargar visitas: $e';
      });
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _terminoBusqueda = '';
      _busquedaController.clear();
    });
  }

  bool _tieneFiltrosActivos() {
    return _terminoBusqueda.isNotEmpty;
  }

  List<Visita> _filtrarVisitas() {
    if (_terminoBusqueda.isEmpty) {
      return _visitas;
    }

    final termino = _terminoBusqueda.toLowerCase();
    return _visitas.where((visita) {
      // Buscar en contrato
      if (visita.contrato?.toLowerCase().contains(termino) == true) return true;
      
      // Buscar en operador
      if (visita.operador?.toLowerCase().contains(termino) == true) return true;
      
      // Buscar en estado
      if (visita.estado?.toLowerCase().contains(termino) == true) return true;
      
      // Buscar en fecha (formato YYYY-MM-DD)
      if (visita.fechaCreacion != null) {
        final fechaStr = visita.fechaCreacion!.toIso8601String().split('T')[0];
        if (fechaStr.contains(termino)) return true;
      }
      
      // Buscar en observaciones
      if (visita.observaciones?.toLowerCase().contains(termino) == true) return true;
      
      // Buscar en nombre de la sede
      if (visita.sede?.nombre?.toLowerCase().contains(termino) == true) return true;
      
      // Buscar en nombre de la institución
      if (visita.institucion?.nombre?.toLowerCase().contains(termino) == true) return true;
      
      // Buscar en nombre del municipio
      if (visita.municipio?.nombre?.toLowerCase().contains(termino) == true) return true;
      
      return false;
    }).toList();
  }

  Future<void> _descargarExcel(int visitaId) async {
    try {
      final rutaArchivo = await _apiService.descargarExcelVisita(visitaId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ Excel descargado exitosamente para visita #$visitaId'),
                if (rutaArchivo != null) ...[
                  SizedBox(height: 4),
                  Text(
                    '📁 Ubicación: $rutaArchivo',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      String mensajeError = 'Error al descargar Excel: $e';
      
      // Manejar específicamente errores de permisos
      if (e.toString().contains('permisos de almacenamiento')) {
        mensajeError = 'Se requieren permisos de almacenamiento para descargar el archivo.\n\n'
            'Por favor, ve a Configuración > Aplicaciones > SMC VS > Permisos y habilita "Almacenamiento".';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensajeError),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Configuración',
              textColor: Colors.white,
              onPressed: () {
                AppSettings.openAppSettings();
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _descargarVisitasFiltradas() async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generando reporte con filtros...'),
            ],
          ),
        ),
      );

      // Generar reporte con el término de búsqueda
      final reporteData = {
        'busqueda': _terminoBusqueda.isNotEmpty ? _terminoBusqueda : null,
        'tipo_reporte': 'excel',
      };

      // Llamar al endpoint de reportes
      final response = await _apiService.generarReporte(reporteData);
      
      // Cerrar diálogo de carga
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Reporte descargado exitosamente con filtros aplicados'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Cerrar diálogo de carga si está abierto
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al descargar reporte: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitas Completas PAE'),
        centerTitle: true,
        actions: [
          // Botón para descargar visitas filtradas
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _descargarVisitasFiltradas,
            tooltip: 'Descargar visitas filtradas',
          ),
          
          if (_tieneFiltrosActivos())
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _limpiarFiltros,
              tooltip: 'Limpiar filtros',
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _mostrarFiltros,
            tooltip: 'Filtros',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarVisitasCompletas,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_tieneFiltrosActivos()) _buildFiltrosActivos(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  void _mostrarFiltros() {
    showDialog(
      context: context,
      builder: (context) => _buildFiltrosModal(),
    );
  }

  Widget _buildFiltrosModal() {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.search, color: Colors.blue[600]),
          const SizedBox(width: 8),
          const Text('Buscador de Visitas'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Busca visitas por contrato, operador, estado o fecha. El filtrado es en tiempo real:',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          
          // Buscador único
          TextFormField(
            controller: _busquedaController,
            decoration: InputDecoration(
              labelText: 'Buscar visita',
              hintText: 'Buscar visita por contrato, operador, estado o fecha...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search, color: Colors.blue[600]),
              suffixIcon: _terminoBusqueda.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 20),
                      onPressed: () {
                        setState(() {
                          _terminoBusqueda = '';
                          _busquedaController.clear();
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                _terminoBusqueda = value;
              });
            },
          ),
          const SizedBox(height: 12),
          
          // Información sobre qué campos se pueden buscar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Puedes buscar por:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Contrato: "CON-2024", "12345"\n• Operador: "Juan Pérez", "María"\n• Estado: "Completada", "Pendiente"\n• Fecha: "2024-01-15", "enero"\n• Sede: "Escuela Central"\n• Institución: "Universidad"\n• Municipio: "Popayán"',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            _limpiarFiltros();
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[600],
            foregroundColor: Colors.white,
          ),
          child: const Text('Limpiar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
          ),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }

  Widget _buildFiltrosActivos() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.blue[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Buscando: "$_terminoBusqueda"',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ),
          Chip(
            label: Text('${_filtrarVisitas().length} resultados'),
            backgroundColor: Colors.blue[100],
            labelStyle: TextStyle(color: Colors.blue[700]),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _limpiarFiltros,
            icon: Icon(Icons.clear, color: Colors.red[600]),
            tooltip: 'Limpiar búsqueda',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando visitas completas...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarVisitasCompletas,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final visitasFiltradas = _filtrarVisitas();
    
    if (visitasFiltradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _terminoBusqueda.isNotEmpty ? Icons.search_off : Icons.assignment,
              color: Colors.grey,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _terminoBusqueda.isNotEmpty 
                  ? 'No se encontraron visitas con "$_terminoBusqueda"'
                  : 'No hay visitas completas registradas',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            if (_terminoBusqueda.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _limpiarFiltros,
                child: const Text('Limpiar búsqueda'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: visitasFiltradas.length,
      itemBuilder: (context, index) {
        final visita = visitasFiltradas[index];
        return _buildVisitaCard(visita);
      },
    );
  }

  Widget _buildVisitaCard(Visita visita) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    visita.numeroVisitaUsuario != null 
                        ? 'Visita #${visita.numeroVisitaUsuario}'
                        : 'Visita #${visita.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                _buildEstadoChip(visita.estado ?? 'Sin estado'),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Fecha Visita', visita.fechaVisita != null ? _formatDate(visita.fechaVisita!.toIso8601String()) : 'Sin fecha'),
            _buildInfoRow('Contrato', visita.contrato ?? 'N/A'),
            _buildInfoRow('Operador', visita.operador ?? 'N/A'),
            _buildInfoRow('Caso Prioritaria', visita.casoAtencionPrioritaria ?? 'N/A'),
            _buildInfoRow('Municipio', visita.municipio?.nombre ?? 'N/A'),
            _buildInfoRow('Institución', visita.institucion?.nombre ?? 'N/A'),
            _buildInfoRow('Sede', visita.sede?.nombre ?? 'N/A'),
            _buildInfoRow('Profesional', visita.profesional?.nombre ?? 'N/A'),
            _buildInfoRow('Respuestas Checklist', '${visita.respuestasChecklist.length} items'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _verDetallesVisita(visita),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Ver Detalles'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _descargarExcel(visita.id),
                    icon: const Icon(Icons.download),
                    label: const Text('Descargar Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoChip(String estado) {
    Color color;
    String text;
    
    switch (estado.toLowerCase()) {
      case 'completada':
        color = Colors.green;
        text = 'Completada';
        break;
      case 'pendiente':
        color = Colors.orange;
        text = 'Pendiente';
        break;
      case 'cancelada':
        color = Colors.red;
        text = 'Cancelada';
        break;
      default:
        color = Colors.grey;
        text = estado;
    }

    return Chip(
      label: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _verDetallesVisita(Visita visita) {
    // Mostrar un diálogo con los detalles de la visita
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Detalles de ${visita.numeroVisitaUsuario != null ? "Visita #${visita.numeroVisitaUsuario}" : "Visita #${visita.id}"}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow('Fecha Visita', visita.fechaVisita != null ? _formatDate(visita.fechaVisita!.toIso8601String()) : 'Sin fecha'),
                _buildInfoRow('Contrato', visita.contrato ?? 'N/A'),
                _buildInfoRow('Operador', visita.operador ?? 'N/A'),
                _buildInfoRow('Caso Prioritaria', visita.casoAtencionPrioritaria ?? 'N/A'),
                _buildInfoRow('Municipio', visita.municipio?.nombre ?? 'N/A'),
                _buildInfoRow('Institución', visita.institucion?.nombre ?? 'N/A'),
                _buildInfoRow('Sede', visita.sede?.nombre ?? 'N/A'),
                _buildInfoRow('Profesional', visita.profesional?.nombre ?? 'N/A'),
                _buildInfoRow('Estado', visita.estado ?? 'Sin estado'),
                _buildInfoRow('Respuestas Checklist', '${visita.respuestasChecklist.length} items'),
                const SizedBox(height: 16),
                const Text(
                  'Respuestas del Checklist:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...visita.respuestasChecklist.map<Widget>((respuesta) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• Item ${respuesta.itemId}: ${respuesta.respuesta}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
} 