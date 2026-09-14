import 'package:equatable/equatable.dart';
import 'package:penyintas_app/core/utils/date_helper.dart'; // addDays — C3
import 'package:penyintas_app/features/challenge/domain/challenge_constants.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_candidate.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
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
({Map<String, int> baselines, Map<String, int> weeksWithData})
computeBaselines({
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

/// Bentuk riwayat seminimalnya yang dibutuhkan kalkulator. Sengaja bukan baris
/// Drift: kalkulator tidak boleh kenal database.
class ResolvedWeek extends Equatable {
  const ResolvedWeek({
    required this.weekKey,
    required this.category,
    required this.status,
  });

  final int weekKey;
  final String? category;
  final ChallengeStatus status;

  @override
  List<Object?> get props => [weekKey, category, status];
}

/// Berapa minggu BERTURUT terakhir kategori ini berstatus `achieved` (T5).
///
/// [history] harus terurut weekKey MENURUN (terbaru dulu).
///
/// `held` dan `skipped` TRANSPARAN: tidak memutus dan tidak menambah. Kalau
/// `held` memutus, user yang ditahan sekali mendapat reset rotasi gratis; kalau
/// ia menambah, app menghitung kemenangan yang tidak pernah terjadi.
int consecutiveWins(List<ResolvedWeek> history, String category) {
  var n = 0;
  for (final baris in history) {
    if (baris.status == ChallengeStatus.held ||
        baris.status == ChallengeStatus.skipped) {
      continue;
    }
    if (baris.status == ChallengeStatus.achieved &&
        baris.category == category) {
      n++;
    } else {
      break;
    }
  }
  return n;
}

/// Kandidat terurut, maksimal [kMaxCandidates] (T3, T5, T17).
List<ChallengeCandidate> selectCandidates({
  required Map<String, int> baselines,
  required Map<String, int> weeksWithData,
  required Set<String> limitableSlugs,
  required List<ResolvedWeek> history,
}) {
  final layak = <ChallengeCandidate>[];
  for (final e in baselines.entries) {
    if (!limitableSlugs.contains(e.key)) continue;
    if ((weeksWithData[e.key] ?? 0) < kMinBaselineWeeksWithData) continue;
    if (e.value < kMinWeeklyBaseline) continue;
    layak.add(
      ChallengeCandidate(
        category: e.key,
        baseline: e.value,
        target: computeTarget(e.value),
      ),
    );
  }

  // Basis menurun; seri diputus slug abjad supaya dua device yang sama-sama
  // offline menghasilkan baris IDENTIK untuk minggu yang sama (T17 aturan 1).
  layak.sort((a, b) {
    final cmp = b.baseline.compareTo(a.baseline);
    return cmp != 0 ? cmp : a.category.compareTo(b.category);
  });

  // Rem rotasi (T5): PENGURUTAN, bukan larangan. Kategori yang sudah menang
  // kRotationWins kali berturut turun ke urutan terakhir — tapi kalau ia
  // satu-satunya kandidat, ia tetap dipakai. Melarangnya berarti menghukum
  // user karena berhasil.
  final jenuh = <ChallengeCandidate>[];
  final segar = <ChallengeCandidate>[];
  for (final c in layak) {
    if (consecutiveWins(history, c.category) >= kRotationWins) {
      jenuh.add(c);
    } else {
      segar.add(c);
    }
  }

  return [...segar, ...jenuh].take(kMaxCandidates).toList();
}

/// dayKey Senin minggu tempat [localNow] berada (D2).
///
/// [localNow] WAJIB wall-clock lokal dari `AppClock` — bukan UTC. Seluruh app
/// merender tanggal transaksi dengan wall-clock device; minggu yang memakai
/// sumber lain akan berselisih satu hari dengan daftar transaksi.
int weekKeyOf(DateTime localNow) {
  final senin = DateTime(localNow.year, localNow.month, localNow.day)
      .subtract(Duration(days: localNow.weekday - DateTime.monday));
  return localDayKey(senin);
}

/// Apakah [localNow] berada di jendela pembuatan Senin–Selasa (T6).
bool isCreationWindow(DateTime localNow) =>
    localNow.weekday == DateTime.monday || localNow.weekday == DateTime.tuesday;

/// Sisa hari kalender minggu ini, TERMASUK hari ini (§7.4).
/// Senin = 7, Minggu = 1. Tidak pernah nol.
int daysLeftInWeek(DateTime localNow) => 8 - localNow.weekday;

/// Hasil satu minggu (T9). Batas inklusif: tepat di target berarti berhasil.
ChallengeStatus evaluateResult({
  required int target,
  required int finalSpent,
}) => finalSpent <= target ? ChallengeStatus.achieved : ChallengeStatus.missed;
