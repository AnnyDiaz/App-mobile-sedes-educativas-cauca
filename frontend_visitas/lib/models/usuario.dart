class Usuario {
  final int id;
  final String nombre;
  final String? apellido;
  final String correo;
  final String? rol;
  final bool? activo;
  final DateTime? fechaCreacion;

  Usuario({
    required this.id,
    required this.nombre,
    this.apellido,
    required this.correo,
    this.rol,
    this.activo,
    this.fechaCreacion,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    // Extraer el nombre del rol del objeto anidado
    String? rolNombre;
    if (json['rol'] != null) {
      if (json['rol'] is String) {
        rolNombre = json['rol'];
      } else if (json['rol'] is Map<String, dynamic>) {
        rolNombre = json['rol']['nombre'];
      }
    }

    return Usuario(
      id: json['id'] is int ? json['id'] : (json['id'] is String ? int.tryParse(json['id']) ?? 0 : 0),
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'],
      correo: json['correo'] ?? '',
      rol: rolNombre,
      activo: json['activo'],
      fechaCreacion: json['fecha_creacion'] != null 
          ? DateTime.parse(json['fecha_creacion']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'correo': correo,
      'rol': rol,
      'activo': activo,
      'fecha_creacion': fechaCreacion?.toIso8601String(),
    };
  }
}