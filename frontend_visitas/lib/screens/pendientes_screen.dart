// lib/screens/pendientes_screen.dart

import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/screens/crear_cronograma_screen.dart';
import 'package:frontend_visitas/screens/visitas_completas_screen.dart';

class PendientesScreen extends StatefulWidget {
  const PendientesScreen({super.key});

  @override
  State<PendientesScreen> createState() => _PendientesScreenState();
}

class _PendientesScreenState extends State<PendientesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _visitasPendientes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarVisitasPendientes();
  }

  Future<void> _cargarVisitasPendientes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final visitas = await _apiService.getVisitasPendientes();
      setState(() {
        _visitasPendientes = visitas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error al cargar visitas pendientes: $e';
      });
    }
  }

  void _seleccionarVisita(dynamic visita) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearCronogramaScreen(visitaExistente: visita),
      ),
    ).then((_) {
      _cargarVisitasPendientes();
    });
  }

  Future<void> _marcarComoCompletada(dynamic visita) async {
    try {
      final success = await _apiService.actualizarEstadoVisita(visita['id'], 'completada');
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Visita #${visita['id']} marcada como completada'),
            backgroundColor: Colors.green,
          ),
        );
        _cargarVisitasPendientes(); // Recargar la lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al marcar visita como completada'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitas Pendientes'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildVisitasList(),
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
            'Error al cargar visitas',
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
            onPressed: _cargarVisitasPendientes,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitasList() {
    if (_visitas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay visitas pendientes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¡Excelente trabajo! Todas tus visitas están completadas.',
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
      onRefresh: _cargarVisitasPendientes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _visitas.length,
            itemBuilder: (context, index) {
          final visita = _visitas[index];
          return _buildVisitaCard(visita);
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarVisitasPendientes,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _visitasPendientes.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No hay visitas pendientes',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarVisitasPendientes,
                      child: ListView.builder(
                        itemCount: _visitasPendientes.length,
                        itemBuilder: (context, index) {
                          final visita = _visitasPendientes[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Icon(
                                  Icons.schedule,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                'Visita #${visita['id']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Sede: ${visita['sede']?['nombre'] ?? 'N/A'}'),
                                  Text('Fecha: ${visita['fecha_visita'] ?? 'N/A'}'),
                                  Text('Estado: ${visita['estado'] ?? 'N/A'}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _seleccionarVisita(visita),
                                    tooltip: 'Editar visita',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.green),
                                    onPressed: () => _marcarComoCompletada(visita),
                                    tooltip: 'Marcar como completada',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/visitas-completas');
        },
        icon: const Icon(Icons.check_circle),
        label: const Text('Ver Completadas'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }
}