import 'package:equatable/equatable.dart';

/// Tipos de actividad detectados
enum ActivityType {
  stationary, // Quieto
  walking, // Caminando
  running, // Corriendo
}

/// Datos del acelerómetro
class StepData extends Equatable {
  final int stepCount;
  final ActivityType activityType;
  final double magnitude;
  final double rawMagnitude;

  const StepData({
    required this.stepCount,
    required this.activityType,
    required this.magnitude,
    required this.rawMagnitude,
  });

  /// Calorías estimadas (0.04 cal por paso)
  double get estimatedCalories => stepCount * 0.04;

  factory StepData.fromMap(Map<dynamic, dynamic> map) {
    final activityTypeString = map['activityType'] as String;

    return StepData(
      stepCount: map['stepCount'] as int,
      activityType: _parseActivityType(activityTypeString),
      magnitude: (map['magnitude'] as num).toDouble(),
      rawMagnitude: (map['rawMagnitude'] as num?)?.toDouble() ?? (map['magnitude'] as num).toDouble(),
    );
  }

  static ActivityType _parseActivityType(String type) {
    switch (type) {
      case 'walking':
        return ActivityType.walking;
      case 'running':
        return ActivityType.running;
      default:
        return ActivityType.stationary;
    }
  }

  @override
  List<Object> get props => [stepCount, activityType, magnitude, rawMagnitude];
}
