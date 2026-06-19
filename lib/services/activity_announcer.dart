import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import '../features/auth/domain/entities/step_data.dart';

class ActivityAnnouncer {
  final FlutterTts _tts = FlutterTts();
  Timer? _debounceTimer;
  ActivityType? _lastAnnounced;
  ActivityType? _pendingType;

  String? lastSpokenText;

  void onActivityUpdate(ActivityType type) {
    if (type == _lastAnnounced) {
      _debounceTimer?.cancel();
      _debounceTimer = null;
      _pendingType = null;
      return;
    }

    if (_pendingType != type) {
      _debounceTimer?.cancel();
      _pendingType = type;
      _debounceTimer = Timer(const Duration(seconds: 2), () {
        final typeToAnnounce = _pendingType!;
        _pendingType = null;
        _lastAnnounced = typeToAnnounce;
        _speak(typeToAnnounce);
      });
    }
  }

  String _getMessage(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return 'Estás corriendo';
      case ActivityType.walking:
        return 'Cambiaste a caminata';
      case ActivityType.stationary:
        return 'Te has detenido';
    }
  }

  Future<void> _speak(ActivityType type) async {
    final message = _getMessage(type);
    lastSpokenText = message;
    try {
      await _tts.setLanguage('es-ES');
      await _tts.setSpeechRate(0.4);
      final result = await _tts.speak(message);
      if (result == null) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _tts.speak(message);
      }
    } catch (_) {}
  }

  Future<void> speakMessage(String message) async {
    _debounceTimer?.cancel();
    lastSpokenText = message;
    try {
      await _tts.setLanguage('es-ES');
      await _tts.setSpeechRate(0.4);
      final result = await _tts.speak(message);
      if (result == null) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _tts.speak(message);
      }
    } catch (_) {}
  }

  void dispose() {
    _debounceTimer?.cancel();
    _tts.stop();
  }
}
