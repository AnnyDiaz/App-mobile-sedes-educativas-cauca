import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseInit {
  static bool _initialized = false;
  
  /// Inicializa la base de datos de manera global
  static Future<void> initialize() async {
    print('🔧 DatabaseInit.initialize() llamado');
    if (_initialized) {
      print('✅ Ya está inicializado, retornando...');
      return;
    }
    
    try {
      print('🔍 Verificando plataforma...');
      print('🌐 kIsWeb: $kIsWeb');
      print('🖥️ defaultTargetPlatform: $defaultTargetPlatform');
      
      // Para web, no inicializamos databaseFactory ya que sqflite no funciona en web
      if (kIsWeb) {
        print('🌐 Detectada plataforma web - saltando inicialización de base de datos local');
        print('⚠️ Nota: En web, la aplicación usará solo almacenamiento en servidor');
        _initialized = true;
        print('🗄️ Inicialización de base de datos completada (modo web)');
        return;
      }
      
      // Para desktop (Windows, Linux, macOS)
      if (defaultTargetPlatform == TargetPlatform.windows || 
          defaultTargetPlatform == TargetPlatform.linux || 
          defaultTargetPlatform == TargetPlatform.macOS) {
        print('🖥️ Inicializando databaseFactory para desktop...');
        
        // Inicializar sqflite_common_ffi
        print('📦 Llamando sqfliteFfiInit()...');
        sqfliteFfiInit();
        print('✅ sqfliteFfiInit() completado');
        
        // Configurar databaseFactory global
        print('🔧 Configurando databaseFactory global...');
        databaseFactory = databaseFactoryFfi;
        
        print('✅ databaseFactory configurado exitosamente para desktop');
        print('🔍 Tipo de databaseFactory: ${databaseFactory.runtimeType}');
        print('🔍 databaseFactory == null: ${databaseFactory == null}');
      } else {
        print('📱 Usando databaseFactory por defecto para móvil');
        // No acceder a databaseFactory en web para evitar errores
        if (!kIsWeb) {
          print('🔍 databaseFactory actual: ${databaseFactory.runtimeType}');
        }
      }
      
      _initialized = true;
      print('🗄️ Inicialización de base de datos completada');
      
    } catch (e) {
      print('❌ Error al inicializar base de datos: $e');
      print('📚 Stack trace: ${StackTrace.current}');
      // En lugar de rethrow, continuamos la aplicación
      print('⚠️ Continuando sin base de datos local...');
      _initialized = true;
    }
  }
  
  /// Verifica que la base de datos esté inicializada
  static void ensureInitialized() {
    if (!_initialized) {
      throw Exception('DatabaseInit.initialize() debe ser llamado antes de usar la base de datos');
    }
  }
}
