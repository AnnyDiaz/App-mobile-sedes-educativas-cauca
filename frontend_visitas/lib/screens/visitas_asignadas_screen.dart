import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/models/visita_asignada.dart';
import 'package:intl/intl.dart';

class VisitasAsignadasScreen extends StatefulWidget {
  const VisitasAsignadasScreen({super.key});

  @override
  State<VisitasAsignadasScreen> createState() => _VisitasAsignadasScreenState();
}

class _VisitasAsignadasScreenState extends State<VisitasAsignadasScreen> {
  final ApiService _apiService = ApiService();
  List<VisitaAsignada> _visitasPendientes = [];
  List<VisitaAsignada> _visitasEnProceso = [];
  bool _isLoading = true;
  String? _error;
  
  // Contadores para el resumen
  int _totalPendientes = 0;
  int _totalEnProceso = 0;
  int _totalCompletadas = 0;

  @override
  void initState() {
    super.initState();
    _cargarVisitasAsignadas();
  }

  Future<void> _cargarVisitasAsignadas() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('🔄 Cargando visitas asignadas...');

      // Obtener estadísticas del dashboard
      try {
        final estadisticas = await _apiService.getEstadisticasVisitador();
        print('📊 Estadísticas del dashboard: $estadisticas');
        
        // Obtener visitas pendientes
        final visitasPendientes = await _apiService.getMisVisitasAsignadas(estado: 'pendiente');
        final visitasPendientesObj = visitasPendientes.map((json) => VisitaAsignada.fromJson(json)).toList();
        print('📋 Visitas pendientes obtenidas: ${visitasPendientesObj.length}');
        
        // Obtener visitas en proceso
        final visitasEnProceso = await _apiService.getMisVisitasAsignadas(estado: 'en_proceso');
        final visitasEnProcesoObj = visitasEnProceso.map((json) => VisitaAsignada.fromJson(json)).toList();
        print('🔄 Visitas en proceso obtenidas: ${visitasEnProcesoObj.length}');
        
        // Obtener visitas completadas
        final visitasCompletadas = await _apiService.getMisVisitasAsignadas(estado: 'completada');
        final visitasCompletadasObj = visitasCompletadas.map((json) => VisitaAsignada.fromJson(json)).toList();
        print('✅ Visitas completadas obtenidas: ${visitasCompletadasObj.length}');
        
        setState(() {
          _visitasPendientes = visitasPendientesObj;
          _visitasEnProceso = visitasEnProcesoObj;
          _totalPendientes = visitasPendientesObj.length;
          _totalEnProceso = visitasEnProcesoObj.length;
          _totalCompletadas = visitasCompletadasObj.length;
          _isLoading = false;
        });

                 print('✅ RESUMEN FINAL:');
         print('   - Pendientes: ${_visitasPendientes.length}');
         print('   - En proceso: ${_visitasEnProceso.length}');
         print('   - Completadas: ${visitasCompletadasObj.length}');
         print('   - Total activas: ${_visitasPendientes.length + _visitasEnProceso.length}');
        
      } catch (e) {
        print('⚠️ Error al obtener estadísticas: $e');
        
        // Si fallan las estadísticas, intentar obtener solo las visitas
        try {
          final visitasPendientes = await _apiService.getMisVisitasAsignadas(estado: 'pendiente');
          final visitasPendientesObj = visitasPendientes.map((json) => VisitaAsignada.fromJson(json)).toList();
          
          final visitasEnProceso = await _apiService.getMisVisitasAsignadas(estado: 'en_proceso');
          final visitasEnProcesoObj = visitasEnProceso.map((json) => VisitaAsignada.fromJson(json)).toList();
          
          setState(() {
            _visitasPendientes = visitasPendientesObj;
            _visitasEnProceso = visitasEnProcesoObj;
            _totalPendientes = visitasPendientesObj.length;
            _totalEnProceso = visitasEnProcesoObj.length;
            _isLoading = false;
          });
        } catch (e2) {
          print('❌ Error al obtener visitas: $e2');
          setState(() {
            _error = e2.toString();
            _isLoading = false;
          });
        }
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
      print('▶️ Iniciando visita ID: ${visita.id}');
      
      // Cambiar estado a "en_proceso"
      await _apiService.actualizarEstadoVisitaAsignada(
        visita.id,
        estado: 'en_proceso',
      );

      // Recargar la lista
      await _cargarVisitasAsignadas();

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Visita iniciada exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error al iniciar visita: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al iniciar visita: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _crearCronogramaPAE(VisitaAsignada visita) async {
    print('📝 Creando cronograma PAE para visita ID: ${visita.id}');
    
    // Navegar a la pantalla de crear cronograma PAE
    final result = await Navigator.pushNamed(
      context,
      '/crear_cronograma',
      arguments: visita.toVisitaProgramadaMap(),
    );

    // Verificar si se completó el cronograma
    if (result != null && result is Map<String, dynamic> && result['refresh'] == true) {
      print('✅ Cronograma completado, actualizando visita asignada a completada...');
      
      try {
        // Actualizar la visita asignada a completada
        await _apiService.actualizarEstadoVisitaAsignada(
          visita.id,
          estado: 'completada',
        );
        
        print('✅ Visita asignada actualizada a completada');
        
        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Visita completada exitosamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print('❌ Error al completar visita: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error al completar visita: $e'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    }

    // Siempre recargar la lista al regresar
    print('🔄 Regresando de crear cronograma. Recargando lista...');
    await _cargarVisitasAsignadas();
    
    // Mostrar mensaje informativo
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Lista de visitas actualizada'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Método de debug para ver qué está pasando con las visitas
  Future<void> _debugVisitas() async {
    try {
      print('🐛 === DEBUG VISITAS ===');
      
      // Obtener todas las visitas sin filtro de estado
      final todasLasVisitas = await _apiService.getMisVisitasAsignadas();
      print('📋 Todas las visitas obtenidas: ${todasLasVisitas.length}');
      
      if (todasLasVisitas.isNotEmpty) {
        print('📊 Primera visita: ${todasLasVisitas.first}');
        print('📊 Última visita: ${todasLasVisitas.last}');
      }
      
      // Obtener visitas por estado específico
      final visitasPendientes = await _apiService.getMisVisitasAsignadas(estado: 'pendiente');
      print('📋 Visitas pendientes: ${visitasPendientes.length}');
      
      final visitasEnProceso = await _apiService.getMisVisitasAsignadas(estado: 'en_proceso');
      print('🔄 Visitas en proceso: ${visitasEnProceso.length}');
      
      final visitasCompletadas = await _apiService.getMisVisitasAsignadas(estado: 'completada');
      print('✅ Visitas completadas: ${visitasCompletadas.length}');
      
      // Obtener estadísticas del dashboard
      try {
        final estadisticas = await _apiService.getEstadisticasVisitador();
        print('📊 Estadísticas del dashboard: $estadisticas');
      } catch (e) {
        print('❌ Error al obtener estadísticas: $e');
      }
      
      print('🐛 === FIN DEBUG ===');
      
      // Mostrar resumen en pantalla
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Debug: Total=${todasLasVisitas.length}, '
              'Pendientes=${visitasPendientes.length}, '
              'En proceso=${visitasEnProceso.length}, '
              'Completadas=${visitasCompletadas.length}'
            ),
            backgroundColor: Colors.purple,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
    } catch (e) {
      print('❌ Error en debug: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en debug: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitas Asignadas'),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        actions: [
          // Botón de debug para ver datos
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => _debugVisitas(),
            tooltip: 'Debug visitas',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('🔄 Actualización manual solicitada');
              _cargarVisitasAsignadas();
            },
            tooltip: 'Actualizar visitas',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildVisitasAsignadas(),
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
            onPressed: _cargarVisitasAsignadas,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitasAsignadas() {
    return RefreshIndicator(
      onRefresh: _cargarVisitasAsignadas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // RESUMEN RÁPIDO
            _buildResumenRapido(),
            
            const SizedBox(height: 24),
            
            // SECCIÓN VISITAS PENDIENTES
            _buildSeccionVisitas(
              titulo: '📋 Visitas Pendientes',
              subtitulo: 'Visitas que aún no han sido iniciadas',
              visitas: _visitasPendientes,
              color: Colors.orange,
              icon: Icons.schedule,
              mostrarBotonIniciar: true,
            ),
            
            const SizedBox(height: 24),
            
            // SECCIÓN VISITAS EN PROCESO
            _buildSeccionVisitas(
              titulo: ' Visitas en Proceso',
              subtitulo: 'Visitas que ya han sido iniciadas',
              visitas: _visitasEnProceso,
              color: Colors.blue,
              icon: Icons.play_circle,
              mostrarBotonIniciar: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenRapido() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[50]!, Colors.indigo[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard, size: 28, color: Colors.indigo[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Resumen Rápido',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.indigo[800],
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Contadores
          Row(
            children: [
              Expanded(
                child: _buildContador(
                  titulo: 'Pendientes',
                  valor: _totalPendientes,
                  color: Colors.orange,
                  icon: Icons.schedule,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildContador(
                  titulo: 'En Proceso',
                  valor: _totalEnProceso,
                  color: Colors.blue,
                  icon: Icons.play_circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildContador(
                  titulo: 'Completadas',
                  valor: _totalCompletadas,
                  color: Colors.green,
                  icon: Icons.check_circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContador({
    required String titulo,
    required int valor,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 6),
          Text(
            valor.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            titulo,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionVisitas({
    required String titulo,
    required String subtitulo,
    required List<VisitaAsignada> visitas,
    required Color color,
    required IconData icon,
    required bool mostrarBotonIniciar,
  }) {
    if (visitas.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color.withOpacity(0.6)),
            const SizedBox(height: 16),
                         Text(
               'No hay ${titulo.replaceAll('📋 ', '').replaceAll('🔄 ', '').toLowerCase()}',
               style: Theme.of(context).textTheme.titleLarge?.copyWith(
                 color: color.withOpacity(0.7),
                 fontWeight: FontWeight.w600,
               ),
             ),
            const SizedBox(height: 8),
            Text(
              subtitulo,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 28, color: color),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      titulo,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      '${visitas.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subtitulo,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Lista de visitas
        ...visitas.map((visita) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildTarjetaVisita(visita, mostrarBotonIniciar),
        )).toList(),
      ],
    );
  }

  Widget _buildTarjetaVisita(VisitaAsignada visita, bool mostrarBotonIniciar) {
    final fechaFormateada = DateFormat('dd/MM/yyyy HH:mm').format(visita.fechaProgramada);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con prioridad, tipo y estado
            Row(
              children: [
                _buildChipPrioridad(visita.prioridad),
                const SizedBox(width: 12),
                _buildChipTipo(visita.tipoVisita),
                const Spacer(),
                _buildChipEstado(visita.estado),
              ],
            ),
            
            const SizedBox(height: 20),

            // Información de la sede
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.school, color: Colors.indigo[600], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visita.sedeNombre.isNotEmpty ? visita.sedeNombre : 'Sede no especificada',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${visita.institucionNombre.isNotEmpty ? visita.institucionNombre : 'Institución'} - ${visita.municipioNombre.isNotEmpty ? visita.municipioNombre : 'Municipio'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),

            // Fecha programada
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.orange[600], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Programada para: $fechaFormateada',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Datos del cronograma PAE (si existen)
            if (visita.contrato != null || visita.operador != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              if (visita.contrato != null) ...[
                Row(
                  children: [
                    Icon(Icons.description, color: Colors.green[600], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Contrato: ${visita.contrato}',
                        style: Theme.of(context).textTheme.bodyLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              if (visita.operador != null) ...[
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.purple[600], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Operador: ${visita.operador}',
                        style: Theme.of(context).textTheme.bodyLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],

            // Observaciones (si existen)
            if (visita.observaciones != null && visita.observaciones!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, color: Colors.amber[600], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Observaciones: ${visita.observaciones}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // Botones de acción
            if (mostrarBotonIniciar) ...[
              // Botón iniciar visita (ancho completo)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _iniciarVisita(visita),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('▶️ Iniciar Visita'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Botón crear cronograma PAE (ancho completo)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _crearCronogramaPAE(visita),
                icon: const Icon(Icons.checklist),
                label: const Text('📝 Crear Cronograma PAE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              prioridad.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipTipo(String tipo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
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

  Widget _buildChipEstado(String estado) {
    Color color;
    IconData icon;
    String textoMostrado;
    
    switch (estado.toLowerCase()) {
      case 'pendiente':
        color = Colors.orange;
        icon = Icons.schedule;
        textoMostrado = 'PENDIENTE';
        break;
      case 'en_proceso':
        color = Colors.blue;
        icon = Icons.play_circle;
        textoMostrado = 'EN PROCESO';
        break;
      case 'completada':
        color = Colors.green;
        icon = Icons.check_circle;
        textoMostrado = 'COMPLETADA';
        break;
      case 'cancelada':
        color = Colors.red;
        icon = Icons.cancel;
        textoMostrado = 'CANCELADA';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
        textoMostrado = estado.replaceAll('_', ' ').toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            textoMostrado,
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
