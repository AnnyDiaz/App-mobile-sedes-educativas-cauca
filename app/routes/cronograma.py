from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app import models, schemas
from app.database import get_db

router = APIRouter()

@router.post("/cronogramas_pae", status_code=201)
def crear_cronograma_pae(datos: schemas.CronogramaPAECrear, db: Session = Depends(get_db)):
<<<<<<< HEAD
    # Crear cronograma base
    cronograma = models.CronogramaVisitaPAE(
        fecha_visita=datos.fecha_visita,
        contrato=datos.contrato,
        operador=datos.operador,
        municipio_id=datos.municipio_id,
        institucion_id=datos.institucion_id,
        sede_id=datos.sede_id,
        profesional_id=datos.profesional_id
    )
    db.add(cronograma)
    db.commit()
    db.refresh(cronograma)

    # Registrar ítems de evaluación
    for item in datos.evaluaciones:
        evaluacion = models.EvaluacionPAE(
            cronograma_id=cronograma.id,
            item=item.item,
            valor=item.valor
        )
        db.add(evaluacion)

    db.commit()
    return {"mensaje": "Cronograma y evaluación registrados correctamente", "cronograma_id": cronograma.id}
=======
    try:
        # Validar que el usuario existe
        usuario = db.query(models.Usuario).filter(models.Usuario.id == datos.profesional_id).first()
        if not usuario:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"El usuario con ID {datos.profesional_id} no existe. Usuarios disponibles: 2, 3, 4, 5, 6, 7, 8"
            )
        
        # Validar que el municipio existe
        municipio = db.query(models.Municipio).filter(models.Municipio.id == datos.municipio_id).first()
        if not municipio:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"El municipio con ID {datos.municipio_id} no existe. Municipios disponibles: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10..."
            )
        
        # Validar que la institución existe
        institucion = db.query(models.Institucion).filter(models.Institucion.id == datos.institucion_id).first()
        if not institucion:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"La institución con ID {datos.institucion_id} no existe"
            )
        
        # Validar que la sede existe
        sede = db.query(models.SedeEducativa).filter(models.SedeEducativa.id == datos.sede_id).first()
        if not sede:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"La sede con ID {datos.sede_id} no existe"
            )
        
        # Crear cronograma base
        cronograma = models.CronogramaVisitaPAE(
            fecha_visita=datos.fecha_visita,
            contrato=datos.contrato,
            operador=datos.operador,
            caso_atencion_prioritaria=datos.caso_atencion_prioritaria,
            municipio_id=datos.municipio_id,
            institucion_id=datos.institucion_id,
            sede_id=datos.sede_id,
            profesional_id=datos.profesional_id
        )
        db.add(cronograma)
        db.flush()  # Esto hace que el ID esté disponible sin hacer commit

        # Registrar ítems de evaluación (si existen)
        if datos.evaluaciones:
            for item in datos.evaluaciones:
                evaluacion = models.EvaluacionPAE(
                    cronograma_id=cronograma.id,
                    item=item.item,
                    valor=item.valor
                )
                db.add(evaluacion)

        db.commit()  # Un solo commit al final
        return {"mensaje": "Cronograma y evaluación registrados correctamente", "cronograma_id": cronograma.id}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error interno del servidor: {str(e)}"
        )
>>>>>>> frontend
