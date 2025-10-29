import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend_visitas/utils/platform_compat.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:frontend_visitas/services/permission_service.dart';

// Importa tus modelos y configuración
import 'package:frontend_visitas/config.dart';
import 'package:frontend_visitas/models/visita.dart';
import 'package:frontend_visitas/models/municipio.dart';
import 'package:frontend_visitas/models/sede.dart';
import 'package:frontend_visitas/models/institucion.dart';
import 'package:frontend_visitas/models/usuario.dart';

import 'package:frontend_visitas/models/evaluacion_item.dart';
import 'package:frontend_visitas/models/item_pae.dart';
import 'package:frontend_visitas/models/checklist_categoria.dart';
import 'package:frontend_visitas/models/checklist_item.dart';
import 'package:frontend_visitas/models/visita_respuesta.dart';
import 'package:frontend_visitas/models/evidencia.dart';
import 'package:frontend_visitas/models/visita_programada.dart';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'error_handler_service.dart';

class ApiService {
  // Configuración de almacenamiento seguro
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // --- MÉTODOS AUXILIARES ---
  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  Future<int?> getUsuarioId() async {
    final token = await getToken();
    if (token != null && !JwtDecoder.isExpired(token)) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      return decodedToken['id'];
    }
    return null;
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && !JwtDecoder.isExpired(token);
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    if (token == null) {
      return {
        'Content-Type': 'application/json; charset=UTF-8',
      };
    }
    
    // Verificar si el token está expirado
    if (JwtDecoder.isExpired(token)) {
      // Intentar renovar el token
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        // Obtener el nuevo token
        final newToken = await getToken();
        return {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $newToken',
        };
      } else {
        await logout();
        return {
          'Content-Type': 'application/json; charset=UTF-8',
        };
      }
    }
    
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  // --- AUTENTICACIÓN ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'correo': email, 'contrasena': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Guardar tokens de forma segura
      await _storage.write(key: 'access_token', value: data['access_token']);
      if (data['refresh_token'] != null) {
        await _storage.write(key: 'refresh_token', value: data['refresh_token']);
      }
      
      // También guardar en SharedPreferences para compatibilidad (solo el rol)
      final prefs = await SharedPreferences.getInstance();
      if (data['usuario'] != null && data['usuario']['rol'] != null) {
        await prefs.setString('rol', data['usuario']['rol']['nombre']);
      }
      
      return data;
    } else {
      throw Exception('Error al iniciar sesión: ${response.body}');
    }
  }

  Future<void> logout() async {
    // Limpiar tokens del almacenamiento seguro
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    
    // Limpiar datos de SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('rol');
  }

  Future<Map<String, dynamic>> register(String nombre, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'nombre': nombre,
        'correo': email,
        'contrasena': password,
        'rol_id': 4, // Rol Visitador (ID: 1=Super Admin, 2=Admin, 3=Supervisor, 4=Visitador)
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'message': 'Usuario registrado exitosamente',
        'usuario': data['usuario'],
      };
    } else {
      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'message': errorData['detail'] ?? 'Error en el registro',
      };
    }
  }

  // --- RENOVACIÓN AUTOMÁTICA DE TOKENS ---
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'access_token', value: data['access_token']);
        return true;
      }
      return false;
    } catch (e) {
      print('Error renovando token: $e');
      return false;
    }
  }

  /// Obtiene el perfil del usuario autenticado
  Future<Map<String, dynamic>> getPerfilUsuario() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/perfil'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      // Si no hay endpoint específico, devolver datos del token
      final token = await getToken();
      if (token != null && !JwtDecoder.isExpired(token)) {
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        return {
          'nombre': decodedToken['nombre'] ?? 'Usuario',
          'rol': decodedToken['rol'] ?? 'Visitador',
          'email': decodedToken['sub'] ?? 'usuario@example.com',
        };
      }
      throw Exception('Error al obtener perfil de usuario: ${response.body}');
    }
  }

  /// Cambia la contraseña del usuario autenticado
  Future<bool> cambiarContrasena({
    required String contrasenaActual,
    required String contrasenaNueva,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final body = {
        'contrasena_actual': contrasenaActual,
        'contrasena_nueva': contrasenaNueva,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/api/auth/cambiar-contrasena'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('🔑 Cambiar contraseña - Status: ${response.statusCode}');
      print('🔑 Response: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error en cambiarContrasena: $e');
      throw Exception('Error al cambiar contraseña: $e');
    }
  }

  // --- OBTENER DATOS ---
  Future<List<Visita>> getMisVisitas() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/api/visitas/mis-visitas'), headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Visita.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar visitas');
    }
  }

  Future<List<Visita>> getMisVisitasPorEstado(String estado) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/api/visitas/mis-visitas?estado=$estado'), headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Visita.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar visitas por estado');
    }
  }

  Future<List<Municipio>> getMunicipios() async {
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl/api/municipios';
      print('🔗 Solicitando municipios a: $url');
      print('🔑 Headers: $headers');
      
      final response = await http.get(Uri.parse(url), headers: headers);
      
      print('📌 Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('📊 Datos parseados: $data');
        
        final municipios = data.map((json) {
          print('🏛️ Procesando municipio: $json');
          return Municipio.fromJson(json);
        }).toList();
        
        print('✅ Municipios procesados: ${municipios.length}');
        return municipios;
      } else {
        throw Exception('Error al cargar municipios. Código: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en getMunicipios: $e');
      throw Exception('Error al cargar municipios: $e');
    }
  }

  Future<List<Institucion>> getInstituciones() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/api/instituciones'), headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Institucion.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar instituciones');
    }
  }

  Future<List<Institucion>> getInstitucionesPorMunicipio(int municipioId) async {
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl/api/instituciones_por_municipio/$municipioId';
      print('🔗 Solicitando instituciones a: $url');
      print('🔑 Headers: $headers');
      
      final response = await http.get(Uri.parse(url), headers: headers);
      
      print('📌 Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('📊 Datos parseados: $data');
        
        final instituciones = data.map((json) {
          print('🏛️ Procesando institución: $json');
          return Institucion.fromJson(json);
        }).toList();
        
        print('✅ Instituciones procesadas: ${instituciones.length}');
        return instituciones;
      } else {
        throw Exception('Error al obtener instituciones por municipio. Código: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en getInstitucionesPorMunicipio: $e');
      throw Exception('Error al obtener instituciones por municipio: $e');
    }
  }

  /// Obtiene las sedes filtradas por el ID de un municipio.
  Future<List<Sede>> getSedesPorMunicipio(int municipioId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/sedes_por_municipio/$municipioId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Sede.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar sedes por municipio. Código: ${response.statusCode}');
    }
  }

  /// Obtiene las sedes filtradas por el ID de una institución.
  Future<List<Sede>> getSedesPorInstitucion(int institucionId) async {
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl/api/sedes_institucion/$institucionId';
      print('🔗 Solicitando sedes a: $url');
      print('🔑 Headers: $headers');
      
      final response = await http.get(Uri.parse(url), headers: headers);
      
      print('📌 Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('📊 Datos parseados: $data');
        
        final sedes = data.map((json) {
          print('🏫 Procesando sede: $json');
          return Sede.fromJson(json);
        }).toList();
        
        print('✅ Sedes procesadas: ${sedes.length}');
        return sedes;
      } else {
        throw Exception('Error al cargar sedes por institución. Código: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en getSedesPorInstitucion: $e');
      throw Exception('Error al cargar sedes por institución: $e');
    }
  }

  /// Obtiene todas las sedes disponibles.
  Future<List<Sede>> getSedes() async {
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl/api/sedes';
      print('🔗 Solicitando todas las sedes a: $url');
      
      final response = await http.get(Uri.parse(url), headers: headers);
      
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final sedes = data.map((json) => Sede.fromJson(json)).toList();
        print('✅ Sedes obtenidas: ${sedes.length}');
        return sedes;
      } else {
        throw Exception('Error al cargar sedes. Código: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getSedes: $e');
      throw Exception('Error al cargar sedes: $e');
    }
  }

  /// Obtiene todos los usuarios disponibles.
  Future<List<Usuario>> getUsuarios() async {
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl/api/admin/usuarios';
      print('🔗 Solicitando todos los usuarios a: $url');
      
      final response = await http.get(Uri.parse(url), headers: headers);
      
      print('📌 Respuesta de usuarios - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final usuarios = data.map((json) => Usuario.fromJson(json)).toList();
        print('✅ Usuarios obtenidos: ${usuarios.length}');
        return usuarios;
      } else {
        throw Exception('Error al cargar usuarios. Código: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getUsuarios: $e');
      throw Exception('Error al cargar usuarios: $e');
    }
  }

  // --- CREAR VISITA ---
  Future<bool> crearVisita({
    required int sedeId,
    required String tipoAsunto,
    required String observaciones,
    required double lat,
    required double lon,
    required String prioridad,
    required String hora,
    File? fotoEvidencia,
    File? firma,
  }) async {
    final token = await getToken();
    final usuarioId = await getUsuarioId();
    if (usuarioId == null) throw Exception('No se pudo obtener el ID del usuario');

    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/visitas'));
    request.headers['Authorization'] = 'Bearer $token';

    request.fields.addAll({
      'sede_id': sedeId.toString(),
      'usuario_id': usuarioId.toString(),
      'tipo_asunto': tipoAsunto,
      'observaciones': observaciones,
      'lat': lat.toString(),
      'lon': lon.toString(),
      'prioridad': prioridad,
      'hora': hora,
    });

    if (fotoEvidencia != null) {
      request.files.add(await http.MultipartFile.fromPath('foto_evidencia', fotoEvidencia.path));
    }

    if (firma != null) {
      request.files.add(await http.MultipartFile.fromPath('foto_firma', firma.path));
    }

    final response = await request.send();
    return response.statusCode == 201;
  }

  // --- CREAR VISITA COMPLETA PAE ---
  Future<bool> crearVisitaCompletaPAE({
    required DateTime fechaVisita,
    required TimeOfDay horaVisita,
    required String contrato,
    required String operador,
    required int municipioId,
    required int institucionId,
    required int sedeId,
    int? profesionalId,
    required String casoAtencionPrioritaria,
    required String tipoVisita,
    required String prioridad,
    required String observaciones,
    double? lat,
    double? lon,
    double? precisionGps,
    Map<int, String>? respuestasChecklist,
  }) async {
    try {
      final token = await getToken();
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      // Validar IDs del checklist antes de enviar
      if (respuestasChecklist != null && respuestasChecklist.isNotEmpty) {
        // Obtener el checklist actual para validación
        try {
          final checklist = await getChecklist();
          final validacion = validarChecklistIds(respuestasChecklist, checklist);
          
          if (!validacion['esValido']) {
            print('❌ Validación del checklist falló: ${validacion['mensaje']}');
            throw Exception('IDs del checklist inválidos: ${validacion['idsInvalidos']}. Por favor, recarga la página y vuelve a intentar.');
          }
          
          print('✅ Validación del checklist exitosa: ${validacion['mensaje']}');
        } catch (e) {
          print('⚠️ No se pudo validar el checklist: $e');
          // Continuar sin validación si hay error
        }
      }
      
      // Preparar las respuestas del checklist
      List<Map<String, dynamic>> respuestas = [];
      if (respuestasChecklist != null) {
        respuestasChecklist.forEach((itemId, respuesta) {
          respuestas.add({
            "item_id": itemId,
            "respuesta": respuesta,
            "observacion": null
          });
        });
      }

      final body = {
        "fecha_visita": fechaVisita.toIso8601String(),
        "contrato": contrato,
        "operador": operador,
        "municipio_id": municipioId,
        "institucion_id": institucionId,
        "sede_id": sedeId,
        "profesional_id": profesionalId,
        "caso_atencion_prioritaria": casoAtencionPrioritaria,
        "observaciones": observaciones,
        "respuestas_checklist": respuestas,
      };

      final url = '$baseUrl/api/visitas-completas-pae';
      print('🔗 === INICIANDO ENVÍO DE CRONOGRAMA ===');
      print('🔗 URL: $url');
      print('🔗 Base URL: $baseUrl');
      print('🔑 Headers: $headers');
      print('📦 Body: $body');
      print('📋 Respuestas checklist incluidas: ${respuestasChecklist?.length ?? 0} items');

      // Verificar conectividad antes de enviar
      try {
        final testFuture = http.get(
          Uri.parse('$baseUrl/'),
          headers: {'Content-Type': 'application/json'},
        );
        final testResponse = await testFuture.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw Exception('Timeout: No se pudo conectar en 5 segundos');
          },
        );
        print('✅ Conexión al servidor verificada: ${testResponse.statusCode}');
      } catch (testError) {
        print('❌ Error al verificar conexión: $testError');
        throw Exception('No se pudo conectar con el servidor en $baseUrl. Verifica que el contenedor esté corriendo y accesible.');
      }

      final postFuture = http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      final response = await postFuture.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: El servidor tardó demasiado en responder');
        },
      );

      // Verificar si es un error de autenticación
      if (response.statusCode == 401) {
        throw Exception('UNAUTHORIZED');
      }

      // NOTA: Sincronización deshabilitada automáticamente después de crear cronograma
      // Si necesitas sincronizar, hazlo manualmente desde el dashboard
      // 
      // if (response.statusCode == 200 || response.statusCode == 201) {
      //   try {
      //     final syncResult = await sincronizarTodasLasVisitas();
      //     print('✅ Sincronización completada. Resultado: $syncResult');
      //   } catch (e) {
      //     print('⚠️ Error en sincronización: $e');
      //   }
      // } else {
      //   print('❌ No se pudo crear el cronograma. Status: ${response.statusCode}');
      // }
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('❌ No se pudo crear el cronograma. Status: ${response.statusCode}');
      }

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ === ERROR AL CREAR CRONOGRAMA ===');
      print('❌ Tipo de error: ${e.runtimeType}');
      print('❌ Mensaje: $e');
      print('❌ Base URL intentada: $baseUrl');
      
      // Verificar si es un error de autenticación
      if (e.toString().contains('UNAUTHORIZED') || e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        await logout(); // Limpiar token expirado
        throw Exception('UNAUTHORIZED');
      }
      
      // Detectar errores de conexión
      if (e.toString().contains('Failed to fetch') || 
          e.toString().contains('SocketException') || 
          e.toString().contains('NetworkError') ||
          e.toString().contains('ClientException') ||
          e.toString().contains('TimeoutException') ||
          e.toString().contains('timeout')) {
        String mensaje = 'Error de conexión: No se pudo conectar con el servidor en $baseUrl.\n\n';
        mensaje += 'Verifica:\n';
        mensaje += '1. El contenedor Docker está corriendo\n';
        mensaje += '2. La IP del servidor es correcta\n';
        mensaje += '3. El firewall permite conexiones al puerto 8000\n';
        mensaje += '4. Puedes acceder a $baseUrl/ en tu navegador';
        throw Exception(mensaje);
      }
      
      // Error genérico
      String mensajeError = 'Error al crear cronograma PAE';
      if (e.toString().isNotEmpty) {
        mensajeError += ': ${e.toString()}';
      }
      
      throw Exception(mensajeError);
    }
  }



  // --- OBTENER CHECKLIST COMPLETO ---
  Future<List<dynamic>> getChecklist() async {
    try {
      // Primero intentamos sin autenticación (el endpoint es público)
      final response = await http.get(
        Uri.parse('$baseUrl/api/checklist'),
        headers: {'Content-Type': 'application/json'},
      );

      print('🔗 Obteniendo checklist desde: $baseUrl/api/checklist');
      print('📌 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('📊 Checklist cargado desde BD: ${data.length} categorías');
        
        // Contar total de items
        int totalItems = 0;
        for (var categoria in data) {
          if (categoria['items'] != null) {
            totalItems += (categoria['items'] as List).length;
          }
        }
        print('📋 Total de items: $totalItems');
        
        return data;
      } else {
        print('⚠️ Error ${response.statusCode}: ${response.body}');
        print('🔄 Usando datos mock como fallback...');
        return _getMockChecklist();
      }
    } catch (e) {
      print('❌ Error en getChecklist: $e');
      print('🔄 Usando datos mock como fallback...');
      return _getMockChecklist();
    }
  }

  /// Validar IDs del checklist antes de enviar al backend
  Map<String, dynamic> validarChecklistIds(Map<int, String> respuestasChecklist, List<dynamic> checklist) {
    print('🔍 Validando IDs del checklist...');
    
    // Extraer todos los IDs válidos del checklist
    Set<int> idsValidos = {};
    for (var categoria in checklist) {
      if (categoria['items'] != null) {
        for (var item in categoria['items']) {
          idsValidos.add(item['id']);
        }
      }
    }
    
    print('📋 IDs válidos encontrados: ${idsValidos.length}');
    print('🆔 Rango de IDs: ${idsValidos.isNotEmpty ? '${idsValidos.reduce((a, b) => a < b ? a : b)} - ${idsValidos.reduce((a, b) => a > b ? a : b)}' : 'N/A'}');
    
    // Validar cada respuesta del checklist
    List<int> idsInvalidos = [];
    List<int> idsValidosEncontrados = [];
    
    for (int id in respuestasChecklist.keys) {
      if (idsValidos.contains(id)) {
        idsValidosEncontrados.add(id);
      } else {
        idsInvalidos.add(id);
      }
    }
    
    // Preparar resultado de validación
    Map<String, dynamic> resultado = {
      'esValido': idsInvalidos.isEmpty,
      'idsInvalidos': idsInvalidos,
      'idsValidos': idsValidosEncontrados,
      'totalRespuestas': respuestasChecklist.length,
      'totalIdsValidos': idsValidos.length,
      'mensaje': idsInvalidos.isEmpty 
          ? '✅ Todos los IDs del checklist son válidos'
          : '❌ Se encontraron ${idsInvalidos.length} IDs inválidos: $idsInvalidos'
    };
    
    print('🔍 Resultado de validación: ${resultado['mensaje']}');
    if (idsInvalidos.isNotEmpty) {
      print('⚠️ IDs inválidos detectados: $idsInvalidos');
      print('✅ IDs válidos encontrados: $idsValidosEncontrados');
    }
    
    return resultado;
  }

  /// Datos mock temporales para el checklist PAE 2025 
  List<dynamic> _getMockChecklist() {
    print('🔄 Generando datos mock del checklist PAE 2025 completo (15 categorías, 64 items)...');
    return [
      {
        "id": 1,
        "nombre": "Diseño, construcción y disposición de residuos sólidos",
        "items": [
          {
            "id": 52,
            "pregunta_texto": "No se evidencia presencia de animales en áreas de producción, almacenamiento, distribución o consumo de alimentos."
          },
          {
            "id": 53,
            "pregunta_texto": "Los residuos sólidos están ubicados de manera que no representen riesgo de contaminación para el alimento, para los ambientes o superficies de potencial contacto con este."
          },
          {
            "id": 54,
            "pregunta_texto": "Los residuos sólidos son removidos frecuentemente de las áreas de producción y están ubicados de manera que se evite la generación de malos olores, el refugio de animales y plagas y que además no contribuya al deterioro ambiental."
          },
          {
            "id": 55,
            "pregunta_texto": "Los residuos sólidos son removidos frecuentemente de las áreas de producción y están ubicados de manera que se evite la generación de malos olores, el refugio de animales y plagas y que además no contribuya al deterioro ambiental."
          },
          {
            "id": 56,
            "pregunta_texto": "Los recipientes utilizados para almacenamiento de residuos orgánicos e inorgánicos, son a prueba de fugas, debidamente identificados, construidos de material impermeable, de fácil limpieza y desinfección y de ser requerido están provistos de tapa hermética, dichos recipientes no pueden utilizarse para contener productos comestibles."
          },
        ],
      },
      {
        "id": 2,
        "nombre": "Equipos y utensilios",
        "items": [
          {
            "id": 115,
            "pregunta_texto": "Los equipos se encuentran instalados y ubicados según la secuencia lógica del proceso tecnológico, desde la recepción de las materias primas y demás insumos, hasta el envasado y embalaje del producto terminado."
          },
          {
            "id": 116,
            "pregunta_texto": "La distancia entre los equipos y las paredes perimetrales, columnas u otros elementos de la edificación, permite el funcionamiento de los equipos y facilita el acceso para la inspección, mantenimiento, limpieza y desinfección."
          },
        ],
      },
      {
        "id": 3,
        "nombre": "Personal manipulador",
        "items": [
          {
            "id": 57,
            "pregunta_texto": "El personal manipulador cuenta con certificación médica, la cual especifique ser apto(a) para manipular alimentos."
          },
          {
            "id": 58,
            "pregunta_texto": "Se cuenta con un plan de capacitación continuo y permanente para el personal manipulador de alimentos desde el momento de su contratación y luego ser reforzado mediante charlas, cursos u otros medios efectivos de actualización. Dicho plan debe ser de por lo menos 10 horas anuales, sobre asuntos específicos relacionados al tema."
          },
          {
            "id": 59,
            "pregunta_texto": "El manipulador de alimentos se encuentra capacitado para comprender y manejar el control de los puntos del proceso que están bajo su responsabilidad y la importancia de su vigilancia o monitoreo; además, conoce los límites del punto del proceso y las acciones correctivas a tomar cuando existan desviaciones en dichos límites."
          },
        ],
      },
      {
        "id": 4,
        "nombre": "Prácticas Higiénicas y Medidas de Protección",
        "items": [
          {
            "id": 60,
            "pregunta_texto": "El personal manipulador cuenta con una estricta limpieza e higiene personal y aplica buenas prácticas higiénicas en sus labores, de manera que se evite la contaminación del alimento y de las superficies de contacto con este."
          },
          {
            "id": 61,
            "pregunta_texto": "El personal manipulador usa vestimenta de trabajo que cumpla los siguientes requisitos: De color claro que permita visualizar fácilmente su limpieza; con cierres o cremalleras y/o broches en lugar de botones u otros accesorios que puedan caer en el alimento; sin bolsillos ubicados por encima de la cintura; usa calzado cerrado, de material resistente e impermeable y de tacón bajo. Cuando se utiliza delantal, este permanece atado al cuerpo en forma segura."
          },
          {
            "id": 62,
            "pregunta_texto": "El operador hace entrega de la dotación completa al personal manipulador, conformada por (camisa, pantalón, cofia, tapaboca, delantal y calzado cerrado) en la cantidad establecida en el contrato vigente y de acuerdo con lo estipulado en el anexo técnico. En caso que por usos y costumbres el personal manipulador no utilice la dotación establecida, se cuenta con la certificación firmada por el personal manipulador."
          },
          {
            "id": 63,
            "pregunta_texto": "El operador entrega en el período los siguientes elementos de higiene para cada manipulador(a): * 1 Jabón antibacterial inoloro en cantidad mayor o igual a 300 mL/cc * 1 Rollo de papel higiénico"
          },
          {
            "id": 64,
            "pregunta_texto": "El personal manipulador se lava y desinfecta las manos con agua y jabón antibacterial, antes de comenzar su trabajo, cada vez que salga y regrese al área asignada y después de manipular cualquier material u objeto que pudiese representar un riesgo de contaminación para el alimento."
          },
          {
            "id": 65,
            "pregunta_texto": "El personal manipulador cumple: * Mantiene el cabello recogido y cubierto totalmente mediante malla, gorro u otro medio efectivo y en caso de llevar barba, bigote o patillas usa cubiertas para estas. *No usa maquillaje.* utiliza tapabocas cubriendo nariz y boca mientras se manipula el alimento. *Mantiene las uñas cortas, limpias y sin esmalte. * No utiliza reloj, anillos, aretes, joyas u otros accesorios mientras realice sus labores. En caso de usar lentes, deben asegurarse a la cabeza mediante bandas, cadenas u otros medios ajustables."
          },
          {
            "id": 66,
            "pregunta_texto": "De ser necesario el uso de guantes, estos se mantienen limpios, sin roturas o desperfectos y son tratados con el mismo cuidado higiénico de las manos sin protección. El material de los guantes, es apropiado para la operación realizada y evitan la acumulación de humedad y contaminación en su interior para prevenir posibles afecciones cutáneas de los operarios. El uso de guantes no exime al operario de la obligación de lavarse las manos."
          },
          {
            "id": 67,
            "pregunta_texto": "El personal manipulador no realiza actividades como: Beber o masticar cualquier objeto o producto, fumar o escupir en las áreas de producción o en cualquier otra zona donde exista riesgo de contaminación del alimento."
          },
          {
            "id": 68,
            "pregunta_texto": "El personal manipulador no presenta afecciones de la piel o enfermedad infectocontagiosa."
          },
          {
            "id": 69,
            "pregunta_texto": "Los visitantes de los establecimientos cumplen estrictamente todas las prácticas de higiene y portan la vestimenta y/o dotación adecuada."
          },
        ],
      },
      {
        "id": 5,
        "nombre": "Materias primas e insumos",
        "items": [
          {
            "id": 70,
            "pregunta_texto": "La recepción de materias primas se realiza en condiciones que eviten su contaminación, alteración y daños físicos y están debidamente identificadas de conformidad con la Resolución 5109 de 2005 o las normas que la modifiquen, adicionen o sustituyan, y para el caso de los insumos, deben cumplir con las resoluciones 1506 de 2011 y/o la 683 de 2012, según corresponda, o las normas que las modifiquen, adicionen o sustituyan."
          },
          {
            "id": 71,
            "pregunta_texto": "Las materias primas son sometidas a limpieza con agua potable u otro medio adecuado de ser requerido, se aplica la descontaminación previa a su incorporación en las etapas sucesivas del proceso."
          },
          {
            "id": 72,
            "pregunta_texto": "Las materias primas conservadas por congelación que requieren ser descongeladas previo al uso, se descogelan a una velocidad controlada para evitar el desarrollo de microorganismos y no son recongeladas. Además, se manipulan de manera que se minimiza la contaminación proveniente de otras fuentes."
          },
          {
            "id": 73,
            "pregunta_texto": "Las materias primas e insumos se almacenan en sitios exclusivos y adecuados que evitan su contaminación y alteración."
          },
          {
            "id": 74,
            "pregunta_texto": "Los alimentos que por su naturaleza permiten un rápido crecimiento de microorganismos indeseables, se mantienen en condiciones que eviten su proliferación. - Alimentos a temperaturas de refrigeración no mayores a 4°C/2ºC. - Alimento en estado congelado (-18 °C). - Alimento caliente a temperaturas mayores de 60°C (140°F)."
          },
        ],
      },
      {
        "id": 6,
        "nombre": "Operaciones de fabricación",
        "items": [
          {
            "id": 75,
            "pregunta_texto": "Las operaciones de fabricación se realizan en forma secuencial y continua para que no se produzcan retrasos indebidos que permitan el crecimiento de microorganismos, contribuyan a otros tipos de deterioro o contaminación del alimento. Cuando se requiera esperar entre una etapa del proceso y la siguiente, el alimento se mantiene protegido y en el caso de alimentos susceptibles al rápido crecimiento de microorganismos durante el tiempo de espera, se emplean temperaturas altas (> 60°C) o bajas no mayores de 4°C +/-2ºC según sea el caso."
          },
          {
            "id": 76,
            "pregunta_texto": "Los procedimientos de manufactura, tales como, lavar, pelar, cortar, clasificar, desmenuzar, extraer, batir, secar, entre otros, se realizan de manera que se protegen los alimentos y las materias primas de la contaminación."
          },
        ],
      },
      {
        "id": 7,
        "nombre": "Prevención de la contaminación cruzada",
        "items": [
          {
            "id": 77,
            "pregunta_texto": "Durante las operaciones de fabricación, almacenamiento y distribución se toman medidas eficaces para evitar la contaminación de los alimentos por contacto directo o indirecto con materias primas que se encuentren en las fases iniciales del proceso."
          },
          {
            "id": 78,
            "pregunta_texto": "Las operaciones de fabricación se realizan en forma secuencial y continua para evitar el cruce de flujos de producción."
          },
          {
            "id": 79,
            "pregunta_texto": "Todo equipo y utensilio que entra en contacto con materias primas o con material contaminado se limpia y se desinfecta cuidadosamente antes de ser utilizado nuevamente."
          },
        ],
      },
      {
        "id": 8,
        "nombre": "Aseguramiento y control de la calidad e inocuidad",
        "items": [
          {
            "id": 80,
            "pregunta_texto": "En la recepción de materias primas e insumos, se aplican los criterios de aceptación, liberación, retención o rechazo."
          },
        ],
      },
      {
        "id": 9,
        "nombre": "Saneamiento",
        "items": [
          {
            "id": 81,
            "pregunta_texto": "En la carpeta PAE se encuentra el Plan de Saneamiento establecido por la entidad territorial para la vigencia (programa de limpieza y desinfección, manejo de residuos, abastecimiento o suministro de agua y control integrado de plagas) con procedimientos escritos y registros de las actividades."
          },
          {
            "id": 82,
            "pregunta_texto": "El operador entrega los implementos de aseo mínimos según lo establecido anexos técnicos (mayoritaria /indígena) y se realiza su reposición en caso de que aplique."
          },
          {
            "id": 83,
            "pregunta_texto": "El operador entrega los insumos de aseo mensual para el comedor escolar, según lo establecido en anexos técnicos (mayoritaria /indígena) y se realiza su reposición en caso que aplique."
          },
        ],
      },
      {
        "id": 10,
        "nombre": "Almacenamiento",
        "items": [
          {
            "id": 84,
            "pregunta_texto": "Se lleva control de primeras entradas y primeras salidas a diario, con el fin de garantizar la rotación de los productos (formato kardex)."
          },
          {
            "id": 85,
            "pregunta_texto": "El almacenamiento de materia prima e insumos, se realiza ordenadamente en pilas o estibas con separación mínima de 60 centímetros con respecto a las paredes perimetrales, y dispone de estibas o tarimas limpias y en buen estado, elevadas del piso por lo menos 15 centímetros de manera que permita la inspección, limpieza y fumigación, si es el caso."
          },
          {
            "id": 86,
            "pregunta_texto": "En el lugar o espacio destinado al almacenamiento de materia prima e insumos, no se realizan actividades diferentes."
          },
          {
            "id": 87,
            "pregunta_texto": "Los plaguicidas, detergentes, desinfectantes y otras sustancias peligrosas, se encuentran debidamente rotuladas, incluida información sobre su modo de empleo y toxicidad, estos productos se almacenan en áreas independientes con separación física y su manipulación solo es realizada por personal idóneo. Estas áreas están debidamente identificadas, organizadas, señalizadas y aireadas."
          },
        ],
      },
      {
        "id": 11,
        "nombre": "Transporte",
        "items": [
          {
            "id": 88,
            "pregunta_texto": "El transporte de materias primas, insumos y producto terminado (CCT) se realiza en condiciones que impiden la contaminación, la proliferación de microorganismos y eviten su alteración, incluidos los daños en el envase o embalaje según sea el caso."
          },
          {
            "id": 89,
            "pregunta_texto": "Las materias primas que por su naturaleza requieran mantenerse refrigeradas o congeladas, son transportadas y distribuidas en condiciones que aseguran y garantizan su calidad e inocuidad hasta su destino final. Este procedimiento es susceptible de verificación mediante planillas de registro de temperatura del vehículo, durante el transporte, cargue o descargue del alimento."
          },
          {
            "id": 90,
            "pregunta_texto": "Los vehículos de transporte de alimentos, están diseñados en material sanitario en su interior y aquellos que poseen sistema de refrigeración o congelación, cuentan con indicador de temperatura y su funcionamiento garantiza la conservación de los alimentos."
          },
          {
            "id": 91,
            "pregunta_texto": "Los contenedores o recipientes en los que se transportan los alimentos o materias primas, están fabricados en materiales sanitarios que facilitan su correcta limpieza y desinfección."
          },
          {
            "id": 92,
            "pregunta_texto": "Se dispone de recipientes, canastillas o elementos, de material sanitario, que aíslan el producto de toda posibilidad de contaminación que pueda presentarse por contacto directo del alimento con el piso del vehículo."
          },
          {
            "id": 93,
            "pregunta_texto": "No se transporta conjuntamente en un mismo vehículo alimentos o materias primas con sustancias peligrosas u otras sustancias que por su naturaleza representen riesgo de contaminación para el alimento o la materia prima."
          },
          {
            "id": 94,
            "pregunta_texto": "Los vehículos en los que se transportan los alimentos o materias primas, llevan en su exterior de forma claramente visible la leyenda: Transporte de Alimentos."
          },
          {
            "id": 95,
            "pregunta_texto": "Los vehículos destinados al transporte de alimentos y materias primas, cumplen dentro del territorio colombiano con los requisitos sanitarios que garantizan la adecuada protección y conservación de los mismos."
          },
        ],
      },
      {
        "id": 12,
        "nombre": "Distribución y consumo",
        "items": [
          {
            "id": 99,
            "pregunta_texto": "Se suministra el complemento en el horario establecido. En caso que se presente modificación en el horario de servido, se encuentra definido de manera escrita mediante acta de reunión del CAE."
          },
          {
            "id": 100,
            "pregunta_texto": "El operador hace entrega de las materias primas e insumos, dentro del horario de la jornada escolar o por fuera del horario establecido, siempre y cuando no ponga en riesgo la calidad e inocuidad de las materias primas e insumos, ni la entrega oportuna del complemento alimentario."
          },
          {
            "id": 101,
            "pregunta_texto": "Se promueven los buenos hábitos con los estudiantes como lo es el lavado de manos con jabón desinfectante antes del consumo de los alimentos."
          },
          {
            "id": 112,
            "pregunta_texto": "Se suministra el complemento en el horario establecido. En caso que se presente modificación en el horario de servido, se encuentra definido de manera escrita mediante acta de reunión del CAE."
          },
          {
            "id": 113,
            "pregunta_texto": "El operador hace entrega de las materias primas e insumos, dentro del horario de la jornada escolar o por fuera del horario establecido, siempre y cuando no ponga en riesgo la calidad e inocuidad de las materias primas e insumos, ni la entrega oportuna del complemento alimentario."
          },
          {
            "id": 114,
            "pregunta_texto": "Se promueven los buenos hábitos con los estudiantes como lo es el lavado de manos con jabón desinfectante antes del consumo de los alimentos."
          },
        ],
      },
      {
        "id": 13,
        "nombre": "Documentación PAE",
        "items": [
          {
            "id": 102,
            "pregunta_texto": "Existen avisos de señalización de áreas ubicados en sitios estratégicos y en buen estado (verificar que sea del contrato vigente). Los avisos son: Área de recibo de alimentos - Área de almacenamiento - Área de preparación - Área de distribución - Comedor - Área de lavado - Avisos referentes a la necesidad de lavarse las manos luego de usar los servicios sanitarios."
          },
          {
            "id": 103,
            "pregunta_texto": "El operador entrega remisión de materias primas e insumos (la cual debe contener como mínimo: Nombre de la sede educativa, número de cupos adjudicados y atendidos, la modalidad de atención, los días de atención para los cuales se están entregando los víveres, tipo de alimentos, unidad de medida, cantidad de entrega y espacio de observaciones), firmada por el personal manipulador de alimentos que recibe y existe copia de este documento en el comedor escolar."
          },
          {
            "id": 104,
            "pregunta_texto": "DEVOLUCIONES O FALTANTES: Se hace reposición de materias primas o insumos faltantes, antes de la preparación o entrega del alimento, de acuerdo con lo planeado en el ciclo de menú y el horario de servido estipulado, haciendo uso del formato establecido por la ETC, denominado \"Reposición y faltantes de alimentos\", debidamente diligenciado y firmado por el personal manipulador de alimentos y un representante de la unidad de servicio, que certifique la entrega."
          },
          {
            "id": 105,
            "pregunta_texto": "En la carpeta PAE se encuentra el formato CARACTERÍSTICAS DE CALIDAD, COMPRA DE ALIMENTOS Y ELEMENTOS DE ASEO, donde se relacionan los alimentos e insumos entregados por el operador, debidamente diligenciado y legible."
          },
          {
            "id": 106,
            "pregunta_texto": "En la carpeta PAE se encuentra el documento de inventario de equipo y menaje debidamente diligenciado y firmado."
          },
          {
            "id": 107,
            "pregunta_texto": "El comedor escolar tiene publicado en un lugar visible la FICHA TÉCNICA de información del PAE, completamente diligenciada, incluidos los mecanismos que el operador y la ETC, tienen para atender las SPQR en el comedor escolar, de acuerdo con lo establecido por el MEN."
          },
          {
            "id": 108,
            "pregunta_texto": "Se cuenta con la carpeta del Programa de Alimentación Escolar, organizada y debidamente identificada, con soportes de los programas implementados, información del personal manipulador (hoja de vida, certificado de BPM), gestiones realizadas y registros de la ejecución del programa en el comedor escolar."
          },
          {
            "id": 109,
            "pregunta_texto": "En el comedor escolar está conformado el comité de alimentación escolar (CAE), y en la carpeta PAE reposa copia del acta de constitución CAE. Cuentan con actas de reunión del comité que evidencien su implementación."
          },
        ],
      },
      {
        "id": 14,
        "nombre": "Cobertura",
        "items": [
          {
            "id": 110,
            "pregunta_texto": "Se diligencia diariamente, sin interrupciones el formato registro y control de asistencia de titulares de derecho, beneficiarios del programa, sin tachones o enmendaduras."
          },
          {
            "id": 111,
            "pregunta_texto": "Verificación de titulares atendidos en el comedor Escolar donde la respuesta sea seleccionable, donde 1 cumple prácticamente 2 cumple 0 no cumple N/A no aplica y N/O no observado"
          },
        ],
      },
    ];
  }

  // --- OBTENER ÍTEMS PAE 2025 ---
  Future<List<ItemPAE>> getItemsPAE() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/items-pae'),
        headers: headers,
      );

      print('🔗 Obteniendo ítems PAE desde: $baseUrl/api/items-pae');
      print('📌 Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ItemPAE.fromJson(json)).toList();
      } else {
        // Si el endpoint no existe, usamos datos mock temporales
        print('⚠️ Endpoint /api/items-pae no disponible. Usando datos mock...');
        return _getMockItemsPAE();
      }
    } catch (e) {
      print('❌ Error en getItemsPAE: $e');
      print('🔄 Usando datos mock como fallback...');
      return _getMockItemsPAE();
    }
  }

  /// Datos mock temporales para los ítems PAE 2025
  List<ItemPAE> _getMockItemsPAE() {
    print('🔄 Generando datos mock de ítems PAE 2025...');
    return [
      ItemPAE(
        id: 1,
        nombre: "Número de manipuladoras de alimentos",
        categoria: "Personal y Recursos Humanos",
        items: [
          SubItemPAE(id: 1, preguntaTexto: "¿La cantidad de manipuladoras corresponde al número de cupos asignados?"),
          SubItemPAE(id: 2, preguntaTexto: "¿Existe documentación de justificación si no se cumple con el personal requerido?"),
        ],
      ),
      ItemPAE(
        id: 2,
        nombre: "Diseño, construcción y disposición de residuos sólidos",
        categoria: "Infraestructura y Equipamiento",
        items: [
          SubItemPAE(id: 3, preguntaTexto: "¿No se evidencia presencia de animales en áreas de producción?"),
          SubItemPAE(id: 4, preguntaTexto: "¿Los residuos sólidos están ubicados sin riesgo de contaminación?"),
        ],
      ),
      ItemPAE(
        id: 3,
        nombre: "Equipos y utensilios",
        categoria: "Infraestructura y Equipamiento",
        items: [
          SubItemPAE(id: 5, preguntaTexto: "¿Los equipos están instalados según la secuencia lógica del proceso?"),
          SubItemPAE(id: 6, preguntaTexto: "¿La distancia entre equipos permite funcionamiento y mantenimiento?"),
        ],
      ),
      ItemPAE(
        id: 4,
        nombre: "Personal manipulador",
        categoria: "Personal y Recursos Humanos",
        items: [
          SubItemPAE(id: 7, preguntaTexto: "¿El personal cuenta con certificación médica vigente?"),
          SubItemPAE(id: 8, preguntaTexto: "¿Existe plan de capacitación continua para el personal?"),
        ],
      ),
      ItemPAE(
        id: 5,
        nombre: "Prácticas higiénicas y medidas de protección",
        categoria: "Personal y Recursos Humanos",
        items: [
          SubItemPAE(id: 9, preguntaTexto: "¿El personal mantiene higiene personal estricta?"),
          SubItemPAE(id: 10, preguntaTexto: "¿Se usa vestimenta de trabajo adecuada?"),
        ],
      ),
    ];
  }

  // --- GUARDAR VISITA CON CHECKLIST ---
  Future<bool> guardarVisitaConChecklist({
    required DateTime fechaVisita,
    required String contrato,
    required String operador,
    required int municipioId,
    required int institucionId,
    required int sedeId,
    required int profesionalId,
    required List<VisitaRespuesta> respuestas,
  }) async {
    try {
      final headers = await _getHeaders();
      final data = {
        'fecha_visita': fechaVisita.toIso8601String(),
        'contrato': contrato,
        'operador': operador,
        'municipio_id': municipioId,
        'institucion_id': institucionId,
        'sede_id': sedeId,
        'profesional_id': profesionalId,
        'respuestas': respuestas.map((r) => r.toJson()).toList(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/visitas'),
        headers: headers,
        body: jsonEncode(data),
      );

      print('🔗 Guardando visita con checklist en: $baseUrl/api/visitas');
      print('📌 Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Visita con checklist guardada exitosamente');
        return true;
      } else {
        print('❌ Error al guardar visita con checklist: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error en guardarVisitaConChecklist: $e');
      return false;
    }
  }

  // --- GUARDAR VISITA CON EVALUACIONES PAE ---
  Future<bool> guardarVisitaConEvaluacionesPAE({
    required DateTime fechaVisita,
    required String contrato,
    required String operador,
    required int municipioId,
    required int institucionId,
    required int sedeId,
    required int profesionalId,
    required List<EvaluacionItem> evaluaciones,
  }) async {
    try {
      final token = await getToken();
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        "fecha_visita": fechaVisita.toIso8601String(),
        "contrato": contrato,
        "operador": operador,
        "municipio_id": municipioId,
        "institucion_id": institucionId,
        "sede_id": sedeId,
        "profesional_id": profesionalId,
        "evaluaciones": evaluaciones.map((e) => e.toJson()).toList(),
      });

      final url = '$baseUrl/api/visitas-pae';
      print('🔗 Enviando visita PAE a: $url');
      print('🔑 Headers: $headers');
      print('📦 Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print('📌 Respuesta del servidor - Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      return response.statusCode == 201;
    } catch (e) {
      print('❌ Error en guardarVisitaConEvaluacionesPAE: $e');
      throw Exception('Error al guardar visita PAE: $e');
    }
  }

  // --- GUARDAR VISITA CON EVALUACIONES PAE Y EVIDENCIAS ---
  Future<bool> guardarVisitaConEvaluacionesPAEYEvidencias({
    required DateTime fechaVisita,
    required String contrato,
    required String operador,
    required int municipioId,
    required int institucionId,
    required int sedeId,
    required int profesionalId,
    required List<EvaluacionItem> evaluaciones,
    required Map<String, List<Evidencia>> evidencias,
  }) async {
    try {
      final token = await getToken();
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      // Preparar evidencias para envío
      final evidenciasParaEnviar = <String, List<Map<String, dynamic>>>{};
      evidencias.forEach((itemId, listaEvidencias) {
        evidenciasParaEnviar[itemId] = listaEvidencias.map((e) => e.toJson()).toList();
      });

      final body = jsonEncode({
        "fecha_visita": fechaVisita.toIso8601String(),
        "contrato": contrato,
        "operador": operador,
        "municipio_id": municipioId,
        "institucion_id": institucionId,
        "sede_id": sedeId,
        "profesional_id": profesionalId,
        "evaluaciones": evaluaciones.map((e) => e.toJson()).toList(),
        "evidencias": evidenciasParaEnviar,
      });

      final url = '$baseUrl/api/visitas-pae-con-evidencia';
      print('🔗 Enviando visita PAE con evidencias a: $url');
      print('🔑 Headers: $headers');
      print('📦 Body: $body');
      print('📸 Evidencias incluidas: ${evidenciasParaEnviar.keys.length} items con evidencias');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print('📌 Respuesta del servidor - Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      return response.statusCode == 201;
    } catch (e) {
      print('❌ Error en guardarVisitaConEvaluacionesPAEYEvidencias: $e');
      throw Exception('Error al guardar visita PAE con evidencias: $e');
    }
  }

  // --- OBTENER EVALUACIONES DE UNA VISITA ---
  Future<List<EvaluacionItem>> getEvaluacionesVisita(int visitaId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/visitas/$visitaId/evaluaciones'),
        headers: headers,
      );

      print('🔗 Obteniendo evaluaciones de visita $visitaId');
      print('📌 Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => EvaluacionItem.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener evaluaciones de la visita');
      }
    } catch (e) {
      print('❌ Error en getEvaluacionesVisita: $e');
      throw Exception('Error al obtener evaluaciones de la visita: $e');
    }
  }

  // --- DASHBOARD DEL VISITADOR ---
  Future<Map<String, dynamic>> getEstadisticasVisitador() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/dashboard/estadisticas'),
        headers: headers,
      );

      print('🔗 Obteniendo estadísticas desde: $baseUrl/api/dashboard/estadisticas');
      print('📌 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Estadísticas obtenidas: $data');
        return data;
      } else {
        print('❌ Error al cargar estadísticas: ${response.statusCode} - ${response.body}');
        throw Exception('Error al cargar estadísticas. Código: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en getEstadisticasVisitador: $e');
      throw Exception('Error al cargar estadísticas: $e');
    }
  }

  // --- DASHBOARD DEL SUPERVISOR ---
  // Método eliminado - duplicado con el de la sección supervisor

  // --- TODAS LAS VISITAS (SUPERVISOR) ---
  Future<List<Visita>> getTodasVisitas() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/visitas/todas'),
        headers: headers,
      );

      print('🔗 Obteniendo todas las visitas desde: $baseUrl/api/visitas/todas');
      print('📌 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Visita.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar todas las visitas. Código: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en getTodasVisitas: $e');
      throw Exception('Error al cargar todas las visitas: $e');
    }
  }

  // --- GENERAR REPORTES ---
  Future<String?> generarReporte(Map<String, dynamic> parametros) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/reportes/generar'),
        headers: headers,
        body: jsonEncode(parametros),
      );

      print('🔗 Generando reporte en: $baseUrl/api/reportes/generar');
      print('📌 Status: ${response.statusCode}');
      print('📋 Content-Type: ${response.headers['content-type']}');
      print('📊 Body length: ${response.bodyBytes.length} bytes');
      print('📄 Primeros 200 caracteres del body: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');

      if (response.statusCode == 200) {
        // Si la respuesta contiene bytes del archivo (Excel/CSV), descargar directamente
        final contentType = response.headers['content-type'] ?? '';
        
        if (contentType.contains('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') ||
            contentType.contains('text/csv') ||
            response.bodyBytes.isNotEmpty && response.bodyBytes.length > 1000) {
          
          print('📥 Respuesta contiene archivo, iniciando descarga...');
          
          // Determinar el formato basado en los parámetros o content-type
          final tipoReporte = parametros['tipo_reporte']?.toString().toLowerCase() ?? 'excel';
          final extension = tipoReporte == 'csv' ? 'csv' : 'xlsx';
          final mimeType = tipoReporte == 'csv' 
              ? 'text/csv' 
              : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final filename = 'reporte_$timestamp.$extension';
          
        if (kIsWeb) {
          await _descargarArchivoWeb(response.bodyBytes, filename, mimeType);
          return 'Archivo descargado en el navegador';
        } else {
          // Para móvil, verificar permisos y guardar en el directorio de descargas
          final hasPermissions = await PermissionService.requestStoragePermissions();
          if (!hasPermissions) {
            throw Exception('Se requieren permisos de almacenamiento para descargar el archivo. Por favor, habilita los permisos en la configuración de la aplicación.');
          }
          
          final downloadsDir = await _obtenerDirectorioDescargas();
          final file = File('${downloadsDir.path}/$filename');
          await file.writeAsBytes(response.bodyBytes);
          print('✅ Reporte guardado en: ${file.path}');
          
          return file.path;
        }
        } else {
          print('✅ Reporte generado exitosamente (sin descarga directa)');
          return null;
        }
      } else {
        throw Exception('Error al generar reporte. Código: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en generarReporte: $e');
      throw Exception('Error al generar reporte: $e');
    }
  }

  // --- CRONOGRAMAS (SUPERVISOR) ---
  Future<List<Map<String, dynamic>>> getCronogramas() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/cronogramas'),
        headers: headers,
      );

      print('🔗 Obteniendo cronogramas desde: $baseUrl/api/cronogramas');
      print('📌 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        // Mock data para desarrollo
        return [
          {
            'id': 1,
            'operador': 'Operador A',
            'contrato': 'CON-2024-001',
            'fecha_inicio': '2024-01-01T00:00:00Z',
            'fecha_fin': '2024-12-31T00:00:00Z',
            'estado': 'activo',
            'visitas_programadas': 50,
            'visitas_completadas': 35,
          },
          {
            'id': 2,
            'operador': 'Operador B',
            'contrato': 'CON-2024-002',
            'fecha_inicio': '2024-02-01T00:00:00Z',
            'fecha_fin': '2024-11-30T00:00:00Z',
            'estado': 'pendiente',
            'visitas_programadas': 30,
            'visitas_completadas': 0,
          },
        ];
      }
    } catch (e) {
      print('❌ Error en getCronogramas: $e');
      // Mock data para desarrollo
      return [
        {
          'id': 1,
          'operador': 'Operador A',
          'contrato': 'CON-2024-001',
          'fecha_inicio': '2024-01-01T00:00:00Z',
          'fecha_fin': '2024-12-31T00:00:00Z',
          'estado': 'activo',
          'visitas_programadas': 50,
          'visitas_completadas': 35,
        },
        {
          'id': 2,
          'operador': 'Operador B',
          'contrato': 'CON-2024-002',
          'fecha_inicio': '2024-02-01T00:00:00Z',
          'fecha_fin': '2024-11-30T00:00:00Z',
          'estado': 'pendiente',
          'visitas_programadas': 30,
          'visitas_completadas': 0,
        },
      ];
    }
  }

  // --- ACTIVIDAD RECIENTE (SUPERVISOR) ---
  Future<List<Visita>> getUltimasVisitas() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/visitas/ultimas'),
        headers: headers,
      );

      print('🔗 Obteniendo últimas visitas desde: $baseUrl/api/visitas/ultimas');
      print('📌 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Visita.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar últimas visitas. Código: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en getUltimasVisitas: $e');
      throw Exception('Error al cargar últimas visitas: $e');
    }
  }

  Future<List<Visita>> getVisitasSinEvidencia() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/visitas/sin-evidencia'),
        headers: headers,
      );

      print('🔗 Obteniendo visitas sin evidencia desde: $baseUrl/api/visitas/sin-evidencia');
      print('📌 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Visita.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar visitas sin evidencia. Código: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en getVisitasSinEvidencia: $e');
      throw Exception('Error al cargar visitas sin evidencia: $e');
    }
  }

  Future<Map<String, dynamic>> getEstadisticasActividad() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/dashboard/actividad'),
        headers: headers,
      );

      print('🔗 Obteniendo estadísticas de actividad desde: $baseUrl/api/dashboard/actividad');
      print('📌 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // El endpoint devuelve {ultimas_visitas: [...], estadisticas: {...}}
        return data;
      } else {
        // Mock data para desarrollo
        return {
          'ultimas_visitas': [],
          'estadisticas': {
            'total_visitas': 150,
            'visitas_hoy': 5,
            'usuarios_activos': 10,
          }
        };
      }
    } catch (e) {
      print('❌ Error en getEstadisticasActividad: $e');
      // Mock data para desarrollo
      return {
        'ultimas_visitas': [],
        'estadisticas': {
          'total_visitas': 150,
          'visitas_hoy': 5,
          'usuarios_activos': 10,
        }
      };
    }
  }

  // --- GESTIÓN DE USUARIOS (SUPERVISOR) ---
  Future<List<Usuario>> getTodosUsuarios() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/usuarios'),
        headers: headers,
      );

      print('🔗 Obteniendo todos los usuarios desde: $baseUrl/api/admin/usuarios');
      print('📌 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('📄 Response body: ${response.body}');
        print('📊 Datos JSON recibidos: $data');
        
        final usuarios = data.map((json) => Usuario.fromJson(json)).toList();
        print('👥 Usuarios parseados: ${usuarios.map((u) => '${u.nombre} (${u.rol})').toList()}');
        
        return usuarios;
      } else {
        throw Exception('Error al cargar usuarios. Código: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en getTodosUsuarios: $e');
      throw Exception('Error al cargar usuarios: $e');
    }
  }

  // --- NOTIFICACIONES SUPERVISOR ---
  Future<List<Map<String, dynamic>>> getAlertasSistema() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/alertas/sistema'),
        headers: headers,
      );

      print('🔗 Obteniendo alertas del sistema desde: $baseUrl/api/alertas/sistema');
      print('📌 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        // Mock data para desarrollo
        return [
          {
            'titulo': 'Sistema funcionando correctamente',
            'mensaje': 'Todos los servicios están operativos',
            'prioridad': 'baja',
            'fecha': DateTime.now().toIso8601String(),
          },
        ];
      }
    } catch (e) {
      print('❌ Error en getAlertasSistema: $e');
      // Mock data para desarrollo
      return [
        {
          'titulo': 'Sistema funcionando correctamente',
          'mensaje': 'Todos los servicios están operativos',
          'prioridad': 'baja',
          'fecha': DateTime.now().toIso8601String(),
        },
      ];
    }
  }

  Future<List<Map<String, dynamic>>> getInconsistenciasDatos() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/alertas/inconsistencias'),
        headers: headers,
      );

      print('🔗 Obteniendo inconsistencias desde: $baseUrl/api/alertas/inconsistencias');
      print('📌 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        // Mock data para desarrollo
        return [
          {
            'titulo': 'Visita sin evidencia fotográfica',
            'mensaje': 'La visita #123 no tiene fotos adjuntas',
            'prioridad': 'alta',
            'fecha': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          },
        ];
      }
    } catch (e) {
      print('❌ Error en getInconsistenciasDatos: $e');
      // Mock data para desarrollo
      return [
        {
          'titulo': 'Visita sin evidencia fotográfica',
          'mensaje': 'La visita #123 no tiene fotos adjuntas',
          'prioridad': 'alta',
          'fecha': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        },
      ];
    }
  }

  Future<List<Map<String, dynamic>>> getVencimientosCronogramas() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/alertas/vencimientos'),
        headers: headers,
      );

      print('🔗 Obteniendo vencimientos desde: $baseUrl/api/alertas/vencimientos');
      print('📌 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        // Mock data para desarrollo
        return [
          {
            'titulo': 'Cronograma próximo a vencer',
            'mensaje': 'El cronograma #2 vence en 5 días',
            'prioridad': 'media',
            'fecha': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          },
        ];
      }
    } catch (e) {
      print('❌ Error en getVencimientosCronogramas: $e');
      // Mock data para desarrollo
      return [
        {
          'titulo': 'Cronograma próximo a vencer',
          'mensaje': 'El cronograma #2 vence en 5 días',
          'prioridad': 'media',
          'fecha': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        },
      ];
    }
  }



  // --- VISITAS COMPLETAS PAE ---
  Future<List<Visita>> getVisitasCompletas({
    String? contrato,
    String? operador,
    int? municipioId,
    int? institucionId,
    String? estado,
    String? fechaInicio,
    String? fechaFin,
    bool soloDelUsuario = false, // Nuevo parámetro para filtrar por usuario
  }) async {
    try {
      final headers = await _getHeaders();
      
      // Construir query parameters
      final queryParams = <String, String>{};
      if (contrato != null && contrato.isNotEmpty) queryParams['contrato'] = contrato;
      if (operador != null && operador.isNotEmpty) queryParams['operador'] = operador;
      if (municipioId != null) queryParams['municipio_id'] = municipioId.toString();
      if (institucionId != null) queryParams['institucion_id'] = institucionId.toString();
      if (estado != null && estado.isNotEmpty) queryParams['estado'] = estado;
      if (fechaInicio != null && fechaInicio.isNotEmpty) queryParams['fecha_inicio'] = fechaInicio;
      if (fechaFin != null && fechaFin.isNotEmpty) queryParams['fecha_fin'] = fechaFin;
      
      // Si se solicita solo del usuario, agregar el filtro
      if (soloDelUsuario) {
        final usuarioId = await getUsuarioId();
        if (usuarioId != null) {
          queryParams['usuario_id'] = usuarioId.toString();
        }
      }
      
      final uri = Uri.parse('$baseUrl/api/visitas-completas-pae').replace(
        queryParameters: queryParams,
      );
      
      final response = await http.get(uri, headers: headers);

      print('🔗 Obteniendo visitas completas desde: $uri');
      print('📌 Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Visita.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar visitas completas. Código: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en getVisitasCompletas: $e');
      throw Exception('Error al cargar visitas completas: $e');
    }
  }

  // --- OPCIONES DE FILTROS PARA VISITAS COMPLETAS ---
  Future<Map<String, List<String>>> getOpcionesFiltrosVisitas() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/visitas-completas-pae/filtros'),
        headers: headers,
      );

      print('🔗 Obteniendo opciones de filtros desde: $baseUrl/api/visitas-completas-pae/filtros');
      print('📌 Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'contratos': List<String>.from(data['contratos'] ?? []),
          'operadores': List<String>.from(data['operadores'] ?? []),
          'estados': List<String>.from(data['estados'] ?? []),
        };
      } else {
        throw Exception('Error al cargar opciones de filtros. Código: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en getOpcionesFiltrosVisitas: $e');
      throw Exception('Error al cargar opciones de filtros: $e');
    }
  }

  // --- VISITAS PENDIENTES PAE ---
  Future<List<Visita>> getVisitasPendientes() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/visitas-completas-pae/pendientes'),
        headers: headers,
      );

      print('🔗 Obteniendo visitas pendientes desde: $baseUrl/api/visitas-completas-pae/pendientes');
      print('📌 Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Visita.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar visitas pendientes. Código: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en getVisitasPendientes: $e');
      throw Exception('Error al cargar visitas pendientes: $e');
    }
  }

  // --- ACTUALIZAR ESTADO DE VISITA ---
  Future<bool> actualizarEstadoVisita(int visitaId, String estado) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/visitas-completas-pae/$visitaId/estado?estado=$estado'),
        headers: headers,
      );

      print('🔗 Actualizando estado de visita $visitaId a $estado');
      print('📌 Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error en actualizarEstadoVisita: $e');
      throw Exception('Error al actualizar estado de visita: $e');
    }
  }

  // --- DESCARGAR EXCEL DE VISITA COMPLETA ---
  Future<String?> descargarExcelVisita(int visitaId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/visitas-completas-pae/$visitaId/excel'),
        headers: headers,
      );

      print('🔗 Descargando Excel para visita $visitaId desde: $baseUrl/api/visitas-completas-pae/$visitaId/excel');
      print('📌 Status: ${response.statusCode}');
      print('📌 Content-Type: ${response.headers['content-type']}');
      print('📌 Content-Length: ${response.bodyBytes.length} bytes');

      if (response.statusCode == 200) {
        // Crear el archivo Excel en el directorio de descargas
        final bytes = response.bodyBytes;
        final filename = 'visita_${visitaId}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        
        // En Flutter móvil, guardamos el archivo en el directorio de descargas
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          // Verificar y solicitar permisos de almacenamiento
          final hasPermissions = await PermissionService.requestStoragePermissions();
          if (!hasPermissions) {
            throw Exception('Se requieren permisos de almacenamiento para descargar el archivo. Por favor, habilita los permisos en la configuración de la aplicación.');
          }
          
          // Obtener directorio de descargas usando el método mejorado
          final downloadsDir = await _obtenerDirectorioDescargas();
          final file = File('${downloadsDir.path}/$filename');
          await file.writeAsBytes(bytes);
          print('✅ Excel guardado en: ${file.path}');
          return file.path;
        } else if (kIsWeb) {
          // Para Flutter web, usar un enfoque directo
          print('🌐 Descargando Excel en Flutter web...');
          
          try {
            await _descargarExcelWeb(bytes, filename);
            print('✅ Excel descargado en Flutter web: $filename');
            return filename;
          } catch (e) {
            print('❌ Error al descargar Excel en web: $e');
            throw Exception('Error al descargar Excel en web: $e');
          }
        } else {
          // Para otras plataformas
          print('⚠️ Descarga de Excel no implementada para esta plataforma');
          return null;
        }
      } else {
        throw Exception('Error al descargar Excel. Código: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en descargarExcelVisita: $e');
      throw Exception('Error al descargar Excel: $e');
    }
  }

  // --- RECUPERACIÓN DE CONTRASEÑA ---
  
  // Enviar código de recuperación por email
  Future<void> enviarCodigoRecuperacion(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/olvidaste-contrasena'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'correo': email}),
      );

      print('🔗 Enviando código de recuperación a: $email');
      print('📌 Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Código de recuperación enviado exitosamente');
        return;
      } else {
        throw Exception('Error al enviar código de recuperación: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Verificar código de recuperación
  Future<void> verificarCodigoRecuperacion(String email, String codigo) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/verificar-codigo'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'correo': email,
          'codigo': codigo,
        }),
      );

      print('🔗 Verificando código de recuperación para: $email');
      print('📌 Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Código de recuperación verificado exitosamente');
        return;
      } else {
        throw Exception('Error al verificar código: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Cambiar contraseña con código de verificación
  Future<void> cambiarContrasenaConCodigo(String email, String codigo, String nuevaContrasena) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/cambiar-contrasena'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'correo': email,
          'codigo': codigo,
          'nueva_contrasena': nuevaContrasena,
        }),
      );

      print('🔗 Cambiando contraseña para: $email');
      print('📌 Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Contraseña cambiada exitosamente');
        return;
      } else {
        throw Exception('Error al cambiar contraseña: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // --- VISITAS PROGRAMADAS ---
  
  // Obtener visitas programadas del visitador actual
  Future<List<VisitaProgramada>> getVisitasProgramadasVisitador() async {
    try {
      final token = await getToken();
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      final url = '$baseUrl/api/visitas-programadas/visitador';
      print('🔗 Obteniendo visitas programadas del visitador');
      print('🔑 Headers: $headers');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📌 Respuesta del servidor - Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => VisitaProgramada.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener visitas programadas: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getVisitasProgramadasVisitador: $e');
      throw Exception('Error al obtener visitas programadas: $e');
    }
  }

  // Obtener todas las visitas programadas (para supervisores)
  Future<List<VisitaProgramada>> getTodasVisitasProgramadas() async {
    try {
      final token = await getToken();
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      final url = '$baseUrl/api/visitas-programadas';
      print('🔗 Obteniendo todas las visitas programadas');
      print('🔑 Headers: $headers');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📌 Respuesta del servidor - Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => VisitaProgramada.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener visitas programadas: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getTodasVisitasProgramadas: $e');
      throw Exception('Error al obtener visitas programadas: $e');
    }
  }

  // Obtener visitas programadas del visitador actual
  Future<List<VisitaProgramada>> getMisVisitasProgramadas() async {
    try {
      final token = await getToken();
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      final url = '$baseUrl/api/visitas-programadas/mis-visitas';
      print('🔗 Obteniendo mis visitas programadas');
      print('🔑 Headers: $headers');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📌 Respuesta del servidor - Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => VisitaProgramada.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener mis visitas programadas: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getMisVisitasProgramadas: $e');
      throw Exception('Error al obtener mis visitas programadas: $e');
    }
  }

  // Asignar visita a visitador (para supervisores) - Versión con parámetros individuales
  Future<bool> asignarVisitaAVisitador({
    required String contrato,
    required String operador,
    required DateTime fechaProgramada,
    required int municipioId,
    required int institucionId,
    required int sedeId,
    required int visitadorId,
  }) async {
    try {
      final token = await getToken();
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      final body = {
        'sede_id': sedeId,
        'visitador_id': visitadorId,
        'fecha_programada': fechaProgramada.toIso8601String(),
        'tipo_visita': 'PAE',
        'prioridad': 'normal',
        'contrato': contrato,
        'operador': operador,
        'municipio_id': municipioId,
        'institucion_id': institucionId,
        'observaciones': '',
      };

      final url = '$baseUrl/api/visitas-asignadas';
      print('🔗 Asignando visita a visitador');
      print('🔑 Headers: $headers');
      print('📦 Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      print('📌 Respuesta del servidor - Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      return response.statusCode == 201;
    } catch (e) {
      print('❌ Error en asignarVisitaAVisitador: $e');
      throw Exception('Error al asignar visita: $e');
    }
  }

  // Asignar visita a visitador (para supervisores) - Versión con Map
  Future<bool> asignarVisitaConMap(Map<String, dynamic> visitaProgramada) async {
    try {
      final token = await getToken();
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode(visitaProgramada);

      final url = '$baseUrl/api/visitas-asignadas';
      print('🔗 Asignando visita con Map');
      print('🔑 Headers: $headers');
      print('📦 Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print('📌 Respuesta del servidor - Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      return response.statusCode == 201;
    } catch (e) {
      print('❌ Error en asignarVisitaConMap: $e');
      throw Exception('Error al asignar visita: $e');
    }
  }

  // Actualizar estado de visita programada
  Future<bool> actualizarEstadoVisitaProgramada(int visitaId, String nuevoEstado) async {
    try {
      final token = await getToken();
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        'estado': nuevoEstado,
      });

      final url = '$baseUrl/api/visitas-programadas/$visitaId/estado';
      print('🔗 Actualizando estado de visita programada: $visitaId');
      print('🔑 Headers: $headers');
      print('📦 Body: $body');

      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print('📌 Respuesta del servidor - Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error en actualizarEstadoVisitaProgramada: $e');
      throw Exception('Error al actualizar estado de visita programada: $e');
    }
  }

  // --- MÉTODOS PARA VISITAS ASIGNADAS ---

  // Obtener mis visitas asignadas (para visitadores)
  Future<List<Map<String, dynamic>>> getMisVisitasAsignadas({String? estado}) async {
    try {
      final token = await getToken();
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      String url = '$baseUrl/api/visitas-asignadas/mis-visitas';
      if (estado != null) {
        url += '?estado=$estado';
      }
      
      print('🔗 Obteniendo mis visitas asignadas - Estado: $estado');
      print('🔑 Headers: $headers');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📌 Respuesta del servidor - Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final visitas = data.map((json) => Map<String, dynamic>.from(json)).toList();
        print('✅ Visitas asignadas obtenidas: ${visitas.length}');
        return visitas;
      } else {
        throw Exception('Error al obtener mis visitas asignadas: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getMisVisitasAsignadas: $e');
      throw Exception('Error al obtener mis visitas asignadas: $e');
    }
  }

  // Actualizar estado de visita asignada
  Future<Map<String, dynamic>> actualizarEstadoVisitaAsignada(
    int visitaId, {
    String? estado,
    DateTime? fechaInicio,
    DateTime? fechaCompletada,
    String? observaciones,
  }) async {
    try {
      final token = await getToken();
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      final Map<String, dynamic> datos = {};
      if (estado != null) datos['estado'] = estado;
      if (fechaInicio != null) datos['fecha_inicio'] = fechaInicio.toIso8601String();
      if (fechaCompletada != null) datos['fecha_completada'] = fechaCompletada.toIso8601String();
      if (observaciones != null) datos['observaciones'] = observaciones;

      final body = jsonEncode(datos);

      final url = '$baseUrl/api/visitas-asignadas/$visitaId/estado';
      print('🔗 Actualizando estado de visita asignada: $visitaId');
      print('🔑 Headers: $headers');
      print('📦 Body: $body');

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print('📌 Respuesta del servidor - Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Estado de visita asignada actualizado: $estado');
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception('Error al actualizar estado de visita asignada: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en actualizarEstadoVisitaAsignada: $e');
      throw Exception('Error al actualizar estado de visita asignada: $e');
    }
  }

  // Obtener todas las visitas del usuario (asignadas + completas) para el calendario
  Future<List<Map<String, dynamic>>> getTodasVisitasUsuario() async {
    try {
      // Obtener visitas asignadas (que son las que realmente existen)
      final visitasAsignadas = await getMisVisitasAsignadas();
      
      print('📅 DEBUG: Total visitas asignadas obtenidas: ${visitasAsignadas.length}');
      
      // Convertir al formato esperado por el calendario
      final visitasFormateadas = visitasAsignadas.map((visita) => {
        'id': visita['id'],
        'sede_id': visita['sede_id'],
        'sede_nombre': visita['sede_nombre'],
        'visitador_id': visita['visitador_id'],
        'visitador_nombre': visita['visitador_nombre'],
        'fecha_programada': visita['fecha_programada'],
        'contrato': visita['contrato'] ?? '',
        'operador': visita['operador'] ?? '',
        'observaciones': visita['observaciones'] ?? '',
        'estado': visita['estado'],
        'municipio_id': visita['municipio_id'],
        'municipio_nombre': visita['municipio_nombre'] ?? '',
        'institucion_id': visita['institucion_id'],
        'institucion_nombre': visita['institucion_nombre'] ?? '',
        'fecha_creacion': visita['fecha_creacion'] ?? DateTime.now().toIso8601String(),
      }).toList();
      
      return visitasFormateadas;
    } catch (e) {
      print('❌ Error en getTodasVisitasUsuario: $e');
      return [];
    }
  }

  String _timeOfDayToIso8601String(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return dateTime.toIso8601String();
  }

  // Obtener casos de atención prioritaria
  Future<List<Map<String, dynamic>>> getCasosAtencionPrioritaria() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/casos-atencion-prioritaria'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        print('❌ Error al obtener casos de atención prioritaria: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error en getCasosAtencionPrioritaria: $e');
      return [];
    }
  }

  // --- MÉTODOS DE NOTIFICACIONES PUSH ---

  /// Registra un dispositivo para notificaciones push
  Future<Map<String, dynamic>> registrarDispositivoNotificacion({
    required String token,
    required String plataforma,
  }) async {
    try {
      final url = '$baseUrl/api/notificaciones/dispositivos/registrar';
      final headers = await _getHeaders();
      
      final body = jsonEncode({
        'token_dispositivo': token,
        'plataforma': plataforma,
      });

      print('🔗 Registrando dispositivo para notificaciones: $plataforma');
      print('📦 Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print('📌 Respuesta del servidor - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Dispositivo registrado exitosamente');
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception('Error al registrar dispositivo: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en registrarDispositivoNotificacion: $e');
      throw Exception('Error al registrar dispositivo: $e');
    }
  }

  /// Desactiva un dispositivo para notificaciones
  Future<bool> desactivarDispositivoNotificacion(String token) async {
    try {
      final url = '$baseUrl/api/notificaciones/dispositivos/desactivar/$token';
      final headers = await _getHeaders();

      print('🔗 Desactivando dispositivo: ${token.substring(0, 20)}...');

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      print('📌 Respuesta del servidor - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Dispositivo desactivado exitosamente');
        return true;
      } else {
        throw Exception('Error al desactivar dispositivo: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en desactivarDispositivoNotificacion: $e');
      throw Exception('Error al desactivar dispositivo: $e');
    }
  }

  /// Obtiene las notificaciones del usuario
  Future<List<Map<String, dynamic>>> getNotificacionesUsuario({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final url = '$baseUrl/api/notificaciones/usuario?limit=$limit&offset=$offset';
      final headers = await _getHeaders();

      print('🔗 Obteniendo notificaciones del usuario');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📌 Respuesta del servidor - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ Notificaciones obtenidas: ${data.length}');
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error al obtener notificaciones: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getNotificacionesUsuario: $e');
      throw Exception('Error al obtener notificaciones: $e');
    }
  }

  /// Marca una notificación como leída
  Future<bool> marcarNotificacionLeida(int notificacionId) async {
    try {
      final url = '$baseUrl/api/notificaciones/$notificacionId/leer';
      final headers = await _getHeaders();

      print('🔗 Marcando notificación como leída: $notificacionId');

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
      );

      print('📌 Respuesta del servidor - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Notificación marcada como leída');
        return true;
      } else {
        throw Exception('Error al marcar notificación como leída: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en marcarNotificacionLeida: $e');
      throw Exception('Error al marcar notificación como leída: $e');
    }
  }

  /// Obtiene estadísticas de notificaciones
  Future<Map<String, dynamic>> getEstadisticasNotificaciones() async {
    try {
      final url = '$baseUrl/api/notificaciones/estadisticas';
      final headers = await _getHeaders();

      print('🔗 Obteniendo estadísticas de notificaciones');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📌 Respuesta del servidor - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Estadísticas obtenidas');
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception('Error al obtener estadísticas: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getEstadisticasNotificaciones: $e');
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  /// Envía una notificación push (solo para administradores/supervisores)
  Future<Map<String, dynamic>> enviarNotificacionPush({
    required String titulo,
    required String mensaje,
    required String tipo,
    required List<int> usuarioIds,
    String prioridad = 'normal',
    Map<String, dynamic>? datosAdicionales,
  }) async {
    try {
      final url = '$baseUrl/api/notificaciones/enviar';
      final headers = await _getHeaders();
      
      final body = jsonEncode({
        'titulo': titulo,
        'mensaje': mensaje,
        'tipo': tipo,
        'prioridad': prioridad,
        'usuario_ids': usuarioIds,
        'datos_adicionales': datosAdicionales,
      });

      print('🔗 Enviando notificación push a ${usuarioIds.length} usuarios');
      print('📦 Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print('📌 Respuesta del servidor - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Notificación push enviada exitosamente');
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception('Error al enviar notificación push: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en enviarNotificacionPush: $e');
      throw Exception('Error al enviar notificación push: $e');
    }
  }

  /// Sincroniza las visitas programadas con las visitas completas PAE
  Future<bool> sincronizarVisitasProgramadas() async {
    try {
      final url = '$baseUrl/api/sincronizar-visitas-programadas';
      final headers = await _getHeaders();
      
      print('🔄 Sincronizando visitas programadas...');
      print('🔗 URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      );

      print('📌 Respuesta de sincronización - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Sincronización exitosa: ${data['mensaje']}');
        print('📊 Visitas actualizadas: ${data['visitas_actualizadas']}');
        return true;
      } else {
        print('❌ Error en sincronización: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error en sincronizarVisitasProgramadas: $e');
      
      // Verificar si es un error de autenticación
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        print('🔐 Error de autenticación en sincronización. Limpiando token...');
        await logout(); // Limpiar token expirado
        throw Exception('Sesión expirada durante la sincronización. Por favor, inicia sesión nuevamente.');
      }
      
      return false;
    }
  }

  /// Sincroniza TODAS las visitas del usuario (asignadas, completas, programadas)
  Future<bool> sincronizarTodasLasVisitas() async {
    try {
      print('🔄 === INICIANDO SINCRONIZAR TODAS LAS VISITAS ===');
      final url = '$baseUrl/api/sincronizar-todas-las-visitas';
      final headers = await _getHeaders();
      
      print('🔄 Sincronizando TODAS las visitas...');
      print('🔗 URL: $url');
      print('🔑 Headers: $headers');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      );

      print('📌 Respuesta de sincronización completa - Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Sincronización completa exitosa: ${data['mensaje']}');
        print('📊 Visitas sincronizadas: ${data['visitas_sincronizadas']}');
        print('🔄 === FIN SINCRONIZAR TODAS LAS VISITAS ===');
        return true;
      } else {
        print('❌ Error en sincronización completa: ${response.statusCode} - ${response.body}');
        print('🔄 === FIN SINCRONIZAR TODAS LAS VISITAS (ERROR) ===');
        return false;
      }
    } catch (e) {
      print('❌ Error en sincronizarTodasLasVisitas: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      
      // Verificar si es un error de autenticación
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        print('🔐 Error de autenticación en sincronización. Limpiando token...');
        await logout(); // Limpiar token expirado
        throw Exception('Sesión expirada durante la sincronización. Por favor, inicia sesión nuevamente.');
      }
      
      print('🔄 === FIN SINCRONIZAR TODAS LAS VISITAS (EXCEPTION) ===');
      return false;
    }
  }

  /// Función auxiliar para descargar Excel en Flutter web
  Future<void> _descargarExcelWeb(List<int> bytes, String filename) async {
    return _descargarArchivoWeb(bytes, filename, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  }

  /// Función auxiliar genérica para descargar archivos en Flutter web
  Future<void> _descargarArchivoWeb(List<int> bytes, String filename, String mimeType) async {
    if (kIsWeb) {
      try {
        print('🌐 Descargando archivo en Flutter web...');
        print('📄 Archivo: $filename');
        print('🔖 Tipo MIME: $mimeType');
        print('📊 Tamaño: ${bytes.length} bytes');
        
        // Usar la clase de compatibilidad
        await PlatformCompat.downloadFile(bytes, filename, mimeType);
        print('✅ Descarga iniciada: $filename');
      } catch (e) {
        print('❌ Error al descargar archivo en web: $e');
        throw Exception('Error al descargar archivo en web: $e');
      }
    } else {
      throw Exception('Esta función solo está disponible en Flutter web');
    }
  }

  // --- MÉTODOS DEL SUPERVISOR ---

  /// Obtiene estadísticas específicas del supervisor
  Future<Map<String, dynamic>> getEstadisticasSupervisor() async {
    try {
      final url = '$baseUrl/api/dashboard/supervisor/estadisticas';
      final headers = await _getHeaders();
      
      print('📊 Obteniendo estadísticas del supervisor...');
      print('🔗 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📌 Respuesta estadísticas supervisor - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Estadísticas del supervisor obtenidas exitosamente');
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception('Error al obtener estadísticas: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getEstadisticasSupervisor: $e');
      throw Exception('Error al obtener estadísticas del supervisor: $e');
    }
  }

  /// Obtiene visitas del equipo del supervisor
  Future<List<Map<String, dynamic>>> getVisitasEquipo() async {
    try {
      final url = '$baseUrl/api/supervisor/visitas-equipo';
      final headers = await _getHeaders();
      
      print('👥 Obteniendo visitas del equipo...');
      print('🔗 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📌 Respuesta visitas equipo - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Visitas del equipo obtenidas exitosamente');
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Error al obtener visitas del equipo: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getVisitasEquipo: $e');
      throw Exception('Error al obtener visitas del equipo: $e');
    }
  }

  /// Obtiene visitadores del equipo del supervisor
  Future<List<Map<String, dynamic>>> getVisitadoresEquipo() async {
    try {
      final url = '$baseUrl/api/admin/visitadores';
      final headers = await _getHeaders();
      
      print('👥 Obteniendo visitadores del equipo...');
      print('🔗 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📌 Respuesta visitadores equipo - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Visitadores del equipo obtenidos exitosamente');
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Error al obtener visitadores del equipo: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getVisitadoresEquipo: $e');
      throw Exception('Error al obtener visitadores del equipo: $e');
    }
  }

  /// Obtiene sedes disponibles para asignar visitas
  Future<List<Map<String, dynamic>>> getSedesDisponibles() async {
    try {
      final url = '$baseUrl/api/admin/sedes';
      final headers = await _getHeaders();
      
      print('🏫 Obteniendo sedes disponibles...');
      print('🔗 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📌 Respuesta sedes disponibles - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Sedes disponibles obtenidas exitosamente');
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Error al obtener sedes disponibles: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getSedesDisponibles: $e');
      throw Exception('Error al obtener sedes disponibles: $e');
    }
  }

  /// Obtiene tipos de visita disponibles
  Future<List<Map<String, dynamic>>> getTiposVisita() async {
    try {
      final url = '$baseUrl/api/admin/tipos-visita';
      final headers = await _getHeaders();
      
      print('📋 Obteniendo tipos de visita...');
      print('🔗 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📌 Respuesta tipos visita - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Tipos de visita obtenidos exitosamente');
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Error al obtener tipos de visita: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getTiposVisita: $e');
      throw Exception('Error al obtener tipos de visita: $e');
    }
  }

  /// Asigna una visita a un visitador
  Future<void> asignarVisita(Map<String, dynamic> datosVisita) async {
    try {
      final url = '$baseUrl/api/supervisor/asignar-visita';
      final headers = await _getHeaders();
      
      print('📝 Asignando visita...');
      print('🔗 URL: $url');
      print('📊 Datos: $datosVisita');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(datosVisita),
      );

      print('📌 Respuesta asignar visita - Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Visita asignada exitosamente');
        print('📄 Respuesta: ${response.body}');
      } else {
        print('❌ Error del servidor: ${response.statusCode}');
        print('📄 Respuesta: ${response.body}');
        throw Exception('Error al asignar visita: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error en asignarVisita: $e');
      throw Exception('Error al asignar visita: $e');
    }
  }

  /// Genera un reporte del equipo
  Future<Map<String, dynamic>> generarReporteEquipo(Map<String, dynamic> filtros) async {
    try {
      final url = '$baseUrl/api/supervisor/generar-reporte-equipo';
      final headers = await _getHeaders();
      
      print('📊 Generando reporte del equipo...');
      print('🔗 URL: $url');
      print('🔍 Filtros: $filtros');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(filtros),
      );

      print('📌 Respuesta generar reporte - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Reporte del equipo generado exitosamente');
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception('Error al generar reporte: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en generarReporteEquipo: $e');
      throw Exception('Error al generar reporte del equipo: $e');
    }
  }

  /// Descarga un reporte del equipo
  Future<void> descargarReporteEquipo(int reporteId) async {
    try {
      final url = '$baseUrl/api/supervisor/descargar-reporte-equipo/$reporteId';
      final headers = await _getHeaders();
      
      print('📥 Descargando reporte del equipo...');
      print('🔗 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📌 Respuesta descargar reporte - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final filename = 'reporte_equipo_$reporteId.xlsx';
        
        if (kIsWeb) {
          await _descargarExcelWeb(bytes, filename);
        } else {
          // Para móvil, guardar en el dispositivo
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/$filename');
          await file.writeAsBytes(bytes);
          print('✅ Reporte guardado en: ${file.path}');
        }
      } else {
        throw Exception('Error al descargar reporte: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en descargarReporteEquipo: $e');
      throw Exception('Error al descargar reporte del equipo: $e');
    }
  }

  /// Obtiene el directorio de descargas, creando la carpeta SMC si es necesario
  Future<Directory> _obtenerDirectorioDescargas() async {
    try {
      Directory downloadsDir;
      
      if (Platform.isAndroid) {
        // Para Android, usar el directorio de descargas estándar
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          // Fallback al directorio externo
          downloadsDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        // Para iOS, usar el directorio de documentos
        downloadsDir = await getApplicationDocumentsDirectory();
      } else {
        // Para otras plataformas
        downloadsDir = await getApplicationDocumentsDirectory();
      }
      
      // Crear subdirectorio SMC
      final smcDir = Directory('${downloadsDir.path}/SMC');
      if (!await smcDir.exists()) {
        await smcDir.create(recursive: true);
        print('📁 Directorio SMC creado: ${smcDir.path}');
      }
      
      return smcDir;
    } catch (e) {
      print('❌ Error al obtener directorio de descargas: $e');
      // Fallback al directorio de documentos
      return await getApplicationDocumentsDirectory();
    }
  }

  /// Obtiene alertas del equipo
  Future<List<Map<String, dynamic>>> getAlertasEquipo() async {
    try {
      final url = '$baseUrl/api/supervisor/alertas-equipo';
      final headers = await _getHeaders();
      
      print('🚨 Obteniendo alertas del equipo...');
      print('🔗 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📌 Respuesta alertas equipo - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Alertas del equipo obtenidas exitosamente');
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Error al obtener alertas del equipo: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getAlertasEquipo: $e');
      throw Exception('Error al obtener alertas del equipo: $e');
    }
  }
}
