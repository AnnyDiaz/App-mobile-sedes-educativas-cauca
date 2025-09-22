#!/usr/bin/env python3
"""
Script para crear las tablas de visitas completas PAE
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import engine
from app.models import Base
from sqlalchemy import text

def crear_tablas_visitas_completas():
    """Crea las tablas de visitas completas PAE"""
    print("🔧 Creando tablas de visitas completas PAE...")
    
    # Crear todas las tablas
    Base.metadata.create_all(bind=engine)
    print("✅ Tablas creadas/verificadas correctamente")

def verificar_tablas():
    """Verifica si las tablas de visitas completas existen"""
    try:
        with engine.connect() as conn:
            # Verificar si existe la tabla visitas_completas_pae
            result = conn.execute(text("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_name = 'visitas_completas_pae'
                );
            """))
            existe_visitas = result.scalar()
            
            # Verificar si existe la tabla visita_respuestas_completas
            result = conn.execute(text("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_name = 'visita_respuestas_completas'
                );
            """))
            existe_respuestas = result.scalar()
            
            print(f"📊 Estado de las tablas:")
            print(f"   - visitas_completas_pae: {'✅ Existe' if existe_visitas else '❌ No existe'}")
            print(f"   - visita_respuestas_completas: {'✅ Existe' if existe_respuestas else '❌ No existe'}")
            
            return existe_visitas and existe_respuestas
            
    except Exception as e:
        print(f"❌ Error al verificar tablas: {e}")
        return False

if __name__ == "__main__":
    print("🔍 Verificando estado de las tablas de visitas completas...")
    
    # Verificar si las tablas existen
    tablas_existen = verificar_tablas()
    
    if not tablas_existen:
        print("\n🔧 Creando tablas faltantes...")
        crear_tablas_visitas_completas()
        verificar_tablas()
    
    print("\n✅ Proceso completado!") 