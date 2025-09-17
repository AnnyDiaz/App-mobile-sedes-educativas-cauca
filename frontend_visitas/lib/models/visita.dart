// lib/models/visita.dart

import 'package:frontend_visitas/models/sede.dart';
import 'package:frontend_visitas/models/usuario.dart';
import 'package:frontend_visitas/models/municipio.dart';
import 'package:frontend_visitas/models/institucion.dart';
import 'package:frontend_visitas/models/visita_respuesta.dart';

class Visita {
  final int id;
  final DateTime? fechaCreacion;
  final DateTime? fechaVisita;
  final String? estado;
  final String? observaciones;
  final String? tipoAsunto;
  final String? contrato;
  final String? operador;
  final String? casoAtencionPrioritaria;
  final Sede? sede;
  final Usuario? usuario;
  final Usuario? profesional;
  final Municipio? municipio;
  final Institucion? institucion;
  final double? lat;
  final double? lon;
  final String? fotoEvidencia;
  final String? pdfEvidencia;
  final String? fotoFirma;
  final List<VisitaRespuesta> respuestasChecklist;

  Visita({
    required this.id,
    this.fechaCreacion,
    this.fechaVisita,
    this.estado,
    this.tipoAsunto,
    this.observaciones,
    this.contrato,
    this.operador,
    this.casoAtencionPrioritaria,
    this.sede,
    this.usuario,
    this.profesional,
    this.municipio,
    this.institucion,
    this.lat,
    this.lon,
    this.fotoEvidencia,
    this.pdfEvidencia,
    this.fotoFirma,
    this.respuestasChecklist = const [],
  });

  factory Visita.fromJson(Map<String, dynamic> json) {
    return Visita(
      id: json['id'] is int ? json['id'] : (json['id'] is String ? int.tryParse(json['id']) ?? 0 : 0),
      fechaCreacion: json['fecha_creacion'] != null 
          ? DateTime.parse(json['fecha_creacion']) 
          : null,
      fechaVisita: json['fecha_visita'] != null 
          ? DateTime.parse(json['fecha_visita']) 
          : null,
      estado: json['estado'],
      tipoAsunto: json['tipo_asunto'],
      observaciones: json['observaciones'],
      contrato: json['contrato'],
      operador: json['operador'],
      casoAtencionPrioritaria: json['caso_atencion_prioritaria'],
      sede: json['sede'] != null ? Sede.fromJson(json['sede']) : null,
      usuario: json['usuario'] != null ? Usuario.fromJson(json['usuario']) : null,
      profesional: json['profesional'] != null ? Usuario.fromJson(json['profesional']) : null,
      municipio: json['municipio'] != null ? Municipio.fromJson(json['municipio']) : null,
      institucion: json['institucion'] != null ? Institucion.fromJson(json['institucion']) : null,
      lat: json['lat']?.toDouble(),
      lon: json['lon']?.toDouble(),
      fotoEvidencia: json['foto_evidencia'],
      pdfEvidencia: json['pdf_evidencia'],
      fotoFirma: json['foto_firma'],
      respuestasChecklist: json['respuestas_checklist'] != null 
          ? (json['respuestas_checklist'] as List)
              .map((item) => VisitaRespuesta.fromJson(item))
              .toList()
          : [],
    );
  }
}