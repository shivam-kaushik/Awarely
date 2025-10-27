import 'package:permission_handler/permission_handler.dart';

/// Permission service for managing app permissions
class PermissionService {
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

  /// Request notification permission
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
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
    };
  }

  /// Check all permissions status
  Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'location': await hasLocationPermission(),
      'locationAlways': await hasLocationAlwaysPermission(),
      'notification': await hasNotificationPermission(),
    };
  }

  /// Open app settings
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
