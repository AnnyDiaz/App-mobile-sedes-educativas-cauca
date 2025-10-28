-- insert_datos_normalizados.sql
-- Normalizar datos desde instituciones_educativas -> municipios, instituciones, sedes_educativas

BEGIN;

-- 1) Insertar municipios únicos
INSERT INTO municipios (nombre)
SELECT DISTINCT trim(ie.municipio) AS nombre
FROM instituciones_educativas ie
WHERE ie.municipio IS NOT NULL
  AND trim(ie.municipio) <> ''
  AND NOT EXISTS (
    SELECT 1 FROM municipios m WHERE m.nombre = trim(ie.municipio)
  );

-- 2) Insertar instituciones vinculadas al municipio
INSERT INTO instituciones (nombre, municipio_id)
SELECT DISTINCT
  trim(ie.institucion) AS nombre,
  m.id AS municipio_id
FROM instituciones_educativas ie
JOIN municipios m ON m.nombre = trim(ie.municipio)
WHERE ie.institucion IS NOT NULL
  AND trim(ie.institucion) <> ''
  AND NOT EXISTS (
    SELECT 1 FROM instituciones i
    WHERE i.nombre = trim(ie.institucion) AND i.municipio_id = m.id
  );

-- 3) Insertar sedes educativas
INSERT INTO sedes_educativas (
  nombre_sede,
  dane,
  due,
  lat,
  lon,
  principal,
  municipio_id,
  institucion_id
)
SELECT DISTINCT
  trim(ie.sede) AS nombre_sede,
  NULL::varchar AS dane,
  NULL::varchar AS due,
  NULL::double precision AS lat,
  NULL::double precision AS lon,
  (CASE 
    WHEN lower(ie.sede) LIKE '%sede principal%' 
    OR lower(ie.sede) LIKE '%principal%' 
    THEN true 
    ELSE false 
  END) AS principal,
  m.id AS municipio_id,
  i.id AS institucion_id
FROM instituciones_educativas ie
JOIN municipios m ON m.nombre = trim(ie.municipio)
JOIN instituciones i ON i.nombre = trim(ie.institucion) AND i.municipio_id = m.id
WHERE ie.sede IS NOT NULL
  AND trim(ie.sede) <> ''
  AND NOT EXISTS (
    SELECT 1 FROM sedes_educativas s
    WHERE s.nombre_sede = trim(ie.sede)
      AND s.institucion_id = i.id
      AND s.municipio_id = m.id
  );

COMMIT;

-- Mostrar conteos de verificación
SELECT
  (SELECT COUNT(*) FROM municipios) AS municipios,
  (SELECT COUNT(*) FROM instituciones) AS instituciones,
  (SELECT COUNT(*) FROM sedes_educativas) AS sedes;

