import 'package:equatable/equatable.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_environment.dart';

/// Apa yang ensure SEMPAT ketahui pada pemanggilan terakhirnya.
///
/// Ada karena `resolveChallengePhase` butuh `candidateCount` dan `env`, sedang
/// keduanya bukan bahan yang berbentuk stream: kandidat butuh proyeksi empat
/// minggu penuh, dan lingkungan butuh satu bacaan dashboard ber-timeout tiga
/// detik. Menghitung ulang keduanya tiap kali tabel transaksi berubah adalah
/// harga yang tak akan pernah sepadan di HP kelas bawah.
///
/// Yang membuatnya aman: daftar "kapan phase membutuhkannya" identik dengan
/// daftar "kapan ensure menghitungnya" — sakelar nyala DAN belum ada baris DAN
/// Senin/Selasa. Di luar itu, presedensi phase sudah menjawab lebih dulu di
/// tingkat 1 atau 2, dan nilai-nilai ini tak pernah dibaca.
///
/// [weekKey] BUKAN hiasan: BLoC wajib memperlakukan outcome dari minggu lain
/// sebagai tak diketahui. Tanpa penjaga itu, pergantian minggu memakai kandidat
/// minggu lalu selama beberapa milidetik.
class EnsureOutcome extends Equatable {
  const EnsureOutcome({
    required this.weekKey,
    required this.candidateCount,
    required this.env,
  });

  final int weekKey;

  /// `null` = tidak sempat dihitung. `0` = dihitung, memang tak ada yang layak.
  /// Memampatkan keduanya jadi `0` membuat kegagalan baca tampil sebagai
  /// "belum cukup data" — tuduhan yang salah alamat.
  final int? candidateCount;

  /// `null` = tidak sempat dibaca, ATAU dibaca dan gagal/timeout. Keduanya
  /// berarti hal yang sama untuk phase: belum diketahui.
  final ChallengeEnvironment? env;

  @override
  List<Object?> get props => [weekKey, candidateCount, env];
}
