class Institucion {
  final int id;
  final String nombre;
  final int municipioId;

  Institucion({required this.id, required this.nombre, required this.municipioId});

  factory Institucion.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 Procesando JSON institución: $json');
      final id = json['id'];
      final nombre = json['nombre'];
      final municipioId = json['municipio_id'] ?? 0;
      
      print('🔍 ID: $id (tipo: ${id.runtimeType})');
      print('🔍 Nombre: $nombre (tipo: ${nombre.runtimeType})');
      print('🔍 MunicipioID: $municipioId (tipo: ${municipioId.runtimeType})');
      
      return Institucion(
        id: id is int ? id : (id is String ? int.tryParse(id) ?? 0 : 0),
        nombre: nombre is String ? nombre : (nombre?.toString() ?? ''),
        municipioId: municipioId is int ? municipioId : (municipioId is String ? int.tryParse(municipioId) ?? 0 : 0),
      );
    } catch (e) {
      print('❌ Error procesando institución: $e');
      return Institucion(id: 0, nombre: 'Error', municipioId: 0);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'municipio_id': municipioId,
    };
  }

  @override
  String toString() => nombre;
}
