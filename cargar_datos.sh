#!/bin/bash
# Script para cargar y normalizar datos de instituciones educativas en el contenedor Docker

echo "=========================================="
echo "📦 SISTEMA DE CARGA DE DATOS NORMALIZADOS"
echo "=========================================="

# Usar credenciales del docker-compose.yml (visitas/visitas)
DB_USER="${DB_USER:-visitas}"
DB_PASSWORD="${DB_PASSWORD:-visitas}"
echo "📌 Usando usuario de BD: $DB_USER"

echo ""
echo "🔹 PASO 1: Cargando datos denormalizados..."
docker cp insert_data_optimized.sql visitas_db:/tmp/insert_data_optimized.sql
docker exec -i visitas_db psql -U $DB_USER -d visitas_cauca -f /tmp/insert_data_optimized.sql

echo ""
echo "🔹 PASO 2: Normalizando datos a municipios, instituciones y sedes_educativas..."
docker cp insert_datos_normalizados.sql visitas_db:/tmp/insert_datos_normalizados.sql
docker exec -i visitas_db psql -U $DB_USER -d visitas_cauca -f /tmp/insert_datos_normalizados.sql

echo ""
echo "🔹 PASO 3: Verificando conteos finales..."
docker exec -i visitas_db psql -U $DB_USER -d visitas_cauca -c "
SELECT 
    (SELECT COUNT(*) FROM municipios) AS municipios,
    (SELECT COUNT(*) FROM instituciones) AS instituciones,
    (SELECT COUNT(*) FROM sedes_educativas) AS sedes;
"

echo ""
echo "📊 PASO 4: Mostrando ejemplos de datos..."
echo ""
echo "--- Primeros 5 municipios ---"
docker exec -i visitas_db psql -U $DB_USER -d visitas_cauca -c "SELECT * FROM municipios LIMIT 5;"

echo ""
echo "--- Primeras 5 instituciones ---"
docker exec -i visitas_db psql -U $DB_USER -d visitas_cauca -c "SELECT * FROM instituciones LIMIT 5;"

echo ""
echo "--- Primeras 5 sedes ---"
docker exec -i visitas_db psql -U $DB_USER -d visitas_cauca -c "SELECT * FROM sedes_educativas LIMIT 5;"

echo ""
echo "✅ ¡Datos normalizados cargados exitosamente!"
echo "=========================================="

