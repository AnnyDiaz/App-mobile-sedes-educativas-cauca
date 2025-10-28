# app/routes/visitas.py

from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, Request, Query, Path, status
from sqlalchemy.orm import Session, joinedload
from app import models, schemas
from app.database import get_db
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy import func
from typing import Optional, List
from uuid import uuid4
import shutil
import os

# Asumo que estas dependencias vienen de tu archivo auth.py
from app.dependencies import get_current_user 

router = APIRouter(
    tags=["Visitas y Sedes"] # Agrupa las rutas en la documentación de Swagger
)

# --- ENDPOINTS DE CONSULTA GEOGRÁFICA (NORMALIZADOS) ---
# Nota: Los municipios se manejan en app/routes/municipios.py

@router.get("/instituciones", response_model=List[schemas.InstitucionOut])
def listar_instituciones(db: Session = Depends(get_db)):
    """
    Obtiene una lista de todas las instituciones educativas.
    """
    return db.query(models.Institucion).order_by(models.Institucion.nombre).all()

@router.get("/instituciones_por_municipio/{municipio_id}", response_model=List[schemas.InstitucionOut])
def listar_instituciones_por_municipio(municipio_id: int, db: Session = Depends(get_db)):
    """
    Obtiene las instituciones educativas de un municipio específico.
    """
    return db.query(models.Institucion).filter(
        models.Institucion.municipio_id == municipio_id
    ).order_by(models.Institucion.nombre).all()

@router.get("/sedes_por_municipio/{municipio_id}", response_model=List[schemas.SedeEducativaSimpleOut])
def listar_sedes_por_municipio(municipio_id: int, db: Session = Depends(get_db)):
    """
    Obtiene las sedes educativas de un municipio específico.
    """
    return db.query(models.SedeEducativa).filter(
        models.SedeEducativa.municipio_id == municipio_id
    ).order_by(models.SedeEducativa.nombre).all()

@router.get("/sedes_por_institucion/{institucion_id}", response_model=List[schemas.SedeEducativaSimpleOut])
def listar_sedes_por_institucion(institucion_id: int, db: Session = Depends(get_db)):
    """
    Obtiene las sedes educativas de una institución específica.
    """
    return db.query(models.SedeEducativa).filter(
        models.SedeEducativa.institucion_id == institucion_id
    ).order_by(models.SedeEducativa.nombre).all()

# --- ENDPOINTS DE VISITAS (CRUD Y LÓGICA DE NEGOCIO) ---

@router.post("/visitas", response_model=schemas.VisitaOut, status_code=status.HTTP_201_CREATED)
def crear_visita(
    # El usuario se obtiene del token, no se envía en el formulario
    usuario: models.Usuario = Depends(get_current_user),
    # Datos del formulario
    sede_id: int = Form(...),
    tipo_asunto: str = Form(...),
    observaciones: str = Form(...),
    lat: float = Form(...),
    lon: float = Form(...),
    # Archivos opcionales
    foto_evidencia: UploadFile = File(None),
    video_evidencia: UploadFile = File(None),
    audio_evidencia: UploadFile = File(None),
    pdf_evidencia: UploadFile = File(None),
    foto_firma: UploadFile = File(None),
    # Dependencia de la base de datos
    db: Session = Depends(get_db)
):
    """
    Crea un nuevo registro de visita. El ID del usuario se toma del token de autenticación.
    """
    def guardar_archivo(archivo: UploadFile, carpeta: str) -> Optional[str]:
        if not archivo:
            return None
        
        # Uso de UUID para nombres de archivo únicos y seguros
        ext = archivo.filename.split(".")[-1]
        nombre_archivo = f"{uuid4()}.{ext}"
        ruta_directorio = os.path.join("media", carpeta)
        os.makedirs(ruta_directorio, exist_ok=True)
        ruta_completa = os.path.join(ruta_directorio, nombre_archivo)
        
        with open(ruta_completa, "wb") as buffer:
            shutil.copyfileobj(archivo.file, buffer)
        
        # Guardamos la ruta relativa
        return ruta_completa

    # NOTA: Esta función usa el modelo Visita que ya no existe
    # Se mantiene comentada por compatibilidad histórica
    # Para crear visitas, usar el endpoint /api/visitas-completas-pae
    raise HTTPException(
        status_code=400,
        detail="Este endpoint está deshabilitado. Use /api/visitas-completas-pae para crear visitas."
    )

@router.get("/visitas", response_model=List[schemas.VisitaOut])
def listar_visitas_para_admin(
    request: Request,
    db: Session = Depends(get_db),
    # Filtros opcionales
    municipio_id: Optional[int] = Query(None),
    sede_id: Optional[int] = Query(None),
    estado: Optional[str] = Query(None),
    # Dependencia de autorización
    usuario: models.Usuario = Depends(get_current_user)
):
    """
    Endpoint unificado para listar visitas. Los administradores pueden ver todo.
    Los demás usuarios deben usar /visitas/mis-visitas.
    """
    # COMENTADO: Verificación de rol deshabilitada temporalmente
    # if usuario.rol.nombre != 'admin':
    #     raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes permiso para ver todas las visitas.")

    # NOTA: Este endpoint usa el modelo Visita que ya no existe
    # Se mantiene comentado por compatibilidad histórica
    # Para listar visitas, usar el endpoint /api/visitas-completas-pae
    raise HTTPException(
        status_code=400,
        detail="Este endpoint está deshabilitado. Use /api/visitas-completas-pae para listar visitas."
    )

@router.get("/visitas/todas", response_model=List[schemas.VisitaCompletaPAEOut])
def listar_todas_visitas(
    request: Request,
    db: Session = Depends(get_db),
    usuario: models.Usuario = Depends(get_current_user)
):
    """
    Obtiene todas las visitas completas PAE. Solo para supervisores y administradores.
    """
    try:
        # Verificar permisos
        if usuario.rol.nombre not in ['supervisor', 'admin']:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, 
                detail="No tienes permiso para ver todas las visitas."
            )
        
        # Obtener todas las visitas con relaciones cargadas
        query = db.query(models.VisitaCompletaPAE).options(
            joinedload(models.VisitaCompletaPAE.municipio),
            joinedload(models.VisitaCompletaPAE.institucion),
            joinedload(models.VisitaCompletaPAE.sede),
            joinedload(models.VisitaCompletaPAE.profesional)
        )
        
        # Si es supervisor, mostrar solo visitas de su área
        if usuario.rol.nombre == 'supervisor':
            # Por ahora, mostrar todas las visitas para supervisores
            # En el futuro se puede filtrar por área geográfica
            pass
        
        visitas = query.order_by(models.VisitaCompletaPAE.fecha_creacion.desc()).all()
        
        print(f"🔍 Usuario {usuario.id} ({usuario.nombre}) - Encontradas {len(visitas)} visitas totales")
        for visita in visitas:
            print(f"   - Visita ID: {visita.id}, Estado: {visita.estado}, Profesional: {visita.profesional.nombre}")
        
        return visitas
    except Exception as e:
        print(f"❌ Error al listar todas las visitas: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al cargar todas las visitas: {str(e)}"
        )

@router.get("/visitas/mis-visitas", response_model=List[schemas.VisitaCompletaPAEOut])
def listar_mis_visitas(
    request: Request,
    db: Session = Depends(get_db),
    usuario: models.Usuario = Depends(get_current_user),
    estado: Optional[str] = Query(None, description="Filtrar por estado: 'pendiente' o 'completada'")
):
    """
    Obtiene la lista de visitas completas PAE asignadas al usuario actualmente autenticado.
    """
    try:
        query = db.query(models.VisitaCompletaPAE).options(
            joinedload(models.VisitaCompletaPAE.municipio),
            joinedload(models.VisitaCompletaPAE.institucion),
            joinedload(models.VisitaCompletaPAE.sede),
            joinedload(models.VisitaCompletaPAE.profesional)
        ).filter(models.VisitaCompletaPAE.profesional_id == usuario.id)
        
        if estado:
            query = query.filter(models.VisitaCompletaPAE.estado == estado)
        
        visitas = query.order_by(models.VisitaCompletaPAE.fecha_creacion.desc()).all()
        
        print(f"🔍 Usuario {usuario.id} ({usuario.nombre}) - Encontradas {len(visitas)} visitas")
        for visita in visitas:
            print(f"   - Visita ID: {visita.id}, Estado: {visita.estado}")
        
        return visitas
    except Exception as e:
        print(f"❌ Error al listar mis visitas: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al cargar visitas por estado: {str(e)}"
        )


@router.put("/visitas/{visita_id}/estado", response_model=schemas.VisitaOut)
def actualizar_estado_visita(
    visita_id: int,
    nuevo_estado: schemas.EstadoVisitaUpdate, # Usamos un schema para el body
    db: Session = Depends(get_db),
    usuario: models.Usuario = Depends(get_current_user)
):
    """
    Actualiza el estado de una visita a 'pendiente' or 'completada'.
    """
    # NOTA: Este endpoint usa el modelo Visita que ya no existe
    # Se mantiene comentado por compatibilidad histórica
    # Para actualizar visitas, usar el endpoint /api/visitas-completas-pae
    raise HTTPException(
        status_code=400,
        detail="Este endpoint está deshabilitado. Use /api/visitas-completas-pae para actualizar visitas."
    )


# --- FUNCIÓN AUXILIAR ---
def _build_absolute_url(request: Request, file_path: str) -> Optional[str]:
    """Construye una URL absoluta para un archivo de evidencia."""
    if not file_path:
        return None
    return str(request.base_url.replace(path=file_path))

# --- ENDPOINTS PARA EL DASHBOARD DEL VISITADOR ---

@router.get("/dashboard/estadisticas")
def obtener_estadisticas_visitador(
    db: Session = Depends(get_db),
    usuario: models.Usuario = Depends(get_current_user)
):
    """
    Obtiene estadísticas del visitador: visitas pendientes, en proceso y completadas.
    CORREGIDO: Ahora cuenta correctamente desde VisitaCompletaPAE
    """
    try:
        # CORREGIDO: Contar visitas pendientes usando VisitaAsignada (estado pendiente)
        visitas_pendientes = db.query(models.VisitaAsignada).filter(
            models.VisitaAsignada.visitador_id == usuario.id,
            models.VisitaAsignada.estado == "pendiente"
        ).count()
        
        # CORREGIDO: Contar visitas en proceso usando VisitaAsignada (estado en_proceso)
        visitas_en_proceso = db.query(models.VisitaAsignada).filter(
            models.VisitaAsignada.visitador_id == usuario.id,
            models.VisitaAsignada.estado == "en_proceso"
        ).count()
        
        # CORREGIDO: Contar visitas completadas usando VisitaCompletaPAE (todas las visitas del visitador)
        visitas_completadas = db.query(models.VisitaCompletaPAE).filter(
            models.VisitaCompletaPAE.profesional_id == usuario.id
        ).count()
        
        # Total de visitas activas (pendientes + en proceso)
        total_activas = visitas_pendientes + visitas_en_proceso
        
        # Total de todas las visitas (activas + completadas)
        total_visitas = total_activas + visitas_completadas
        
        print(f"📊 Estadísticas del visitador {usuario.nombre} (ID: {usuario.id}):")
        print(f"   - Pendientes: {visitas_pendientes}")
        print(f"   - En proceso: {visitas_en_proceso}")
        print(f"   - Completadas: {visitas_completadas}")
        print(f"   - Total activas: {total_activas}")
        print(f"   - Total visitas: {total_visitas}")
        
        return {
            "visitas_pendientes": visitas_pendientes,
            "visitas_en_proceso": visitas_en_proceso,
            "visitas_completadas": visitas_completadas,
            "total_visitas": total_visitas,
            "total_activas": total_activas
        }
    except Exception as e:
        print(f"❌ Error al obtener estadísticas del visitador: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al obtener estadísticas: {str(e)}"
        )

@router.get("/test-auth")
def test_auth(
    usuario: models.Usuario = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Endpoint de prueba para verificar autenticación básica.
    """
    return {
        "mensaje": "Autenticación exitosa",
        "usuario_id": usuario.id,
        "nombre": usuario.nombre,
        "correo": usuario.correo,
        "rol": usuario.rol.nombre if usuario.rol else "Sin rol",
        "activo": usuario.activo
    }

@router.get("/perfil")
def obtener_perfil_usuario(
    usuario: models.Usuario = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Obtiene el perfil del usuario autenticado.
    Accesible para todos los usuarios autenticados.
    """
    print(f"🔍 Usuario solicitando perfil: {usuario.correo}, Rol: {usuario.rol.nombre if usuario.rol else 'Sin rol'}")
    
    # Cargar el usuario con sus relaciones
    usuario_completo = db.query(models.Usuario).options(
        joinedload(models.Usuario.rol)
    ).filter(models.Usuario.id == usuario.id).first()
    
    if not usuario_completo:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    return {
        "nombre": usuario_completo.nombre,
        "correo": usuario_completo.correo,
        "rol": usuario_completo.rol.nombre if usuario_completo.rol else "Visitador",
        "rol_nombre": usuario_completo.rol.nombre if usuario_completo.rol else "Visitador",
        "cargo": usuario_completo.rol.nombre if usuario_completo.rol else "Visitador",
    }

@router.put("/cambiar-contrasena")
def cambiar_contrasena(
    contrasena_data: dict,
    usuario: models.Usuario = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Cambia la contraseña del usuario autenticado.
    """
    try:
        contrasena_actual = contrasena_data.get("contrasena_actual")
        contrasena_nueva = contrasena_data.get("contrasena_nueva")
        
        if not contrasena_actual or not contrasena_nueva:
            raise HTTPException(status_code=400, detail="Contraseña actual y nueva son requeridas")
        
        # Validar seguridad de la nueva contraseña
        error_validacion = _validar_seguridad_contrasena(contrasena_nueva)
        if error_validacion:
            raise HTTPException(status_code=400, detail=error_validacion)
        
        # Verificar contraseña actual
        from passlib.context import CryptContext
        pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
        
        if not pwd_context.verify(contrasena_actual, usuario.contrasena):
            raise HTTPException(status_code=400, detail="Contraseña actual incorrecta")
        
        # Hash de la nueva contraseña
        contrasena_nueva_hash = pwd_context.hash(contrasena_nueva)
        
        # Actualizar en la base de datos
        usuario.contrasena = contrasena_nueva_hash
        db.commit()
        
        return {"message": "Contraseña actualizada exitosamente"}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error al cambiar contraseña: {str(e)}")

def _validar_seguridad_contrasena(contrasena: str) -> str:
    """
    Valida que la contraseña cumpla con los requisitos de seguridad.
    Retorna un mensaje de error si no cumple, o None si es válida.
    """
    if len(contrasena) < 8:
        return "La contraseña debe tener al menos 8 caracteres"
    
    if not any(c.isupper() for c in contrasena):
        return "La contraseña debe contener al menos una letra mayúscula"
    
    if not any(c.islower() for c in contrasena):
        return "La contraseña debe contener al menos una letra minúscula"
    
    if not any(c.isdigit() for c in contrasena):
        return "La contraseña debe contener al menos un número"
    
    caracteres_especiales = "!@#$%^&*()_+-=[]{}|;:,.<>?"
    if not any(c in caracteres_especiales for c in contrasena):
        return "La contraseña debe contener al menos un carácter especial (!@#$%^&*()_+-=[]{}|;:,.<>?)"
    
    return None

# --- ENDPOINTS PARA EL CHECKLIST ---

@router.get("/checklist", response_model=List[schemas.ChecklistCategoriaBase])
def get_full_checklist(db: Session = Depends(get_db)):
    """
    Obtiene el checklist completo con categorías e items desde la base de datos.
    """
    try:
        # Obtener todas las categorías con sus items
        categorias = db.query(models.ChecklistCategoria).options(
            joinedload(models.ChecklistCategoria.items)
        ).all()
        
        return categorias
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error al obtener checklist: {str(e)}"
        )


@router.post("/visitas-checklist", status_code=201)
def create_visita_con_respuestas(
    visita_data: schemas.VisitaCompletaPAECreate,
    db: Session = Depends(get_db),
    usuario: models.Usuario = Depends(get_current_user)
):
    """
    Este endpoint recibe los datos de una visita y la lista de respuestas
    del checklist, y los guarda en la base de datos.
    """
    try:
        # Crear la visita completa PAE
        nueva_visita_completa = models.VisitaCompletaPAE(
            fecha_visita=visita_data.fecha_visita,
            contrato=visita_data.contrato,
            operador=visita_data.operador,
            caso_atencion_prioritaria=visita_data.caso_atencion_prioritaria,
            municipio_id=visita_data.municipio_id,
            institucion_id=visita_data.institucion_id,
            sede_id=visita_data.sede_id,
            profesional_id=visita_data.profesional_id,
            observaciones=visita_data.observaciones
        )
        db.add(nueva_visita_completa)
        db.flush()  # Para obtener el ID de la visita
        
        # Guardar las respuestas del checklist
        for respuesta in visita_data.respuestas_checklist:
            nueva_respuesta = models.VisitaRespuestaCompleta(
                visita_id=nueva_visita_completa.id,
                categoria_id=1,  # Por defecto
                item_id=respuesta.item_id,
                respuesta=respuesta.respuesta,
                observacion=respuesta.observacion
            )
            db.add(nueva_respuesta)
        
        db.commit()
        return {"mensaje": "Visita completa PAE guardada con éxito", "visita_id": nueva_visita_completa.id, "respuestas_guardadas": len(visita_data.respuestas_checklist)}
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error al guardar la visita: {str(e)}"
        )

@router.get("/visitas/ultimas", response_model=List[schemas.VisitaCompletaPAEOut])
def obtener_ultimas_visitas(
    db: Session = Depends(get_db),
    usuario: models.Usuario = Depends(get_current_user),
    limit: int = Query(10, description="Número de visitas a obtener")
):
    """
    Obtiene las últimas visitas del sistema
    """
    try:
        visitas = db.query(models.VisitaCompletaPAE)\
            .order_by(models.VisitaCompletaPAE.fecha_creacion.desc())\
            .limit(limit)\
            .all()
        
        return visitas
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener últimas visitas: {str(e)}")

@router.get("/visitas/sin-evidencia", response_model=List[schemas.VisitaCompletaPAEOut])
def obtener_visitas_sin_evidencia(
    db: Session = Depends(get_db),
    usuario: models.Usuario = Depends(get_current_user)
):
    """
    Obtiene las visitas que no tienen evidencia (fotos, videos, etc.)
    """
    try:
        visitas = db.query(models.VisitaCompletaPAE)\
            .filter(
                (models.VisitaCompletaPAE.foto_evidencia.is_(None)) |
                (models.VisitaCompletaPAE.video_evidencia.is_(None)) |
                (models.VisitaCompletaPAE.audio_evidencia.is_(None)) |
                (models.VisitaCompletaPAE.pdf_evidencia.is_(None))
            )\
            .order_by(models.VisitaCompletaPAE.fecha_creacion.desc())\
            .all()
        
        return visitas
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener visitas sin evidencia: {str(e)}")