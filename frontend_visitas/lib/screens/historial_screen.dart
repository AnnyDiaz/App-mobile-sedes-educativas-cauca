import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/models/visita.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final ApiService _apiService = ApiService();
  List<Visita> _visitas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarVisitasCompletadas();
  }

  Future<void> _cargarVisitasCompletadas() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final visitas = await _apiService.getMisVisitasPorEstado('completada');
      setState(() {
        _visitas = visitas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Visitas'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarVisitasCompletadas,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildHistorialList(),
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
            'Error al cargar historial',
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
            onPressed: _cargarVisitasCompletadas,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorialList() {
    if (_visitas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay visitas completadas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aún no has completado ninguna visita.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarVisitasCompletadas,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _visitas.length,
        itemBuilder: (context, index) {
          final visita = _visitas[index];
          return _buildVisitaCard(visita);
        },
      ),
    );
  }

  Widget _buildVisitaCard(Visita visita) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                                       decoration: BoxDecoration(
                       color: Colors.green.withValues(alpha: 0.1),
                       borderRadius: BorderRadius.circular(8),
                     ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visita.sede?.nombre ?? 'Sede no disponible',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        visita.sede?.municipio?.nombre ?? 'Municipio no disponible',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                     decoration: BoxDecoration(
                     color: Colors.green.withValues(alpha: 0.1),
                     borderRadius: BorderRadius.circular(12),
                   ),
                  child: Text(
                    'COMPLETADA',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.calendar_today,
              'Fecha de visita',
              visita.fechaCreacion != null
                  ? _formatDate(visita.fechaCreacion!)
                  : 'No disponible',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.location_on,
              'Ubicación',
              '${visita.sede?.municipio?.nombre ?? 'N/A'} - ${visita.sede?.institucion?.nombre ?? 'N/A'}',
            ),
            if (visita.tipoAsunto != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.subject,
                'Tipo de asunto',
                visita.tipoAsunto!,
              ),
            ],
            if (visita.observaciones != null && visita.observaciones!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.note,
                'Observaciones',
                visita.observaciones!,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _mostrarDetallesVisita(visita),
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Ver Detalles'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green[700],
                      side: BorderSide(color: Colors.green[700]!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (visita.fotoEvidencia != null || visita.pdfEvidencia != null)
                  IconButton(
                    onPressed: () => _mostrarEvidencias(visita),
                    icon: const Icon(Icons.attach_file),
                    tooltip: 'Ver evidencias',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _mostrarDetallesVisita(Visita visita) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Detalles de la Visita Completada'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Sede', visita.sede?.nombre ?? 'No disponible'),
                _buildDetailRow('Municipio', visita.sede?.municipio?.nombre ?? 'No disponible'),
                _buildDetailRow('Institución', visita.sede?.institucion?.nombre ?? 'No disponible'),
                _buildDetailRow('Estado', visita.estado ?? 'No disponible'),
                if (visita.tipoAsunto != null)
                  _buildDetailRow('Tipo de asunto', visita.tipoAsunto!),
                if (visita.observaciones != null && visita.observaciones!.isNotEmpty)
                  _buildDetailRow('Observaciones', visita.observaciones!),
                if (visita.fechaCreacion != null)
                  _buildDetailRow('Fecha de visita', _formatDate(visita.fechaCreacion!)),
                if (visita.lat != null && visita.lon != null)
                  _buildDetailRow('Coordenadas', '${visita.lat}, ${visita.lon}'),
                if (visita.fotoEvidencia != null)
                  _buildDetailRow('Foto de evidencia', 'Sí'),
                if (visita.pdfEvidencia != null)
                  _buildDetailRow('PDF de evidencia', 'Sí'),
                if (visita.fotoFirma != null)
                  _buildDetailRow('Foto de firma', 'Sí'),
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

  void _mostrarEvidencias(Visita visita) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Evidencias de la Visita'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (visita.fotoEvidencia != null)
                ListTile(
                  leading: const Icon(Icons.photo),
                  title: const Text('Foto de evidencia'),
                  subtitle: Text(visita.fotoEvidencia!),
                  onTap: () {
                    // Aquí podrías abrir la imagen
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Función de visualización en desarrollo')),
                    );
                  },
                ),
              if (visita.pdfEvidencia != null)
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: const Text('PDF de evidencia'),
                  subtitle: Text(visita.pdfEvidencia!),
                  onTap: () {
                    // Aquí podrías abrir el PDF
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Función de visualización en desarrollo')),
                    );
                  },
                ),
              if (visita.fotoFirma != null)
                ListTile(
                  leading: const Icon(Icons.draw),
                  title: const Text('Foto de firma'),
                  subtitle: Text(visita.fotoFirma!),
                  onTap: () {
                    // Aquí podrías abrir la imagen
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Función de visualización en desarrollo')),
                    );
                  },
                ),
              if (visita.fotoEvidencia == null && 
                  visita.pdfEvidencia == null && 
                  visita.fotoFirma == null)
                const Text('No hay evidencias disponibles'),
            ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
