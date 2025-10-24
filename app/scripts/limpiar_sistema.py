#!/usr/bin/env python3
"""
Script de limpieza completa del sistema.
Elimina datos duplicados, corrige inconsistencias y prepara el sistema para producción.
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy.orm import Session
from sqlalchemy import text
from passlib.context import CryptContext

from app.database import SessionLocal, engine
from app.models import Rol, Usuario, Municipio, Institucion, Sede

# Configuración
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def limpiar_roles_duplicados(db: Session):
    """Limpia roles duplicados y asegura que existan los roles básicos."""
    print("🧹 Limpiando roles duplicados...")
    
    # Roles básicos requeridos
    roles_requeridos = [
        "Super Administrador",
        "Administrador", 
        "Supervisor",
        "Visitador"
    ]
    
    # Eliminar roles duplicados (mantener solo el primero)
    for rol_nombre in roles_requeridos:
        roles_duplicados = db.query(Rol).filter(Rol.nombre == rol_nombre).all()
        if len(roles_duplicados) > 1:
            print(f"  Eliminando {len(roles_duplicados) - 1} roles duplicados de: {rol_nombre}")
            # Mantener el primero, eliminar el resto
            for rol in roles_duplicados[1:]:
                db.delete(rol)
    
    db.commit()
    print("  ✅ Roles limpiados")

def limpiar_usuarios_duplicados(db: Session):
    """Limpia usuarios duplicados por correo."""
    print("🧹 Limpiando usuarios duplicados...")
    
    # Encontrar usuarios duplicados por correo
    usuarios_duplicados = db.execute(text("""
        SELECT correo, COUNT(*) as count 
        FROM usuarios 
        GROUP BY correo 
        HAVING COUNT(*) > 1
    """)).fetchall()
    
    for correo, count in usuarios_duplicados:
        print(f"  Eliminando {count - 1} usuarios duplicados de: {correo}")
        usuarios = db.query(Usuario).filter(Usuario.correo == correo).all()
        # Mantener el primero, eliminar el resto
        for usuario in usuarios[1:]:
            db.delete(usuario)
    
    db.commit()
    print("  ✅ Usuarios limpiados")

def corregir_usuario_admin(db: Session):
    """Corrige el usuario administrador para que tenga el rol correcto."""
    print("🔧 Corrigiendo usuario administrador...")
    
    admin_email = "admin@test.com"
    admin_password = "admin"
    
    # Obtener rol de Administrador
    admin_rol = db.query(Rol).filter(Rol.nombre == "Administrador").first()
    if not admin_rol:
        print("  ❌ Error: No se encontró el rol Administrador")
        return
    
    # Buscar usuario admin
    admin_user = db.query(Usuario).filter(Usuario.correo == admin_email).first()
    
    if admin_user:
        # Actualizar rol si es necesario
        if admin_user.rol_id != admin_rol.id:
            print(f"  Actualizando rol de {admin_email} a Administrador")
            admin_user.rol_id = admin_rol.id
            db.commit()
        else:
            print(f"  Usuario {admin_email} ya tiene el rol correcto")
    else:
        # Crear usuario admin si no existe
        print(f"  Creando usuario administrador: {admin_email}")
        admin_user = Usuario(
            nombre="Administrador del Sistema",
            correo=admin_email,
            contrasena=pwd_context.hash(admin_password),
            rol_id=admin_rol.id
        )
        db.add(admin_user)
        db.commit()
    
    print("  ✅ Usuario administrador corregido")

def limpiar_datos_geograficos(db: Session):
    """Limpia datos geográficos duplicados."""
    print("🧹 Limpiando datos geográficos...")
    
    # Limpiar municipios duplicados
    municipios_duplicados = db.execute(text("""
        SELECT nombre, COUNT(*) as count 
        FROM municipios 
        GROUP BY nombre 
        HAVING COUNT(*) > 1
    """)).fetchall()
    
    for nombre, count in municipios_duplicados:
        print(f"  Eliminando {count - 1} municipios duplicados de: {nombre}")
        municipios = db.query(Municipio).filter(Municipio.nombre == nombre).all()
        # Mantener el primero, eliminar el resto
        for municipio in municipios[1:]:
            db.delete(municipio)
    
    # Limpiar instituciones duplicadas
    instituciones_duplicadas = db.execute(text("""
        SELECT nombre, municipio_id, COUNT(*) as count 
        FROM instituciones 
        GROUP BY nombre, municipio_id 
        HAVING COUNT(*) > 1
    """)).fetchall()
    
    for nombre, municipio_id, count in instituciones_duplicadas:
        print(f"  Eliminando {count - 1} instituciones duplicadas de: {nombre}")
        instituciones = db.query(Institucion).filter(
            Institucion.nombre == nombre,
            Institucion.municipio_id == municipio_id
        ).all()
        # Mantener el primero, eliminar el resto
        for institucion in instituciones[1:]:
            db.delete(institucion)
    
    db.commit()
    print("  ✅ Datos geográficos limpiados")

def verificar_sistema(db: Session):
    """Verifica que el sistema esté funcionando correctamente."""
    print("🔍 Verificando sistema...")
    
    # Verificar roles
    roles = db.query(Rol).all()
    print(f"  Roles disponibles: {[r.nombre for r in roles]}")
    
    # Verificar usuario admin
    admin_user = db.query(Usuario).filter(Usuario.correo == "admin@test.com").first()
    if admin_user:
        print(f"  Usuario admin: {admin_user.correo}, Rol: {admin_user.rol.nombre if admin_user.rol else 'Sin rol'}")
    else:
        print("  ❌ Usuario admin no encontrado")
    
    # Verificar municipios
    municipios_count = db.query(Municipio).count()
    print(f"  Municipios disponibles: {municipios_count}")
    
    # Verificar instituciones
    instituciones_count = db.query(Institucion).count()
    print(f"  Instituciones disponibles: {instituciones_count}")
    
    print("  ✅ Verificación completada")

def main():
    """Función principal de limpieza."""
    print("🚀 Iniciando limpieza completa del sistema...\n")
    
    # Obtener sesión de base de datos
    db = SessionLocal()
    
    try:
        # Ejecutar limpiezas
        limpiar_roles_duplicados(db)
        print()
        
        limpiar_usuarios_duplicados(db)
        print()
        
        corregir_usuario_admin(db)
        print()
        
        limpiar_datos_geograficos(db)
        print()
        
        verificar_sistema(db)
        print()
        
        print("🎉 Limpieza completada exitosamente!")
        print("\nSistema listo para:")
        print("  - Login con admin@test.com / admin")
        print("  - Acceso a dashboard de administrador")
        print("  - Gestión de municipios e instituciones")
        print("  - Funcionamiento completo de la app móvil")
        
    except Exception as e:
        print(f"❌ Error durante la limpieza: {str(e)}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    main()
