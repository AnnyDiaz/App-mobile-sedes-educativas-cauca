import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String appVersion = "Cargando...";
  String appBuildNumber = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      
      if (!mounted) return;
      
      setState(() {
        appVersion = packageInfo.version;
        appBuildNumber = packageInfo.buildNumber;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        appVersion = "No disponible";
        isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
            // Logo de la aplicación
            _buildAppLogo(),
            const SizedBox(height: 16),
            
            // Nombre de la aplicación
            _buildAppName(),
            const SizedBox(height: 8),
            
            // Versión de la aplicación
            _buildVersionInfo(),
            const SizedBox(height: 20),
            
            // Descripción
            _buildAppDescription(),
            const SizedBox(height: 30),
            
            // Información FUP
            _buildFUPInfoCard(),
            const SizedBox(height: 20),
            
            // Contacto
            _buildContactListTile(
              icon: Icons.email,
              title: "Correo de soporte",
              subtitle: "soporte@smcvs.com",
              onTap: () => _launchUrl('mailto:soporte@smcvs.com'),
            ),
            _buildContactListTile(
              icon: Icons.public,
              title: "Sitio web",
              subtitle: "www.smcvs.com",
              onTap: () => _launchUrl('https://www.smcvs.com'),
            ),
            const Divider(height: 40),
            
            // Desarrolladores
            _buildDevelopersSection(),
            const SizedBox(height: 20),
            
            // Enlaces legales
            _buildLegalLinks(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppLogo() {
    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.deepPurple.shade100,
      child: ClipOval(
        child: Image.asset(
          'assets/images/portada.png',
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.school,
              color: Colors.deepPurple[700],
              size: 40,
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppName() {
    return const Text(
      "SMC VS – Sistema de Gestión de Visitas",
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildVersionInfo() {
    return isLoading 
      ? const SizedBox(
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Column(
          children: [
            Text(
              "Versión: $appVersion",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            if (appBuildNumber.isNotEmpty)
              Text(
                "Build: $appBuildNumber",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
          ],
        );
  }

  Widget _buildAppDescription() {
    return const Text(
      "Esta aplicación permite gestionar y supervisar las visitas a sedes educativas del Cauca, incluyendo programación, registro y seguimiento en tiempo real.",
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 15, height: 1.4),
    );
  }

  Widget _buildFUPInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logofup.png',
            width: 50,
            height: 50,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.school,
                color: Colors.blue[700],
                size: 30,
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Fundación Universitaria de Popayán",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Institución de Educación Superior",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }


  Widget _buildDevelopersSection() {
    return Column(
      children: [
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
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "En colaboración con:",
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Image.asset(
              'assets/images/logofup.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.school,
                  color: Colors.blue[700],
                  size: 24,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegalLinks() {
    return Column(
      children: [
        TextButton(
          onPressed: () => _launchUrl('https://www.smcvs.com/privacy'),
          child: const Text("Política de Privacidad"),
        ),
        TextButton(
          onPressed: () => _launchUrl('https://www.smcvs.com/terms'),
          child: const Text("Términos y Condiciones"),
        ),
      ],
    );
  }
}