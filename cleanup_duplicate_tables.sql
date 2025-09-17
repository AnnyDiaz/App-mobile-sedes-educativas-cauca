-- Script para limpiar tablas duplicadas después de la migración exitosa
-- IMPORTANTE: Solo ejecutar DESPUÉS de verificar que la migración fue exitosa

-- ========================================
-- PASO 1: VERIFICACIÓN FINAL
-- ========================================
SELECT 'VERIFICACIÓN FINAL ANTES DE LIMPIEZA' as paso;

-- Verificar que tenemos datos en las tablas consolidadas
SELECT 'Instituciones consolidadas:' as info, COUNT(*) as total FROM instituciones;
SELECT 'Sedes consolidadas:' as info, COUNT(*) as total FROM sedes_educativas;

-- Verificar que no hay referencias a instituciones_educativas en otras tablas
SELECT 'Verificando referencias a instituciones_educativas:' as info;
SELECT 
    table_name, 
    column_name 
FROM information_schema.columns 
WHERE column_name LIKE '%institucion%' 
AND table_name != 'instituciones_educativas'
AND table_name != 'instituciones'
AND table_name != 'sedes_educativas';

-- ========================================
-- PASO 2: CREAR BACKUP DE LA TABLA DUPLICADA
-- ========================================
SELECT 'CREANDO BACKUP DE TABLA DUPLICADA' as paso;

-- Crear backup completo de instituciones_educativas
CREATE TABLE IF NOT EXISTS instituciones_educativas_backup AS 
SELECT * FROM instituciones_educativas;

SELECT 'Backup creado:' as info, COUNT(*) as total FROM instituciones_educativas_backup;

-- ========================================
-- PASO 3: ELIMINAR TABLA DUPLICADA
-- ========================================
SELECT 'ELIMINANDO TABLA DUPLICADA' as paso;

-- Eliminar la tabla duplicada
DROP TABLE IF EXISTS instituciones_educativas;

-- ========================================
-- PASO 4: VERIFICAR LIMPIEZA
-- ========================================
SELECT 'VERIFICANDO LIMPIEZA' as paso;

-- Verificar que la tabla fue eliminada
SELECT 'Tablas restantes:' as info;
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%institucion%' 
ORDER BY table_name;

-- ========================================
-- PASO 5: ESTADÍSTICAS FINALES
-- ========================================
SELECT 'ESTADÍSTICAS FINALES DEL SISTEMA' as paso;

-- Resumen de la estructura consolidada
SELECT 
    'Estructura final del sistema:' as info,
    'instituciones' as tabla,
    COUNT(*) as registros
FROM instituciones
UNION ALL
SELECT 
    'Estructura final del sistema:' as info,
    'sedes_educativas' as tabla,
    COUNT(*) as registros
FROM sedes_educativas
UNION ALL
SELECT 
    'Estructura final del sistema:' as info,
    'municipios' as tabla,
    COUNT(*) as registros
FROM municipios;

-- Top 10 municipios con más instituciones
SELECT 
    'Top municipios por instituciones:' as info,
    m.nombre as municipio,
    COUNT(i.id) as total_instituciones,
    COUNT(s.id) as total_sedes
FROM municipios m
LEFT JOIN instituciones i ON i.municipio_id = m.id
LEFT JOIN sedes_educativas s ON s.municipio_id = m.id
GROUP BY m.id, m.nombre
ORDER BY total_instituciones DESC
LIMIT 10;
