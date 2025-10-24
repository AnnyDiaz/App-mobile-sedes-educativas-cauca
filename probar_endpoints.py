#!/usr/bin/env python3
"""
Script para probar los endpoints con autenticación
"""

import requests
import json

BASE_URL = "http://127.0.0.1:8000"

def login():
    """Hacer login para obtener un token"""
    login_data = {
        "correo": "admin@test.com",
        "contrasena": "admin"
    }
    
    response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
    if response.status_code == 200:
        data = response.json()
        return data.get("access_token")
    else:
        print(f"❌ Error en login: {response.status_code} - {response.text}")
        return None

def test_endpoints(token):
    """Probar los endpoints con el token"""
    headers = {"Authorization": f"Bearer {token}"}
    
    print("🔍 PROBANDO ENDPOINTS")
    print("=" * 50)
    
    # 1. Probar perfil (sin ID)
    print("\n1️⃣ Probando /api/perfil:")
    response = requests.get(f"{BASE_URL}/api/perfil", headers=headers)
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Perfil: {data}")
    else:
        print(f"❌ Error: {response.status_code} - {response.text}")
    
    # 2. Probar visitas completas PAE
    print("\n2️⃣ Probando /api/visitas-completas-pae:")
    response = requests.get(f"{BASE_URL}/api/visitas-completas-pae", headers=headers)
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Encontradas {len(data)} visitas completas PAE")
        for visita in data:
            print(f"   - ID: {visita.get('id')}, Estado: {visita.get('estado')}, Contrato: {visita.get('contrato')}")
    else:
        print(f"❌ Error: {response.status_code} - {response.text}")
    
    # 3. Probar mis visitas (pendientes)
    print("\n3️⃣ Probando /api/visitas/mis-visitas?estado=pendiente:")
    response = requests.get(f"{BASE_URL}/api/visitas/mis-visitas?estado=pendiente", headers=headers)
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Encontradas {len(data)} visitas pendientes")
        for visita in data:
            print(f"   - ID: {visita.get('id')}, Estado: {visita.get('estado')}, Contrato: {visita.get('contrato')}")
    else:
        print(f"❌ Error: {response.status_code} - {response.text}")
    
    # 4. Probar mis visitas (completadas)
    print("\n4️⃣ Probando /api/visitas/mis-visitas?estado=completada:")
    response = requests.get(f"{BASE_URL}/api/visitas/mis-visitas?estado=completada", headers=headers)
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Encontradas {len(data)} visitas completadas")
        for visita in data:
            print(f"   - ID: {visita.get('id')}, Estado: {visita.get('estado')}, Contrato: {visita.get('contrato')}")
    else:
        print(f"❌ Error: {response.status_code} - {response.text}")

def main():
    print("🚀 INICIANDO PRUEBAS DE ENDPOINTS")
    print("=" * 50)
    
    # Hacer login
    token = login()
    if not token:
        print("❌ No se pudo obtener el token. Saliendo...")
        return
    
    print(f"✅ Token obtenido: {token[:20]}...")
    
    # Probar endpoints
    test_endpoints(token)

if __name__ == "__main__":
    main() 