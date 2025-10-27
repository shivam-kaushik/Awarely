import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/reminder.dart';
import '../models/context_event.dart';

/// Repository for reminder CRUD operations
class ReminderRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Create a new reminder
  Future<String> createReminder(Reminder reminder) async {
    final db = await _dbHelper.database;
    await db.insert(
      AppConstants.remindersTable,
      reminder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return reminder.id;
  }

  /// Get reminder by ID
  Future<Reminder?> getReminder(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.remindersTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Reminder.fromMap(maps.first);
  }

  /// Get all reminders
  Future<List<Reminder>> getAllReminders() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.remindersTable,
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => Reminder.fromMap(map)).toList();
  }

  /// Get active (enabled) reminders
  Future<List<Reminder>> getActiveReminders() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.remindersTable,
      where: 'enabled = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => Reminder.fromMap(map)).toList();
  }

  /// Update reminder
  Future<int> updateReminder(Reminder reminder) async {
    final db = await _dbHelper.database;
    return await db.update(
      AppConstants.remindersTable,
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  /// Delete reminder
  Future<int> deleteReminder(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      AppConstants.remindersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Toggle reminder enabled state
  Future<int> toggleReminder(String id, bool enabled) async {
    final db = await _dbHelper.database;
    return await db.update(
      AppConstants.remindersTable,
      {'enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update reminder trigger stats
  Future<void> updateTriggerStats(String id) async {
    final db = await _dbHelper.database;
    final reminder = await getReminder(id);
    if (reminder != null) {
      await db.update(
        AppConstants.remindersTable,
        {
          'lastTriggeredAt': DateTime.now().toIso8601String(),
          'triggerCount': reminder.triggerCount + 1,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  /// Create context event
  Future<String> createContextEvent(ContextEvent event) async {
    final db = await _dbHelper.database;
    await db.insert(
      AppConstants.contextEventsTable,
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return event.id;
  }

  /// Get context events for a reminder
  Future<List<ContextEvent>> getContextEvents(String reminderId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.contextEventsTable,
      where: 'reminderId = ?',
      whereArgs: [reminderId],
      orderBy: 'triggerTime DESC',
    );

    return maps.map((map) => ContextEvent.fromMap(map)).toList();
  }

  /// Get all context events
  Future<List<ContextEvent>> getAllContextEvents() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.contextEventsTable,
      orderBy: 'triggerTime DESC',
      limit: 100,
    );

    return maps.map((map) => ContextEvent.fromMap(map)).toList();
  }

  /// Get completion statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await _dbHelper.database;

    // Total reminders
    final totalCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${AppConstants.remindersTable}',
          ),
        ) ??
        0;

    // Active reminders
    final activeCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${AppConstants.remindersTable} WHERE enabled = 1',
          ),
        ) ??
        0;

    // Total events
    final totalEvents =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${AppConstants.contextEventsTable}',
          ),
        ) ??
        0;

    // Completed events
    final completedEvents =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${AppConstants.contextEventsTable} WHERE outcome = ?',
            [AppConstants.outcomeCompleted],
          ),
        ) ??
        0;

    // Calculate completion rate
    final completionRate = totalEvents > 0
        ? (completedEvents / totalEvents * 100).round()
        : 0;

    return {
      'totalReminders': totalCount,
      'activeReminders': activeCount,
      'totalEvents': totalEvents,
      'completedEvents': completedEvents,
      'completionRate': completionRate,
    };
  }
}
