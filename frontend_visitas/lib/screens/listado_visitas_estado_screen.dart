import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/models/visita.dart';

class ListadoVisitasEstadoScreen extends StatefulWidget {
  final String estado;

  const ListadoVisitasEstadoScreen({super.key, required this.estado});

  @override
  State<ListadoVisitasEstadoScreen> createState() => _ListadoVisitasEstadoScreenState();
}

class _ListadoVisitasEstadoScreenState extends State<ListadoVisitasEstadoScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Visita>> _futureVisitas;

  @override
  void initState() {
    super.initState();
    _futureVisitas = _apiService.getMisVisitasPorEstado(widget.estado ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Visitas ${widget.estado}')),
      body: FutureBuilder<List<Visita>>(
        future: _futureVisitas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final visitas = snapshot.data!;
          if (visitas.isEmpty) {
            return const Center(child: Text('No hay visitas'));
          }
          return ListView.builder(
            itemCount: visitas.length,
            itemBuilder: (context, index) {
              final visita = visitas[index];
              return ListTile(
                title: Text(visita.tipoAsunto ?? 'Sin asunto'),
                subtitle: Text(visita.observaciones ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
