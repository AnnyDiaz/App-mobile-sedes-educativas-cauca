#!/usr/bin/env python3
"""
Script para eliminar las tablas restantes que no necesitamos
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import engine
from sqlalchemy import text

def eliminar_tablas_restantes():
    """Elimina las tablas restantes que no necesitamos"""
    tablas_a_eliminar = [
        'visitas',
        'visita_respuestas'
    ]
    
    print("🗑️ ELIMINANDO TABLAS RESTANTES...")
    
    try:
        with engine.connect() as conn:
            for tabla in tablas_a_eliminar:
                try:
                    # Verificar si la tabla existe
                    result = conn.execute(text(f"""
                        SELECT EXISTS (
                            SELECT FROM information_schema.tables 
                            WHERE table_name = '{tabla}'
                        );
                    """))
                    
                    if result.scalar():
                        print(f"   🗑️ Eliminando tabla: {tabla}")
                        conn.execute(text(f"DROP TABLE IF EXISTS {tabla} CASCADE;"))
                        conn.commit()
                        print(f"   ✅ Tabla {tabla} eliminada")
                    else:
                        print(f"   ⚠️ Tabla {tabla} no existe, saltando...")
                        
                except Exception as e:
                    print(f"   ❌ Error al eliminar {tabla}: {e}")
                    
    except Exception as e:
        print(f"❌ Error general: {e}")

def verificar_tablas_finales():
    """Verifica las tablas que quedan después de la limpieza"""
    tablas_esperadas = [
        'checklist_categorias',
        'checklist_items', 
        'instituciones',
        'municipios',
        'roles',
        'sedes_educativas',
        'usuarios',
        'visita_respuestas_completas',
        'visitas_completas_pae'
    ]
    
    print("\n📋 VERIFICANDO TABLAS FINALES...")
    
    try:
        with engine.connect() as conn:
            result = conn.execute(text("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public'
                ORDER BY table_name;
            """))
            
            tablas_finales = [row[0] for row in result]
            
            print("✅ TABLAS QUE QUEDAN:")
            for tabla in tablas_finales:
                if tabla in tablas_esperadas:
                    print(f"   ✅ {tabla}")
                else:
                    print(f"   ⚠️ {tabla} (no esperada)")
            
            # Verificar que todas las tablas esperadas estén presentes
            faltantes = set(tablas_esperadas) - set(tablas_finales)
            if faltantes:
                print(f"\n❌ TABLAS FALTANTES: {faltantes}")
            else:
                print(f"\n✅ Todas las tablas necesarias están presentes!")
                
    except Exception as e:
        print(f"❌ Error al verificar tablas finales: {e}")

def main():
    print("🧹 LIMPIEZA FINAL DE TABLAS")
    print("=" * 50)
    
    # 1. Eliminar tablas restantes
    print("\n1️⃣ Eliminando tablas restantes...")
    eliminar_tablas_restantes()
    
    # 2. Verificar resultado final
    print("\n2️⃣ Verificando resultado final...")
    verificar_tablas_finales()
    
    print("\n✅ Limpieza final completada!")

if __name__ == "__main__":
    main() 