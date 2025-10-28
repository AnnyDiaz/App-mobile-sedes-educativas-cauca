#!/usr/bin/env python3
"""
Script para verificar usuarios en la base de datos
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models import Usuario, Rol

def verificar_usuarios():
    db = SessionLocal()
    try:
        print("🔍 Verificando usuarios en la base de datos...\n")
        
        usuarios = db.query(Usuario).all()
        
        print(f"📊 Total de usuarios: {len(usuarios)}\n")
        
        for usuario in usuarios:
            rol = db.query(Rol).filter(Rol.id == usuario.rol_id).first()
            print(f"👤 ID: {usuario.id}")
            print(f"   Nombre: {usuario.nombre}")
            print(f"   Email: {usuario.correo}")
            print(f"   Rol: {rol.nombre if rol else 'Sin rol'}")
            print(f"   Activo: {usuario.activo}")
            print()
            
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    verificar_usuarios()

