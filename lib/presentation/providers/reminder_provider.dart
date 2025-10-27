import 'package:flutter/foundation.dart';

import '../../data/models/reminder.dart';
import '../../data/repositories/reminder_repository.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/nlu_parser.dart';

/// Reminder state management provider
class ReminderProvider with ChangeNotifier {
  final ReminderRepository _reminderRepository;
  final NotificationService _notificationService;

  List<Reminder> _reminders = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _statistics;

  ReminderProvider({
    required ReminderRepository reminderRepository,
    required NotificationService notificationService,
  }) : _reminderRepository = reminderRepository,
       _notificationService = notificationService;

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

      // Schedule notification if time-based
      if (reminder.timeAt != null) {
        await _notificationService.scheduleNotification(
          id: reminder.id.hashCode,
          title: 'Reminder',
          body: reminder.text,
          scheduledTime: reminder.timeAt!,
          payload: reminder.id,
        );
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
      await loadReminders();
      return id;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
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
      await _reminderRepository.deleteReminder(id);
      await _notificationService.cancelNotification(id.hashCode);
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
        await _notificationService.cancelNotification(id.hashCode);
      } else {
        // Reschedule if time-based
        final reminder = _reminders.firstWhere((r) => r.id == id);
        if (reminder.timeAt != null) {
          await _notificationService.scheduleNotification(
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
