import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

/// Service for detecting device activity (walking, driving, stationary, etc.)
class ActivityRecognitionService {
  StreamSubscription<Position>? _positionSubscription;
  ActivityType? _currentActivity;
  void Function(ActivityType activity)? _onActivityChanged;
  
  ActivityType? get currentActivity => _currentActivity;

  /// Start monitoring device activity
  /// Requires location permission
  Future<void> startMonitoring({
    void Function(ActivityType activity)? onActivityChanged,
  }) async {
    try {
      // Check location permission first
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        if (kDebugMode) {
          print('⚠️ Activity Recognition: Location permission denied');
        }
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          print('⚠️ Activity Recognition: Location permission permanently denied');
        }
        return;
      }

      // Request permission if needed
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          if (kDebugMode) {
            print('⚠️ Activity Recognition: Permission not granted');
          }
          return;
        }
      }

      // Store callback
      _onActivityChanged = onActivityChanged;
      
      // Start activity stream (using position stream to infer activity from speed)
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen((Position position) {
        // Note: Geolocator doesn't directly provide activity, but we can infer
        // from speed. For actual activity recognition, we'd need a dedicated package.
        // This is a simplified implementation.
        final previousActivity = _currentActivity;
        _updateActivityFromSpeed(position.speed);
        
        // Notify callback if activity changed
        if (previousActivity != _currentActivity && _currentActivity != null && _onActivityChanged != null) {
          _onActivityChanged!(_currentActivity!);
        }
      });

      if (kDebugMode) {
        print('✅ Activity Recognition: Started monitoring');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Activity Recognition Error: $e');
      }
    }
  }

  /// Stop monitoring activity
  Future<void> stopMonitoring() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _currentActivity = null;
    _onActivityChanged = null;
    
    if (kDebugMode) {
      print('🛑 Activity Recognition: Stopped monitoring');
    }
  }

  /// Infer activity from speed (simplified approach)
  /// For production, consider using dedicated activity recognition package
  void _updateActivityFromSpeed(double speedMs) {
    ActivityType? newActivity;
    
    // Convert m/s to km/h
    final speedKmh = speedMs * 3.6;
    
    if (kDebugMode) {
      print('🏃 ActivityRecognition: Position update - speed: ${speedKmh.toStringAsFixed(1)} km/h (${speedMs.toStringAsFixed(2)} m/s)');
    }
    
    if (speedKmh < 1) {
      newActivity = ActivityType.still;
    } else if (speedKmh < 5) {
      newActivity = ActivityType.walking;
    } else if (speedKmh < 20) {
      newActivity = ActivityType.running;
    } else if (speedKmh < 60) {
      newActivity = ActivityType.onBicycle;
    } else {
      newActivity = ActivityType.inVehicle;
    }

    if (_currentActivity != newActivity) {
      final oldActivityName = _currentActivity != null ? _getActivityName(_currentActivity!) : 'Unknown';
      final newActivityName = _getActivityName(newActivity);
      
      _currentActivity = newActivity;
      
      if (kDebugMode) {
        print('');
        print('🔄═══════════════════════════════════════════════════');
        print('🔄 ActivityRecognition: ACTIVITY CHANGED');
        print('🔄═══════════════════════════════════════════════════');
        print('   Previous: $oldActivityName');
        print('   New: $newActivityName');
        print('   Speed: ${speedKmh.toStringAsFixed(1)} km/h');
        print('   Threshold: ${_getSpeedThreshold(newActivity)}');
        print('🔄═══════════════════════════════════════════════════');
        print('');
      }
    } else {
      if (kDebugMode && speedKmh > 0.1) {
        final activityName = _getActivityName(newActivity);
        print('🏃 ActivityRecognition: Activity unchanged ($activityName), speed: ${speedKmh.toStringAsFixed(1)} km/h');
      }
    }
  }
  
  String _getSpeedThreshold(ActivityType? activity) {
    switch (activity) {
      case ActivityType.still:
        return '< 1 km/h';
      case ActivityType.walking:
        return '1-5 km/h';
      case ActivityType.running:
        return '5-20 km/h';
      case ActivityType.onBicycle:
        return '20-60 km/h';
      case ActivityType.inVehicle:
        return '> 60 km/h';
      default:
        return 'unknown';
    }
  }

  /// Get human-readable activity name
  String _getActivityName(ActivityType activity) {
    switch (activity) {
      case ActivityType.still:
        return 'Stationary';
      case ActivityType.walking:
        return 'Walking';
      case ActivityType.running:
        return 'Running';
      case ActivityType.onBicycle:
        return 'Cycling';
      case ActivityType.inVehicle:
        return 'Driving';
      case ActivityType.onFoot:
        return 'On Foot';
      case ActivityType.unknown:
        return 'Unknown';
    }
  }

  /// Get human-readable activity name (public)
  String getActivityName(ActivityType? activity) {
    if (activity == null) return 'Unknown';
    return _getActivityName(activity);
  }

  /// Check if user is currently driving
  bool get isDriving => _currentActivity == ActivityType.inVehicle;

  /// Check if user is currently walking
  bool get isWalking => _currentActivity == ActivityType.walking;

  /// Check if user is currently stationary
  bool get isStationary => _currentActivity == ActivityType.still;
}

/// Activity types that can be detected
enum ActivityType {
  still,
  walking,
  running,
  onBicycle,
  inVehicle,
  onFoot,
  unknown,
}

