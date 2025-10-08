#!/usr/bin/env python3
"""
Script de inicialización del sistema de administración.
Crea roles, permisos, usuario administrador inicial y configuraciones básicas.
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy.orm import Session
from passlib.context import CryptContext
import json
from datetime import datetime, timedelta

from app.database import SessionLocal, engine
from app.models import Rol, Usuario

# Configuración
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def create_default_roles(db: Session):
    """Crea los roles por defecto del sistema."""
    roles_default = [
        "Super Administrador",
        "Administrador", 
        "Supervisor",
        "Visitador"
    ]
    
    print("Creando roles por defecto...")
    for nombre_rol in roles_default:
        rol_existente = db.query(Rol).filter(
            Rol.nombre == nombre_rol
        ).first()
        
        if not rol_existente:
            nuevo_rol = Rol(nombre=nombre_rol)
            db.add(nuevo_rol)
            print(f"  Rol creado: {nombre_rol}")
        else:
            print(f"  Rol ya existe: {nombre_rol}")
    
    db.commit()

# Funciones de permisos eliminadas - no existen los modelos necesarios

def create_admin_user(db: Session):
    """Crea el usuario administrador inicial."""
    
    admin_email = "admin@educacion.cauca.gov.co"
    admin_password = "Admin123!"  # Cambiar en producción
    
    print("Creando usuario administrador inicial...")
    
    # Verificar si ya existe
    admin_existente = db.query(Usuario).filter(
        Usuario.correo == admin_email
    ).first()
    
    if admin_existente:
        print(f"  Usuario administrador ya existe: {admin_email}")
        return
    
    # Obtener rol de Super Administrador
    super_admin_rol = db.query(Rol).filter(
        Rol.nombre == "Super Administrador"
    ).first()
    
    if not super_admin_rol:
        print("  Error: No se encontro el rol Super Administrador")
        return
    
    # Crear usuario
    admin_user = Usuario(
        nombre="Administrador del Sistema",
        correo=admin_email,
        contrasena=pwd_context.hash(admin_password),
        rol_id=super_admin_rol.id
    )
    
    db.add(admin_user)
    db.commit()
    
    print(f"  Usuario administrador creado:")
    print(f"     Email: {admin_email}")
    print(f"     Password: {admin_password}")
    print(f"     IMPORTANTE: Cambiar la contrasena en el primer login")

# Funciones de configuración eliminadas - no existen los modelos necesarios

def main():
    """Función principal de inicialización."""
    print("Iniciando configuracion del sistema de administracion...\n")
    
    # Crear tablas
    print("Creando tablas de base de datos...")
    from app.models import Base
    Base.metadata.create_all(bind=engine)
    print("  Tablas creadas\n")
    
    # Obtener sesión de base de datos
    db = SessionLocal()
    
    try:
        # Ejecutar inicializaciones disponibles
        create_default_roles(db)
        print()
        
        create_admin_user(db)
        print()
        
        print("Inicializacion completada exitosamente!")
        print("\nResumen:")
        print("   - Roles basicos creados")
        print("   - Usuario administrador creado")
        print("\nCredenciales de administrador:")
        print("   Email: admin@educacion.cauca.gov.co")
        print("   Password: Admin123!")
        print("   IMPORTANTE: Cambiar contrasena en primer login")
        
    except Exception as e:
        print(f"Error durante la inicializacion: {str(e)}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    main()
