import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
 final String baseUrl = 'http://192.168.101.26:8000';   // ⚠️ Usa la IP local de tu PC

  Future<Map<String, dynamic>> login(String correo, String contrasena) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"correo": correo, "contrasena": contrasena}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Login fallido');
    }
  }
}
