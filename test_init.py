#!/usr/bin/env python3
"""
Script de prueba para verificar la inicialización de la base de datos.
"""

import os
import sys
import subprocess

def test_init_script():
    """Prueba el script de inicialización."""
    print("🧪 Probando script de inicialización...")
    
    try:
        # Ejecutar el script de inicialización
        result = subprocess.run([
            sys.executable, "-m", "app.scripts.init_admin_system"
        ], capture_output=True, text=True, cwd=os.getcwd())
        
        print(f"📊 Código de salida: {result.returncode}")
        print(f"📤 Salida estándar:\n{result.stdout}")
        
        if result.stderr:
            print(f"📤 Error estándar:\n{result.stderr}")
        
        if result.returncode == 0:
            print("✅ Script ejecutado correctamente")
            return True
        else:
            print("❌ Script falló")
            return False
            
    except Exception as e:
        print(f"❌ Error ejecutando script: {e}")
        return False

def test_docker_init():
    """Prueba el script de inicialización para Docker."""
    print("🧪 Probando script de inicialización para Docker...")
    
    try:
        # Ejecutar el script de inicialización para Docker
        result = subprocess.run([
            sys.executable, "app/scripts/docker_init.py"
        ], capture_output=True, text=True, cwd=os.getcwd())
        
        print(f"📊 Código de salida: {result.returncode}")
        print(f"📤 Salida estándar:\n{result.stdout}")
        
        if result.stderr:
            print(f"📤 Error estándar:\n{result.stderr}")
        
        if result.returncode == 0:
            print("✅ Script Docker ejecutado correctamente")
            return True
        else:
            print("❌ Script Docker falló")
            return False
            
    except Exception as e:
        print(f"❌ Error ejecutando script Docker: {e}")
        return False

def main():
    """Función principal de prueba."""
    print("🚀 Iniciando pruebas de inicialización...")
    
    # Verificar que existe el archivo .env
    if not os.path.exists('.env'):
        print("❌ No se encontró el archivo .env")
        print("💡 Crea un archivo .env basado en env_example.txt")
        return False
    
    print("✅ Archivo .env encontrado")
    
    # Probar script de inicialización normal
    print("\n" + "="*50)
    print("PRUEBA 1: Script de inicialización normal")
    print("="*50)
    success1 = test_init_script()
    
    # Probar script de inicialización para Docker
    print("\n" + "="*50)
    print("PRUEBA 2: Script de inicialización para Docker")
    print("="*50)
    success2 = test_docker_init()
    
    # Resumen
    print("\n" + "="*50)
    print("RESUMEN DE PRUEBAS")
    print("="*50)
    print(f"✅ Script normal: {'PASÓ' if success1 else 'FALLÓ'}")
    print(f"✅ Script Docker: {'PASÓ' if success2 else 'FALLÓ'}")
    
    if success1 and success2:
        print("🎉 ¡Todas las pruebas pasaron!")
        return True
    else:
        print("❌ Algunas pruebas fallaron")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)

