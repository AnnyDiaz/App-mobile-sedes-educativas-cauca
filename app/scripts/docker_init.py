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
            
            print("Inicializacion completada exitosamente!")
            print("\nResumen:")
            print("   - Roles basicos creados")
            print("   - Usuario administrador creado")
            print("\nCredenciales de administrador:")
            print("   Email: admin@educacion.cauca.gov.co")
            print("   Password: Admin123!")
            
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
