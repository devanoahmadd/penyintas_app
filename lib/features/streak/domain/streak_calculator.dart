import 'package:penyintas_app/core/utils/date_helper.dart';
import 'package:penyintas_app/features/streak/domain/entities/streak_snapshot.dart';

/// Jumlah hari aman berturut yang memanen satu jeda.
const int _kGracePeriod = 7;

/// Plafon jeda yang bisa ditahan sekaligus.
const int _kGraceMax = 2;

/// Hitung snapshot streak dari fakta harian. MURNI: tanpa I/O, tanpa jam,
/// tanpa database — seluruh turunan sudah terjadi di lapisan datasource.
///
/// [markedDays] penanda nihil yang SUDAH bersih dari baris `viaClockCorrection`.
/// [transactionDays] hari yang aman karena transaksi, sudah lolos aturan
/// jendela `createdAt` (spec §4.2 aturan 1).
StreakSnapshot computeStreak({
  required Set<int> markedDays,

  /// Penanda MENTAH — termasuk baris `viaClockCorrection` (D-11/D-17).
  /// Kalkulator TIDAK PERNAH membacanya; ia hanya diteruskan ke snapshot
  /// supaya UI bisa menjawab "sudah pernah ditekan?" tanpa mencemari
  /// jawaban "menghitung?". Satu-satunya pembacanya adalah aturan CTA
  /// di Task 12.
  required Set<int> markedDaysAll,

  required Set<int> transactionDays,
  required int epochDay,
  required int lastSeenDay,
  required int today,
}) {
  // Task 5 mengganti dua baris ini dengan klasifikasi tiga cabang penjaga jam.
  final effectiveToday = today;
  final nextLastSeenDay = today;
  const todayIsAnomaly = false;

  // Batas ATAS sama pentingnya dengan batas bawah (spec §5.1, aturan Rev 6).
  // Tanpa `d <= effectiveToday`, satu hari aman bertanggal masa depan — yang
  // bisa muncul tanpa kecurangan apa pun setelah jam device sempat maju lalu
  // dikembalikan — membuat `hasStarted` true sementara `currentStreak` tetap
  // 0. Halaman lalu menampilkan "0 hari berturut" alih-alih empty state:
  // persis angka-nol-yang-berbohong yang K10 dan §8.2 larang.
  final safeDays = <int>{
    for (final d in markedDays)
      if (d >= epochDay && d <= effectiveToday) d,
    for (final d in transactionDays)
      if (d >= epochDay && d <= effectiveToday) d,
  };

  final hasStarted = safeDays.isNotEmpty;
  final activatedDay = hasStarted
      ? safeDays.reduce((a, b) => a < b ? a : b)
      : (effectiveToday > epochDay ? effectiveToday : epochDay);

  var run = 0;
  var longest = 0;
  var grace = 0;
  var graceCounter = 0;
  final graceUsed = <int>{};
  int? lastBreakDay;
  var brokenRunLength = 0;

  void hitungHariAman() {
    run += 1;
    if (run > longest) longest = run;
    graceCounter += 1;
    if (graceCounter == _kGracePeriod) {
      if (grace < _kGraceMax) grace += 1; // kelebihan panen HANGUS (T12)
      graceCounter = 0; // (A) penghitung reset tiap panen
    }
  }

  // Hari yang SUDAH lewat dievaluasi penuh: aman, terserap jeda, atau putus.
  var d = activatedDay;
  while (d < effectiveToday) {
    if (safeDays.contains(d)) {
      hitungHariAman();
    } else if (grace > 0) {
      grace -= 1;
      graceUsed.add(d);
      run += 1; // ruas lanjut
      if (run > longest) longest = run;
      // (B) graceCounter TIDAK bertambah — hari terserap bukan hari aman.
      // Tanpa aturan ini, pola "6 aman + 1 bolong" berulang memanen jeda
      // tanpa henti dan jeda berhenti bermakna.
    } else {
      // Kekosongan bisa lebih dari satu hari. Yang memutus ruas hanya hari
      // bolong PERTAMA — hari bolong berikutnya menemukan `run` sudah 0 dan
      // akan menimpa catatan ini jadi "terhenti di 0 hari" (dilarang §8.2).
      if (run > 0) {
        lastBreakDay = d;
        brokenRunLength = run;
      }
      run = 0;
      graceCounter = 0; // (C) putus me-reset penghitung, tanpa syarat
    }
    d = addDays(d, 1);
  }

  // Hari ini belum selesai — ia hanya boleh MENAMBAH (keputusan plan D-1).
  // Hari ini yang belum aman TIDAK memutus ruas dan TIDAK memakai jeda;
  // ia baru dievaluasi besok, saat sudah jadi masa lalu.
  if (effectiveToday >= activatedDay && safeDays.contains(effectiveToday)) {
    hitungHariAman();
  }

  final DayStatus todayStatus;
  // Selama `todayIsAnomaly` masih const false, cabang ini memang tak
  // terjangkau. Ia sengaja ditulis sekarang supaya Task 5 tinggal mengisi
  // klasifikasi penjaga jam tanpa mengubah bentuk percabangan ini.
  // ignore: dead_code
  if (todayIsAnomaly) {
    todayStatus = DayStatus.anomaly;
  } else if (effectiveToday < activatedDay) {
    todayStatus = DayStatus.beforeStart;
  } else if (safeDays.contains(effectiveToday)) {
    todayStatus = DayStatus.safe;
  } else {
    todayStatus = DayStatus.pending;
  }

  return StreakSnapshot(
    hasStarted: hasStarted,
    activatedDay: activatedDay,
    currentStreak: run,
    longestRuas: longest,
    graceAvailable: grace,
    graceUsedDays: graceUsed,
    todayStatus: todayStatus,
    today: effectiveToday,
    nextLastSeenDay: nextLastSeenDay,
    lastBreakDay: lastBreakDay,
    brokenRunLength: brokenRunLength,
    markedDays: markedDays,
    markedDaysAll: markedDaysAll,
    transactionDays: transactionDays,
  );
}
