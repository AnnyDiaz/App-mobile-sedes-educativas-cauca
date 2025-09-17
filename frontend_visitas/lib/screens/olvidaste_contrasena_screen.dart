import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';

class OlvidasteContrasenaScreen extends StatefulWidget {
  const OlvidasteContrasenaScreen({super.key});

  @override
  State<OlvidasteContrasenaScreen> createState() => _OlvidasteContrasenaScreenState();
}

class _OlvidasteContrasenaScreenState extends State<OlvidasteContrasenaScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codigoController = TextEditingController();
  final _nuevaContrasenaController = TextEditingController();
  final _confirmarContrasenaController = TextEditingController();
  
  bool _isLoading = false;
  bool _codigoEnviado = false;
  bool _codigoVerificado = false;
  String? _error;
  String? _mensaje;

  @override
  void dispose() {
    _emailController.dispose();
    _codigoController.dispose();
    _nuevaContrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    super.dispose();
  }

  // Validar seguridad de contraseña
  String? _validarSeguridadContrasena(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa una contraseña';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'La contraseña debe contener al menos una mayúscula';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'La contraseña debe contener al menos una minúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'La contraseña debe contener al menos un número';
    }
    if (!RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]').hasMatch(value)) {
      return 'La contraseña debe contener al menos un carácter especial';
    }
    return null;
  }

  // Construir indicador de requisito
  Widget _buildRequisito(String texto, bool cumplido) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            cumplido ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: cumplido ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              color: cumplido ? Colors.green : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enviarCodigo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _apiService.enviarCodigoRecuperacion(_emailController.text.trim());
      
      setState(() {
        _codigoEnviado = true;
        _mensaje = 'Código de verificación enviado a ${_emailController.text.trim()}';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mensaje!),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Error al enviar código: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _verificarCodigo() async {
    if (_codigoController.text.isEmpty) {
      setState(() {
        _error = 'Por favor ingresa el código de verificación';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _apiService.verificarCodigoRecuperacion(
        _emailController.text.trim(),
        _codigoController.text.trim(),
      );
      
      setState(() {
        _codigoVerificado = true;
        _mensaje = 'Código verificado correctamente';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mensaje!),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Código incorrecto. Por favor verifica e intenta nuevamente';
        _isLoading = false;
      });
    }
  }

  Future<void> _cambiarContrasena() async {
    if (!_formKey.currentState!.validate()) return;

    if (_nuevaContrasenaController.text != _confirmarContrasenaController.text) {
      setState(() {
        _error = 'Las contraseñas no coinciden';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _apiService.cambiarContrasenaConCodigo(
        _emailController.text.trim(),
        _codigoController.text.trim(),
        _nuevaContrasenaController.text,
      );
      
      setState(() {
        _mensaje = 'Contraseña cambiada exitosamente';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mensaje!),
          backgroundColor: Colors.green,
        ),
      );

      // Regresar a la pantalla de login
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = 'Error al cambiar contraseña: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Icono y título
              const Icon(
                Icons.lock_reset,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa tu correo electrónico y te enviaremos un código de verificación',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Campo de email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  hintText: 'ejemplo@correo.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu correo electrónico';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Por favor ingresa un correo válido';
                  }
                  return null;
                },
                enabled: !_codigoEnviado,
              ),
              const SizedBox(height: 16),

              // Botón enviar código
              if (!_codigoEnviado)
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _enviarCodigo,
                  icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                  label: Text(_isLoading ? 'Enviando...' : 'Enviar Código'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

              // Sección de código de verificación
              if (_codigoEnviado) ...[
                const SizedBox(height: 24),
                const Text(
                  'Código de Verificación',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ingresa el código de 6 dígitos que enviamos a tu correo',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _codigoController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Código de Verificación',
                    hintText: '123456',
                    prefixIcon: Icon(Icons.security),
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  enabled: !_codigoVerificado,
                ),
                const SizedBox(height: 16),

                // Botón verificar código
                if (!_codigoVerificado)
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _verificarCodigo,
                    icon: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified),
                    label: Text(_isLoading ? 'Verificando...' : 'Verificar Código'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),

                // Sección de nueva contraseña
                if (_codigoVerificado) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Nueva Contraseña',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _nuevaContrasenaController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nueva Contraseña',
                      hintText: 'Ingresa tu nueva contraseña',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    validator: _validarSeguridadContrasena,
                    onChanged: (value) {
                      setState(() {}); // Actualizar indicadores en tiempo real
                    },
                  ),
                  
                  // Indicadores de requisitos de contraseña
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Requisitos de contraseña:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildRequisito('Al menos 8 caracteres', _nuevaContrasenaController.text.length >= 8),
                        _buildRequisito('Una mayúscula', RegExp(r'[A-Z]').hasMatch(_nuevaContrasenaController.text)),
                        _buildRequisito('Una minúscula', RegExp(r'[a-z]').hasMatch(_nuevaContrasenaController.text)),
                        _buildRequisito('Un número', RegExp(r'[0-9]').hasMatch(_nuevaContrasenaController.text)),
                        _buildRequisito('Un carácter especial', RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]').hasMatch(_nuevaContrasenaController.text)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _confirmarContrasenaController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar Contraseña',
                      hintText: 'Confirma tu nueva contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor confirma tu contraseña';
                      }
                      if (value != _nuevaContrasenaController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Botón cambiar contraseña
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _cambiarContrasena,
                    icon: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle),
                    label: Text(_isLoading ? 'Cambiando...' : 'Cambiar Contraseña'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ],

              // Mensajes de error o éxito
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_mensaje != null && _error == null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _mensaje!,
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Botón regresar al login
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Regresar al Login'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 