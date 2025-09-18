import 'package:flutter/material.dart';
import 'package:frontend_visitas/utils/responsive_utils.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Gobernación
                Image.asset(
                  'assets/images/logo.png',
                  height: ResponsiveUtils.screenHeight(context) * 0.15,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 40),

                // Título principal
                Text(
                  'SMC VS',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 28),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Subtítulo
                

                const SizedBox(height: 60),

                // Botón iniciar sesión
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/auth');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90E2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'Iniciar Sesion',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Enlace de registro
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/auth');
                  },
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                        color: Colors.black87,
                      ),
                      children: [
                        const TextSpan(text: "¿No tienes cuenta? "),
                        TextSpan(
                          text: 'Registrarse',
                          style: const TextStyle(
                            color: Color(0xFF4A90E2),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
