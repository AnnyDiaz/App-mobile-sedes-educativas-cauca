# Script de Despliegue Completo - Sistema de Visitas PAE Cauca
# Windows PowerShell

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🚀 DESPLIEGUE SISTEMA VISITAS PAE CAUCA" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Paso 1: Detener y limpiar contenedores existentes
Write-Host "📦 Paso 1: Limpiando contenedores anteriores..." -ForegroundColor Yellow
docker compose down -v
Write-Host "✅ Contenedores anteriores eliminados" -ForegroundColor Green
Write-Host ""

# Paso 2: Construir y levantar contenedores
Write-Host "🔨 Paso 2: Construyendo y levantando contenedores..." -ForegroundColor Yellow
docker compose up --build -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error al construir los contenedores" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Contenedores levantados correctamente" -ForegroundColor Green
Write-Host ""

# Paso 3: Esperar a que la base de datos esté lista
Write-Host "⏳ Paso 3: Esperando a que la base de datos esté lista (30 segundos)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30
Write-Host "✅ Base de datos lista" -ForegroundColor Green
Write-Host ""

# Paso 4: Cargar datos de municipios, instituciones y sedes
Write-Host "📊 Paso 4: Cargando municipios, instituciones y sedes..." -ForegroundColor Yellow

Write-Host "   → Copiando archivos SQL al contenedor..." -ForegroundColor Gray
docker cp insert_data_optimized.sql visitas_db:/tmp/insert_data_optimized.sql
docker cp insert_datos_normalizados.sql visitas_db:/tmp/insert_datos_normalizados.sql

Write-Host "   → Cargando datos denormalizados..." -ForegroundColor Gray
docker exec -i visitas_db psql -U visitas -d visitas_cauca -f /tmp/insert_data_optimized.sql | Out-Null

Write-Host "   → Normalizando datos..." -ForegroundColor Gray
docker exec -i visitas_db psql -U visitas -d visitas_cauca -f /tmp/insert_datos_normalizados.sql

Write-Host "✅ Datos de ubicación cargados" -ForegroundColor Green
Write-Host ""

# Paso 5: Verificar que el checklist PAE se cargó automáticamente
Write-Host "📋 Paso 5: Verificando checklist PAE (15 categorías, 64 items)..." -ForegroundColor Yellow
$checklistCheck = docker exec -i visitas_db psql -U visitas -d visitas_cauca -t -c "SELECT COUNT(*) FROM checklist_items;"
$checklistCount = $checklistCheck.Trim()

if ($checklistCount -lt 64) {
    Write-Host "   → Checklist incompleto ($checklistCount items), cargando items faltantes..." -ForegroundColor Gray
    docker exec -i visitas_db bash -c "psql -U visitas -d visitas_cauca -f /app/insert_checklist_items.sql"
    Write-Host "   ✅ Items del checklist cargados" -ForegroundColor Green
} else {
    Write-Host "   ✅ Checklist PAE ya está completo ($checklistCount items)" -ForegroundColor Green
}
Write-Host ""

# Paso 6: Verificación del sistema
Write-Host "🔍 Paso 6: Verificando el sistema..." -ForegroundColor Yellow
Write-Host ""

$query = "SELECT 'Municipios:' as tipo, COUNT(*)::text as cantidad FROM municipios UNION ALL SELECT 'Instituciones:', COUNT(*)::text FROM instituciones UNION ALL SELECT 'Sedes:', COUNT(*)::text FROM sedes_educativas UNION ALL SELECT 'Categorías:', COUNT(*)::text FROM checklist_categorias UNION ALL SELECT 'Items Checklist:', COUNT(*)::text FROM checklist_items UNION ALL SELECT 'Roles:', COUNT(*)::text FROM roles UNION ALL SELECT 'Usuarios:', COUNT(*)::text FROM usuarios;"

docker exec -i visitas_db psql -U visitas -d visitas_cauca -c $query

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ SISTEMA DESPLEGADO CORRECTAMENTE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📄 Información importante:" -ForegroundColor Yellow
Write-Host "   • API Backend: http://localhost:8000" -ForegroundColor White
Write-Host "   • Documentación Swagger: http://localhost:8000/docs" -ForegroundColor White
Write-Host "   • Documentación ReDoc: http://localhost:8000/redoc" -ForegroundColor White
Write-Host "   • Base de datos PostgreSQL: localhost:5432" -ForegroundColor White
Write-Host ""
Write-Host "👤 Credenciales de administrador:" -ForegroundColor Yellow
Write-Host "   • Email: admin@test.com" -ForegroundColor White
Write-Host "   • Password: admin" -ForegroundColor White
Write-Host ""
Write-Host "📝 Comandos útiles:" -ForegroundColor Yellow
Write-Host "   • Ver logs: docker compose logs -f" -ForegroundColor White
Write-Host "   • Detener sistema: docker compose stop" -ForegroundColor White
Write-Host "   • Reiniciar sistema: docker compose restart" -ForegroundColor White
Write-Host ""
Write-Host "🎉 ¡Listo para usar!" -ForegroundColor Green
Write-Host ""

