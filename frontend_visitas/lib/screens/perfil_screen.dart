// lib/screens/perfil_screen.dart

import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/screens/about_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_visitas/screens/auth_screen.dart';
import 'package:frontend_visitas/utils/responsive_utils.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _perfilUsuario;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final perfil = await _apiService.getPerfilUsuario();
      
      setState(() {
        _perfilUsuario = perfil;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _cerrarSesion() async {
    try {
      // Mostrar diálogo de confirmación
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar'),
          content: const Text('¿Seguro que deseas cerrar sesión?\n\nEsto cerrará tu sesión actual. Tendrás que iniciar sesión de nuevo para continuar.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      );

      if (confirmar == true) {
        // Limpiar token y datos de sesión
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // Navegar a la pantalla de login (ruta nombrada)
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mi Perfil',
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error al cargar perfil',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _cargarPerfil,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final perfil = _perfilUsuario!;
    
    return SingleChildScrollView(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        children: [
          // Tarjeta de perfil principal
          _buildPerfilCard(perfil),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 3),
          
          // Información detallada
          _buildInformacionDetallada(perfil),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 3),
          
          // Acciones
          _buildAcciones(),
        ],
      ),
    );
  }

  Widget _buildPerfilCard(Map<String, dynamic> perfil) {
    final nombre = perfil['nombre'] ?? 'Usuario';
    final correo = perfil['correo'] ?? 'correo@ejemplo.com';
    final rol = perfil['rol_nombre'] ?? 'Rol';
    final avatar = ''; // Campo no disponible en la base de datos

    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveUtils.getResponsivePadding(context) * 1.5,
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: ResponsiveUtils.getResponsiveSpacing(context) * 6,
              backgroundColor: Colors.indigo[100],
              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
              child: avatar.isEmpty
                  ? Icon(
                      Icons.person,
                      size: ResponsiveUtils.getResponsiveSpacing(context) * 6,
                      color: Colors.indigo[600],
                    )
                  : null,
            ),
            
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 2),
            
            // Nombre
            Text(
              nombre,
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
            
            // Correo
            Text(
              correo,
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 1.5),
            
            // Rol
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getResponsiveSpacing(context) * 2,
                vertical: ResponsiveUtils.getResponsiveSpacing(context),
              ),
              decoration: BoxDecoration(
                color: Colors.indigo[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                rol,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformacionDetallada(Map<String, dynamic> perfil) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: ResponsiveUtils.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Personal',
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 2),
            
            _buildInfoItem(
              icon: Icons.person,
              label: 'Nombre Completo',
              value: perfil['nombre'] ?? 'No especificado',
            ),
            
            const SizedBox(height: 12),
            
            _buildInfoItem(
              icon: Icons.email,
              label: 'Correo Electrónico',
              value: perfil['correo'] ?? 'No especificado',
            ),
            
            const SizedBox(height: 12),
            

            
            _buildInfoItem(
              icon: Icons.work,
              label: 'Cargo',
              value: perfil['cargo'] ?? 'No especificado',
            ),
            
            const SizedBox(height: 12),
            

          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.indigo[600], size: ResponsiveUtils.getIconSize(context)),
        SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context) * 1.5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.25),
              Text(
                value,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAcciones() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: ResponsiveUtils.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acciones',
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 2),
            
            // Cambiar contraseña
            _buildAccionButton(
              title: 'Cambiar Contraseña',
              subtitle: 'Actualizar tu contraseña de acceso',
              icon: Icons.lock,
              color: Colors.orange,
              onTap: () {
                _mostrarDialogoCambiarContrasena();
              },
            ),
            
            const SizedBox(height: 12),
            
            // Cerrar sesión
            _buildAccionButton(
              title: 'Cerrar Sesión',
              subtitle: 'Salir de la aplicación',
              icon: Icons.logout,
              color: Colors.red,
              onTap: _cerrarSesion,
            ),

            const SizedBox(height: 12),

            // Acerca de
            _buildAccionButton(
              title: 'Acerca de',
              subtitle: 'Información de la aplicación',
              icon: Icons.info_outline,
              color: Colors.deepPurple,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AboutScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: ResponsiveUtils.getResponsivePadding(context),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context) * 1.5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: ResponsiveUtils.getIconSize(context)),
            ),
            SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context) * 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: ResponsiveUtils.getResponsiveSpacing(context)),
          ],
        ),
      ),
    );
  }



  void _mostrarDialogoCambiarContrasena() {
    final contrasenaActualController = TextEditingController();
    final contrasenaNuevaController = TextEditingController();
    final confirmarContrasenaController = TextEditingController();
    bool _obscureTextActual = true;
    bool _obscureTextNueva = true;
    bool _obscureTextConfirmar = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Cambiar Contraseña'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: contrasenaActualController,
                      obscureText: _obscureTextActual,
                      decoration: InputDecoration(
                        labelText: 'Contraseña Actual',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureTextActual ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureTextActual = !_obscureTextActual;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contrasenaNuevaController,
                      obscureText: _obscureTextNueva,
                      decoration: InputDecoration(
                        labelText: 'Nueva Contraseña',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureTextNueva ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureTextNueva = !_obscureTextNueva;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmarContrasenaController,
                      obscureText: _obscureTextConfirmar,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Nueva Contraseña',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureTextConfirmar ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureTextConfirmar = !_obscureTextConfirmar;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Mostrar requisitos de seguridad
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Requisitos de seguridad:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildRequisito('• Al menos 8 caracteres'),
                          _buildRequisito('• Al menos 1 letra mayúscula'),
                          _buildRequisito('• Al menos 1 letra minúscula'),
                          _buildRequisito('• Al menos 1 número'),
                          _buildRequisito('• Al menos 1 carácter especial (!@#\$%^&*)'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (contrasenaActualController.text.isEmpty ||
                        contrasenaNuevaController.text.isEmpty ||
                        confirmarContrasenaController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Todos los campos son obligatorios'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (contrasenaNuevaController.text != confirmarContrasenaController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Las contraseñas nuevas no coinciden'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Validar requisitos de seguridad
                    String? errorValidacion = _validarSeguridadContrasena(contrasenaNuevaController.text);
                    if (errorValidacion != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(errorValidacion),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                      return;
                    }

                    try {
                      final apiService = ApiService();
                      final success = await apiService.cambiarContrasena(
                        contrasenaActual: contrasenaActualController.text,
                        contrasenaNueva: contrasenaNuevaController.text,
                      );

                      if (success) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Contraseña actualizada exitosamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error al cambiar la contraseña'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Cambiar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  Widget _buildRequisito(String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }

  String? _validarSeguridadContrasena(String contrasena) {
    if (contrasena.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    
    if (!contrasena.contains(RegExp(r'[A-Z]'))) {
      return 'La contraseña debe contener al menos una letra mayúscula';
    }
    
    if (!contrasena.contains(RegExp(r'[a-z]'))) {
      return 'La contraseña debe contener al menos una letra minúscula';
    }
    
    if (!contrasena.contains(RegExp(r'[0-9]'))) {
      return 'La contraseña debe contener al menos un número';
    }
    
    if (!contrasena.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]'))) {
      return 'La contraseña debe contener al menos un carácter especial (!@#\$%^&*()_+-=[]{}|;:,.<>?)';
    }
    
    return null; // Contraseña válida
  }
}