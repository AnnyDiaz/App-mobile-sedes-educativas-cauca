#!/usr/bin/env python3
"""
Script de inicialización de la base de datos para Docker.
Se ejecuta automáticamente al iniciar el contenedor.
"""

import sys
import os
import time
import subprocess
from sqlalchemy import create_engine, text
from sqlalchemy.exc import OperationalError

# Añadir el directorio raíz al path
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

def wait_for_database(database_url, max_retries=30, delay=2):
    """Espera a que la base de datos esté disponible."""
    print("🔄 Esperando a que la base de datos esté disponible...")
    
    for attempt in range(max_retries):
        try:
            engine = create_engine(database_url)
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            print("✅ Base de datos disponible")
            return True
        except OperationalError as e:
            print(f"⏳ Intento {attempt + 1}/{max_retries}: Base de datos no disponible aún...")
            time.sleep(delay)
        except Exception as e:
            print(f"❌ Error inesperado: {e}")
            time.sleep(delay)
    
    print("❌ No se pudo conectar a la base de datos después de todos los intentos")
    return False

def run_init_script():
    """Ejecuta el script de inicialización."""
    try:
        print("🚀 Ejecutando script de inicialización...")
        result = subprocess.run([
            sys.executable, "-m", "app.scripts.init_admin_system"
        ], capture_output=True, text=True, cwd=os.path.dirname(os.path.dirname(os.path.dirname(__file__))))
        
        if result.returncode == 0:
            print("✅ Script de inicialización ejecutado correctamente")
            print(result.stdout)
            return True
        else:
            print("❌ Error en el script de inicialización:")
            print(result.stderr)
            return False
    except Exception as e:
        print(f"❌ Error ejecutando script de inicialización: {e}")
        return False

def main():
    """Función principal."""
    print("🔧 Inicializando base de datos...")
    
    # Obtener URL de la base de datos
    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        print("❌ DATABASE_URL no está configurada")
        return False
    
    print(f"📊 URL de base de datos: {database_url}")
    
    # Esperar a que la base de datos esté disponible
    if not wait_for_database(database_url):
        return False
    
    # Ejecutar script de inicialización
    if not run_init_script():
        return False
    
    print("🎉 ¡Inicialización de base de datos completada!")
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)

