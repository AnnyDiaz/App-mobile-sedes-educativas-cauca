import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String appVersion = "Cargando...";

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      appVersion = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Acerca de"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.deepPurple.shade100,
              child: ClipOval(
                child: Image.asset(
                  'assets/images/portada.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "SMC VS – Sistema de Gestión de Visitas",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Versión: $appVersion",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 20),
            const Text(
              "Esta aplicación permite gestionar y supervisar las visitas a sedes educativas del Cauca, incluyendo programación, registro y seguimiento en tiempo real.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 30),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.deepPurple),
              title: const Text("Correo de soporte"),
              subtitle: const Text("soporte@smcvs.com"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.public, color: Colors.deepPurple),
              title: const Text("Sitio web"),
              subtitle: const Text("www.smcvs.com"),
              onTap: () {},
            ),
            const Divider(height: 40),
            const Text(
              "Desarrollado por:",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "Ana Yuliza Díaz Quintero\nLizeth Carolina Alonso Gonzales",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            TextButton(onPressed: () {}, child: const Text("Política de Privacidad")),
            TextButton(onPressed: () {}, child: const Text("Términos y Condiciones")),
          ],
        ),
      ),
    );
  }
}


