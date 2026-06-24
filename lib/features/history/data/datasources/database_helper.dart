import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DatabaseHelper {
  static const _dbName = 'fitness_tracker.db';
  static const _dbVersion = 1;

  static const tableActivity = 'activity_records';
  static const colId = 'id';
  static const colCategory = 'category';
  static const colStartTime = 'start_time';
  static const colEndTime = 'end_time';
  static const colSteps = 'steps';
  static const colDistanceKm = 'distance_km';
  static const colCalories = 'calories';
  static const colAverageSpeedKmh = 'average_speed_kmh';
  static const colNotes = 'notes';

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableActivity (
        $colId               INTEGER PRIMARY KEY AUTOINCREMENT,
        $colCategory         TEXT    NOT NULL,
        $colStartTime        INTEGER NOT NULL,
        $colEndTime          INTEGER NOT NULL,
        $colSteps            INTEGER NOT NULL DEFAULT 0,
        $colDistanceKm       REAL    NOT NULL DEFAULT 0,
        $colCalories         REAL    NOT NULL DEFAULT 0,
        $colAverageSpeedKmh  REAL    NOT NULL DEFAULT 0,
        $colNotes            TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_activity_start ON $tableActivity ($colStartTime DESC)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
