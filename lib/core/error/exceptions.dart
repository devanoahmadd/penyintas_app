class ServerException implements Exception {
  final String message;
  const ServerException([
    this.message = 'Server sedang bermasalah. Coba lagi sebentar lagi.',
  ]);
}

class CacheException implements Exception {
  final String message;
  const CacheException([
    this.message = 'Data di perangkatmu belum bisa dibaca. Coba lagi ya.',
  ]);
}

class AuthException implements Exception {
  final String message;
  const AuthException([
    this.message = 'Kami belum bisa memverifikasi akunmu. Coba masuk lagi.',
  ]);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([
    this.message = 'Tidak ada koneksi. Data tersimpan lokal.',
  ]);
}

class ValidationException implements Exception {
  final String message;
  const ValidationException([
    this.message = 'Ada isian yang belum pas. Cek lagi sebentar.',
  ]);
}
