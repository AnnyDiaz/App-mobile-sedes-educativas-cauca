-- Script de consolidación de tablas de instituciones educativas
-- Opción 1: Migrar datos de instituciones_educativas a instituciones + sedes_educativas
-- 
-- IMPORTANTE: Ejecutar en orden y verificar cada paso antes de continuar

-- ========================================
-- PASO 1: ANÁLISIS PREVIO
-- ========================================
SELECT 'ANÁLISIS PREVIO' as paso;
SELECT 'Municipios existentes:' as info, COUNT(*) as total FROM municipios;
SELECT 'Instituciones existentes:' as info, COUNT(*) as total FROM instituciones;
SELECT 'Sedes existentes:' as info, COUNT(*) as total FROM sedes_educativas;
SELECT 'Datos a migrar:' as info, COUNT(*) as total FROM instituciones_educativas;

-- ========================================
-- PASO 2: VERIFICAR MUNICIPIOS
-- ========================================
SELECT 'VERIFICANDO MUNICIPIOS' as paso;

-- Ver municipios únicos en instituciones_educativas que no están en municipios
SELECT DISTINCT ie.municipio 
FROM instituciones_educativas ie 
WHERE ie.municipio NOT IN (SELECT nombre FROM municipios)
ORDER BY ie.municipio;

-- ========================================
-- PASO 3: CREAR BACKUP DE DATOS EXISTENTES
-- ========================================
SELECT 'CREANDO BACKUP' as paso;

-- Crear backup de instituciones existentes
CREATE TABLE IF NOT EXISTS instituciones_backup AS 
SELECT * FROM instituciones;

-- Crear backup de sedes existentes  
CREATE TABLE IF NOT EXISTS sedes_educativas_backup AS 
SELECT * FROM sedes_educativas;

-- ========================================
-- PASO 4: MIGRAR INSTITUCIONES
-- ========================================
SELECT 'MIGRANDO INSTITUCIONES' as paso;

-- Insertar instituciones únicas (solo las que no existen)
INSERT INTO instituciones (nombre, municipio_id)
SELECT DISTINCT 
    ie.institucion,
    m.id as municipio_id
FROM instituciones_educativas ie
JOIN municipios m ON m.nombre = ie.municipio
WHERE ie.institucion NOT IN (SELECT nombre FROM instituciones)
ORDER BY ie.institucion;

-- ========================================
-- PASO 5: MIGRAR SEDES
-- ========================================
SELECT 'MIGRANDO SEDES' as paso;

-- Insertar sedes (evitando duplicados)
INSERT INTO sedes_educativas (nombre_sede, dane, due, municipio_id, institucion_id, principal)
SELECT 
    ie.sede as nombre_sede,
    CONCAT('DUE', LPAD(ROW_NUMBER() OVER (ORDER BY ie.id)::text, 6, '0')) as dane,
    CONCAT('DUE', LPAD(ROW_NUMBER() OVER (ORDER BY ie.id)::text, 6, '0')) as due,
    m.id as municipio_id,
    i.id as institucion_id,
    CASE 
        WHEN ie.sede ILIKE '%principal%' OR ie.sede ILIKE '%sede principal%' THEN true
        ELSE false
    END as principal
FROM instituciones_educativas ie
JOIN municipios m ON m.nombre = ie.municipio
JOIN instituciones i ON i.nombre = ie.institucion
WHERE NOT EXISTS (
    SELECT 1 FROM sedes_educativas se 
    WHERE se.nombre_sede = ie.sede 
    AND se.institucion_id = i.id
)
ORDER BY ie.id;

-- ========================================
-- PASO 6: VERIFICAR MIGRACIÓN
-- ========================================
SELECT 'VERIFICANDO MIGRACIÓN' as paso;

SELECT 'Instituciones después de migración:' as info, COUNT(*) as total FROM instituciones;
SELECT 'Sedes después de migración:' as info, COUNT(*) as total FROM sedes_educativas;

-- Verificar que no hay duplicados
SELECT 'Verificando duplicados en instituciones:' as info;
SELECT nombre, COUNT(*) as duplicados 
FROM instituciones 
GROUP BY nombre 
HAVING COUNT(*) > 1;

SELECT 'Verificando duplicados en sedes:' as info;
SELECT nombre_sede, institucion_id, COUNT(*) as duplicados 
FROM sedes_educativas 
GROUP BY nombre_sede, institucion_id 
HAVING COUNT(*) > 1;

-- ========================================
-- PASO 7: ESTADÍSTICAS FINALES
-- ========================================
SELECT 'ESTADÍSTICAS FINALES' as paso;

SELECT 
    'Instituciones por municipio' as info,
    m.nombre as municipio,
    COUNT(i.id) as total_instituciones
FROM municipios m
LEFT JOIN instituciones i ON i.municipio_id = m.id
GROUP BY m.id, m.nombre
ORDER BY total_instituciones DESC
LIMIT 10;

SELECT 
    'Sedes por institución' as info,
    i.nombre as institucion,
    COUNT(s.id) as total_sedes
FROM instituciones i
LEFT JOIN sedes_educativas s ON s.institucion_id = i.id
GROUP BY i.id, i.nombre
ORDER BY total_sedes DESC
LIMIT 10;
