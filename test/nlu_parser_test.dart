import 'package:flutter_test/flutter_test.dart';
import 'package:awarely/core/services/nlu_parser.dart';

void main() {
  group('NLU Parser Tests', () {
    test('Parses time-based reminder correctly', () {
      const input = 'Remind me to take medicine at 8 PM';
      final reminder = NLUParser.parseReminderText(input);

      expect(reminder.text, 'Take medicine');
      expect(reminder.timeAt, isNotNull);
      expect(reminder.timeAt?.hour, 20);
    });

    test('Parses location + leaving context', () {
      const input = 'Remind me to turn off AC when leaving home';
      final reminder = NLUParser.parseReminderText(input);

      expect(reminder.text, contains('Turn off AC'));
      expect(reminder.onLeaveContext, true);
      expect(reminder.geofenceId, 'home');
    });

    test('Parses location + arriving context', () {
      const input = 'Remind me to call Mom when I arrive at work';
      final reminder = NLUParser.parseReminderText(input);

      expect(reminder.text, contains('Call Mom'));
      expect(reminder.onArriveContext, true);
      expect(reminder.geofenceId, 'work');
    });

    test('Validates valid intent', () {
      expect(NLUParser.hasValidIntent('Take medicine'), true);
      expect(NLUParser.hasValidIntent('Call Mom'), true);
      expect(NLUParser.hasValidIntent('a'), false);
      expect(NLUParser.hasValidIntent(''), false);
    });

    test('Provides relevant suggestions', () {
      final suggestions = NLUParser.getSuggestions('');
      expect(suggestions.isNotEmpty, true);
      expect(suggestions.length, greaterThan(3));
    });

    test('Cleans reminder text correctly', () {
      const input = 'Remind me to carry keys when leaving home at 8 AM';
      final reminder = NLUParser.parseReminderText(input);

      expect(reminder.text, isNot(contains('remind me')));
      expect(reminder.text, isNot(contains('when leaving')));
      expect(reminder.text[0], equals(reminder.text[0].toUpperCase()));
    });
  });
}
