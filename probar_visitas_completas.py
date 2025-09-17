#!/usr/bin/env python3
"""
Script para probar el sistema de visitas completas PAE
"""

import sys
import os
import requests
import json
from datetime import datetime

# Configuración
BASE_URL = "http://127.0.0.1:8000"
LOGIN_URL = f"{BASE_URL}/auth/login"
VISITAS_COMPLETAS_URL = f"{BASE_URL}/api/visitas-completas-pae"

def login():
    """Hacer login y obtener token"""
    login_data = {
        "username": "test@example.com",
        "password": "test123"
    }
    
    try:
        response = requests.post(LOGIN_URL, data=login_data)
        if response.status_code == 200:
            token = response.json()["access_token"]
            print("✅ Login exitoso")
            return token
        else:
            print(f"❌ Error en login: {response.status_code}")
            print(f"Respuesta: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Error de conexión: {e}")
        return None

def crear_visita_completa(token):
    """Crear una visita completa PAE de prueba"""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    # Datos de prueba
    visita_data = {
        "fecha_visita": datetime.now().isoformat(),
        "contrato": "CONTRATO-2025-001",
        "operador": "OPERADOR TEST",
        "caso_atencion_prioritaria": "SI",
        "municipio_id": 1,
        "institucion_id": 1,
        "sede_id": 1,
        "profesional_id": 1,
        "observaciones": "Visita de prueba del sistema completo",
        "respuestas_checklist": [
            {
                "item_id": 1,
                "respuesta": "Cumple",
                "observacion": "Observación de prueba"
            },
            {
                "item_id": 2,
                "respuesta": "No Cumple",
                "observacion": "Necesita mejora"
            }
        ]
    }
    
    try:
        response = requests.post(
            VISITAS_COMPLETAS_URL,
            headers=headers,
            json=visita_data
        )
        
        print(f"📊 Status Code: {response.status_code}")
        print(f"📋 Respuesta: {response.text}")
        
        if response.status_code == 200:
            print("✅ Visita completa creada exitosamente")
            return response.json()
        else:
            print("❌ Error al crear visita completa")
            return None
            
    except Exception as e:
        print(f"❌ Error de conexión: {e}")
        return None

def listar_visitas_completas(token):
    """Listar todas las visitas completas"""
    headers = {
        "Authorization": f"Bearer {token}"
    }
    
    try:
        response = requests.get(VISITAS_COMPLETAS_URL, headers=headers)
        
        print(f"📊 Status Code: {response.status_code}")
        
        if response.status_code == 200:
            visitas = response.json()
            print(f"✅ Se encontraron {len(visitas)} visitas completas")
            for visita in visitas:
                print(f"   - Visita #{visita.get('id')}: {visita.get('contrato')}")
            return visitas
        else:
            print(f"❌ Error al listar visitas: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Error de conexión: {e}")
        return None

def main():
    print("🧪 PROBANDO SISTEMA DE VISITAS COMPLETAS PAE")
    print("=" * 50)
    
    # 1. Login
    print("\n1️⃣ Haciendo login...")
    token = login()
    if not token:
        print("❌ No se pudo obtener token. Saliendo...")
        return
    
    # 2. Crear visita completa
    print("\n2️⃣ Creando visita completa de prueba...")
    visita_creada = crear_visita_completa(token)
    
    # 3. Listar visitas completas
    print("\n3️⃣ Listando visitas completas...")
    visitas = listar_visitas_completas(token)
    
    print("\n✅ Prueba completada!")

if __name__ == "__main__":
    main() 