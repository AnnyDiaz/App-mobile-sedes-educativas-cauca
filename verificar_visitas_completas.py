#!/usr/bin/env python3
"""
Script para verificar las visitas completas PAE en la base de datos
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import engine
from sqlalchemy import text

def verificar_visitas_completas():
    """Verifica las visitas completas PAE en la base de datos"""
    try:
        with engine.connect() as conn:
            # Contar total de visitas
            result = conn.execute(text("""
                SELECT COUNT(*) as total
                FROM visitas_completas_pae;
            """))
            total = result.scalar()
            print(f"📊 Total de visitas completas PAE: {total}")
            
            # Mostrar todas las visitas con detalles
            result = conn.execute(text("""
                SELECT 
                    vcp.id,
                    vcp.fecha_visita,
                    vcp.contrato,
                    vcp.operador,
                    vcp.caso_atencion_prioritaria,
                    vcp.estado,
                    vcp.fecha_creacion,
                    u.nombre as profesional,
                    m.nombre as municipio,
                    i.nombre as institucion,
                    se.nombre_sede as sede
                FROM visitas_completas_pae vcp
                LEFT JOIN usuarios u ON vcp.profesional_id = u.id
                LEFT JOIN municipios m ON vcp.municipio_id = m.id
                LEFT JOIN instituciones i ON vcp.institucion_id = i.id
                LEFT JOIN sedes_educativas se ON vcp.sede_id = se.id
                ORDER BY vcp.fecha_creacion DESC;
            """))
            
            visitas = result.fetchall()
            print(f"\n📋 DETALLES DE LAS VISITAS:")
            print("=" * 80)
            for visita in visitas:
                print(f"ID: {visita[0]}")
                print(f"  Fecha Visita: {visita[1]}")
                print(f"  Contrato: {visita[2]}")
                print(f"  Operador: {visita[3]}")
                print(f"  Caso Prioritaria: {visita[4]}")
                print(f"  Estado: {visita[5]}")
                print(f"  Fecha Creación: {visita[6]}")
                print(f"  Profesional: {visita[7]}")
                print(f"  Municipio: {visita[8]}")
                print(f"  Institución: {visita[9]}")
                print(f"  Sede: {visita[10]}")
                print("-" * 40)
            
            # Contar respuestas del checklist
            result = conn.execute(text("""
                SELECT COUNT(*) as total_respuestas
                FROM visita_respuestas_completas;
            """))
            total_respuestas = result.scalar()
            print(f"\n📊 Total de respuestas del checklist: {total_respuestas}")
            
            # Mostrar respuestas por visita
            result = conn.execute(text("""
                SELECT 
                    vrc.visita_completa_id,
                    COUNT(*) as num_respuestas
                FROM visita_respuestas_completas vrc
                GROUP BY vrc.visita_completa_id
                ORDER BY vrc.visita_completa_id;
            """))
            
            respuestas_por_visita = result.fetchall()
            print(f"\n📋 RESPUESTAS POR VISITA:")
            for visita_id, num_respuestas in respuestas_por_visita:
                print(f"  Visita {visita_id}: {num_respuestas} respuestas")
                
    except Exception as e:
        print(f"❌ Error al verificar visitas: {e}")

if __name__ == "__main__":
    print("🔍 VERIFICANDO VISITAS COMPLETAS PAE")
    print("=" * 50)
    verificar_visitas_completas() 