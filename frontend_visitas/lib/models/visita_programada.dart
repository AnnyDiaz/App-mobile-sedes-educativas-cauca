class VisitaProgramada {
  final int id;
  final String contrato;
  final String operador;
  final DateTime fechaProgramada;
  final int municipioId;
  final String municipioNombre;
  final int institucionId;
  final String institucionNombre;
  final int sedeId;
  final String sedeNombre;
  final int visitadorId;
  final String visitadorNombre;
  final String estado; // 'pendiente', 'en_progreso', 'completada'
  final String? observaciones;
  final DateTime fechaCreacion;

  VisitaProgramada({
    required this.id,
    required this.contrato,
    required this.operador,
    required this.fechaProgramada,
    required this.municipioId,
    required this.municipioNombre,
    required this.institucionId,
    required this.institucionNombre,
    required this.sedeId,
    required this.sedeNombre,
    required this.visitadorId,
    required this.visitadorNombre,
    required this.estado,
    this.observaciones,
    required this.fechaCreacion,
  });

  factory VisitaProgramada.fromJson(Map<String, dynamic> json) {
    return VisitaProgramada(
      id: json['id'],
      contrato: json['contrato'],
      operador: json['operador'],
      fechaProgramada: DateTime.parse(json['fecha_programada']),
      municipioId: json['municipio_id'],
      municipioNombre: json['municipio_nombre'],
      institucionId: json['institucion_id'],
      institucionNombre: json['institucion_nombre'],
      sedeId: json['sede_id'],
      sedeNombre: json['sede_nombre'],
      visitadorId: json['visitador_id'],
      visitadorNombre: json['visitador_nombre'],
      estado: json['estado'],
      observaciones: json['observaciones'],
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contrato': contrato,
      'operador': operador,
      'fecha_programada': fechaProgramada.toIso8601String(),
      'municipio_id': municipioId,
      'municipio_nombre': municipioNombre,
      'institucion_id': institucionId,
      'institucion_nombre': institucionNombre,
      'sede_id': sedeId,
      'sede_nombre': sedeNombre,
      'visitador_id': visitadorId,
      'visitador_nombre': visitadorNombre,
      'estado': estado,
      'observaciones': observaciones,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  // Getter para acceder al departamento del municipio
  String? get departamento => null; // Por ahora retornamos null, se puede implementar si es necesario
}
