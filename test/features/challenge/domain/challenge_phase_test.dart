import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/challenge/domain/challenge_calculator.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_environment.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_phase.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_week.dart';

final _senin = DateTime(2026, 9, 7, 9);
final _rabu = DateTime(2026, 9, 9, 9);

// S-C — entity domain, bukan baris Drift. Perhatikan berapa banyak field yang
// TIDAK perlu disebut: timezone, createdAt, updatedAt, isSynced. Tak satu pun
// dari mereka pernah menentukan apa yang dilihat user.
ChallengeWeek _minggu({
  ChallengeStatus status = ChallengeStatus.active,
  String? category = 'food',
  int? target = 115000,
}) => ChallengeWeek(
  weekKey: 20260907,
  category: category,
  targetAmount: target,
  baselineAmount: 140000,
  status: status,
  finalSpent: null,
  resolvedAt: null,
  resultSeenAt: null,
);

ChallengePhase _phase({
  ChallengeWeek? week,
  int spent = 0,
  bool enabled = true,
  ChallengeEnvironment? env = const ChallengeEnvironment(
    budgetConfigured: true,
    survivalActive: false,
  ),
  int? candidates = 3,
  bool historyEmpty = false,
  DateTime? now,
}) => resolveChallengePhase(
  weekThisWeek: week,
  spentThisWeek: spent,
  enabled: enabled,
  env: env,
  candidateCount: candidates,
  historyEmpty: historyEmpty,
  localNow: now ?? _senin,
);

void main() {
  test('U23 · sakelar mati → disabled, apa pun isi baris & kandidat', () {
    expect(
      _phase(enabled: false, week: _minggu(), candidates: 3),
      isA<PhaseDisabled>(),
    );
    expect(
      _phase(enabled: false, week: null, candidates: 0),
      isA<PhaseDisabled>(),
    );
  });

  test('U24 · baris active, terpakai <= target → active; > target → over', () {
    expect(_phase(week: _minggu(), spent: 115000), isA<PhaseActive>());
    expect(_phase(week: _minggu(), spent: 115001), isA<PhaseOver>());
  });

  test('U25 · baris held minggu ini → held', () {
    final p = _phase(
      week: _minggu(status: ChallengeStatus.held, category: null, target: null),
    );
    expect(p, isA<PhaseHeld>());
  });

  test('U26 · baris skipped minggu ini → settledThisWeek', () {
    expect(
      _phase(week: _minggu(status: ChallengeStatus.skipped)),
      isA<PhaseSettledThisWeek>(),
    );
  });

  test(
    'U112 · baris achieved/missed/unknown minggu ini → settledThisWeek, BUKAN preparing',
    () {
      // preparing merender skeleton; kalau ketiganya jatuh ke sana, tile dan
      // halaman memutar loading yang tak pernah selesai.
      for (final s in [
        ChallengeStatus.achieved,
        ChallengeStatus.missed,
        ChallengeStatus.unknown,
      ]) {
        expect(
          _phase(week: _minggu(status: s)),
          isA<PhaseSettledThisWeek>(),
          reason: 'status $s',
        );
      }
    },
  );

  test(
    'U27 · IRISAN: Rabu DAN kandidat 0 → outOfWindow, bukan notEnoughData',
    () {
      // Jawabannya "Mulai Senin depan", bukan "belum cukup data" yang
      // menyalahkan user.
      expect(
        _phase(week: null, candidates: 0, now: _rabu),
        isA<PhaseOutOfWindow>(),
      );
    },
  );

  test('U28 · di jendela, kandidat 0 → notEnoughData', () {
    expect(_phase(week: null, candidates: 0), isA<PhaseNotEnoughData>());
  });

  test('U29 · di jendela, env null → undetermined', () {
    expect(_phase(week: null, env: null), isA<PhaseUndetermined>());
  });

  test('U30 · di jendela, budgetConfigured false → budgetNotSet', () {
    expect(
      _phase(
        week: null,
        env: const ChallengeEnvironment(
          budgetConfigured: false,
          survivalActive: false,
        ),
      ),
      isA<PhaseBudgetNotSet>(),
    );
  });

  test(
    'U31 · IRISAN: budget 0 TAPI baris active ada → tetap active (T11 poin 4)',
    () {
      final p = _phase(
        week: _minggu(),
        spent: 10000,
        env: const ChallengeEnvironment(
          budgetConfigured: false,
          survivalActive: false,
        ),
      );
      expect(p, isA<PhaseActive>());
    },
  );

  test('semua syarat lolos, belum ada baris → preparing', () {
    expect(_phase(week: null), isA<PhasePreparing>());
  });

  test('outOfWindow membawa isFirstWeek dari riwayat kosong', () {
    final p =
        _phase(week: null, now: _rabu, historyEmpty: true) as PhaseOutOfWindow;
    expect(p.isFirstWeek, isTrue);
  });

  // ── Rev 2 · S-B — `null` bukan `0` ──────────────────────────────────────
  group('S-B · kandidat belum terhitung ≠ kandidat nol', () {
    test('kandidat null di jendela → undetermined, BUKAN notEnoughData', () {
      // "Belum sempat dihitung" adalah keadaan berumur milidetik yang jujur
      // dirender sebagai skeleton. Menyebutnya "belum cukup data" menuduh user
      // atas kelambatan app.
      expect(_phase(week: null, candidates: null), isA<PhaseUndetermined>());
    });

    test('kandidat 0 DAN env null → notEnoughData, BUKAN undetermined', () {
      // Ini keadaan TERMINAL, bukan sementara: ensure keluar di langkah 5 dan
      // memang tak pernah membaca lingkungan. Merendernya sebagai skeleton
      // memutar loading yang tak akan pernah selesai.
      expect(
        _phase(week: null, candidates: 0, env: null),
        isA<PhaseNotEnoughData>(),
      );
    });

    test('S-C · phase membandingkan ISI minggu, bukan hanya weekKey', () {
      // Rev 1 memakai props [row.weekKey, spent]. Ganti pos Senin pagi (spent
      // masih 0) menghasilkan dua PhaseActive yang dianggap SAMA — dan
      // BlocBuilder tidak merender ulang kartu yang kategorinya sudah berubah.
      final a = _phase(week: _minggu(category: 'food', target: 115000));
      final b = _phase(week: _minggu(category: 'transport', target: 80000));
      expect(a, isNot(equals(b)));
    });
  });

  // ── Ronde 2 · kisi irisan tingkat 3 ─────────────────────────────────────
  // Tiap test di bawah menyetel DUA syarat sekaligus, jadi ia hanya bisa lolos
  // kalau URUTAN pemeriksaannya benar — bukan sekadar kalau cabangnya bisa
  // dicapai. Tanpa ketiganya, tiga pasangan presedensi bisa ditukar posisinya
  // tanpa satu pun test berubah warna.
  group('Irisan presedensi tingkat 3 — mengunci urutan, bukan cabang', () {
    test('IRISAN: luar jendela DAN kandidat belum terhitung → outOfWindow', () {
      // Irisan yang PALING SERING terjadi di produksi: di luar jendela, alur
      // tulis tidak pernah menghitung kandidat, jadi `candidateCount` memang
      // null tiap Rabu–Minggu. Kalau cek jendela turun ke bawah cek kandidat,
      // setiap user melihat skeleton yang tak kunjung selesai selama lima hari
      // seminggu — alih-alih "Mulai Senin depan".
      //
      // Bandingkan U27 (luar jendela + kandidat 0): kombinasi itu justru TIDAK
      // bisa diproduksi alur tulis, karena kandidat tak pernah dihitung di luar
      // jendela. U27 menjaga batas yang sintetis; test ini menjaga yang nyata.
      expect(
        _phase(week: null, candidates: null, now: _rabu),
        isA<PhaseOutOfWindow>(),
      );
    });

    test('IRISAN: luar jendela DAN budget belum diatur → outOfWindow', () {
      // Jendela menang atas anggaran. Kalau `budgetConfigured` naik ke atas cek
      // jendela, user tanpa anggaran diberi tahu "atur anggaran dulu" pada hari
      // yang app-nya sendiri tak akan berbuat apa-apa — ajakan bertindak yang
      // tak mengubah apa pun sampai Senin.
      expect(
        _phase(
          week: null,
          now: _rabu,
          env: const ChallengeEnvironment(
            budgetConfigured: false,
            survivalActive: false,
          ),
        ),
        isA<PhaseOutOfWindow>(),
      );
    });

    test('IRISAN: kandidat 0 DAN budget belum diatur → notEnoughData', () {
      // Kandidat menang atas anggaran. Alur tulis keluar di langkah kandidat
      // SEBELUM menyentuh lingkungan, jadi jawaban yang jujur adalah "belum ada
      // kategori yang layak" — bukan menyuruh user mengatur anggaran yang, bahkan
      // setelah diatur, tetap tak memunculkan tantangan minggu ini.
      expect(
        _phase(
          week: null,
          candidates: 0,
          env: const ChallengeEnvironment(
            budgetConfigured: false,
            survivalActive: false,
          ),
        ),
        isA<PhaseNotEnoughData>(),
      );
    });
  });
}
