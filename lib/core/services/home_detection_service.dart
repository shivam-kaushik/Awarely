import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../data/models/saved_location.dart';

/// Service for intelligently detecting user's home location
/// Uses multi-layered approach: Auto-learning + WiFi + GPS + Manual
class HomeDetectionService {
  static const String _prefHomeLocation = 'home_location';
  static const String _prefHomeWifiList = 'home_wifi_list';
  static const String _prefLocationVisits = 'location_visits';
  static const String _prefHomeDetectionMode = 'home_detection_mode';

  static const _wifiChannel = MethodChannel('com.example.awarely/wifi');

  // Detection modes
  static const String modeAutomatic = 'automatic';
  static const String modeManual = 'manual';
  static const String modeHybrid = 'hybrid';

  /// Get current home location (if set)
  Future<SavedLocation?> getHomeLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefHomeLocation);

    if (jsonString == null) return null;

    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return SavedLocation.fromMap(map);
    } catch (e) {
      debugPrint('❌ Error parsing home location: $e');
      return null;
    }
  }

  /// Set home location manually
  Future<void> setHomeLocation(SavedLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefHomeLocation, jsonEncode(location.toMap()));
    await prefs.setString(_prefHomeDetectionMode, modeManual);
    debugPrint('✅ Home location set manually: ${location.name}');
  }

  /// Get list of WiFi networks associated with home
  Future<List<String>> getHomeWifiNetworks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefHomeWifiList);

    if (jsonString == null) return [];

    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.cast<String>();
    } catch (e) {
      debugPrint('❌ Error parsing home WiFi list: $e');
      return [];
    }
  }

  /// Add a WiFi network to home WiFi list
  Future<void> addHomeWifiNetwork(String ssid) async {
    final prefs = await SharedPreferences.getInstance();
    final networks = await getHomeWifiNetworks();

    if (!networks.contains(ssid)) {
      networks.add(ssid);
      await prefs.setString(_prefHomeWifiList, jsonEncode(networks));
      debugPrint('✅ Added home WiFi: $ssid');
    }
  }

  /// Remove a WiFi network from home WiFi list
  Future<void> removeHomeWifiNetwork(String ssid) async {
    final prefs = await SharedPreferences.getInstance();
    final networks = await getHomeWifiNetworks();

    if (networks.contains(ssid)) {
      networks.remove(ssid);
      await prefs.setString(_prefHomeWifiList, jsonEncode(networks));
      debugPrint('✅ Removed home WiFi: $ssid');
    }
  }

  /// Check if user is currently at home (WiFi-based)
  Future<bool> isAtHomeViaWifi() async {
    try {
      // Get current WiFi SSID
      final currentSsid = await getCurrentWifiSsid();
      if (currentSsid == null) return false;

      // Check against home WiFi list
      final homeNetworks = await getHomeWifiNetworks();
      final isHome = homeNetworks.contains(currentSsid);

      debugPrint(
          '📶 WiFi check: $currentSsid ${isHome ? "IS" : "is NOT"} home',);
      return isHome;
    } catch (e) {
      debugPrint('❌ Error checking home WiFi: $e');
      return false;
    }
  }

  /// Check if user is currently at home (GPS-based)
  Future<bool> isAtHomeViaGps() async {
    try {
      final home = await getHomeLocation();
      if (home == null) return false;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final distance = Geolocator.distanceBetween(
        home.latitude,
        home.longitude,
        position.latitude,
        position.longitude,
      );

      final isHome = distance <= home.radius;
      debugPrint(
          '📍 GPS check: ${distance.toStringAsFixed(0)}m from home ${isHome ? "IS" : "is NOT"} home',);
      return isHome;
    } catch (e) {
      debugPrint('❌ Error checking home GPS: $e');
      return false;
    }
  }

  /// Check if user is at home (combines WiFi + GPS)
  /// WiFi is preferred as it's faster and more battery efficient
  Future<bool> isAtHome() async {
    // Try WiFi first (fastest, most reliable)
    final wifiResult = await isAtHomeViaWifi();
    if (wifiResult) return true;

    // Fallback to GPS if WiFi check failed
    return await isAtHomeViaGps();
  }

  /// Get current WiFi SSID
  /// Note: iOS 13+ restricts WiFi SSID access (privacy feature)
  /// On iOS, this will return null and rely on GPS-based detection
  Future<String?> getCurrentWifiSsid() async {
    try {
      final connectivity = Connectivity();
      final result = await connectivity.checkConnectivity();

      if (result != ConnectivityResult.wifi) {
        debugPrint('📶 Not connected to WiFi');
        return null;
      }

      // Platform-specific handling
      if (Platform.isIOS) {
        // iOS 13+ restrictions: Can't read WiFi SSID without special entitlements
        // Return null and rely on GPS-based home detection instead
        debugPrint('📶 iOS: WiFi SSID unavailable due to iOS privacy restrictions');
        debugPrint('📶 iOS: Using GPS-based home detection as fallback');
        return null; // Or return a placeholder like 'wifi_connected'
      }

      // Android: Get SSID from native code
      final ssid =
          await _wifiChannel.invokeMethod<String>('getCurrentWifiSsid');
      debugPrint('📶 Current WiFi SSID: ${ssid ?? "none"}');
      return ssid;
    } catch (e) {
      debugPrint('❌ Error getting WiFi SSID: $e');
      return null;
    }
  }

  /// Learn home location automatically based on user behavior
  /// Tracks where user spends most time during "home hours" (10 PM - 7 AM)
  Future<void> trackLocationVisit(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      // Only track during typical "home hours" (night time)
      final hour = now.hour;
      final isHomeHours = hour >= 22 || hour <= 7; // 10 PM to 7 AM

      if (!isHomeHours) return;

      // Get existing visits
      final jsonString = prefs.getString(_prefLocationVisits);
      Map<String, dynamic> visits = {};

      if (jsonString != null) {
        visits = jsonDecode(jsonString) as Map<String, dynamic>;
      }

      // Create location key (rounded to ~100m precision)
      final latKey = (position.latitude * 100).round() / 100;
      final lngKey = (position.longitude * 100).round() / 100;
      final locationKey = '$latKey,$lngKey';

      // Increment visit count
      visits[locationKey] = (visits[locationKey] ?? 0) + 1;

      // Save updated visits
      await prefs.setString(_prefLocationVisits, jsonEncode(visits));

      // Check if we should auto-set home location
      await _checkAndSetAutoHome(visits, position);
    } catch (e) {
      debugPrint('❌ Error tracking location visit: $e');
    }
  }

  /// Automatically set home location if confidence is high enough
  Future<void> _checkAndSetAutoHome(
      Map<String, dynamic> visits, Position lastPosition,) async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(_prefHomeDetectionMode) ?? modeAutomatic;

    // Don't override if user set it manually
    if (mode == modeManual) return;

    // Need at least 10 visits during home hours
    final totalVisits =
        visits.values.fold<int>(0, (sum, count) => sum + (count as int));
    if (totalVisits < 10) {
      debugPrint('📊 Auto-learning: $totalVisits/10 visits collected');
      return;
    }

    // Find most visited location
    String? topLocation;
    int maxVisits = 0;

    visits.forEach((location, count) {
      if (count > maxVisits) {
        maxVisits = count;
        topLocation = location;
      }
    });

    // Check if this location has >60% of visits (high confidence)
    final confidence = maxVisits / totalVisits;
    if (confidence < 0.6) {
      debugPrint(
          '📊 Auto-learning: Confidence too low (${(confidence * 100).toStringAsFixed(0)}%)',);
      return;
    }

    // Parse location
    if (topLocation != null) {
      final parts = topLocation!.split(',');
      final lat = double.parse(parts[0]);
      final lng = double.parse(parts[1]);

      // Auto-set home location
      final homeLocation = SavedLocation(
        id: 'home_auto',
        name: 'Home (Auto-detected)',
        latitude: lat,
        longitude: lng,
        radius: 150.0, // Slightly larger radius for auto-detected
      );

      await prefs.setString(
          _prefHomeLocation, jsonEncode(homeLocation.toMap()),);
      await prefs.setString(_prefHomeDetectionMode, modeAutomatic);

      debugPrint(
          '🏠 Auto-detected home location with ${(confidence * 100).toStringAsFixed(0)}% confidence',);
      debugPrint('   Location: $lat, $lng');
      debugPrint('   Based on $maxVisits visits');
    }
  }

  /// Learn home WiFi automatically
  /// If user is at home (GPS) and connected to WiFi, remember that WiFi
  Future<void> learnHomeWifi() async {
    try {
      final isHome = await isAtHomeViaGps();
      if (!isHome) return;

      final ssid = await getCurrentWifiSsid();
      if (ssid == null) return;

      // Add this WiFi to home networks
      await addHomeWifiNetwork(ssid);
      debugPrint('🏠 Learned home WiFi: $ssid');
    } catch (e) {
      debugPrint('❌ Error learning home WiFi: $e');
    }
  }

  /// Setup wizard: Ask user to set home location and WiFi
  Future<Map<String, dynamic>> getSetupStatus() async {
    final home = await getHomeLocation();
    final wifiNetworks = await getHomeWifiNetworks();
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(_prefHomeDetectionMode);

    return {
      'hasHomeLocation': home != null,
      'homeLocation': home?.toMap(),
      'hasHomeWifi': wifiNetworks.isNotEmpty,
      'homeWifiNetworks': wifiNetworks,
      'detectionMode': mode ?? 'none',
      'isFullySetup': home != null || wifiNetworks.isNotEmpty,
    };
  }

  /// Reset all home detection data
  Future<void> resetHomeData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefHomeLocation);
    await prefs.remove(_prefHomeWifiList);
    await prefs.remove(_prefLocationVisits);
    await prefs.remove(_prefHomeDetectionMode);
    debugPrint('🗑️ Reset all home detection data');
  }

  /// Get debug information
  Future<Map<String, dynamic>> getDebugInfo() async {
    final home = await getHomeLocation();
    final wifiNetworks = await getHomeWifiNetworks();
    final currentSsid = await getCurrentWifiSsid();
    final isHomeWifi = await isAtHomeViaWifi();
    final isHomeGps = await isAtHomeViaGps();
    final prefs = await SharedPreferences.getInstance();
    final visits = prefs.getString(_prefLocationVisits);

    return {
      'homeLocation': home?.toMap(),
      'homeWifiNetworks': wifiNetworks,
      'currentWifiSsid': currentSsid,
      'isAtHomeViaWifi': isHomeWifi,
      'isAtHomeViaGps': isHomeGps,
      'isAtHome': isHomeWifi || isHomeGps,
      'detectionMode': prefs.getString(_prefHomeDetectionMode),
      'totalLocationVisits': visits != null
          ? (jsonDecode(visits) as Map)
              .values
              .fold(0, (sum, v) => sum + (v as int))
          : 0,
    };
  }
}
