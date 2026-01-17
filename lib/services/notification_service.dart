import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/task_model.dart';
import '../models/objective_model.dart';
import '../core/utils/constants.dart';

/// Handler para notificações em background (top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Notificação em background: ${message.messageId}');
}

/// Serviço de Notificações Push usando FCM e Local Notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _fcmToken;

  /// Inicializa o serviço de notificações
  Future<void> initializeNotifications() async {
    if (_isInitialized) return;

    try {
      // Inicializar timezone
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

      // Configurar Firebase Messaging
      await _setupFirebaseMessaging();

      // Configurar Local Notifications
      await _setupLocalNotifications();

      // Solicitar permissões
      await _requestPermissions();

      _isInitialized = true;
      debugPrint('NotificationService inicializado com sucesso');
    } catch (e) {
      debugPrint('Erro ao inicializar NotificationService: $e');
    }
  }

  /// Configura Firebase Messaging
  Future<void> _setupFirebaseMessaging() async {
    // Handler para notificações em background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Obter token FCM
    _fcmToken = await _firebaseMessaging.getToken();
    debugPrint('FCM Token: $_fcmToken');

    // Listener para mudanças no token
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      debugPrint('Novo FCM Token: $newToken');
    });

    // Handler para notificações em foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Notificação em foreground: ${message.notification?.title}');
      _showLocalNotification(
        id: message.hashCode,
        title: message.notification?.title ?? 'SYSTEM: AWAKEN',
        body: message.notification?.body ?? '',
        payload: message.data.toString(),
      );
    });

    // Handler para quando usuário toca na notificação
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notificação aberta: ${message.notification?.title}');
      // Aqui pode navegar para tela específica baseado em message.data
    });
  }

  /// Configura Local Notifications
  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notificação local tocada: ${response.payload}');
        // Aqui pode navegar para tela específica
      },
    );

    // CRIAR CANAIS EXPLICITAMENTE (Android 8.0+)
    await _createNotificationChannels();
  }

  /// Cria todos os canais de notificação explicitamente
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return; // Não é Android

    // Canal de Tarefas
    const tasksChannel = AndroidNotificationChannel(
      'tasks_channel',
      'Tarefas',
      description: 'Notificações de tarefas agendadas',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await androidPlugin.createNotificationChannel(tasksChannel);

    // Canal de Hábitos
    const habitsChannel = AndroidNotificationChannel(
      'habits_channel',
      'Hábitos',
      description: 'Notificações de hábitos diários',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await androidPlugin.createNotificationChannel(habitsChannel);

    // Canal de Daily Quests
    const dailyQuestsChannel = AndroidNotificationChannel(
      'daily_quests_channel',
      'Daily Quests',
      description: 'Notificações de daily quests',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await androidPlugin.createNotificationChannel(dailyQuestsChannel);

    // Canal de Penalty Zone
    const penaltyZoneChannel = AndroidNotificationChannel(
      'penalty_zone_channel',
      'Penalty Zone',
      description: 'Notificações da Penalty Zone',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await androidPlugin.createNotificationChannel(penaltyZoneChannel);

    // Canal de Streaks
    const streakChannel = AndroidNotificationChannel(
      'streak_channel',
      'Streaks',
      description: 'Notificações de streaks em risco',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await androidPlugin.createNotificationChannel(streakChannel);

    // Canal padrão
    const defaultChannel = AndroidNotificationChannel(
      'default_channel',
      'SYSTEM: AWAKEN',
      description: 'Notificações gerais do sistema',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await androidPlugin.createNotificationChannel(defaultChannel);

    debugPrint('Todos os canais de notificação foram criados');
  }

  /// Solicita permissões de notificação
  Future<void> _requestPermissions() async {
    // Android 13+ requer permissão explícita
    final androidInfo = await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // iOS requer permissão
    final iosInfo = await _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Firebase Messaging também precisa de permissão
    final fcmSettings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('Permissões Android: $androidInfo');
    debugPrint('Permissões iOS: $iosInfo');
    debugPrint('Permissões FCM: ${fcmSettings.authorizationStatus}');
  }

  /// Agenda notificação para uma tarefa
  Future<void> scheduleTaskNotification(TaskModel task) async {
    if (task.time == null || task.createdAt.isBefore(DateTime.now())) {
      return; // Não agenda se não tiver horário ou já passou
    }

    try {
      // Parse do horário (formato "HH:mm")
      final timeParts = task.time!.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Data da tarefa
      final taskDate = DateTime(
        task.createdAt.year,
        task.createdAt.month,
        task.createdAt.day,
        hour,
        minute,
      );

      // Notificar 15 minutos antes
      final notificationTime = taskDate.subtract(const Duration(minutes: 15));

      // Se já passou, não agenda
      if (notificationTime.isBefore(DateTime.now())) {
        return;
      }

      await _localNotifications.zonedSchedule(
        task.id.hashCode,
        'Tarefa em 15 minutos',
        task.title,
        tz.TZDateTime.from(notificationTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'tasks_channel',
            'Tarefas',
            channelDescription: 'Notificações de tarefas agendadas',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('Notificação agendada para tarefa: ${task.title} em $notificationTime');
    } catch (e) {
      debugPrint('Erro ao agendar notificação de tarefa: $e');
    }
  }

  /// Agenda notificação para um hábito
  Future<void> scheduleHabitNotification(ObjectiveModel habit) async {
    if (habit.rank != ObjectiveRank.b || habit.time == null) {
      return; // Apenas hábitos (Rank B) com horário
    }

    try {
      // Parse do horário (formato "HH:mm")
      final timeParts = habit.time!.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Agendar para hoje e todos os dias seguintes
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, hour, minute);

      // Se já passou hoje, agenda para amanhã
      final notificationTime = today.isBefore(now)
          ? today.add(const Duration(days: 1))
          : today;

      await _localNotifications.zonedSchedule(
        habit.id.hashCode,
        'Hábito: ${habit.title}',
        'Hora de completar seu hábito diário',
        tz.TZDateTime.from(notificationTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habits_channel',
            'Hábitos',
            channelDescription: 'Notificações de hábitos diários',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('Notificação agendada para hábito: ${habit.title} em $notificationTime');
    } catch (e) {
      debugPrint('Erro ao agendar notificação de hábito: $e');
    }
  }

  /// Agenda notificação para Daily Quests (meia-noite)
  Future<void> scheduleDailyQuestNotification() async {
    try {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 0);

      await _localNotifications.zonedSchedule(
        'daily_quests'.hashCode,
        'Daily Quests Disponíveis',
        'Suas daily quests foram resetadas! Complete-as para manter seu streak.',
        tz.TZDateTime.from(tomorrow, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_quests_channel',
            'Daily Quests',
            channelDescription: 'Notificações de daily quests',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('Notificação agendada para daily quests em $tomorrow');
    } catch (e) {
      debugPrint('Erro ao agendar notificação de daily quests: $e');
    }
  }

  /// Agenda notificação de Penalty Zone
  Future<void> schedulePenaltyZoneNotification() async {
    try {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1, 8, 0); // 8h da manhã

      await _localNotifications.zonedSchedule(
        'penalty_zone'.hashCode,
        'Penalty Zone Ativa',
        'Você está na Penalty Zone! Complete suas daily quests para sair.',
        tz.TZDateTime.from(tomorrow, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'penalty_zone_channel',
            'Penalty Zone',
            channelDescription: 'Notificações da Penalty Zone',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFFFF0000), // Vermelho
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('Notificação agendada para Penalty Zone em $tomorrow');
    } catch (e) {
      debugPrint('Erro ao agendar notificação de Penalty Zone: $e');
    }
  }

  /// Notifica se streak está em risco (23:59)
  Future<void> scheduleStreakRiskNotification(String habitId, String habitTitle) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 23, 59);

      // Se já passou, agenda para amanhã
      final notificationTime = today.isBefore(now)
          ? today.add(const Duration(days: 1))
          : today;

      await _localNotifications.zonedSchedule(
        'streak_$habitId'.hashCode,
        'Streak em Risco!',
        'Complete "$habitTitle" antes da meia-noite para manter seu streak.',
        tz.TZDateTime.from(notificationTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'streak_channel',
            'Streaks',
            channelDescription: 'Notificações de streaks em risco',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('Notificação de streak agendada para: $notificationTime');
    } catch (e) {
      debugPrint('Erro ao agendar notificação de streak: $e');
    }
  }

  /// Cancela uma notificação específica
  Future<void> cancelNotification(String notificationId) async {
    await _localNotifications.cancel(notificationId.hashCode);
    debugPrint('Notificação cancelada: $notificationId');
  }

  /// Cancela todas as notificações
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    debugPrint('Todas as notificações foram canceladas');
  }

  /// Mostra notificação local imediatamente
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'SYSTEM: AWAKEN',
          channelDescription: 'Notificações gerais do sistema',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Retorna o token FCM (para salvar no Firestore se necessário)
  String? get fcmToken => _fcmToken;
}
