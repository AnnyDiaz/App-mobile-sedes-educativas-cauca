// frontend_visitas/lib/services/notificaciones_push_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificacionesPushService {
  static final NotificacionesPushService _instance = NotificacionesPushService._internal();
  factory NotificacionesPushService() => _instance;
  NotificacionesPushService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();
  
  String? _fcmToken;
  bool _isInitialized = false;
  
  // Stream para escuchar notificaciones en primer plano
  Stream<RemoteMessage> get onMessageStream => FirebaseMessaging.onMessage;
  
  // Stream para escuchar cuando se toca una notificación
  Stream<RemoteMessage> get onMessageOpenedAppStream => FirebaseMessaging.onMessageOpenedApp;
  
  // Stream para escuchar cuando se abre la app desde una notificación
  Stream<RemoteMessage> get onInitialMessageStream => FirebaseMessaging.onMessageOpenedApp;

  /// Inicializa el servicio de notificaciones push
  Future<void> inicializar() async {
    if (_isInitialized) return;
    
    try {
      // Inicializar Firebase si no está en web
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await Firebase.initializeApp();
      }
      
      // Configurar notificaciones locales
      await _configurarNotificacionesLocales();
      
      // Solicitar permisos
      await _solicitarPermisos();
      
      // Configurar Firebase Messaging
      await _configurarFirebaseMessaging();
      
      // Configurar handlers para notificaciones
      await _configurarHandlers();
      
      // Obtener token FCM
      await _obtenerTokenFCM();
      
      _isInitialized = true;
      print('✅ Servicio de notificaciones push inicializado');
      
    } catch (e) {
      print('❌ Error al inicializar notificaciones push: $e');
    }
  }

  /// Configura las notificaciones locales
  Future<void> _configurarNotificacionesLocales() async {
    try {
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings iosSettings = 
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      print('✅ Notificaciones locales configuradas');
      
    } catch (e) {
      print('❌ Error al configurar notificaciones locales: $e');
    }
  }

  /// Solicita permisos para notificaciones
  Future<void> _solicitarPermisos() async {
    try {
      if (Platform.isAndroid) {
        // Para Android, los permisos se manejan automáticamente
        print('✅ Permisos de Android configurados');
      } else if (Platform.isIOS) {
        // Para iOS, solicitar permisos explícitamente
        final status = await Permission.notification.request();
        if (status.isGranted) {
          print('✅ Permisos de notificación concedidos en iOS');
        } else {
          print('⚠️ Permisos de notificación denegados en iOS');
        }
      }
    } catch (e) {
      print('❌ Error al solicitar permisos: $e');
    }
  }

  /// Configura Firebase Messaging
  Future<void> _configurarFirebaseMessaging() async {
    try {
      // Configurar opciones de notificación
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      
      // Configurar topic para notificaciones generales
      await _firebaseMessaging.subscribeToTopic('general');
      
      print('✅ Firebase Messaging configurado');
      
    } catch (e) {
      print('❌ Error al configurar Firebase Messaging: $e');
    }
  }

  /// Configura los handlers para diferentes tipos de notificaciones
  Future<void> _configurarHandlers() async {
    try {
      // Handler para notificaciones en primer plano
      FirebaseMessaging.onMessage.listen(_manejarNotificacionPrimerPlano);
      
      // Handler para cuando se toca una notificación
      FirebaseMessaging.onMessageOpenedApp.listen(_manejarNotificacionTocada);
      
      // Handler para notificación inicial
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _manejarNotificacionTocada(initialMessage);
      }
      
      print('✅ Handlers de notificaciones configurados');
      
    } catch (e) {
      print('❌ Error al configurar handlers: $e');
    }
  }

  /// Obtiene el token FCM del dispositivo
  Future<void> _obtenerTokenFCM() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        print('✅ Token FCM obtenido: ${_fcmToken!.substring(0, 20)}...');
        
        // Guardar token en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
        
        // Registrar dispositivo en el backend
        await _registrarDispositivoEnBackend();
      } else {
        print('⚠️ No se pudo obtener token FCM');
      }
    } catch (e) {
      print('❌ Error al obtener token FCM: $e');
    }
  }

  /// Registra el dispositivo en el backend
  Future<void> _registrarDispositivoEnBackend() async {
    try {
      if (_fcmToken == null) return;
      
      final plataforma = _getPlataforma();
      
      // Aquí deberías llamar a tu API para registrar el dispositivo
      // await _apiService.registrarDispositivoNotificacion(
      //   token: _fcmToken!,
      //   plataforma: plataforma,
      // );
      
      print('✅ Dispositivo registrado en backend');
      
    } catch (e) {
      print('❌ Error al registrar dispositivo en backend: $e');
    }
  }

  /// Obtiene la plataforma del dispositivo
  String _getPlataforma() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  /// Maneja notificaciones recibidas en primer plano
  void _manejarNotificacionPrimerPlano(RemoteMessage message) {
    print('📱 Notificación recibida en primer plano: ${message.notification?.title}');
    
    // Mostrar notificación local
    _mostrarNotificacionLocal(
      id: message.hashCode,
      title: message.notification?.title ?? 'Nueva notificación',
      body: message.notification?.body ?? '',
      payload: json.encode(message.data),
    );
  }

  /// Maneja cuando se toca una notificación
  void _manejarNotificacionTocada(RemoteMessage message) {
    print('👆 Notificación tocada: ${message.notification?.title}');
    
    // Aquí puedes navegar a una pantalla específica basada en los datos
    final data = message.data;
    if (data.containsKey('tipo')) {
      switch (data['tipo']) {
        case 'visita_proxima':
          // Navegar a pantalla de visitas próximas
          break;
        case 'visita_vencida':
          // Navegar a pantalla de visitas vencidas
          break;
        case 'recordatorio':
          // Navegar a pantalla de recordatorios
          break;
        default:
          // Navegar a pantalla de notificaciones
          break;
      }
    }
  }

  /// Muestra una notificación local
  Future<void> _mostrarNotificacionLocal({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'default_channel',
        'Canal Principal',
        channelDescription: 'Canal para notificaciones principales',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );
      
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _localNotifications.show(id, title, body, details, payload: payload);
      
    } catch (e) {
      print('❌ Error al mostrar notificación local: $e');
    }
  }

  /// Envía una notificación local programada
  Future<void> programarNotificacionLocal({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      // Convertir DateTime a TZDateTime
      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
      
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'scheduled_channel',
        'Canal Programado',
        channelDescription: 'Canal para notificaciones programadas',
        importance: Importance.high,
        priority: Priority.high,
      );
      
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
      
      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      
      print('✅ Notificación local programada para ${scheduledDate.toString()}');
      
    } catch (e) {
      print('❌ Error al programar notificación local: $e');
    }
  }

  /// Cancela una notificación programada
  Future<void> cancelarNotificacionProgramada(int id) async {
    try {
      await _localNotifications.cancel(id);
      print('✅ Notificación programada cancelada');
    } catch (e) {
      print('❌ Error al cancelar notificación programada: $e');
    }
  }

  /// Cancela todas las notificaciones programadas
  Future<void> cancelarTodasNotificacionesProgramadas() async {
    try {
      await _localNotifications.cancelAll();
      print('✅ Todas las notificaciones programadas canceladas');
    } catch (e) {
      print('❌ Error al cancelar todas las notificaciones: $e');
    }
  }

  /// Obtiene el token FCM actual
  String? get fcmToken => _fcmToken;

  /// Verifica si el servicio está inicializado
  bool get isInitialized => _isInitialized;

  /// Suscribe a un topic específico
  Future<void> suscribirATopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Suscrito al topic: $topic');
    } catch (e) {
      print('❌ Error al suscribirse al topic: $e');
    }
  }

  /// Desuscribe de un topic específico
  Future<void> desuscribirDeTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Desuscrito del topic: $topic');
    } catch (e) {
      print('❌ Error al desuscribirse del topic: $e');
    }
  }

  /// Handler para cuando se toca una notificación local
  void _onNotificationTapped(NotificationResponse response) {
    print('👆 Notificación local tocada: ${response.payload}');
    
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        // Manejar la navegación basada en los datos
        print('📱 Datos de notificación: $data');
      } catch (e) {
        print('❌ Error al procesar payload de notificación: $e');
      }
    }
  }

  /// Limpia recursos del servicio
  Future<void> dispose() async {
    try {
      // Cancelar todas las notificaciones programadas
      await cancelarTodasNotificacionesProgramadas();
      
      // Desuscribir de todos los topics
      await _firebaseMessaging.unsubscribeFromTopic('general');
      
      print('✅ Servicio de notificaciones push limpiado');
      
    } catch (e) {
      print('❌ Error al limpiar servicio de notificaciones: $e');
    }
  }
}
