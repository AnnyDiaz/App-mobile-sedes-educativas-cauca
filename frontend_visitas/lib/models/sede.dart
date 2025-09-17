import 'package:frontend_visitas/models/municipio.dart';
import 'package:frontend_visitas/models/institucion.dart';

class Sede {
  final int id;
  final String nombre;
  final String dane;
  final String due;
  final double? lat;
  final double? lon;
  final bool principal;
  final Municipio municipio;
  final Institucion institucion;
  final int? _institucionId;

  Sede({
    required this.id, 
    required this.nombre,
    required this.dane,
    required this.due,
    this.lat,
    this.lon,
    required this.principal,
    required this.municipio,
    required this.institucion,
    int? institucionId,
  }) : _institucionId = institucionId;

  factory Sede.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 Procesando JSON sede: $json');
      
      // Manejar tanto datos anidados como datos planos
      Municipio municipio;
      Institucion institucion;
      
      if (json['municipio'] != null) {
        // Datos anidados (formato original)
        municipio = Municipio.fromJson(json['municipio']);
      } else {
        // Datos planos (formato nuevo)
        municipio = Municipio(
          id: json['municipio_id'] ?? 0,
          nombre: json['municipio_nombre'] ?? 'Desconocido'
        );
      }
      
      if (json['institucion'] != null) {
        // Datos anidados (formato original)
        institucion = Institucion.fromJson(json['institucion']);
      } else {
        // Datos planos (formato nuevo)
        institucion = Institucion(
          id: json['institucion_id'] ?? 0,
          nombre: json['institucion_nombre'] ?? 'Desconocida',
          municipioId: json['municipio_id'] ?? 0
        );
      }
      
      return Sede(
        id: json['id'] is int ? json['id'] : (json['id'] is String ? int.tryParse(json['id']) ?? 0 : 0),
        nombre: json['nombre'] ?? '',
        dane: json['dane'] ?? '',
        due: json['due'] ?? '',
        lat: json['lat'] != null ? (json['lat'] is double ? json['lat'] : double.tryParse(json['lat'].toString())) : null,
        lon: json['lon'] != null ? (json['lon'] is double ? json['lon'] : double.tryParse(json['lon'].toString())) : null,
        principal: json['principal'] ?? false,
        municipio: municipio,
        institucion: institucion,
        institucionId: json['institucion_id'],
      );
    } catch (e) {
      print('❌ Error procesando sede: $e');
      return Sede(
        id: 0, 
        nombre: 'Error',
        dane: '',
        due: '',
        principal: false,
        municipio: Municipio(id: 0, nombre: ''),
        institucion: Institucion(id: 0, nombre: '', municipioId: 0),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'dane': dane,
      'due': due,
      'lat': lat,
      'lon': lon,
      'principal': principal,
      'municipio': municipio.toJson(),
      'institucion': institucion.toJson(),
    };
  }

  int get institucionId => _institucionId ?? institucion.id;
  int get municipioId => municipio.id;
  String? get departamento => municipio.departamento;
  
  @override
  String toString() => nombre;
}
