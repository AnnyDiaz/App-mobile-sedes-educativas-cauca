#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para procesar y optimizar los datos de instituciones educativas
"""

import re
import os

def process_insert_data():
    """Procesa el archivo insert_data.sql y crea una versión optimizada"""
    
    print("🔄 Procesando archivo insert_data.sql...")
    
    # Leer el archivo original
    with open('insert_data.sql', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Extraer todas las líneas INSERT usando regex más robusta
    pattern = r"INSERT INTO instituciones_educativas \(municipio, institucion, sede\) VALUES \('([^']*(?:''[^']*)*)', '([^']*(?:''[^']*)*)', '([^']*(?:''[^']*)*)'\);"
    insert_lines = re.findall(pattern, content)
    
    print(f"📊 Encontrados {len(insert_lines)} registros")
    
    # Crear archivo optimizado
    with open('insert_data_optimized.sql', 'w', encoding='utf-8') as f:
        # Escribir header
        f.write("""-- Script SQL optimizado para insertar datos de instituciones educativas
-- Generado automáticamente para mejor rendimiento

-- Crear tabla si no existe
CREATE TABLE IF NOT EXISTS instituciones_educativas (
    id SERIAL PRIMARY KEY,
    municipio VARCHAR(255) NOT NULL,
    institucion VARCHAR(255) NOT NULL,
    sede VARCHAR(255) NOT NULL
);

-- Crear índices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_instituciones_municipio ON instituciones_educativas(municipio);
CREATE INDEX IF NOT EXISTS idx_instituciones_institucion ON instituciones_educativas(institucion);

-- Limpiar datos existentes (opcional - descomenta si quieres reemplazar)
-- TRUNCATE TABLE instituciones_educativas RESTART IDENTITY;

-- Insertar datos en lotes para mejor rendimiento
""")
        
        # Procesar en lotes de 100
        batch_size = 100
        for i in range(0, len(insert_lines), batch_size):
            batch = insert_lines[i:i+batch_size]
            
            f.write("INSERT INTO instituciones_educativas (municipio, institucion, sede) VALUES\n")
            
            values = []
            for municipio, institucion, sede in batch:
                # Escapar comillas simples correctamente
                municipio = municipio.replace("'", "''")
                institucion = institucion.replace("'", "''")
                sede = sede.replace("'", "''")
                values.append(f"('{municipio}', '{institucion}', '{sede}')")
            
            f.write(',\n'.join(values))
            f.write(';\n\n')
            
            print(f"✅ Procesado lote {i//batch_size + 1}/{(len(insert_lines)-1)//batch_size + 1}")
    
    print(f"🎉 Archivo optimizado creado: insert_data_optimized.sql")
    print(f"📈 Total de registros: {len(insert_lines)}")
    print(f"📦 Lotes creados: {(len(insert_lines)-1)//batch_size + 1}")

if __name__ == "__main__":
    process_insert_data()
