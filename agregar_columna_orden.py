#!/usr/bin/env python3
"""
Script para agregar la columna orden a la tabla checklist_items
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import engine
from sqlalchemy import text

def agregar_columna_orden():
    """Agrega la columna orden a la tabla checklist_items"""
    try:
        with engine.connect() as conn:
            # Verificar si la columna orden ya existe
            result = conn.execute(text("""
                SELECT EXISTS (
                    SELECT FROM information_schema.columns 
                    WHERE table_name = 'checklist_items' 
                    AND column_name = 'orden'
                );
            """))
            existe_columna = result.scalar()
            
            if existe_columna:
                print("✅ La columna 'orden' ya existe en checklist_items")
                return
            
            # Agregar la columna orden
            print("🔧 Agregando columna 'orden' a checklist_items...")
            conn.execute(text("""
                ALTER TABLE checklist_items 
                ADD COLUMN orden INTEGER NOT NULL DEFAULT 1;
            """))
            
            # Actualizar los valores de orden basados en el ID
            print("📝 Actualizando valores de orden...")
            conn.execute(text("""
                UPDATE checklist_items 
                SET orden = id 
                WHERE orden IS NULL OR orden = 1;
            """))
            
            conn.commit()
            print("✅ Columna 'orden' agregada y actualizada correctamente")
            
    except Exception as e:
        print(f"❌ Error al agregar columna: {e}")

if __name__ == "__main__":
    print("🔧 Agregando columna orden a checklist_items...")
    agregar_columna_orden()
    print("✅ Proceso completado!") 