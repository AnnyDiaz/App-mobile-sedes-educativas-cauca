# 🐳 Guía de Actualización Docker - App Sedes Educativas Cauca

## 📋 Resumen
Esta guía te llevará paso a paso desde la actualización del repositorio hasta la configuración completa de roles y usuarios en el contenedor Docker.

---

## 🔄 Paso 1: Actualizar el Repositorio

### 1.1 Verificar cambios pendientes
```bash
# Ver archivos modificados
git status

# Ver cambios específicos
git diff
```

### 1.2 Agregar cambios al staging
```bash
# Agregar todos los cambios
git add .

# O agregar archivos específicos
git add app/routes/visitas.py
git add app/routes/visitas_asignadas.py
git add app/scripts/init_admin_system.py
git add frontend_visitas/lib/config.dart
```

### 1.3 Hacer commit
```bash
git commit -m "Fix: Resolver errores de compilación Flutter y permisos API

- Actualizar Flutter a versión 3.35.6 con Dart 3.9.2
- Corregir errores de CardThemeData y withValues() en múltiples archivos
- Eliminar restricciones de permisos en endpoints /api/perfil y /api/visitas-asignadas/mis-visitas
- Configurar usuario administrador con rol 'Administrador' en lugar de 'Super Administrador'
- Agregar logs de debug para identificar problemas de autenticación
- Actualizar dependencias de Flutter a versiones compatibles
- Corregir configuración de Gradle para compilación de APK
- Agregar endpoint de prueba /api/test-auth para debugging"
```

### 1.4 Hacer push (si es necesario)
```bash
# Si hay conflictos, hacer pull primero
git pull origin develop

# Luego hacer push
git push origin develop
```

---

## 🐳 Paso 2: Actualizar Contenedor Docker

### 2.1 Detener contenedores existentes
```bash
# Ver contenedores activos
docker ps

# Detener contenedores específicos
docker stop visitas_api visitas_db

# O detener todos los contenedores
docker stop $(docker ps -q)
```

### 2.2 Eliminar contenedores anteriores
```bash
# Eliminar contenedores específicos
docker rm visitas_api visitas_db

# O eliminar todos los contenedores detenidos
docker container prune -f
```

### 2.3 Reconstruir y ejecutar con docker-compose
```bash
# Construir y ejecutar en segundo plano
docker-compose up -d --build

# Verificar que estén funcionando
docker ps
```

### 2.4 Verificar logs del contenedor
```bash
# Ver logs del contenedor de la API
docker logs visitas_api

# Ver logs en tiempo real
docker logs -f visitas_api
```

---

## 🔧 Paso 3: Configurar Roles y Usuarios

### 3.1 Opción A: Script Automatizado (Recomendado)
```bash
# Ejecutar script de limpieza completa del sistema
docker exec visitas_api python -c "
import os
os.environ['DATABASE_URL'] = 'postgresql://postgres:postgres@visitas_db:5432/visitas_cauca'
import sys
sys.path.append('.')
exec(open('app/scripts/limpiar_sistema.py').read())
"
```

### 3.2 Opción B: Script de Inicialización Básico
```bash
# Entrar al contenedor de la API
docker exec -it visitas_api bash

# Dentro del contenedor, ejecutar:
PYTHONPATH="." python app/scripts/init_admin_system.py
```

### 3.3 Opción C: Script Manual (Si los anteriores fallan)
```bash
# Dentro del contenedor, ejecutar:
python -c "
import os
os.environ['DATABASE_URL'] = 'postgresql://postgres:postgres@visitas_db:5432/visitas_cauca'
import sys
sys.path.append('.')
from app.database import SessionLocal
from app.models import Rol, Usuario
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=['bcrypt'], deprecated='auto')
db = SessionLocal()

# Crear roles si no existen
roles_data = [
    {'nombre': 'Super Administrador', 'descripcion': 'Acceso completo al sistema'},
    {'nombre': 'Administrador', 'descripcion': 'Administrador del sistema'},
    {'nombre': 'Supervisor', 'descripcion': 'Supervisor de visitas'},
    {'nombre': 'Visitador', 'descripcion': 'Visitador de campo'}
]

for rol_data in roles_data:
    existing_rol = db.query(Rol).filter(Rol.nombre == rol_data['nombre']).first()
    if not existing_rol:
        rol = Rol(**rol_data)
        db.add(rol)
        print(f'Rol creado: {rol_data[\"nombre\"]}')

db.commit()

# Crear usuario administrador
admin_rol = db.query(Rol).filter(Rol.nombre == 'Administrador').first()
if admin_rol:
    admin_user = Usuario(
        nombre='Administrador del Sistema',
        correo='admin@test.com',
        contrasena=pwd_context.hash('admin'),
        rol_id=admin_rol.id
    )
    db.add(admin_user)
    db.commit()
    print('Usuario administrador creado exitosamente')
    print('Email: admin@test.com')
    print('Password: admin')
    print('Rol: Administrador')
else:
    print('Error: Rol Administrador no encontrado')

db.close()
"
```

---

## ✅ Paso 4: Verificar Funcionamiento

### 4.1 Probar API desde el contenedor
```bash
# Dentro del contenedor, probar:
curl http://localhost:8000/docs
```

### 4.2 Probar login
```bash
# Dentro del contenedor, probar:
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"correo": "admin@test.com", "contrasena": "admin"}'
```

### 4.3 Salir del contenedor y probar desde fuera
```bash
# Salir del contenedor
exit

# Probar desde la máquina host:
curl http://localhost:8000/docs

# Probar login desde la máquina host:
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"correo": "admin@test.com", "contrasena": "admin"}'
```

---

## 📱 Paso 5: Configurar App Móvil

### 5.1 Verificar configuración de la app
Abrir `frontend_visitas/lib/config.dart` y verificar que tenga:

```dart
// Para DOCKER local
const String baseUrl = 'http://localhost:8000';

// O si está en otra máquina:
// const String baseUrl = 'http://192.168.1.60:8000';
```

### 5.2 Probar login en la app móvil
1. Abrir la app Flutter
2. Intentar hacer login con:
   - **Email:** `admin@test.com`
   - **Password:** `admin`
3. Debería ir al dashboard de administrador sin errores 403

---

## 🚀 Paso 6: Compilar APK (Opcional)

### 6.1 Limpiar y obtener dependencias
```bash
cd frontend_visitas
flutter clean
flutter pub get
```

### 6.2 Compilar APK
```bash
flutter build apk --release
```

### 6.3 Ubicación del APK
El APK se generará en: `frontend_visitas\build\app\outputs\flutter-apk\app-release.apk`

---

## 🔍 Comandos de Diagnóstico

### Verificar contenedores
```bash
# Ver contenedores activos
docker ps

# Ver todos los contenedores
docker ps -a

# Ver logs de un contenedor específico
docker logs visitas_api
```

### Verificar base de datos
```bash
# Entrar al contenedor de la base de datos
docker exec -it visitas_db psql -U postgres -d visitas_cauca

# Dentro de PostgreSQL, verificar tablas:
\dt

# Ver usuarios:
SELECT * FROM usuarios;

# Ver roles:
SELECT * FROM roles;
```

### Limpiar sistema Docker (si es necesario)
```bash
# Detener todos los contenedores
docker stop $(docker ps -q)

# Eliminar todos los contenedores
docker rm $(docker ps -aq)

# Eliminar todas las imágenes
docker rmi $(docker images -q)

# Limpiar sistema Docker
docker system prune -a -f
```

---

## 🚀 Scripts de Despliegue Automatizado

### Script de Despliegue Completo (Linux/Mac)
```bash
# Ejecutar script automatizado
./desplegar_sistema.sh

# O con opciones específicas
./desplegar_sistema.sh --auto-commit --clean-docker
```

### Script de Despliegue Completo (Windows PowerShell)
```powershell
# Ejecutar script automatizado
.\desplegar_sistema.ps1

# O con parámetros específicos
.\desplegar_sistema.ps1 -AutoCommit -CleanDocker -SkipTests
```

### Script de Limpieza del Sistema
```bash
# Ejecutar limpieza completa
docker exec visitas_api python -c "
import os
os.environ['DATABASE_URL'] = 'postgresql://postgres:postgres@visitas_db:5432/visitas_cauca'
import sys
sys.path.append('.')
exec(open('app/scripts/limpiar_sistema.py').read())
"
```

---

## 📋 Checklist de Verificación

- [ ] Repositorio actualizado con todos los cambios
- [ ] Contenedores Docker reconstruidos y funcionando
- [ ] Script de limpieza ejecutado exitosamente
- [ ] Roles creados correctamente (Super Administrador, Administrador, Supervisor, Visitador)
- [ ] Usuario administrador creado con rol "Administrador" (no "Super Administrador")
- [ ] API responde en `http://localhost:8000/docs`
- [ ] Login de admin funciona (`admin@test.com` / `admin`)
- [ ] Endpoint `/api/municipios` funciona sin autenticación
- [ ] Endpoint `/api/perfil` funciona con autenticación
- [ ] Endpoint `/api/visitas-asignadas/mis-visitas` funciona con autenticación
- [ ] App móvil puede conectar al backend
- [ ] No hay errores 403 en la app móvil
- [ ] Dashboard de administrador se carga correctamente
- [ ] Municipios se cargan correctamente en la app móvil
- [ ] Instituciones se cargan correctamente por municipio

---

## 🚨 Solución de Problemas Comunes

### Error: "ModuleNotFoundError: No module named 'app'"
**Solución:** Usar `PYTHONPATH="." python app/scripts/init_admin_system.py`

### Error: "No such container: visitas_api"
**Solución:** Verificar que el contenedor esté ejecutándose con `docker ps`

### Error: "403 Forbidden" en la app móvil
**Solución:** 
1. Verificar que `baseUrl` en `config.dart` apunte a la IP correcta
2. Ejecutar script de limpieza del sistema
3. Verificar que el usuario tenga el rol correcto

### Error: "Connection refused" en la app móvil
**Solución:** 
1. Verificar que el contenedor esté escuchando en el puerto 8000
2. Verificar configuración de red y firewall
3. Probar con `http://localhost:8000` en lugar de IP específica

### Error: "Municipios no se cargan"
**Solución:**
1. Verificar que el endpoint `/api/municipios` funcione sin autenticación
2. Verificar que haya datos en la tabla `municipios`
3. Revisar logs del contenedor: `docker logs visitas_api`

### Error: "Usuario va a dashboard de visitador en lugar de administrador"
**Solución:**
1. Ejecutar script de limpieza del sistema
2. Verificar que el usuario tenga rol "Administrador" (no "Super Administrador")
3. Verificar que `get_current_user` cargue el rol correctamente

### Error: "Datos duplicados en la base de datos"
**Solución:** Ejecutar script de limpieza: `app/scripts/limpiar_sistema.py`

---

## 📞 Credenciales de Prueba

- **Administrador:** `admin@test.com` / `admin` → Dashboard Admin

---

## 📝 Notas Importantes

1. **Base de datos:** El sistema usa PostgreSQL en el contenedor `visitas_db`
2. **Puerto:** La API está disponible en `http://localhost:8000`
3. **Roles:** El usuario administrador tiene rol "Administrador" (no "Super Administrador")
4. **Permisos:** Se eliminaron restricciones de permisos en endpoints críticos
5. **Logs:** Se agregaron logs de debug para identificar problemas de autenticación
6. **Municipios:** Endpoint público sin autenticación en `/api/municipios`
7. **Autenticación:** Función `get_current_user` carga el rol correctamente con `joinedload`
8. **Limpieza:** Script de limpieza elimina duplicados y corrige inconsistencias
9. **Scripts:** Scripts automatizados disponibles para Linux/Mac y Windows
10. **Configuración:** App móvil configurada para Docker local por defecto

---

*Documento creado para la actualización del sistema App Sedes Educativas Cauca*
