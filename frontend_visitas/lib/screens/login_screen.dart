import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_visitas/config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  void _login() async {
  setState(() {
    _loading = true;
    _error = null;
  });

  final correo = emailController.text.trim();
  final contrasena = passwordController.text.trim();
  final url = Uri.parse('$baseUrl/auth/login');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'correo': correo,
        'contrasena': contrasena,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];
      final usuario = data['usuario'];

      // --- LA CORRECCIÓN MÁS IMPORTANTE ESTÁ AQUÍ ---

      // 1. Extraemos el rol de forma segura y lo convertimos a minúsculas
      final String rol = (usuario['rol']['nombre'] as String).toLowerCase();

      // 2. Imprimimos en la consola de depuración para estar 100% seguros
      print('--- DEBUG DE REDIRECCIÓN ---');
      print('Rol recibido y procesado: "$rol"');
      print('Intentando navegar a la ruta correspondiente...');
      print('-----------------------------');


      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('rol', rol);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Inicio de sesión exitoso")),
        );

        // 3. Usamos la ruta correcta del main.dart
        switch (rol) {
          case "admin":
          case "super administrador":
            Navigator.pushReplacementNamed(context, '/admin_dashboard');
            break;
          case "supervisor":
            Navigator.pushReplacementNamed(context, '/supervisor_dashboard');
            break;
          case "visitador":
            // Esta es la ruta correcta para el dashboard principal del visitador
            Navigator.pushReplacementNamed(context, '/visitador_dashboard');
            break;
          default:
            // Si el rol no coincide, nos dará un error claro
            setState(() {
              _error = 'Rol de usuario desconocido: "$rol"';
            });
        }
      }
    } else {
      setState(() {
        _error = 'Correo o contraseña inválidos';
      });
    }
  } catch (e) {
    setState(() {
      _loading = false;
      _error = 'Error procesando la respuesta: ${e.toString()}';
    });
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                Image.asset('assets/images/logo_cauca.png', height: 80),
                const SizedBox(height: 20),
                const Text('Iniciar sesión', style: TextStyle(fontSize: 20)),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Correo electrónico'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                ),
                const SizedBox(height: 20),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16)),
                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008BE8),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Iniciar sesión'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text('¿No tienes cuenta? Registrarse'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
