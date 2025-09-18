# Documentación: Sistema de Evidencias Múltiples para Checklist PAE

## Descripción General

El sistema de evidencias múltiples permite a los visitadores adjuntar varios tipos de archivos (fotos, PDFs, videos, audio) a cada pregunta del checklist, proporcionando un respaldo visual y documental completo de las visitas realizadas.

## Características Principales

### 1. Múltiples Evidencias por Pregunta
- Cada pregunta del checklist puede tener **múltiples evidencias**
- No hay límite en el número de archivos por pregunta
- Las evidencias se almacenan temporalmente en memoria hasta el envío

### 2. Tipos de Evidencias Soportados
- **📷 Fotos**: Capturadas con cámara o seleccionadas de galería
- **🎥 Videos**: Archivos de video en formatos comunes (MP4, AVI, MOV)
- **📄 PDFs**: Documentos PDF para reportes o certificaciones
- **🎵 Audio**: Archivos de audio para grabaciones de voz
- **📎 Otros**: Cualquier tipo de archivo no categorizado

### 3. Interfaz de Usuario Mejorada

#### Widget de Evidencias (`EvidenciasWidget`)
- **Encabezado claro**: Muestra "Evidencias" con contador
- **Vista previa en grid**: 3 columnas con miniaturas de archivos
- **Resumen por tipo**: Contadores visuales de cada tipo de evidencia
- **Botón de subida**: Menú desplegable con opciones claras

#### Pantalla de Checklist (`ChecklistConEvidenciasScreen`)
- **Indicador de estado**: Muestra si la pregunta está respondida
- **Barra de progreso mejorada**: Incluye contador de evidencias
- **Resumen detallado**: Estadísticas completas antes del envío

## Flujo de Trabajo del Usuario

### 1. Responder Pregunta
```
1. Seleccionar respuesta (Cumple/No Cumple/No Aplica)
2. Agregar observaciones opcionales
3. Subir evidencias relacionadas
```

### 2. Subir Evidencias
```
1. Hacer clic en "Subir evidencia"
2. Elegir tipo de archivo:
   - 📷 Tomar foto con cámara
   - 🖼️ Seleccionar de galería
   - 📎 Seleccionar archivo (PDF/Video)
3. El archivo se agrega a la lista de evidencias
4. Repetir para más evidencias si es necesario
```

### 3. Gestionar Evidencias
```
- Ver vista previa de cada archivo
- Hacer clic en evidencia para ver detalles
- Eliminar evidencias no deseadas
- Ver resumen de tipos y cantidades
```

### 4. Enviar Checklist
```
1. Completar todas las preguntas
2. Revisar resumen de evidencias
3. Confirmar envío con vista previa detallada
4. Enviar datos y archivos al servidor
```

## Estructura Técnica

### Modelo de Datos

#### Clase `Evidencia`
```dart
class Evidencia {
  final String? id;
  final String preguntaId;        // ID de la pregunta asociada
  final String nombreArchivo;     // Nombre del archivo
  final String rutaArchivo;       // Ruta local del archivo
  final TipoEvidencia tipo;       // Tipo de evidencia
  final DateTime fechaCreacion;   // Fecha de creación
  final int? tamanoBytes;        // Tamaño en bytes
  final String? mimeType;        // Tipo MIME
  final bool esTemporal;         // Si está en memoria temporal
}
```

#### Enum `TipoEvidencia`
```dart
enum TipoEvidencia {
  foto,    // 📷 Imágenes
  video,   // 🎥 Videos
  pdf,     // 📄 Documentos PDF
  audio,   // 🎵 Archivos de audio
  otro     // 📎 Otros tipos
}
```

### Almacenamiento

#### Memoria Temporal
- Las evidencias se almacenan en memoria durante la sesión
- Se asocian con el ID de la pregunta correspondiente
- Se mantienen hasta el envío del checklist

#### Estructura de Datos
```dart
Map<String, List<Evidencia>> _evidencias = {
  "1": [evidencia1, evidencia2],     // Pregunta ID 1
  "2": [evidencia3],                 // Pregunta ID 2
  "3": [],                           // Pregunta ID 3 (sin evidencias)
}
```

## Funcionalidades Avanzadas

### 1. Vista Previa de Imágenes
- **Zoom automático**: Hacer clic en evidencia de foto para ampliar
- **Información detallada**: Nombre, tipo, tamaño, fecha, MIME
- **Manejo de errores**: Fallback visual si la imagen no carga

### 2. Resumen Estadístico
- **Contador por tipo**: Cuántas fotos, PDFs, videos, etc.
- **Total general**: Número total de evidencias
- **Distribución visual**: Chips de colores por tipo

### 3. Validación y Feedback
- **Indicadores visuales**: Estado de respuesta y evidencias
- **Advertencias**: Sugerencias si no hay evidencias
- **Confirmación detallada**: Resumen completo antes del envío

## Mejoras de UX Implementadas

### 1. Diseño Responsivo
- Grid adaptativo para evidencias
- Espaciado consistente y legible
- Colores semánticos por tipo de archivo

### 2. Navegación Intuitiva
- Botones claros y descriptivos
- Menús desplegables organizados
- Acciones directas (eliminar, ver detalles)

### 3. Feedback Visual
- Contadores en tiempo real
- Indicadores de progreso
- Estados claros (respondida, con evidencias)

## Consideraciones de Rendimiento

### 1. Memoria
- Las evidencias se mantienen en memoria temporal
- Se recomienda comprimir imágenes antes de subir
- Límite práctico: ~50-100 MB por sesión

### 2. Almacenamiento
- Los archivos se guardan temporalmente en el dispositivo
- Se limpian automáticamente después del envío
- No se acumulan entre sesiones

### 3. Red
- Las evidencias se envían junto con las respuestas
- Se recomienda conexión estable para archivos grandes
- Fallback para conexiones lentas

## Casos de Uso Típicos

### 1. Verificación de Infraestructura
```
Pregunta: "¿El comedor tiene ventilación adecuada?"
Evidencias:
- 📷 Foto del sistema de ventilación
- 📷 Foto de las ventanas abiertas
- 📄 Certificado de instalación eléctrica
```

### 2. Control de Calidad
```
Pregunta: "¿Los alimentos cumplen con estándares de frescura?"
Evidencias:
- 📷 Foto de los alimentos
- 📷 Foto de la fecha de vencimiento
- 🎥 Video del proceso de verificación
```

### 3. Documentación de Incidencias
```
Pregunta: "¿Se identificaron problemas de higiene?"
Evidencias:
- 📷 Fotos del problema
- 📄 Reporte de incidencia
- 🎵 Audio de la explicación del personal
```

## Mantenimiento y Extensibilidad

### 1. Agregar Nuevos Tipos
- Extender el enum `TipoEvidencia`
- Agregar iconos y colores correspondientes
- Actualizar la lógica de detección de tipos

### 2. Modificar Formatos Soportados
- Actualizar la función `_obtenerMimeType`
- Agregar validaciones de tamaño
- Implementar compresión automática

### 3. Personalizar Interfaz
- Modificar colores y estilos
- Ajustar layout del grid
- Agregar animaciones o transiciones

## Solución de Problemas

### Problemas Comunes

#### 1. Evidencia No Se Agrega
- Verificar permisos de cámara/archivos
- Comprobar espacio en dispositivo
- Revisar logs de error

#### 2. Imagen No Se Muestra
- Verificar formato de archivo
- Comprobar ruta del archivo
- Revisar permisos de lectura

#### 3. Error al Enviar
- Verificar conexión a internet
- Comprobar tamaño total de archivos
- Revisar logs del servidor

### Logs y Debugging
- Activar modo debug en la consola
- Revisar mensajes de error en SnackBars
- Verificar estado de las variables en tiempo real

## Conclusión

El sistema de evidencias múltiples proporciona una solución robusta y fácil de usar para la documentación visual de visitas PAE. Permite a los visitadores capturar y organizar evidencia de manera eficiente, mejorando la calidad y credibilidad de los reportes generados.

La implementación actual es escalable y puede extenderse fácilmente para soportar nuevos tipos de archivos o funcionalidades adicionales según las necesidades futuras del programa PAE.
