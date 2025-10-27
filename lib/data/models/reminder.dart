import 'package:uuid/uuid.dart';

/// Reminder model representing a context-aware reminder
class Reminder {
  final String id;
  final String text;
  final DateTime? timeAt;
  final String? geofenceId;
  final double? geofenceLat;
  final double? geofenceLng;
  final double? geofenceRadius;
  final String? wifiSsid;
  final bool onLeaveContext;
  final bool onArriveContext;
  final bool enabled;
  final DateTime createdAt;
  final DateTime? lastTriggeredAt;
  final int triggerCount;
  final int?
      repeatInterval; // How many units to repeat (e.g., 2 for "every 2 hours")
  final String? repeatUnit; // 'minutes', 'hours', 'days', 'weeks'

  Reminder({
    String? id,
    required this.text,
    this.timeAt,
    this.geofenceId,
    this.geofenceLat,
    this.geofenceLng,
    this.geofenceRadius,
    this.wifiSsid,
    this.onLeaveContext = false,
    this.onArriveContext = false,
    this.enabled = true,
    DateTime? createdAt,
    this.lastTriggeredAt,
    this.triggerCount = 0,
    this.repeatInterval,
    this.repeatUnit,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Create Reminder from database map
  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as String,
      text: map['text'] as String,
      timeAt: map['timeAt'] != null
          ? DateTime.parse(map['timeAt'] as String)
          : null,
      geofenceId: map['geofenceId'] as String?,
      geofenceLat: map['geofenceLat'] as double?,
      geofenceLng: map['geofenceLng'] as double?,
      geofenceRadius: map['geofenceRadius'] as double?,
      wifiSsid: map['wifiSsid'] as String?,
      onLeaveContext: (map['onLeaveContext'] as int) == 1,
      onArriveContext: (map['onArriveContext'] as int) == 1,
      enabled: (map['enabled'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastTriggeredAt: map['lastTriggeredAt'] != null
          ? DateTime.parse(map['lastTriggeredAt'] as String)
          : null,
      triggerCount: map['triggerCount'] as int? ?? 0,
      repeatInterval: map['repeatInterval'] as int?,
      repeatUnit: map['repeatUnit'] as String?,
    );
  }

  /// Convert Reminder to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'timeAt': timeAt?.toIso8601String(),
      'geofenceId': geofenceId,
      'geofenceLat': geofenceLat,
      'geofenceLng': geofenceLng,
      'geofenceRadius': geofenceRadius,
      'wifiSsid': wifiSsid,
      'onLeaveContext': onLeaveContext ? 1 : 0,
      'onArriveContext': onArriveContext ? 1 : 0,
      'enabled': enabled ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'lastTriggeredAt': lastTriggeredAt?.toIso8601String(),
      'triggerCount': triggerCount,
      'repeatInterval': repeatInterval,
      'repeatUnit': repeatUnit,
    };
  }

  /// Get context type icons
  List<String> getContextIcons() {
    final icons = <String>[];
    if (timeAt != null) icons.add('⏰');
    if (geofenceId != null) icons.add('📍');
    if (wifiSsid != null) icons.add('📶');
    if (onLeaveContext) icons.add('🚪');
    if (onArriveContext) icons.add('🏠');
    return icons;
  }

  /// Get context description
  String getContextDescription() {
    final parts = <String>[];

    if (repeatInterval != null && repeatUnit != null) {
      parts.add('Every $repeatInterval $repeatUnit');
    } else if (timeAt != null) {
      parts.add('at ${_formatTime(timeAt!)}');
    }
    if (onLeaveContext && geofenceId != null) {
      parts.add('when leaving');
    }
    if (onArriveContext && geofenceId != null) {
      parts.add('when arriving');
    }
    if (wifiSsid != null) {
      parts.add('via Wi-Fi: $wifiSsid');
    }

    return parts.isEmpty ? 'No context set' : parts.join(' • ');
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Check if this is a recurring reminder
  bool get isRecurring => repeatInterval != null && repeatUnit != null;

  /// Copy with method for updates
  Reminder copyWith({
    String? text,
    DateTime? timeAt,
    String? geofenceId,
    double? geofenceLat,
    double? geofenceLng,
    double? geofenceRadius,
    String? wifiSsid,
    bool? onLeaveContext,
    bool? onArriveContext,
    bool? enabled,
    DateTime? lastTriggeredAt,
    int? triggerCount,
    int? repeatInterval,
    String? repeatUnit,
  }) {
    return Reminder(
      id: id,
      text: text ?? this.text,
      timeAt: timeAt ?? this.timeAt,
      geofenceId: geofenceId ?? this.geofenceId,
      geofenceLat: geofenceLat ?? this.geofenceLat,
      geofenceLng: geofenceLng ?? this.geofenceLng,
      geofenceRadius: geofenceRadius ?? this.geofenceRadius,
      wifiSsid: wifiSsid ?? this.wifiSsid,
      onLeaveContext: onLeaveContext ?? this.onLeaveContext,
      onArriveContext: onArriveContext ?? this.onArriveContext,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
      triggerCount: triggerCount ?? this.triggerCount,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      repeatUnit: repeatUnit ?? this.repeatUnit,
    );
  }
}
