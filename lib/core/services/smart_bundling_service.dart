import 'package:geolocator/geolocator.dart';

import '../../data/models/reminder.dart';

/// Service for intelligently grouping reminders by context
class SmartBundlingService {
  /// Group reminders by current context (location, time, category)
  static Map<String, List<Reminder>> groupByContext(
    List<Reminder> reminders, {
    Position? currentPosition,
    String? currentWifiSsid,
    DateTime? currentTime,
  }) {
    final groups = <String, List<Reminder>>{
      'Relevant Now': [],
      'Time-Based': [],
      'Location-Based': [],
      'Recurring': [],
      'Other': [],
    };

    final now = currentTime ?? DateTime.now();

    for (var reminder in reminders) {
      if (!reminder.enabled) continue;

      // Check if reminder is relevant right now
      bool isRelevantNow = false;

      // Check location-based relevance
      if (currentPosition != null &&
          reminder.geofenceLat != null &&
          reminder.geofenceLng != null) {
        final distance = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          reminder.geofenceLat!,
          reminder.geofenceLng!,
        );

        final radius = reminder.geofenceRadius ?? 100.0;
        if (distance <= radius) {
          isRelevantNow = true;
          groups['Relevant Now']!.add(reminder);
          continue;
        }
      }

      // Check WiFi-based relevance
      if (currentWifiSsid != null && reminder.wifiSsid != null) {
        if (currentWifiSsid == reminder.wifiSsid) {
          isRelevantNow = true;
          groups['Relevant Now']!.add(reminder);
          continue;
        }
      }

      // Check time-based relevance (within next hour)
      if (reminder.timeAt != null && !isRelevantNow) {
        final timeDiff = reminder.timeAt!.difference(now).inMinutes;
        if (timeDiff >= 0 && timeDiff <= 60) {
          isRelevantNow = true;
          groups['Relevant Now']!.add(reminder);
          continue;
        }
        
        // Group upcoming time-based reminders
        if (timeDiff > 0) {
          groups['Time-Based']!.add(reminder);
          continue;
        }
      }

      // Group by type
      if (reminder.isRecurring) {
        groups['Recurring']!.add(reminder);
      } else if (reminder.geofenceId != null) {
        groups['Location-Based']!.add(reminder);
      } else {
        groups['Other']!.add(reminder);
      }
    }

    // Remove empty groups
    groups.removeWhere((key, value) => value.isEmpty);

    return groups;
  }

  /// Get reminders relevant to current context
  static List<Reminder> getRelevantReminders(
    List<Reminder> allReminders, {
    Position? currentPosition,
    String? currentWifiSsid,
    DateTime? currentTime,
  }) {
    final groups = groupByContext(
      allReminders,
      currentPosition: currentPosition,
      currentWifiSsid: currentWifiSsid,
      currentTime: currentTime,
    );

    return groups['Relevant Now'] ?? [];
  }

  /// Group reminders by location
  static Map<String, List<Reminder>> groupByLocation(List<Reminder> reminders) {
    final groups = <String, List<Reminder>>{};

    for (var reminder in reminders) {
      final locationKey = reminder.geofenceId ?? 'Other';
      groups.putIfAbsent(locationKey, () => []).add(reminder);
    }

    return groups;
  }

  /// Get context description for a group
  static String getContextDescription(String groupName, List<Reminder> reminders) {
    if (reminders.isEmpty) return '';

    switch (groupName) {
      case 'Relevant Now':
        if (reminders.length == 1) {
          return '1 task ready';
        }
        return '${reminders.length} tasks ready';
      case 'Time-Based':
        return '${reminders.length} upcoming';
      case 'Location-Based':
        return '${reminders.length} location-based';
      case 'Recurring':
        return '${reminders.length} recurring';
      default:
        return '${reminders.length} tasks';
    }
  }

  /// Get icon for context group
  static String getContextIcon(String groupName) {
    switch (groupName) {
      case 'Relevant Now':
        return '🔔';
      case 'Time-Based':
        return '⏰';
      case 'Location-Based':
        return '📍';
      case 'Recurring':
        return '🔄';
      default:
        return '📌';
    }
  }
}

