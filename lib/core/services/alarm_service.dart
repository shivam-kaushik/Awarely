import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service for scheduling reliable alarms using native AlarmManager
/// This is more reliable than flutter_local_notifications for exact timing
class AlarmService {
  static const _channel = MethodChannel('com.example.awarely/alarms');

  /// Schedule an exact alarm that will fire even if the app is killed
  static Future<bool> scheduleExactAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      // Validate scheduled time is in future
      if (scheduledTime.isBefore(DateTime.now())) {
        debugPrint('⚠️ Cannot schedule alarm in the past: $scheduledTime');
        return false;
      }

      final scheduledTimeMillis = scheduledTime.millisecondsSinceEpoch;

      debugPrint('📱 Scheduling native alarm:');
      debugPrint('   ID: $id');
      debugPrint('   Title: $title');
      debugPrint('   Time: $scheduledTime');
      debugPrint('   Millis: $scheduledTimeMillis');
      debugPrint('   Payload: $payload');

      final result = await _channel.invokeMethod<bool>('scheduleExactAlarm', {
        'id': id,
        'title': title,
        'body': body,
        'scheduledTimeMillis': scheduledTimeMillis,
        'payload': payload,
      });

      if (result == true) {
        debugPrint('✅ Native alarm scheduled successfully');
      } else {
        debugPrint('❌ Native alarm scheduling failed');
      }

      return result ?? false;
    } catch (e) {
      debugPrint('❌ Error scheduling native alarm: $e');
      return false;
    }
  }

  /// Cancel a scheduled alarm
  static Future<void> cancelAlarm(int id) async {
    try {
      await _channel.invokeMethod('cancelAlarm', {'id': id});
      debugPrint('🗑️ Cancelled alarm id=$id');
    } catch (e) {
      debugPrint('❌ Error cancelling alarm: $e');
    }
  }

  /// Cancel all scheduled alarms
  static Future<void> cancelAllAlarms() async {
    try {
      await _channel.invokeMethod('cancelAllAlarms');
      debugPrint('🗑️ Cancelled all alarms');
    } catch (e) {
      debugPrint('❌ Error cancelling all alarms: $e');
    }
  }
}
