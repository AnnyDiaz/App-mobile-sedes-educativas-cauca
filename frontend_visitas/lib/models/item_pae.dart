class ItemPAE {
  final int id;
  final String nombre;
  final String? categoria;
  final List<SubItemPAE>? items;

  ItemPAE({
    required this.id,
    required this.nombre,
    this.categoria,
    this.items,
  });

  factory ItemPAE.fromJson(Map<String, dynamic> json) {
    return ItemPAE(
      id: json['id'] ?? 0,
      nombre: json['nombre']?.toString() ?? 'Sin nombre',
      categoria: json['categoria']?.toString(),
      items: json['items'] != null 
          ? (json['items'] as List).map((item) => SubItemPAE.fromJson(item)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria,
      'items': items?.map((item) => item.toJson()).toList(),
    };
  }
}

class SubItemPAE {
  final int id;
  final String preguntaTexto;

  SubItemPAE({
    required this.id,
    required this.preguntaTexto,
  });

  factory SubItemPAE.fromJson(Map<String, dynamic> json) {
    return SubItemPAE(
      id: json['id'] ?? 0,
      preguntaTexto: json['pregunta_texto']?.toString() ?? 'Sin pregunta',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pregunta_texto': preguntaTexto,
    };
  }
} 