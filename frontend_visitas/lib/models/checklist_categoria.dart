import 'checklist_item.dart';

class ChecklistCategoria {
  final int id;
  final String nombre;
  final String descripcion;
  final List<ChecklistItem> items;

  ChecklistCategoria({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.items,
  });

  factory ChecklistCategoria.fromJson(Map<String, dynamic> json) {
    return ChecklistCategoria(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => ChecklistItem.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
} 