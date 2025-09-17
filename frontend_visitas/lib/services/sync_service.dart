import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:frontend_visitas/local/db_helper.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:flutter/material.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ApiService _apiService = ApiService();
  bool _isSyncing = false;
  
  // Obtener estado de sincronización
  bool get isSyncing => _isSyncing;
  
  // Verificar conectividad
  Future<bool> _tieneConexion() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  // Sincronizar todas las visitas pendientes
  Future<Map<String, dynamic>> sincronizarVisitasPendientes() async {
    if (_isSyncing) {
      print('⏳ Sincronización ya en progreso...');
      return {'success': false, 'message': 'Sincronización ya en progreso'};
    }
    
    if (!await _tieneConexion()) {
      print('🔌 Sin conexión a internet');
      return {'success': false, 'message': 'Sin conexión a internet'};
    }
    
    _isSyncing = true;
    int exitosas = 0;
    int fallidas = 0;
    List<String> errores = [];
    
    try {
      print('🔄 Iniciando sincronización de visitas pendientes...');
      
      // Obtener visitas pendientes
      final visitasPendientes = await LocalDB.obtenerVisitasPendientes();
      
      if (visitasPendientes.isEmpty) {
        print('✅ No hay visitas pendientes de sincronización');
        return {'success': true, 'message': 'No hay visitas pendientes', 'exitosas': 0, 'fallidas': 0};
      }
      
      print('📋 Encontradas ${visitasPendientes.length} visitas pendientes');
      
      // Procesar cada visita
      for (var visita in visitasPendientes) {
        try {
          final visitaId = visita['id'] as int;
          final dataCompleta = visita['data_completa'] as Map<String, dynamic>;
          
          print('🔄 Sincronizando visita $visitaId...');
          
          // Extraer datos de la visita
          final fechaVisita = DateTime.parse(dataCompleta['fecha_visita']);
          final horaVisita = _parseTimeString(dataCompleta['hora_visita']);
          final respuestasChecklist = dataCompleta['respuestas_checklist'] as Map<int, String>?;
          
          // Enviar al servidor (la función crearVisitaCompletaPAE ya convierte el formato)
          final success = await _apiService.crearVisitaCompletaPAE(
            fechaVisita: fechaVisita,
            horaVisita: horaVisita,
            contrato: dataCompleta['contrato'],
            operador: dataCompleta['operador'],
            municipioId: dataCompleta['municipio_id'],
            institucionId: dataCompleta['institucion_id'],
            sedeId: dataCompleta['sede_id'],
            profesionalId: dataCompleta['profesional_id'],
            casoAtencionPrioritaria: dataCompleta['caso_atencion_prioritaria'],
            tipoVisita: dataCompleta['tipo_visita'],
            prioridad: dataCompleta['prioridad'],
            observaciones: dataCompleta['observaciones'],
            lat: dataCompleta['lat'],
            lon: dataCompleta['lon'],
            precisionGps: dataCompleta['precision_gps'],
            respuestasChecklist: respuestasChecklist,
          );
          
          if (success) {
            // Marcar como sincronizada
            await LocalDB.marcarVisitaSincronizada(visitaId);
            exitosas++;
            print('✅ Visita $visitaId sincronizada exitosamente');
          } else {
            // Marcar como fallida
            await LocalDB.marcarVisitaFallida(visitaId, 'Error en la respuesta del servidor');
            fallidas++;
            errores.add('Visita $visitaId: Error en la respuesta del servidor');
            print('❌ Visita $visitaId falló en la sincronización');
          }
          
        } catch (e) {
          final visitaId = visita['id'] as int;
          await LocalDB.marcarVisitaFallida(visitaId, e.toString());
          fallidas++;
          errores.add('Visita $visitaId: $e');
          print('❌ Error al sincronizar visita ${visita['id']}: $e');
        }
      }
      
      print('🎉 Sincronización completada: $exitosas exitosas, $fallidas fallidas');
      
      return {
        'success': true,
        'message': 'Sincronización completada',
        'exitosas': exitosas,
        'fallidas': fallidas,
        'errores': errores,
      };
      
    } catch (e) {
      print('❌ Error general en sincronización: $e');
      return {
        'success': false,
        'message': 'Error general en sincronización: $e',
        'exitosas': exitosas,
        'fallidas': fallidas,
        'errores': errores,
      };
    } finally {
      _isSyncing = false;
    }
  }
  
  // Sincronización automática cuando se restaura la conexión
  Future<void> sincronizacionAutomatica() async {
    if (_isSyncing) return;
    
    if (await _tieneConexion()) {
      print('🌐 Conexión restaurada. Iniciando sincronización automática...');
      await sincronizarVisitasPendientes();
    }
  }
  
  // Sincronización con retry automático
  Future<void> sincronizacionConRetry({int maxIntentos = 3, Duration delay = const Duration(seconds: 5)}) async {
    int intentos = 0;
    
    while (intentos < maxIntentos) {
      try {
        final resultado = await sincronizarVisitasPendientes();
        
        if (resultado['success'] && resultado['fallidas'] == 0) {
          print('✅ Sincronización exitosa en intento ${intentos + 1}');
          break;
        }
        
        if (resultado['fallidas'] > 0) {
          print('⚠️ ${resultado['fallidas']} visitas fallaron. Reintentando...');
          intentos++;
          
          if (intentos < maxIntentos) {
            print('⏳ Esperando $delay antes del siguiente intento...');
            await Future.delayed(delay);
          }
        }
        
      } catch (e) {
        print('❌ Error en intento ${intentos + 1}: $e');
        intentos++;
        
        if (intentos < maxIntentos) {
          print('⏳ Esperando $delay antes del siguiente intento...');
          await Future.delayed(delay);
        }
      }
    }
    
    if (intentos >= maxIntentos) {
      print('⚠️ Se alcanzó el máximo de intentos de sincronización');
    }
  }
  
  // Obtener estadísticas de sincronización
  Future<Map<String, dynamic>> obtenerEstadisticas() async {
    try {
      final stats = await LocalDB.obtenerEstadisticasSincronizacion();
      final tieneConexion = await _tieneConexion();
      
      return {
        ...stats,
        'tiene_conexion': tieneConexion,
        'estado_sincronizacion': _isSyncing ? 'en_progreso' : 'disponible',
      };
    } catch (e) {
      print('❌ Error al obtener estadísticas: $e');
      return {
        'pendientes': 0,
        'fallidas': 0,
        'total': 0,
        'tiene_conexion': false,
        'estado_sincronizacion': 'error',
      };
    }
  }
  
  // Limpiar datos fallidos (para debugging)
  Future<void> limpiarDatosFallidos() async {
    try {
      await LocalDB.limpiarBaseDatos();
      print('🧹 Datos fallidos limpiados');
    } catch (e) {
      print('❌ Error al limpiar datos fallidos: $e');
    }
  }
  
  // Convertir string de hora a TimeOfDay
  TimeOfDay _parseTimeString(String timeString) {
    try {
      // Formato esperado: "14:30:00.000"
      final parts = timeString.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      print('⚠️ Error al parsear hora: $timeString, usando hora actual');
      final now = DateTime.now();
      return TimeOfDay(hour: now.hour, minute: now.minute);
    }
  }
}


