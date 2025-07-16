import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend_visitas/config.dart';

class VisitadorHome extends StatefulWidget {
  const VisitadorHome({super.key});

  @override
  State<VisitadorHome> createState() => _VisitadorHomeState();
}

class _VisitadorHomeState extends State<VisitadorHome> {
  String nombre = "";
  Map<String, dynamic>? visitaReciente;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    cargarDatosUsuario();
    cargarUltimaVisita();
  }

  Future<void> cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nombre = prefs.getString('nombre') ?? "Visitador";
    });
  }

  Future<void> cargarUltimaVisita() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() => loading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/visitas/mis-visitas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final visitas = jsonDecode(response.body);
        if (visitas.isNotEmpty) {
          setState(() {
            visitaReciente = visitas.last;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Widget _buildCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        child: Container(
          width: 150,
          height: 140,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Colors.black),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(subtitle, 
                  textAlign: TextAlign.center, 
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Principal"),
        backgroundColor: const Color(0xFF008BE8),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('token');
              await prefs.remove('nombre');
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  '/login', 
                  (route) => false
                );
              }
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Bienvenido, $nombre", 
                        style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildCard(
                        "Iniciar nueva visita", 
                        "Comienza un nuevo registro de visita", 
                        Icons.add, 
                        () => Navigator.pushNamed(context, '/crear-visita')),
                      const SizedBox(width: 10),
                      _buildCard(
                        "Mis visitas pendientes", 
                        "Accede a visitas guardadas", 
                        Icons.assignment_late, 
                        () => Navigator.pushNamed(context, '/pendientes')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildCard(
                        "Historial de visitas", 
                        "Revisa tus visitas completadas", 
                        Icons.history, 
                        () => Navigator.pushNamed(context, '/historial')),
                      const SizedBox(width: 10),
                      _buildCard(
                        "Mi perfil", 
                        "Gestiona tu información", 
                        Icons.settings, 
                        () => Navigator.pushNamed(context, '/perfil')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (visitaReciente != null) ...[
                    const Divider(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Actividad reciente\nVisita iniciada: ${visitaReciente!['sede']['nombre']}\n${visitaReciente!['fecha']}",
                        style: const TextStyle(fontSize: 14),
                      ),
                    )
                  ]
                ],
              ),
            ),
    );
  }
}