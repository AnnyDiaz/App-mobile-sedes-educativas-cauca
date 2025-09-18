import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/evidencia.dart';

class EvidenciasService {
  static const String baseUrl = 'http://localhost:8000'; // Cambiar según tu configuración

  // Subir evidencia individual
  static Future<String?> subirEvidencia({
    required String preguntaId,
    required File archivo,
    required TipoEvidencia tipo,
    required String token,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/evidencias/subir'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['pregunta_id'] = preguntaId;
      request.fields['tipo'] = tipo.toString().split('.').last;

      request.files.add(
        await http.MultipartFile.fromPath(
          'archivo',
          archivo.path,
          filename: archivo.path.split('/').last,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        final data = jsonDecode(responseBody);
        return data['id']; // ID de la evidencia subida
      } else {
        throw Exception('Error al subir evidencia: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Subir múltiples evidencias para un checklist
  static Future<Map<String, List<String>>> subirEvidenciasChecklist({
    required Map<String, List<Evidencia>> evidencias,
    required String token,
  }) async {
    final Map<String, List<String>> evidenciasSubidas = {};
    
    try {
      for (final entry in evidencias.entries) {
        final preguntaId = entry.key;
        final listaEvidencias = entry.value;
        final idsEvidencias = <String>[];

        for (final evidencia in listaEvidencias) {
          if (evidencia.esTemporal) {
            final archivo = File(evidencia.rutaArchivo);
            if (await archivo.exists()) {
              final idEvidencia = await subirEvidencia(
                preguntaId: preguntaId,
                archivo: archivo,
                tipo: evidencia.tipo,
                token: token,
              );
              
              if (idEvidencia != null) {
                idsEvidencias.add(idEvidencia);
              }
            }
          }
        }

        if (idsEvidencias.isNotEmpty) {
          evidenciasSubidas[preguntaId] = idsEvidencias;
        }
      }

      return evidenciasSubidas;
    } catch (e) {
      throw Exception('Error al subir evidencias del checklist: $e');
    }
  }

  // Obtener evidencias de una pregunta
  static Future<List<Evidencia>> obtenerEvidenciasPregunta({
    required String preguntaId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/evidencias/pregunta/$preguntaId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Evidencia.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener evidencias: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar evidencia
  static Future<bool> eliminarEvidencia({
    required String evidenciaId,
    required String token,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/evidencias/$evidenciaId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al eliminar evidencia: $e');
    }
  }

  // Descargar evidencia
  static Future<File?> descargarEvidencia({
    required String evidenciaId,
    required String token,
    required String rutaDestino,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/evidencias/$evidenciaId/descargar'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final archivo = File(rutaDestino);
        await archivo.writeAsBytes(response.bodyBytes);
        return archivo;
      } else {
        throw Exception('Error al descargar evidencia: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener estadísticas de evidencias
  static Future<Map<String, dynamic>> obtenerEstadisticasEvidencias({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/evidencias/estadisticas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener estadísticas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Validar tipo de archivo
  static bool esTipoArchivoValido(String nombreArchivo, TipoEvidencia tipo) {
    final extension = nombreArchivo.split('.').last.toLowerCase();
    
    switch (tipo) {
      case TipoEvidencia.foto:
        return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
      case TipoEvidencia.video:
        return ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm', 'mkv'].contains(extension);
      case TipoEvidencia.pdf:
        return ['pdf'].contains(extension);
      case TipoEvidencia.audio:
        return ['mp3', 'wav', 'aac', 'ogg', 'flac'].contains(extension);
      case TipoEvidencia.firma:
        return ['png', 'jpg', 'jpeg'].contains(extension); // Firmas como imágenes
      case TipoEvidencia.otro:
        return true; // Aceptar cualquier tipo
      default:
        return true; // Aceptar cualquier tipo por defecto
    }
  }

  // Obtener tamaño máximo permitido (en bytes)
  static int getTamanioMaximo(TipoEvidencia tipo) {
    switch (tipo) {
      case TipoEvidencia.foto:
        return 10 * 1024 * 1024; // 10 MB
      case TipoEvidencia.video:
        return 100 * 1024 * 1024; // 100 MB
      case TipoEvidencia.pdf:
        return 25 * 1024 * 1024; // 25 MB
      case TipoEvidencia.audio:
        return 50 * 1024 * 1024; // 50 MB
      case TipoEvidencia.firma:
        return 5 * 1024 * 1024; // 5 MB para firmas
      case TipoEvidencia.otro:
        return 50 * 1024 * 1024; // 50 MB
      default:
        return 50 * 1024 * 1024; // 50 MB por defecto
    }
  }

  // Validar archivo antes de subir
  static String? validarArchivo(File archivo, TipoEvidencia tipo) {
    // Verificar tamaño
    final tamanio = archivo.lengthSync();
    final tamanioMaximo = getTamanioMaximo(tipo);
    
    if (tamanio > tamanioMaximo) {
      return 'El archivo es demasiado grande. Tamaño máximo: ${_formatearTamanio(tamanioMaximo)}';
    }

    // Verificar tipo
    if (!esTipoArchivoValido(archivo.path, tipo)) {
      return 'Tipo de archivo no válido para este tipo de evidencia';
    }

    return null; // Archivo válido
  }

  // Formatear tamaño en bytes
  static String _formatearTamanio(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
