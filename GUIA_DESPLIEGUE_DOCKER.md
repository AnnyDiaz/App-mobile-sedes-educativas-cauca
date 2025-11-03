# 📘 Guía de Despliegue - Sistema de Visitas PAE Cauca

Esta guía detalla el proceso completo para desplegar el backend y la base de datos del sistema de visitas PAE en contenedores Docker.

---

## 📋 Tabla de Contenidos

1. [Pre-requisitos](#pre-requisitos)
2. [Estructura del Proyecto](#estructura-del-proyecto)
3. [Configuración Inicial](#configuración-inicial)
4. [Despliegue de Contenedores](#despliegue-de-contenedores)
5. [Carga de Datos](#carga-de-datos)
6. [Verificación del Sistema](#verificación-del-sistema)
7. [Solución de Problemas](#solución-de-problemas)
8. [Comandos Útiles](#comandos-útiles)

---

## 🔧 Pre-requisitos

Antes de comenzar, asegúrate de tener instalado:

- ✅ **Docker Desktop** (versión 20.10 o superior)
- ✅ **Docker Compose** (versión 1.29 o superior)
- ✅ **Git** (para clonar el repositorio)
- ✅ **PowerShell** o **Bash** (según tu sistema operativo)

### Verificar instalación:

```bash
# Verificar Docker
docker --version
# Salida esperada: Docker version 20.10.x o superior

# Verificar Docker Compose
docker compose version
# Salida esperada: Docker Compose version v2.x.x o superior
```

---

## 📁 Estructura del Proyecto

```
App-mobile-sedes-educativas-cauca/
├── app/                          # Código del backend (FastAPI)
│   ├── routes/                   # Endpoints de la API
│   ├── models.py                 # Modelos de la base de datos
│   ├── database.py               # Configuración de la BD
│   └── scripts/                  # Scripts de inicialización
│       ├── init_admin_system.py  # Crear roles y usuario admin
│       ├── docker_init.py        # Script de inicialización Docker
│       └── cargar_checklist_pae.py  # Cargar checklist PAE
├── docker-compose.yml            # Configuración de contenedores
├── Dockerfile                    # Imagen del backend
├── requirements.txt              # Dependencias Python
├── main.py                       # Punto de entrada de FastAPI
├── insert_data_optimized.sql     # Datos denormalizados
├── insert_datos_normalizados.sql # Script de normalización
└── frontend_visitas/             # Aplicación móvil Flutter
```

---

## ⚙️ Configuración Inicial

### 1. Variables de Entorno

Crea un archivo `.env` en la raíz del proyecto (opcional, ya que docker-compose tiene valores por defecto):

```env
# Base de Datos
DATABASE_URL=postgresql+psycopg2://visitas:visitas@db:5432/visitas_cauca

# Seguridad
SECRET_KEY=tu_clave_secreta_muy_segura_aqui
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7

# Email (opcional)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=tu_correo@gmail.com
EMAIL_PASSWORD=tu_password_de_aplicacion

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080,http://localhost:*,http://127.0.0.1:*
```

### 2. Verificar Archivos Requeridos

Asegúrate de que estos archivos existen en la raíz del proyecto:

```bash
# Windows PowerShell
Test-Path .\docker-compose.yml
Test-Path .\Dockerfile
Test-Path .\requirements.txt
Test-Path .\main.py
Test-Path .\insert_data_optimized.sql
Test-Path .\insert_datos_normalizados.sql

# Linux/Mac
ls docker-compose.yml Dockerfile requirements.txt main.py
```

---

## 🚀 Despliegue de Contenedores

### Paso 1: Detener Contenedores Existentes (si los hay)

```bash
# Detener y eliminar contenedores anteriores
docker compose down

# Eliminar volúmenes (si quieres empezar desde cero)
docker compose down -v
```

### Paso 2: Construir y Levantar los Contenedores

```bash
# Construir las imágenes y levantar los contenedores
docker compose up --build

# O en segundo plano (detached mode)
docker compose up --build -d
```

**Salida esperada:**
```
✔ Container visitas_db    Started
✔ Container visitas_api   Started
```

### Paso 3: Verificar que los Contenedores Están Corriendo

```bash
# Ver contenedores en ejecución
docker ps

# Deberías ver:
# CONTAINER ID   IMAGE                                   STATUS
# xxxxxxxxxxxx   app-mobile-sedes-educativas-cauca-api   Up X seconds
# xxxxxxxxxxxx   postgres:15-alpine                      Up X seconds
```

### Paso 4: Ver los Logs del Backend

```bash
# Ver logs en tiempo real
docker logs -f visitas_api

# Salida esperada:
# Esperando a que la base de datos este disponible...
# Base de datos disponible
# Creando tablas de base de datos...
# Tablas creadas
# Roles basicos creados
# Usuario administrador creado
# Inicializacion completada exitosamente!
```

---

## 📊 Carga de Datos

### Paso 1: Cargar Municipios, Instituciones y Sedes

#### En Windows (PowerShell):

```powershell
# Copiar archivos SQL al contenedor
docker cp insert_data_optimized.sql visitas_db:/tmp/insert_data_optimized.sql
docker cp insert_datos_normalizados.sql visitas_db:/tmp/insert_datos_normalizados.sql

# Cargar datos denormalizados
docker exec -i visitas_db psql -U visitas -d visitas_cauca -f /tmp/insert_data_optimized.sql

# Normalizar datos (crear municipios, instituciones y sedes)
docker exec -i visitas_db psql -U visitas -d visitas_cauca -f /tmp/insert_datos_normalizados.sql

# Verificar carga
docker exec -i visitas_db psql -U visitas -d visitas_cauca -c "SELECT COUNT(*) FROM municipios;"
docker exec -i visitas_db psql -U visitas -d visitas_cauca -c "SELECT COUNT(*) FROM instituciones;"
docker exec -i visitas_db psql -U visitas -d visitas_cauca -c "SELECT COUNT(*) FROM sedes_educativas;"
```

#### En Linux/Mac (Bash):

```bash
# Copiar archivos SQL al contenedor
docker cp insert_data_optimized.sql visitas_db:/tmp/insert_data_optimized.sql
docker cp insert_datos_normalizados.sql visitas_db:/tmp/insert_datos_normalizados.sql

# Cargar datos denormalizados
docker exec -i visitas_db psql -U visitas -d visitas_cauca -f /tmp/insert_data_optimized.sql

# Normalizar datos
docker exec -i visitas_db psql -U visitas -d visitas_cauca -f /tmp/insert_datos_normalizados.sql

# Verificar carga
docker exec -i visitas_db psql -U visitas -d visitas_cauca -c "SELECT COUNT(*) FROM municipios;"
docker exec -i visitas_db psql -U visitas -d visitas_cauca -c "SELECT COUNT(*) FROM instituciones;"
docker exec -i visitas_db psql -U visitas -d visitas_cauca -c "SELECT COUNT(*) FROM sedes_educativas;"
```

**Resultado esperado:**
```
Municipios:      41
Instituciones:   564
Sedes:          2556
```

### Paso 2: Verificar Checklist PAE (carga automática)

El checklist PAE (15 categorías, 64 items) se carga **automáticamente** durante la inicialización del contenedor.

**Verificar que se cargó correctamente:**

```bash
# Verificar categorías (debe mostrar 15)
docker exec -i visitas_db psql -U visitas -d visitas_cauca -c "SELECT COUNT(*) FROM checklist_categorias;"

# Verificar items (debe mostrar 64)
docker exec -i visitas_db psql -U visitas -d visitas_cauca -c "SELECT COUNT(*) FROM checklist_items;"
```

**Resultado esperado:**
```
Categorías:  15
Items:       64
```

**Si los items no se cargaron automáticamente (aparecen 0 items):**

```bash
# Cargar manualmente los items del checklist
docker exec -i visitas_db bash -c "psql -U visitas -d visitas_cauca -f /app/insert_checklist_items.sql"
```

---

## ✅ Verificación del Sistema

### 1. Verificar Estado de los Contenedores

```bash
# Ver estado de salud de los contenedores
docker compose ps

# Todos deben estar "Up" y "healthy"
```

### 2. Verificar la API

#### Verificar que la API responde:

```bash
# Windows PowerShell
Invoke-WebRequest -Uri "http://localhost:8000/docs" -UseBasicParsing

# Linux/Mac
curl http://localhost:8000/docs
```

Deberías poder abrir en tu navegador:
- 📄 **Documentación Swagger:** http://localhost:8000/docs
- 📄 **Documentación ReDoc:** http://localhost:8000/redoc

### 3. Verificar Endpoints Principales

```bash
# Verificar endpoint de salud
curl http://localhost:8000/

# Verificar endpoint de municipios
curl http://localhost:8000/api/municipios

# Verificar endpoint de checklist
curl http://localhost:8000/api/checklist
```

### 4. Verificar Base de Datos

```bash
# Conectarse a la base de datos
docker exec -it visitas_db psql -U visitas -d visitas_cauca

# Dentro de psql, ejecutar:
\dt  # Ver todas las tablas
\q   # Salir
```

### 5. Probar Login con Usuario Admin

**Credenciales por defecto:**
- **Email:** `admin@test.com`
- **Password:** `admin`

```bash
# Probar login (Windows PowerShell)
$body = @{
    username = "admin@test.com"
    password = "admin"
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://localhost:8000/api/auth/login" `
    -Method POST `
    -ContentType "application/json" `
    -Body $body

# Probar login (Linux/Mac)
curl -X POST "http://localhost:8000/api/auth/login" \
     -H "Content-Type: application/json" \
     -d '{"username":"admin@test.com","password":"admin"}'
```

---

## 🔧 Solución de Problemas

### Problema 1: El contenedor `visitas_api` no arranca

**Síntoma:** El contenedor se reinicia constantemente

```bash
# Ver logs del contenedor
docker logs visitas_api

# Causas comunes:
# - Error en requirements.txt
# - Error en el código Python
# - Base de datos no disponible
```

**Solución:**
```bash
# Reconstruir la imagen
docker compose down
docker compose build --no-cache
docker compose up
```

### Problema 2: Error "Module not found"

**Síntoma:** `ModuleNotFoundError: No module named 'app'`

**Solución:**
```bash
# Verificar que el Dockerfile tiene el WORKDIR correcto
# Verificar que requirements.txt incluye todas las dependencias

# Dentro del contenedor, verificar el path
docker exec -it visitas_api python -c "import sys; print(sys.path)"
```

### Problema 3: No se pueden cargar los municipios

**Síntoma:** Tablas vacías después de ejecutar los scripts SQL

**Solución:**
```bash
# Verificar que los archivos SQL existen
ls insert_data_optimized.sql insert_datos_normalizados.sql

# Ejecutar paso a paso y ver los errores
docker exec -i visitas_db psql -U visitas -d visitas_cauca -f /tmp/insert_data_optimized.sql
```

### Problema 4: Puerto 8000 ya está en uso

**Síntoma:** `Error: port is already allocated`

**Solución:**
```bash
# Ver qué proceso usa el puerto 8000
# Windows PowerShell
netstat -ano | findstr :8000

# Linux/Mac
lsof -i :8000

# Detener el proceso o cambiar el puerto en docker-compose.yml
```

### Problema 5: Checklist no se carga en la app móvil

**Síntoma:** Mensaje "El checklist aún se está cargando"

**Solución:**
```bash
# Verificar que las tablas tienen datos
docker exec -i visitas_db psql -U visitas -d visitas_cauca -c "SELECT COUNT(*) FROM checklist_categorias;"
docker exec -i visitas_db psql -U visitas -d visitas_cauca -c "SELECT COUNT(*) FROM checklist_items;"

# Si están vacías, ejecutar el script de carga
docker exec -it visitas_api python app/scripts/cargar_checklist_pae.py

# Verificar que el endpoint responde
curl http://localhost:8000/api/checklist
```

---

## 📝 Comandos Útiles

### Gestión de Contenedores

```bash
# Iniciar contenedores
docker compose up -d

# Detener contenedores
docker compose stop

# Reiniciar contenedores
docker compose restart

# Ver logs
docker compose logs -f

# Ver logs de un servicio específico
docker compose logs -f api

# Ejecutar comando dentro del contenedor
docker exec -it visitas_api bash

# Ver uso de recursos
docker stats
```

### Gestión de Base de Datos

```bash
# Conectarse a PostgreSQL
docker exec -it visitas_db psql -U visitas -d visitas_cauca

# Backup de la base de datos
docker exec -t visitas_db pg_dump -U visitas visitas_cauca > backup.sql

# Restaurar backup
docker exec -i visitas_db psql -U visitas -d visitas_cauca < backup.sql

# Ver tablas y registros
docker exec -i visitas_db psql -U visitas -d visitas_cauca -c "\dt"
docker exec -i visitas_db psql -U visitas -d visitas_cauca -c "SELECT * FROM municipios LIMIT 5;"
```

### Limpieza del Sistema

```bash
# Eliminar contenedores, redes y volúmenes
docker compose down -v

# Eliminar todas las imágenes no usadas
docker system prune -a

# Eliminar solo volúmenes no usados
docker volume prune
```

---

## 🎯 Resumen del Proceso Completo

### Script Rápido de Despliegue (Windows PowerShell):

```powershell
# 1. Levantar contenedores
docker compose down
docker compose up --build -d

# 2. Esperar a que la base de datos esté lista (30 segundos)
Start-Sleep -Seconds 30

# 3. Cargar datos de municipios, instituciones y sedes
docker cp insert_data_optimized.sql visitas_db:/tmp/insert_data_optimized.sql
docker cp insert_datos_normalizados.sql visitas_db:/tmp/insert_datos_normalizados.sql
docker exec -i visitas_db psql -U visitas -d visitas_cauca -f /tmp/insert_data_optimized.sql
docker exec -i visitas_db psql -U visitas -d visitas_cauca -f /tmp/insert_datos_normalizados.sql

# 4. Cargar checklist PAE
docker exec -it visitas_api python app/scripts/cargar_checklist_pae.py

# 5. Verificar
Write-Host "`n=== VERIFICACIÓN DEL SISTEMA ===" -ForegroundColor Cyan
docker exec -i visitas_db psql -U visitas -d visitas_cauca -c "SELECT 'Municipios:' as tabla, COUNT(*) FROM municipios UNION ALL SELECT 'Instituciones:', COUNT(*) FROM instituciones UNION ALL SELECT 'Sedes:', COUNT(*) FROM sedes_educativas UNION ALL SELECT 'Categorías:', COUNT(*) FROM checklist_categorias UNION ALL SELECT 'Items:', COUNT(*) FROM checklist_items;"

Write-Host "`n✅ Sistema desplegado correctamente!" -ForegroundColor Green
Write-Host "📄 Documentación: http://localhost:8000/docs" -ForegroundColor Cyan
Write-Host "👤 Usuario admin: admin@test.com / admin" -ForegroundColor Yellow
```

### Script Rápido de Despliegue (Linux/Mac):

```bash
#!/bin/bash

# 1. Levantar contenedores
docker compose down
docker compose up --build -d

# 2. Esperar a que la base de datos esté lista
echo "⏳ Esperando 30 segundos para que la base de datos esté lista..."
sleep 30

# 3. Cargar datos
echo "📊 Cargando datos..."
docker cp insert_data_optimized.sql visitas_db:/tmp/insert_data_optimized.sql
docker cp insert_datos_normalizados.sql visitas_db:/tmp/insert_datos_normalizados.sql
docker exec -i visitas_db psql -U visitas -d visitas_cauca -f /tmp/insert_data_optimized.sql
docker exec -i visitas_db psql -U visitas -d visitas_cauca -f /tmp/insert_datos_normalizados.sql

# 4. Cargar checklist PAE
echo "📋 Cargando checklist PAE..."
docker exec -it visitas_api python app/scripts/cargar_checklist_pae.py

# 5. Verificar
echo ""
echo "=== VERIFICACIÓN DEL SISTEMA ==="
docker exec -i visitas_db psql -U visitas -d visitas_cauca -c "SELECT 'Municipios:' as tabla, COUNT(*) FROM municipios UNION ALL SELECT 'Instituciones:', COUNT(*) FROM instituciones UNION ALL SELECT 'Sedes:', COUNT(*) FROM sedes_educativas UNION ALL SELECT 'Categorías:', COUNT(*) FROM checklist_categorias UNION ALL SELECT 'Items:', COUNT(*) FROM checklist_items;"

echo ""
echo "✅ Sistema desplegado correctamente!"
echo "📄 Documentación: http://localhost:8000/docs"
echo "👤 Usuario admin: admin@test.com / admin"
```

---

## 🔒 Consideraciones de Seguridad

Para producción, considera:

1. **Cambiar contraseñas por defecto:**
   - Usuario admin: `admin@test.com` / `admin`
   - PostgreSQL: `visitas` / `visitas`

2. **Usar variables de entorno seguras:**
   - Genera un `SECRET_KEY` fuerte y único
   - No uses valores por defecto en producción

3. **Configurar HTTPS:**
   - Usa un reverse proxy como Nginx
   - Configura certificados SSL

4. **Limitar acceso a la base de datos:**
   - No expongas el puerto 5432 públicamente
   - Usa redes privadas de Docker

---

## 📞 Soporte

Si encuentras problemas:

1. Revisa los logs: `docker compose logs -f`
2. Verifica la documentación de la API: http://localhost:8000/docs
3. Consulta esta guía de solución de problemas

---

## 📄 Licencia

Este proyecto es parte del Sistema de Visitas PAE del Departamento del Cauca.

---

**¡Sistema listo para usar! 🎉**

Usuario por defecto:
- Email: `admin@test.com`
- Password: `admin`

Endpoints importantes:
- API: http://localhost:8000
- Documentación: http://localhost:8000/docs
- Base de datos: localhost:5432

