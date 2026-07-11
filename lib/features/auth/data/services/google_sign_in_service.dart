import 'package:google_sign_in/google_sign_in.dart';

/// Wrapper tipis di atas plugin google_sign_in v7 — satu-satunya titik yang
/// menyentuh plugin agar `AuthRemoteDataSourceImpl` tetap bisa di-unit-test
/// (plugin memakai singleton statis yang tak bisa di-mock langsung).
class GoogleSignInService {
  Future<void>? _initFuture;

  /// Return idToken Google, atau null bila user MEMBATALKAN dialog.
  /// Throw untuk kegagalan lain (jaringan, Play Services, konfigurasi).
  Future<String?> getIdToken() async {
    try {
      // serverClientId di Android terbaca dari google-services.json
      // (web OAuth client dibuat otomatis saat provider Google diaktifkan).
      await (_initFuture ??= GoogleSignIn.instance.initialize());
    } catch (_) {
      // Init gagal (mis. jaringan) TIDAK boleh permanen — reset agar tap
      // tombol berikutnya mencoba initialize ulang, bukan replay error lama.
      _initFuture = null;
      rethrow;
    }
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw StateError(
          'idToken null — cek serverClientId/google-services.json (oauth_client web).',
        );
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }
}
