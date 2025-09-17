#!/usr/bin/env python3
"""
Script para consultar los datos guardados del checklist en la base de datos
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import SessionLocal
from app.models import CronogramaVisitaPAE, VisitaRespuesta, ChecklistItem, ChecklistCategoria
from sqlalchemy.orm import joinedload

def consultar_ultimo_cronograma():
    """Consulta el último cronograma creado y sus respuestas"""
    db = SessionLocal()
    try:
        # Obtener el último cronograma
        ultimo_cronograma = db.query(CronogramaVisitaPAE).order_by(CronogramaVisitaPAE.id.desc()).first()
        
        if not ultimo_cronograma:
            print("❌ No hay cronogramas en la base de datos")
            return
        
        print(f"📊 ÚLTIMO CRONOGRAMA CREADO:")
        print(f"   ID: {ultimo_cronograma.id}")
        print(f"   Fecha Visita: {ultimo_cronograma.fecha_visita}")
        print(f"   Contrato: {ultimo_cronograma.contrato}")
        print(f"   Operador: {ultimo_cronograma.operador}")
        print(f"   Caso Atención Prioritaria: {ultimo_cronograma.caso_atencion_prioritaria}")
        print(f"   Municipio ID: {ultimo_cronograma.municipio_id}")
        print(f"   Institución ID: {ultimo_cronograma.institucion_id}")
        print(f"   Sede ID: {ultimo_cronograma.sede_id}")
        print(f"   Profesional ID: {ultimo_cronograma.profesional_id}")
        
        # Buscar la visita asociada
        from app.models import Visita
        visita = db.query(Visita).filter(Visita.sede_id == ultimo_cronograma.sede_id).order_by(Visita.id.desc()).first()
        
        if visita:
            print(f"\n📋 VISITA ASOCIADA:")
            print(f"   ID: {visita.id}")
            print(f"   Estado: {visita.estado}")
            print(f"   Fecha Creación: {visita.fecha_creacion}")
            
            # Obtener las respuestas del checklist para esta visita
            respuestas = db.query(VisitaRespuesta).filter(VisitaRespuesta.visita_id == visita.id).all()
            
            if respuestas:
                print(f"\n✅ RESPUESTAS DEL CHECKLIST GUARDADAS:")
                print(f"   Total respuestas: {len(respuestas)}")
                
                for i, respuesta in enumerate(respuestas, 1):
                    # Obtener el item del checklist
                    item = db.query(ChecklistItem).filter(ChecklistItem.id == respuesta.item_id).first()
                    categoria = db.query(ChecklistCategoria).filter(ChecklistCategoria.id == item.categoria_id).first()
                    
                    print(f"\n   {i}. Respuesta #{respuesta.id}:")
                    print(f"      Categoría: {categoria.nombre}")
                    print(f"      Pregunta: {item.pregunta_texto}")
                    print(f"      Respuesta: {respuesta.respuesta}")
                    if respuesta.observacion:
                        print(f"      Observación: {respuesta.observacion}")
            else:
                print(f"\n⚠️ No se encontraron respuestas del checklist para la visita {visita.id}")
        else:
            print(f"\n⚠️ No se encontró visita asociada al cronograma")
            
    except Exception as e:
        print(f"❌ Error al consultar datos: {e}")
    finally:
        db.close()

def consultar_todas_las_respuestas():
    """Consulta todas las respuestas del checklist en la base de datos"""
    db = SessionLocal()
    try:
        respuestas = db.query(VisitaRespuesta).all()
        
        print(f"\n📊 ESTADÍSTICAS GENERALES:")
        print(f"   Total respuestas guardadas: {len(respuestas)}")
        
        if respuestas:
            # Agrupar por visita
            visitas_con_respuestas = {}
            for respuesta in respuestas:
                if respuesta.visita_id not in visitas_con_respuestas:
                    visitas_con_respuestas[respuesta.visita_id] = []
                visitas_con_respuestas[respuesta.visita_id].append(respuesta)
            
            print(f"   Visitas con respuestas: {len(visitas_con_respuestas)}")
            
            for visita_id, respuestas_visita in visitas_con_respuestas.items():
                print(f"\n   📋 Visita #{visita_id}: {len(respuestas_visita)} respuestas")
                
    except Exception as e:
        print(f"❌ Error al consultar estadísticas: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    print("🔍 CONSULTANDO DATOS GUARDADOS DEL CHECKLIST...")
    consultar_ultimo_cronograma()
    consultar_todas_las_respuestas()
    print("\n✅ Consulta completada!") 