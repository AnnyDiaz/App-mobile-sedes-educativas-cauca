class EvaluacionItem {
  final int? id;
  final int visitaId;
  final String item;
  final String valor;
  final String? observaciones;

  EvaluacionItem({
    this.id,
    required this.visitaId,
    required this.item,
    required this.valor,
    this.observaciones,
  });

  factory EvaluacionItem.fromJson(Map<String, dynamic> json) {
    return EvaluacionItem(
      id: json['id'],
      visitaId: json['visita_id'],
      item: json['item'],
      valor: json['valor'],
      observaciones: json['observaciones'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visita_id': visitaId,
      'item': item,
      'valor': valor,
      'observaciones': observaciones,
    };
  }
} 