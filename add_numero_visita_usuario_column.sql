-- Migración para agregar la columna numero_visita_usuario a la tabla visitas_completas_pae
-- Ejecutar este script en la base de datos antes de usar la aplicación

-- Agregar la columna numero_visita_usuario
ALTER TABLE visitas_completas_pae 
ADD COLUMN numero_visita_usuario INTEGER;

-- Crear un índice para mejorar el rendimiento de las consultas
CREATE INDEX idx_visitas_completas_pae_numero_visita_usuario 
ON visitas_completas_pae(numero_visita_usuario);

-- Comentario para documentar la columna
COMMENT ON COLUMN visitas_completas_pae.numero_visita_usuario IS 'Número secuencial de visita por usuario (ej: 1, 2, 3...)';

-- Verificar que la columna se agregó correctamente
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'visitas_completas_pae' 
AND column_name = 'numero_visita_usuario';
