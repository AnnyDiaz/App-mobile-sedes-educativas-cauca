import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config.dart';
import '../utils/responsive_utils.dart';

class VisitadorHome extends StatefulWidget {
  const VisitadorHome({super.key});

  @override
  State<VisitadorHome> createState() => _VisitadorHomeState();
}

class _VisitadorHomeState extends State<VisitadorHome> {
  String nombre = "";
  Map<String, dynamic>? visitaReciente;

  @override
  void initState() {
    super.initState();
    verificarAutenticacion();
    cargarDatosUsuario();
    cargarUltimaVisita();
  }

  Future<void> verificarAutenticacion() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    }
  }

  Future<void> cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nombre = prefs.getString('nombre') ?? "Visitador";
    });
  }

  Future<void> cargarUltimaVisita() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/visitas-asignadas/mis-visitas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final visitas = jsonDecode(response.body);
        if (visitas is List && visitas.isNotEmpty) {
          final ultimaVisita = visitas.last;
          // Verificar que la visita tenga los campos necesarios
          if (ultimaVisita != null && 
              ultimaVisita is Map<String, dynamic> &&
              ultimaVisita['sede'] != null &&
              ultimaVisita['sede'] is Map<String, dynamic>) {
            setState(() {
              visitaReciente = ultimaVisita;
            });
          }
        }
      } else if (response.statusCode == 401) {
        // Token expirado o inválido
        await prefs.clear();
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/auth');
        }
      }
    } catch (e) {
      debugPrint('Error al cargar última visita: $e');
    }
  }

  Widget _buildCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        child: Container(
          width: ResponsiveUtils.screenWidth(context) * 0.4,
          height: ResponsiveUtils.getCardHeight(context),
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: ResponsiveUtils.getIconSize(context), color: Colors.black),
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
              Text(
                title, 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14)
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
              Text(
                subtitle, 
                textAlign: TextAlign.center, 
                style: TextStyle(fontSize: ResponsiveUtils.getResponsiveFontSize(context, 10)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
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
         title: Text(
           "Principal",
           style: TextStyle(
             fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
             fontWeight: FontWeight.w600,
           ),
         ),
         backgroundColor: const Color(0xFF008BE8),
        actions: [
                     IconButton(
             icon: Icon(
               Icons.logout,
               size: ResponsiveUtils.getIconSize(context),
             ),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/auth');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.getResponsivePadding(context),
        child: Column(
          children: [
                         Align(
               alignment: Alignment.centerLeft,
               child: Text(
                 "Bienvenido, $nombre", 
                 style: TextStyle(
                   fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
                   fontWeight: FontWeight.bold,
                 ),
               ),
             ),
             SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 2.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCard("Iniciar nueva visita", "Comienza un nuevo registro de visita", Icons.add, () {
                  Navigator.pushNamed(context, '/crear-visita');
                }),
                _buildCard("Mis visitas pendientes", "Accede a visitas guardadas", Icons.assignment_late, () {
                  Navigator.pushNamed(context, '/visitas_pendientes');
                }),
              ],
            ),
                         SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCard("Historial de visitas", "Revisa tus visitas completadas", Icons.history, () {
                  Navigator.pushNamed(context, '/visitas_completas');
                }),
                _buildCard("Mi perfil", "Gestiona tu información", Icons.settings, () {
                  Navigator.pushNamed(context, '/perfil');
                }),
              ],
            ),
                         SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 2.5),
            if (visitaReciente != null && 
                visitaReciente!['sede'] != null &&
                visitaReciente!['sede'] is Map<String, dynamic>) ...[
              const Divider(),
              Padding(
                padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.getResponsiveSpacing(context)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Actividad reciente",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
                      Text(
                        "Visita iniciada: ${visitaReciente!['sede']?['nombre'] ?? 'Sede no especificada'}",
                        style: TextStyle(fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Fecha: ${visitaReciente!['fecha'] ?? 'Fecha no especificada'}",
                        style: TextStyle(fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const Divider(),
              Padding(
                padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.getResponsiveSpacing(context)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Actividad reciente",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
                      Text(
                        "No hay visitas recientes",
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}