import 'dart:async';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../domain/entities/step_data.dart';

abstract class AccelerometerDataSource {
  Stream<StepData> get stepStream;
  Future<void> startCounting();
  Future<void> stopCounting();
  Future<bool> requestPermissions();
}

class AccelerometerDataSourceImpl implements AccelerometerDataSource {
  StreamController<StepData>? _controller;
  StreamSubscription<AccelerometerEvent>? _subscription;
  bool _isRunning = false;

  int _stepCount = 0;

  // Anti-bounce 300ms para pasos (Regla 2)
  DateTime _lastStepTime = DateTime.now();

  // Ventanas de tiempo 3s para estados de voz (Regla 3)
  DateTime _lastWalkTime = DateTime.now().subtract(const Duration(seconds: 10));
  DateTime _lastRunTime = DateTime.now().subtract(const Duration(seconds: 10));

  static const double _walkThreshold = 13.0;
  static const double _runThreshold = 17.0;
  static const Duration _debounceDelay = Duration(milliseconds: 300);
  static const Duration _timeWindow = Duration(seconds: 3);

  @override
  Stream<StepData> get stepStream =>
      _controller?.stream ?? const Stream.empty();

  @override
  Future<void> startCounting() async {
    if (_isRunning) return;
    _isRunning = true;

    _stepCount = 0;
    _lastStepTime = DateTime.now();
    _lastWalkTime = DateTime.now().subtract(const Duration(seconds: 10));
    _lastRunTime = DateTime.now().subtract(const Duration(seconds: 10));

    _controller = StreamController<StepData>.broadcast(
      onCancel: () {},
    );

    _subscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen(
      _onSensorEvent,
      onError: (error) {
        print('AccelerometerDataSource error: $error');
      },
    );
  }

  void _onSensorEvent(AccelerometerEvent event) {
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    final now = DateTime.now();

    // ═══════════════════════════════════════════════
    // REGLA 2: Anti-bounce 300ms para pasos
    // ═══════════════════════════════════════════════
    // Solo cuenta paso si:
    //   a) magnitud > 13.0 (umbral de caminata)
    //   b) han pasado >300ms desde el último paso
    if (magnitude > _walkThreshold &&
        now.difference(_lastStepTime).inMilliseconds > _debounceDelay.inMilliseconds) {
      _stepCount++;
      _lastStepTime = now;
    }

    // ═══════════════════════════════════════════════
    // REGLA 3: Ventanas de tiempo para estados
    // ═══════════════════════════════════════════════
    // Actualizar timestamp de cada umbral
    if (magnitude > _runThreshold) {
      _lastRunTime = now;
    }
    if (magnitude > _walkThreshold) {
      _lastWalkTime = now;
    }

    // Determinar estado por ventanas de 3 segundos
    final activityType = _resolveActivity(now);

    _controller?.add(StepData(
      stepCount: _stepCount,
      activityType: activityType,
      magnitude: magnitude,
      rawMagnitude: magnitude,
    ));
  }

  ActivityType _resolveActivity(DateTime now) {
    // Si hay running en los últimos 3s → CORRIENDO
    if (now.difference(_lastRunTime) < _timeWindow) {
      return ActivityType.running;
    }
    // Si hay walking en los últimos 3s → CAMINANDO
    if (now.difference(_lastWalkTime) < _timeWindow) {
      return ActivityType.walking;
    }
    // Si pasaron 3s sin actividad → QUIETO
    return ActivityType.stationary;
  }

  @override
  Future<void> stopCounting() async {
    _subscription?.cancel();
    _subscription = null;
    await _controller?.close();
    _controller = null;
    _isRunning = false;
  }

  @override
  Future<bool> requestPermissions() async {
    final activityStatus = await Permission.activityRecognition.request();
    final sensorsStatus = await Permission.sensors.request();
    return activityStatus.isGranted && sensorsStatus.isGranted;
  }
}
