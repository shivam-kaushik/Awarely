import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../providers/reminder_provider.dart';
import '../../core/services/nlu_parser.dart';
import '../../data/models/reminder.dart';
import '../../core/services/permission_service.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reminder')),
      );
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

    if (!NLUParser.hasValidIntent(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please provide a clear task description')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    final reminderProvider = context.read<ReminderProvider>();

    // Parse using NLU to allow editing of parsed time
    final parsed = NLUParser.parseReminderText(text);

    // If parsed time exists, ask user to confirm or edit
    Reminder finalReminder = parsed;
    if (parsed.timeAt != null) {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(parsed.timeAt!),
      );
      if (picked != null) {
        final now = DateTime.now();
        final newDate = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
        // If user picks a time that has already passed today, schedule for tomorrow
        var scheduled = newDate;
        if (scheduled.isBefore(now)) {
          scheduled = scheduled.add(const Duration(days: 1));
        }
        finalReminder = parsed.copyWith(timeAt: scheduled);
      }
    }

    final id = await reminderProvider.createReminder(finalReminder);

    if (!mounted) return;

    setState(() {
      _isCreating = false;
    });

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
                        _speech.listen(onResult: (result) {
                          setState(() {
                            _textController.text = result.recognizedWords;
                          });
                        });
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
