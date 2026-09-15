import 'package:equatable/equatable.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_phase.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_week.dart';

/// Bahan MURAH & REAKTIF yang lahir dari stream `watchInputs()` (S-B).
///
/// Sengaja TIDAK memuat `phase`: `phase` juga butuh `candidateCount` (proyeksi
/// empat minggu penuh) dan `env` (satu bacaan dashboard ber-timeout tiga
/// detik). Menghitung ulang keduanya tiap kali tabel transaksi berubah adalah
/// harga yang tak akan pernah sepadan di HP kelas bawah — jadi keduanya datang
/// dari `EnsureOutcome`, dan perakitannya terjadi di BLoC.
///
/// Juga TIDAK memuat `daysLeft`: ia berubah karena WAKTU berjalan, bukan karena
/// tabel berubah, dan stream yang meng-emit ulang tiap tengah malam bukan yang
/// kita mau. BLoC menghitungnya dari `AppClock` saat merakit.
class ChallengeInputs extends Equatable {
  const ChallengeInputs({
    required this.weekThisWeek,
    required this.spentThisWeek,
    required this.excludedThisWeek,
    required this.history,
    required this.enabled,
  });

  /// Baris minggu berjalan, `null` bila belum ada.
  final ChallengeWeek? weekThisWeek;

  /// Belanja OPERASIONAL kategori tantangan minggu ini (S-D: `!isFixed` dan
  /// `sourceBillId IS NULL`). Nol bila belum ada baris/kategori.
  final int spentThisWeek;

  /// Komplemen persis [spentThisWeek] — melayani baris penjelas §7.4.
  final int excludedThisWeek;

  /// Riwayat terurut weekKey MENURUN, maksimal `kChallengeHistoryWeeks`.
  final List<ChallengeWeek> history;

  /// Sakelar fitur. Reaktif: ikut stream, bukan bacaan sekali di awal — kalau
  /// tidak, menyalakannya di Pengaturan tak mengubah apa pun di layar sampai
  /// ada perubahan tabel lain yang kebetulan memicu emit.
  final bool enabled;

  @override
  List<Object?> get props => [
    weekThisWeek,
    spentThisWeek,
    excludedThisWeek,
    history,
    enabled,
  ];
}

/// Satu-satunya bentuk yang dibaca tile dashboard DAN halaman `/challenge`
/// (S1). Dirakit di `ChallengeBloc` — sekali, di satu tempat — dari bahan
/// murah milik [ChallengeInputs] dan bahan mahal milik `EnsureOutcome`.
class ChallengeSnapshot extends Equatable {
  const ChallengeSnapshot({
    required this.phase,
    required this.pendingResult,
    required this.spentThisWeek,
    required this.excludedThisWeek,
    required this.history,
    required this.daysLeft,
  });

  final ChallengePhase phase;

  /// Kartu hasil BUKAN phase: ia lapisan terpisah yang berlaku di atas phase
  /// apa pun. `null` bila tak ada hasil yang belum dilihat.
  final ChallengeWeek? pendingResult;

  final int spentThisWeek;
  final int excludedThisWeek;
  final List<ChallengeWeek> history;

  /// Sisa hari kalender minggu ini, TERMASUK hari ini. Senin = 7, Minggu = 1.
  final int daysLeft;

  @override
  List<Object?> get props => [
    phase,
    pendingResult,
    spentThisWeek,
    excludedThisWeek,
    history,
    daysLeft,
  ];
}
