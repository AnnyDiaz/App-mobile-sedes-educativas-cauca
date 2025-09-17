class ChecklistItem {
  final int id;
  final String nombre;
  final String descripcion;
  final String tipo; // 'texto', 'numero', 'booleano', 'opciones'
  final List<String> opciones; // Para items de tipo 'opciones'
  final bool requerido;
  final int orden;

  ChecklistItem({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.tipo,
    required this.opciones,
    required this.requerido,
    required this.orden,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      tipo: json['tipo'] ?? 'texto',
      opciones: (json['opciones'] as List<dynamic>?)
          ?.map((opcion) => opcion.toString())
          .toList() ?? [],
      requerido: json['requerido'] ?? false,
      orden: json['orden'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'tipo': tipo,
      'opciones': opciones,
      'requerido': requerido,
      'orden': orden,
    };
  }
} 