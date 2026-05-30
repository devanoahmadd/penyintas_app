/// Shared auth validation utilities.
///
/// Gunakan constants ini secara konsisten di semua halaman auth —
/// jangan duplikat regex inline.
class AuthValidators {
  const AuthValidators._();

  /// Regex email klien — anchor penuh, tolak whitespace di lokal & domain.
  /// Firebase tetap jadi otoritas validasi di server.
  static final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
}
