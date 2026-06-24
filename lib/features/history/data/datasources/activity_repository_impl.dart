import 'package:sqflite/sqflite.dart';
import '../../domain/entities/activity_record.dart';
import '../../domain/repositories/activity_repository.dart';
import '../models/activity_record_model.dart';
import 'database_helper.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final DatabaseHelper _helper;

  ActivityRepositoryImpl({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  Future<Database> get _db async => _helper.database;

  @override
  Future<int> create(ActivityRecord record) async {
    final db = await _db;
    return db.insert(
      DatabaseHelper.tableActivity,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<ActivityRecord>> getAll() async {
    final db = await _db;
    final maps = await db.query(
      DatabaseHelper.tableActivity,
      orderBy: '${DatabaseHelper.colStartTime} DESC',
    );
    return maps.map(ActivityRecordModel.fromMap).toList();
  }

  @override
  Future<ActivityRecord?> getById(int id) async {
    final db = await _db;
    final maps = await db.query(
      DatabaseHelper.tableActivity,
      where: '${DatabaseHelper.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ActivityRecordModel.fromMap(maps.first);
  }

  @override
  Future<void> update(ActivityRecord record) async {
    assert(record.id != null, 'No se puede actualizar un registro sin id');
    final db = await _db;
    await db.update(
      DatabaseHelper.tableActivity,
      record.toMap(),
      where: '${DatabaseHelper.colId} = ?',
      whereArgs: [record.id],
    );
  }

  @override
  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete(
      DatabaseHelper.tableActivity,
      where: '${DatabaseHelper.colId} = ?',
      whereArgs: [id],
    );
  }

  /// Borra todos los registros del historial.
  @override
  Future<void> deleteAll() async {
    final db = await _db;
    await db.delete(DatabaseHelper.tableActivity);
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT
        COUNT(*)                           AS totalSessions,
        COALESCE(SUM(steps), 0)            AS totalSteps,
        COALESCE(SUM(distance_km), 0)      AS totalDistanceKm,
        COALESCE(SUM(calories), 0)         AS totalCalories,
        COALESCE(SUM((end_time - start_time) / 60000), 0) AS totalMinutes
      FROM ${DatabaseHelper.tableActivity}
    ''');

    if (result.isEmpty) {
      return {
        'totalSessions': 0,
        'totalSteps': 0,
        'totalDistanceKm': 0.0,
        'totalCalories': 0.0,
        'totalMinutes': 0,
      };
    }

    final row = result.first;
    return {
      'totalSessions': row['totalSessions'] as int,
      'totalSteps': row['totalSteps'] as int,
      'totalDistanceKm': (row['totalDistanceKm'] as num).toDouble(),
      'totalCalories': (row['totalCalories'] as num).toDouble(),
      'totalMinutes': row['totalMinutes'] as int,
    };
  }
}
