import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
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

  Future<void> _fetchUsuarios() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No se encontró token de autenticación');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/usuarios'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          usuarios = data['usuarios'] ?? [];
        });
      } else {
        throw Exception('Error al cargar usuarios: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar usuarios: ${e.toString()}';
      });
    }
  }

  Future<void> _fetchSedes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No se encontró token de autenticación');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/sedes'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          sedes = data is List ? data : [];
          loading = false;
        });
      } else {
        throw Exception('Error al cargar sedes: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar sedes: ${e.toString()}';
        loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
    await Future.wait([_fetchUsuarios(), _fetchSedes()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
            tooltip: 'Actualizar datos',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(errorMessage!),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _fetchData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildUsuariosSection(),
                      const SizedBox(height: 24),
                      _buildSedesSection(),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUsuariosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Usuarios Registrados',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        usuarios.isEmpty
            ? const Text('No hay usuarios registrados')
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: usuarios.length,
                itemBuilder: (context, index) {
                  final usuario = usuarios[index];
                  return Card(
                    child: ListTile(
                      title: Text(usuario['nombre']?.toString() ?? 'Nombre no disponible'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(usuario['correo']?.toString() ?? 'Correo no disponible'),
                          Text('Rol: ${usuario['rol']?.toString() ?? 'No especificado'}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editUser(usuario),
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildSedesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sedes Educativas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        sedes.isEmpty
            ? const Text('No hay sedes registradas')
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sedes.length,
                itemBuilder: (context, index) {
                  final sede = sedes[index];
                  return Card(
                    child: ListTile(
                      title: Text(sede['nombre']?.toString() ?? 'Nombre no disponible'),
                      subtitle: Text(
                          'Municipio: ${sede['municipio']?.toString() ?? 'No especificado'}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editSede(sede),
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Future<void> _showAddUserDialog() async {
    // Implementar diálogo para agregar usuario
  }

  Future<void> _editUser(Map<String, dynamic> usuario) async {
    // Implementar edición de usuario
  }

  Future<void> _editSede(Map<String, dynamic> sede) async {
    // Implementar edición de sede
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_rol');
    await prefs.remove('nombre');
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }
}