// lib/models/municipio.dart

class Municipio {
  final int id;
  final String nombre;
  final String? departamento;

  Municipio({required this.id, required this.nombre, this.departamento});

  factory Municipio.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 Procesando JSON municipio: $json');
      final id = json['id'];
      final nombre = json['nombre'];
      
      print('🔍 ID: $id (tipo: ${id.runtimeType})');
      print('🔍 Nombre: $nombre (tipo: ${nombre.runtimeType})');
      
      return Municipio(
        id: id is int ? id : (id is String ? int.tryParse(id) ?? 0 : 0),
        nombre: nombre is String ? nombre : (nombre?.toString() ?? ''),
        departamento: json['departamento'],
      );
    } catch (e) {
      print('❌ Error procesando municipio: $e');
      return Municipio(id: 0, nombre: 'Error', departamento: null);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'departamento': departamento,
    };
  }

  @override
  String toString() => nombre;
}