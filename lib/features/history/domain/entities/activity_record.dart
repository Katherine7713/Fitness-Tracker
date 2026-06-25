import 'package:equatable/equatable.dart';

enum ActivityCategory {
  walking,
  running,
  cycling,
  gym,
  stationary,
  other,
}

extension ActivityCategoryX on ActivityCategory {
  String get label => switch (this) {
        ActivityCategory.walking => 'Caminata',
        ActivityCategory.running => 'Carrera',
        ActivityCategory.cycling => 'Ciclismo',
        ActivityCategory.gym => 'Gimnasio',
        ActivityCategory.stationary => 'Quieto',
        ActivityCategory.other => 'Otra',
      };

  String get icon => switch (this) {
        ActivityCategory.walking => '🚶',
        ActivityCategory.running => '🏃',
        ActivityCategory.cycling => '🚴',
        ActivityCategory.gym => '🏋️',
        ActivityCategory.stationary => '🧍',
        ActivityCategory.other => '⚡',
      };

  static ActivityCategory fromString(String value) {
    return ActivityCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ActivityCategory.other,
    );
  }
}

class ActivityRecord extends Equatable {
  final int? id;
  final ActivityCategory category;
  final DateTime startTime;
  final DateTime endTime;
  final int steps;
  final double distanceKm;
  final double calories;
  final double averageSpeedKmh;
  final String? notes;

  const ActivityRecord({
    this.id,
    required this.category,
    required this.startTime,
    required this.endTime,
    this.steps = 0,
    this.distanceKm = 0,
    this.calories = 0,
    this.averageSpeedKmh = 0,
    this.notes,
  });

  Duration get duration => endTime.difference(startTime);

  String get formattedDuration {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  ActivityRecord copyWith({
    int? id,
    ActivityCategory? category,
    DateTime? startTime,
    DateTime? endTime,
    int? steps,
    double? distanceKm,
    double? calories,
    double? averageSpeedKmh,
    String? notes,
  }) {
    return ActivityRecord(
      id: id ?? this.id,
      category: category ?? this.category,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      steps: steps ?? this.steps,
      distanceKm: distanceKm ?? this.distanceKm,
      calories: calories ?? this.calories,
      averageSpeedKmh: averageSpeedKmh ?? this.averageSpeedKmh,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        category,
        startTime,
        endTime,
        steps,
        distanceKm,
        calories,
        averageSpeedKmh,
        notes,
      ];
}
