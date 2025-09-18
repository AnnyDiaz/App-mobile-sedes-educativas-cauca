import 'package:flutter/material.dart';

class RestriccionSupervisorWidget extends StatelessWidget {
  final String accion;
  final String motivo;
  final IconData icon;
  final Color? color;

  const RestriccionSupervisorWidget({
    super.key,
    required this.accion,
    required this.motivo,
    this.icon = Icons.block,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorFinal = color ?? Colors.orange[600]!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colorFinal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorFinal.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: colorFinal,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acción Restringida: $accion',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorFinal,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  motivo,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar restricciones específicas del supervisor
class RestriccionEliminarWidget extends StatelessWidget {
  const RestriccionEliminarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const RestriccionSupervisorWidget(
      accion: 'Eliminar Registros',
      motivo: 'Los supervisores no pueden eliminar registros por motivos de seguridad y auditoría.',
      icon: Icons.delete_forever,
      color: Colors.red,
    );
  }
}

/// Widget para mostrar cuando se requiere autenticación adicional
class RequiereAutenticacionWidget extends StatelessWidget {
  final String accion;
  
  const RequiereAutenticacionWidget({
    super.key,
    required this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return RestriccionSupervisorWidget(
      accion: accion,
      motivo: 'Esta acción requiere autenticación adicional por motivos de seguridad.',
      icon: Icons.security,
      color: Colors.orange[600],
    );
  }
}
