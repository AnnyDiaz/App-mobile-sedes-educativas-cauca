import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/evidencia.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class EvidenciasWidget extends StatefulWidget {
  final String preguntaId;
  final List<Evidencia> evidencias;
  final Function(Evidencia) onEvidenciaAgregada;
  final Function(Evidencia) onEvidenciaEliminada;
  final bool esEditable;

  const EvidenciasWidget({
    Key? key,
    required this.preguntaId,
    required this.evidencias,
    required this.onEvidenciaAgregada,
    required this.onEvidenciaEliminada,
    this.esEditable = true,
  }) : super(key: key);

  @override
  State<EvidenciasWidget> createState() => _EvidenciasWidgetState();
}

class _EvidenciasWidgetState extends State<EvidenciasWidget> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado de evidencias
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Evidencias',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            if (widget.evidencias.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.attach_file, size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.evidencias.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Lista de evidencias con vista previa
        if (widget.evidencias.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                // Grid de evidencias
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: widget.evidencias.length,
                  itemBuilder: (context, index) {
                    return _EvidenciaPreview(
                      evidencia: widget.evidencias[index],
                      onEliminar: widget.esEditable 
                        ? () => widget.onEvidenciaEliminada(widget.evidencias[index])
                        : null,
                    );
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Resumen de tipos de evidencias
                _buildResumenTiposEvidencias(),
              ],
            ),
          ),
        
        const SizedBox(height: 12),
        
        // Botón para agregar evidencia
        if (widget.esEditable)
          _BotonAgregarEvidencia(
            onEvidenciaSeleccionada: _agregarEvidencia,
            onTomarFoto: _tomarFoto,
            onSeleccionarGaleria: _seleccionarDeGaleria,
            onSeleccionarArchivo: _seleccionarArchivo,
          ),
      ],
    );
  }

  Widget _buildResumenTiposEvidencias() {
    final Map<TipoEvidencia, int> conteoTipos = {};
    for (final evidencia in widget.evidencias) {
      conteoTipos[evidencia.tipo] = (conteoTipos[evidencia.tipo] ?? 0) + 1;
    }

    return Wrap(
      spacing: 8,
      children: conteoTipos.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Color(_getColorTipo(entry.key)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(_getColorTipo(entry.key)).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getIconoTipo(entry.key),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 2),
              Text(
                '${entry.value}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(_getColorTipo(entry.key)),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  int _getColorTipo(TipoEvidencia tipo) {
    switch (tipo) {
      case TipoEvidencia.foto:
        return 0xFF4CAF50; // Verde
      case TipoEvidencia.video:
        return 0xFF2196F3; // Azul
      case TipoEvidencia.pdf:
        return 0xFFF44336; // Rojo
      case TipoEvidencia.audio:
        return 0xFF9C27B0; // Púrpura
      case TipoEvidencia.otro:
        return 0xFF607D8B; // Gris azulado
      case TipoEvidencia.firma:
        return 0xFF795548; // Marrón
      default:
        return 0xFF607D8B; // Gris azulado por defecto
    }
  }

  String _getIconoTipo(TipoEvidencia tipo) {
    switch (tipo) {
      case TipoEvidencia.foto:
        return '📷';
      case TipoEvidencia.video:
        return '🎥';
      case TipoEvidencia.pdf:
        return '📄';
      case TipoEvidencia.audio:
        return '🎵';
      case TipoEvidencia.otro:
        return '📎';
      case TipoEvidencia.firma:
        return '✍️';
      default:
        return '📎';
    }
  }

  Future<void> _agregarEvidencia(Evidencia evidencia) async {
    widget.onEvidenciaAgregada(evidencia);
  }

  // Métodos para capturar/seleccionar archivos
  Future<void> _tomarFoto() async {
    print('📷 DEBUG: Intentando tomar foto...');
    try {
      final XFile? imagen = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (imagen != null) {
        print('📷 DEBUG: Foto tomada exitosamente: ${imagen.path}');
        
        // Para web, usar la URL del blob en lugar de File
        String rutaArchivo;
        if (kIsWeb) {
          rutaArchivo = imagen.path;
        } else {
          final archivo = File(imagen.path);
          rutaArchivo = archivo.path;
        }
        
        final evidencia = Evidencia(
          preguntaId: widget.preguntaId,
          nombreArchivo: imagen.name,
          rutaArchivo: rutaArchivo,
          tipo: TipoEvidencia.foto,
          fechaCreacion: DateTime.now(),
          esTemporal: true,
        );
        
        print('📷 DEBUG: Evidencia creada, llamando callback...');
        widget.onEvidenciaAgregada(evidencia);
      } else {
        print('📷 DEBUG: No se tomó foto');
      }
    } catch (e) {
      print('❌ DEBUG: Error al tomar foto: $e');
      _mostrarError('Error al tomar foto: $e');
    }
  }

  Future<void> _seleccionarDeGaleria() async {
    print('🖼️ DEBUG: Intentando seleccionar de galería...');
    try {
      final XFile? imagen = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (imagen != null) {
        print('🖼️ DEBUG: Imagen seleccionada: ${imagen.path}');
        
        // Para web, usar la URL del blob en lugar de File
        String rutaArchivo;
        if (kIsWeb) {
          rutaArchivo = imagen.path;
        } else {
          final archivo = File(imagen.path);
          rutaArchivo = archivo.path;
        }
        
        final evidencia = Evidencia(
          preguntaId: widget.preguntaId,
          nombreArchivo: imagen.name,
          rutaArchivo: rutaArchivo,
          tipo: TipoEvidencia.foto,
          fechaCreacion: DateTime.now(),
          esTemporal: true,
        );
        
        print('🖼️ DEBUG: Evidencia creada, llamando callback...');
        widget.onEvidenciaAgregada(evidencia);
      } else {
        print('🖼️ DEBUG: No se seleccionó imagen');
      }
    } catch (e) {
      print('❌ DEBUG: Error al seleccionar imagen: $e');
      _mostrarError('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _seleccionarArchivo() async {
    print('📎 DEBUG: Intentando seleccionar archivo...');
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        print('📎 DEBUG: Archivo seleccionado: ${result.files.first.path}');
        
        final file = result.files.first;
        String rutaArchivo;
        
        if (kIsWeb) {
          // Para web, usar el nombre del archivo
          rutaArchivo = file.name;
        } else {
          // Para móvil, usar la ruta del archivo
          rutaArchivo = file.path ?? file.name;
        }
        
        final extension = file.extension?.toLowerCase() ?? '';
        
        TipoEvidencia tipo;
        if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
          tipo = TipoEvidencia.foto;
        } else if (['mp4', 'avi', 'mov', 'wmv'].contains(extension)) {
          tipo = TipoEvidencia.video;
        } else if (['pdf'].contains(extension)) {
          tipo = TipoEvidencia.pdf;
        } else if (['mp3', 'wav', 'aac'].contains(extension)) {
          tipo = TipoEvidencia.audio;
        } else {
          tipo = TipoEvidencia.otro;
        }
        
        final evidencia = Evidencia(
          preguntaId: widget.preguntaId,
          nombreArchivo: file.name,
          rutaArchivo: rutaArchivo,
          tipo: tipo,
          fechaCreacion: DateTime.now(),
          tamanoBytes: file.size,
          mimeType: file.extension,
          esTemporal: true,
        );
        
        print('📎 DEBUG: Evidencia creada, llamando callback...');
        widget.onEvidenciaAgregada(evidencia);
      } else {
        print('📎 DEBUG: No se seleccionó archivo');
      }
    } catch (e) {
      print('❌ DEBUG: Error al seleccionar archivo: $e');
      _mostrarError('Error al seleccionar archivo: $e');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class _EvidenciaPreview extends StatelessWidget {
  final Evidencia evidencia;
  final VoidCallback? onEliminar;

  const _EvidenciaPreview({
    required this.evidencia,
    this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _mostrarDetallesEvidencia(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono del tipo de archivo
                Text(
                  evidencia.icono,
                  style: const TextStyle(fontSize: 24),
                ),
                
                const SizedBox(height: 4),
                
                // Nombre del archivo truncado
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    evidencia.nombreArchivo,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 2),
                
                // Tamaño del archivo
                Text(
                  evidencia.tamanoFormateado,
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Botón de eliminar
        if (onEliminar != null)
          Positioned(
            top: -4,
            right: -4,
            child: GestureDetector(
              onTap: onEliminar,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: const Icon(
                  Icons.close,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _mostrarDetallesEvidencia(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(evidencia.icono),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Detalles de la evidencia',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vista previa si es imagen
            if (evidencia.tipo == TipoEvidencia.foto)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(evidencia.rutaArchivo),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.grey.shade400, size: 48),
                            Text(
                              'Error al cargar imagen',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Información del archivo
            _buildInfoRow('Nombre:', evidencia.nombreArchivo),
            _buildInfoRow('Tipo:', _getNombreTipo(evidencia.tipo)),
            _buildInfoRow('Tamaño:', evidencia.tamanoFormateado),
            _buildInfoRow('Fecha:', _formatearFecha(evidencia.fechaCreacion)),
            if (evidencia.mimeType != null)
              _buildInfoRow('MIME:', evidencia.mimeType!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  String _getNombreTipo(TipoEvidencia tipo) {
    switch (tipo) {
      case TipoEvidencia.foto:
        return 'Imagen';
      case TipoEvidencia.video:
        return 'Video';
      case TipoEvidencia.pdf:
        return 'Documento PDF';
      case TipoEvidencia.audio:
        return 'Audio';
      case TipoEvidencia.otro:
        return 'Otro archivo';
      case TipoEvidencia.firma:
        return 'Firma Digital';
      default:
        return 'Otro archivo';
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }
}

class _BotonAgregarEvidencia extends StatelessWidget {
  final Function(Evidencia) onEvidenciaSeleccionada;
  final VoidCallback onTomarFoto;
  final VoidCallback onSeleccionarGaleria;
  final VoidCallback onSeleccionarArchivo;

  const _BotonAgregarEvidencia({
    required this.onEvidenciaSeleccionada,
    required this.onTomarFoto,
    required this.onSeleccionarGaleria,
    required this.onSeleccionarArchivo,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (opcion) => _seleccionarOpcion(opcion),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline, size: 18, color: Colors.green.shade700),
            const SizedBox(width: 8),
            Text(
              'Subir evidencia',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_drop_down, size: 18, color: Colors.green.shade700),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'camara',
          child: Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.blue),
              SizedBox(width: 12),
              Text('Tomar foto con cámara'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'galeria',
          child: Row(
            children: [
              Icon(Icons.photo_library, color: Colors.green),
              SizedBox(width: 12),
              Text('Seleccionar de galería'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'archivo',
          child: Row(
            children: [
              Icon(Icons.attach_file, color: Colors.orange),
              SizedBox(width: 12),
              Text('Seleccionar archivo (PDF/Video)'),
            ],
          ),
        ),
      ],
    );
  }

  void _seleccionarOpcion(String opcion) {
    switch (opcion) {
      case 'camara':
        onTomarFoto();
        break;
      case 'galeria':
        onSeleccionarGaleria();
        break;
      case 'archivo':
        onSeleccionarArchivo();
        break;
    }
  }
}
