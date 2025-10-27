import 'package:uuid/uuid.dart';

/// Context event model for tracking reminder triggers and outcomes
class ContextEvent {
  final String id;
  final String reminderId;
  final String contextType;
  final DateTime triggerTime;
  final String outcome;
  final Map<String, dynamic>? metadata;

  ContextEvent({
    String? id,
    required this.reminderId,
    required this.contextType,
    DateTime? triggerTime,
    required this.outcome,
    this.metadata,
  }) : id = id ?? const Uuid().v4(),
       triggerTime = triggerTime ?? DateTime.now();

  /// Create ContextEvent from database map
  factory ContextEvent.fromMap(Map<String, dynamic> map) {
    return ContextEvent(
      id: map['id'] as String,
      reminderId: map['reminderId'] as String,
      contextType: map['contextType'] as String,
      triggerTime: DateTime.parse(map['triggerTime'] as String),
      outcome: map['outcome'] as String,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
    );
  }

  /// Convert ContextEvent to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reminderId': reminderId,
      'contextType': contextType,
      'triggerTime': triggerTime.toIso8601String(),
      'outcome': outcome,
      'metadata': metadata?.toString(),
    };
  }
}
