#!/usr/bin/env python3
import requests
import json

# Token de autenticación
token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0QHRlc3QuY29tIiwicm9sIjoiVmlzaXRhZG9yIiwiaWQiOjksImV4cCI6MTc1NDA2NjE3Nn0.IK7MpfExno60gXuvfUJ3CNapoTT7PzvQBZIZjtAlTG8"

# URL del endpoint
url = "http://10.10.140.124:8000/api/visitas-completas-pae/1/excel"

# Headers
headers = {
    'Authorization': f'Bearer {token}'
}

try:
    print("🔗 Probando descarga de Excel...")
    response = requests.get(url, headers=headers)
    
    print(f"📌 Status: {response.status_code}")
    print(f"📌 Content-Type: {response.headers.get('content-type')}")
    print(f"📌 Content-Length: {len(response.content)} bytes")
    
    if response.status_code == 200:
        # Guardar el archivo Excel
        filename = "visita_1_test.xlsx"
        with open(filename, "wb") as f:
            f.write(response.content)
        print(f"✅ Archivo Excel guardado como: {filename}")
        print(f"📁 Tamaño del archivo: {len(response.content)} bytes")
    else:
        print(f"❌ Error: {response.text}")
        
except Exception as e:
    print(f"❌ Error: {e}") 