import 'dart:io';
import 'dart:typed_data';

enum TipoEvidencia {
  foto,
  video,
  pdf,
  audio,
  firma,
  otro
}

class Evidencia {
  final String? id;
  final String preguntaId;
  final String nombreArchivo;
  final String rutaArchivo;
  final TipoEvidencia tipo;
  final DateTime fechaCreacion;
  final int? tamanoBytes;
  final String? mimeType;
  final bool esTemporal;

  Evidencia({
    this.id,
    required this.preguntaId,
    required this.nombreArchivo,
    required this.rutaArchivo,
    required this.tipo,
    required this.fechaCreacion,
    this.tamanoBytes,
    this.mimeType,
    this.esTemporal = true,
  });

  // Crear evidencia desde archivo
  factory Evidencia.desdeArchivo({
    required String preguntaId,
    required File archivo,
    required TipoEvidencia tipo,
  }) {
    return Evidencia(
      preguntaId: preguntaId,
      nombreArchivo: archivo.path.split('/').last,
      rutaArchivo: archivo.path,
      tipo: tipo,
      fechaCreacion: DateTime.now(),
      tamanoBytes: archivo.lengthSync(),
      mimeType: _obtenerMimeType(archivo.path),
    );
  }

  // Crear evidencia desde firma digital
  factory Evidencia.desdeFirma({
    required String preguntaId,
    required Uint8List firmaBytes,
    required String nombreUsuario,
  }) {
    return Evidencia(
      preguntaId: preguntaId,
      nombreArchivo: 'firma_${nombreUsuario}_${DateTime.now().millisecondsSinceEpoch}.png',
      rutaArchivo: 'firma_digital', // Identificador especial para firmas
      tipo: TipoEvidencia.firma,
      fechaCreacion: DateTime.now(),
      tamanoBytes: firmaBytes.length,
      mimeType: 'image/png',
    );
  }

  // Crear evidencia desde JSON
  factory Evidencia.fromJson(Map<String, dynamic> json) {
    return Evidencia(
      id: json['id'],
      preguntaId: json['pregunta_id'],
      nombreArchivo: json['nombre_archivo'],
      rutaArchivo: json['ruta_archivo'],
      tipo: TipoEvidencia.values.firstWhere(
        (e) => e.toString().split('.').last == json['tipo'],
        orElse: () => TipoEvidencia.otro,
      ),
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      tamanoBytes: json['tamano_bytes'],
      mimeType: json['mime_type'],
      esTemporal: json['es_temporal'] ?? false,
    );
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pregunta_id': preguntaId,
      'nombre_archivo': nombreArchivo,
      'ruta_archivo': rutaArchivo,
      'tipo': tipo.toString().split('.').last,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'tamano_bytes': tamanoBytes,
      'mime_type': mimeType,
      'es_temporal': esTemporal,
    };
  }

  // Obtener MIME type basado en extensión
  static String? _obtenerMimeType(String ruta) {
    final extension = ruta.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/x-msvideo';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      default:
        return 'application/octet-stream';
    }
  }

  // Obtener icono según tipo
  String get icono {
    switch (tipo) {
      case TipoEvidencia.foto:
        return '📷';
      case TipoEvidencia.video:
        return '🎥';
      case TipoEvidencia.pdf:
        return '📄';
      case TipoEvidencia.audio:
        return '🎵';
      case TipoEvidencia.otro:
        return '📎';
      case TipoEvidencia.firma:
        return '✍️';
      default:
        return '📎';
    }
  }

  // Obtener color según tipo
  int get color {
    switch (tipo) {
      case TipoEvidencia.foto:
        return 0xFF4CAF50; // Verde
      case TipoEvidencia.video:
        return 0xFF2196F3; // Azul
      case TipoEvidencia.pdf:
        return 0xFFF44336; // Rojo
      case TipoEvidencia.audio:
        return 0xFF9C27B0; // Púrpura
      case TipoEvidencia.otro:
        return 0xFF607D8B; // Gris azulado
      case TipoEvidencia.firma:
        return 0xFF795548; // Marrón
      default:
        return 0xFF607D8B; // Gris azulado por defecto
    }
  }

  // Obtener tamaño formateado
  String get tamanoFormateado {
    if (tamanoBytes == null) return 'N/A';
    
    if (tamanoBytes! < 1024) {
      return '${tamanoBytes} B';
    } else if (tamanoBytes! < 1024 * 1024) {
      return '${(tamanoBytes! / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(tamanoBytes! / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // Copiar con cambios
  Evidencia copyWith({
    String? id,
    String? preguntaId,
    String? nombreArchivo,
    String? rutaArchivo,
    TipoEvidencia? tipo,
    DateTime? fechaCreacion,
    int? tamanoBytes,
    String? mimeType,
    bool? esTemporal,
  }) {
    return Evidencia(
      id: id ?? this.id,
      preguntaId: preguntaId ?? this.preguntaId,
      nombreArchivo: nombreArchivo ?? this.nombreArchivo,
      rutaArchivo: rutaArchivo ?? this.rutaArchivo,
      tipo: tipo ?? this.tipo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      tamanoBytes: tamanoBytes ?? this.tamanoBytes,
      mimeType: mimeType ?? this.mimeType,
      esTemporal: esTemporal ?? this.esTemporal,
    );
  }
}
