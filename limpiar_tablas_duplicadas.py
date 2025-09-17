#!/usr/bin/env python3
"""
Script para limpiar tablas duplicadas y mantener solo las necesarias
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import engine
from sqlalchemy import text

def verificar_tablas_actuales():
    """Verifica qué tablas existen actualmente"""
    try:
        with engine.connect() as conn:
            result = conn.execute(text("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public'
                ORDER BY table_name;
            """))
            
            tablas = [row[0] for row in result]
            print("📊 TABLAS ACTUALES EN LA BASE DE DATOS:")
            for tabla in tablas:
                print(f"   - {tabla}")
            
            return tablas
    except Exception as e:
        print(f"❌ Error al verificar tablas: {e}")
        return []

def eliminar_tablas_duplicadas():
    """Elimina las tablas duplicadas que ya no necesitamos"""
    tablas_a_eliminar = [
        'cronogramas',
        'cronogramas_pae', 
        'evaluaciones_pae',
        'visitas',
        'visita_respuestas'
    ]
    
    print("\n🗑️ ELIMINANDO TABLAS DUPLICADAS...")
    
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
    print("🧹 LIMPIEZA DE TABLAS DUPLICADAS")
    print("=" * 50)
    
    # 1. Verificar tablas actuales
    print("\n1️⃣ Verificando tablas actuales...")
    tablas_actuales = verificar_tablas_actuales()
    
    if not tablas_actuales:
        print("❌ No se pudieron obtener las tablas. Saliendo...")
        return
    
    # 2. Eliminar tablas duplicadas
    print("\n2️⃣ Eliminando tablas duplicadas...")
    eliminar_tablas_duplicadas()
    
    # 3. Verificar resultado final
    print("\n3️⃣ Verificando resultado final...")
    verificar_tablas_finales()
    
    print("\n✅ Limpieza completada!")

if __name__ == "__main__":
    main() 