import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

import '../../data/models/reminder.dart';
import '../../data/models/context_event.dart';
import '../../data/repositories/reminder_repository.dart';
import '../../core/constants/app_constants.dart';
import 'notification_service.dart';

/// Context trigger engine that monitors sensors and triggers reminders
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

  /// Start monitoring context
  Future<void> startMonitoring() async {
    await _startLocationMonitoring();
    await _startWifiMonitoring();
  }

  /// Stop monitoring context
  Future<void> stopMonitoring() async {
    await _positionSubscription?.cancel();
    await _connectivitySubscription?.cancel();
  }

  /// Start location monitoring
  Future<void> _startLocationMonitoring() async {
    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 50, // Update every 50 meters
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        _currentPosition = position;
        _checkGeofenceReminders();
      },
    );
  }

  /// Start Wi-Fi monitoring
  Future<void> _startWifiMonitoring() async {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) async {
      if (result == ConnectivityResult.wifi) {
        // Note: Getting SSID requires additional platform-specific code
        // For MVP, we'll use connectivity state
        _currentWifiSsid = 'connected';
        await _checkWifiReminders();
      } else {
        final previousSsid = _currentWifiSsid;
        _currentWifiSsid = null;

        // Check if we left a Wi-Fi network (leaving home/office)
        if (previousSsid != null) {
          await _checkWifiReminders(leaving: true);
        }
      }
    });
  }

  /// Check location permission
  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Check geofence-based reminders
  Future<void> _checkGeofenceReminders() async {
    if (_currentPosition == null) return;

    final reminders = await _reminderRepository.getActiveReminders();

    for (var reminder in reminders) {
      if (reminder.geofenceLat == null || reminder.geofenceLng == null) {
        continue;
      }

      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        reminder.geofenceLat!,
        reminder.geofenceLng!,
      );

      final radius =
          reminder.geofenceRadius ?? AppConstants.defaultGeofenceRadius;
      final isInside = distance <= radius;

      // Check if arriving at location
      if (isInside && reminder.onArriveContext) {
        await _triggerReminder(reminder, AppConstants.contextTypeArriving);
      }

      // Check if leaving location
      if (!isInside && reminder.onLeaveContext) {
        // This would need state tracking to detect transition
        // For MVP, simplified implementation
      }
    }
  }

  /// Check Wi-Fi based reminders
  Future<void> _checkWifiReminders({bool leaving = false}) async {
    final reminders = await _reminderRepository.getActiveReminders();

    for (var reminder in reminders) {
      if (reminder.wifiSsid == null) continue;

      final isConnected = _currentWifiSsid != null;

      if (leaving && reminder.onLeaveContext) {
        await _triggerReminder(reminder, AppConstants.contextTypeLeaving);
      } else if (isConnected && reminder.onArriveContext) {
        await _triggerReminder(reminder, AppConstants.contextTypeArriving);
      }
    }
  }

  /// Check time-based reminders
  Future<void> checkTimeReminders() async {
    final reminders = await _reminderRepository.getActiveReminders();
    final now = DateTime.now();

    for (var reminder in reminders) {
      if (reminder.timeAt == null) continue;

      // Check if time matches (within 1 minute window)
      final timeDiff = reminder.timeAt!.difference(now).inMinutes.abs();
      if (timeDiff <= 1) {
        await _triggerReminder(reminder, AppConstants.contextTypeTime);
      }
    }
  }

  /// Trigger reminder notification
  Future<void> _triggerReminder(Reminder reminder, String contextType) async {
    // Update trigger stats
    await _reminderRepository.updateTriggerStats(reminder.id);

    // Create context event
    final event = ContextEvent(
      reminderId: reminder.id,
      contextType: contextType,
      outcome: AppConstants.outcomeMissed, // Default, updated on user action
    );
    await _reminderRepository.createContextEvent(event);

    // Show notification
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
