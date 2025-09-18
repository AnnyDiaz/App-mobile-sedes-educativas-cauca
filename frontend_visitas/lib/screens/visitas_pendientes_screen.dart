import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/models/visita_asignada.dart';
import 'package:intl/intl.dart';

class VisitasPendientesScreen extends StatefulWidget {
  const VisitasPendientesScreen({super.key});

  @override
  State<VisitasPendientesScreen> createState() => _VisitasPendientesScreenState();
}

class _VisitasPendientesScreenState extends State<VisitasPendientesScreen> {
  final ApiService _apiService = ApiService();
  List<VisitaAsignada> _visitasPendientes = [];
  List<VisitaAsignada> _visitasEnProceso = [];
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

      print('🔄 Cargando visitas pendientes y en proceso...');

      // Obtener estadísticas del dashboard para verificar números
      try {
        final estadisticas = await _apiService.getEstadisticasVisitador();
        print('📊 Estadísticas del dashboard: $estadisticas');
        
        final visitasPendientesDashboard = estadisticas['visitas_pendientes'] ?? 0;
        print('📋 Visitas pendientes según dashboard: $visitasPendientesDashboard');
        
        // Obtener visitas pendientes usando el mismo endpoint que el dashboard
        final visitasPendientes = await _apiService.getMisVisitasAsignadas(estado: 'pendiente');
        final visitasPendientesObj = visitasPendientes.map((json) => VisitaAsignada.fromJson(json)).toList();
        print('📋 Visitas pendientes obtenidas de API: ${visitasPendientesObj.length}');
        
        // Obtener visitas en proceso
        final visitasEnProceso = await _apiService.getMisVisitasAsignadas(estado: 'en_proceso');
        final visitasEnProcesoObj = visitasEnProceso.map((json) => VisitaAsignada.fromJson(json)).toList();
        print('🔄 Visitas en proceso obtenidas: ${visitasEnProcesoObj.length}');
        
        // Verificar consistencia
        if (visitasPendientesObj.length != visitasPendientesDashboard) {
          print('⚠️ INCONSISTENCIA: Dashboard dice $visitasPendientesDashboard pero API devuelve ${visitasPendientesObj.length}');
        }
      
        setState(() {
          _visitasPendientes = visitasPendientesObj;
          _visitasEnProceso = visitasEnProcesoObj;
          _isLoading = false;
        });

        print('✅ Total de visitas pendientes: ${_visitasPendientes.length}');
        print('✅ Total de visitas en proceso: ${_visitasEnProceso.length}');
        
        // Mostrar resumen en consola
        print('📊 RESUMEN ACTUALIZADO:');
        print('   - Pendientes: ${_visitasPendientes.length}');
        print('   - En proceso: ${_visitasEnProceso.length}');
        print('   - Total activas: ${_visitasPendientes.length + _visitasEnProceso.length}');
        
      } catch (e) {
        print('⚠️ Error al obtener visitas: $e');
        setState(() {
          _isLoading = false;
        });
      }
      
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('❌ Error al cargar visitas: $e');
    }
  }

  Future<void> _iniciarVisita(VisitaAsignada visita) async {
    try {
      // Cambiar estado a "en_proceso"
      await _apiService.actualizarEstadoVisitaAsignada(
        visita.id,
        estado: 'en_proceso',
      );

      // Recargar la lista
      await _cargarVisitasPendientes();

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visita iniciada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar visita: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _crearCronogramaPAE(VisitaAsignada visita) async {
    // Navegar a la pantalla de crear cronograma PAE con los datos precargados
    final result = await Navigator.pushNamed(
      context,
      '/crear_cronograma',
      arguments: visita.toVisitaProgramadaMap(),
    );

    // IMPORTANTE: Siempre recargar la lista al regresar, 
    // independientemente del resultado, para mostrar cambios de estado
    print('🔄 Regresando de crear cronograma. Recargando lista de visitas...');
    await _cargarVisitasPendientes();
    
    // Mostrar mensaje informativo
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lista de visitas actualizada'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Visitas'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('🔄 Botón de actualizar presionado manualmente');
              _cargarVisitasPendientes();
            },
            tooltip: 'Actualizar lista de visitas',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildVisitasPendientes(),
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

  Widget _buildVisitasPendientes() {
    final totalVisitas = _visitasPendientes.length + _visitasEnProceso.length;
    
    if (totalVisitas == 0) {
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
              'No tienes visitas activas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Todas tus visitas asignadas han sido completadas o no hay visitas pendientes/en proceso',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarVisitasPendientes,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de Visitas Pendientes
            _buildSeccionVisitas(
              titulo: '📋 Visitas Pendientes',
              subtitulo: 'Visitas que aún no han sido iniciadas',
              visitas: _visitasPendientes,
              color: Colors.orange,
              icon: Icons.schedule,
            ),
            
            const SizedBox(height: 24),
            
            // Sección de Visitas en Proceso
            _buildSeccionVisitas(
              titulo: '🔄 Visitas en Proceso',
              subtitulo: 'Visitas que ya han sido iniciadas',
              visitas: _visitasEnProceso,
              color: Colors.blue,
              icon: Icons.play_circle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetaVisita(VisitaAsignada visita) {
    final fechaFormateada = DateFormat('dd/MM/yyyy HH:mm').format(visita.fechaProgramada);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con prioridad y tipo
                         Row(
               children: [
                 _buildChipPrioridad(visita.prioridad),
                 const SizedBox(width: 8),
                 _buildChipTipo(visita.tipoVisita),
                 const Spacer(),
                 _buildChipEstado(visita.estado),
               ],
             ),
            const SizedBox(height: 16),

            // Información de la sede
            Row(
              children: [
                Icon(Icons.school, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                             Text(
                         visita.sedeNombre.isNotEmpty ? visita.sedeNombre : 'Sede no especificada',
                         style: Theme.of(context).textTheme.titleMedium?.copyWith(
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                       Text(
                         '${visita.institucionNombre.isNotEmpty ? visita.institucionNombre : 'Institución'} - ${visita.municipioNombre.isNotEmpty ? visita.municipioNombre : 'Municipio'}',
                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
                           color: Colors.grey[600],
                         ),
                       ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Fecha programada
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.orange[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Programada para: $fechaFormateada',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

                         // Datos del cronograma PAE (si existen)
             if (visita.contrato != null || visita.operador != null) ...[
               const Divider(),
               const SizedBox(height: 8),
               if (visita.contrato != null) ...[
                 Row(
                   children: [
                     Icon(Icons.description, color: Colors.green[600], size: 20),
                     const SizedBox(width: 8),
                     Expanded(
                       child: Text(
                         'Contrato: ${visita.contrato}',
                         style: Theme.of(context).textTheme.bodyMedium,
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 4),
               ],
               if (visita.operador != null) ...[
                 Row(
                   children: [
                     Icon(Icons.person, color: Colors.purple[600], size: 20),
                     const SizedBox(width: 8),
                     Expanded(
                       child: Text(
                         'Operador: ${visita.operador}',
                         style: Theme.of(context).textTheme.bodyMedium,
                       ),
                     ),
                   ],
                 ),
               ],
               const SizedBox(height: 12),
             ],

                         // Observaciones (si existen)
             if (visita.observaciones != null && visita.observaciones!.isNotEmpty) ...[
               const Divider(),
               const SizedBox(height: 8),
               Row(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Icon(Icons.note, color: Colors.amber[600], size: 20),
                   const SizedBox(width: 8),
                   Expanded(
                     child: Text(
                       'Observaciones: ${visita.observaciones}',
                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                         fontStyle: FontStyle.italic,
                       ),
                     ),
                   ),
                 ],
               ),
               const SizedBox(height: 12),
             ],

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _iniciarVisita(visita),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Iniciar Visita'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _crearCronogramaPAE(visita),
                    icon: const Icon(Icons.checklist),
                    label: const Text('Crear Cronograma PAE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
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

  Widget _buildChipPrioridad(String prioridad) {
    Color color;
    IconData icon;
    
    switch (prioridad.toLowerCase()) {
      case 'urgente':
        color = Colors.red;
        icon = Icons.priority_high;
        break;
      case 'alta':
        color = Colors.orange;
        icon = Icons.trending_up;
        break;
      case 'normal':
        color = Colors.blue;
        icon = Icons.remove;
        break;
      case 'baja':
        color = Colors.grey;
        icon = Icons.trending_down;
        break;
      default:
        color = Colors.grey;
        icon = Icons.remove;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            prioridad.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipTipo(String tipo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo),
      ),
      child: Text(
        tipo.toUpperCase(),
        style: const TextStyle(
          color: Colors.indigo,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSeccionVisitas({
    required String titulo,
    required String subtitulo,
    required List<VisitaAsignada> visitas,
    required Color color,
    required IconData icon,
  }) {
    if (visitas.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color.withOpacity(0.6)),
            const SizedBox(height: 12),
            Text(
              'No hay $titulo.toLowerCase()',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitulo,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de la sección
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitulo,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${visitas.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Lista de visitas de esta sección
        ...visitas.map((visita) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTarjetaVisita(visita),
        )).toList(),
      ],
    );
  }

  Widget _buildChipEstado(String estado) {
    Color color;
    IconData icon;
    
    switch (estado.toLowerCase()) {
      case 'pendiente':
        color = Colors.orange;
        icon = Icons.schedule;
        break;
      case 'en_proceso':
        color = Colors.blue;
        icon = Icons.play_circle;
        break;
      case 'completada':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'cancelada':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            estado.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
