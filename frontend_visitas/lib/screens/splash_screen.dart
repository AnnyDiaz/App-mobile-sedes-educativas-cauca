import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/permission_service.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/utils/responsive_utils.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isLoading = true;
  String _statusMessage = 'Iniciando aplicación...';
  Map<String, bool> _permissionResults = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // 1. Verificar autenticación
      setState(() {
        _statusMessage = 'Verificando autenticación...';
      });
      
      final isAuthenticated = await ApiService().isAuthenticated();
      
      if (isAuthenticated) {
        setState(() {
          _statusMessage = 'Solicitando permisos...';
        });
        
        // 2. Verificar y solicitar permisos
        _permissionResults = await PermissionService.checkAndRequestPermissions();
        
        // 3. Verificar si hay permisos denegados
        final deniedPermissions = _permissionResults.entries
            .where((entry) => !entry.value)
            .map((entry) => entry.key)
            .toList();
        
        if (deniedPermissions.isNotEmpty) {
          setState(() {
            _statusMessage = 'Permisos requeridos...';
          });
          
          // Mostrar diálogo de permisos denegados
          await PermissionService.showPermissionDeniedDialog(context, deniedPermissions);
          
          // Verificar nuevamente después del diálogo
          _permissionResults = await PermissionService.checkAndRequestPermissions();
        }
        
        setState(() {
          _statusMessage = 'Iniciando aplicación...';
        });
        
        // 4. Navegar al dashboard apropiado
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/visitador_dashboard');
        }
      } else {
        setState(() {
          _statusMessage = 'Redirigiendo al login...';
        });
        
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/auth');
        }
      }
    } catch (e) {
      print('❌ Error en inicialización: $e');
      setState(() {
        _statusMessage = 'Error al inicializar...';
        _isLoading = false;
      });
      
      // En caso de error, redirigir al login
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo animado
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: ResponsiveUtils.screenHeight(context) * 0.15,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Título animado
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Text(
                        'SMC VS',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 28),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Subtítulo
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Text(
                        'Sistema de Monitoreo y Control de Visitas',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 60),

                // Indicador de carga
                if (_isLoading) ...[
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ],

                // Estado de permisos (si no está cargando)
                if (!_isLoading && _permissionResults.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildPermissionStatus(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionStatus() {
    return Column(
      children: [
        const Text(
          'Estado de Permisos:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ..._permissionResults.entries.map((entry) {
          final permission = entry.key;
          final granted = entry.value;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  granted ? Icons.check_circle : Icons.cancel,
                  color: granted ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _getPermissionDisplayName(permission),
                  style: TextStyle(
                    fontSize: 14,
                    color: granted ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _getPermissionDisplayName(String permission) {
    switch (permission) {
      case 'location':
        return 'Ubicación';
      case 'camera':
        return 'Cámara';
      case 'storage':
        return 'Almacenamiento';
      default:
        return permission;
    }
  }
}
