import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/models/usuario.dart';

class GestionUsuariosScreen extends StatefulWidget {
  const GestionUsuariosScreen({super.key});

  @override
  State<GestionUsuariosScreen> createState() => _GestionUsuariosScreenState();
}

class _GestionUsuariosScreenState extends State<GestionUsuariosScreen> {
  final ApiService _apiService = ApiService();
  List<Usuario> _usuarios = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final usuarios = await _apiService.getTodosUsuarios();
      setState(() {
        _usuarios = usuarios;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarUsuarios,
            tooltip: 'Actualizar',
          ),
        ],
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
            'Error al cargar usuarios',
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
            onPressed: _cargarUsuarios,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Resumen de usuarios
        _buildResumenUsuarios(),
        
        // Lista de usuarios
        Expanded(
          child: _usuarios.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _usuarios.length,
                  itemBuilder: (context, index) {
                    final usuario = _usuarios[index];
                    return _buildUsuarioCard(usuario);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildResumenUsuarios() {
    final totalUsuarios = _usuarios.length;
    final usuariosActivos = _usuarios.where((u) => u.activo == true).length;
    final supervisores = _usuarios.where((u) => u.rol == 'supervisor').length;
    final visitadores = _usuarios.where((u) => u.rol == 'visitador').length;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, size: 32, color: Colors.purple),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen de Usuarios',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Gestión de usuarios del sistema',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Total', totalUsuarios.toString(), Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem('Activos', usuariosActivos.toString(), Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Supervisores', supervisores.toString(), Colors.purple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem('Visitadores', visitadores.toString(), Colors.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay usuarios registrados',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los usuarios aparecerán aquí cuando se registren',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsuarioCard(Usuario usuario) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getColorForRol(usuario.rol).withOpacity(0.1),
              child: Icon(
                _getIconForRol(usuario.rol),
                color: _getColorForRol(usuario.rol),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usuario.nombre,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    usuario.correo,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getColorForRol(usuario.rol).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          usuario.rol?.toUpperCase() ?? 'SIN ROL',
                          style: TextStyle(
                            color: _getColorForRol(usuario.rol),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (usuario.activo == true ? Colors.green : Colors.red).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          usuario.activo == true ? 'ACTIVO' : 'INACTIVO',
                          style: TextStyle(
                            color: usuario.activo == true ? Colors.green : Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForRol(String? rol) {
    switch (rol?.toLowerCase()) {
      case 'supervisor':
        return Colors.purple;
      case 'visitador':
        return Colors.orange;
      case 'admin':
      case 'super administrador':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForRol(String? rol) {
    switch (rol?.toLowerCase()) {
      case 'supervisor':
        return Icons.admin_panel_settings;
      case 'visitador':
        return Icons.person;
      case 'admin':
      case 'super administrador':
        return Icons.security;
      default:
        return Icons.person_outline;
    }
  }
} 