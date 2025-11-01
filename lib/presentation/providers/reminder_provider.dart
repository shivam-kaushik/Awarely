import 'package:flutter/foundation.dart';

import '../../data/models/reminder.dart';
import '../../data/repositories/reminder_repository.dart';
import '../../core/services/alarm_service.dart';
import '../../core/services/nlu_parser.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/learning_service.dart';

/// Reminder state management provider
class ReminderProvider with ChangeNotifier {
  final ReminderRepository _reminderRepository;
  late final LearningService _learningService;

  List<Reminder> _reminders = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _statistics;

  ReminderProvider({
    required ReminderRepository reminderRepository,
  }) : _reminderRepository = reminderRepository {
    _learningService = LearningService(reminderRepository);
  }

  // Getters
  List<Reminder> get reminders => _reminders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get statistics => _statistics;

  List<Reminder> get activeReminders =>
      _reminders.where((r) => r.enabled).toList();

  int get reminderCount => _reminders.length;
  int get activeReminderCount => activeReminders.length;

  /// Load all reminders
  Future<void> loadReminders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reminders = await _reminderRepository.getAllReminders();
      await loadStatistics();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create reminder from text (using NLU parser)
  Future<String?> createReminderFromText(String text) async {
    try {
      // Validate intent
      if (!NLUParser.hasValidIntent(text)) {
        _error = 'Please provide a clear task description';
        notifyListeners();
        return null;
      }

      // Parse text using NLU
      final reminder = NLUParser.parseReminderText(text);

      // Save to database
      final id = await _reminderRepository.createReminder(reminder);

      // Schedule notification(s)
      if (reminder.timeAt != null) {
        if (reminder.isRecurring) {
          // Schedule multiple occurrences for recurring reminders
          await _scheduleRecurringNotifications(reminder);
        } else {
          // Schedule single notification using native AlarmManager
          await AlarmService.scheduleExactAlarm(
            id: reminder.id.hashCode,
            title: 'Reminder',
            body: reminder.text,
            scheduledTime: reminder.timeAt!,
            payload: reminder.id,
          );
          debugPrint(
              'Scheduled alarm for reminder ${reminder.id} at ${reminder.timeAt} (id=${reminder.id.hashCode})',);
        }
      }

      // Reload reminders
      await loadReminders();

      return id;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Create reminder (manual)
  Future<String?> createReminder(Reminder reminder) async {
    try {
      debugPrint('');
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('📝 CREATING NEW REMINDER');
      debugPrint('═══════════════════════════════════════════════════');
      
      // Debug: Log reminder details before saving
      debugPrint('📋 Reminder Details:');
      debugPrint('   ID: ${reminder.id}');
      debugPrint('   Text: "${reminder.text}"');
      debugPrint('   TimeAt: ${reminder.timeAt}');
      debugPrint('   Enabled: ${reminder.enabled}');
      debugPrint('   IsRecurring: ${reminder.isRecurring}');
      debugPrint('   RepeatInterval: ${reminder.repeatInterval}');
      debugPrint('   RepeatUnit: ${reminder.repeatUnit}');
      debugPrint('   RepeatOnDays: ${reminder.repeatOnDays}');
      debugPrint('   RepeatEndDate: ${reminder.repeatEndDate}');
      debugPrint('   KeepRemindingUntilCompleted: ${reminder.keepRemindingUntilCompleted}');

      debugPrint('');
      debugPrint('💾 Saving reminder to database...');
      final id = await _reminderRepository.createReminder(reminder);
      debugPrint('✅ Reminder saved with ID: $id');
      debugPrint('');

      // Check exact alarm permission (Android only, iOS always returns true)
      debugPrint('🔐 Checking exact alarm permission...');
      final hasPermission = await PermissionService().hasExactAlarmPermission();
      if (!hasPermission) {
        debugPrint('⚠️⚠️⚠️ WARNING: EXACT ALARM PERMISSION NOT GRANTED! ⚠️⚠️⚠️');
        debugPrint('   Notifications may not work reliably!');
        debugPrint('   User needs to grant permission:');
        debugPrint('   Settings → Apps → Awarely → Alarms & Reminders');
      } else {
        debugPrint('✅ Exact alarm permission granted (or not required on this platform)');
      }
      debugPrint('');

      // Apply smart timing if enabled
      DateTime? finalTimeAt = reminder.timeAt;
      if (reminder.useSmartTiming && reminder.timeAt != null) {
        debugPrint('');
        debugPrint('🧠 Applying Smart Timing...');
        final adjustedTime = await _learningService.getAdjustedTime(reminder.id, reminder.timeAt!);
        if (adjustedTime != null) {
          debugPrint('   Original time: ${reminder.timeAt}');
          debugPrint('   Adjusted time: $adjustedTime');
          finalTimeAt = adjustedTime;
          
          // Update reminder with adjusted time
          final updatedReminder = reminder.copyWith(timeAt: adjustedTime);
          await _reminderRepository.updateReminder(updatedReminder);
        } else {
          debugPrint('   No learning pattern yet - using original time');
        }
        debugPrint('');
      }

      // Schedule notifications
      if (finalTimeAt != null) {
        debugPrint('📅 TimeAt is set, scheduling notifications...');
        debugPrint('   TimeAt value: $finalTimeAt');
        
        // Create reminder with adjusted time if smart timing was applied
        final reminderToSchedule = finalTimeAt != reminder.timeAt
            ? reminder.copyWith(timeAt: finalTimeAt)
            : reminder;
        
        if (reminderToSchedule.isRecurring) {
          debugPrint('   Type: Recurring reminder');
          debugPrint('   Will call _scheduleRecurringNotifications()');
          // Schedule multiple occurrences for recurring reminders
          await _scheduleRecurringNotifications(reminderToSchedule);
        } else {
          debugPrint('   Type: One-time reminder');
          // Schedule single notification for one-time reminders
          final now = DateTime.now();
          final scheduleTime = finalTimeAt;

          // Validate time is in future
          if (scheduleTime.isAfter(now)) {
            debugPrint('📅 Creating reminder: ${reminder.text}');
            debugPrint('🕐 Scheduled for: $scheduleTime');
            debugPrint('⏰ Time from now: ${scheduleTime.difference(now)}');

            await AlarmService.scheduleExactAlarm(
              id: reminder.id.hashCode,
              title: 'Reminder',
              body: reminder.text,
              scheduledTime: scheduleTime,
              payload: reminder.id,
            );

            debugPrint('✅ Alarm scheduled');
      } else {
        debugPrint('⚠️⚠️⚠️ WARNING: SCHEDULED TIME IS IN THE PAST! ⚠️⚠️⚠️');
        debugPrint('   Scheduled: $scheduleTime');
        debugPrint('   Now: $now');
        debugPrint('   Difference: ${scheduleTime.difference(now)}');
        debugPrint('   Notification will NOT be scheduled');
      }
        }
      } else {
        debugPrint('⚠️ TimeAt is NULL - no notification will be scheduled');
        debugPrint('   Reminder will be saved but won\'t trigger');
      }

      // Learn from this reminder after creation (async, don't wait)
      if (reminder.useSmartTiming) {
        _learningService.learnOptimalTiming(reminder.id).then((result) {
          if (result != null && kDebugMode) {
            debugPrint('🧠 Learned optimal timing for "${reminder.text}": ${result['optimalHour']}:00');
          }
        });
      }

      debugPrint('');
      debugPrint('📥 Reloading reminders list...');
      await loadReminders();
      debugPrint('✅ Reminder creation complete!');
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('');
      return id;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error creating reminder: $e');
      notifyListeners();
      return null;
    }
  }

  /// Schedule multiple notifications for recurring reminders
  /// Schedules next 24 hours (or up to 50 occurrences, whichever is less)
  Future<void> _scheduleRecurringNotifications(Reminder reminder) async {
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('🔁 SCHEDULING RECURRING REMINDER');
    debugPrint('═══════════════════════════════════════════════════');
    
    if (!reminder.isRecurring) {
      debugPrint('❌ Reminder is not marked as recurring (isRecurring=false)');
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('');
      return;
    }
    
    if (reminder.repeatInterval == null) {
      debugPrint('❌ Repeat interval is null');
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('');
      return;
    }
    
    if (reminder.repeatUnit == null) {
      debugPrint('❌ Repeat unit is null');
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('');
      return;
    }

    debugPrint('📝 Reminder Details:');
    debugPrint('   ID: ${reminder.id}');
    debugPrint('   Text: ${reminder.text}');
    debugPrint('   Enabled: ${reminder.enabled}');
    debugPrint('   IsRecurring: ${reminder.isRecurring}');
    debugPrint('   RepeatInterval: ${reminder.repeatInterval}');
    debugPrint('   RepeatUnit: ${reminder.repeatUnit}');
    debugPrint('   TimeAt: ${reminder.timeAt}');
    debugPrint('   RepeatOnDays: ${reminder.repeatOnDays}');
    debugPrint('   RepeatEndDate: ${reminder.repeatEndDate}');

    // Calculate interval duration
    Duration interval;
    switch (reminder.repeatUnit) {
      case 'minutes':
        interval = Duration(minutes: reminder.repeatInterval!);
        debugPrint('   Calculated interval: ${interval.inMinutes} minutes');
        break;
      case 'hours':
        interval = Duration(hours: reminder.repeatInterval!);
        debugPrint('   Calculated interval: ${interval.inHours} hours');
        break;
      case 'days':
        interval = Duration(days: reminder.repeatInterval!);
        debugPrint('   Calculated interval: ${interval.inDays} days');
        break;
      case 'weeks':
        interval = Duration(days: reminder.repeatInterval! * 7);
        debugPrint('   Calculated interval: ${interval.inDays} days (${reminder.repeatInterval} weeks)');
        break;
      default:
        interval = Duration(minutes: reminder.repeatInterval!);
        debugPrint('   Calculated interval: ${interval.inMinutes} minutes (default)');
    }

    // Schedule up to 50 occurrences or 24 hours, whichever comes first
    final now = DateTime.now();
    final maxTime = now.add(const Duration(hours: 24));
    int count = 0;
    const maxOccurrences = 50;

    // Determine starting time for first occurrence
    DateTime nextOccurrence;
    if (reminder.timeAt != null) {
      // Check if the parsed time is still valid
      final timeUntilFirst = reminder.timeAt!.difference(now);
      debugPrint('   Parsed timeAt: ${reminder.timeAt}');
      debugPrint('   Time until first: ${timeUntilFirst.inSeconds} seconds');
      debugPrint('   Current time: $now');
      
      if (timeUntilFirst.isNegative) {
        // Time is in the past - start immediately (1 second) then continue
        debugPrint('⏰ Parsed time is in past, starting immediately then continuing');
        nextOccurrence = now.add(const Duration(seconds: 1));
      } else if (timeUntilFirst.inSeconds < 1) {
        // Less than 1 second - bump to 1 second minimum (AlarmService requirement)
        debugPrint('⏰ Time too close (< 1s), setting to 1 second');
        nextOccurrence = now.add(const Duration(seconds: 1));
      } else {
        // Use the parsed time as-is (could be 10 seconds for "starting now")
        nextOccurrence = reminder.timeAt!;
        debugPrint('✅ Using parsed time: $nextOccurrence');
      }
    } else {
      // No time specified - start after interval
      debugPrint('⏰ No timeAt specified, starting after interval');
      nextOccurrence = now.add(const Duration(seconds: 1)).add(interval);
    }

    // Final safety check: ensure first occurrence is at least 1 second in the future
    final finalCheck = nextOccurrence.difference(now);
    if (finalCheck.inSeconds < 1) {
      debugPrint('⏰ Final adjustment: first occurrence was too close, setting to 1 second');
      nextOccurrence = now.add(const Duration(seconds: 1));
    }

    debugPrint('');
    debugPrint('📅 SCHEDULING OCCURRENCES:');
    debugPrint('   First occurrence: $nextOccurrence');
    debugPrint('   Time from now: ${nextOccurrence.difference(now).inSeconds} seconds');
    debugPrint('   Max time window: $maxTime (24 hours from now)');
    debugPrint('   Max occurrences: $maxOccurrences');
    debugPrint('');

    while (nextOccurrence.isBefore(maxTime) && count < maxOccurrences) {
      final timeUntil = nextOccurrence.difference(now);
      
      debugPrint('   [Occurrence ${count + 1}] Processing...');
      debugPrint('      Scheduled time: $nextOccurrence');
      debugPrint('      Time from now: ${timeUntil.inSeconds} seconds');
      
      // Ensure each occurrence is at least 1 second in the future
      if (nextOccurrence.isAfter(now.add(const Duration(seconds: 1)))) {
        // Use unique ID for each occurrence: base hash + occurrence index
        final notificationId = reminder.id.hashCode + count;
        debugPrint('      Notification ID: $notificationId (base: ${reminder.id.hashCode} + $count)');

        debugPrint('      📤 Calling AlarmService.scheduleExactAlarm...');
        final scheduled = await AlarmService.scheduleExactAlarm(
          id: notificationId,
          title: 'Reminder',
          body: reminder.text,
          scheduledTime: nextOccurrence,
          payload: reminder.id,
        );

        if (scheduled) {
          debugPrint('      ✅ Occurrence ${count + 1} scheduled successfully!');
          count++;
        } else {
          debugPrint('      ❌ FAILED to schedule occurrence ${count + 1}');
          debugPrint('         This occurrence will be skipped.');
          // Don't increment count if scheduling failed
        }
      } else {
        debugPrint('      ⏭️ Skipping occurrence ${count + 1} (too soon: ${timeUntil.inSeconds}s)');
      }

      debugPrint('');
      nextOccurrence = nextOccurrence.add(interval);
    }

    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('📊 SCHEDULING SUMMARY:');
    debugPrint('   Total occurrences scheduled: $count');
    debugPrint('   Reminder ID: ${reminder.id}');
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('');
    
    if (count == 0) {
      debugPrint('⚠️⚠️⚠️ WARNING: NO OCCURRENCES WERE SCHEDULED! ⚠️⚠️⚠️');
      debugPrint('');
      debugPrint('🔍 DIAGNOSTIC CHECKLIST:');
      debugPrint('   1. Is timeAt set? ${reminder.timeAt != null ? "✅ Yes" : "❌ No"}');
      debugPrint('   2. Is reminder enabled? ${reminder.enabled ? "✅ Yes" : "❌ No"}');
      debugPrint('   3. Is repeatInterval set? ${reminder.repeatInterval != null ? "✅ Yes (${reminder.repeatInterval})" : "❌ No"}');
      debugPrint('   4. Is repeatUnit set? ${reminder.repeatUnit != null ? "✅ Yes (${reminder.repeatUnit})" : "❌ No"}');
      debugPrint('   5. Check exact alarm permission in app settings');
      debugPrint('   6. Check battery optimization is disabled');
      debugPrint('');
    } else {
      debugPrint('✅ Successfully scheduled $count occurrences');
      debugPrint('   First notification should appear in ${nextOccurrence.subtract(interval).difference(now).inSeconds} seconds');
    }
    debugPrint('');
  }
  
  /// Check if exact alarm permission is granted
  Future<bool> checkExactAlarmPermission() async {
    try {
      final permissionService = PermissionService();
      return await permissionService.hasExactAlarmPermission();
    } catch (e) {
      debugPrint('Error checking exact alarm permission: $e');
      return false;
    }
  }

  /// Update reminder
  Future<bool> updateReminder(Reminder reminder) async {
    try {
      await _reminderRepository.updateReminder(reminder);
      await loadReminders();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete reminder
  Future<bool> deleteReminder(String id) async {
    try {
      // Find the reminder to check if it's recurring
      final reminder = _reminders.firstWhere((r) => r.id == id);

      // Cancel all alarms for this reminder
      if (reminder.isRecurring) {
        // Cancel all 50 occurrences
        for (int i = 0; i < 50; i++) {
          final notificationId = reminder.id.hashCode + i;
          await AlarmService.cancelAlarm(notificationId);
        }
        debugPrint('🗑️ Cancelled 50 recurring alarms for reminder $id');
      } else {
        // Cancel single alarm
        await AlarmService.cancelAlarm(id.hashCode);
        debugPrint('🗑️ Cancelled alarm for reminder $id');
      }

      await _reminderRepository.deleteReminder(id);
      await loadReminders();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Toggle reminder enabled state
  Future<bool> toggleReminder(String id, bool enabled) async {
    try {
      final reminder = _reminders.firstWhere((r) => r.id == id);

      // Debug: Log reminder details
      debugPrint(
          '🔄 Toggling reminder $id to ${enabled ? "enabled" : "disabled"}',);
      debugPrint('   Text: ${reminder.text}');
      debugPrint('   IsRecurring: ${reminder.isRecurring}');
      debugPrint('   RepeatInterval: ${reminder.repeatInterval}');
      debugPrint('   RepeatUnit: ${reminder.repeatUnit}');

      await _reminderRepository.toggleReminder(id, enabled);

      if (!enabled) {
        // Cancel all alarms for this reminder
        if (reminder.isRecurring) {
          // Cancel all 50 occurrences
          debugPrint('   Cancelling 50 recurring alarms...');
          for (int i = 0; i < 50; i++) {
            final notificationId = reminder.id.hashCode + i;
            await AlarmService.cancelAlarm(notificationId);
          }
          debugPrint('✅ Cancelled 50 recurring alarms for reminder $id');
        } else {
          debugPrint('   Cancelling single alarm...');
          await AlarmService.cancelAlarm(id.hashCode);
          debugPrint('✅ Cancelled single alarm for reminder $id');
        }
      } else {
        // Reschedule if time-based
        if (reminder.timeAt != null) {
          if (reminder.isRecurring) {
            debugPrint('   Rescheduling recurring notifications...');
            await _scheduleRecurringNotifications(reminder);
          } else {
            debugPrint('   Rescheduling single notification...');
            await AlarmService.scheduleExactAlarm(
              id: reminder.id.hashCode,
              title: 'Reminder',
              body: reminder.text,
              scheduledTime: reminder.timeAt!,
              payload: reminder.id,
            );
          }
        }
      }

      await loadReminders();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Load statistics
  Future<void> loadStatistics() async {
    try {
      _statistics = await _reminderRepository.getStatistics();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
