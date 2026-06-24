import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';
import '../../domain/entities/auth_result.dart';

/// DataSource para autenticación biométrica usando Platform Channels
/// - Este es el LADO FLUTTER del Platform Channel
/// - Usamos MethodChannel porque es petición/respuesta
/// - El nombre del canal DEBE coincidir con el lado Android
abstract class BiometricDataSource {
  Future<bool> canAuthenticate();
  Future<AuthResult> authenticate();
}

class BiometricDataSourceImpl implements BiometricDataSource {
  /// MethodChannel: canal de comunicación Flutter ↔ Android
  /// El nombre debe ser exactamente igual en ambos lados
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  Future<bool> canAuthenticate() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;

      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } on PlatformException catch (e) {
      print('BiometricDataSource.canAuthenticate error: ${e.message}');
      return false;
    }
  }

  @override
  Future<AuthResult> authenticate() async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason:
            'Usa tu huella dactilar para acceder a Fitness Tracker',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          sensitiveTransaction: false,
        ),
      );

      return AuthResult(
        success: authenticated,
        message:
            authenticated ? 'Autenticación exitosa' : 'Autenticación cancelada',
      );
    } on PlatformException catch (e) {
      final message = switch (e.code) {
        auth_error.notAvailable =>
          'Biometría no disponible en este dispositivo',
        auth_error.notEnrolled =>
          'No hay huellas registradas. Configura una en Ajustes',
        auth_error.lockedOut =>
          'Demasiados intentos fallidos. Intenta más tarde',
        auth_error.permanentlyLockedOut =>
          'Biometría bloqueada. Usa el PIN del dispositivo',
        _ => 'Error de autenticación: ${e.message}',
      };
      return AuthResult(success: false, message: message);
    }
  }
}
