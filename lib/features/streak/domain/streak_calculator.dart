import 'package:penyintas_app/core/utils/date_helper.dart';
import 'package:penyintas_app/features/streak/domain/entities/streak_snapshot.dart';

/// Jumlah hari aman berturut yang memanen satu jeda.
const int _kGracePeriod = 7;

/// Plafon jeda yang bisa ditahan sekaligus.
const int _kGraceMax = 2;

/// Selisih KALENDER `a - b` dalam hari, dari dua dayKey berformat `yyyymmdd`.
///
/// Pengurangan integer mentah TIDAK mengukur hari — ia mengukur jarak antara
/// dua bilangan yang kebetulan berbentuk tanggal. `20261001 - 20260930` = 71
/// padahal jaraknya satu hari, dan `20270101 - 20261231` = 8870 padahal juga
/// satu hari. Ambang penjaga jam (spec §4.6) dinyatakan dalam HARI, jadi ia
/// wajib diukur dalam hari — kalau tidak, tiap pergantian bulan melempar
/// keputusan ke cabang yang salah.
///
/// Sengaja lewat `DateTime.utc`, bukan waktu lokal: UTC tak mengenal DST,
/// sehingga satu hari selalu genap 24 jam dan `.inDays` tak pernah memotong
/// hari 23 jam menjadi 0. Indonesia memang tanpa DST, tapi kalkulator inti
/// tidak boleh menggantungkan kebenarannya pada zona waktu penggunanya.
int _selisihHari(int a, int b) {
  DateTime utcOf(int dayKey) =>
      DateTime.utc(dayKey ~/ 10000, (dayKey ~/ 100) % 100, dayKey % 100);
  return utcOf(a).difference(utcOf(b)).inDays;
}

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
  // Penjaga jam tiga cabang (spec §4.6). Dihitung DI DALAM kalkulator supaya
  // tetap murni dan bisa diuji tanpa database.
  //
  //   selisih ≤ 0  → hari maju/normal: lastSeenDay := today
  //   selisih 1–2  → mode netral: penandaan ditolak, streak beku (maks 2 hari,
  //                  sembuh sendiri), effectiveToday = lastSeenDay
  //   selisih > 2  → koreksi jam (RTC reset / user menyetel tanggal), BUKAN
  //                  kecurangan: lastSeenDay := today, perhitungan lanjut normal
  //
  // Ambang 2 hari menutup persis manipulasi yang membayar (memundurkan jam
  // 1–2 hari untuk menambal gap yang baru terjadi). Invarian tanpa pintu
  // keluar adalah jebakan, bukan pengamanan: Rev 2 dulu membekukan user
  // jujur sampai setahun karena `lastSeenDay` hanya boleh naik.
  final selisih = _selisihHari(lastSeenDay, today);
  final bool todayIsAnomaly;
  final int effectiveToday;
  final int nextLastSeenDay;
  if (selisih <= 0) {
    todayIsAnomaly = false;
    effectiveToday = today;
    nextLastSeenDay = today;
  } else if (selisih <= 2) {
    todayIsAnomaly = true;
    effectiveToday = lastSeenDay;
    nextLastSeenDay = lastSeenDay; // TIDAK diturunkan
  } else {
    todayIsAnomaly = false;
    effectiveToday = today;
    nextLastSeenDay = today; // penjaga melepaskan dirinya sendiri
  }
  final clockAnomalyDetected = selisih > 0;

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
    clockAnomalyDetected: clockAnomalyDetected,
  );
}
