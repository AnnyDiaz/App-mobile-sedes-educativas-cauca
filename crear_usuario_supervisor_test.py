#!/usr/bin/env python3
"""
Script para crear un usuario de prueba con rol de supervisor
"""

from app.database import engine, SessionLocal
from app.models import Usuario, Rol
from passlib.context import CryptContext
from sqlalchemy.orm import sessionmaker

# Configuración de bcrypt
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verificar_roles():
    """Verifica qué roles existen en la base de datos"""
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()
    
    try:
        roles = db.query(Rol).all()
        print("📋 Roles existentes en la base de datos:")
        for rol in roles:
            print(f"   - ID: {rol.id}, Nombre: {rol.nombre}")
        return roles
    except Exception as e:
        print(f"❌ Error al verificar roles: {e}")
        return []
    finally:
        db.close()

def crear_rol_supervisor():
    """Crea el rol supervisor si no existe"""
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()
    
    try:
        # Verificar si ya existe el rol supervisor
        rol_supervisor = db.query(Rol).filter(Rol.nombre == "supervisor").first()
        if rol_supervisor:
            print("✅ El rol 'supervisor' ya existe")
            return rol_supervisor
        
        # Obtener el máximo ID para crear el nuevo rol
        max_id = db.query(Rol).order_by(Rol.id.desc()).first()
        nuevo_id = (max_id.id + 1) if max_id else 1
        
        print(f"🔧 Creando rol supervisor con ID: {nuevo_id}")
        
        # Crear el rol supervisor
        nuevo_rol = Rol(
            id=nuevo_id,
            nombre="supervisor"
        )
        
        db.add(nuevo_rol)
        db.commit()
        db.refresh(nuevo_rol)
        
        print("✅ Rol supervisor creado exitosamente")
        return nuevo_rol
            
    except Exception as e:
        print(f"❌ Error al crear rol supervisor: {e}")
        db.rollback()
        return None
    finally:
        db.close()

def crear_usuario_supervisor_test():
    """Crea un usuario de prueba con rol de supervisor"""
    
    # Crear sesión de base de datos
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()
    
    try:
        # Verificar si el usuario ya existe
        usuario_existente = db.query(Usuario).filter(Usuario.correo == "supervisor@test.com").first()
        
        if usuario_existente:
            print("❌ El usuario supervisor@test.com ya existe")
            return
        
        # Verificar que existe el rol supervisor
        rol_supervisor = db.query(Rol).filter(Rol.nombre == "supervisor").first()
        if not rol_supervisor:
            print("❌ El rol 'supervisor' no existe. Creando...")
            rol_supervisor = crear_rol_supervisor()
            if not rol_supervisor:
                print("❌ No se pudo crear el rol supervisor")
                return
        
        # Crear hash de la contraseña
        contrasena_hash = pwd_context.hash("supervisor123")
        
        # Crear nuevo usuario supervisor
        nuevo_usuario = Usuario(
            nombre="Supervisor Test",
            correo="supervisor@test.com",
            contrasena=contrasena_hash,
            rol_id=rol_supervisor.id
        )
        
        # Agregar a la base de datos
        db.add(nuevo_usuario)
        db.commit()
        db.refresh(nuevo_usuario)
        
        print("✅ Usuario supervisor de prueba creado exitosamente:")
        print(f"   - Correo: supervisor@test.com")
        print(f"   - Contraseña: supervisor123")
        print(f"   - Rol: Supervisor")
        print(f"   - ID: {nuevo_usuario.id}")
        
    except Exception as e:
        print(f"❌ Error al crear usuario: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    print("🔍 Verificando roles existentes...")
    verificar_roles()
    
    print("\n👤 Creando usuario supervisor de prueba...")
    crear_usuario_supervisor_test()
    
    print("\n✅ Proceso completado!") 