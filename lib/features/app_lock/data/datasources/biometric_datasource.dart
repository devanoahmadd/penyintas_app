import 'package:local_auth/local_auth.dart';

/// Wrapper tipis local_auth. Abstrak agar bisa di-mock. Selalu fail-safe:
/// error apa pun → dianggap tidak tersedia / gagal (jatuh ke PIN).
abstract class BiometricDataSource {
  Future<bool> isAvailable();
  Future<bool> authenticate(String reason);
}

class BiometricDataSourceImpl implements BiometricDataSource {
  BiometricDataSourceImpl(this._auth);
  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!supported || !canCheck) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
