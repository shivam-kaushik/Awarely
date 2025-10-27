import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Permission service for managing app permissions
class PermissionService {
  static const _platform = MethodChannel('com.example.awarely/permissions');

  /// Check if exact alarm permission is granted (Android 12+)
  Future<bool> hasExactAlarmPermission() async {
    try {
      final bool result = await _platform.invokeMethod('hasExactAlarmPermission');
      return result;
    } catch (e) {
      debugPrint('Error checking exact alarm permission: $e');
      return false;
    }
  }

  /// Ensure exact alarm permission is granted
  Future<bool> ensureExactAlarmPermission(
      BuildContext context, {
        String? rationale,
      }) async {
    final hasPermission = await hasExactAlarmPermission();

    if (hasPermission) return true;

    if (context.mounted) {
      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Exact Alarm Permission Required'),
          content: Text(
            rationale ??
                'This app needs permission to schedule exact alarms for reminders. '
                    'Please enable "Alarms & reminders" in the app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      if (shouldRequest == true) {
        try {
          await _platform.invokeMethod('openExactAlarmSettings');
          // Wait a bit for user to return
          await Future.delayed(const Duration(seconds: 1));
          return await hasExactAlarmPermission();
        } catch (e) {
          debugPrint('Error opening exact alarm settings: $e');
        }
      }
    }

    return false;
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Request location always permission (for background)
  Future<bool> requestLocationAlwaysPermission() async {
    final status = await Permission.locationAlways.request();
    return status.isGranted;
  }

  /// Ensure location permission is granted; prompt user to open settings if blocked
  Future<bool> ensureLocationPermission(BuildContext context,
      {bool requireAlways = false, String? rationale}) async {
    if (requireAlways) {
      final status = await Permission.locationAlways.status;
      if (status.isGranted) return true;
      final granted = await requestLocationAlwaysPermission();
      if (granted) return true;

      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Location permission required'),
            content: Text(rationale ??
                'Background location access is required for location-based reminders. Please enable it in app settings.'),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );

      return false;
    } else {
      final status = await Permission.location.status;
      if (status.isGranted) return true;
      final granted = await requestLocationPermission();
      if (granted) return true;

      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Location permission required'),
            content: Text(rationale ??
                'Location access is required for location-based reminders. Please enable it in app settings.'),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );

      return false;
    }
  }

  /// Request notification permission
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Ensure notification permission is granted; if not, prompt the user to open settings
  Future<bool> ensureNotificationPermission(BuildContext context,
      {String? rationale}) async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    final granted = await requestNotificationPermission();
    if (granted) return true;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Notifications permission required'),
          content: Text(rationale ??
              'Notifications are required to deliver reminders. Please enable notifications in app settings.'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    return false;
  }

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Ensure microphone permission is granted, otherwise prompt user to open settings
  Future<bool> ensureMicrophonePermission(BuildContext context,
      {String? rationale}) async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;

    final granted = await requestMicrophonePermission();
    if (granted) return true;

    // If not granted, show a dialog guiding the user to app settings
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Microphone permission required'),
          content: Text(rationale ??
              'Microphone access is required for voice input. Please enable it in app settings.'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    return false;
  }

  /// Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Check if location always permission is granted
  Future<bool> hasLocationAlwaysPermission() async {
    final status = await Permission.locationAlways.status;
    return status.isGranted;
  }

  /// Check if notification permission is granted
  Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Request all necessary permissions
  Future<Map<String, bool>> requestAllPermissions() async {
    return {
      'location': await requestLocationPermission(),
      'locationAlways': await requestLocationAlwaysPermission(),
      'notification': await requestNotificationPermission(),
      'exactAlarm': await hasExactAlarmPermission(),
    };
  }

  /// Check all permissions status
  Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'location': await hasLocationPermission(),
      'locationAlways': await hasLocationAlwaysPermission(),
      'notification': await hasNotificationPermission(),
      'exactAlarm': await hasExactAlarmPermission(),
    };
  }

  /// Open app settings
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}