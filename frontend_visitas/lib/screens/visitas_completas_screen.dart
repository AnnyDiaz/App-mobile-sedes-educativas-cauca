import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/models/visita.dart';

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

  @override
  void initState() {
    super.initState();
    _cargarVisitasCompletas();
  }

  Future<void> _cargarVisitasCompletas() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Usar el endpoint real del backend
      final visitas = await _apiService.getVisitasCompletas();
      
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

  Future<void> _descargarExcel(int visitaId) async {
    try {
      await _apiService.descargarExcelVisita(visitaId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel descargado exitosamente para visita #$visitaId'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al descargar Excel: $e'),
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarVisitasCompletas,
          ),
        ],
      ),
      body: _buildBody(),
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

    if (_visitas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, color: Colors.grey, size: 64),
            SizedBox(height: 16),
            Text(
              'No hay visitas completas registradas',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _visitas.length,
      itemBuilder: (context, index) {
        final visita = _visitas[index];
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
                Text(
                  'Visita #${visita.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
          title: Text('Detalles de Visita #${visita.id}'),
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