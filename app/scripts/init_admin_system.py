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
from app import models

# Configuración
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def create_default_roles(db: Session):
    """Crea los roles por defecto del sistema."""
    roles_default = [
        {
            "nombre": "Super Administrador",
            "descripcion": "Acceso completo al sistema, incluyendo configuración de seguridad"
        },
        {
            "nombre": "Administrador",
            "descripcion": "Administración general del sistema sin acceso a configuración crítica"
        },
        {
            "nombre": "Supervisor",
            "descripcion": "Supervisión de equipos de visitadores y generación de reportes"
        },
        {
            "nombre": "Visitador",
            "descripcion": "Realización de visitas y cumplimiento de checklists"
        }
    ]
    
    print("📋 Creando roles por defecto...")
    for rol_data in roles_default:
        rol_existente = db.query(models.Rol).filter(
            models.Rol.nombre == rol_data["nombre"]
        ).first()
        
        if not rol_existente:
            nuevo_rol = models.Rol(**rol_data)
            db.add(nuevo_rol)
            print(f"  ✅ Rol creado: {rol_data['nombre']}")
        else:
            print(f"  ⏭️  Rol ya existe: {rol_data['nombre']}")
    
    db.commit()

def create_default_permissions(db: Session):
    """Crea los permisos por defecto del sistema."""
    permisos_default = [
        # Usuarios
        {"clave": "usuarios.listar", "nombre": "Listar usuarios", "modulo": "usuarios"},
        {"clave": "usuarios.crear", "nombre": "Crear usuarios", "modulo": "usuarios"},
        {"clave": "usuarios.editar", "nombre": "Editar usuarios", "modulo": "usuarios"},
        {"clave": "usuarios.activar", "nombre": "Activar usuarios", "modulo": "usuarios"},
        {"clave": "usuarios.desactivar", "nombre": "Desactivar usuarios", "modulo": "usuarios"},
        {"clave": "usuarios.reset_2fa", "nombre": "Resetear 2FA", "modulo": "usuarios"},
        
        # Checklists
        {"clave": "checklists.listar", "nombre": "Listar checklists", "modulo": "checklists"},
        {"clave": "checklists.crear", "nombre": "Crear checklists", "modulo": "checklists"},
        {"clave": "checklists.editar", "nombre": "Editar checklists", "modulo": "checklists"},
        {"clave": "checklists.publicar", "nombre": "Publicar checklists", "modulo": "checklists"},
        {"clave": "checklists.eliminar", "nombre": "Eliminar checklists", "modulo": "checklists"},
        
        # Configuración
        {"clave": "config.listar", "nombre": "Ver configuración", "modulo": "config"},
        {"clave": "config.editar", "nombre": "Editar configuración", "modulo": "config"},
        
        # Visitas
        {"clave": "visitas.programar_masivo", "nombre": "Programación masiva", "modulo": "visitas"},
        {"clave": "visitas.eliminar", "nombre": "Eliminar visitas", "modulo": "visitas"},
        
        # Exportaciones
        {"clave": "exportaciones.solicitar", "nombre": "Solicitar exportaciones", "modulo": "exportaciones"},
        {"clave": "exportaciones.listar", "nombre": "Listar exportaciones", "modulo": "exportaciones"},
        
        # Auditoría
        {"clave": "auditoria.listar", "nombre": "Ver auditoría", "modulo": "auditoria"},
        {"clave": "auditoria.exportar", "nombre": "Exportar auditoría", "modulo": "auditoria"},
        
        # Permisos y roles
        {"clave": "roles.listar", "nombre": "Listar roles", "modulo": "roles"},
        {"clave": "roles.crear", "nombre": "Crear roles", "modulo": "roles"},
        {"clave": "roles.editar", "nombre": "Editar roles", "modulo": "roles"},
        {"clave": "permisos.asignar", "nombre": "Asignar permisos", "modulo": "permisos"},
    ]
    
    print("🔐 Creando permisos por defecto...")
    for permiso_data in permisos_default:
        permiso_existente = db.query(models.Permiso).filter(
            models.Permiso.clave == permiso_data["clave"]
        ).first()
        
        if not permiso_existente:
            nuevo_permiso = models.Permiso(**permiso_data)
            db.add(nuevo_permiso)
            print(f"  ✅ Permiso creado: {permiso_data['clave']}")
        else:
            print(f"  ⏭️  Permiso ya existe: {permiso_data['clave']}")
    
    db.commit()

def assign_permissions_to_roles(db: Session):
    """Asigna permisos a los roles según su jerarquía."""
    
    # Super Administrador: todos los permisos
    super_admin = db.query(models.Rol).filter(models.Rol.nombre == "Super Administrador").first()
    todos_permisos = db.query(models.Permiso).all()
    
    print("👑 Asignando permisos a Super Administrador...")
    for permiso in todos_permisos:
        permiso_rol_existente = db.query(models.RolPermiso).filter(
            models.RolPermiso.rol_id == super_admin.id,
            models.RolPermiso.permiso_id == permiso.id
        ).first()
        
        if not permiso_rol_existente:
            nuevo_rol_permiso = models.RolPermiso(
                rol_id=super_admin.id,
                permiso_id=permiso.id
            )
            db.add(nuevo_rol_permiso)
    
    # Administrador: casi todos excepto configuración crítica
    admin = db.query(models.Rol).filter(models.Rol.nombre == "Administrador").first()
    permisos_admin = db.query(models.Permiso).filter(
        ~models.Permiso.clave.in_([
            "config.editar",  # No puede editar configuración crítica
            "roles.crear",    # No puede crear roles
            "roles.editar"    # No puede editar roles
        ])
    ).all()
    
    print("🛡️  Asignando permisos a Administrador...")
    for permiso in permisos_admin:
        permiso_rol_existente = db.query(models.RolPermiso).filter(
            models.RolPermiso.rol_id == admin.id,
            models.RolPermiso.permiso_id == permiso.id
        ).first()
        
        if not permiso_rol_existente:
            nuevo_rol_permiso = models.RolPermiso(
                rol_id=admin.id,
                permiso_id=permiso.id
            )
            db.add(nuevo_rol_permiso)
    
    # Supervisor: permisos de gestión de equipo
    supervisor = db.query(models.Rol).filter(models.Rol.nombre == "Supervisor").first()
    permisos_supervisor = db.query(models.Permiso).filter(
        models.Permiso.clave.in_([
            "usuarios.listar",
            "checklists.listar",
            "visitas.programar_masivo",
            "exportaciones.solicitar",
            "exportaciones.listar"
        ])
    ).all()
    
    print("👥 Asignando permisos a Supervisor...")
    for permiso in permisos_supervisor:
        permiso_rol_existente = db.query(models.RolPermiso).filter(
            models.RolPermiso.rol_id == supervisor.id,
            models.RolPermiso.permiso_id == permiso.id
        ).first()
        
        if not permiso_rol_existente:
            nuevo_rol_permiso = models.RolPermiso(
                rol_id=supervisor.id,
                permiso_id=permiso.id
            )
            db.add(nuevo_rol_permiso)
    
    # Visitador: permisos básicos
    visitador = db.query(models.Rol).filter(models.Rol.nombre == "Visitador").first()
    permisos_visitador = db.query(models.Permiso).filter(
        models.Permiso.clave.in_([
            "checklists.listar",
        ])
    ).all()
    
    print("🚶 Asignando permisos a Visitador...")
    for permiso in permisos_visitador:
        permiso_rol_existente = db.query(models.RolPermiso).filter(
            models.RolPermiso.rol_id == visitador.id,
            models.RolPermiso.permiso_id == permiso.id
        ).first()
        
        if not permiso_rol_existente:
            nuevo_rol_permiso = models.RolPermiso(
                rol_id=visitador.id,
                permiso_id=permiso.id
            )
            db.add(nuevo_rol_permiso)
    
    db.commit()

def create_admin_user(db: Session):
    """Crea el usuario administrador inicial."""
    
    admin_email = "admin@educacion.cauca.gov.co"
    admin_password = "Admin123!"  # Cambiar en producción
    
    print("👤 Creando usuario administrador inicial...")
    
    # Verificar si ya existe
    admin_existente = db.query(models.Usuario).filter(
        models.Usuario.correo == admin_email
    ).first()
    
    if admin_existente:
        print(f"  ⏭️  Usuario administrador ya existe: {admin_email}")
        return
    
    # Obtener rol de Super Administrador
    super_admin_rol = db.query(models.Rol).filter(
        models.Rol.nombre == "Super Administrador"
    ).first()
    
    if not super_admin_rol:
        print("  ❌ Error: No se encontró el rol Super Administrador")
        return
    
    # Crear usuario
    admin_user = models.Usuario(
        nombre="Administrador del Sistema",
        correo=admin_email,
        contrasena=pwd_context.hash(admin_password),
        rol_id=super_admin_rol.id,
        activo=True,
        twofa_enabled=False,  # Se habilitará después del primer login
        fecha_creacion=datetime.utcnow()
    )
    
    db.add(admin_user)
    db.commit()
    
    print(f"  ✅ Usuario administrador creado:")
    print(f"     Email: {admin_email}")
    print(f"     Password: {admin_password}")
    print(f"     ⚠️  IMPORTANTE: Cambiar la contraseña en el primer login")

def create_default_config(db: Session):
    """Crea la configuración por defecto del sistema."""
    
    configuraciones_default = [
        {
            "clave": "seguridad.intentos_maximos_login",
            "valor_json": "5",
            "descripcion": "Número máximo de intentos de login fallidos antes de bloquear cuenta",
            "categoria": "seguridad",
            "tipo_dato": "number"
        },
        {
            "clave": "seguridad.duracion_bloqueo_minutos",
            "valor_json": "30",
            "descripcion": "Duración del bloqueo de cuenta en minutos",
            "categoria": "seguridad",
            "tipo_dato": "number"
        },
        {
            "clave": "seguridad.expiracion_contrasena_dias",
            "valor_json": "90",
            "descripcion": "Días para expiración de contraseña",
            "categoria": "seguridad",
            "tipo_dato": "number"
        },
        {
            "clave": "exportacion.tamaño_maximo_mb",
            "valor_json": "100",
            "descripcion": "Tamaño máximo de archivos de exportación en MB",
            "categoria": "exportacion",
            "tipo_dato": "number"
        },
        {
            "clave": "exportacion.dias_expiracion",
            "valor_json": "7",
            "descripcion": "Días antes de que expire un archivo de exportación",
            "categoria": "exportacion",
            "tipo_dato": "number"
        },
        {
            "clave": "notificaciones.email_habilitado",
            "valor_json": "true",
            "descripcion": "Habilitar notificaciones por email",
            "categoria": "notificaciones",
            "tipo_dato": "boolean"
        },
        {
            "clave": "visitas.tiempo_maximo_horas",
            "valor_json": "8",
            "descripcion": "Tiempo máximo para completar una visita (horas)",
            "categoria": "visitas",
            "tipo_dato": "number"
        },
        {
            "clave": "visitas.dias_alerta_vencimiento",
            "valor_json": "3",
            "descripcion": "Días antes del vencimiento para enviar alerta",
            "categoria": "visitas",
            "tipo_dato": "number"
        }
    ]
    
    print("⚙️  Creando configuración por defecto...")
    for config_data in configuraciones_default:
        config_existente = db.query(models.ConfiguracionSistema).filter(
            models.ConfiguracionSistema.clave == config_data["clave"]
        ).first()
        
        if not config_existente:
            nueva_config = models.ConfiguracionSistema(**config_data)
            db.add(nueva_config)
            print(f"  ✅ Configuración creada: {config_data['clave']}")
        else:
            print(f"  ⏭️  Configuración ya existe: {config_data['clave']}")
    
    db.commit()

def create_default_visit_types(db: Session):
    """Crea los tipos de visita por defecto."""
    
    tipos_default = [
        {
            "nombre": "PAE - Programa de Alimentación Escolar",
            "descripcion": "Verificación del cumplimiento del Programa de Alimentación Escolar",
            "color_codigo": "#4CAF50",
            "orden": 1
        },
        {
            "nombre": "Infraestructura y Mantenimiento",
            "descripcion": "Inspección del estado de la infraestructura educativa",
            "color_codigo": "#FF9800",
            "orden": 2
        },
        {
            "nombre": "Seguridad y Protección",
            "descripcion": "Verificación de medidas de seguridad y protección",
            "color_codigo": "#F44336",
            "orden": 3
        },
        {
            "nombre": "Calidad Educativa",
            "descripcion": "Evaluación de la calidad de los procesos educativos",
            "color_codigo": "#2196F3",
            "orden": 4
        }
    ]
    
    print("📋 Creando tipos de visita por defecto...")
    for tipo_data in tipos_default:
        tipo_existente = db.query(models.TipoVisita).filter(
            models.TipoVisita.nombre == tipo_data["nombre"]
        ).first()
        
        if not tipo_existente:
            nuevo_tipo = models.TipoVisita(**tipo_data)
            db.add(nuevo_tipo)
            print(f"  ✅ Tipo de visita creado: {tipo_data['nombre']}")
        else:
            print(f"  ⏭️  Tipo de visita ya existe: {tipo_data['nombre']}")
    
    db.commit()

def create_sample_checklist_template(db: Session):
    """Crea un template de checklist de ejemplo para PAE."""
    
    # Obtener el tipo PAE
    tipo_pae = db.query(models.TipoVisita).filter(
        models.TipoVisita.nombre.contains("PAE")
    ).first()
    
    if not tipo_pae:
        print("  ⚠️  No se encontró el tipo de visita PAE, saltando creación de template")
        return
    
    # Verificar si ya existe
    template_existente = db.query(models.ChecklistTemplate).filter(
        models.ChecklistTemplate.tipo_visita_id == tipo_pae.id,
        models.ChecklistTemplate.version == "1.0"
    ).first()
    
    if template_existente:
        print("  ⏭️  Template PAE v1.0 ya existe")
        return
    
    # Schema de ejemplo para PAE
    schema_pae = {
        "categorias": [
            {
                "id": "equipos_utensilios",
                "nombre": "Equipos y Utensilios",
                "orden": 1,
                "items": [
                    {
                        "id": "cocina_funcionando",
                        "pregunta": "¿La cocina se encuentra en funcionamiento?",
                        "tipo": "si_no",
                        "requerido": True,
                        "evidencia_requerida": False
                    },
                    {
                        "id": "utensilios_limpios",
                        "pregunta": "¿Los utensilios de cocina están limpios?",
                        "tipo": "si_no",
                        "requerido": True,
                        "evidencia_requerida": True
                    }
                ]
            },
            {
                "id": "personal_manipulador",
                "nombre": "Personal Manipulador",
                "orden": 2,
                "items": [
                    {
                        "id": "uniforme_completo",
                        "pregunta": "¿El personal cuenta con uniforme completo?",
                        "tipo": "si_no",
                        "requerido": True,
                        "evidencia_requerida": True
                    },
                    {
                        "id": "capacitacion_actualizada",
                        "pregunta": "¿El personal tiene capacitación actualizada?",
                        "tipo": "si_no",
                        "requerido": True,
                        "evidencia_requerida": False
                    }
                ]
            }
        ]
    }
    
    template_pae = models.ChecklistTemplate(
        tipo_visita_id=tipo_pae.id,
        version="1.0",
        nombre="Checklist PAE Estándar v1.0",
        descripcion="Template estándar para evaluación del Programa de Alimentación Escolar",
        json_schema=json.dumps(schema_pae),
        publicado=True,
        publicado_en=datetime.utcnow(),
        activo=True
    )
    
    db.add(template_pae)
    db.commit()
    
    print("  ✅ Template de checklist PAE v1.0 creado y publicado")

def main():
    """Función principal de inicialización."""
    print("🚀 Iniciando configuración del sistema de administración...\n")
    
    # Crear tablas
    print("📊 Creando tablas de base de datos...")
    models.Base.metadata.create_all(bind=engine)
    print("  ✅ Tablas creadas\n")
    
    # Obtener sesión de base de datos
    db = SessionLocal()
    
    try:
        # Ejecutar todas las inicializaciones
        create_default_roles(db)
        print()
        
        create_default_permissions(db)
        print()
        
        assign_permissions_to_roles(db)
        print()
        
        create_admin_user(db)
        print()
        
        create_default_config(db)
        print()
        
        create_default_visit_types(db)
        print()
        
        create_sample_checklist_template(db)
        print()
        
        print("🎉 ¡Inicialización completada exitosamente!")
        print("\n📝 Resumen:")
        print("   - Roles y permisos configurados")
        print("   - Usuario administrador creado")
        print("   - Configuración del sistema establecida")
        print("   - Tipos de visita por defecto creados")
        print("   - Template de checklist PAE creado")
        print("\n🔐 Credenciales de administrador:")
        print("   Email: admin@educacion.cauca.gov.co")
        print("   Password: Admin123!")
        print("   ⚠️  IMPORTANTE: Cambiar contraseña en primer login")
        
    except Exception as e:
        print(f"❌ Error durante la inicialización: {str(e)}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    main()
