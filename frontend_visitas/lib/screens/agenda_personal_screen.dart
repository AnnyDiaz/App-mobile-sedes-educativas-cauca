import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/models/visita.dart';

class AgendaPersonalScreen extends StatefulWidget {
  const AgendaPersonalScreen({super.key});

  @override
  State<AgendaPersonalScreen> createState() => _AgendaPersonalScreenState();
}

class _AgendaPersonalScreenState extends State<AgendaPersonalScreen> {
  final ApiService _apiService = ApiService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Visita>> _events = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarVisitas();
  }

  Future<void> _cargarVisitas() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final visitas = await _apiService.getMisVisitas();
      
      // Agrupar visitas por fecha
      final eventos = <DateTime, List<Visita>>{};
      for (final visita in visitas) {
        if (visita.fechaCreacion != null) {
          final fecha = DateTime(
            visita.fechaCreacion!.year,
            visita.fechaCreacion!.month,
            visita.fechaCreacion!.day,
          );
          if (eventos[fecha] == null) eventos[fecha] = [];
          eventos[fecha]!.add(visita);
        }
      }

      setState(() {
        _events = eventos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Visita> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Agenda'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarVisitas,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildCalendarContent(),
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
            'Error al cargar agenda',
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
            onPressed: _cargarVisitas,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarContent() {
    return Column(
      children: [
        // Calendario
        TableCalendar<Visita>(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          eventLoader: _getEventsForDay,
          calendarStyle: const CalendarStyle(
            markerDecoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
          ),
        ),
        const SizedBox(height: 16),
        
        // Lista de eventos del día seleccionado
        Expanded(
          child: _selectedDay != null
              ? _buildEventsList(_selectedDay!)
              : _buildNoDaySelected(),
        ),
      ],
    );
  }

  Widget _buildNoDaySelected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Selecciona un día para ver las visitas',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(DateTime day) {
    final eventos = _getEventsForDay(day);
    
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
              'No hay visitas programadas para este día',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: eventos.length,
      itemBuilder: (context, index) {
        final visita = eventos[index];
        return _buildEventCard(visita);
      },
    );
  }

  Widget _buildEventCard(Visita visita) {
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
                  _getIconForEstado(visita.estado),
                  color: _getColorForEstado(visita.estado),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visita.tipoAsunto ?? 'Visita sin tipo',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (visita.sede != null)
                        Text(
                          visita.sede!.nombre,
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
                    color: _getColorForEstado(visita.estado).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    visita.estado ?? 'Sin estado',
                    style: TextStyle(
                      color: _getColorForEstado(visita.estado),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (visita.observaciones != null && visita.observaciones!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  visita.observaciones!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            if (visita.fechaCreacion != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(visita.fechaCreacion!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForEstado(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'pendiente':
        return Icons.pending_actions;
      case 'en_proceso':
        return Icons.play_circle_outline;
      case 'completada':
        return Icons.check_circle;
      case 'cancelada':
        return Icons.cancel;
      default:
        return Icons.event;
    }
  }

  Color _getColorForEstado(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'en_proceso':
        return Colors.blue;
      case 'completada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 