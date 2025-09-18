import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../utils/database_init.dart';

class LocalDB {
  static Database? _database;
  
  // Para web, usamos almacenamiento en memoria
  static final List<Map<String, dynamic>> _visitasPendientes = [];
  static final List<Map<String, dynamic>> _checklistPendientes = [];
  
  // Tabla para visitas pendientes de sincronización
  static const String tableVisitasPendientes = 'visitas_pendientes';
  static const String tableChecklistPendientes = 'checklist_pendientes';
  
  // Obtener instancia de la base de datos
  static Future<Database?> get database async {
    if (kIsWeb) {
      print('🌐 Modo web: usando almacenamiento en memoria');
      return null; // No hay base de datos real en web
    }
    
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  // Inicializar base de datos
  static Future<Database> _initDatabase() async {
    // Verificar que la base de datos esté inicializada
    DatabaseInit.ensureInitialized();
    
    String path;
    
    if (defaultTargetPlatform == TargetPlatform.windows || 
        defaultTargetPlatform == TargetPlatform.linux || 
        defaultTargetPlatform == TargetPlatform.macOS) {
      // Para desktop, usar el directorio de documentos del usuario
      final documentsDir = await getApplicationDocumentsDirectory();
      path = join(documentsDir.path, 'visitas_offline.db');
      print('🖥️ Usando directorio de documentos para desktop: $path');
    } else {
      // Para móvil, usar el directorio de base de datos por defecto
      path = join(await getDatabasesPath(), 'visitas_offline.db');
      print('📱 Usando directorio de base de datos para móvil: $path');
    }
    
    print('🗄️ Ruta final de la base de datos: $path');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }
  
  // Crear tablas
  static Future<void> _onCreate(Database db, int version) async {
    // Tabla para visitas pendientes
    await db.execute('''
      CREATE TABLE $tableVisitasPendientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data_visita TEXT NOT NULL,
        timestamp_creacion INTEGER NOT NULL,
        intentos_sincronizacion INTEGER DEFAULT 0,
        ultimo_intento INTEGER,
        estado TEXT DEFAULT 'pendiente'
      )
    ''');
    
    // Tabla para checklist pendientes
    await db.execute('''
      CREATE TABLE $tableChecklistPendientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        visita_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        respuesta TEXT NOT NULL,
        timestamp_creacion INTEGER NOT NULL,
        FOREIGN KEY (visita_id) REFERENCES $tableVisitasPendientes (id) ON DELETE CASCADE
      )
    ''');
    
    print('✅ Base de datos local creada exitosamente');
  }
  
  // Guardar visita localmente
  static Future<int> guardarVisitaLocal(Map<String, dynamic> dataVisita) async {
    try {
      if (kIsWeb) {
        // Para web, usar almacenamiento en memoria
        final visitaId = _visitasPendientes.length + 1;
        _visitasPendientes.add({
          'id': visitaId,
          'data_visita': jsonEncode(dataVisita),
          'timestamp_creacion': DateTime.now().millisecondsSinceEpoch,
          'estado': 'pendiente',
        });
        print('📥 Visita guardada en memoria (web) con ID: $visitaId');
        return visitaId;
      }
      
      final db = await database;
      
      // Guardar datos principales de la visita
      final visitaId = await db!.insert(
        tableVisitasPendientes,
        {
          'data_visita': jsonEncode(dataVisita),
          'timestamp_creacion': DateTime.now().millisecondsSinceEpoch,
          'estado': 'pendiente',
        },
      );
      
      print('📥 Visita guardada localmente con ID: $visitaId');
      return visitaId;
    } catch (e) {
      print('❌ Error al guardar visita localmente: $e');
      rethrow;
    }
  }
  
  // Guardar respuestas del checklist localmente
  static Future<void> guardarChecklistLocal(int visitaId, Map<int, String> respuestasChecklist) async {
    try {
      if (kIsWeb) {
        // Para web, usar almacenamiento en memoria
        for (var entry in respuestasChecklist.entries) {
          _checklistPendientes.add({
            'id': _checklistPendientes.length + 1,
            'visita_id': visitaId,
            'item_id': entry.key,
            'respuesta': entry.value,
            'timestamp_creacion': DateTime.now().millisecondsSinceEpoch,
          });
        }
        print('📋 Checklist guardado en memoria (web) para visita $visitaId');
        return;
      }
      
      final db = await database;
      
      for (var entry in respuestasChecklist.entries) {
        await db!.insert(
          tableChecklistPendientes,
          {
            'visita_id': visitaId,
            'item_id': entry.key,
            'respuesta': entry.value,
            'timestamp_creacion': DateTime.now().millisecondsSinceEpoch,
          },
        );
      }
      
      print('📋 Checklist guardado localmente para visita $visitaId');
    } catch (e) {
      print('❌ Error al guardar checklist localmente: $e');
      rethrow;
    }
  }
  
  // Obtener todas las visitas pendientes
  static Future<List<Map<String, dynamic>>> obtenerVisitasPendientes() async {
    try {
      if (kIsWeb) {
        // Para web, usar almacenamiento en memoria
        final visitas = _visitasPendientes.where((v) => v['estado'] == 'pendiente').toList();
        visitas.sort((a, b) => (a['timestamp_creacion'] as int).compareTo(b['timestamp_creacion'] as int));
        
        // Obtener checklist para cada visita
        for (var visita in visitas) {
          final checklist = _checklistPendientes.where((c) => c['visita_id'] == visita['id']).toList();
          
          // Convertir checklist a Map<int, String>
          Map<int, String> respuestasChecklist = {};
          for (var item in checklist) {
            respuestasChecklist[item['item_id'] as int] = item['respuesta'] as String;
          }
          
          // Agregar checklist a la visita
          final dataVisita = jsonDecode(visita['data_visita'] as String);
          dataVisita['respuestas_checklist'] = respuestasChecklist;
          visita['data_completa'] = dataVisita;
        }
        
        return visitas;
      }
      
      final db = await database;
      final visitas = await db!.query(
        tableVisitasPendientes,
        where: 'estado = ?',
        whereArgs: ['pendiente'],
        orderBy: 'timestamp_creacion ASC',
      );
      
      // Obtener checklist para cada visita
      for (var visita in visitas) {
        final checklist = await db.query(
          tableChecklistPendientes,
          where: 'visita_id = ?',
          whereArgs: [visita['id']],
        );
        
        // Convertir checklist a Map<int, String>
        Map<int, String> respuestasChecklist = {};
        for (var item in checklist) {
          respuestasChecklist[item['item_id'] as int] = item['respuesta'] as String;
        }
        
        // Agregar checklist a la visita
        final dataVisita = jsonDecode(visita['data_visita'] as String);
        dataVisita['respuestas_checklist'] = respuestasChecklist;
        visita['data_completa'] = dataVisita;
      }
      
      return visitas;
    } catch (e) {
      print('❌ Error al obtener visitas pendientes: $e');
      return [];
    }
  }
  
  // Marcar visita como sincronizada
  static Future<void> marcarVisitaSincronizada(int visitaId) async {
    try {
      if (kIsWeb) {
        // Para web, eliminar de memoria
        _visitasPendientes.removeWhere((v) => v['id'] == visitaId);
        _checklistPendientes.removeWhere((c) => c['visita_id'] == visitaId);
        print('✅ Visita $visitaId marcada como sincronizada y eliminada de memoria (web)');
        return;
      }
      
      final db = await database;
      
      // Eliminar checklist asociado
      await db!.delete(
        tableChecklistPendientes,
        where: 'visita_id = ?',
        whereArgs: [visitaId],
      );
      
      // Eliminar visita
      await db.delete(
        tableVisitasPendientes,
        where: 'id = ?',
        whereArgs: [visitaId],
      );
      
      print('✅ Visita $visitaId marcada como sincronizada y eliminada localmente');
    } catch (e) {
      print('❌ Error al marcar visita como sincronizada: $e');
      rethrow;
    }
  }
  
  // Marcar visita como fallida (para retry)
  static Future<void> marcarVisitaFallida(int visitaId, String error) async {
    try {
      if (kIsWeb) {
        // Para web, actualizar en memoria
        final index = _visitasPendientes.indexWhere((v) => v['id'] == visitaId);
        if (index != -1) {
          final intentosActuales = _visitasPendientes[index]['intentos_sincronizacion'] as int? ?? 0;
          _visitasPendientes[index]['estado'] = 'fallida';
          _visitasPendientes[index]['intentos_sincronizacion'] = intentosActuales + 1;
          _visitasPendientes[index]['ultimo_intento'] = DateTime.now().millisecondsSinceEpoch;
        }
        print('⚠️ Visita $visitaId marcada como fallida en memoria (web): $error');
        return;
      }
      
      final db = await database;
      
      // Obtener el valor actual de intentos_sincronizacion
      final result = await db!.query(
        tableVisitasPendientes,
        columns: ['intentos_sincronizacion'],
        where: 'id = ?',
        whereArgs: [visitaId],
      );
      
      if (result.isNotEmpty) {
        final intentosActuales = result.first['intentos_sincronizacion'] as int? ?? 0;
        
        await db.update(
          tableVisitasPendientes,
          {
            'estado': 'fallida',
            'intentos_sincronizacion': intentosActuales + 1,
            'ultimo_intento': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [visitaId],
        );
      }
      
      print('⚠️ Visita $visitaId marcada como fallida: $error');
    } catch (e) {
      print('❌ Error al marcar visita como fallida: $e');
      rethrow;
    }
  }
  
  // Obtener estadísticas de sincronización
  static Future<Map<String, int>> obtenerEstadisticasSincronizacion() async {
    try {
      if (kIsWeb) {
        // Para web, calcular desde memoria
        final totalPendientes = _visitasPendientes.where((v) => v['estado'] == 'pendiente').length;
        final totalFallidas = _visitasPendientes.where((v) => v['estado'] == 'fallida').length;
        
        return {
          'pendientes': totalPendientes,
          'fallidas': totalFallidas,
          'total': totalPendientes + totalFallidas,
        };
      }
      
      final db = await database;
      
      final totalPendientes = Sqflite.firstIntValue(
        await db!.rawQuery('SELECT COUNT(*) FROM $tableVisitasPendientes WHERE estado = "pendiente"')
      ) ?? 0;
      
      final totalFallidas = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableVisitasPendientes WHERE estado = "fallida"')
      ) ?? 0;
      
      return {
        'pendientes': totalPendientes,
        'fallidas': totalFallidas,
        'total': totalPendientes + totalFallidas,
      };
    } catch (e) {
      print('❌ Error al obtener estadísticas: $e');
      return {'pendientes': 0, 'fallidas': 0, 'total': 0};
    }
  }
  
  // Limpiar base de datos (para debugging)
  static Future<void> limpiarBaseDatos() async {
    try {
      if (kIsWeb) {
        // Para web, limpiar memoria
        _visitasPendientes.clear();
        _checklistPendientes.clear();
        print('🧹 Memoria limpiada (web)');
        return;
      }
      
      final db = await database;
      await db!.delete(tableChecklistPendientes);
      await db.delete(tableVisitasPendientes);
      print('🧹 Base de datos local limpiada');
    } catch (e) {
      print('❌ Error al limpiar base de datos: $e');
    }
  }
}
