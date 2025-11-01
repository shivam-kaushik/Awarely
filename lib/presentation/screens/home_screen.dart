import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../providers/reminder_provider.dart';
import '../widgets/context_group_card.dart';
import '../widgets/smart_reminder_dialog.dart';
import 'add_reminder_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import '../../data/models/reminder.dart';
import '../../core/services/smart_bundling_service.dart';
import '../../core/services/home_detection_service.dart';

/// Home screen - main dashboard
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Position? _currentPosition;
  String? _currentWifiSsid;
  bool _hideCompleted = true;

  @override
  void initState() {
    super.initState();
    // Load reminders on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReminderProvider>().loadReminders();
      _updateContext();
    });
  }

  Future<void> _updateContext() async {
    try {
      // Get current location
      final hasPermission = await Geolocator.checkPermission();
      if (hasPermission == LocationPermission.whileInUse ||
          hasPermission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _currentPosition = position;
        });
      }

      // Get current WiFi SSID
      final homeService = HomeDetectionService();
      final wifiSsid = await homeService.getCurrentWifiSsid();
      setState(() {
        _currentWifiSsid = wifiSsid;
      });
    } catch (e) {
      debugPrint('Error updating context: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Awarely'),
            Text(
              'Never forget what matters',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AnalyticsScreen(),
                ),
              );
            },
            tooltip: 'Analytics',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (c) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Consumer<ReminderProvider>(
        builder: (context, reminderProvider, child) {
          if (reminderProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (reminderProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${reminderProvider.error}',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      reminderProvider.loadReminders();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (reminderProvider.reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 100,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No reminders yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first reminder',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          // Filter out completed reminders if hiding them
          final visibleReminders = _hideCompleted
              ? reminderProvider.reminders
              : reminderProvider.reminders;

          // Group reminders by context
          final groups = SmartBundlingService.groupByContext(
            visibleReminders,
            currentPosition: _currentPosition,
            currentWifiSsid: _currentWifiSsid,
          );

          return RefreshIndicator(
            onRefresh: () async {
              await reminderProvider.loadReminders();
              await _updateContext();
            },
            child: groups.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 100,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No active reminders',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to create your first reminder',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Toggle to show/hide completed
                      if (!_hideCompleted)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Show completed',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Switch(
                                value: !_hideCompleted,
                                onChanged: (value) {
                                  setState(() {
                                    _hideCompleted = !value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                      // Display grouped reminders
                      ...groups.entries.map((entry) {
                        return ContextGroupCard(
                          contextTitle: entry.key,
                          reminders: entry.value,
                          contextIcon: SmartBundlingService.getContextIcon(entry.key),
                          onReminderTap: (reminder) async {
                            final result = await showDialog<Reminder>(
                              context: context,
                              builder: (context) => SmartReminderDialog(
                                reminder: reminder,
                              ),
                            );
                            if (result != null) {
                              reminderProvider.updateReminder(result);
                            }
                          },
                          onToggle: (id, enabled) {
                            reminderProvider.toggleReminder(id, enabled);
                          },
                          onDelete: (id) {
                            reminderProvider.deleteReminder(id);
                          },
                        );
                      }),
                    ],
                  ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddReminderScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Reminder'),
      ),
    );
  }
}
