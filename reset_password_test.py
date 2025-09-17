#!/usr/bin/env python3
"""
Script para cambiar la contraseña del usuario test@test.com
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

def reset_password():
    """Cambia la contraseña del usuario test@test.com"""
    
    # Nueva contraseña (cambia esta por la que quieras)
    new_password = "Test123!"
    
    db = SessionLocal()
    
    try:
        # Buscar el usuario
        from app.models import Usuario
        usuario = db.query(Usuario).filter(Usuario.correo == "test@test.com").first()
        
        if not usuario:
            print("❌ Usuario test@test.com no encontrado")
            return
        
        # Generar hash de la nueva contraseña
        hashed_password = pwd_context.hash(new_password)
        
        # Actualizar contraseña
        usuario.contrasena = hashed_password
        db.commit()
        
        print("✅ Contraseña actualizada exitosamente")
        print(f"   Usuario: test@test.com")
        print(f"   Nueva contraseña: {new_password}")
        print(f"   Hash generado: {hashed_password[:50]}...")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    reset_password()
