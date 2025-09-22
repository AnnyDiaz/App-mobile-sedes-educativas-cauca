#!/usr/bin/env python3
"""
Script para verificar que el sistema limpio funciona correctamente
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import engine
from sqlalchemy import text

def verificar_tablas_finales():
    """Verifica que solo tengamos las tablas necesarias"""
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
    
    print("📊 VERIFICANDO TABLAS FINALES...")
    
    try:
        with engine.connect() as conn:
            result = conn.execute(text("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public'
                ORDER BY table_name;
            """))
            
            tablas_finales = [row[0] for row in result]
            
            print("✅ TABLAS PRESENTES:")
            for tabla in tablas_finales:
                if tabla in tablas_esperadas:
                    print(f"   ✅ {tabla}")
                else:
                    print(f"   ⚠️ {tabla} (no esperada)")
            
            # Verificar que todas las tablas esperadas estén presentes
            faltantes = set(tablas_esperadas) - set(tablas_finales)
            if faltantes:
                print(f"\n❌ TABLAS FALTANTES: {faltantes}")
                return False
            else:
                print(f"\n✅ Todas las tablas necesarias están presentes!")
                return True
                
    except Exception as e:
        print(f"❌ Error al verificar tablas: {e}")
        return False

def verificar_datos_checklist():
    """Verifica que tengamos datos del checklist"""
    print("\n📋 VERIFICANDO DATOS DEL CHECKLIST...")
    
    try:
        with engine.connect() as conn:
            # Verificar categorías
            result = conn.execute(text("SELECT COUNT(*) FROM checklist_categorias;"))
            num_categorias = result.scalar()
            print(f"   📊 Categorías del checklist: {num_categorias}")
            
            # Verificar items
            result = conn.execute(text("SELECT COUNT(*) FROM checklist_items;"))
            num_items = result.scalar()
            print(f"   📊 Items del checklist: {num_items}")
            
            if num_categorias > 0 and num_items > 0:
                print("   ✅ Datos del checklist disponibles")
                return True
            else:
                print("   ⚠️ Faltan datos del checklist")
                return False
                
    except Exception as e:
        print(f"   ❌ Error al verificar datos del checklist: {e}")
        return False

def verificar_datos_geograficos():
    """Verifica que tengamos datos geográficos"""
    print("\n🌍 VERIFICANDO DATOS GEOGRÁFICOS...")
    
    try:
        with engine.connect() as conn:
            # Verificar municipios
            result = conn.execute(text("SELECT COUNT(*) FROM municipios;"))
            num_municipios = result.scalar()
            print(f"   📊 Municipios: {num_municipios}")
            
            # Verificar instituciones
            result = conn.execute(text("SELECT COUNT(*) FROM instituciones;"))
            num_instituciones = result.scalar()
            print(f"   📊 Instituciones: {num_instituciones}")
            
            # Verificar sedes
            result = conn.execute(text("SELECT COUNT(*) FROM sedes_educativas;"))
            num_sedes = result.scalar()
            print(f"   📊 Sedes educativas: {num_sedes}")
            
            if num_municipios > 0 and num_instituciones > 0 and num_sedes > 0:
                print("   ✅ Datos geográficos disponibles")
                return True
            else:
                print("   ⚠️ Faltan datos geográficos")
                return False
                
    except Exception as e:
        print(f"   ❌ Error al verificar datos geográficos: {e}")
        return False

def verificar_usuarios():
    """Verifica que tengamos usuarios en el sistema"""
    print("\n👥 VERIFICANDO USUARIOS...")
    
    try:
        with engine.connect() as conn:
            result = conn.execute(text("SELECT COUNT(*) FROM usuarios;"))
            num_usuarios = result.scalar()
            print(f"   📊 Usuarios registrados: {num_usuarios}")
            
            if num_usuarios > 0:
                print("   ✅ Usuarios disponibles")
                return True
            else:
                print("   ⚠️ No hay usuarios registrados")
                return False
                
    except Exception as e:
        print(f"   ❌ Error al verificar usuarios: {e}")
        return False

def main():
    print("🧹 VERIFICACIÓN DEL SISTEMA LIMPIO")
    print("=" * 50)
    
    # 1. Verificar tablas
    tablas_ok = verificar_tablas_finales()
    
    # 2. Verificar datos del checklist
    checklist_ok = verificar_datos_checklist()
    
    # 3. Verificar datos geográficos
    geograficos_ok = verificar_datos_geograficos()
    
    # 4. Verificar usuarios
    usuarios_ok = verificar_usuarios()
    
    # Resumen final
    print("\n" + "=" * 50)
    print("📋 RESUMEN DE VERIFICACIÓN:")
    print(f"   Tablas: {'✅ OK' if tablas_ok else '❌ ERROR'}")
    print(f"   Checklist: {'✅ OK' if checklist_ok else '❌ ERROR'}")
    print(f"   Datos geográficos: {'✅ OK' if geograficos_ok else '❌ ERROR'}")
    print(f"   Usuarios: {'✅ OK' if usuarios_ok else '❌ ERROR'}")
    
    if all([tablas_ok, checklist_ok, geograficos_ok, usuarios_ok]):
        print("\n🎉 ¡SISTEMA LIMPIO Y FUNCIONAL!")
        print("✅ Todas las verificaciones pasaron correctamente")
        print("✅ El sistema está listo para usar")
    else:
        print("\n⚠️ ALGUNAS VERIFICACIONES FALLARON")
        print("❌ Revisa los errores anteriores")

if __name__ == "__main__":
    main() 