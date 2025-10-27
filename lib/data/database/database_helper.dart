import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';

/// Database helper singleton for SQLite operations
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Get database instance (lazy initialization)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.dbName);
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Create database tables
  Future<void> _createDB(Database db, int version) async {
    // Reminders table
    await db.execute('''
      CREATE TABLE ${AppConstants.remindersTable} (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        timeAt TEXT,
        geofenceId TEXT,
        geofenceLat REAL,
        geofenceLng REAL,
        geofenceRadius REAL,
        wifiSsid TEXT,
        onLeaveContext INTEGER DEFAULT 0,
        onArriveContext INTEGER DEFAULT 0,
        enabled INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        lastTriggeredAt TEXT,
        triggerCount INTEGER DEFAULT 0,
        repeatInterval INTEGER,
        repeatUnit TEXT
      )
    ''');

    // Context events table
    await db.execute('''
      CREATE TABLE ${AppConstants.contextEventsTable} (
        id TEXT PRIMARY KEY,
        reminderId TEXT NOT NULL,
        contextType TEXT NOT NULL,
        triggerTime TEXT NOT NULL,
        outcome TEXT NOT NULL,
        metadata TEXT,
        FOREIGN KEY (reminderId) REFERENCES ${AppConstants.remindersTable} (id)
          ON DELETE CASCADE
      )
    ''');

    // Locations table
    await db.execute('''
      CREATE TABLE ${AppConstants.locationsTable} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        radius REAL DEFAULT 100.0,
        wifiSsid TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create indexes for performance
    await db.execute('''
      CREATE INDEX idx_reminders_enabled 
      ON ${AppConstants.remindersTable} (enabled)
    ''');

    await db.execute('''
      CREATE INDEX idx_context_events_reminder 
      ON ${AppConstants.contextEventsTable} (reminderId)
    ''');

    await db.execute('''
      CREATE INDEX idx_context_events_time 
      ON ${AppConstants.contextEventsTable} (triggerTime)
    ''');
  }

  /// Upgrade database schema
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations here
    if (oldVersion < 2) {
      // Add recurrence fields - check if they exist first
      try {
        await db.execute(
          'ALTER TABLE ${AppConstants.remindersTable} ADD COLUMN repeatInterval INTEGER',
        );
      } catch (e) {
        // Column might already exist, ignore error
        print('repeatInterval column already exists or error: $e');
      }

      try {
        await db.execute(
          'ALTER TABLE ${AppConstants.remindersTable} ADD COLUMN repeatUnit TEXT',
        );
      } catch (e) {
        // Column might already exist, ignore error
        print('repeatUnit column already exists or error: $e');
      }
    }
  }

  /// Close database
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }

  /// Delete database (for testing/reset)
  Future<void> deleteDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
    await deleteDatabase(path);
    _database = null;
  }
}
