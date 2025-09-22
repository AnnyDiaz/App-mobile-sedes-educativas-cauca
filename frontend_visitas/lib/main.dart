import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/register_screen.dart';
import 'screens/admin_dashboard_professional.dart';
import 'screens/admin_user_management_enhanced.dart';
import 'screens/admin_roles_management.dart';
import 'screens/admin_mass_scheduling.dart';
import 'screens/admin_exports_management.dart';
import 'screens/admin_2fa_settings.dart';
import 'screens/admin_analytics_dashboard.dart';
import 'screens/admin_notifications_management.dart';
import 'screens/admin_checklist_management_enhanced.dart';
import 'screens/visitador_home.dart';
import 'utils/responsive_theme.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';

import 'screens/perfil_screen.dart';
import 'screens/visitador_dashboard.dart';
import 'screens/supervisor_dashboard_real.dart';
import 'screens/visitas_equipo_screen.dart';
import 'screens/asignar_visitas_screen.dart';
import 'screens/reportes_supervisor_screen.dart';
import 'screens/alertas_screen.dart';
import 'screens/crear_cronograma_screen.dart';
import 'screens/crear_visita_pae_screen.dart';
import 'screens/calendario_visitas_screen.dart';
import 'screens/cronogramas_guardados_screen.dart';
import 'screens/visitas_completas_screen.dart';
import 'screens/visitas_pendientes_screen.dart';
import 'screens/visitas_asignadas_screen.dart';
import 'screens/gestion_sedes_screen.dart';
import 'screens/programar_visita_screen.dart';
import 'screens/programar_visita_visitador_screen.dart';
import 'models/institucion.dart';
import 'package:flutter/foundation.dart';
import 'utils/database_init.dart';

void main() async {
  print('🚀 Iniciando aplicación...');
  WidgetsFlutterBinding.ensureInitialized();
  print('✅ WidgetsFlutterBinding inicializado');
  
  // Inicializar la base de datos de manera global
  try {
    print('🗄️ Iniciando inicialización de base de datos...');
    await DatabaseInit.initialize();
    print('✅ Inicialización de base de datos completada exitosamente');
  } catch (e) {
    print('❌ Error crítico al inicializar base de datos: $e');
    print('⚠️ La aplicación continuará pero puede haber problemas con la base de datos local');
  }
  
  print('🎯 Ejecutando aplicación...');
  runApp(SMCApp());
}

class SMCApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'SMC VS',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/auth': (context) => const AuthScreen(),
        '/register': (context) => RegisterScreen(),
        '/admin_dashboard': (context) => AdminDashboardProfessional(),
        '/admin_usuarios': (context) => AdminUserManagementEnhanced(),
        '/admin_roles': (context) => AdminRolesManagementScreen(),
        '/admin_mass_scheduling': (context) => AdminMassSchedulingScreen(),
        '/admin_exports': (context) => AdminExportsManagementScreen(),
        '/admin_2fa': (context) => Admin2FASettingsScreen(),
        '/admin_analytics': (context) => AdminAnalyticsDashboard(),
        '/admin_notifications': (context) => AdminNotificationsManagement(),
        '/admin_checklists': (context) => AdminChecklistManagementEnhanced(),
        '/visitador_dashboard': (context) => VisitadorDashboard(),
        '/supervisor_dashboard': (context) => SupervisorDashboardReal(),
        '/supervisor_dashboard_real': (context) => SupervisorDashboardReal(),
        '/visitas_equipo': (context) => VisitasEquipoScreen(),
        '/asignar_visitas': (context) => AsignarVisitasScreen(),
        '/reportes_supervisor': (context) => ReportesSupervisorScreen(),
        '/alertas_supervisor': (context) => AlertasScreen(),
        '/visitador': (context) => const VisitadorHome(),

        '/perfil': (context) => const PerfilScreen(),
        '/crear_cronograma': (context) => CrearCronogramaScreen(),
        '/crear_visita_pae': (context) => const CrearVisitaPAEScreen(),
        '/calendario_visitas': (context) => const CalendarioVisitasScreen(),
        '/cronogramas_guardados': (context) => const CronogramasGuardadosScreen(),
        '/visitas_completas': (context) => const VisitasCompletasScreen(),
        '/visitas_pendientes': (context) => const VisitasPendientesScreen(),
        '/visitas_asignadas': (context) => const VisitasAsignadasScreen(),
        '/gestion_sedes': (context) => const GestionSedesScreen(),
        '/programar_visita': (context) => const ProgramarVisitaScreen(),
        '/programar_visita_visitador': (context) => const ProgramarVisitaVisitadorScreen(),
      },
    );
        },
      ),
    );
  }
}