import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend_visitas/providers/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  final IconData? icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? size;

  const ThemeToggleButton({
    super.key,
    this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDark;
        final currentIcon = icon ?? (isDark ? Icons.light_mode : Icons.dark_mode);
        final currentTooltip = tooltip ?? (isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro');
        
        return IconButton(
          icon: Icon(currentIcon),
          onPressed: () => themeProvider.toggleTheme(),
          tooltip: currentTooltip,
          style: IconButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            iconSize: size ?? 24,
          ),
        );
      },
    );
  }
}

class ThemeModeSelector extends StatelessWidget {
  final bool showLabel;
  final EdgeInsetsGeometry? padding;

  const ThemeModeSelector({
    super.key,
    this.showLabel = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return PopupMenuButton<ThemeMode>(
          icon: Icon(
            themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          tooltip: 'Seleccionar tema',
          onSelected: themeProvider.setThemeMode,
          itemBuilder: (context) => [
            PopupMenuItem<ThemeMode>(
              value: ThemeMode.light,
              child: Row(
                children: [
                  Icon(Icons.light_mode, color: Colors.orange),
                  if (showLabel) ...[
                    const SizedBox(width: 8),
                    const Text('Claro'),
                  ],
                ],
              ),
            ),
            PopupMenuItem<ThemeMode>(
              value: ThemeMode.dark,
              child: Row(
                children: [
                  Icon(Icons.dark_mode, color: Colors.indigo),
                  if (showLabel) ...[
                    const SizedBox(width: 8),
                    const Text('Oscuro'),
                  ],
                ],
              ),
            ),
            PopupMenuItem<ThemeMode>(
              value: ThemeMode.system,
              child: Row(
                children: [
                  Icon(Icons.settings_system_daydream, color: Colors.grey),
                  if (showLabel) ...[
                    const SizedBox(width: 8),
                    const Text('Sistema'),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class ThemeAwareContainer extends StatelessWidget {
  final Widget child;
  final Color? lightColor;
  final Color? darkColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final BoxBorder? border;

  const ThemeAwareContainer({
    super.key,
    required this.child,
    this.lightColor,
    this.darkColor,
    this.padding,
    this.margin,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDark;
        final backgroundColor = isDark 
            ? (darkColor ?? Theme.of(context).colorScheme.surface)
            : (lightColor ?? Theme.of(context).colorScheme.surface);

        return Container(
          padding: padding,
          margin: margin,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
            border: border,
          ),
          child: this.child,
        );
      },
    );
  }
}
