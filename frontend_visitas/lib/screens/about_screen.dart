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
            
            // Información Gobernación del Cauca
            _buildGobernacionInfoCard(),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: const Text(
        "Sistema integral para la gestión, monitoreo y control de visitas a sedes educativas del Departamento del Cauca. Permite programación, registro, seguimiento en tiempo real y generación de reportes de las visitas del Programa de Alimentación Escolar (PAE).",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 15, height: 1.5),
      ),
    );
  }

  Widget _buildGobernacionInfoCard() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance, color: Colors.green[700], size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Gobernación del Cauca",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Secretaría de Educación",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Text(
                "Programa de Alimentación Escolar (PAE)",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[800],
                ),
              ),
            ),
          ],
        ),
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
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Desarrollado por",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple[700],
              ),
            ),
            const SizedBox(height: 12),
            _buildDeveloperCard(
              nombre: "Ana Yuliza Díaz Quintero",
              cargo: "Desarrolladora Frontend y Backend",
            ),
            const SizedBox(height: 8),
            _buildDeveloperCard(
              nombre: "Lizeth Carolina Alonso Gonzales",
              cargo: "Desarrolladora Backend y Frontend",
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "En colaboración con",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
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
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Fundación Universitaria de Popayán",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Institución de Educación Superior",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperCard({
    required String nombre,
    required String cargo,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person, color: Colors.deepPurple[400], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  cargo,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalLinks() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          "Información Legal",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        _buildLegalLink(
          icon: Icons.privacy_tip,
          title: "Política de Privacidad",
          url: 'https://www.fup.edu.co/politica-privacidad',
        ),
        _buildLegalLink(
          icon: Icons.description,
          title: "Términos y Condiciones",
          url: 'https://www.fup.edu.co/terminos-condiciones',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "© 2025 SMC VS - Todos los derechos reservados\nSistema desarrollado para el Programa de Alimentación Escolar (PAE) del Cauca",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegalLink({
    required IconData icon,
    required String title,
    required String url,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple[400], size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      onTap: () => _launchUrl(url),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}