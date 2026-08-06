import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/core/error/failures.dart';

/// M7 — default message tiap `Failure` adalah teks yang PALING mungkin
/// muncul di layar error (sesudah 7.2b meneruskan error stream sebagai
/// `Left`). Register-nya tunduk pada aturan copy: hangat, sapaan "kamu",
/// tidak menakuti, tanpa jargon.
///
/// `Exception` ikut dikunci di sini, bukan di file terpisah, karena keduanya
/// adalah SATU register yang kebetulan tinggal di dua file. Repository
/// menyalin `e.message` ke dalam `Failure` (`budget_repository_impl.dart:39`),
/// jadi memperbaiki satu sisi saja meninggalkan teks lama di jalur yang
/// justru paling sering jalan. Test `parity` di bawah yang menahannya.
void main() {
  test('default message tiap Failure sesuai aturan voice', () {
    expect(
      const ServerFailure().message,
      'Server sedang bermasalah. Coba lagi sebentar lagi.',
    );
    expect(
      const CacheFailure().message,
      'Data di perangkatmu belum bisa dibaca. Coba lagi ya.',
    );
    expect(
      const AuthFailure().message,
      'Kami belum bisa memverifikasi akunmu. Coba masuk lagi.',
    );
    expect(
      const NetworkFailure().message,
      'Tidak ada koneksi. Data tersimpan lokal.',
    );
    expect(
      const ValidationFailure().message,
      'Ada isian yang belum pas. Cek lagi sebentar.',
    );
    expect(
      const UnknownFailure().message,
      'Ada yang tidak beres. Coba muat ulang sebentar lagi.',
    );
  });

  test('message eksplisit menang atas default', () {
    expect(const CacheFailure('Pesan khusus').message, 'Pesan khusus');
  });

  test(
    'PARITY Exception ↔ Failure: register-nya kata-per-kata sama. Repository '
    'menyalin e.message ke dalam Failure, jadi dua sisi yang menyimpang '
    'berarti pengguna membaca teks lama lewat jalur yang paling sering jalan',
    () {
      expect(const ServerException().message, const ServerFailure().message);
      expect(const CacheException().message, const CacheFailure().message);
      expect(const AuthException().message, const AuthFailure().message);
      expect(const NetworkException().message, const NetworkFailure().message);
      expect(
        const ValidationException().message,
        const ValidationFailure().message,
      );
    },
  );
}
