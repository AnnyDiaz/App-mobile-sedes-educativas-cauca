#!/usr/bin/env python3
"""
Script de inicialización específico para Docker.
Se ejecuta automáticamente al iniciar el contenedor.
"""

import sys
import os
import time
from sqlalchemy import create_engine, text
from sqlalchemy.exc import OperationalError

# Añadir el directorio raíz al path
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

def wait_for_database(database_url, max_retries=30, delay=2):
    """Espera a que la base de datos esté disponible."""
    print("Esperando a que la base de datos este disponible...")
    
    for attempt in range(max_retries):
        try:
            engine = create_engine(database_url)
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            print("Base de datos disponible")
            return True
        except OperationalError as e:
            print(f"Intento {attempt + 1}/{max_retries}: Base de datos no disponible aun...")
            time.sleep(delay)
        except Exception as e:
            print(f"Error inesperado: {e}")
            time.sleep(delay)
    
    print("No se pudo conectar a la base de datos despues de todos los intentos")
    return False

def load_checklist_pae(engine, db):
    """Carga el checklist PAE completo (15 categorías, 64 items)."""
    try:
        from app.models import ChecklistCategoria
        from sqlalchemy import text
        
        # Verificar si ya existe el checklist
        existe_checklist = db.query(ChecklistCategoria).first()
        if existe_checklist:
            print("Checklist PAE ya existe, omitiendo carga...")
            return True
        
        print("Cargando Checklist PAE (15 categorias, 64 items)...")
        
        # Datos de las categorías
        categorias = [
            (1, 'Numero de manipuladoras encontradas'),
            (2, 'Diseño, construccion y disposicion de residuos solidos'),
            (3, 'Equipos y utensilios'),
            (4, 'Personal manipulador'),
            (5, 'Practicas Higienicas y Medidas de Proteccion'),
            (6, 'Materias primas e insumos'),
            (7, 'Operaciones de fabricacion'),
            (8, 'Prevencion de la contaminacion cruzada'),
            (9, 'Aseguramiento y control de la calidad e inocuidad'),
            (10, 'Saneamiento'),
            (11, 'Almacenamiento'),
            (12, 'Transporte'),
            (13, 'Distribucion y consumo'),
            (14, 'Documentacion PAE'),
            (15, 'Cobertura')
        ]
        
        # Insertar categorías
        for cat_id, cat_nombre in categorias:
            categoria = ChecklistCategoria(id=cat_id, nombre=cat_nombre)
            db.add(categoria)
        
        db.commit()
        print("   -> Categorias creadas: 15")
        
        # Ejecutar archivo SQL con los items
        sql_file = '/app/insert_checklist_items.sql'
        if os.path.exists(sql_file):
            print("   -> Ejecutando archivo SQL de items...")
            with open(sql_file, 'r', encoding='utf-8') as f:
                sql_content = f.read()
            
            # Ejecutar el SQL directamente
            with engine.connect() as conn:
                conn.execute(text(sql_content))
                conn.commit()
            
            print("   -> Items cargados: 64")
        else:
            print(f"   -> ADVERTENCIA: No se encontro el archivo {sql_file}")
            print("   -> Los items del checklist deben cargarse manualmente")
        
        return True
        
    except Exception as e:
        print(f"Error cargando checklist PAE: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

def initialize_database():
    """Inicializa la base de datos."""
    try:
        # Importar después de configurar el path
        from app.database import engine, SessionLocal
        from app.models import Base
        from app.scripts.init_admin_system import create_default_roles, create_admin_user
        
        print("Creando tablas de base de datos...")
        Base.metadata.create_all(bind=engine)
        print("Tablas creadas")
        
        # Obtener sesión de base de datos
        db = SessionLocal()
        
        try:
            # Ejecutar inicializaciones
            create_default_roles(db)
            create_admin_user(db)
            load_checklist_pae(engine, db)
            
            print("\nInicializacion completada exitosamente!")
            print("\nResumen:")
            print("   - Roles basicos creados")
            print("   - Usuario administrador creado")
            print("   - Checklist PAE creado (15 categorias, 64 items)")
            print("\nCredenciales de administrador:")
            print("   Email: admin@test.com")
            print("   Password: admin")
            
            return True
            
        except Exception as e:
            print(f"Error durante la inicializacion: {str(e)}")
            db.rollback()
            return False
        finally:
            db.close()
            
    except Exception as e:
        print(f"Error importando modulos: {str(e)}")
        return False

def main():
    """Función principal."""
    print("Iniciando inicializacion de base de datos para Docker...")
    
    # Obtener URL de la base de datos
    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        # Intentar cargar desde .env si no está en variables de entorno
        try:
            from dotenv import load_dotenv
            load_dotenv()
            database_url = os.getenv("DATABASE_URL")
        except ImportError:
            pass
        
        if not database_url:
            print("DATABASE_URL no esta configurada")
            return False
    
    print(f"URL de base de datos: {database_url}")
    
    # Esperar a que la base de datos esté disponible
    if not wait_for_database(database_url):
        return False
    
    # Inicializar la base de datos
    if not initialize_database():
        return False
    
    print("Inicializacion completada")
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
