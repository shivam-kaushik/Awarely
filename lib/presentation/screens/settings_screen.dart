import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/notification_service.dart';
import '../../core/services/permission_service.dart';
import '../providers/theme_provider.dart';
import 'recent_notifications_screen.dart';

/// Settings screen to manage permissions and notification diagnostics
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final PermissionService _permissionService = PermissionService();
  final NotificationService _notificationService = NotificationService();

  bool _notificationsEnabled = false;
  bool _microphoneEnabled = false;
  bool _locationEnabled = false;
  bool _exactAlarmEnabled = false;
  List<String> _pendingNotifications = [];
  bool _loadingPending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When returning from system settings, refresh permission statuses
    if (state == AppLifecycleState.resumed) {
      _refreshStatuses();
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<void> _refreshStatuses() async {
    final notif = await _permissionService.hasNotificationPermission();
    final mic = await _permissionService.hasMicrophonePermission();
    final loc = await _permissionService.hasLocationPermission();
    final exactAlarm = await _permissionService.hasExactAlarmPermission();

    setState(() {
      _notificationsEnabled = notif;
      _microphoneEnabled = mic;
      _locationEnabled = loc;
      _exactAlarmEnabled = exactAlarm;
    });

    await _loadPendingNotifications();
  }

  Future<void> _loadPendingNotifications() async {
    setState(() => _loadingPending = true);
    try {
      final pending = await _notificationService.getPendingNotifications();
      setState(() {
        _pendingNotifications = pending
            .map((p) => '${p.id}: ${p.title ?? "(no title)"} @ ${p.body ?? ""}')
            .toList();
      });
    } finally {
      setState(() => _loadingPending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshStatuses,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Theme Settings
            const Text('Appearance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
            const SizedBox(height: 12),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.palette),
                        title: const Text('Theme'),
                        subtitle: Text(_getThemeModeLabel(themeProvider.themeMode)),
                        trailing: PopupMenuButton<ThemeMode>(
                          icon: const Icon(Icons.arrow_drop_down),
                          onSelected: (mode) {
                            themeProvider.setThemeMode(mode);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: ThemeMode.system,
                              child: Row(
                                children: [
                                  Icon(Icons.phone_android, size: 20),
                                  SizedBox(width: 8),
                                  Text('System Default'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: ThemeMode.light,
                              child: Row(
                                children: [
                                  Icon(Icons.light_mode, size: 20),
                                  SizedBox(width: 8),
                                  Text('Light'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: ThemeMode.dark,
                              child: Row(
                                children: [
                                  Icon(Icons.dark_mode, size: 20),
                                  SizedBox(width: 8),
                                  Text('Dark'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (themeProvider.themeMode != ThemeMode.system)
                        SwitchListTile(
                          secondary: Icon(
                            themeProvider.isDarkMode(context)
                                ? Icons.dark_mode
                                : Icons.light_mode,
                          ),
                          title: Text(themeProvider.isDarkMode(context)
                              ? 'Dark Mode'
                              : 'Light Mode'),
                          subtitle: const Text('Toggle between light and dark'),
                          value: themeProvider.themeMode == ThemeMode.dark,
                          onChanged: (value) {
                            themeProvider.setThemeMode(
                              value ? ThemeMode.dark : ThemeMode.light,
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('Permissions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Notifications'),
              subtitle: Text(_notificationsEnabled ? 'Enabled' : 'Disabled'),
              trailing: ElevatedButton(
                onPressed: () async {
                  final granted =
                      await _permissionService.ensureNotificationPermission(
                    context,
                    rationale:
                        'Notifications are used to deliver reminders. Please enable them.',
                  );
                  if (granted) {
                    setState(() => _notificationsEnabled = true);
                  }
                },
                child: const Text('Manage'),
              ),
            ),
            ListTile(
              title: const Text('Exact Alarms'),
              subtitle: Text(_exactAlarmEnabled ? 'Enabled' : 'Disabled'),
              trailing: ElevatedButton(
                onPressed: () async {
                  final granted =
                      await _permissionService.ensureExactAlarmPermission(
                    context,
                    rationale:
                        'Exact alarms are needed to deliver reminders at the precise time.',
                  );
                  if (granted) {
                    setState(() => _exactAlarmEnabled = true);
                  }
                },
                child: const Text('Manage'),
              ),
            ),
            ListTile(
              title: const Text('Microphone'),
              subtitle: Text(_microphoneEnabled ? 'Enabled' : 'Disabled'),
              trailing: ElevatedButton(
                onPressed: () async {
                  final granted =
                      await _permissionService.ensureMicrophonePermission(
                    context,
                    rationale: 'Microphone is needed for voice input.',
                  );
                  if (granted) setState(() => _microphoneEnabled = true);
                },
                child: const Text('Manage'),
              ),
            ),
            ListTile(
              title: const Text('Location'),
              subtitle: Text(_locationEnabled ? 'Enabled' : 'Disabled'),
              trailing: ElevatedButton(
                onPressed: () async {
                  final granted =
                      await _permissionService.ensureLocationPermission(
                    context,
                    rationale: 'Location is needed for place-based reminders.',
                  );
                  if (granted) setState(() => _locationEnabled = true);
                },
                child: const Text('Manage'),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Notifications diagnostics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Test notifications'),
              subtitle:
                  const Text('Send a test notification to verify permissions'),
              trailing: ElevatedButton(
                onPressed: () async {
                  final notif = _notificationService;

                  // Test immediate notification
                  await notif.showNotification(
                    id: 999999,
                    title: '✅ Test Notification',
                    body: 'If you see this, notifications work!',
                  );

                  // Test scheduled notification (30 seconds from now)
                  final testTime =
                      DateTime.now().add(const Duration(seconds: 30));
                  await notif.scheduleNotification(
                    id: 888888,
                    title: '⏰ Test Scheduled',
                    body: 'This should appear in 30 seconds',
                    scheduledTime: testTime,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Test sent! Check notification in 30 seconds.',),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
                child: const Text('Send Test'),
              ),
            ),
            ListTile(
              title: const Text('Recent notifications'),
              subtitle: const Text('View recent notification events'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (c) => const RecentNotificationsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Pending scheduled notifications'),
              subtitle: _loadingPending
                  ? const Text('Loading...')
                  : _pendingNotifications.isEmpty
                      ? const Text('No pending scheduled notifications')
                      : Text('${_pendingNotifications.length} pending'),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadPendingNotifications,
              ),
            ),
            if (_pendingNotifications.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._pendingNotifications.map((s) => Card(
                    child: ListTile(
                      title: Text(s),
                    ),
                  ),),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await _permissionService.requestDisableBatteryOptimization();
                await Future.delayed(const Duration(seconds: 1));
                _refreshStatuses();
              },
              icon: const Icon(Icons.battery_charging_full),
              label: const Text('Disable Battery Optimization'),
            ),
            const SizedBox(height: 8),
            Text(
              'Recommended: Disable battery optimization for reliable notification delivery',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await _permissionService.openSettings();
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open App Settings'),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }
}
