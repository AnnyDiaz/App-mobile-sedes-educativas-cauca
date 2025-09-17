import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Simular la configuración del frontend
const String baseUrl = "http://127.0.0.1:8000";

Future<void> testTokenHandling() async {
  print('🧪 Iniciando prueba de manejo de tokens...');
  
  try {
    // 1. Hacer login
    print('\n1️⃣ Haciendo login...');
    final loginResponse = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'correo': 'test@test.com',
        'contrasena': 'test123',
      }),
    );
    
    print('📊 Status Code: ${loginResponse.statusCode}');
    print('📄 Response Body: ${loginResponse.body}');
    
    if (loginResponse.statusCode == 200) {
      final data = jsonDecode(loginResponse.body);
      final token = data['access_token'];
      
      print('✅ Login exitoso');
      print('🔑 Token obtenido: ${token.substring(0, 50)}...');
      
      // 2. Guardar token en SharedPreferences (simulado)
      print('\n2️⃣ Guardando token en SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      
      // 3. Leer token de SharedPreferences
      print('\n3️⃣ Leyendo token de SharedPreferences...');
      final savedToken = prefs.getString('token');
      print('🔑 Token guardado: ${savedToken?.substring(0, 50)}...');
      
      // 4. Probar endpoint protegido
      print('\n4️⃣ Probando endpoint protegido...');
      final protectedResponse = await http.get(
        Uri.parse('$baseUrl/api/dashboard/estadisticas'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $savedToken',
        },
      );
      
      print('📊 Status Code: ${protectedResponse.statusCode}');
      print('📄 Response Body: ${protectedResponse.body}');
      
      if (protectedResponse.statusCode == 200) {
        print('✅ Endpoint protegido funciona correctamente');
      } else {
        print('❌ Error en endpoint protegido');
      }
      
      // 5. Probar endpoint de perfil
      print('\n5️⃣ Probando endpoint de perfil...');
      final perfilResponse = await http.get(
        Uri.parse('$baseUrl/api/perfil'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $savedToken',
        },
      );
      
      print('📊 Status Code: ${perfilResponse.statusCode}');
      print('📄 Response Body: ${perfilResponse.body}');
      
      if (perfilResponse.statusCode == 200) {
        print('✅ Endpoint de perfil funciona correctamente');
      } else {
        print('❌ Error en endpoint de perfil');
      }
      
    } else {
      print('❌ Error en login');
    }
    
  } catch (e) {
    print('❌ Error durante la prueba: $e');
  }
}

void main() async {
  await testTokenHandling();
} 