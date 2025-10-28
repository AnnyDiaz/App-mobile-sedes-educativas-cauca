# app/routes/visitas_completas.py

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional
from datetime import datetime
try:
    import pandas as pd
    PANDAS_AVAILABLE = True
except ImportError:
    PANDAS_AVAILABLE = False
    print("⚠️ pandas no está disponible. La generación de Excel estará deshabilitada.")

from io import BytesIO
from fastapi.responses import StreamingResponse
import os
from openpyxl import load_workbook

from app import models, schemas
from app.database import get_db
from app.dependencies import get_current_user

router = APIRouter()

# Función helper para normalizar campos None en sedes
def normalizar_sede(sede):
    """Normaliza campos None en la sede a strings vacíos para evitar errores de serialización"""
    if sede:
        if hasattr(sede, 'dane') and sede.dane is None:
            sede.dane = ""
        if hasattr(sede, 'due') and sede.due is None:
            sede.due = ""
    return sede

@router.post("/test-crear-cronograma")
def test_crear_cronograma(
    datos: schemas.VisitaCompletaPAECreate,
    db: Session = Depends(get_db)
):
    """
    Endpoint de prueba para crear cronograma sin autenticación
    """
    try:
        print(f"🔄 TEST CREAR CRONOGRAMA - Datos recibidos: {datos}")
        
        # Validar que los IDs existan
        municipio = db.query(models.Municipio).filter(models.Municipio.id == datos.municipio_id).first()
        if not municipio:
            return {"error": "Municipio no encontrado"}
            
        institucion = db.query(models.Institucion).filter(models.Institucion.id == datos.institucion_id).first()
        if not institucion:
            return {"error": "Institución no encontrada"}
            
        sede = db.query(models.SedeEducativa).filter(models.SedeEducativa.id == datos.sede_id).first()
        if not sede:
            return {"error": "Sede no encontrada"}
            
        profesional = db.query(models.Usuario).filter(models.Usuario.id == datos.profesional_id).first()
        if not profesional:
            return {"error": "Profesional no encontrado"}
        
        print(f"✅ Validaciones pasadas - Creando visita completa...")
        
        # Crear la visita completa
        visita_completa = models.VisitaCompletaPAE(
            sede_id=datos.sede_id,
            municipio_id=datos.municipio_id,
            institucion_id=datos.institucion_id,
            profesional_id=datos.profesional_id,
            fecha_visita=datos.fecha_visita,
            contrato=datos.contrato,
            operador=datos.operador,
            estado='pendiente',  # Estado por defecto
            observaciones=datos.observaciones,
            fecha_creacion=datetime.utcnow()
        )
        
        db.add(visita_completa)
        db.flush()  # Para obtener el ID
        
        print(f"✅ Visita completa creada con ID: {visita_completa.id}")
        
        # Crear respuestas del checklist
        for respuesta_data in datos.respuestas_checklist:
            respuesta = models.VisitaRespuestaCompleta(
                visita_id=visita_completa.id,
                categoria_id=1,  # Por defecto
                item_id=respuesta_data.item_id,
                respuesta=respuesta_data.respuesta,
                observacion=respuesta_data.observacion
            )
            db.add(respuesta)
        
        print(f"✅ Respuestas del checklist creadas: {len(datos.respuestas_checklist)}")
        
        # Crear o actualizar visita asignada
        visita_asignada = db.query(models.VisitaAsignada).filter(
            models.VisitaAsignada.sede_id == datos.sede_id,
            models.VisitaAsignada.visitador_id == datos.profesional_id,
            models.VisitaAsignada.contrato == datos.contrato
        ).first()
        
        if visita_asignada:
            print(f"✅ Visita asignada existente encontrada: ID {visita_asignada.id}")
            visita_asignada.estado = "completada"
            if visita_asignada.fecha_completada is None:
                visita_asignada.fecha_completada = datetime.utcnow()
        else:
            print(f"🔄 Creando nueva visita asignada...")
            # Buscar supervisor o usar el profesional como supervisor
            supervisor = db.query(models.Usuario).filter(
                models.Usuario.rol_id == 2  # Rol supervisor
            ).first()
            
            if not supervisor:
                supervisor_id = datos.profesional_id
                print(f"⚠️ No se encontró supervisor, usando profesional como supervisor")
            else:
                supervisor_id = supervisor.id
                print(f"✅ Supervisor encontrado: ID {supervisor_id}")
            
            visita_asignada = models.VisitaAsignada(
                sede_id=datos.sede_id,
                visitador_id=datos.profesional_id,
                supervisor_id=supervisor_id,
                contrato=datos.contrato,
                estado="completada",
                fecha_creacion=datetime.utcnow(),
                fecha_completada=datetime.utcnow(),
                tipo_visita="PAE",
                municipio_id=datos.municipio_id,
                institucion_id=datos.institucion_id,
                fecha_programada=datetime.utcnow()
            )
            db.add(visita_asignada)
        
        db.commit()
        
        print(f"✅ TEST COMPLETADO - Visita creada exitosamente")
        return {
            "mensaje": "Cronograma creado exitosamente",
            "visita_completa_id": visita_completa.id,
            "visita_asignada_id": visita_asignada.id if visita_asignada else None,
            "estado": "completada"
        }
        
    except Exception as e:
        db.rollback()
        print(f"❌ Error en test crear cronograma: {str(e)}")
        return {"error": f"Error al crear cronograma: {str(e)}"}

@router.post("/visitas-completas-pae", response_model=schemas.VisitaCompletaPAEOut)
def crear_visita_completa_pae(
    datos: schemas.VisitaCompletaPAECreate,
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user)
):
    """
    Crea una visita completa PAE con cronograma y respuestas del checklist
    """
    try:
        # Validar que los IDs existan
        municipio = db.query(models.Municipio).filter(models.Municipio.id == datos.municipio_id).first()
        if not municipio:
            raise HTTPException(status_code=400, detail="Municipio no encontrado")
            
        institucion = db.query(models.Institucion).filter(models.Institucion.id == datos.institucion_id).first()
        if not institucion:
            raise HTTPException(status_code=400, detail="Institución no encontrada")
            
        sede = db.query(models.SedeEducativa).filter(models.SedeEducativa.id == datos.sede_id).first()
        if not sede:
            raise HTTPException(status_code=400, detail="Sede no encontrada")
            
        profesional = db.query(models.Usuario).filter(models.Usuario.id == datos.profesional_id).first()
        if not profesional:
            raise HTTPException(status_code=400, detail="Profesional no encontrado")

        # Calcular el número de visita para este usuario
        # Contar visitas existentes del usuario + 1
        visitas_usuario_count = db.query(models.VisitaCompletaPAE).filter(
            models.VisitaCompletaPAE.profesional_id == datos.profesional_id
        ).count()
        numero_visita_usuario = visitas_usuario_count + 1

        # Crear la visita completa
        visita_completa = models.VisitaCompletaPAE(
            fecha_visita=datos.fecha_visita,
            contrato=datos.contrato,
            operador=datos.operador,
            municipio_id=datos.municipio_id,
            institucion_id=datos.institucion_id,
            sede_id=datos.sede_id,
            profesional_id=datos.profesional_id,
            observaciones=datos.observaciones,
            estado="completada",  # Se marca como completada inmediatamente
            numero_visita_usuario=numero_visita_usuario
        )
        # Asignar caso_atencion_prioritaria usando el setter (es una propiedad)
        visita_completa.caso_atencion_prioritaria = datos.caso_atencion_prioritaria
        
        db.add(visita_completa)
        db.flush()  # Para obtener el ID
        
        # Guardar las respuestas del checklist
        for respuesta_data in datos.respuestas_checklist:
            respuesta = models.VisitaRespuestaCompleta(
                visita_id=visita_completa.id,
                categoria_id=1,  # Por defecto
                item_id=respuesta_data.item_id,
                respuesta=respuesta_data.respuesta,
                observacion=respuesta_data.observacion
            )
            db.add(respuesta)
        
        # IMPORTANTE: Crear o actualizar la visita asignada correspondiente
        print(f"🔍 Buscando visita asignada para sincronizar...")
        print(f"   - Sede ID: {datos.sede_id}")
        print(f"   - Profesional ID: {datos.profesional_id}")
        print(f"   - Contrato: {datos.contrato}")
        
        # Buscar la visita asignada que coincida con estos datos
        visita_asignada = db.query(models.VisitaAsignada).filter(
            models.VisitaAsignada.sede_id == datos.sede_id,
            models.VisitaAsignada.visitador_id == datos.profesional_id,
            models.VisitaAsignada.contrato == datos.contrato,
            models.VisitaAsignada.estado.in_(["pendiente", "en_proceso"])
        ).first()
        
        if visita_asignada:
            print(f"✅ Visita asignada encontrada: ID {visita_asignada.id}, Estado actual: {visita_asignada.estado}")
            print(f"🔄 Actualizando estado de visita asignada ID {visita_asignada.id} de '{visita_asignada.estado}' a 'completada'")
            visita_asignada.estado = "completada"
            visita_asignada.fecha_completada = datetime.utcnow()
            print(f"✅ Visita asignada ID {visita_asignada.id} actualizada a 'completada'")
        else:
            print(f"⚠️ No se encontró visita asignada correspondiente para sincronizar")
            # Si no existe visita asignada, crear una nueva
            print(f"🆕 No se encontró visita asignada correspondiente. Creando nueva visita asignada...")
            
            # Obtener el supervisor (asumimos que es el usuario con rol supervisor)
            supervisor = db.query(models.Usuario).join(models.Rol).filter(
                models.Rol.nombre == "supervisor"
            ).first()
            
            if not supervisor:
                print("⚠️ No se encontró supervisor, usando profesional como supervisor")
                supervisor = profesional
            
            nueva_visita_asignada = models.VisitaAsignada(
                sede_id=datos.sede_id,
                visitador_id=datos.profesional_id,
                supervisor_id=supervisor.id,
                fecha_programada=datos.fecha_visita,
                tipo_visita="PAE",  # Valor por defecto
                prioridad="normal",  # Valor por defecto
                estado="completada",  # Se marca como completada inmediatamente
                contrato=datos.contrato,
                operador=datos.operador,
                caso_atencion_prioritaria=datos.caso_atencion_prioritaria,
                municipio_id=datos.municipio_id,
                institucion_id=datos.institucion_id,
                observaciones=datos.observaciones,
                fecha_completada=datetime.utcnow()
            )
            
            db.add(nueva_visita_asignada)
            print(f"✅ Nueva visita asignada creada con ID {nueva_visita_asignada.id}")
            
        # CORRECCIÓN: También buscar visitas asignadas que tengan visitas completas correspondientes
        # pero que no se hayan actualizado automáticamente
        visitas_asignadas_pendientes = db.query(models.VisitaAsignada).filter(
            models.VisitaAsignada.visitador_id == datos.profesional_id,
            models.VisitaAsignada.estado.in_(["pendiente", "en_proceso"])
        ).all()
        
        for visita_pendiente in visitas_asignadas_pendientes:
            # Buscar si existe una visita completa correspondiente
            visita_completa_existente = db.query(models.VisitaCompletaPAE).filter(
                models.VisitaCompletaPAE.sede_id == visita_pendiente.sede_id,
                models.VisitaCompletaPAE.profesional_id == visita_pendiente.visitador_id,
                models.VisitaCompletaPAE.contrato == visita_pendiente.contrato
            ).first()
            
            if visita_completa_existente:
                print(f"🔄 CORRECCIÓN: Actualizando visita asignada ID {visita_pendiente.id} que ya tiene visita completa")
                visita_pendiente.estado = "completada"
                visita_pendiente.fecha_completada = datetime.utcnow()
        
        # NOTA: VisitaProgramada no tiene campos visitador_id, estado, ni contrato
        # Esta lógica se eliminó porque el modelo VisitaProgramada no tiene estos campos
        
        db.commit()
        
        # Retornar la visita completa con relaciones cargadas
        from sqlalchemy.orm import joinedload
        visita_retornar = db.query(models.VisitaCompletaPAE).options(
            joinedload(models.VisitaCompletaPAE.municipio),
            joinedload(models.VisitaCompletaPAE.institucion),
            joinedload(models.VisitaCompletaPAE.sede),
            joinedload(models.VisitaCompletaPAE.profesional),
            joinedload(models.VisitaCompletaPAE.respuestas_checklist)
        ).filter(
            models.VisitaCompletaPAE.id == visita_completa.id
        ).first()
        
        if not visita_retornar:
            raise HTTPException(status_code=500, detail="Error al recuperar la visita creada")
        
        # El schema ahora acepta None, no necesitamos normalizar
        return visita_retornar
        
    except HTTPException:
        # Re-lanzar excepciones HTTP sin modificar
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        import traceback
        error_traceback = traceback.format_exc()
        print(f"❌ === ERROR AL CREAR VISITA COMPLETA PAE ===")
        print(f"❌ Tipo de error: {type(e).__name__}")
        print(f"❌ Mensaje: {str(e)}")
        print(f"❌ Traceback completo:")
        print(error_traceback)
        print(f"❌ Datos recibidos: {datos}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al crear visita completa: {str(e)}"
        )

@router.get("/visitas-completas-pae", response_model=List[schemas.VisitaCompletaPAEOut])
def listar_visitas_completas_pae(
    contrato: Optional[str] = Query(None, description="Filtrar por contrato"),
    operador: Optional[str] = Query(None, description="Filtrar por operador"),
    municipio_id: Optional[int] = Query(None, description="Filtrar por municipio"),
    institucion_id: Optional[int] = Query(None, description="Filtrar por institución"),
    estado: Optional[str] = Query(None, description="Filtrar por estado"),
    fecha_inicio: Optional[str] = Query(None, description="Filtrar desde fecha (YYYY-MM-DD)"),
    fecha_fin: Optional[str] = Query(None, description="Filtrar hasta fecha (YYYY-MM-DD)"),
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user)
):
    """
    Lista las visitas completas PAE del usuario actual con filtros opcionales
    """
    try:
        # Construir query base - FILTRAR POR USUARIO ACTUAL
        query = db.query(models.VisitaCompletaPAE).filter(
            models.VisitaCompletaPAE.profesional_id == current_user.id
        )
        
        # Aplicar filtros
        if contrato:
            query = query.filter(models.VisitaCompletaPAE.contrato.ilike(f"%{contrato}%"))
        
        if operador:
            query = query.filter(models.VisitaCompletaPAE.operador.ilike(f"%{operador}%"))
        
        if municipio_id:
            query = query.filter(models.VisitaCompletaPAE.municipio_id == municipio_id)
        
        if institucion_id:
            query = query.filter(models.VisitaCompletaPAE.institucion_id == institucion_id)
        
        if estado:
            query = query.filter(models.VisitaCompletaPAE.estado == estado)
        
        if fecha_inicio:
            from datetime import datetime
            try:
                fecha_inicio_dt = datetime.strptime(fecha_inicio, "%Y-%m-%d")
                query = query.filter(models.VisitaCompletaPAE.fecha_visita >= fecha_inicio_dt)
            except ValueError:
                raise HTTPException(status_code=400, detail="Formato de fecha_inicio inválido. Use YYYY-MM-DD")
        
        if fecha_fin:
            from datetime import datetime
            try:
                fecha_fin_dt = datetime.strptime(fecha_fin, "%Y-%m-%d")
                # Agregar 23:59:59 para incluir todo el día
                fecha_fin_dt = fecha_fin_dt.replace(hour=23, minute=59, second=59)
                query = query.filter(models.VisitaCompletaPAE.fecha_visita <= fecha_fin_dt)
            except ValueError:
                raise HTTPException(status_code=400, detail="Formato de fecha_fin inválido. Use YYYY-MM-DD")
        
        # Obtener visitas con relaciones cargadas
        visitas = query.options(
            joinedload(models.VisitaCompletaPAE.municipio),
            joinedload(models.VisitaCompletaPAE.institucion),
            joinedload(models.VisitaCompletaPAE.sede),
            joinedload(models.VisitaCompletaPAE.profesional),
            joinedload(models.VisitaCompletaPAE.respuestas_checklist)
        ).order_by(models.VisitaCompletaPAE.fecha_visita.desc()).all()
        
        # El schema ahora acepta None, no necesitamos normalizar
        print(f"🔍 Encontradas {len(visitas)} visitas completas PAE")
        for visita in visitas:
            print(f"   - Visita ID: {visita.id}, Estado: {visita.estado}, Profesional: {visita.profesional.nombre if visita.profesional else 'N/A'}, Contrato: {visita.contrato}, Operador: {visita.operador}")
        
        return visitas
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error al listar visitas completas: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al listar visitas completas: {str(e)}"
        )

@router.get("/visitas-completas-pae/filtros")
def obtener_opciones_filtros(
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user)
):
    """
    Obtiene las opciones disponibles para los filtros de visitas completas PAE del usuario actual
    """
    try:
        # Obtener contratos únicos del usuario actual
        contratos = db.query(models.VisitaCompletaPAE.contrato).filter(
            models.VisitaCompletaPAE.profesional_id == current_user.id,
            models.VisitaCompletaPAE.contrato.isnot(None),
            models.VisitaCompletaPAE.contrato != ""
        ).distinct().all()
        
        # Obtener operadores únicos del usuario actual
        operadores = db.query(models.VisitaCompletaPAE.operador).filter(
            models.VisitaCompletaPAE.profesional_id == current_user.id,
            models.VisitaCompletaPAE.operador.isnot(None),
            models.VisitaCompletaPAE.operador != ""
        ).distinct().all()
        
        # Obtener estados únicos del usuario actual
        estados = db.query(models.VisitaCompletaPAE.estado).filter(
            models.VisitaCompletaPAE.profesional_id == current_user.id
        ).distinct().all()
        
        return {
            "contratos": [c[0] for c in contratos if c[0]],
            "operadores": [o[0] for o in operadores if o[0]],
            "estados": [e[0] for e in estados if e[0]]
        }
    except Exception as e:
        print(f"❌ Error al obtener opciones de filtros: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al obtener opciones de filtros: {str(e)}"
        )

@router.get("/visitas-completas-pae/pendientes", response_model=List[schemas.VisitaCompletaPAEOut])
def listar_visitas_pendientes(
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user)
):
    """
    Lista solo las visitas pendientes PAE
    """
    try:
        # Obtener solo las visitas pendientes con relaciones cargadas
        visitas = db.query(models.VisitaCompletaPAE).filter(
            models.VisitaCompletaPAE.estado == "pendiente"
        ).options(
            joinedload(models.VisitaCompletaPAE.municipio),
            joinedload(models.VisitaCompletaPAE.institucion),
            joinedload(models.VisitaCompletaPAE.sede),
            joinedload(models.VisitaCompletaPAE.profesional),
            joinedload(models.VisitaCompletaPAE.respuestas_checklist)
        ).all()
        
        # El schema ahora acepta None, no necesitamos normalizar
        print(f"🔍 Encontradas {len(visitas)} visitas pendientes PAE")
        for visita in visitas:
            print(f"   - Visita ID: {visita.id}, Estado: {visita.estado}, Profesional: {visita.profesional.nombre if visita.profesional else 'N/A'}")
        
        return visitas
    except Exception as e:
        print(f"❌ Error al listar visitas pendientes: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al listar visitas pendientes: {str(e)}"
        )

@router.get("/visitas-completas-pae/{visita_id}", response_model=schemas.VisitaCompletaPAEOut)
def obtener_visita_completa_pae(
    visita_id: int,
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user)
):
    """
    Obtiene una visita completa PAE específica
    """
    visita = db.query(models.VisitaCompletaPAE).filter(
        models.VisitaCompletaPAE.id == visita_id
    ).first()
    
    if not visita:
        raise HTTPException(status_code=404, detail="Visita no encontrada")
    
    # El schema ahora acepta None, no necesitamos normalizar
    return visita

@router.get("/visitas-completas-pae/{visita_id}/excel")
def generar_excel_visita_completa(
    visita_id: int,
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user)
):

    """
    Genera un archivo Excel basado en la plantilla personalizada con toda la información de una visita completa PAE
    """
    # Obtener la visita completa con todas las relaciones
    visita = db.query(models.VisitaCompletaPAE).filter(
        models.VisitaCompletaPAE.id == visita_id
    ).first()
    
    if not visita:
        raise HTTPException(status_code=404, detail="Visita no encontrada")
    
    # Obtener las respuestas del checklist
    respuestas = db.query(models.VisitaRespuestaCompleta).filter(
        models.VisitaRespuestaCompleta.visita_id == visita_id
    ).all()
    
    try:
        # Cargar la plantilla Excel
        plantilla_path = os.path.join("app", "templates", "plantilla_historial_visitas_checklist.xlsx")
        if not os.path.exists(plantilla_path):
            raise HTTPException(
                status_code=500,
                detail="Plantilla Excel no encontrada. Contacte al administrador."
            )
        
        # Cargar el workbook de la plantilla
        workbook = load_workbook(plantilla_path)
        
        # Obtener la hoja principal (asumiendo que es la primera)
        worksheet = workbook.active
        
        # Llenar la información de la visita en la plantilla
        # Según el análisis, la plantilla tiene encabezados en la fila 1
        # Vamos a llenar los datos de la visita en la fila 2
        
        # Información de la visita (fila 2)
        worksheet['A2'] = visita.id
        worksheet['B2'] = visita.fecha_visita.strftime('%Y-%m-%d %H:%M') if visita.fecha_visita else 'N/A'
        worksheet['C2'] = visita.contrato or 'N/A'
        worksheet['D2'] = visita.operador or 'N/A'
        worksheet['E2'] = visita.caso_atencion_prioritaria or 'N/A'
        worksheet['F2'] = visita.municipio.nombre if visita.municipio else 'N/A'
        worksheet['G2'] = visita.institucion.nombre if visita.institucion else 'N/A'
        worksheet['H2'] = visita.sede.nombre if visita.sede else 'N/A'
        worksheet['I2'] = visita.profesional.nombre if visita.profesional else 'N/A'
        
        # Llenar las respuestas del checklist
        # Comenzar desde la fila 3 (después de los encabezados)
        fila_actual = 3
        for respuesta in respuestas:
            item = db.query(models.ChecklistItem).filter(
                models.ChecklistItem.id == respuesta.item_id
            ).first()
            
            if item:
                categoria = db.query(models.ChecklistCategoria).filter(
                    models.ChecklistCategoria.id == item.categoria_id
                ).first()
                
                # Llenar fila del checklist según la estructura de la plantilla
                worksheet[f'A{fila_actual}'] = visita.id  # Nº Visita
                worksheet[f'B{fila_actual}'] = visita.fecha_visita.strftime('%Y-%m-%d %H:%M') if visita.fecha_visita else 'N/A'  # Fecha Visita
                worksheet[f'C{fila_actual}'] = visita.contrato or 'N/A'  # Contrato
                worksheet[f'D{fila_actual}'] = visita.operador or 'N/A'  # Operador
                worksheet[f'E{fila_actual}'] = visita.caso_atencion_prioritaria or 'N/A'  # Caso Prioritario
                worksheet[f'F{fila_actual}'] = visita.municipio.nombre if visita.municipio else 'N/A'  # Municipio
                worksheet[f'G{fila_actual}'] = visita.institucion.nombre if visita.institucion else 'N/A'  # Institución
                worksheet[f'H{fila_actual}'] = visita.sede.nombre if visita.sede else 'N/A'  # Sede
                worksheet[f'I{fila_actual}'] = visita.profesional.nombre if visita.profesional else 'N/A'  # Profesional
                worksheet[f'J{fila_actual}'] = item.id  # Nº Ítem
                worksheet[f'K{fila_actual}'] = item.pregunta_texto  # Pregunta / Descripción
                worksheet[f'L{fila_actual}'] = respuesta.respuesta  # Respuesta
                worksheet[f'M{fila_actual}'] = respuesta.observacion or 'N/A'  # Observaciones
                worksheet[f'N{fila_actual}'] = 'N/A'  # Evidencia (por ahora N/A)
                
                fila_actual += 1
        
        # Guardar el archivo modificado en memoria
        output = BytesIO()
        workbook.save(output)
        output.seek(0)
        
        return StreamingResponse(
            output,
            media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            headers={"Content-Disposition": f"attachment; filename=historial_visita_{visita_id}.xlsx"}
        )
        
    except Exception as e:
        print(f"❌ Error al generar Excel con plantilla: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al generar Excel: {str(e)}"
        )

@router.put("/visitas-completas-pae/{visita_id}/estado")
def actualizar_estado_visita(
    visita_id: int,
    estado: str,
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user)
):
    """
    Actualiza el estado de una visita (pendiente -> completada)
    """
    try:
        # Buscar la visita
        visita = db.query(models.VisitaCompletaPAE).filter(
            models.VisitaCompletaPAE.id == visita_id
        ).first()
        
        if not visita:
            raise HTTPException(status_code=404, detail="Visita no encontrada")
        
        # Validar que el estado sea válido
        estados_validos = ["pendiente", "completada", "cancelada"]
        if estado not in estados_validos:
            raise HTTPException(
                status_code=400, 
                detail=f"Estado inválido. Estados válidos: {estados_validos}"
            )
        
        # Actualizar el estado
        visita.estado = estado
        
        # 🔄 SINCRONIZACIÓN AUTOMÁTICA: Actualizar visita asignada correspondiente
        visita_asignada = db.query(models.VisitaAsignada).filter(
            models.VisitaAsignada.sede_id == visita.sede_id,
            models.VisitaAsignada.visitador_id == visita.profesional_id,
            models.VisitaAsignada.contrato == visita.contrato
        ).first()
        
        if visita_asignada:
            print(f"🔄 Sincronizando visita asignada {visita_asignada.id} con estado: {estado}")
            visita_asignada.estado = estado
            if estado == "completada" and visita_asignada.fecha_completada is None:
                visita_asignada.fecha_completada = datetime.utcnow()
        else:
            print(f"⚠️ No se encontró visita asignada correspondiente para sincronizar")
        
        db.commit()
        
        print(f"✅ Visita {visita_id} actualizada a estado: {estado}")
        
        return {
            "mensaje": f"Visita {visita_id} actualizada a estado: {estado}",
            "visita_id": visita_id,
            "estado": estado
        }
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error al actualizar estado de la visita: {str(e)}"
        ) 

@router.get("/casos-atencion-prioritaria")
def obtener_casos_atencion_prioritaria():
    """
    Obtiene la lista de casos de atención prioritaria disponibles
    """
    casos = [
        {"id": "SI", "nombre": "SI"},
        {"id": "NO", "nombre": "NO"},
        {"id": "NO HUBO SERVICIO", "nombre": "NO HUBO SERVICIO"},
        {"id": "ACTA RAPIDA", "nombre": "ACTA RAPIDA"},
    ]
    return casos


@router.post("/test-sincronizacion")
def test_sincronizacion(
    db: Session = Depends(get_db)
):
    """
    Endpoint de prueba para sincronización (sin autenticación)
    """
    try:
        print(f"🔄 TEST SINCRONIZACIÓN para usuario 9")
        
        # 1. Sincronizar visitas en proceso
        visitas_en_proceso = db.query(models.VisitaAsignada).filter(
            models.VisitaAsignada.visitador_id == 9,
            models.VisitaAsignada.estado == "en_proceso"
        ).all()
        
        print(f"📋 Encontradas {len(visitas_en_proceso)} visitas en proceso")
        
        visitas_sincronizadas = 0
        
        for visita_asignada in visitas_en_proceso:
            print(f"🔍 Verificando visita asignada ID {visita_asignada.id} - Contrato: {visita_asignada.contrato}")
            
            # Buscar visita completa correspondiente
            visita_completa = db.query(models.VisitaCompletaPAE).filter(
                models.VisitaCompletaPAE.sede_id == visita_asignada.sede_id,
                models.VisitaCompletaPAE.profesional_id == visita_asignada.visitador_id,
                models.VisitaCompletaPAE.contrato == visita_asignada.contrato
            ).first()
            
            if visita_completa:
                print(f"✅ Encontrada visita completa ID {visita_completa.id} - Estado: {visita_completa.estado}")
                
                # Si la visita completa está completada, actualizar la asignada
                if visita_completa.estado == "completada":
                    visita_asignada.estado = "completada"
                    if visita_asignada.fecha_completada is None:
                        visita_asignada.fecha_completada = datetime.utcnow()
                    visitas_sincronizadas += 1
                    print(f"🔄 Actualizando visita asignada ID {visita_asignada.id} a 'completada'")
                else:
                    print(f"⚠️ Visita completa no está completada, estado: {visita_completa.estado}")
            else:
                print(f"❌ No se encontró visita completa para contrato {visita_asignada.contrato}")
        
        # 2. Sincronizar visitas completas pendientes
        visitas_completas_pendientes = db.query(models.VisitaCompletaPAE).filter(
            models.VisitaCompletaPAE.profesional_id == 9,
            models.VisitaCompletaPAE.estado == "pendiente"
        ).all()
        
        print(f"📋 Encontradas {len(visitas_completas_pendientes)} visitas completas pendientes")
        
        for visita_completa in visitas_completas_pendientes:
            print(f"🔍 Verificando visita completa ID {visita_completa.id} - Contrato: {visita_completa.contrato}")
            
            # Buscar visita asignada correspondiente
            visita_asignada = db.query(models.VisitaAsignada).filter(
                models.VisitaAsignada.sede_id == visita_completa.sede_id,
                models.VisitaAsignada.visitador_id == visita_completa.profesional_id,
                models.VisitaAsignada.contrato == visita_completa.contrato
            ).first()
            
            if visita_asignada:
                print(f"✅ Encontrada visita asignada ID {visita_asignada.id} - Estado: {visita_asignada.estado}")
                
                # Si la visita asignada está completada, actualizar la completa
                if visita_asignada.estado == "completada":
                    visita_completa.estado = "completada"
                    visitas_sincronizadas += 1
                    print(f"🔄 Actualizando visita completa ID {visita_completa.id} a 'completada'")
                else:
                    print(f"⚠️ Visita asignada no está completada, estado: {visita_asignada.estado}")
            else:
                print(f"❌ No se encontró visita asignada para contrato {visita_completa.contrato}")
        
        db.commit()
        
        print(f"✅ TEST SINCRONIZACIÓN: {visitas_sincronizadas} visitas sincronizadas")
        
        return {
            "mensaje": f"Test de sincronización completado. {visitas_sincronizadas} visitas sincronizadas.",
            "visitas_sincronizadas": visitas_sincronizadas
        }
        
    except Exception as e:
        db.rollback()
        print(f"❌ Error en test sincronización: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error en test sincronización: {str(e)}"
        )

@router.post("/sincronizar-todas-las-visitas")
def sincronizar_todas_las_visitas(
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user)
):
    """
    Sincroniza TODAS las visitas del usuario actual.
    Útil para forzar la sincronización después de crear cronogramas.
    """
    try:
        print(f"🔄 SINCRONIZACIÓN COMPLETA para usuario {current_user.id}")
        
        # 1. Sincronizar visitas en proceso
        visitas_en_proceso = db.query(models.VisitaAsignada).filter(
            models.VisitaAsignada.visitador_id == current_user.id,
            models.VisitaAsignada.estado == "en_proceso"
        ).all()
        
        print(f"📋 Encontradas {len(visitas_en_proceso)} visitas en proceso")
        
        visitas_sincronizadas = 0
        
        for visita_asignada in visitas_en_proceso:
            print(f"🔍 Verificando visita asignada ID {visita_asignada.id} - Contrato: {visita_asignada.contrato}")
            
            # Buscar visita completa correspondiente
            visita_completa = db.query(models.VisitaCompletaPAE).filter(
                models.VisitaCompletaPAE.sede_id == visita_asignada.sede_id,
                models.VisitaCompletaPAE.profesional_id == visita_asignada.visitador_id,
                models.VisitaCompletaPAE.contrato == visita_asignada.contrato
            ).first()
            
            if visita_completa:
                print(f"✅ Encontrada visita completa ID {visita_completa.id} - Estado: {visita_completa.estado}")
                
                # Si la visita completa está completada, actualizar la asignada
                if visita_completa.estado == "completada":
                    visita_asignada.estado = "completada"
                    if visita_asignada.fecha_completada is None:
                        visita_asignada.fecha_completada = datetime.utcnow()
                    visitas_sincronizadas += 1
                    print(f"🔄 Actualizando visita asignada ID {visita_asignada.id} a 'completada'")
                else:
                    print(f"⚠️ Visita completa no está completada, estado: {visita_completa.estado}")
            else:
                print(f"❌ No se encontró visita completa para contrato {visita_asignada.contrato}")
        
        # 2. Sincronizar visitas completas pendientes
        visitas_completas_pendientes = db.query(models.VisitaCompletaPAE).filter(
            models.VisitaCompletaPAE.profesional_id == current_user.id,
            models.VisitaCompletaPAE.estado == "pendiente"
        ).all()
        
        print(f"📋 Encontradas {len(visitas_completas_pendientes)} visitas completas pendientes")
        
        for visita_completa in visitas_completas_pendientes:
            print(f"🔍 Verificando visita completa ID {visita_completa.id} - Contrato: {visita_completa.contrato}")
            
            # Buscar visita asignada correspondiente
            visita_asignada = db.query(models.VisitaAsignada).filter(
                models.VisitaAsignada.sede_id == visita_completa.sede_id,
                models.VisitaAsignada.visitador_id == visita_completa.profesional_id,
                models.VisitaAsignada.contrato == visita_completa.contrato
            ).first()
            
            if visita_asignada:
                print(f"✅ Encontrada visita asignada ID {visita_asignada.id} - Estado: {visita_asignada.estado}")
                
                # Si la visita asignada está completada, actualizar la completa
                if visita_asignada.estado == "completada":
                    visita_completa.estado = "completada"
                    visitas_sincronizadas += 1
                    print(f"🔄 Actualizando visita completa ID {visita_completa.id} a 'completada'")
                else:
                    print(f"⚠️ Visita asignada no está completada, estado: {visita_asignada.estado}")
            else:
                print(f"❌ No se encontró visita asignada para contrato {visita_completa.contrato}")
        
        db.commit()
        
        print(f"✅ SINCRONIZACIÓN COMPLETA: {visitas_sincronizadas} visitas sincronizadas")
        
        return {
            "mensaje": f"Sincronización completa realizada. {visitas_sincronizadas} visitas sincronizadas.",
            "visitas_sincronizadas": visitas_sincronizadas
        }
        
    except Exception as e:
        db.rollback()
        print(f"❌ Error en sincronización completa: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error en sincronización completa: {str(e)}"
        )

@router.post("/sincronizar-visitas-en-proceso")
def sincronizar_visitas_en_proceso(
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user)
):
    """
    Sincroniza visitas asignadas en proceso con visitas completas pendientes.
    Útil cuando se completa un cronograma pero no se actualiza automáticamente.
    """
    try:
        print(f"🔄 SINCRONIZANDO VISITAS EN PROCESO para usuario {current_user.id}")
        
        # Buscar visitas asignadas en proceso
        visitas_en_proceso = db.query(models.VisitaAsignada).filter(
            models.VisitaAsignada.visitador_id == current_user.id,
            models.VisitaAsignada.estado == "en_proceso"
        ).all()
        
        print(f"📋 Encontradas {len(visitas_en_proceso)} visitas en proceso")
        
        visitas_sincronizadas = 0
        
        for visita_asignada in visitas_en_proceso:
            print(f"🔍 Verificando visita asignada ID {visita_asignada.id} - Contrato: {visita_asignada.contrato}")
            
            # Buscar visita completa correspondiente
            visita_completa = db.query(models.VisitaCompletaPAE).filter(
                models.VisitaCompletaPAE.sede_id == visita_asignada.sede_id,
                models.VisitaCompletaPAE.profesional_id == visita_asignada.visitador_id,
                models.VisitaCompletaPAE.contrato == visita_asignada.contrato
            ).first()
            
            if visita_completa:
                print(f"✅ Encontrada visita completa ID {visita_completa.id} - Estado: {visita_completa.estado}")
                
                # Si la visita completa está completada, actualizar la asignada
                if visita_completa.estado == "completada":
                    visita_asignada.estado = "completada"
                    if visita_asignada.fecha_completada is None:
                        visita_asignada.fecha_completada = datetime.utcnow()
                    visitas_sincronizadas += 1
                    print(f"🔄 Actualizando visita asignada ID {visita_asignada.id} a 'completada'")
                else:
                    print(f"⚠️ Visita completa no está completada, estado: {visita_completa.estado}")
            else:
                print(f"❌ No se encontró visita completa para contrato {visita_asignada.contrato}")
        
        db.commit()
        
        print(f"✅ SINCRONIZACIÓN COMPLETADA: {visitas_sincronizadas} visitas en proceso actualizadas")
        
        return {
            "mensaje": f"Sincronización completada. {visitas_sincronizadas} visitas en proceso actualizadas.",
            "visitas_sincronizadas": visitas_sincronizadas
        }
        
    except Exception as e:
        db.rollback()
        print(f"❌ Error en sincronización: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error en sincronización: {str(e)}"
        )

@router.post("/sincronizar-visitas-programadas")
def sincronizar_visitas_programadas(
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user)
):
    """
    Sincroniza el estado de las visitas programadas con las visitas completas PAE
    """
    try:
        print("🔄 INICIANDO SINCRONIZACIÓN DE VISITAS PROGRAMADAS...")
        
        # NOTA: VisitaProgramada no tiene campos visitador_id, estado, ni contrato
        # Esta lógica se eliminó porque el modelo VisitaProgramada no tiene estos campos
        visitas_programadas = []
        
        print(f"📅 Encontradas {len(visitas_programadas)} visitas programadas para sincronizar")
        
        visitas_actualizadas = 0
        
        # NOTA: La lógica de sincronización se eliminó porque VisitaProgramada no tiene los campos necesarios
        
        db.commit()
        
        print(f"✅ SINCRONIZACIÓN COMPLETADA: {visitas_actualizadas} visitas programadas actualizadas")
        
        return {
            "mensaje": f"Sincronización completada. {visitas_actualizadas} visitas programadas actualizadas.",
            "visitas_actualizadas": visitas_actualizadas
        }
        
    except Exception as e:
        db.rollback()
        print(f"❌ Error en sincronización: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al sincronizar visitas programadas: {str(e)}"
        )

@router.post("/actualizar-visita-programada/{visita_id}")
def actualizar_visita_programada_manual(
    visita_id: int,
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user)
):
    """
    Actualiza manualmente el estado de una visita programada específica
    """
    try:
        print(f"🔄 ACTUALIZANDO MANUALMENTE VISITA PROGRAMADA ID {visita_id}...")
        
        # NOTA: VisitaProgramada no tiene campos visitador_id ni estado
        # Esta funcionalidad se deshabilitó porque el modelo no tiene estos campos
        raise HTTPException(status_code=501, detail="Funcionalidad no implementada: VisitaProgramada no tiene campos visitador_id ni estado")
        
    except Exception as e:
        db.rollback()
        print(f"❌ Error al actualizar visita programada: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al actualizar visita programada: {str(e)}"
        ) 