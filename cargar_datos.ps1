# Script PowerShell para cargar y normalizar datos de instituciones educativas

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "📦 SISTEMA DE CARGA DE DATOS NORMALIZADOS" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Usar credenciales del docker-compose.yml (visitas/visitas)
$DB_USER = if ($env:DB_USER) { $env:DB_USER } else { "visitas" }
$DB_PASSWORD = if ($env:DB_PASSWORD) { $env:DB_PASSWORD } else { "visitas" }
Write-Host "📌 Usando usuario de BD: $DB_USER" -ForegroundColor Green

Write-Host ""
Write-Host "🔹 PASO 1: Cargando datos denormalizados..." -ForegroundColor Yellow
docker cp insert_data_optimized.sql visitas_db:/tmp/insert_data_optimized.sql
docker exec -i visitas_db psql -U $DB_USER -d visitas_cauca -f /tmp/insert_data_optimized.sql

Write-Host ""
Write-Host "🔹 PASO 2: Normalizando datos..." -ForegroundColor Yellow
docker cp insert_datos_normalizados.sql visitas_db:/tmp/insert_datos_normalizados.sql
docker exec -i visitas_db psql -U $DB_USER -d visitas_cauca -f /tmp/insert_datos_normalizados.sql

Write-Host ""
Write-Host "🔹 PASO 3: Verificando carga..." -ForegroundColor Yellow
docker exec -i visitas_db psql -U $DB_USER -d visitas_cauca -c "
SELECT 
    (SELECT COUNT(*) FROM municipios) as municipios,
    (SELECT COUNT(*) FROM instituciones) as instituciones,
    (SELECT COUNT(*) FROM sedes_educativas) as sedes;
"

Write-Host ""
Write-Host "✅ ¡Datos normalizados cargados exitosamente!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan

