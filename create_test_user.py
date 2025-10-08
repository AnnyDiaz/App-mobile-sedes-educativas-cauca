#!/usr/bin/env python3
"""
Script para crear el usuario test@test.com
"""
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from passlib.context import CryptContext

# Configuración de la base de datos
DATABASE_URL = "sqlite:///visitas_cauca.db"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Configuración de hash
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def create_test_user():
    """Crea el usuario test@test.com"""
    
    db = SessionLocal()
    
    try:
        from app.models import Usuario, Rol
        
        # Verificar si el usuario ya existe
        usuario_existente = db.query(Usuario).filter(Usuario.correo == "test@test.com").first()
        if usuario_existente:
            print("✅ Usuario test@test.com ya existe")
            return
        
        # Crear rol Visitador si no existe
        rol = db.query(Rol).filter(Rol.nombre == "Visitador").first()
        if not rol:
            rol = Rol(nombre="Visitador", descripcion="Usuario visitador")
            db.add(rol)
            db.commit()
            db.refresh(rol)
            print("✅ Rol Visitador creado")
        
        # Crear usuario
        usuario = Usuario(
            nombre="Test User",
            correo="test@test.com",
            contrasena=pwd_context.hash("Test123!"),
            rol_id=rol.id
        )
        db.add(usuario)
        db.commit()
        
        print("✅ Usuario test@test.com creado exitosamente")
        print(f"   Email: test@test.com")
        print(f"   Password: Test123!")
        print(f"   Rol: {rol.nombre}")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    create_test_user()
