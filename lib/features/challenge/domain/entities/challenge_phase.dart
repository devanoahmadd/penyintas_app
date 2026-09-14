import 'package:equatable/equatable.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_week.dart';

/// Satu-satunya sumber kebenaran "layar sedang menampilkan keadaan apa" (S1).
///
/// Tile dashboard DAN halaman /challenge sama-sama men-`switch` nilai ini.
/// Selama salah satunya menghitung sendiri, keduanya bisa berbeda pendapat —
/// dan app yang tidak sepakat dengan dirinya sendiri adalah hal yang T11 tolak.
///
/// Kartu hasil BUKAN phase: ia lapisan terpisah yang berlaku di atas phase apa
/// pun, sehingga irisan "sakelar mati + hasil belum dilihat" tidak butuh
/// aturan tambahan.
sealed class ChallengePhase extends Equatable {
  const ChallengePhase();

  @override
  List<Object?> get props => const [];
}

/// Sakelar mati. Selalu menang atas apa pun (jaring 1b menjamin kombinasi
/// "sakelar mati + baris active" tak bertahan lebih dari satu kali ensure).
final class PhaseDisabled extends ChallengePhase {
  const PhaseDisabled();
}

/// Props memuat SELURUH [week], bukan hanya `weekKey`. Rev 1 memakai
/// `[row.weekKey, spent]`; ganti pos di Senin pagi (saat `spent` masih nol)
/// menghasilkan dua `PhaseActive` yang dianggap sama, dan kartu tidak pernah
/// dirender ulang dengan kategori barunya. `ChallengeWeek` sudah sempit, jadi
/// membandingkannya utuh tidak menambah rebuild yang sia-sia.
final class PhaseActive extends ChallengePhase {
  const PhaseActive({required this.week, required this.spent});

  final ChallengeWeek week;
  final int spent;

  @override
  List<Object?> get props => [week, spent];
}

final class PhaseOver extends ChallengePhase {
  const PhaseOver({required this.week, required this.spent});

  final ChallengeWeek week;
  final int spent;

  @override
  List<Object?> get props => [week, spent];
}

final class PhaseHeld extends ChallengePhase {
  const PhaseHeld(this.week);

  final ChallengeWeek week;

  @override
  List<Object?> get props => [week];
}

/// Minggu ini sudah selesai urusannya: dilewati, sudah dievaluasi (bisa terjadi
/// lewat merge lintas-device), atau berstatus tak dikenal dari versi app lebih
/// baru. Ketiganya berkata sama ke user: "Mulai Senin depan."
final class PhaseSettledThisWeek extends ChallengePhase {
  const PhaseSettledThisWeek(this.week);

  final ChallengeWeek week;

  @override
  List<Object?> get props => [week];
}

final class PhaseOutOfWindow extends ChallengePhase {
  const PhaseOutOfWindow({required this.isFirstWeek});

  final bool isFirstWeek;

  @override
  List<Object?> get props => [isFirstWeek];
}

final class PhaseNotEnoughData extends ChallengePhase {
  const PhaseNotEnoughData();
}

/// Belum diketahui SELAGI di dalam jendela — entah kandidat belum sempat
/// dihitung (`candidateCount == null`, berumur milidetik) atau lingkungan tak
/// terbaca (timeout / Left, berumur detik). Tile merender skeleton, halaman
/// merender kartu penjelas.
///
/// Ini keadaan SEMENTARA. Jangan pernah menaruh keadaan terminal di sini —
/// skeleton yang tak pernah selesai adalah salah satu kerusakan yang paling
/// lama tak dilaporkan user, karena tampak seperti koneksi lambat.
final class PhaseUndetermined extends ChallengePhase {
  const PhaseUndetermined();
}

final class PhaseBudgetNotSet extends ChallengePhase {
  const PhaseBudgetNotSet();
}

/// Semua syarat lolos, ensure belum sempat menulis. Berumur milidetik.
final class PhasePreparing extends ChallengePhase {
  const PhasePreparing();
}
