import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_visitas/config.dart';

class PendientesScreen extends StatefulWidget {
  const PendientesScreen({super.key});

  @override
  State<PendientesScreen> createState() => _PendientesScreenState();
}

class _PendientesScreenState extends State<PendientesScreen> {
  List<dynamic> pendientes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    cargarPendientes();
  }

  Future<void> cargarPendientes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/visitas/mis-visitas'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        pendientes = data.where((v) => v['estado'] == 'pendiente').toList();
        loading = false;
      });
    } else {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar pendientes: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Visitas pendientes")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: pendientes.length,
              itemBuilder: (context, index) {
                final v = pendientes[index];
                return ListTile(
                  title: Text(v['sede']['nombre']),
                  subtitle: Text("Asunto: ${v['tipo_asunto']}\nFecha: ${v['fecha']}"),
                );
              },
            ),
    );
  }
}
