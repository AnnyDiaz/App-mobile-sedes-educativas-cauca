#!/usr/bin/env python3
"""
Script para crear las tablas del checklist en la base de datos
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import engine, SessionLocal
from app.models import Base, ChecklistCategoria, ChecklistItem
from sqlalchemy import text

def crear_tablas_checklist():
    """Crea las tablas del checklist si no existen"""
    print("🔧 Creando tablas del checklist...")
    
    # Crear todas las tablas
    Base.metadata.create_all(bind=engine)
    print("✅ Tablas creadas/verificadas correctamente")

def verificar_tablas():
    """Verifica si las tablas del checklist existen"""
    try:
        with engine.connect() as conn:
            # Verificar si existe la tabla checklist_categorias
            result = conn.execute(text("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_name = 'checklist_categorias'
                );
            """))
            existe_categorias = result.scalar()
            
            # Verificar si existe la tabla checklist_items
            result = conn.execute(text("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_name = 'checklist_items'
                );
            """))
            existe_items = result.scalar()
            
            # Verificar si existe la tabla visita_respuestas
            result = conn.execute(text("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_name = 'visita_respuestas'
                );
            """))
            existe_respuestas = result.scalar()
            
            print(f"📊 Estado de las tablas:")
            print(f"   - checklist_categorias: {'✅ Existe' if existe_categorias else '❌ No existe'}")
            print(f"   - checklist_items: {'✅ Existe' if existe_items else '❌ No existe'}")
            print(f"   - visita_respuestas: {'✅ Existe' if existe_respuestas else '❌ No existe'}")
            
            return existe_categorias and existe_items and existe_respuestas
            
    except Exception as e:
        print(f"❌ Error al verificar tablas: {e}")
        return False

def insertar_datos_checklist():
    """Inserta datos de ejemplo para el checklist"""
    db = SessionLocal()
    try:
        # Verificar si ya hay datos
        categorias_existentes = db.query(ChecklistCategoria).count()
        if categorias_existentes > 0:
            print("📋 Ya existen datos en el checklist")
            return
        
        print("📝 Insertando datos de ejemplo para el checklist...")
        
        # Crear categorías
        categoria1 = ChecklistCategoria(
            id=1,
            nombre="Equipos y Utensilios"
        )
        
        categoria2 = ChecklistCategoria(
            id=2,
            nombre="Personal Manipulador"
        )
        
        categoria3 = ChecklistCategoria(
            id=3,
            nombre="Condiciones Sanitarias"
        )
        
        db.add_all([categoria1, categoria2, categoria3])
        db.flush()  # Para obtener los IDs
        
        # Crear items para cada categoría
        items_categoria1 = [
            ChecklistItem(
                categoria_id=1,
                pregunta_texto="¿Los equipos están en buen estado de conservación?",
                orden=1
            ),
            ChecklistItem(
                categoria_id=1,
                pregunta_texto="¿Los utensilios están limpios y desinfectados?",
                orden=2
            ),
            ChecklistItem(
                categoria_id=1,
                pregunta_texto="¿Existe suficiente cantidad de equipos para la demanda?",
                orden=3
            )
        ]
        
        items_categoria2 = [
            ChecklistItem(
                categoria_id=2,
                pregunta_texto="¿El personal usa uniforme completo y limpio?",
                orden=1
            ),
            ChecklistItem(
                categoria_id=2,
                pregunta_texto="¿El personal tiene certificado de manipulación de alimentos?",
                orden=2
            ),
            ChecklistItem(
                categoria_id=2,
                pregunta_texto="¿El personal mantiene buenas prácticas de higiene?",
                orden=3
            )
        ]
        
        items_categoria3 = [
            ChecklistItem(
                categoria_id=3,
                pregunta_texto="¿Las instalaciones están limpias y ordenadas?",
                orden=1
            ),
            ChecklistItem(
                categoria_id=3,
                pregunta_texto="¿Existe control de plagas?",
                orden=2
            ),
            ChecklistItem(
                categoria_id=3,
                pregunta_texto="¿Los residuos se manejan correctamente?",
                orden=3
            )
        ]
        
        db.add_all(items_categoria1 + items_categoria2 + items_categoria3)
        db.commit()
        
        print("✅ Datos del checklist insertados correctamente")
        print(f"   - 3 categorías creadas")
        print(f"   - 9 items creados")
        
    except Exception as e:
        db.rollback()
        print(f"❌ Error al insertar datos: {e}")
    finally:
        db.close()

def verificar_datos():
    """Verifica los datos existentes en el checklist"""
    db = SessionLocal()
    try:
        categorias = db.query(ChecklistCategoria).all()
        items = db.query(ChecklistItem).all()
        respuestas = db.query(ChecklistItem).count()  # Solo contar
        
        print(f"📊 Datos actuales:")
        print(f"   - Categorías: {len(categorias)}")
        print(f"   - Items: {len(items)}")
        print(f"   - Respuestas guardadas: {respuestas}")
        
        if categorias:
            print("\n📋 Categorías disponibles:")
            for cat in categorias:
                print(f"   - {cat.nombre} (ID: {cat.id})")
                items_cat = [item for item in items if item.categoria_id == cat.id]
                for item in items_cat:
                    print(f"     • {item.pregunta_texto}")
        
    except Exception as e:
        print(f"❌ Error al verificar datos: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    print("🔍 Verificando estado de las tablas del checklist...")
    
    # Verificar si las tablas existen
    tablas_existen = verificar_tablas()
    
    if not tablas_existen:
        print("\n🔧 Creando tablas faltantes...")
        crear_tablas_checklist()
        verificar_tablas()
    
    print("\n📋 Verificando datos del checklist...")
    verificar_datos()
    
    print("\n📝 Insertando datos de ejemplo...")
    insertar_datos_checklist()
    
    print("\n✅ Proceso completado!") 