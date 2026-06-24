import '../entities/activity_record.dart';

abstract class ActivityRepository {
  Future<int> create(ActivityRecord record);
  Future<List<ActivityRecord>> getAll();
  Future<ActivityRecord?> getById(int id);
  Future<void> update(ActivityRecord record);
  Future<void> delete(int id);
  Future<void> deleteAll();
  Future<Map<String, dynamic>> getStats();
}
