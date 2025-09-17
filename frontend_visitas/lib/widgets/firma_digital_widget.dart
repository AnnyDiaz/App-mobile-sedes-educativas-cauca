import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class FirmaDigitalWidget extends StatefulWidget {
  final String titulo;
  final String subtitulo;
  final Function(Uint8List?) onFirmaCapturada;
  final Uint8List? firmaExistente;
  final bool esEditable;

  const FirmaDigitalWidget({
    Key? key,
    required this.titulo,
    required this.subtitulo,
    required this.onFirmaCapturada,
    this.firmaExistente,
    this.esEditable = true,
  }) : super(key: key);

  @override
  State<FirmaDigitalWidget> createState() => _FirmaDigitalWidgetState();
}

class _FirmaDigitalWidgetState extends State<FirmaDigitalWidget> {
  late SignatureController _controller;
  bool _firmaCapturada = false;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    // Si hay una firma existente, mostrarla
    if (widget.firmaExistente != null) {
      _firmaCapturada = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _capturarFirma() async {
    if (!widget.esEditable) return;

    try {
      final firma = await _controller.toPngBytes();
      if (firma != null) {
        setState(() {
          _firmaCapturada = true;
        });
        widget.onFirmaCapturada(firma);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Firma capturada exitosamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al capturar firma: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _limpiarFirma() {
    if (!widget.esEditable) return;

    _controller.clear();
    setState(() {
      _firmaCapturada = false;
    });
    widget.onFirmaCapturada(null);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Firma eliminada'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              children: [
                Icon(
                  Icons.draw,
                  color: Colors.blue[600],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.titulo,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.subtitulo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Área de firma
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _firmaCapturada ? Colors.green : Colors.grey[300]!,
                  width: _firmaCapturada ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Signature(
                  controller: _controller,
                  backgroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Indicador de estado
            if (_firmaCapturada)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Firma capturada',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Botones de acción
            if (widget.esEditable) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _firmaCapturada ? null : _capturarFirma,
                      icon: const Icon(Icons.draw),
                      label: Text(_firmaCapturada ? 'Firma Capturada' : 'Capturar Firma'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _firmaCapturada ? Colors.grey[300] : Colors.blue[600],
                        foregroundColor: _firmaCapturada ? Colors.grey[600] : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _firmaCapturada ? _limpiarFirma : null,
                      icon: const Icon(Icons.clear),
                      label: const Text('Limpiar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _firmaCapturada ? Colors.red[600] : Colors.grey[400],
                        side: BorderSide(
                          color: _firmaCapturada ? Colors.red[300]! : Colors.grey[300]!,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Instrucciones
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dibuja tu firma en el área de arriba. Usa el botón "Limpiar" si quieres empezar de nuevo.',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
