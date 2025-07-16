import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; 
class VisitadorDashboard extends StatefulWidget {
  const VisitadorDashboard({super.key});

  @override
  State<VisitadorDashboard> createState() => _VisitadorDashboardState();
}

class _VisitadorDashboardState extends State<VisitadorDashboard> {
  String nombre = "";
  Map<String, dynamic>? visitaReciente;
  bool loading = true;
  final String baseUrl = 'http://192.168.1.2:3000/api'; // Asegúrate de definir tu baseUrl

  @override
  void initState() {
    super.initState();
    cargarDashboard();
  }

  Future<void> cargarDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final usuario = prefs.getString('usuario');

      if (usuario != null) {
        final parsed = jsonDecode(usuario);
        setState(() {
          nombre = parsed['nombre'] ?? "Visitador";
        });
      }

      if (token == null) {
        setState(() => loading = false);
        return;
      }

      final res = await http.get(
        Uri.parse('$baseUrl/visitas/mis-visitas'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty) {
          setState(() {
            visitaReciente = data.last;
          });
        }
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tiempo de espera agotado')),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Visitador"),
        backgroundColor: const Color(0xFF008BE8),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('token');
              await prefs.remove('usuario');

              if (context.mounted) {
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Image.asset('assets/images/logo_cauca.png', height: 60),
                        const SizedBox(height: 10),
                        Text("Bienvenido, $nombre",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/crear-visita'),
                        child: _DashboardCard(
                          icon: Icons.add,
                          title: 'Iniciar nueva visita',
                          subtitle: 'Comienza un nuevo registro de visita',
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/pendientes'),
                        child: _DashboardCard(
                          icon: Icons.pending_actions,
                          title: 'Mis visitas pendientes',
                          subtitle: 'Acceder a visitas guardadas para continuar',
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/historial'),
                        child: _DashboardCard(
                          icon: Icons.history,
                          title: 'Historial de visitas',
                          subtitle: 'Revisa el registro de todas tus visitas completadas',
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/perfil'),
                        child: _DashboardCard(
                          icon: Icons.person,
                          title: 'Mi perfil',
                          subtitle: 'Gestiona tu información y ajustes',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("Actividad reciente",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (visitaReciente != null)
                    Text(
                        "Visita iniciada: ${visitaReciente!['sede']['nombre']}\n${visitaReciente!['fecha']}"),
                  if (visitaReciente == null)
                    const Text("No hay visitas registradas."),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF008BE8),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ""),
        ],
        onTap: (index) {
          // navegación si lo deseas
        },
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: Colors.black87),
          const SizedBox(height: 10),
          Text(title,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 5),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}