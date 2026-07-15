import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper tipis flutter_secure_storage untuk App Lock. Dibuat abstrak agar
/// bisa di-mock — platform channel tak dapat di-unit-test langsung.
abstract class AppLockSecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class AppLockSecureStoreImpl implements AppLockSecureStore {
  AppLockSecureStoreImpl(this._storage);
  final FlutterSecureStorage _storage;

  // `encryptedSharedPreferences` sengaja tidak diisi: parameter itu
  // @Deprecated di flutter_secure_storage v10.3.1 (Jetpack Security library
  // dibuang) dan diabaikan begitu saja. Default baru sudah lebih kuat:
  // AES_GCM_NoPadding untuk data + RSA_ECB_OAEPwithSHA_256andMGF1Padding
  // untuk key-wrapping, hardware-backed KeyStore.
  static const _android = AndroidOptions();

  @override
  Future<String?> read(String key) =>
      _storage.read(key: key, aOptions: _android);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value, aOptions: _android);

  @override
  Future<void> delete(String key) =>
      _storage.delete(key: key, aOptions: _android);
}
