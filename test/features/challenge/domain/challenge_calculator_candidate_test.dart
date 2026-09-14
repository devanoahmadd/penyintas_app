import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/challenge/domain/challenge_constants.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/domain/challenge_calculator.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_candidate.dart';

const _limitable = {
  'food',
  'transport',
  'shopping',
  'health',
  'internet',
  'other',
};

ResolvedWeek _menang(int weekKey, String kategori) => ResolvedWeek(
  weekKey: weekKey,
  category: kategori,
  status: ChallengeStatus.achieved,
);

List<ChallengeCandidate> _pilih({
  required Map<String, int> baselines,
  Map<String, int>? weeksWithData,
  Set<String>? limitable,
  List<ResolvedWeek> history = const [],
}) => selectCandidates(
  baselines: baselines,
  weeksWithData:
      weeksWithData ??
      {for (final k in baselines.keys) k: kMinBaselineWeeksWithData},
  limitableSlugs: limitable ?? _limitable,
  history: history,
);

void main() {
  group('selectCandidates · kelayakan', () {
    test('U6 · 1 dari 4 minggu berdata → bukan kandidat', () {
      final hasil = _pilih(
        baselines: {'health': 200000},
        weeksWithData: {'health': 1},
      );
      expect(hasil, isEmpty);
    });

    test('U7 · basis Rp 49.999 bukan kandidat, Rp 50.000 kandidat', () {
      expect(_pilih(baselines: {'food': 49999}), isEmpty);
      expect(_pilih(baselines: {'food': 50000}).map((c) => c.category), [
        'food',
      ]);
    });

    test('U8 · kategori di luar daftar limitable → bukan kandidat', () {
      final hasil = _pilih(baselines: {'fixed': 500000}, limitable: _limitable);
      expect(hasil, isEmpty);
    });

    test('U9 · tidak ada yang lolos → daftar kosong, bukan exception', () {
      expect(_pilih(baselines: const {}), isEmpty);
    });

    test('U10 · maksimal 3 kandidat meski 6 layak', () {
      final hasil = _pilih(
        baselines: {
          'food': 600000,
          'transport': 500000,
          'shopping': 400000,
          'health': 300000,
          'internet': 200000,
          'other': 100000,
        },
      );
      expect(hasil.length, 3);
      expect(hasil.map((c) => c.category), ['food', 'transport', 'shopping']);
    });

    test('kandidat membawa target hasil computeTarget', () {
      final hasil = _pilih(baselines: {'food': 100000});
      expect(hasil.single.baseline, 100000);
      expect(hasil.single.target, 85000);
    });
  });

  group('consecutiveWins', () {
    test('U15 · held di antara kemenangan TIDAK memutus hitungan', () {
      final riwayat = [
        _menang(20260907, 'food'),
        const ResolvedWeek(
          weekKey: 20260831,
          category: null,
          status: ChallengeStatus.held,
        ),
        _menang(20260824, 'food'),
        _menang(20260817, 'food'),
      ];
      expect(consecutiveWins(riwayat, 'food'), 3);
    });

    test('U16 · skipped TIDAK menambah hitungan', () {
      final riwayat = [
        const ResolvedWeek(
          weekKey: 20260907,
          category: 'food',
          status: ChallengeStatus.skipped,
        ),
        _menang(20260831, 'food'),
      ];
      expect(consecutiveWins(riwayat, 'food'), 1);
    });

    test('missed memutus hitungan', () {
      final riwayat = [
        const ResolvedWeek(
          weekKey: 20260907,
          category: 'food',
          status: ChallengeStatus.missed,
        ),
        _menang(20260831, 'food'),
      ];
      expect(consecutiveWins(riwayat, 'food'), 0);
    });

    test('kemenangan kategori lain memutus hitungan', () {
      final riwayat = [
        _menang(20260907, 'transport'),
        _menang(20260831, 'food'),
      ];
      expect(consecutiveWins(riwayat, 'food'), 0);
    });
  });

  group('selectCandidates · rotasi (T5)', () {
    final tigaMenang = [
      _menang(20260907, 'food'),
      _menang(20260831, 'food'),
      _menang(20260824, 'food'),
    ];

    test(
      'U13 · 3× berturut menang → kategori itu turun ke urutan TERAKHIR',
      () {
        final hasil = _pilih(
          baselines: {'food': 600000, 'transport': 200000},
          history: tigaMenang,
        );
        expect(hasil.map((c) => c.category), ['transport', 'food']);
      },
    );

    test('U14 · 2× berturut menang → urutan tidak berubah', () {
      final hasil = _pilih(
        baselines: {'food': 600000, 'transport': 200000},
        history: [_menang(20260907, 'food'), _menang(20260831, 'food')],
      );
      expect(hasil.map((c) => c.category), ['food', 'transport']);
    });

    test('U17 · kandidat TUNGGAL yang sudah 3× menang TETAP dipakai', () {
      // Pengurutan, bukan larangan: alternatifnya menghukum user karena berhasil.
      final hasil = _pilih(baselines: {'food': 600000}, history: tigaMenang);
      expect(hasil.map((c) => c.category), ['food']);
    });
  });

  group('selectCandidates · determinisme (T17)', () {
    test('U22 · basis sama persis → urutan diputus slug abjad, dan STABIL', () {
      final a = _pilih(baselines: {'transport': 100000, 'food': 100000});
      final b = _pilih(baselines: {'food': 100000, 'transport': 100000});
      expect(a.map((c) => c.category), ['food', 'transport']);
      expect(b.map((c) => c.category), ['food', 'transport']);
    });
  });
}
