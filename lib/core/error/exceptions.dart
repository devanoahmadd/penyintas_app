class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Terjadi kesalahan pada server.']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Gagal membaca data lokal.']);
}

class AuthException implements Exception {
  final String message;
  const AuthException([this.message = 'Autentikasi gagal.']);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Tidak ada koneksi internet.']);
}

class ValidationException implements Exception {
  final String message;
  const ValidationException([this.message = 'Data tidak valid.']);
}
