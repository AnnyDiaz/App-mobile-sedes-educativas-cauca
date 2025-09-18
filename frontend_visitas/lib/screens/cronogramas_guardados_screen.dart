import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';

class CronogramaGuardado {
  final int id;
  final DateTime fechaVisita;
  final String contrato;
  final String operador;
  final String municipio;
  final String institucion;
  final String sede;
  final String casoAtencionPrioritaria;

  CronogramaGuardado({
    required this.id,
    required this.fechaVisita,
    required this.contrato,
    required this.operador,
    required this.municipio,
    required this.institucion,
    required this.sede,
    required this.casoAtencionPrioritaria,
  });

  factory CronogramaGuardado.fromJson(Map<String, dynamic> json) {
    return CronogramaGuardado(
      id: json['id'],
      fechaVisita: DateTime.parse(json['fecha_visita']),
      contrato: json['contrato'],
      operador: json['operador'],
      municipio: json['municipio'] ?? 'N/A',
      institucion: json['institucion'] ?? 'N/A',
      sede: json['sede'] ?? 'N/A',
      casoAtencionPrioritaria: json['caso_atencion_prioritaria'] ?? 'N/A',
    );
  }
}

class CronogramasGuardadosScreen extends StatefulWidget {
  const CronogramasGuardadosScreen({super.key});

  @override
  State<CronogramasGuardadosScreen> createState() => _CronogramasGuardadosScreenState();
}

class _CronogramasGuardadosScreenState extends State<CronogramasGuardadosScreen> {
  final ApiService _apiService = ApiService();
  List<CronogramaGuardado> _cronogramas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarCronogramas();
  }

  Future<void> _cargarCronogramas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Por ahora usamos datos mock, pero aquí iría la llamada real a la API
      await Future.delayed(const Duration(seconds: 1)); // Simular carga
      
      // Datos mock para demostración
      final cronogramasMock = [
        CronogramaGuardado(
          id: 1,
          fechaVisita: DateTime.now().subtract(const Duration(days: 2)),
          contrato: 'CONTRATO-001',
          operador: 'Operador A',
          municipio: 'Popayán',
          institucion: 'Institución Educativa A',
          sede: 'Sede Principal',
          casoAtencionPrioritaria: 'SI',
        ),
        CronogramaGuardado(
          id: 2,
          fechaVisita: DateTime.now().subtract(const Duration(days: 5)),
          contrato: 'CONTRATO-002',
          operador: 'Operador B',
          municipio: 'Santander de Quilichao',
          institucion: 'Institución Educativa B',
          sede: 'Sede Secundaria',
          casoAtencionPrioritaria: 'NO',
        ),
        CronogramaGuardado(
          id: 3,
          fechaVisita: DateTime.now().subtract(const Duration(days: 7)),
          contrato: 'CONTRATO-003',
          operador: 'Operador C',
          municipio: 'El Tambo',
          institucion: 'Institución Educativa C',
          sede: 'Sede Norte',
          casoAtencionPrioritaria: 'NO HUBO SERVICIO',
        ),
      ];

      setState(() {
        _cronogramas = cronogramasMock;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar cronogramas: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronogramas PAE Guardados'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarCronogramas,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildCronogramasList(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _cargarCronogramas,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildCronogramasList() {
    if (_cronogramas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, color: Colors.grey, size: 64),
            SizedBox(height: 16),
            Text(
              'No hay cronogramas guardados',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarCronogramas,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cronogramas.length,
        itemBuilder: (context, index) {
          final cronograma = _cronogramas[index];
          return _buildCronogramaCard(cronograma);
        },
      ),
    );
  }

  Widget _buildCronogramaCard(CronogramaGuardado cronograma) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          'Cronograma #${cronograma.id}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${cronograma.fechaVisita.day}/${cronograma.fechaVisita.month}/${cronograma.fechaVisita.year}',
          style: const TextStyle(color: Colors.grey),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Contrato:', cronograma.contrato),
                _buildInfoRow('Operador:', cronograma.operador),
                _buildInfoRow('Municipio:', cronograma.municipio),
                _buildInfoRow('Institución:', cronograma.institucion),
                _buildInfoRow('Sede:', cronograma.sede),
                _buildInfoRow('Caso de Atención Prioritaria:', cronograma.casoAtencionPrioritaria),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _verDetalles(cronograma),
                      icon: const Icon(Icons.visibility),
                      label: const Text('Ver Detalles'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _editarCronograma(cronograma),
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
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

  void _verDetalles(CronogramaGuardado cronograma) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles Cronograma #${cronograma.id}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Contrato:', cronograma.contrato),
              _buildInfoRow('Operador:', cronograma.operador),
              _buildInfoRow('Fecha:', '${cronograma.fechaVisita.day}/${cronograma.fechaVisita.month}/${cronograma.fechaVisita.year}'),
              _buildInfoRow('Municipio:', cronograma.municipio),
              _buildInfoRow('Institución:', cronograma.institucion),
              _buildInfoRow('Sede:', cronograma.sede),
              _buildInfoRow('Caso de Atención Prioritaria:', cronograma.casoAtencionPrioritaria),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _editarCronograma(CronogramaGuardado cronograma) {
    // Aquí iría la navegación a la pantalla de edición
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editar cronograma #${cronograma.id}'),
        backgroundColor: Colors.orange,
      ),
    );
  }
} 