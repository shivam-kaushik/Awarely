import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/models/reminder.dart';
import '../../data/models/context_event.dart';
import '../../data/repositories/reminder_repository.dart';
import '../../core/constants/app_constants.dart';
import 'notification_service.dart';

/// Context trigger engine that monitors sensors and triggers reminders
///
/// Note: SSID detection is implemented as a connectivity-based fallback
/// (`_currentWifiSsid == 'connected'`) to avoid adding a dependency that
/// may not resolve in all environments. For precise SSID matching, add
/// `wifi_info_plus` and replace getCurrentWifiSsid() with real SSID lookup.
class TriggerEngine {
  final ReminderRepository _reminderRepository;
  final NotificationService _notificationService;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  String? _currentWifiSsid;
  Position? _currentPosition;

  TriggerEngine({
    required ReminderRepository reminderRepository,
    required NotificationService notificationService,
  })  : _reminderRepository = reminderRepository,
        _notificationService = notificationService;

  /// Start monitoring context (location + wifi)
  Future<void> startMonitoring() async {
    await _startLocationMonitoring();
    await _startWifiMonitoring();
  }

  /// Stop monitoring context
  Future<void> stopMonitoring() async {
    await _positionSubscription?.cancel();
    await _connectivitySubscription?.cancel();
  }

  Future<void> _startLocationMonitoring() async {
    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 50, // Update every 50 meters
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _currentPosition = position;
      _checkGeofenceReminders();
    });
  }

  Future<void> _startWifiMonitoring() async {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult r) async {
      if (r == ConnectivityResult.wifi) {
        // Fallback: mark as connected. If you later add wifi_info_plus,
        // replace this with actual SSID detection.
        _currentWifiSsid = 'connected';
        await checkWifiReminders();
      } else {
        final previous = _currentWifiSsid;
        _currentWifiSsid = null;
        if (previous != null) {
          await checkWifiReminders(leaving: true);
        }
      }
    });
  }

  /// Return the current (fallback) wifi SSID value. May be 'connected' or null.
  Future<String?> getCurrentWifiSsid() async => _currentWifiSsid;

  /// Heuristic to determine if user is on "home" wifi. This uses the
  /// connectivity fallback: if connected and any reminder has wifiSsid == 'connected',
  /// we consider that "home". Replace with real SSID matching when available.
  Future<bool> isOnHomeWifi() async {
    final ssid = await getCurrentWifiSsid();
    if (ssid == null) return false;

    final reminders = await _reminderRepository.getAllReminders();
    for (var r in reminders) {
      if (r.wifiSsid != null && r.wifiSsid == 'connected') return true;
    }
    return false;
  }

  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<void> _checkGeofenceReminders() async {
    if (_currentPosition == null) return;

    final reminders = await _reminderRepository.getActiveReminders();

    for (var reminder in reminders) {
      if (reminder.geofenceLat == null || reminder.geofenceLng == null)
        continue;

      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        reminder.geofenceLat!,
        reminder.geofenceLng!,
      );

      final radius =
          reminder.geofenceRadius ?? AppConstants.defaultGeofenceRadius;
      final isInside = distance <= radius;

      if (isInside && reminder.onArriveContext) {
        await _triggerReminder(reminder, AppConstants.contextTypeArriving);
      }

      if (!isInside && reminder.onLeaveContext) {
        // For a robust solution we'd track previous inside/outside state per reminder.
        await _triggerReminder(reminder, AppConstants.contextTypeLeaving);
      }
    }
  }

  /// Check Wi-Fi based reminders
  Future<void> checkWifiReminders({bool leaving = false}) async {
    final reminders = await _reminderRepository.getActiveReminders();
    final isConnected = _currentWifiSsid != null;

    for (var reminder in reminders) {
      if (reminder.wifiSsid == null) continue;

      // If reminder expects 'connected', treat any Wi‑Fi connection as match.
      final ssidMatches = (reminder.wifiSsid == 'connected' && isConnected) ||
          (reminder.wifiSsid != null &&
              _currentWifiSsid != null &&
              reminder.wifiSsid == _currentWifiSsid);

      if (leaving && reminder.onLeaveContext) {
        await _triggerReminder(reminder, AppConstants.contextTypeLeaving);
      } else if (isConnected && reminder.onArriveContext && ssidMatches) {
        await _triggerReminder(reminder, AppConstants.contextTypeArriving);
      }
    }
  }

  /// Check time-based reminders (called periodically)
  Future<void> checkTimeReminders() async {
    final reminders = await _reminderRepository.getActiveReminders();
    final now = DateTime.now();

    for (var reminder in reminders) {
      if (reminder.timeAt == null) continue;

      final timeDiff = reminder.timeAt!.difference(now).inMinutes.abs();
      if (timeDiff <= 1) {
        await _triggerReminder(reminder, AppConstants.contextTypeTime);
      }
    }
  }

  /// Run periodic checks (time + wifi)
  Future<void> runBackgroundChecks() async {
    await checkTimeReminders();
    await checkWifiReminders();
  }

  Future<void> _triggerReminder(Reminder reminder, String contextType) async {
    await _reminderRepository.updateTriggerStats(reminder.id);

    final event = ContextEvent(
      reminderId: reminder.id,
      contextType: contextType,
      outcome: AppConstants.outcomeMissed,
    );
    await _reminderRepository.createContextEvent(event);

    await _notificationService.showNotification(
      id: reminder.id.hashCode,
      title: 'Reminder',
      body: reminder.text,
      payload: reminder.id,
    );
  }

  /// Manual trigger for testing
  Future<void> testTrigger(Reminder reminder) async {
    await _triggerReminder(reminder, 'manual');
  }
}
