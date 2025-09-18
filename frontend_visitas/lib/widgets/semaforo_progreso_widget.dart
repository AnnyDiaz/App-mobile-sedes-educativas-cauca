import 'package:flutter/material.dart';

enum EstadoSemaforo {
  preparando,    // Rojo - Preparando datos
  procesando,    // Amarillo - Procesando
  completado,    // Verde - Completado
  error,         // Rojo - Error
}

class SemaforoProgresoWidget extends StatefulWidget {
  final EstadoSemaforo estado;
  final String mensaje;
  final double? progreso; // 0.0 a 1.0
  final VoidCallback? onReintentar;

  const SemaforoProgresoWidget({
    Key? key,
    required this.estado,
    required this.mensaje,
    this.progreso,
    this.onReintentar,
  }) : super(key: key);

  @override
  State<SemaforoProgresoWidget> createState() => _SemaforoProgresoWidgetState();
}

class _SemaforoProgresoWidgetState extends State<SemaforoProgresoWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.estado == EstadoSemaforo.procesando) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SemaforoProgresoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.estado == EstadoSemaforo.procesando && 
        oldWidget.estado != EstadoSemaforo.procesando) {
      _animationController.repeat(reverse: true);
    } else if (widget.estado != EstadoSemaforo.procesando) {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Semáforo visual
            _buildSemaforo(),
            const SizedBox(height: 16),
            
            // Mensaje de estado
            Text(
              widget.mensaje,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: _getColorEstado(),
              ),
              textAlign: TextAlign.center,
            ),
            
            // Barra de progreso (si está disponible)
            if (widget.progreso != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: widget.progreso,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(_getColorEstado()),
              ),
              const SizedBox(height: 8),
              Text(
                '${(widget.progreso! * 100).toInt()}% completado',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            
            // Botón de reintentar (si hay error)
            if (widget.estado == EstadoSemaforo.error && widget.onReintentar != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: widget.onReintentar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSemaforo() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.estado == EstadoSemaforo.procesando ? _pulseAnimation.value : 1.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLuz(Colors.red, widget.estado == EstadoSemaforo.preparando || widget.estado == EstadoSemaforo.error),
              const SizedBox(width: 8),
              _buildLuz(Colors.orange, widget.estado == EstadoSemaforo.procesando),
              const SizedBox(width: 8),
              _buildLuz(Colors.green, widget.estado == EstadoSemaforo.completado),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLuz(Color color, bool activa) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: activa ? color : Colors.grey[300],
        border: Border.all(
          color: activa ? color : Colors.grey[400]!,
          width: 2,
        ),
        boxShadow: activa ? [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ] : null,
      ),
      child: activa ? Icon(
        Icons.circle,
        color: Colors.white,
        size: 12,
      ) : null,
    );
  }

  Color _getColorEstado() {
    switch (widget.estado) {
      case EstadoSemaforo.preparando:
        return Colors.red[600]!;
      case EstadoSemaforo.procesando:
        return Colors.orange[600]!;
      case EstadoSemaforo.completado:
        return Colors.green[600]!;
      case EstadoSemaforo.error:
        return Colors.red[600]!;
    }
  }
}

// Widget para mostrar el semáforo en un diálogo
class SemaforoDialog extends StatelessWidget {
  final EstadoSemaforo estado;
  final String mensaje;
  final double? progreso;
  final VoidCallback? onReintentar;
  final VoidCallback? onCerrar;

  const SemaforoDialog({
    Key? key,
    required this.estado,
    required this.mensaje,
    this.progreso,
    this.onReintentar,
    this.onCerrar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SemaforoProgresoWidget(
              estado: estado,
              mensaje: mensaje,
              progreso: progreso,
              onReintentar: onReintentar,
            ),
            
            if (estado == EstadoSemaforo.completado || estado == EstadoSemaforo.error) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onCerrar != null)
                    TextButton(
                      onPressed: onCerrar,
                      child: const Text('Cerrar'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static void mostrar(
    BuildContext context, {
    required EstadoSemaforo estado,
    required String mensaje,
    double? progreso,
    VoidCallback? onReintentar,
    VoidCallback? onCerrar,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SemaforoDialog(
        estado: estado,
        mensaje: mensaje,
        progreso: progreso,
        onReintentar: onReintentar,
        onCerrar: onCerrar,
      ),
    );
  }
}
