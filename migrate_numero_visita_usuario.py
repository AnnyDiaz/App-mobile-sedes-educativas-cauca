#!/usr/bin/env python3
"""
Script completo para migrar y actualizar el campo numero_visita_usuario
1. Agrega la columna a la base de datos
2. Actualiza las visitas existentes con números secuenciales
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import SessionLocal, engine
from app.models import VisitaCompletaPAE
from sqlalchemy import text
import psycopg2

def check_column_exists():
    """Verifica si la columna numero_visita_usuario ya existe"""
    db = SessionLocal()
    try:
        result = db.execute(text("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'visitas_completas_pae' 
            AND column_name = 'numero_visita_usuario'
        """))
        return result.fetchone() is not None
    except Exception as e:
        print(f"❌ Error verificando columna: {e}")
        return False
    finally:
        db.close()

def add_column():
    """Agrega la columna numero_visita_usuario a la tabla"""
    db = SessionLocal()
    try:
        print("🔧 Agregando columna numero_visita_usuario...")
        
        # Agregar la columna
        db.execute(text("""
            ALTER TABLE visitas_completas_pae 
            ADD COLUMN numero_visita_usuario INTEGER
        """))
        
        # Crear índice
        db.execute(text("""
            CREATE INDEX IF NOT EXISTS idx_visitas_completas_pae_numero_visita_usuario 
            ON visitas_completas_pae(numero_visita_usuario)
        """))
        
        # Agregar comentario
        db.execute(text("""
            COMMENT ON COLUMN visitas_completas_pae.numero_visita_usuario 
            IS 'Número secuencial de visita por usuario (ej: 1, 2, 3...)'
        """))
        
        db.commit()
        print("✅ Columna agregada exitosamente")
        return True
        
    except Exception as e:
        print(f"❌ Error agregando columna: {e}")
        db.rollback()
        return False
    finally:
        db.close()

def update_existing_visitas():
    """Actualiza las visitas existentes con numero_visita_usuario"""
    db = SessionLocal()
    
    try:
        print("🔄 Actualizando visitas existentes...")
        
        # Obtener todos los usuarios que tienen visitas
        usuarios_con_visitas = db.query(VisitaCompletaPAE.profesional_id).distinct().all()
        
        total_usuarios = len(usuarios_con_visitas)
        print(f"📊 Encontrados {total_usuarios} usuarios con visitas")
        
        total_visitas_actualizadas = 0
        
        for i, (usuario_id,) in enumerate(usuarios_con_visitas, 1):
            print(f"👤 Procesando usuario {usuario_id} ({i}/{total_usuarios})...")
            
            # Obtener todas las visitas del usuario ordenadas por fecha de creación
            visitas_usuario = db.query(VisitaCompletaPAE).filter(
                VisitaCompletaPAE.profesional_id == usuario_id
            ).order_by(VisitaCompletaPAE.fecha_creacion.asc()).all()
            
            print(f"   📝 Encontradas {len(visitas_usuario)} visitas para este usuario")
            
            # Asignar número de visita secuencial
            for j, visita in enumerate(visitas_usuario, 1):
                visita.numero_visita_usuario = j
                total_visitas_actualizadas += 1
                print(f"   ✅ Visita ID {visita.id} -> Visita #{j}")
        
        # Confirmar cambios
        db.commit()
        print(f"✅ Actualización completada: {total_visitas_actualizadas} visitas actualizadas")
        return True
        
    except Exception as e:
        print(f"❌ Error durante la actualización: {str(e)}")
        db.rollback()
        return False
    finally:
        db.close()

def verify_migration():
    """Verifica que la migración se completó correctamente"""
    db = SessionLocal()
    try:
        print("🔍 Verificando migración...")
        
        # Contar visitas con numero_visita_usuario
        visitas_con_numero = db.query(VisitaCompletaPAE).filter(
            VisitaCompletaPAE.numero_visita_usuario.isnot(None)
        ).count()
        
        # Contar total de visitas
        total_visitas = db.query(VisitaCompletaPAE).count()
        
        print(f"📈 Total de visitas: {total_visitas}")
        print(f"📈 Visitas con numero_visita_usuario: {visitas_con_numero}")
        
        if visitas_con_numero == total_visitas:
            print("✅ Migración completada exitosamente")
            return True
        else:
            print("⚠️ Migración incompleta")
            return False
            
    except Exception as e:
        print(f"❌ Error verificando migración: {e}")
        return False
    finally:
        db.close()

def main():
    """Función principal que ejecuta toda la migración"""
    print("🚀 Iniciando migración de numero_visita_usuario...")
    
    # Verificar si la columna ya existe
    if check_column_exists():
        print("ℹ️ La columna numero_visita_usuario ya existe")
    else:
        # Agregar la columna
        if not add_column():
            print("❌ No se pudo agregar la columna. Abortando migración.")
            return False
    
    # Actualizar visitas existentes
    if not update_existing_visitas():
        print("❌ No se pudieron actualizar las visitas existentes.")
        return False
    
    # Verificar migración
    if not verify_migration():
        print("❌ La verificación de migración falló.")
        return False
    
    print("🎉 ¡Migración completada exitosamente!")
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
