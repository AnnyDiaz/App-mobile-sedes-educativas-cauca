import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_visitas/screens/olvidaste_contrasena_screen.dart';
import 'package:frontend_visitas/services/api_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Controllers para los campos
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  // Variables para validación
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _passwordError;
  String? _confirmPasswordError;
  bool _loading = false;
  String? _error;

  // Variables para validación de email
  String? _emailError;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    // Limpiar errores y campos al cambiar de pestaña
    if (_tabController.indexIsChanging) {
      setState(() {
        _error = null;
        _emailError = null;
        _passwordError = null;
        _confirmPasswordError = null;
        _nameError = null;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Método para validar email
  String? _validateEmail(String email) {
    if (email.isEmpty) {
      return 'El correo electrónico es requerido';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    if (!emailRegex.hasMatch(email)) {
      return 'Ingresa un correo electrónico válido';
    }
    return null;
  }

  // Método para validar nombre
  String? _validateName(String name) {
    if (name.isEmpty) {
      return 'El nombre es requerido';
    }
    if (name.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    return null;
  }

  // Método para validar la contraseña
  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Debe contener al menos una mayúscula';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Debe contener al menos una minúscula';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Debe contener al menos un número';
    }
    if (!password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]'))) {
      return 'Debe contener al menos un carácter especial (!@#\$%^&*()_+-=[]{}|;:,.<>?)';
    }
    return null;
  }

  // Método para validar confirmación de contraseña
  String? _validateConfirmPassword(String confirmPassword) {
    if (confirmPassword.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (confirmPassword != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  // Método para validar formulario de login
  bool _validateLoginForm() {
    setState(() {
      _emailError = _validateEmail(_emailController.text);
      // En login solo validamos que la contraseña no esté vacía
      _passwordError = _passwordController.text.isEmpty ? 'La contraseña es requerida' : null;
    });
    
    return _emailError == null && _passwordError == null;
  }

  // Método para validar formulario de registro
  bool _validateRegisterForm() {
    setState(() {
      _nameError = _validateName(_nameController.text);
      _emailError = _validateEmail(_emailController.text);
      _passwordError = _validatePassword(_passwordController.text);
      _confirmPasswordError = _validateConfirmPassword(_confirmPasswordController.text);
    });
    
    return _nameError == null && 
           _emailError == null && 
           _passwordError == null && 
           _confirmPasswordError == null;
  }

  // Método para login
  void _login() async {
    if (!_validateLoginForm()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final correo = _emailController.text.trim();
    final contrasena = _passwordController.text.trim();

    try {
      print('🔍 Intentando login con: $correo');
      final apiService = ApiService();
      final data = await apiService.login(correo, contrasena);
      print('📦 Respuesta del servidor: $data');

      if (data['access_token'] != null) {
        final usuario = data['usuario'];
        final String rol = (usuario['rol']['nombre'] as String).toLowerCase();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['access_token']);
        await prefs.setString('rol', rol);
        await prefs.setString('user_id', usuario['id'].toString());
        await prefs.setString('user_name', usuario['nombre']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Inicio de sesión exitoso")),
          );

          switch (rol) {
            case "admin":
            case "super administrador":
              Navigator.pushReplacementNamed(context, '/admin_dashboard');
              break;
            case "supervisor":
              Navigator.pushReplacementNamed(context, '/supervisor_dashboard_real');
              break;
            case "visitador":
              Navigator.pushReplacementNamed(context, '/visitador_dashboard');
              break;
            default:
              setState(() {
                _error = 'Rol de usuario desconocido: "$rol"';
                _loading = false;
              });
          }
        }
      } else {
        setState(() {
          _error = data['message'] ?? 'Correo o contraseña inválidos';
          _loading = false;
        });
      }
    } catch (e) {
      print('❌ Error en login: $e');
      setState(() {
        _loading = false;
        _error = 'Error al iniciar sesión: ${e.toString()}';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // Método para registro
  void _register() async {
    if (!_validateRegisterForm()) {
      setState(() {
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final nombre = _nameController.text.trim();
    final correo = _emailController.text.trim();
    final contrasena = _passwordController.text.trim();

    try {
      final apiService = ApiService();
      final data = await apiService.register(nombre, correo, contrasena);

      if (data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Registro exitoso. Inicia sesión."),
              backgroundColor: Colors.green,
            ),
          );
          
          // Limpiar formulario de registro
          _nameController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
          
          _tabController.animateTo(0); // Cambiar a la pestaña de login
        }
      } else {
        setState(() {
          _error = data['message'] ?? 'Error en el registro';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error en el registro. Intenta nuevamente.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // Navegar a pantalla de olvidaste contraseña
  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OlvidasteContrasenaScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: Column(
              children: [
                // Logo
                Image.asset(
                  "assets/images/logo.png",
                  height: 60,
                ),
                const SizedBox(height: 15),

                // Títulos
                const Text(
                  "SMC VS",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Gobernación del Cauca",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 15),

                // Tabs login / registro
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.lightBlue,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.symmetric(horizontal: 00, vertical: 0),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black54,
                    tabs: const [
                      Tab(text: "Iniciar sesión"),
                      Tab(text: "Registrarse"),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // Mensaje de error
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Contenido de cada tab
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // --- LOGIN ---
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Bienvenido",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 15),

                          // Email
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: "Correo electrónico",
                              prefixIcon: const Icon(Icons.email_outlined),
                              errorText: _emailError,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide(color: Colors.lightBlue),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Password
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: "Contraseña",
                              prefixIcon: const Icon(Icons.lock_outline),
                              errorText: _passwordError,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide(color: Colors.lightBlue),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Botón Ingresar
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _loading ? null : _login,
                            child: _loading 
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Ingresar",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.white),
                                ),
                          ),
                          const SizedBox(height: 8),

                          // Olvidaste contraseña
                          TextButton(
                            onPressed: _navigateToForgotPassword,
                            child: const Text(
                              "¿Olvidaste tu contraseña?",
                              style: TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                          ),
                        ],
                      ),

                      // --- REGISTRO ---
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              "Crear cuenta",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 15),

                            // Nombre
                            TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: "Nombre completo",
                                prefixIcon: const Icon(Icons.person_outline),
                                errorText: _nameError,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide(color: Colors.lightBlue),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Email
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: "Correo electrónico",
                                prefixIcon: const Icon(Icons.email_outlined),
                                errorText: _emailError,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide(color: Colors.lightBlue),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Password
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              onChanged: (value) {
                                setState(() {
                                  _passwordError = _validatePassword(value);
                                });
                              },
                              decoration: InputDecoration(
                                hintText: "Contraseña",
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                errorText: _passwordError,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide(color: Colors.lightBlue),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Confirmar Password
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              onChanged: (value) {
                                setState(() {
                                  _confirmPasswordError = _validateConfirmPassword(value);
                                });
                              },
                              decoration: InputDecoration(
                                hintText: "Confirmar contraseña",
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                                errorText: _confirmPasswordError,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide(color: Colors.lightBlue),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Requisitos de contraseña
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "La contraseña debe contener:",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "• Al menos 8 caracteres\n• Una mayúscula\n• Una minúscula\n• Un número\n• Un carácter especial",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 15),

                            // Botón Registrarse
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.lightBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: _loading ? null : _register,
                              child: _loading 
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Registrarse",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.white),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}