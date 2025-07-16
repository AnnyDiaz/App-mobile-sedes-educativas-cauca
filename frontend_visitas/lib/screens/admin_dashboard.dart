import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';  // Importación añadida para TimeoutException
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_visitas/config.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<dynamic> usuarios = [];
  List<dynamic> sedes = [];
  bool loading = true;
  String? errorMessage;

  Future<void> fetchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No se encontró token de autenticación');
      }

      final responses = await Future.wait([
        http.get(
          Uri.parse('$baseUrl/admin/usuarios'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 15)),
        http.get(
          Uri.parse('$baseUrl/sedes'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 15)),
      ]);

      for (var response in responses) {
        if (response.statusCode != 200) {
          throw Exception('Error al obtener datos: ${response.statusCode}');
        }
      }

      setState(() {
        usuarios = json.decode(responses[0].body)['usuarios'] ?? [];
        sedes = json.decode(responses[1].body) ?? [];
        loading = false;
        errorMessage = null;
      });
    } on TimeoutException {
      setState(() {
        loading = false;
        errorMessage = 'Tiempo de espera agotado. Intente nuevamente';
      });
    } on http.ClientException catch (e) {
      setState(() {
        loading = false;
        errorMessage = 'Error de conexión: ${e.message}';
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  // ... resto del código permanece igual ...
}