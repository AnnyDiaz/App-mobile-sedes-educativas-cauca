from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional
from datetime import datetime, timedelta
from app.database import get_db
from app import models
from app.routes.auth import obtener_usuario_actual
from pydantic import BaseModel
from fastapi.responses import StreamingResponse
from io import BytesIO
import pandas as pd
from openpyxl import load_workbook

router = APIRouter(prefix="", tags=["Reportes"])

class ReporteRequest(BaseModel):
    tipo_reporte: str  # "excel", "csv"
    fecha_inicio: Optional[str] = None
    fecha_fin: Optional[str] = None
    municipio_id: Optional[int] = None
    institucion_id: Optional[int] = None
    estado: Optional[str] = None  # "pendiente", "completada", "cancelada"

@router.post("/generar")
def generar_reporte(
    request: ReporteRequest,
    db: Session = Depends(get_db),
    usuario: models.Usuario = Depends(obtener_usuario_actual)
):
    """Genera reportes de visitas según los parámetros especificados"""
    
    try:
        # Verificar permisos (solo supervisores y admins pueden generar reportes)
        if usuario.rol.nombre not in ['supervisor', 'admin']:
            raise HTTPException(
                status_code=403,
                detail="No tienes permisos para generar reportes"
            )
        
        # Construir la consulta base
        query = db.query(models.VisitaCompletaPAE).options(
            joinedload(models.VisitaCompletaPAE.municipio),
            joinedload(models.VisitaCompletaPAE.institucion),
            joinedload(models.VisitaCompletaPAE.sede),
            joinedload(models.VisitaCompletaPAE.profesional)
        )
        
        # Aplicar filtros (solo si se proporcionan)
        print(f"🔍 Filtros recibidos:")
        print(f"   - fecha_inicio: {request.fecha_inicio}")
        print(f"   - fecha_fin: {request.fecha_fin}")
        print(f"   - municipio_id: {request.municipio_id}")
        print(f"   - institucion_id: {request.institucion_id}")
        print(f"   - estado: {request.estado}")
        
        if request.fecha_inicio:
            try:
                fecha_inicio = datetime.fromisoformat(request.fecha_inicio.replace('Z', '+00:00'))
                query = query.filter(models.VisitaCompletaPAE.fecha_creacion >= fecha_inicio)
                print(f"✅ Filtro fecha_inicio aplicado: {fecha_inicio}")
            except Exception as e:
                print(f"⚠️ Error en fecha_inicio, ignorando filtro: {e}")
        
        if request.fecha_fin:
            try:
                fecha_fin = datetime.fromisoformat(request.fecha_fin.replace('Z', '+00:00'))
                query = query.filter(models.VisitaCompletaPAE.fecha_creacion <= fecha_fin)
                print(f"✅ Filtro fecha_fin aplicado: {fecha_fin}")
            except Exception as e:
                print(f"⚠️ Error en fecha_fin, ignorando filtro: {e}")
        
        if request.municipio_id:
            query = query.filter(models.VisitaCompletaPAE.municipio_id == request.municipio_id)
        
        if request.institucion_id:
            query = query.filter(models.VisitaCompletaPAE.institucion_id == request.institucion_id)
        
        if request.estado:
            query = query.filter(models.VisitaCompletaPAE.estado == request.estado)
        
        # Ejecutar la consulta
        visitas = query.order_by(models.VisitaCompletaPAE.fecha_creacion.desc()).all()
        
        print(f"📊 Generando reporte {request.tipo_reporte} para usuario {usuario.nombre}")
        print(f"   - Filtros aplicados: {request.dict()}")
        print(f"   - Visitas encontradas: {len(visitas)}")
        
        # Preparar datos para el reporte
        datos_reporte = []
        for visita in visitas:
            datos_reporte.append({
                "id": visita.id,
                "fecha_visita": visita.fecha_visita.isoformat() if visita.fecha_visita else None,
                "fecha_creacion": visita.fecha_creacion.isoformat() if visita.fecha_creacion else None,
                "contrato": visita.contrato,
                "operador": visita.operador,
                "caso_atencion_prioritaria": visita.caso_atencion_prioritaria,
                "estado": visita.estado,
                "observaciones": visita.observaciones,
                "municipio": visita.municipio.nombre if visita.municipio else "N/A",
                "institucion": visita.institucion.nombre if visita.institucion else "N/A",
                "sede": visita.sede.nombre if visita.sede else "N/A",
                "profesional": visita.profesional.nombre if visita.profesional else "N/A",
            })
        
        # 🔥 GENERAR ARCHIVOS REALES
        if request.tipo_reporte == "excel":
            # Generar Excel real
            df = pd.DataFrame(datos_reporte)
            
            # Crear archivo Excel en memoria
            output = BytesIO()
            with pd.ExcelWriter(output, engine='openpyxl') as writer:
                df.to_excel(writer, sheet_name='Visitas', index=False)
            
            output.seek(0)
            
            # Preparar nombre del archivo
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"reporte_visitas_{timestamp}.xlsx"
            
            print(f"✅ Excel generado: {filename} con {len(datos_reporte)} visitas")
            
            # Retornar archivo Excel
            return StreamingResponse(
                BytesIO(output.read()),
                media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                headers={"Content-Disposition": f"attachment; filename={filename}"}
            )
            
        elif request.tipo_reporte == "csv":
            # Generar CSV real
            df = pd.DataFrame(datos_reporte)
            output = BytesIO()
            df.to_csv(output, index=False, encoding='utf-8')
            output.seek(0)
            
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"reporte_visitas_{timestamp}.csv"
            
            print(f"✅ CSV generado: {filename} con {len(datos_reporte)} visitas")
            
            return StreamingResponse(
                BytesIO(output.read()),
                media_type="text/csv",
                headers={"Content-Disposition": f"attachment; filename={filename}"}
            )
            
        else:
            raise HTTPException(
                status_code=400,
                detail="Tipo de reporte no válido. Use 'excel' o 'csv'"
            )
        
    except HTTPException:
        # Re-lanzar las excepciones HTTP que ya fueron creadas
        raise
    except Exception as e:
        print(f"❌ Error al generar reporte: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error interno al generar el reporte: {str(e)}"
        ) 