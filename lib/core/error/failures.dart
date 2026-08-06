import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Server sedang bermasalah. Coba lagi sebentar lagi.',
  ]);
}

class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'Data di perangkatmu belum bisa dibaca. Coba lagi ya.',
  ]);
}

class AuthFailure extends Failure {
  const AuthFailure([
    super.message = 'Kami belum bisa memverifikasi akunmu. Coba masuk lagi.',
  ]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Tidak ada koneksi. Data tersimpan lokal.',
  ]);
}

class ValidationFailure extends Failure {
  const ValidationFailure([
    super.message = 'Ada isian yang belum pas. Cek lagi sebentar.',
  ]);
}

class UnknownFailure extends Failure {
  const UnknownFailure([
    super.message = 'Ada yang tidak beres. Coba muat ulang sebentar lagi.',
  ]);
}
