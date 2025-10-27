import 'package:flutter/foundation.dart';

import '../../data/models/reminder.dart';
import '../../data/repositories/reminder_repository.dart';
import '../../core/services/alarm_service.dart';
import '../../core/services/nlu_parser.dart';

/// Reminder state management provider
class ReminderProvider with ChangeNotifier {
  final ReminderRepository _reminderRepository;

  List<Reminder> _reminders = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _statistics;

  ReminderProvider({
    required ReminderRepository reminderRepository,
  }) : _reminderRepository = reminderRepository;

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
              'Scheduled alarm for reminder ${reminder.id} at ${reminder.timeAt} (id=${reminder.id.hashCode})');
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
      final id = await _reminderRepository.createReminder(reminder);

      // Schedule notifications
      if (reminder.timeAt != null) {
        if (reminder.isRecurring) {
          // Schedule multiple occurrences for recurring reminders
          await _scheduleRecurringNotifications(reminder);
        } else {
          // Schedule single notification for one-time reminders
          final now = DateTime.now();
          final scheduleTime = reminder.timeAt!;

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
            debugPrint('⚠️ Warning: Scheduled time is in the past!');
          }
        }
      }

      await loadReminders();
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
    if (!reminder.isRecurring ||
        reminder.repeatInterval == null ||
        reminder.repeatUnit == null) {
      return;
    }

    debugPrint('🔁 Creating recurring reminder: ${reminder.text}');
    debugPrint('⏰ Every ${reminder.repeatInterval} ${reminder.repeatUnit}');

    // Calculate interval duration
    Duration interval;
    switch (reminder.repeatUnit) {
      case 'minutes':
        interval = Duration(minutes: reminder.repeatInterval!);
        break;
      case 'hours':
        interval = Duration(hours: reminder.repeatInterval!);
        break;
      case 'days':
        interval = Duration(days: reminder.repeatInterval!);
        break;
      case 'weeks':
        interval = Duration(days: reminder.repeatInterval! * 7);
        break;
      default:
        interval = Duration(minutes: reminder.repeatInterval!);
    }

    // Schedule up to 50 occurrences or 24 hours, whichever comes first
    final now = DateTime.now();
    final maxTime = now.add(const Duration(hours: 24));
    int count = 0;
    const maxOccurrences = 50;

    DateTime nextOccurrence = reminder.timeAt ?? now.add(interval);

    while (nextOccurrence.isBefore(maxTime) && count < maxOccurrences) {
      if (nextOccurrence.isAfter(now)) {
        // Use unique ID for each occurrence: base hash + occurrence index
        final notificationId = reminder.id.hashCode + count;

        await AlarmService.scheduleExactAlarm(
          id: notificationId,
          title: 'Reminder',
          body: reminder.text,
          scheduledTime: nextOccurrence,
          payload: reminder.id,
        );

        debugPrint(
            '  📅 Scheduled occurrence ${count + 1}: $nextOccurrence (id: $notificationId)');
        count++;
      }

      nextOccurrence = nextOccurrence.add(interval);
    }

    debugPrint('✅ Scheduled $count occurrences for recurring reminder');
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
      await _reminderRepository.deleteReminder(id);
      await AlarmService.cancelAlarm(id.hashCode);
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
      await _reminderRepository.toggleReminder(id, enabled);

      if (!enabled) {
        await AlarmService.cancelAlarm(id.hashCode);
      } else {
        // Reschedule if time-based
        final reminder = _reminders.firstWhere((r) => r.id == id);
        if (reminder.timeAt != null) {
          await AlarmService.scheduleExactAlarm(
            id: reminder.id.hashCode,
            title: 'Reminder',
            body: reminder.text,
            scheduledTime: reminder.timeAt!,
            payload: reminder.id,
          );
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
