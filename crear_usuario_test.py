#!/usr/bin/env python3
"""
Script para crear un usuario de prueba con contraseña conocida
"""

from app.database import engine, SessionLocal
from app.models import Usuario
from passlib.context import CryptContext
from sqlalchemy.orm import sessionmaker

# Configuración de bcrypt
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def crear_usuario_test():
    """Crea un usuario de prueba con contraseña conocida"""
    
    # Crear sesión de base de datos
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()
    
    try:
        # Verificar si el usuario ya existe
        usuario_existente = db.query(Usuario).filter(Usuario.correo == "test@test.com").first()
        
        if usuario_existente:
            print("❌ El usuario test@test.com ya existe")
            return
        
        # Crear hash de la contraseña
        contrasena_hash = pwd_context.hash("test123")
        
        # Crear nuevo usuario
        nuevo_usuario = Usuario(
            nombre="Usuario Test",
            correo="test@test.com",
            contrasena=contrasena_hash,
            rol_id=1  # Visitador
        )
        
        # Agregar a la base de datos
        db.add(nuevo_usuario)
        db.commit()
        db.refresh(nuevo_usuario)
        
        print("✅ Usuario de prueba creado exitosamente:")
        print(f"   - Correo: test@test.com")
        print(f"   - Contraseña: test123")
        print(f"   - Rol: Visitador")
        print(f"   - ID: {nuevo_usuario.id}")
        
    except Exception as e:
        print(f"❌ Error al crear usuario: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    crear_usuario_test() 