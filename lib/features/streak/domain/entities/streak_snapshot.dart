import 'package:equatable/equatable.dart';

/// Status hari ini terhadap streak.
enum DayStatus {
  /// Hari ini ada sebelum riwayat dimulai (belum ada hari aman sama sekali).
  beforeStart,

  /// Hari ini sudah aman — ada transaksi atau penanda nihil.
  safe,

  /// Hari ini belum aman, tapi harinya juga belum lewat.
  pending,

  /// Jam device mundur 1–2 hari dari hari tertinggi yang pernah dilihat.
  /// Mode netral: streak tidak berubah, penandaan ditolak (Task 5).
  anomaly,
}

/// Status satu petak kalender. Presedensinya dikunci di [StreakSnapshot.cellFor].
enum DayCell {
  beforeStart,
  recorded,
  markedNihil,
  graceUsed,
  missed,
  today,
  future,
}

/// Hasil hitung streak. SELALU turunan — tidak pernah dibaca dari penyimpanan.
class StreakSnapshot extends Equatable {
  const StreakSnapshot({
    required this.hasStarted,
    required this.activatedDay,
    required this.currentStreak,
    required this.longestRuas,
    required this.graceAvailable,
    required this.graceUsedDays,
    required this.todayStatus,
    required this.today,
    required this.nextLastSeenDay,
    required this.lastBreakDay,
    required this.brokenRunLength,
    required this.markedDays,
    required this.markedDaysAll,
    required this.transactionDays,
  });

  /// false selama belum ada satu pun hari aman sejak epoch. UI wajib
  /// menampilkan empty state, BUKAN angka 0.
  final bool hasStarted;

  /// Hari pertama yang ikut dihitung. Diturunkan, tidak disimpan: hari aman
  /// paling awal bila ada, selain itu `max(today, epoch)`.
  final int activatedDay;

  final int currentStreak;
  final int longestRuas;

  /// 0..2.
  final int graceAvailable;

  /// Hari yang ruasnya disambung oleh jeda — untuk render kalender.
  final Set<int> graceUsedDays;

  final DayStatus todayStatus;

  /// `effectiveToday` yang dipakai perhitungan ini (bisa berbeda dari hari
  /// device saat mode netral penjaga jam).
  final int today;

  /// Nilai yang HARUS ditulis StreakBloc ke `StreakMeta.lastSeenDay`.
  /// Kalkulator tidak pernah menulis apa pun (invarian spec §5.5).
  final int nextLastSeenDay;

  /// dayKey hari bolong yang memutus ruas terakhir; null bila belum pernah
  /// putus sejak `activatedDay`.
  final int? lastBreakDay;

  /// Panjang ruas yang putus itu — untuk copy "terhenti di 40 hari".
  final int brokenRunLength;

  /// Input yang disimpan supaya `cellFor` tetap murni & tanpa I/O.
  final Set<int> markedDays;

  /// Penanda MENTAH, termasuk baris `viaClockCorrection` (D-11/D-17).
  /// Ia menjawab **"sudah pernah ditekan?"**, BUKAN **"menghitung?"**.
  /// `cellFor` dan replay DILARANG menyentuhnya — keduanya memakai
  /// [markedDays] yang sudah bersih. Satu-satunya pembacanya adalah aturan
  /// CTA di halaman `/consistency`.
  final Set<int> markedDaysAll;

  final Set<int> transactionDays;

  @override
  List<Object?> get props => [
    hasStarted,
    activatedDay,
    currentStreak,
    longestRuas,
    graceAvailable,
    graceUsedDays,
    todayStatus,
    today,
    nextLastSeenDay,
    lastBreakDay,
    brokenRunLength,
    markedDays,
    markedDaysAll,
    transactionDays,
  ];
}
