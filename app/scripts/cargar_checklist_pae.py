#!/usr/bin/env python3
"""
Script para cargar el checklist PAE en la base de datos.
Este checklist contiene las categorías e items de evaluación para visitas PAE.
"""

import sys
import os

# Añadir el directorio raíz al path
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from app.database import SessionLocal, engine
from app.models import ChecklistCategoria, ChecklistItem, Base
from sqlalchemy import text

def cargar_checklist_pae():
    """Carga el checklist PAE con categorías e items de evaluación."""
    
    # Crear todas las tablas si no existen
    Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    
    try:
        # Verificar si ya hay datos
        existe_checklist = db.query(ChecklistCategoria).first()
        if existe_checklist:
            print("⚠️  Ya existe un checklist en la base de datos")
            respuesta = input("¿Deseas eliminarlo y cargar uno nuevo? (s/n): ")
            if respuesta.lower() != 's':
                print("❌ Operación cancelada")
                return False
            
            # Eliminar datos existentes
            print("🗑️  Eliminando checklist existente...")
            db.execute(text("DELETE FROM checklist_items"))
            db.execute(text("DELETE FROM checklist_categorias"))
            db.commit()
        
        print("📋 Cargando checklist PAE...")
        
        # Definir las categorías y sus items
        checklist_data = [
            {
                "nombre": "1. INFRAESTRUCTURA Y EQUIPAMIENTO",
                "items": [
                    "1.1 ¿La cocina cuenta con áreas separadas para almacenamiento, preparación y distribución?",
                    "1.2 ¿Los pisos, paredes y techos están en buen estado (sin grietas, humedad o deterioro)?",
                    "1.3 ¿La ventilación e iluminación de la cocina son adecuadas?",
                    "1.4 ¿Cuenta con agua potable suficiente para la preparación de alimentos?",
                    "1.5 ¿Dispone de equipos de refrigeración en buen estado y funcionamiento?",
                    "1.6 ¿Los utensilios y menaje están en buen estado y son suficientes?",
                ]
            },
            {
                "nombre": "2. HIGIENE Y SANEAMIENTO",
                "items": [
                    "2.1 ¿El personal manipulador usa dotación completa y limpia (gorro, tapabocas, delantal)?",
                    "2.2 ¿Se evidencia lavado de manos antes de manipular alimentos?",
                    "2.3 ¿La cocina y áreas de preparación están limpias y ordenadas?",
                    "2.4 ¿Los alimentos se almacenan correctamente (separados del piso, identificados, protegidos)?",
                    "2.5 ¿Existe un programa de control de plagas vigente?",
                    "2.6 ¿El manejo de residuos sólidos es adecuado (canecas con tapa, bolsas, separación)?",
                ]
            },
            {
                "nombre": "3. PREPARACIÓN Y SERVICIO DE ALIMENTOS",
                "items": [
                    "3.1 ¿La temperatura de los alimentos preparados es la adecuada al momento del servicio?",
                    "3.2 ¿Las porciones servidas corresponden a la minuta patrón establecida?",
                    "3.3 ¿Los alimentos se preparan el mismo día del consumo?",
                    "3.4 ¿El tiempo entre preparación y consumo es menor a 2 horas?",
                    "3.5 ¿Los utensilios de servicio están limpios y en buen estado?",
                    "3.6 ¿Se lleva registro de temperaturas de almacenamiento y servicio?",
                ]
            },
            {
                "nombre": "4. PERSONAL MANIPULADOR",
                "items": [
                    "4.1 ¿El personal cuenta con carné de manipulación de alimentos vigente?",
                    "4.2 ¿Tiene capacitación en Buenas Prácticas de Manufactura?",
                    "4.3 ¿Presenta buen estado de salud (sin síntomas de enfermedad)?",
                    "4.4 ¿Mantiene higiene personal adecuada (uñas cortas, cabello recogido, sin joyas)?",
                    "4.5 ¿Conoce los protocolos de higiene y manipulación de alimentos?",
                ]
            },
            {
                "nombre": "5. DOCUMENTACIÓN Y REGISTROS",
                "items": [
                    "5.1 ¿Cuenta con el plan de saneamiento básico documentado?",
                    "5.2 ¿Lleva registros de limpieza y desinfección?",
                    "5.3 ¿Mantiene registro de proveedores y materias primas?",
                    "5.4 ¿Tiene la minuta patrón publicada y visible?",
                    "5.5 ¿Conserva las fichas técnicas de los alimentos?",
                    "5.6 ¿Registra la asistencia de beneficiarios diariamente?",
                ]
            },
            {
                "nombre": "6. CONDICIONES GENERALES",
                "items": [
                    "6.1 ¿El comedor cuenta con mesas y sillas suficientes y en buen estado?",
                    "6.2 ¿El área de comedor está limpia y organizada?",
                    "6.3 ¿Los estudiantes tienen acceso a agua potable durante el servicio?",
                    "6.4 ¿El horario de servicio se cumple según lo establecido?",
                    "6.5 ¿Existe supervisión durante el servicio de alimentación?",
                ]
            },
        ]
        
        # Insertar categorías e items
        orden_item = 1
        total_categorias = 0
        total_items = 0
        
        for cat_data in checklist_data:
            # Crear categoría
            categoria = ChecklistCategoria(nombre=cat_data["nombre"])
            db.add(categoria)
            db.flush()  # Para obtener el ID
            total_categorias += 1
            
            print(f"📁 Categoría: {categoria.nombre}")
            
            # Crear items de la categoría
            for item_texto in cat_data["items"]:
                item = ChecklistItem(
                    categoria_id=categoria.id,
                    pregunta_texto=item_texto,
                    orden=orden_item
                )
                db.add(item)
                orden_item += 1
                total_items += 1
                print(f"   ✓ {item_texto}")
        
        # Guardar cambios
        db.commit()
        
        print("\n" + "="*60)
        print("✅ Checklist PAE cargado exitosamente!")
        print("="*60)
        print(f"📊 Categorías creadas: {total_categorias}")
        print(f"📋 Items creados: {total_items}")
        print("\n💡 Ahora la aplicación móvil podrá cargar el checklist correctamente")
        
        return True
        
    except Exception as e:
        print(f"\n❌ Error al cargar checklist: {str(e)}")
        db.rollback()
        import traceback
        traceback.print_exc()
        return False
        
    finally:
        db.close()

if __name__ == "__main__":
    print("="*60)
    print("📋 SISTEMA DE CARGA DE CHECKLIST PAE")
    print("="*60)
    print()
    
    success = cargar_checklist_pae()
    sys.exit(0 if success else 1)

