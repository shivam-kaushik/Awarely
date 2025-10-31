import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/reminder.dart';
import '../../data/models/context_event.dart';
import '../../data/repositories/reminder_repository.dart';
import '../../core/constants/app_constants.dart';
import 'notification_service.dart';
import 'home_detection_service.dart';

/// Context trigger engine that monitors sensors and triggers reminders
/// Integrated with HomeDetectionService for WiFi + GPS home detection
class TriggerEngine {
  final ReminderRepository _reminderRepository;
  final NotificationService _notificationService;
  final HomeDetectionService _homeService = HomeDetectionService();

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  Position? _currentPosition;
  bool _wasAtHome = false;

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
    // Check initial home status
    _wasAtHome = await _homeService.isAtHome();

    if (kDebugMode) {
      print(
          '📡 TriggerEngine: WiFi monitoring started (initial home status: $_wasAtHome)',);
    }

    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult r) async {
      if (kDebugMode) {
        print('📡 Connectivity changed: $r');
      }

      // Check if we're at home when connectivity changes
      final isAtHome = await _homeService.isAtHome();

      if (kDebugMode) {
        print('🏠 Home status check: was=$_wasAtHome, now=$isAtHome');
      }

      // Detect transitions
      if (isAtHome && !_wasAtHome) {
        // Just arrived home
        if (kDebugMode) {
          print('✅ ARRIVING HOME detected');
        }
        await checkLocationReminders(arriving: true);
      } else if (!isAtHome && _wasAtHome) {
        // Just left home
        if (kDebugMode) {
          print('🚪 LEAVING HOME detected');
        }
        await checkLocationReminders(leaving: true);
      }

      _wasAtHome = isAtHome;
    });
  }

  /// Get current WiFi SSID from home service
  Future<String?> getCurrentWifiSsid() async {
    return await _homeService.getCurrentWifiSsid();
  }

  /// Check if user is on home WiFi
  Future<bool> isOnHomeWifi() async {
    return await _homeService.isAtHomeViaWifi();
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

      if (isInside && reminder.onArriveContext) {
        await _triggerReminder(reminder, AppConstants.contextTypeArriving);
      }

      if (!isInside && reminder.onLeaveContext) {
        // For a robust solution we'd track previous inside/outside state per reminder.
        await _triggerReminder(reminder, AppConstants.contextTypeLeaving);
      }
    }
  }

  /// Check location-based reminders (WiFi + GPS)
  Future<void> checkLocationReminders(
      {bool leaving = false, bool arriving = false,}) async {
    final reminders = await _reminderRepository.getActiveReminders();
    final isAtHome = await _homeService.isAtHome();

    if (kDebugMode) {
      print(
          '🔍 Checking location reminders: leaving=$leaving, arriving=$arriving, at home=$isAtHome',);
    }

    for (var reminder in reminders) {
      // Check if this is a home-based reminder
      final isHomeReminder = reminder.geofenceId == 'home';

      if (!isHomeReminder) continue;

      if (kDebugMode) {
        print(
            '  📝 Home reminder: "${reminder.text}" (leave=${reminder.onLeaveContext}, arrive=${reminder.onArriveContext})',);
      }

      // Handle leaving home
      if (leaving && reminder.onLeaveContext && !isAtHome) {
        if (kDebugMode) {
          print('  🔔 TRIGGERING "leaving home" reminder: ${reminder.text}');
        }
        await _triggerReminder(reminder, AppConstants.contextTypeLeaving);
      }

      // Handle arriving home
      if (arriving && reminder.onArriveContext && isAtHome) {
        if (kDebugMode) {
          print('  🔔 TRIGGERING "arriving home" reminder: ${reminder.text}');
        }
        await _triggerReminder(reminder, AppConstants.contextTypeArriving);
      }
    }
  }

  /// Check Wi-Fi based reminders (legacy - redirects to checkLocationReminders)
  @Deprecated('Use checkLocationReminders instead')
  Future<void> checkWifiReminders({bool leaving = false}) async {
    await checkLocationReminders(leaving: leaving, arriving: !leaving);
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

  /// Run periodic checks (time + location)
  Future<void> runBackgroundChecks() async {
    if (kDebugMode) {
      print('⏰ Running background checks...');
    }

    await checkTimeReminders();

    // Check if home status changed
    final isAtHome = await _homeService.isAtHome();
    if (isAtHome != _wasAtHome) {
      if (kDebugMode) {
        print(
            '🏠 Background check detected home status change: was=$_wasAtHome, now=$isAtHome',);
      }
      if (isAtHome) {
        await checkLocationReminders(arriving: true);
      } else {
        await checkLocationReminders(leaving: true);
      }
      _wasAtHome = isAtHome;
    }
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
