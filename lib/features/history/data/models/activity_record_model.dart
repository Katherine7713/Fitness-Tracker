import '../../domain/entities/activity_record.dart';

extension ActivityRecordModel on ActivityRecord {
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category': category.name,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime.millisecondsSinceEpoch,
      'steps': steps,
      'distance_km': distanceKm,
      'calories': calories,
      'average_speed_kmh': averageSpeedKmh,
      'notes': notes,
    };
  }

  static ActivityRecord fromMap(Map<String, dynamic> map) {
    return ActivityRecord(
      id: map['id'] as int?,
      category: ActivityCategoryX.fromString(map['category'] as String),
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int),
      steps: map['steps'] as int? ?? 0,
      distanceKm: (map['distance_km'] as num?)?.toDouble() ?? 0,
      calories: (map['calories'] as num?)?.toDouble() ?? 0,
      averageSpeedKmh: (map['average_speed_kmh'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String?,
    );
  }
}
