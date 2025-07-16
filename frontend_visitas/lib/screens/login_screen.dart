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
    final url = Uri.parse('$baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': correo,
          'contrasena': contrasena,
        }),
      );

      setState(() {
        _loading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        final usuario = data['usuario'];
        final rol = usuario['rol']; // ← Asegúrate de que esto llega del backend

        // Guardar token y rol en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token); // ← USAR CLAVE UNIFICADA
        await prefs.setString('rol', rol);

        print("✅ TOKEN JWT: $token");
        print("👤 Usuario: ${usuario['nombre']}");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Inicio de sesión exitoso")),
        );

        // Redirigir según el rol
        if (rol == "admin") {
          Navigator.pushReplacementNamed(context, '/admin_dashboard');
        } else if (rol == "supervisor") {
          Navigator.pushReplacementNamed(context, '/supervisor_dashboard');
        } else if (rol == "visitador") {
          Navigator.pushReplacementNamed(context, '/visitador');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Rol desconocido")),
          );
        }
      } else {
        setState(() {
          _error = 'Correo o contraseña inválidos';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Error de conexión con el servidor';
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
