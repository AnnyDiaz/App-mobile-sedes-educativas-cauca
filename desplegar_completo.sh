#!/bin/bash

# Script de Despliegue Completo - Sistema de Visitas PAE Cauca
# Linux/Mac

# Colores para output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================"
echo -e "🚀 DESPLIEGUE SISTEMA VISITAS PAE CAUCA"
echo -e "========================================${NC}"
echo ""

# Paso 1: Detener y limpiar contenedores existentes
echo -e "${YELLOW}📦 Paso 1: Limpiando contenedores anteriores...${NC}"
docker compose down -v
echo -e "${GREEN}✅ Contenedores anteriores eliminados${NC}"
echo ""

# Paso 2: Construir y levantar contenedores
echo -e "${YELLOW}🔨 Paso 2: Construyendo y levantando contenedores...${NC}"
docker compose up --build -d

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error al construir los contenedores${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Contenedores levantados correctamente${NC}"
echo ""

# Paso 3: Esperar a que la base de datos esté lista
echo -e "${YELLOW}⏳ Paso 3: Esperando a que la base de datos esté lista (30 segundos)...${NC}"
sleep 30
echo -e "${GREEN}✅ Base de datos lista${NC}"
echo ""

# Paso 4: Cargar datos de municipios, instituciones y sedes
echo -e "${YELLOW}📊 Paso 4: Cargando municipios, instituciones y sedes...${NC}"

echo -e "${GRAY}   → Copiando archivos SQL al contenedor...${NC}"
docker cp insert_data_optimized.sql visitas_db:/tmp/insert_data_optimized.sql
docker cp insert_datos_normalizados.sql visitas_db:/tmp/insert_datos_normalizados.sql

echo -e "${GRAY}   → Cargando datos denormalizados...${NC}"
docker exec -i visitas_db psql -U visitas -d visitas_cauca -f /tmp/insert_data_optimized.sql > /dev/null 2>&1

echo -e "${GRAY}   → Normalizando datos...${NC}"
docker exec -i visitas_db psql -U visitas -d visitas_cauca -f /tmp/insert_datos_normalizados.sql

echo -e "${GREEN}✅ Datos de ubicación cargados${NC}"
echo ""

# Paso 5: Verificar que el checklist PAE se cargó automáticamente
echo -e "${YELLOW}📋 Paso 5: Verificando checklist PAE (15 categorías, 64 items)...${NC}"
checklistCount=$(docker exec -i visitas_db psql -U visitas -d visitas_cauca -t -c "SELECT COUNT(*) FROM checklist_items;" | tr -d ' ')

if [ "$checklistCount" -lt 64 ]; then
    echo -e "${GRAY}   → Checklist incompleto ($checklistCount items), cargando items faltantes...${NC}"
    docker exec -i visitas_db bash -c "psql -U visitas -d visitas_cauca -f /app/insert_checklist_items.sql"
    echo -e "${GREEN}   ✅ Items del checklist cargados${NC}"
else
    echo -e "${GREEN}   ✅ Checklist PAE ya está completo ($checklistCount items)${NC}"
fi
echo ""

# Paso 6: Verificación del sistema
echo -e "${YELLOW}🔍 Paso 6: Verificando el sistema...${NC}"
echo ""

docker exec -i visitas_db psql -U visitas -d visitas_cauca -c "
SELECT 'Municipios:' as tipo, COUNT(*)::text as cantidad FROM municipios 
UNION ALL SELECT 'Instituciones:', COUNT(*)::text FROM instituciones 
UNION ALL SELECT 'Sedes:', COUNT(*)::text FROM sedes_educativas 
UNION ALL SELECT 'Categorías:', COUNT(*)::text FROM checklist_categorias 
UNION ALL SELECT 'Items Checklist:', COUNT(*)::text FROM checklist_items 
UNION ALL SELECT 'Roles:', COUNT(*)::text FROM roles 
UNION ALL SELECT 'Usuarios:', COUNT(*)::text FROM usuarios;
"

echo ""
echo -e "${CYAN}========================================"
echo -e "${GREEN}✅ SISTEMA DESPLEGADO CORRECTAMENTE!${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo -e "${YELLOW}📄 Información importante:${NC}"
echo -e "   • API Backend: http://localhost:8000"
echo -e "   • Documentación Swagger: http://localhost:8000/docs"
echo -e "   • Documentación ReDoc: http://localhost:8000/redoc"
echo -e "   • Base de datos PostgreSQL: localhost:5432"
echo ""
echo -e "${YELLOW}👤 Credenciales de administrador:${NC}"
echo -e "   • Email: admin@test.com"
echo -e "   • Password: admin"
echo ""
echo -e "${YELLOW}📝 Comandos útiles:${NC}"
echo -e "   • Ver logs: docker compose logs -f"
echo -e "   • Detener sistema: docker compose stop"
echo -e "   • Reiniciar sistema: docker compose restart"
echo ""
echo -e "${GREEN}🎉 ¡Listo para usar!${NC}"
echo ""

