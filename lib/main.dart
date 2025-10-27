import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:workmanager/workmanager.dart';

import 'core/services/notification_service.dart';
import 'core/services/permission_service.dart';
import 'data/database/database_helper.dart';
import 'data/repositories/reminder_repository.dart';
import 'presentation/providers/reminder_provider.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/screens/splash_screen.dart';

/// Background task callback for Workmanager
/// Executes context monitoring and reminder triggering in background
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize services for background context
      await DatabaseHelper.instance.database;
      final notificationService = NotificationService();
      await notificationService.initialize();

      // Check context and trigger reminders
      // This will be implemented by the TriggerEngine
      debugPrint('Background task executed: $task');

      return Future.value(true);
    } catch (error) {
      debugPrint('Background task error: $error');
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data for scheduled notifications
  tz.initializeTimeZones();

  // Initialize background task manager
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  // Register periodic context monitoring task (every 15 minutes)
  await Workmanager().registerPeriodicTask(
    'context_monitor',
    'contextMonitorTask',
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.not_required,
      requiresBatteryNotLow: true,
    ),
  );

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const AwarelyApp());
}

/// Main application widget
class AwarelyApp extends StatelessWidget {
  const AwarelyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Repositories
        Provider<ReminderRepository>(create: (_) => ReminderRepository()),

        // Services
        Provider<NotificationService>(create: (_) => NotificationService()),
        Provider<PermissionService>(create: (_) => PermissionService()),

        // State Management
        ChangeNotifierProvider<ReminderProvider>(
          create: (context) => ReminderProvider(
            reminderRepository: context.read<ReminderRepository>(),
            notificationService: context.read<NotificationService>(),
          )..loadReminders(),
        ),
      ],
      child: MaterialApp(
        title: 'Awarely',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}
