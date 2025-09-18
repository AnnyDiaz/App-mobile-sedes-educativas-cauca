import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend_visitas/providers/theme_provider.dart';
import 'package:frontend_visitas/theme/app_theme.dart';

/// Ejemplo de cómo implementar modo oscuro en cualquier pantalla
/// 
/// Este archivo muestra las mejores prácticas para:
/// 1. Usar Consumer<ThemeProvider> para acceder al tema
/// 2. Aplicar colores dinámicos basados en el tema
/// 3. Usar widgets temáticos como ThemeAwareContainer
/// 4. Implementar botones de cambio de tema
class ExampleDarkModeScreen extends StatelessWidget {
  const ExampleDarkModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDark;
        final roleColor = AppTheme.getRoleColor('admin', isDark); // Cambiar según el rol
        
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: AppBar(
            title: const Text('Ejemplo Modo Oscuro'),
            backgroundColor: roleColor,
            foregroundColor: Colors.white,
            actions: [
              // Botón de cambio de tema
              IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título principal
                Text(
                  'Implementación de Modo Oscuro',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.getTextColor(isDark),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Descripción
                Text(
                  'Esta pantalla muestra cómo implementar el modo oscuro de manera consistente en toda la aplicación.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.getTextColor(isDark, isPrimary: false),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Sección de colores
                _buildColorsSection(context, isDark),
                const SizedBox(height: 24),
                
                // Sección de widgets
                _buildWidgetsSection(context, isDark),
                const SizedBox(height: 24),
                
                // Sección de estados
                _buildStatusSection(context, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorsSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🎨 Colores del Tema',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.getTextColor(isDark),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Grid de colores
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildColorCard('Admin', AppTheme.getRoleColor('admin', isDark)),
            _buildColorCard('Supervisor', AppTheme.getRoleColor('supervisor', isDark)),
            _buildColorCard('Visitador', AppTheme.getRoleColor('visitador', isDark)),
            _buildColorCard('Visitante', AppTheme.getRoleColor('visitante', isDark)),
          ],
        ),
      ],
    );
  }

  Widget _buildWidgetsSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🧩 Widgets Temáticos',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.getTextColor(isDark),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Cards con diferentes estilos
        Card(
          color: AppTheme.getCardBackgroundColor(isDark),
          child: ListTile(
            leading: Icon(
              Icons.check_circle,
              color: AppTheme.getStatusColor('success', isDark),
            ),
            title: Text(
              'Card con tema automático',
              style: TextStyle(color: AppTheme.getTextColor(isDark)),
            ),
            subtitle: Text(
              'Se adapta automáticamente al tema',
              style: TextStyle(color: AppTheme.getTextColor(isDark, isPrimary: false)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Botones temáticos
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.getRoleColor('admin', isDark),
                ),
                child: const Text('Botón Primario'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.getTextColor(isDark),
                  side: BorderSide(color: AppTheme.getRoleColor('admin', isDark)),
                ),
                child: const Text('Botón Secundario'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 Estados y Colores',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.getTextColor(isDark),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Estados con colores
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildStatusChip('Completada', 'success', isDark),
            _buildStatusChip('Pendiente', 'warning', isDark),
            _buildStatusChip('Cancelada', 'error', isDark),
            _buildStatusChip('En Proceso', 'info', isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildColorCard(String label, Color color) {
    return Card(
      color: color,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.circle,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String status, bool isDark) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: AppTheme.getStatusColor(status, isDark),
      avatar: Icon(
        _getStatusIcon(status),
        color: Colors.white,
        size: 16,
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'success':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      case 'info':
        return Icons.info;
      default:
        return Icons.help;
    }
  }
}

/// Widgets reutilizables para modo oscuro
class DarkModeWidgets {
  /// Container que se adapta automáticamente al tema
  static Widget themedContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    BoxBorder? border,
  }) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDark;
        return Container(
          padding: padding,
          margin: margin,
          decoration: BoxDecoration(
            color: AppTheme.getCardBackgroundColor(isDark),
            borderRadius: borderRadius,
            border: border,
          ),
          child: this.child,
        );
      },
    );
  }

  /// Texto que se adapta al tema
  static Widget themedText(
    String text, {
    TextStyle? style,
    bool isPrimary = true,
  }) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDark;
        return Text(
          text,
          style: style?.copyWith(
            color: AppTheme.getTextColor(isDark, isPrimary: isPrimary),
          ) ?? TextStyle(
            color: AppTheme.getTextColor(isDark, isPrimary: isPrimary),
          ),
        );
      },
    );
  }
}
