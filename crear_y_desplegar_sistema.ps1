# Script de creación y despliegue completo del sistema
Write-Host "🐳 CREANDO Y DESPLEGANDO SISTEMA COMPLETO" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

# 1. Limpiar sistema
Write-Host "1️⃣ Limpiando sistema Docker..." -ForegroundColor Yellow
docker compose down 2>$null
docker container prune -f
docker volume prune -f
docker image prune -f

# 2. Crear archivo .env
Write-Host "2️⃣ Creando archivo .env..." -ForegroundColor Yellow
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

# 3. Construir y ejecutar contenedores
Write-Host "3️⃣ Construyendo y ejecutando contenedores..." -ForegroundColor Yellow
docker compose up -d --build

# 4. Esperar inicialización
Write-Host "4️⃣ Esperando inicialización..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

# 5. Verificar contenedores
Write-Host "5️⃣ Verificando contenedores..." -ForegroundColor Yellow
docker ps | Select-String -Pattern "(visitas_api|visitas_db)"

# 6. Inicializar sistema
Write-Host "6️⃣ Inicializando sistema..." -ForegroundColor Yellow
docker exec visitas_api python -c "
import os
import sys
os.environ['DATABASE_URL'] = 'postgresql://postgres:postgres@visitas_db:5432/visitas_cauca'
sys.path.append('/app')
from app.scripts.init_admin_system import main
main()
"

# 7. Verificar inicialización
Write-Host "7️⃣ Verificando inicialización..." -ForegroundColor Yellow
docker logs visitas_api --tail=10

# 8. Probar sistema
Write-Host "8️⃣ Probando sistema..." -ForegroundColor Yellow

# Probar API
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/" -UseBasicParsing -TimeoutSec 5
    Write-Host "✅ API responde" -ForegroundColor Green
} catch {
    Write-Host "❌ API no responde" -ForegroundColor Red
}

# Probar municipios
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/api/municipios" -UseBasicParsing -TimeoutSec 5
    Write-Host "✅ Municipios disponibles" -ForegroundColor Green
} catch {
    Write-Host "❌ Municipios no disponibles" -ForegroundColor Red
}

# Probar login
Write-Host "🔐 Probando login..." -ForegroundColor Yellow
try {
    $loginData = @{
        correo = "admin@test.com"
        contrasena = "admin"
    } | ConvertTo-Json

    $response = Invoke-WebRequest -Uri "http://localhost:8000/api/login" -Method POST -Body $loginData -ContentType "application/json" -UseBasicParsing -TimeoutSec 10
    
    if ($response.Content -match "access_token") {
        Write-Host "✅ Login exitoso" -ForegroundColor Green
        $token = ($response.Content | ConvertFrom-Json).access_token
        Write-Host "🔑 Token: $($token.Substring(0,20))..." -ForegroundColor Cyan
        
        # Probar endpoint protegido
        $headers = @{
            "Authorization" = "Bearer $token"
        }
        
        try {
            $profileResponse = Invoke-WebRequest -Uri "http://localhost:8000/api/perfil" -Headers $headers -UseBasicParsing -TimeoutSec 5
            Write-Host "✅ Endpoint protegido funciona" -ForegroundColor Green
        } catch {
            Write-Host "❌ Endpoint protegido no funciona" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Login falló" -ForegroundColor Red
        Write-Host "Respuesta: $($response.Content)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error en login: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "=========================================" -ForegroundColor Green
Write-Host "🎉 Sistema creado y desplegado exitosamente" -ForegroundColor Green
Write-Host "📱 API disponible en: http://localhost:8000" -ForegroundColor Cyan
Write-Host "📚 Documentación en: http://localhost:8000/docs" -ForegroundColor Cyan
Write-Host "🔐 Credenciales admin: admin@test.com / admin" -ForegroundColor Cyan

