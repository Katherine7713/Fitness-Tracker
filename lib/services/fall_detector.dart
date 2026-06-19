import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

typedef FallCallback = void Function();

class FallDetector {
  StreamSubscription<AccelerometerEvent>? _subscription;
  bool _isRunning = false;
  bool _potentialFall = false;
  DateTime? _impactTime;
  int _stillReadings = 0;

  FallCallback? onFallDetected;

  static const double _impactThreshold = 45.0;
  static const double _activityGuard = 15.0;
  static const double _stationaryThreshold = 11.0;
  static const Duration _postFallWindow = Duration(seconds: 2);
  static const int _requiredStillReadings = 5;
  static const Duration _timeout = Duration(seconds: 10);

  bool get isRunning => _isRunning;

  void start() {
    if (_isRunning) return;
    _isRunning = true;

    _subscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen(
      _onSensorEvent,
      onError: (error) {
        print('FallDetector stream error: $error');
      },
    );
  }

  void stop() {
    _subscription?.cancel();
    _isRunning = false;
    _potentialFall = false;
    _impactTime = null;
    _stillReadings = 0;
  }

  void _onSensorEvent(AccelerometerEvent event) {
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    if (!_potentialFall && magnitude > _impactThreshold) {
      _potentialFall = true;
      _impactTime = DateTime.now();
      _stillReadings = 0;
      return;
    }

    if (_potentialFall && _impactTime != null) {
      final elapsed = DateTime.now().difference(_impactTime!);

      // Si durante la ventana detectamos actividad (>15), no es caída
      if (elapsed < _postFallWindow && magnitude > _activityGuard) {
        _potentialFall = false;
        _impactTime = null;
        _stillReadings = 0;
        return;
      }

      // Después de la ventana, contar lecturas quietas consecutivas
      if (elapsed > _postFallWindow) {
        if (magnitude < _stationaryThreshold) {
          _stillReadings++;
          if (_stillReadings >= _requiredStillReadings) {
            onFallDetected?.call();
            _potentialFall = false;
            _impactTime = null;
            _stillReadings = 0;
          }
        } else {
          _stillReadings = 0;
        }
      }

      // Timeout de seguridad
      if (elapsed > _timeout) {
        _potentialFall = false;
        _impactTime = null;
        _stillReadings = 0;
      }
    }
  }

  void dispose() {
    stop();
  }
}
