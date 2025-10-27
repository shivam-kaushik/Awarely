import '../../core/constants/app_constants.dart';
import '../../core/utils/date_time_utils.dart';
import '../../data/models/reminder.dart';

/// Natural Language Understanding parser for reminder text
/// Extracts intent, context, and parameters from user input
class NLUParser {
  /// Parse reminder text and extract context information
  /// Returns a Reminder object with parsed fields
  static Reminder parseReminderText(String text) {
    final lowerText = text.toLowerCase();

    DateTime? timeAt;
    String? locationName;
    bool onLeaveContext = false;
    bool onArriveContext = false;

    // Extract time context
    timeAt = _extractTime(lowerText);

    // Extract location and movement context
    final locationInfo = _extractLocation(lowerText);
    locationName = locationInfo['location'];
    onLeaveContext = locationInfo['leaving'] ?? false;
    onArriveContext = locationInfo['arriving'] ?? false;

    // Clean the reminder text (remove context phrases)
    final cleanText = _cleanReminderText(text);

    return Reminder(
      text: cleanText,
      timeAt: timeAt,
      geofenceId: locationName,
      onLeaveContext: onLeaveContext,
      onArriveContext: onArriveContext,
    );
  }

  /// Extract time from text
  /// Examples: "at 8 PM", "at 8:30", "by 3:00 PM"
  static DateTime? _extractTime(String text) {
    // Pattern: "at|by|before|after <time>"
    final timePatterns = [
      RegExp(
        r'(?:at|by|before|after)\s+(\d{1,2}:\d{2}\s*(?:am|pm)?)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:at|by|before|after)\s+(\d{1,2}\s*(?:am|pm))',
        caseSensitive: false,
      ),
      RegExp(r'(\d{1,2}:\d{2}\s*(?:am|pm)?)', caseSensitive: false),
      RegExp(r'(\d{1,2}\s*(?:am|pm))', caseSensitive: false),
    ];

    for (var pattern in timePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final timeStr = match.group(1);
        if (timeStr != null) {
          final parsedTime = DateTimeUtils.parseTime(timeStr);
          if (parsedTime != null) {
            return parsedTime;
          }
        }
      }
    }

    // Named times
    if (text.contains('morning')) {
      return DateTime.now().copyWith(hour: 8, minute: 0, second: 0);
    } else if (text.contains('afternoon')) {
      return DateTime.now().copyWith(hour: 14, minute: 0, second: 0);
    } else if (text.contains('evening')) {
      return DateTime.now().copyWith(hour: 18, minute: 0, second: 0);
    } else if (text.contains('night')) {
      return DateTime.now().copyWith(hour: 21, minute: 0, second: 0);
    } else if (text.contains('wake up') || text.contains('waking up')) {
      return DateTime.now().copyWith(hour: 7, minute: 0, second: 0);
    } else if (text.contains('bedtime') || text.contains('sleep')) {
      return DateTime.now().copyWith(hour: 22, minute: 0, second: 0);
    }

    return null;
  }

  /// Extract location and movement context
  static Map<String, dynamic> _extractLocation(String text) {
    String? location;
    bool leaving = false;
    bool arriving = false;

    // Check for leaving keywords
    for (var keyword in AppConstants.leaveKeywords) {
      if (text.contains(keyword)) {
        leaving = true;
        break;
      }
    }

    // Check for arriving keywords
    for (var keyword in AppConstants.arriveKeywords) {
      if (text.contains(keyword)) {
        arriving = true;
        break;
      }
    }

    // Extract location name
    for (var locationKeyword in AppConstants.locationKeywords) {
      if (text.contains(locationKeyword)) {
        location = locationKeyword;
        break;
      }
    }

    // Custom location patterns
    final customLocationPattern = RegExp(
      r'(?:at|to|from)\s+([a-z\s]+?)(?:\s+at|\s+when|\s+by|$)',
      caseSensitive: false,
    );
    final match = customLocationPattern.firstMatch(text);
    if (match != null && location == null) {
      location = match.group(1)?.trim();
    }

    return {'location': location, 'leaving': leaving, 'arriving': arriving};
  }

  /// Clean reminder text by removing context phrases
  static String _cleanReminderText(String text) {
    String cleaned = text;

    // Remove time phrases
    cleaned = cleaned.replaceAll(
      RegExp(
        r'\s*(?:at|by|before|after)\s+\d{1,2}(?::\d{2})?\s*(?:am|pm)?\s*',
        caseSensitive: false,
      ),
      ' ',
    );

    // Remove location phrases
    cleaned = cleaned.replaceAll(
      RegExp(
        r'\s*(?:when|while)\s+(?:leaving|arriving|at|to|from)\s+\w+\s*',
        caseSensitive: false,
      ),
      ' ',
    );

    // Remove "remind me to" prefix
    cleaned = cleaned.replaceAll(
      RegExp(r'^\s*remind\s+me\s+to\s+', caseSensitive: false),
      '',
    );

    // Clean up extra spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Capitalize first letter
    if (cleaned.isNotEmpty) {
      cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
    }

    return cleaned.isEmpty ? text : cleaned;
  }

  /// Validate if text contains actionable intent
  static bool hasValidIntent(String text) {
    if (text.trim().length < 3) return false;

    // Check for action verbs
    final actionVerbs = [
      'take',
      'carry',
      'bring',
      'call',
      'text',
      'send',
      'buy',
      'pick',
      'drop',
      'turn',
      'check',
      'drink',
      'eat',
      'exercise',
      'study',
      'read',
      'write',
      'clean',
      'wash',
      'feed',
      'water',
    ];

    final lowerText = text.toLowerCase();
    for (var verb in actionVerbs) {
      if (lowerText.contains(verb)) return true;
    }

    // If no specific verb, still valid if it's a reasonable length
    return text.trim().split(' ').length >= 2;
  }

  /// Get suggested reminders based on input
  static List<String> getSuggestions(String input) {
    if (input.isEmpty) {
      return AppConstants.samplePhrases;
    }

    // Filter sample phrases that match input
    final lowerInput = input.toLowerCase();
    return AppConstants.samplePhrases
        .where((phrase) => phrase.toLowerCase().contains(lowerInput))
        .toList();
  }
}
