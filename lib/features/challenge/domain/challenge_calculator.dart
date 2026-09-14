import 'package:penyintas_app/core/utils/date_helper.dart'; // addDays — C3
import 'package:penyintas_app/features/challenge/domain/challenge_constants.dart';
import 'package:penyintas_app/features/challenge/domain/entities/weekly_spend.dart';

/// Jantung fitur: seluruh aturan T2–T9 hidup di berkas ini, dan HANYA di sini.
/// Tanpa I/O, tanpa `DateTime.now()`, tanpa database — supaya tiap aturan bisa
/// diuji dan disabotase satu per satu.

/// Basis mingguan per kategori dari [kBaselineWeeks] minggu penuh terakhir
/// SEBELUM [currentWeekKey] (T2).
///
/// Pembaginya jumlah minggu yang PUNYA belanja kategori itu, bukan tetap 4:
/// pembagi tetap membuat user yang baru punya 2 minggu data mendapat basis
/// setengah kebiasaannya, lalu dipotong 15% lagi — target mustahil sejak hari
/// pertama.
({Map<String, int> baselines, Map<String, int> weeksWithData}) computeBaselines({
  required List<WeeklySpend> spends,
  required int currentWeekKey,
}) {
  // C3 — batas KALENDER, bukan "empat weekKey terbesar yang kebetulan ada di
  // data". Rev 1 mengambil empat weekKey teratas yang lebih kecil dari minggu
  // berjalan; untuk user berdata bolong itu menarik minggu dari tiga bulan lalu
  // ke dalam basis DAN menggelembungkan `weeksWithData` sampai lolos
  // kMinBaselineWeeksWithData — user yang sebetulnya baru punya dua minggu data
  // diperlakukan seolah punya empat.
  final batasBawah = addDays(currentWeekKey, -7 * kBaselineWeeks);

  final total = <String, int>{};
  final jumlahMinggu = <String, Set<int>>{};

  for (final s in spends) {
    if (s.weekKey < batasBawah || s.weekKey >= currentWeekKey) continue;
    if (s.amount <= 0) continue;
    total[s.category] = (total[s.category] ?? 0) + s.amount;
    (jumlahMinggu[s.category] ??= <int>{}).add(s.weekKey);
  }

  final baselines = <String, int>{};
  final weeksWithData = <String, int>{};
  for (final e in total.entries) {
    final n = jumlahMinggu[e.key]!.length;
    baselines[e.key] = e.value ~/ n;
    weeksWithData[e.key] = n;
  }
  return (baselines: baselines, weeksWithData: weeksWithData);
}

/// Target = basis × [kTargetRatio], dibulatkan KE BAWAH ke kelipatan
/// [kRoundingStep] (T4).
///
/// Ke bawah, bukan ke terdekat: pembulatan ke bawah membuat target selalu
/// sedikit lebih menantang daripada rumus murni — arahnya konsisten.
int computeTarget(int baseline) {
  if (baseline <= 0) return 0;
  final mentah = baseline * kTargetRatio;
  return (mentah ~/ kRoundingStep) * kRoundingStep;
}
