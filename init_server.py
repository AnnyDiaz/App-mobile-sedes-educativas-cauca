#!/usr/bin/env python3
"""
Script para inicializar el servidor remoto
Ejecutar en el servidor: python init_server.py
"""
import requests
import json

def init_server():
    """Inicializa el servidor creando roles y usuario admin"""
    
    base_url = "http://10.10.17.18:8888"
    
    print("🚀 Inicializando servidor...")
    
    # 1. Crear roles
    print("📋 Creando roles...")
    roles = [
        {"nombre": "Super Administrador", "descripcion": "Acceso completo al sistema"},
        {"nombre": "Administrador", "descripcion": "Administración general del sistema"},
        {"nombre": "Supervisor", "descripcion": "Supervisión de equipos de visitadores"},
        {"nombre": "Visitador", "descripcion": "Realización de visitas y cumplimiento de checklists"}
    ]
    
    for rol in roles:
        try:
            response = requests.post(f"{base_url}/api/roles", json=rol)
            if response.status_code in [200, 201]:
                print(f"  ✅ Rol creado: {rol['nombre']}")
            else:
                print(f"  ⚠️  Rol {rol['nombre']}: {response.status_code}")
        except Exception as e:
            print(f"  ❌ Error creando rol {rol['nombre']}: {e}")
    
    # 2. Crear usuario admin
    print("\n👤 Creando usuario admin...")
    admin_data = {
        "nombre": "Administrador del Sistema",
        "correo": "admin@educacion.cauca.gov.co",
        "contrasena": "Admin123!",
        "rol_id": 1  # Super Administrador
    }
    
    try:
        response = requests.post(f"{base_url}/api/auth/register", json=admin_data)
        if response.status_code in [200, 201]:
            print("  ✅ Usuario admin creado")
        else:
            print(f"  ⚠️  Usuario admin: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"  ❌ Error creando admin: {e}")
    
    # 3. Probar login con admin
    print("\n🔐 Probando login con admin...")
    login_data = {
        "correo": "admin@educacion.cauca.gov.co",
        "contrasena": "Admin123!"
    }
    
    try:
        response = requests.post(f"{base_url}/api/auth/login", json=login_data)
        if response.status_code == 200:
            print("  ✅ Login exitoso!")
            data = response.json()
            print(f"  Token: {data.get('access_token', 'N/A')[:20]}...")
        else:
            print(f"  ❌ Login falló: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"  ❌ Error en login: {e}")

if __name__ == "__main__":
    init_server()
