import requests

# Primero crear un usuario nuevo
print("🔧 Creando usuario de prueba...")
url_register = "http://10.10.17.18:8888/api/auth/register"
data_register = {
    "nombre": "Test User",
    "correo": "test@test.com", 
    "contrasena": "Test123!",
    "rol_id": 1
}

try:
    resp_register = requests.post(url_register, json=data_register)
    print(f"Register Status: {resp_register.status_code}")
    print(f"Register Response: {resp_register.json()}")
    
    if resp_register.status_code == 201:
        print("\n✅ Usuario creado exitosamente")
        
        # Ahora probar login
        print("\n🔐 Probando login...")
        url_login = "http://10.10.17.18:8888/api/auth/login"
        data_login = {
            "correo": "test@test.com", 
            "contrasena": "Test123!"
        }
        
        resp_login = requests.post(url_login, json=data_login)
        print(f"Login Status: {resp_login.status_code}")
        print(f"Login Response: {resp_login.json()}")
        
        if resp_login.status_code == 200:
            print("\n🎉 ¡Login exitoso!")
        else:
            print("\n❌ Login falló")
    else:
        print("\n❌ Error al crear usuario")
        
except requests.exceptions.ConnectionError:
    print("❌ Error: No se puede conectar al servidor")
    print("Verifica que el backend esté corriendo en 10.10.17.18:8888")
except Exception as e:
    print(f"❌ Error: {e}")
