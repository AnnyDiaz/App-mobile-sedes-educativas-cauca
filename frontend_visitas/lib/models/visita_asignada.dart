class VisitaAsignada {
  final int id;
  final int sedeId;
  final String sedeNombre;
  final int visitadorId;
  final String visitadorNombre;
  final int supervisorId;
  final String supervisorNombre;
  final DateTime fechaProgramada;
  final String tipoVisita;
  final String prioridad;
  final String estado;
  final String? contrato;
  final String? operador;
  final String? casoAtencionPrioritaria;
  final int municipioId;
  final String municipioNombre;
  final int institucionId;
  final String institucionNombre;
  final String? observaciones;
  final DateTime fechaCreacion;
  final DateTime? fechaInicio;
  final DateTime? fechaCompletada;

  VisitaAsignada({
    required this.id,
    required this.sedeId,
    required this.sedeNombre,
    required this.visitadorId,
    required this.visitadorNombre,
    required this.supervisorId,
    required this.supervisorNombre,
    required this.fechaProgramada,
    required this.tipoVisita,
    required this.prioridad,
    required this.estado,
    this.contrato,
    this.operador,
    this.casoAtencionPrioritaria,
    required this.municipioId,
    required this.municipioNombre,
    required this.institucionId,
    required this.institucionNombre,
    this.observaciones,
    required this.fechaCreacion,
    this.fechaInicio,
    this.fechaCompletada,
  });

  factory VisitaAsignada.fromJson(Map<String, dynamic> json) {
    return VisitaAsignada(
      id: json['id'],
      sedeId: json['sede_id'],
      sedeNombre: json['sede_nombre'] ?? '',
      visitadorId: json['visitador_id'],
      visitadorNombre: json['visitador_nombre'] ?? '',
      supervisorId: json['supervisor_id'],
      supervisorNombre: json['supervisor_nombre'] ?? '',
      fechaProgramada: DateTime.parse(json['fecha_programada']),
      tipoVisita: json['tipo_visita'] ?? 'PAE',
      prioridad: json['prioridad'] ?? 'normal',
      estado: json['estado'] ?? 'pendiente',
      contrato: json['contrato'],
      operador: json['operador'],
      casoAtencionPrioritaria: json['caso_atencion_prioritaria'],
      municipioId: json['municipio_id'],
      municipioNombre: json['municipio_nombre'] ?? '',
      institucionId: json['institucion_id'],
      institucionNombre: json['institucion_nombre'] ?? '',
      observaciones: json['observaciones'],
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      fechaInicio: json['fecha_inicio'] != null 
          ? DateTime.parse(json['fecha_inicio']) 
          : null,
      fechaCompletada: json['fecha_completada'] != null 
          ? DateTime.parse(json['fecha_completada']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sede_id': sedeId,
      'sede_nombre': sedeNombre,
      'visitador_id': visitadorId,
      'visitador_nombre': visitadorNombre,
      'supervisor_id': supervisorId,
      'supervisor_nombre': supervisorNombre,
      'fecha_programada': fechaProgramada.toIso8601String(),
      'tipo_visita': tipoVisita,
      'prioridad': prioridad,
      'estado': estado,
      'contrato': contrato,
      'operador': operador,
      'caso_atencion_prioritaria': casoAtencionPrioritaria,
      'municipio_id': municipioId,
      'municipio_nombre': municipioNombre,
      'institucion_id': institucionId,
      'institucion_nombre': institucionNombre,
      'observaciones': observaciones,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_inicio': fechaInicio?.toIso8601String(),
      'fecha_completada': fechaCompletada?.toIso8601String(),
    };
  }

  // Método para convertir a VisitaProgramada (para compatibilidad)
  Map<String, dynamic> toVisitaProgramadaMap() {
    return {
      'id': id,
      'sede_id': sedeId,
      'sede_nombre': sedeNombre,
      'visitador_id': visitadorId,
      'visitador_nombre': visitadorNombre,
      'fecha_programada': fechaProgramada.toIso8601String(),
      'contrato': contrato ?? '',
      'operador': operador ?? '',
      'observaciones': observaciones,
      'estado': estado,
      'municipio_id': municipioId,
      'municipio_nombre': municipioNombre,
      'institucion_id': institucionId,
      'institucion_nombre': institucionNombre,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }
}
