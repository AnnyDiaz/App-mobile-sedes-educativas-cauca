# Script de despliegue completo para App Sedes Educativas Cauca (PowerShell)
# Este script automatiza todo el proceso de actualización y despliegue

param(
    [switch]$AutoCommit,
    [switch]$CleanDocker,
    [switch]$SkipTests
)

# Configurar para salir en caso de error
$ErrorActionPreference = "Stop"

Write-Host "🚀 Iniciando despliegue completo del sistema..." -ForegroundColor Blue

# Función para imprimir mensajes con color
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "docker-compose.yml")) {
    Write-Error "No se encontró docker-compose.yml. Ejecuta este script desde el directorio raíz del proyecto."
    exit 1
}

# Paso 1: Verificar cambios pendientes
Write-Status "Verificando cambios pendientes en Git..."
$gitStatus = git status --porcelain
if ($gitStatus) {
    if ($AutoCommit) {
        git add .
        git commit -m "Auto-commit: Actualización del sistema antes del despliegue"
        Write-Success "Cambios commiteados automáticamente"
    } else {
        Write-Warning "Hay cambios sin commitear. ¿Deseas hacer commit automático? (y/n)"
        $response = Read-Host
        if ($response -match "^[Yy]$") {
            git add .
            git commit -m "Auto-commit: Actualización del sistema antes del despliegue"
            Write-Success "Cambios commiteados"
        } else {
            Write-Warning "Continuando sin commitear cambios..."
        }
    }
} else {
    Write-Success "No hay cambios pendientes"
}

# Paso 2: Detener contenedores existentes
Write-Status "Deteniendo contenedores existentes..."
try {
    docker-compose down 2>$null
    Write-Success "Contenedores detenidos"
} catch {
    Write-Warning "No había contenedores ejecutándose"
}

# Paso 3: Limpiar sistema Docker (opcional)
if ($CleanDocker) {
    Write-Status "Limpiando sistema Docker..."
    docker system prune -a -f
    Write-Success "Sistema Docker limpiado"
} else {
    Write-Status "¿Deseas limpiar el sistema Docker completamente? (y/n)"
    $response = Read-Host
    if ($response -match "^[Yy]$") {
        Write-Status "Limpiando sistema Docker..."
        docker system prune -a -f
        Write-Success "Sistema Docker limpiado"
    }
}

# Paso 4: Reconstruir y ejecutar contenedores
Write-Status "Reconstruyendo y ejecutando contenedores..."
docker-compose up -d --build
Write-Success "Contenedores reconstruidos y ejecutándose"

# Paso 5: Esperar a que los contenedores estén listos
Write-Status "Esperando a que los contenedores estén listos..."
Start-Sleep -Seconds 10

# Paso 6: Verificar que los contenedores estén funcionando
Write-Status "Verificando estado de los contenedores..."
$apiContainer = docker ps | Select-String "visitas_api"
$dbContainer = docker ps | Select-String "visitas_db"

if ($apiContainer) {
    Write-Success "Contenedor de API está funcionando"
} else {
    Write-Error "Contenedor de API no está funcionando"
    exit 1
}

if ($dbContainer) {
    Write-Success "Contenedor de base de datos está funcionando"
} else {
    Write-Error "Contenedor de base de datos no está funcionando"
    exit 1
}

# Paso 7: Ejecutar script de limpieza del sistema
Write-Status "Ejecutando script de limpieza del sistema..."
try {
    $cleanupScript = @"
import os
os.environ['DATABASE_URL'] = 'postgresql://postgres:postgres@visitas_db:5432/visitas_cauca'
import sys
sys.path.append('.')
exec(open('app/scripts/limpiar_sistema.py').read())
"@
    
    docker exec visitas_api python -c $cleanupScript
    Write-Success "Sistema limpiado correctamente"
} catch {
    Write-Error "Error al limpiar el sistema: $_"
    exit 1
}

# Paso 8: Verificar API
Write-Status "Verificando que la API esté funcionando..."
Start-Sleep -Seconds 5

# Probar endpoint de salud
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/" -UseBasicParsing
    Write-Success "API está respondiendo"
} catch {
    Write-Error "API no está respondiendo: $_"
    exit 1
}

# Probar endpoint de municipios
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/api/municipios" -UseBasicParsing
    Write-Success "Endpoint de municipios está funcionando"
} catch {
    Write-Warning "Endpoint de municipios no está respondiendo: $_"
}

# Paso 9: Probar login de administrador
if (-not $SkipTests) {
    Write-Status "Probando login de administrador..."
    try {
        $loginBody = @{
            correo = "admin@test.com"
            contrasena = "admin"
        } | ConvertTo-Json
        
        $response = Invoke-WebRequest -Uri "http://localhost:8000/api/login" -Method POST -Body $loginBody -ContentType "application/json" -UseBasicParsing
        
        if ($response.Content -match "access_token") {
            Write-Success "Login de administrador funciona correctamente"
        } else {
            Write-Warning "Login de administrador no funciona: $($response.Content)"
        }
    } catch {
        Write-Warning "Error al probar login: $_"
    }
}

# Paso 10: Mostrar información del sistema
Write-Status "Información del sistema:"
Write-Host "  🌐 API disponible en: http://localhost:8000" -ForegroundColor Cyan
Write-Host "  📚 Documentación API: http://localhost:8000/docs" -ForegroundColor Cyan
Write-Host "  👤 Usuario administrador: admin@test.com" -ForegroundColor Cyan
Write-Host "  🔑 Contraseña: admin" -ForegroundColor Cyan
Write-Host "  🗄️ Base de datos: PostgreSQL en puerto 5432" -ForegroundColor Cyan

# Paso 11: Mostrar logs de los contenedores
Write-Status "Mostrando logs recientes de los contenedores..."
Write-Host "--- Logs del contenedor de API ---" -ForegroundColor Yellow
docker logs --tail=10 visitas_api

Write-Host ""
Write-Host "--- Logs del contenedor de base de datos ---" -ForegroundColor Yellow
docker logs --tail=5 visitas_db

# Paso 12: Instrucciones finales
Write-Success "🎉 Despliegue completado exitosamente!"
Write-Host ""
Write-Host "📋 Próximos pasos:" -ForegroundColor Green
Write-Host "  1. Abre la app móvil Flutter"
Write-Host "  2. Configura la URL en frontend_visitas/lib/config.dart si es necesario"
Write-Host "  3. Haz login con admin@test.com / admin"
Write-Host "  4. Verifica que el dashboard de administrador funcione"
Write-Host "  5. Prueba la carga de municipios e instituciones"
Write-Host ""
Write-Host "🔧 Comandos útiles:" -ForegroundColor Green
Write-Host "  - Ver logs: docker logs -f visitas_api"
Write-Host "  - Entrar al contenedor: docker exec -it visitas_api bash"
Write-Host "  - Detener sistema: docker-compose down"
Write-Host "  - Reiniciar sistema: docker-compose restart"
Write-Host ""
Write-Host "📞 Si hay problemas:" -ForegroundColor Green
Write-Host "  - Revisa los logs: docker logs visitas_api"
Write-Host "  - Verifica la configuración de red"
Write-Host "  - Asegúrate de que el puerto 8000 esté disponible"
