import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../providers/reminder_provider.dart';
import '../../core/services/nlu_parser.dart';
import '../../core/services/gpt_nlu_service.dart';
import '../../core/services/home_detection_service.dart';
import '../../data/models/reminder.dart';
import '../../core/services/permission_service.dart';
import '../widgets/smart_reminder_dialog.dart';
import 'home_setup_screen.dart';

/// Add reminder screen with natural language input
class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isCreating = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _createReminder() async {
    final text = _textController.text.trim();

    if (text.isEmpty) {
      // Show smart dialog for manual entry
      _showSmartDialog();
      return;
    }

    // Check exact alarm permission first
    final permissionService = PermissionService();
    final hasExactAlarm = await permissionService.ensureExactAlarmPermission(
      context,
      rationale:
          'Exact alarms are needed to deliver reminders at the right time.',
    );

    if (!hasExactAlarm) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exact alarm permission is required')),
        );
      }
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // First try GPT-powered parsing
      final gptParsed = await GptNluService.parseReminderText(text);

      if (gptParsed != null) {
        debugPrint('✅ GPT parsed: $gptParsed');

        // Check if location-based reminder needs home setup
        if ((gptParsed.onLeave || gptParsed.onArrive) &&
            gptParsed.locationContext == 'home') {
          final homeService = HomeDetectionService();
          final status = await homeService.getSetupStatus();

          if (!(status['isFullySetup'] as bool)) {
            // Prompt user to setup home
            final shouldSetup = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('🏠 Home Setup Required'),
                content: const Text(
                  'This reminder needs to know your home location. Would you like to set it up now?\n\n'
                  'Quick setup takes just 2 steps:\n'
                  '✓ Add your home WiFi\n'
                  '✓ Set your GPS location',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Skip'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Setup Now'),
                  ),
                ],
              ),
            );

            if (shouldSetup == true && mounted) {
              setState(() => _isCreating = false);
              // Navigate to home setup
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeSetupScreen(),
                ),
              );
              return;
            }
          }
        }

        // Convert time range strings to DateTime
        DateTime? timeRangeStart;
        DateTime? timeRangeEnd;

        if (gptParsed.timeRangeStart != null) {
          final parts = gptParsed.timeRangeStart!.split(':');
          final now = DateTime.now();
          timeRangeStart = DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        }

        if (gptParsed.timeRangeEnd != null) {
          final parts = gptParsed.timeRangeEnd!.split(':');
          final now = DateTime.now();
          timeRangeEnd = DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        }

        // Prepare optional location suggestion (don't auto-enable)
        Map<String, dynamic>? locationSuggestion;
        if (gptParsed.locationContext == 'home' &&
            (gptParsed.onLeave || gptParsed.onArrive)) {
          final homeService = HomeDetectionService();
          final homeLocation = await homeService.getHomeLocation();

          if (homeLocation != null) {
            locationSuggestion = {
              'context': 'home',
              'latitude': homeLocation.latitude,
              'longitude': homeLocation.longitude,
              'radius': homeLocation.radius,
            };

            debugPrint(
                '✅ Home location available (suggestion): $locationSuggestion');
          } else {
            debugPrint('⚠️ Home location not configured (no suggestion)');
          }
        }

        // Convert parsed data to Reminder object
        final reminder = Reminder(
          text: gptParsed.title,
          timeAt: gptParsed.dateTime,
          priority: gptParsed.priority ?? ReminderPriority.medium,
          category: gptParsed.category ?? ReminderCategory.other,
          repeatInterval: gptParsed.repeatInterval,
          repeatUnit: gptParsed.repeatUnit,
          repeatEndDate: gptParsed.repeatEndDate,
          repeatOnDays: gptParsed.repeatOnDays,
          timeRangeStart: timeRangeStart,
          timeRangeEnd: timeRangeEnd,
          preferredTimeOfDay: gptParsed.preferredTimeOfDay,
          // Do not auto-set geofence here. Let user enable it in dialog.
          onLeaveContext: gptParsed.onLeave,
          onArriveContext: gptParsed.onArrive,
        );

        // Show smart dialog for confirmation/editing and pass location suggestion if available
        final result = await showDialog<Reminder>(
          context: context,
          builder: (context) => SmartReminderDialog(
            reminder: reminder,
            locationSuggestion: locationSuggestion,
          ),
        );

        if (result == null) {
          setState(() => _isCreating = false);
          return;
        }

        final reminderProvider = context.read<ReminderProvider>();
        final id = await reminderProvider.createReminder(result);

        if (!mounted) return;

        setState(() => _isCreating = false);

        if (id != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder created successfully!')),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(reminderProvider.error ?? 'Failed to create reminder'),
            ),
          );
        }
      } else {
        // Fallback to basic NLU parser
        if (!NLUParser.hasValidIntent(text)) {
          setState(() => _isCreating = false);
          _showSmartDialog(initialText: text);
          return;
        }

        final parsed = NLUParser.parseReminderText(text);
        final result = await showDialog<Reminder>(
          context: context,
          builder: (context) => SmartReminderDialog(reminder: parsed),
        );

        if (result == null) {
          setState(() => _isCreating = false);
          return;
        }

        final reminderProvider = context.read<ReminderProvider>();
        final id = await reminderProvider.createReminder(result);

        if (!mounted) return;

        setState(() => _isCreating = false);

        if (id != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder created successfully!')),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(reminderProvider.error ?? 'Failed to create reminder'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error creating reminder: $e');
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _showSmartDialog({String? initialText}) async {
    final result = await showDialog<Reminder>(
      context: context,
      builder: (context) => SmartReminderDialog(
        reminder: initialText != null ? Reminder(text: initialText) : null,
      ),
    );

    if (result == null) return;

    setState(() => _isCreating = true);

    final reminderProvider = context.read<ReminderProvider>();
    final id = await reminderProvider.createReminder(result);

    if (!mounted) return;

    setState(() => _isCreating = false);

    if (id != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder created successfully!')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reminderProvider.error ?? 'Failed to create reminder'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Reminder')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'What do you want to remember?',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 24),

            // Input field
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'e.g., Take my keys when leaving home at 8 AM',
                suffixIcon: IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  onPressed: () async {
                    final permissionService = PermissionService();
                    final granted =
                        await permissionService.ensureMicrophonePermission(
                      context,
                      rationale:
                          'Microphone access is required for voice input.',
                    );
                    if (!granted) return;

                    if (!_isListening) {
                      final available = await _speech.initialize(
                        onStatus: (status) {
                          if (status == 'done' || status == 'notListening') {
                            setState(() => _isListening = false);
                            _speech.stop();
                          }
                        },
                        onError: (error) {
                          setState(() => _isListening = false);
                        },
                      );
                      if (available) {
                        setState(() => _isListening = true);
                        _speech.listen(
                          onResult: (result) {
                            setState(() {
                              _textController.text = result.recognizedWords;
                            });
                          },
                        );
                      }
                    } else {
                      setState(() => _isListening = false);
                      await _speech.stop();
                    }
                  },
                ),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),

            const SizedBox(height: 16),

            // Help text
            Text(
              'Try to include context like time, place, or actions',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),

            const SizedBox(height: 32),

            // Sample phrases
            Text(
              'Examples:',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            ...NLUParser.getSuggestions('').map((phrase) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.lightbulb_outline_rounded),
                  title: Text(phrase),
                  onTap: () {
                    _textController.text = phrase;
                  },
                  dense: true,
                ),
              );
            }),

            const SizedBox(height: 32),

            // Create button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createReminder,
                child: _isCreating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Create Reminder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
