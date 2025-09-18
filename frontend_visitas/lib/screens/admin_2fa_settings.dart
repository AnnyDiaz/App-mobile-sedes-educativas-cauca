import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_visitas/config.dart';

class Admin2FASettingsScreen extends StatefulWidget {
  @override
  _Admin2FASettingsScreenState createState() => _Admin2FASettingsScreenState();
}

class _Admin2FASettingsScreenState extends State<Admin2FASettingsScreen> {
  bool _isLoading = true;
  bool _is2FAEnabled = false;
  String _error = '';
  
  // Setup variables
  bool _isSetupMode = false;
  String? _qrCodeImage;
  String? _manualEntryKey;
  List<String> _backupCodes = [];
  
  // Controllers
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _verifyCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _verifyCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/2fa/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _is2FAEnabled = data['enabled'] ?? false;
        });
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar estado: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _setupTwoFA() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/2fa/setup'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _isSetupMode = true;
          _qrCodeImage = data['qr_code'];
          _manualEntryKey = data['manual_entry_key'];
          _backupCodes = List<String>.from(data['backup_codes']);
        });
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _error = 'Error al configurar 2FA: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifySetup() async {
    if (_verifyCodeController.text.length != 6) {
      _showSnackBar('Ingresa un código de 6 dígitos');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/2fa/verify-setup'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'code': _verifyCodeController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _is2FAEnabled = true;
            _isSetupMode = false;
          });
          _showSuccessDialog();
        }
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _disable2FA() async {
    final code = await _showCodeInputDialog(
      title: 'Deshabilitar 2FA',
      message: 'Ingresa tu código 2FA para confirmar:',
    );

    if (code == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/2fa/disable'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'code': code,
          'action': 'disable_2fa',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _is2FAEnabled = false;
          });
          _showSnackBar('2FA deshabilitado exitosamente');
        }
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _viewBackupCodes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/2fa/backup-codes'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _showBackupCodesDialog(data['backup_codes'], data['remaining']);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<String?> _showCodeInputDialog({
    required String title,
    required String message,
  }) async {
    final TextEditingController controller = TextEditingController();
    
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 8,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'Código 2FA',
                hintText: '123456',
                border: OutlineInputBorder(),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context, controller.text);
              }
            },
            child: Text('Verificar'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('¡2FA Configurado!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('La autenticación de dos factores ha sido configurada exitosamente.'),
            SizedBox(height: 16),
            Text('Códigos de respaldo:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Se han generado códigos de respaldo por si pierdes acceso a tu dispositivo.'),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showBackupCodesDialog(_backupCodes, _backupCodes.length);
              },
              icon: Icon(Icons.security),
              label: Text('Ver códigos de respaldo'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showBackupCodesDialog(List<dynamic> codes, int remaining) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Códigos de Respaldo'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Códigos restantes: $remaining'),
              SizedBox(height: 8),
              Text(
                'Guarda estos códigos en un lugar seguro. Cada uno solo se puede usar una vez.',
                style: TextStyle(color: Colors.orange),
              ),
              SizedBox(height: 16),
              Container(
                height: 200,
                child: ListView.builder(
                  itemCount: codes.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListTile(
                        title: Text(
                          codes[index],
                          style: TextStyle(fontFamily: 'monospace'),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: codes[index]));
                            _showSnackBar('Código copiado');
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              String allCodes = codes.join('\n');
              Clipboard.setData(ClipboardData(text: allCodes));
              _showSnackBar('Todos los códigos copiados');
            },
            child: Text('Copiar Todos'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Uint8List? _decodeQRImage(String base64String) {
    try {
      // Remover el prefijo data:image/png;base64,
      String cleanBase64 = base64String.split(',').last;
      return base64Decode(cleanBase64);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración 2FA'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(_error, textAlign: TextAlign.center),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStatus,
                        child: Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _isSetupMode
                  ? _buildSetupView()
                  : _buildMainView(),
    );
  }

  Widget _buildMainView() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _is2FAEnabled ? Icons.security : Icons.security_outlined,
                    color: _is2FAEnabled ? Colors.green : Colors.grey,
                    size: 32,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Autenticación de Dos Factores',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _is2FAEnabled 
                              ? 'Habilitada - Tu cuenta está protegida'
                              : 'Deshabilitada - Configúrala para mayor seguridad',
                          style: TextStyle(
                            color: _is2FAEnabled ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _is2FAEnabled,
                    onChanged: (value) {
                      if (value) {
                        _setupTwoFA();
                      } else {
                        _disable2FA();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),

          // Information Card
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        '¿Qué es 2FA?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'La autenticación de dos factores (2FA) añade una capa extra de seguridad '
                    'a tu cuenta. Además de tu contraseña, necesitarás un código temporal '
                    'generado por una app en tu teléfono.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '• Protege tu cuenta incluso si tu contraseña es comprometida\n'
                    '• Usa apps como Google Authenticator o Authy\n'
                    '• Códigos de respaldo para emergencias',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          if (_is2FAEnabled) ...[
            SizedBox(height: 24),
            Text(
              'Gestión de 2FA',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            // Actions
            ListTile(
              leading: Icon(Icons.backup, color: Colors.orange),
              title: Text('Códigos de Respaldo'),
              subtitle: Text('Ver códigos de emergencia'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: _viewBackupCodes,
            ),
            
            Divider(),
            
            ListTile(
              leading: Icon(Icons.security_update_warning, color: Colors.red),
              title: Text('Deshabilitar 2FA'),
              subtitle: Text('Remover protección adicional'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () => _disable2FA(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSetupView() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            LinearProgressIndicator(value: 0.5),
            SizedBox(height: 16),
            
            Text(
              'Configurar 2FA',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            
            Text(
              'Paso 1: Escanea el código QR con tu app de autenticación',
              style: TextStyle(fontSize: 16),
            ),
            
            SizedBox(height: 24),
            
            // QR Code
            if (_qrCodeImage != null)
              Center(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Image.memory(
                    _decodeQRImage(_qrCodeImage!)!,
                    width: 200,
                    height: 200,
                  ),
                ),
              ),
            
            SizedBox(height: 24),
            
            // Manual entry
            Text(
              'O ingresa manualmente:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            
            if (_manualEntryKey != null)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _manualEntryKey!,
                        style: TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _manualEntryKey!));
                        _showSnackBar('Clave copiada');
                      },
                    ),
                  ],
                ),
              ),
            
            SizedBox(height: 32),
            
            Text(
              'Paso 2: Ingresa el código de 6 dígitos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            
            SizedBox(height: 16),
            
            TextField(
              controller: _verifyCodeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Código de verificación',
                hintText: '123456',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.security),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            
            SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isSetupMode = false;
                      });
                    },
                    child: Text('Cancelar'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _verifySetup,
                    child: Text('Verificar y Activar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
