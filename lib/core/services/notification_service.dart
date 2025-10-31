import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';
import '../../data/database/database_helper.dart';

/// Notification service for managing local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationTapped,
    );

    // Create notification channel for Android
    await _createNotificationChannel();

    _initialized = true;
  }

  /// Create Android notification channel with high priority
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDesc,
      importance: Importance.max, // Changed to max
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Handle notification tap when app is in foreground
  void _onNotificationTapped(NotificationResponse response) async {
    final payload = response.payload;
    debugPrint('Notification tapped (foreground): $payload');

    if (payload != null) {
      await _recordNotificationInteraction(payload, 'seen');
    }
  }

  /// Handle notification tap when app is in background/terminated
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(
      NotificationResponse response,) async {
    final payload = response.payload;
    debugPrint('Notification tapped (background): $payload');

    if (payload != null) {
      await _recordNotificationInteraction(payload, 'seen');
    }
  }

  /// Record notification interaction in database
  static Future<void> _recordNotificationInteraction(
      String reminderId, String outcome,) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;

      // Import uuid for generating event id
      final eventId = DateTime.now().millisecondsSinceEpoch.toString();

      await db.insert(
        AppConstants.contextEventsTable,
        {
          'id': eventId,
          'reminderId': reminderId,
          'contextType': 'notification_tap',
          'triggerTime': DateTime.now().toIso8601String(),
          'outcome': outcome,
          'metadata': null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint(
          '✅ Recorded notification interaction for reminder $reminderId',);
    } catch (e) {
      debugPrint('❌ Failed to record notification interaction: $e');
    }
  }

  /// Record scheduled notification in database
  static Future<void> _recordScheduledNotification(
      String reminderId, DateTime scheduledTime,) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;

      final eventId = 'sched_${DateTime.now().millisecondsSinceEpoch}';

      await db.insert(
        AppConstants.contextEventsTable,
        {
          'id': eventId,
          'reminderId': reminderId,
          'contextType': AppConstants.contextTypeTime,
          'triggerTime': scheduledTime.toIso8601String(),
          'outcome': AppConstants.outcomePending,
          'metadata': null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint(
          '✅ Recorded scheduled notification for reminder $reminderId at $scheduledTime',);
    } catch (e) {
      debugPrint('❌ Failed to record scheduled notification: $e');
    }
  }

  /// Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint('Showing notification id=$id title="$title" payload=$payload');

    const androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      enableLights: true,
      autoCancel: true,
      ongoing: false,
      fullScreenIntent: true, // Shows notification even when screen is off
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Schedule notification for a specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    // Validate scheduled time is in the future
    if (scheduledTime.isBefore(DateTime.now())) {
      debugPrint('⚠️ Warning: Scheduled time is in the past! $scheduledTime');
      return;
    }

    debugPrint(
        '📅 Scheduling notification id=$id title="$title" at $scheduledTime payload=$payload',);

    const androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      autoCancel: true,
      ongoing: false,
      fullScreenIntent: true, // Critical for showing when screen is off
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    debugPrint('🔔 TZ Scheduled time: $tzScheduledTime');
    debugPrint('🕐 Current time: ${tz.TZDateTime.now(tz.local)}');
    debugPrint(
        '⏰ Time until notification: ${tzScheduledTime.difference(tz.TZDateTime.now(tz.local))}',);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      details,
      payload: payload,
      androidScheduleMode:
          AndroidScheduleMode.exactAllowWhileIdle, // This allows waking device
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          null, // Important: null for one-time notifications
    );

    // Verify it was scheduled
    final pending = await getPendingNotifications();
    final scheduled = pending.any((p) => p.id == id);
    debugPrint('✅ Notification scheduled successfully: $scheduled');

    // Create context event for scheduled notification
    if (scheduled && payload != null) {
      await NotificationService._recordScheduledNotification(
          payload, scheduledTime,);
    }
  }

  /// Cancel notification
  Future<void> cancelNotification(int id) async {
    debugPrint('🗑️ Cancelling notification id=$id');
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    debugPrint('🗑️ Cancelling all notifications');
    await _notifications.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    final pending = await _notifications.pendingNotificationRequests();
    debugPrint('📋 Pending notifications: ${pending.length}');
    for (var p in pending) {
      debugPrint('  - ID: ${p.id}, Title: ${p.title}, Body: ${p.body}');
    }
    return pending;
  }

  /// Request notification permissions (iOS)
  Future<bool> requestPermissions() async {
    final result = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // requestPermissions returns bool? on iOS; default to true when null
    return result ?? true;
  }

  /// Check if a notification is scheduled
  Future<bool> isNotificationScheduled(int id) async {
    final pending = await getPendingNotifications();
    return pending.any((p) => p.id == id);
  }
}
