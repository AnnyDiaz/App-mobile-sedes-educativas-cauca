class VisitaRespuesta {
  final int? id;
  final int visitaId;
  final int itemId;
  final String respuesta;
  final String? observaciones;

  VisitaRespuesta({
    this.id,
    required this.visitaId,
    required this.itemId,
    required this.respuesta,
    this.observaciones,
  });

  factory VisitaRespuesta.fromJson(Map<String, dynamic> json) {
    return VisitaRespuesta(
      id: json['id'],
      visitaId: json['visita_id'] ?? 0,
      itemId: json['item_id'] ?? 0,
      respuesta: json['respuesta'] ?? '',
      observaciones: json['observaciones'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visita_id': visitaId,
      'item_id': itemId,
      'respuesta': respuesta,
      'observaciones': observaciones,
    };
  }
} 