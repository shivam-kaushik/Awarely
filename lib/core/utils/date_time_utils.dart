import 'package:intl/intl.dart';

/// Utility class for date and time operations
class DateTimeUtils {
  /// Format DateTime to human-readable string
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }

  /// Format time only
  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  /// Format date only
  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  /// Get relative time string (e.g., "2 hours ago")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }

  /// Get time until string (e.g., "in 2 hours")
  static String getTimeUntil(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    }

    if (difference.inMinutes < 60) {
      return 'in ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'in ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'in ${difference.inDays}d';
    } else {
      return formatDate(dateTime);
    }
  }

  /// Check if date is today
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Parse time string (e.g., "8 PM", "20:00") to DateTime
  static DateTime? parseTime(String timeStr) {
    try {
      // Try various formats
      final formats = ['h:mm a', 'hh:mm a', 'h a', 'HH:mm', 'H:mm'];

      for (var format in formats) {
        try {
          final parsedTime = DateFormat(format).parse(timeStr);
          final now = DateTime.now();
          return DateTime(
            now.year,
            now.month,
            now.day,
            parsedTime.hour,
            parsedTime.minute,
          );
        } catch (_) {
          continue;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Calculate next occurrence for recurring reminder
  static DateTime? calculateNextOccurrence(
    DateTime currentTime,
    int interval,
    String unit, {
    List<int>? repeatOnDays,
    DateTime? timeAt,
  }) {
    Duration duration;

    switch (unit) {
      case 'minutes':
        duration = Duration(minutes: interval);
        break;
      case 'hours':
        duration = Duration(hours: interval);
        break;
      case 'days':
        duration = Duration(days: interval);
        break;
      case 'weeks':
        duration = Duration(days: interval * 7);
        break;
      case 'months':
        duration = Duration(days: interval * 30); // Approximate
        break;
      default:
        duration = Duration(minutes: interval);
    }

    // If we have specific days of week and a time, calculate next matching day
    if (repeatOnDays != null && repeatOnDays.isNotEmpty && timeAt != null) {
      final currentDay = currentTime.weekday; // 1=Monday, 7=Sunday
      
      // Find next matching day
      for (var day in repeatOnDays) {
        int daysToAdd = day - currentDay;
        if (daysToAdd < 0) {
          daysToAdd += 7; // Next week
        } else if (daysToAdd == 0 && 
                   currentTime.hour * 60 + currentTime.minute >= timeAt.hour * 60 + timeAt.minute) {
          daysToAdd = 7; // Same day but time has passed, move to next week
        }
        
        final nextDate = currentTime.add(Duration(days: daysToAdd));
        return DateTime(
          nextDate.year,
          nextDate.month,
          nextDate.day,
          timeAt.hour,
          timeAt.minute,
          0,
        );
      }
    }

    // Simple interval-based recurrence
    return currentTime.add(duration);
  }
}
