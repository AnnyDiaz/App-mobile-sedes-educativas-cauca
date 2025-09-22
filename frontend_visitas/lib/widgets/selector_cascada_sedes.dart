import 'package:flutter/material.dart';

class SelectorCascadaSedes extends StatefulWidget {
  final List<Map<String, dynamic>> municipios;
  final List<Map<String, dynamic>> instituciones;
  final List<Map<String, dynamic>> sedes;
  final List<int> sedesSeleccionadas;
  final Function(List<int>) onSedesChanged;

  const SelectorCascadaSedes({
    Key? key,
    required this.municipios,
    required this.instituciones,
    required this.sedes,
    required this.sedesSeleccionadas,
    required this.onSedesChanged,
  }) : super(key: key);

  @override
  _SelectorCascadaSedesState createState() => _SelectorCascadaSedesState();
}

class _SelectorCascadaSedesState extends State<SelectorCascadaSedes> {
  int? _municipioSeleccionado;
  int? _institucionSeleccionada;
  List<Map<String, dynamic>> _institucionesFiltradas = [];
  List<Map<String, dynamic>> _sedesFiltradas = [];

  @override
  void initState() {
    super.initState();
    _institucionesFiltradas = widget.instituciones;
    _sedesFiltradas = widget.sedes;
  }

  @override
  void didUpdateWidget(SelectorCascadaSedes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.municipios != widget.municipios ||
        oldWidget.instituciones != widget.instituciones ||
        oldWidget.sedes != widget.sedes) {
      _resetearFiltros();
    }
  }

  void _resetearFiltros() {
    setState(() {
      _municipioSeleccionado = null;
      _institucionSeleccionada = null;
      _institucionesFiltradas = widget.instituciones;
      _sedesFiltradas = widget.sedes;
    });
  }

  void _onMunicipioChanged(int? municipioId) {
    setState(() {
      _municipioSeleccionado = municipioId;
      _institucionSeleccionada = null;
      
      if (municipioId != null) {
        // Filtrar instituciones por municipio
        _institucionesFiltradas = widget.instituciones
            .where((inst) => inst['municipio_id'] == municipioId)
            .toList();
        
        // Filtrar sedes por municipio
        _sedesFiltradas = widget.sedes
            .where((sede) => sede['municipio_id'] == municipioId)
            .toList();
      } else {
        _institucionesFiltradas = widget.instituciones;
        _sedesFiltradas = widget.sedes;
      }
      
      // Limpiar selección de sedes
      widget.onSedesChanged([]);
    });
  }

  void _onInstitucionChanged(int? institucionId) {
    setState(() {
      _institucionSeleccionada = institucionId;
      
      if (institucionId != null) {
        // Filtrar sedes por institución
        _sedesFiltradas = widget.sedes
            .where((sede) => sede['institucion_id'] == institucionId)
            .toList();
      } else if (_municipioSeleccionado != null) {
        // Si hay municipio seleccionado pero no institución, mostrar todas las sedes del municipio
        _sedesFiltradas = widget.sedes
            .where((sede) => sede['municipio_id'] == _municipioSeleccionado)
            .toList();
      } else {
        _sedesFiltradas = widget.sedes;
      }
      
      // Limpiar selección de sedes
      widget.onSedesChanged([]);
    });
  }

  void _onSedeToggled(int sedeId, bool seleccionada) {
    List<int> nuevasSedes = List.from(widget.sedesSeleccionadas);
    
    if (seleccionada) {
      if (!nuevasSedes.contains(sedeId)) {
        nuevasSedes.add(sedeId);
      }
    } else {
      nuevasSedes.remove(sedeId);
    }
    
    widget.onSedesChanged(nuevasSedes);
  }

  void _seleccionarTodas() {
    List<int> todasLasSedes = _sedesFiltradas.map((sede) => sede['id'] as int).toList();
    widget.onSedesChanged(todasLasSedes);
  }

  void _deseleccionarTodas() {
    widget.onSedesChanged([]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selector de Municipio
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_city, color: Colors.blue[600]),
                    SizedBox(width: 8),
                    Text(
                      '1. Seleccionar Municipio',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _municipioSeleccionado,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Municipio',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  items: [
                    DropdownMenuItem<int>(
                      value: null,
                      child: Text(
                        'Todos los municipios', 
                        style: TextStyle(color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    ...widget.municipios.map((municipio) => DropdownMenuItem<int>(
                      value: municipio['id'],
                      child: Text(
                        municipio['nombre'],
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    )),
                  ],
                  onChanged: _onMunicipioChanged,
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: 16),
        
        // Selector de Institución
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.school, color: Colors.green[600]),
                    SizedBox(width: 8),
                    Text(
                      '2. Seleccionar Institución',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _institucionSeleccionada,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Institución',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school),
                  ),
                  items: [
                    DropdownMenuItem<int>(
                      value: null,
                      child: Text(
                        'Todas las instituciones', 
                        style: TextStyle(color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    ..._institucionesFiltradas.map((institucion) => DropdownMenuItem<int>(
                      value: institucion['id'],
                      child: Text(
                        institucion['nombre'],
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    )),
                  ],
                  onChanged: _onInstitucionChanged,
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: 16),
        
        // Selector de Sedes
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.business, color: Colors.orange[600]),
                    SizedBox(width: 8),
                    Text(
                      '3. Seleccionar Sedes',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Spacer(),
                    if (_sedesFiltradas.isNotEmpty) ...[
                      TextButton.icon(
                        onPressed: _seleccionarTodas,
                        icon: Icon(Icons.select_all, size: 16),
                        label: Text('Todas'),
                      ),
                      TextButton.icon(
                        onPressed: _deseleccionarTodas,
                        icon: Icon(Icons.clear_all, size: 16),
                        label: Text('Ninguna'),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 12),
                
                if (_sedesFiltradas.isEmpty)
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey[600], size: 32),
                          SizedBox(height: 8),
                          Text(
                            'Selecciona un municipio e institución para ver las sedes disponibles',
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: _sedesFiltradas.length,
                      itemBuilder: (context, index) {
                        final sede = _sedesFiltradas[index];
                        final sedeId = sede['id'] as int;
                        final isSelected = widget.sedesSeleccionadas.contains(sedeId);
                        
                        return CheckboxListTile(
                          title: Text(sede['nombre']),
                          subtitle: Text('DANE: ${sede['dane']}'),
                          value: isSelected,
                          onChanged: (value) => _onSedeToggled(sedeId, value ?? false),
                          secondary: Icon(
                            sede['principal'] == true ? Icons.star : Icons.business,
                            color: sede['principal'] == true ? Colors.amber : Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ),
                
                if (widget.sedesSeleccionadas.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.blue[600], size: 20),
                        SizedBox(width: 8),
                        Text(
                          '${widget.sedesSeleccionadas.length} sede(s) seleccionada(s)',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
