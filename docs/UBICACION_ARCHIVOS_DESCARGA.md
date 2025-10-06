# 📁 Ubicación de Archivos para Descarga

## Estructura del Directorio `media/`

Los archivos generados por el sistema se almacenan en el directorio `media/` con la siguiente estructura:

```
media/
├── exports/           # 📊 Archivos de exportación y reportes
├── firmas/           # ✍️ Firmas digitales capturadas
├── fotos/            # 📷 Fotos de evidencias
├── pdfs/             # 📄 Documentos PDF
├── notifications/    # 🔔 Archivos de notificaciones
└── 2fa/             # 🔐 Códigos de autenticación de dos factores
```

## 📊 Directorio `media/exports/`

**Ubicación:** `C:\Users\ANNY\Desktop\App-mobile-sedes-educativas-cauca\media\exports\`

Este directorio contiene todos los archivos de exportación y reportes generados por el sistema:

### Tipos de Archivos:
- **Excel (.xlsx):** Reportes de visitas, usuarios, sedes, estadísticas
- **PDF (.pdf):** Reportes en formato PDF

### Nomenclatura de Archivos:
- `visitas_completas_YYYYMMDD_HHMMSS.xlsx` - Reportes de visitas completas
- `usuarios_YYYYMMDD_HHMMSS.xlsx` - Reportes de usuarios
- `sedes_YYYYMMDD_HHMMSS.xlsx` - Reportes de sedes educativas
- `estadisticas_pae_YYYYMMDD_HHMMSS.xlsx` - Estadísticas del PAE
- `cronograma_YYYYMMDD_HHMMSS.xlsx` - Cronogramas de visitas

### Ejemplos de Archivos Actuales:
```
visitas_completas_20250819_095329.xlsx
usuarios_20250819_192718.xlsx
sedes_20250819_192720.xlsx
estadisticas_pae_20250819_174522.xlsx
cronograma_20250819_173926.xlsx
```

## ✍️ Directorio `media/firmas/`

**Ubicación:** `C:\Users\ANNY\Desktop\App-mobile-sedes-educativas-cauca\media\firmas\`

Contiene las firmas digitales capturadas durante las visitas:
- Formato: PNG
- Nomenclatura: UUID único para cada firma
- Ejemplo: `059c24a6-03cc-40d6-9f58-01454d989dee.png`

## 📷 Directorio `media/fotos/`

**Ubicación:** `C:\Users\ANNY\Desktop\App-mobile-sedes-educativas-cauca\media\fotos\`

Contiene las fotos de evidencias capturadas durante las visitas:
- Formatos: JPEG, PNG
- Nomenclatura: UUID único para cada foto
- Ejemplo: `77f734aa-aeea-4ffd-833f-aa9e11b7bf8f.jpeg`

## 📄 Directorio `media/pdfs/`

**Ubicación:** `C:\Users\ANNY\Desktop\App-mobile-sedes-educativas-cauca\media\pdfs\`

Contiene documentos PDF generados por el sistema:
- Nomenclatura: UUID único para cada documento
- Ejemplo: `35ac72e7-14a6-432f-9d99-62d72766e321.pdf`

## 🔔 Directorio `media/notifications/`

**Ubicación:** `C:\Users\ANNY\Desktop\App-mobile-sedes-educativas-cauca\media\notifications\`

Contiene archivos relacionados con el sistema de notificaciones:
- `emails/` - Plantillas de correos electrónicos
- `logs/` - Logs de notificaciones enviadas
- `14_config.json` - Configuración de notificaciones

## 🔐 Directorio `media/2fa/`

**Ubicación:** `C:\Users\ANNY\Desktop\App-mobile-sedes-educativas-cauca\media\2fa\`

Contiene archivos de respaldo para autenticación de dos factores:
- `14_backup.txt` - Códigos de respaldo
- `14_secret.txt` - Clave secreta

## 🔗 Acceso a Archivos desde la Aplicación

### Para Administradores:
- **Endpoint:** `/api/admin/exportaciones/{export_id}/download`
- **Método:** GET
- **Autenticación:** Requerida (rol admin)

### Para Supervisores:
- **Endpoint:** `/api/supervisor/descargar-reporte-equipo/{reporte_id}`
- **Método:** GET
- **Autenticación:** Requerida (rol supervisor)

### Para Reportes Generales:
- **Endpoint:** `/api/reportes/generar`
- **Método:** POST
- **Formatos:** Excel (.xlsx), CSV (.csv)
- **Autenticación:** Requerida (roles supervisor/admin)

## 📋 Consideraciones Importantes

1. **Seguridad:** Todos los archivos están protegidos por autenticación
2. **Limpieza:** Se recomienda limpiar archivos antiguos periódicamente
3. **Respaldo:** Los archivos importantes deben respaldarse regularmente
4. **Permisos:** Solo usuarios autorizados pueden acceder a los archivos
5. **Formato:** Los archivos mantienen su formato original para compatibilidad

## 🛠️ Mantenimiento

### Limpieza de Archivos Antiguos:
```bash
# Eliminar archivos de exportación más antiguos de 30 días
find media/exports/ -name "*.xlsx" -mtime +30 -delete
find media/exports/ -name "*.pdf" -mtime +30 -delete
```

### Monitoreo de Espacio:
- Verificar regularmente el tamaño del directorio `media/`
- Implementar rotación de logs en `media/notifications/logs/`
- Limpiar archivos temporales de firmas y fotos no utilizados
