import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/visita_programada.dart';
import '../services/api_service.dart';

class CalendarioVisitasScreen extends StatefulWidget {
  const CalendarioVisitasScreen({Key? key}) : super(key: key);

  @override
  State<CalendarioVisitasScreen> createState() => _CalendarioVisitasScreenState();
}

class _CalendarioVisitasScreenState extends State<CalendarioVisitasScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  
  // Cambiar el tipo para usar Map<String, dynamic> en lugar de VisitaProgramada
  List<Map<String, dynamic>> _visitasProgramadas = [];
  Map<DateTime, List<Map<String, dynamic>>> _eventos = {};
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _cargarVisitasProgramadas();
  }

  Future<void> _cargarVisitasProgramadas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Usar el nuevo método que obtiene todas las visitas
      final visitas = await _apiService.getTodasVisitasUsuario();
      print('📅 DEBUG: Total visitas obtenidas: ${visitas.length}');
      
      setState(() {
        _visitasProgramadas = visitas;
        _isLoading = false;
      });
      
      // Agrupar visitas por fecha para el calendario
      _agruparVisitasPorFecha();
      
    } catch (e) {
      print('❌ Error al cargar visitas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _agruparVisitasPorFecha() {
    final Map<DateTime, List<Map<String, dynamic>>> eventos = {};
    
    for (final visita in _visitasProgramadas) {
      final fecha = DateTime.parse(visita['fecha_programada']);
      final fechaNormalizada = DateTime(fecha.year, fecha.month, fecha.day);
      
      if (eventos[fechaNormalizada] == null) {
        eventos[fechaNormalizada] = [];
      }
      eventos[fechaNormalizada]!.add(visita);
    }
    
    setState(() {
      _eventos = eventos;
    });
    
    print('📅 DEBUG: Eventos agrupados: ${_eventos.length} fechas');
  }

  List<Map<String, dynamic>> _getEventosDelDia(DateTime fecha) {
    final fechaNormalizada = DateTime(fecha.year, fecha.month, fecha.day);
    return _eventos[fechaNormalizada] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _onFormatChanged(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });
  }

  void _crearCronogramaPAE(Map<String, dynamic> visita) {
    Navigator.pushNamed(
      context,
      '/crear_cronograma',
      arguments: {'visitaProgramadaMap': visita},
    );
  }

  Widget _buildEventosDelDia() {
    if (_selectedDay == null) {
      return const Center(
        child: Text(
          'Selecciona una fecha para ver las visitas programadas',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    final eventos = _getEventosDelDia(_selectedDay!);
    
    if (eventos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay visitas programadas para el ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
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
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Visitas del ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: eventos.length,
            itemBuilder: (context, index) {
              final visita = eventos[index];
              return _buildTarjetaVisita(visita);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTarjetaVisita(Map<String, dynamic> visita) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    visita['sede_nombre'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildChipEstado(visita['estado']),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.orange[600],
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${DateTime.parse(visita['fecha_programada']).hour.toString().padLeft(2, '0')}:${DateTime.parse(visita['fecha_programada']).minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: Colors.green[600],
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Contrato: ${visita['contrato']}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: Colors.purple[600],
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Operador: ${visita['operador']}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            
            if (visita['observaciones'] != null && visita['observaciones']!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.note,
                    color: Colors.amber[600],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Observaciones: ${visita['observaciones']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
                              child: ElevatedButton.icon(
                  onPressed: () => _crearCronogramaPAE(visita),
                  icon: const Icon(Icons.add_task),
                  label: const Text('Crear Visita PAE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipEstado(String estado) {
    Color color;
    String texto;
    
    switch (estado.toLowerCase()) {
      case 'programada':
        color = Colors.blue;
        texto = 'Programada';
        break;
      case 'en_proceso':
        color = Colors.orange;
        texto = 'En Proceso';
        break;
      case 'completada':
        color = Colors.green;
        texto = 'Completada';
        break;
      case 'cancelada':
        color = Colors.red;
        texto = 'Cancelada';
        break;
      default:
        color = Colors.grey;
        texto = estado;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Calendario de Visitas'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarVisitasProgramadas,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.blue[50]!,
                    Colors.white,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Contenedor para el calendario
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TableCalendar<VisitaProgramada>(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: _onDaySelected,
                  onFormatChanged: _onFormatChanged,
                  onPageChanged: _onPageChanged,
                  eventLoader: (date) => _getEventosDelDia(date).cast<VisitaProgramada>(),
                  calendarStyle: const CalendarStyle(
                    outsideDaysVisible: false,
                    weekendTextStyle: TextStyle(color: Colors.red),
                    holidayTextStyle: TextStyle(color: Colors.red),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isNotEmpty) {
                        return Positioned(
                          right: 1,
                          top: 1,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: Colors.blue[600],
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${events.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                ),
                    ),
                  const Divider(height: 1),
                  Expanded(
                    child: _buildEventosDelDia(),
                  ),
                ],
              ),
            ),
    );
  }
}
