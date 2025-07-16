import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/admin_dashboard.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/visitador_dashboard.dart';
import 'screens/pendientes_screen.dart';
import 'screens/historial_screen.dart';
import 'screens/visitador_home.dart';
import 'screens/crear_visita_screen.dart';
import 'screens/supervisor_dashboard.dart';
import 'screens/perfil_screen.dart';

void main() {
  runApp(SMCApp());
}

class SMCApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMC VS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF008BE8),
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/admin_dashboard': (context) => AdminDashboard(),
        '/supervisor_dashboard': (context) => SupervisorDashboard(),
        '/visitador_dashboard': (context) => VisitadorDashboard(),
        '/visitador': (context) => const VisitadorHome(),
         '/crear-visita': (context) => const CrearVisitaScreen(),
        '/pendientes': (context) => const PendientesScreen(),
        '/historial': (context) => const HistorialScreen(),
        '/perfil': (context) => const PerfilScreen(),
      },
    );
  }
}