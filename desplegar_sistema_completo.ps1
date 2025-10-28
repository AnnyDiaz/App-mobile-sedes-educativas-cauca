# Script de despliegue completo del sistema
Write-Host "🐳 CREANDO Y DESPLEGANDO SISTEMA COMPLETO" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

# 1. Verificar Docker
Write-Host "1️⃣ Verificando Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "✅ Docker: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker no está disponible" -ForegroundColor Red
    exit 1
}

# 2. Limpiar sistema
Write-Host "2️⃣ Limpiando sistema Docker..." -ForegroundColor Yellow
docker compose down 2>$null
docker container prune -f 2>$null
docker volume prune -f 2>$null

# 3. Crear archivo .env completo
Write-Host "3️⃣ Creando archivo .env..." -ForegroundColor Yellow
@"
SECRET_KEY=clave_super_secreta_para_produccion_2025
DATABASE_URL=postgresql://postgres:postgres@visitas_db:5432/visitas_cauca
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080,http://localhost:51377,http://localhost:50063,http://localhost:51598,http://127.0.0.1:51598,http://localhost:52388,http://127.0.0.1:52388,http://localhost:53924,http://127.0.0.1:53924,http://192.168.1.83:3000,http://192.168.1.83:8080,http://192.168.1.83:51598,http://192.168.1.83:52388,http://192.168.1.83:53924,http://localhost:5000,http://127.0.0.1:5000,http://localhost:60390,http://127.0.0.1:60390,http://localhost:*,http://127.0.0.1:*
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SENDER_EMAIL=
SENDER_PASSWORD=
SENDER_NAME=Sistema de Visitas Cauca
"@ | Out-File -FilePath ".env" -Encoding UTF8

# 4. Construir y ejecutar contenedores
Write-Host "4️⃣ Construyendo y ejecutando contenedores..." -ForegroundColor Yellow
Write-Host "Ejecutando: docker compose up -d --build" -ForegroundColor Cyan
docker compose up -d --build

# 5. Esperar inicialización
Write-Host "5️⃣ Esperando inicialización (30 segundos)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# 6. Verificar contenedores
Write-Host "6️⃣ Verificando contenedores..." -ForegroundColor Yellow
$containers = docker ps
Write-Host "Contenedores ejecutándose:" -ForegroundColor Cyan
Write-Host $containers -ForegroundColor White

# 7. Verificar logs de la API
Write-Host "7️⃣ Verificando logs de la API..." -ForegroundColor Yellow
Write-Host "Logs de visitas_api:" -ForegroundColor Cyan
docker logs visitas_api --tail=20

# 8. Inicializar sistema
Write-Host "8️⃣ Inicializando sistema..." -ForegroundColor Yellow
Write-Host "Ejecutando script de inicialización..." -ForegroundColor Cyan
docker exec visitas_api python -c "
import os
import sys
os.environ['DATABASE_URL'] = 'postgresql://postgres:postgres@visitas_db:5432/visitas_cauca'
sys.path.append('/app')
from app.scripts.init_admin_system import main
main()
"

# 9. Probar sistema
Write-Host "9️⃣ Probando sistema..." -ForegroundColor Yellow

# Probar API
Write-Host "Probando API..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/" -UseBasicParsing -TimeoutSec 10
    Write-Host "✅ API responde: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "❌ API no responde: $($_.Exception.Message)" -ForegroundColor Red
}

# Probar municipios
Write-Host "Probando municipios..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/api/municipios" -UseBasicParsing -TimeoutSec 10
    Write-Host "✅ Municipios disponibles: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "❌ Municipios no disponibles: $($_.Exception.Message)" -ForegroundColor Red
}

# Probar login
Write-Host "Probando login..." -ForegroundColor Cyan
try {
    $loginData = @{
        correo = "admin@test.com"
        contrasena = "admin"
    } | ConvertTo-Json

    $response = Invoke-WebRequest -Uri "http://localhost:8000/api/login" -Method POST -Body $loginData -ContentType "application/json" -UseBasicParsing -TimeoutSec 15
    
    if ($response.Content -match "access_token") {
        Write-Host "✅ Login exitoso" -ForegroundColor Green
        $token = ($response.Content | ConvertFrom-Json).access_token
        Write-Host "🔑 Token obtenido: $($token.Substring(0,20))..." -ForegroundColor Cyan
        
        # Probar endpoint protegido
        $headers = @{
            "Authorization" = "Bearer $token"
        }
        
        try {
            $profileResponse = Invoke-WebRequest -Uri "http://localhost:8000/api/perfil" -Headers $headers -UseBasicParsing -TimeoutSec 10
            Write-Host "✅ Endpoint protegido funciona: $($profileResponse.StatusCode)" -ForegroundColor Green
        } catch {
            Write-Host "❌ Endpoint protegido no funciona: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Login falló" -ForegroundColor Red
        Write-Host "Respuesta: $($response.Content)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error en login: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "=========================================" -ForegroundColor Green
Write-Host "🎉 Sistema creado y desplegado" -ForegroundColor Green
Write-Host "📱 API disponible en: http://localhost:8000" -ForegroundColor Cyan
Write-Host "📚 Documentación en: http://localhost:8000/docs" -ForegroundColor Cyan
Write-Host "🔐 Credenciales admin: admin@test.com / admin" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Green
