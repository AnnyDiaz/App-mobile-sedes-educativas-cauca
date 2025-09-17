import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';

class DobleAutenticacionWidget extends StatefulWidget {
  final String titulo;
  final String mensaje;
  final Function(String) onAutenticacionExitosa;
  final VoidCallback onCancelar;

  const DobleAutenticacionWidget({
    super.key,
    required this.titulo,
    required this.mensaje,
    required this.onAutenticacionExitosa,
    required this.onCancelar,
  });

  @override
  State<DobleAutenticacionWidget> createState() => _DobleAutenticacionWidgetState();
}

class _DobleAutenticacionWidgetState extends State<DobleAutenticacionWidget> {
  final _formKey = GlobalKey<FormState>();
  final _contrasenaController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isVerificando = false;
  bool _mostrarContrasena = false;
  String? _error;

  @override
  void dispose() {
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _verificarContrasena() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isVerificando = true;
      _error = null;
    });

    try {
      // Verificar la contraseña del usuario actual
      final perfil = await _apiService.getPerfilUsuario();
      final correo = perfil['correo'];
      
      // Intentar hacer login con las credenciales proporcionadas
      await _apiService.login(correo, _contrasenaController.text);
      
      // Si llega aquí, la contraseña es correcta
      if (mounted) {
        widget.onAutenticacionExitosa(_contrasenaController.text);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Contraseña incorrecta. Verifique e intente nuevamente.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerificando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.security, color: Colors.orange[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.titulo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.mensaje,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            
            Text(
              'Confirme su contraseña para continuar:',
              style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            
            TextFormField(
              controller: _contrasenaController,
              obscureText: !_mostrarContrasena,
              enabled: !_isVerificando,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _mostrarContrasena ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _mostrarContrasena = !_mostrarContrasena;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese su contraseña';
                }
                return null;
              },
              onFieldSubmitted: (_) => _verificarContrasena(),
            ),
            
            if (_error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.red[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isVerificando ? null : widget.onCancelar,
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isVerificando ? null : _verificarContrasena,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[600],
            foregroundColor: Colors.white,
          ),
          child: _isVerificando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Verificar'),
        ),
      ],
    );
  }
}

/// Función helper para mostrar el diálogo de doble autenticación
Future<String?> mostrarDobleAutenticacion({
  required BuildContext context,
  required String titulo,
  required String mensaje,
}) async {
  String? contrasenaVerificada;
  
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return DobleAutenticacionWidget(
        titulo: titulo,
        mensaje: mensaje,
        onAutenticacionExitosa: (contrasena) {
          contrasenaVerificada = contrasena;
          Navigator.of(context).pop();
        },
        onCancelar: () {
          Navigator.of(context).pop();
        },
      );
    },
  );
  
  return contrasenaVerificada;
}
