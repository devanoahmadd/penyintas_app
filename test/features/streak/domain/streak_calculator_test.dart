import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/utils/date_helper.dart';
import 'package:penyintas_app/features/streak/domain/entities/streak_snapshot.dart';
import 'package:penyintas_app/features/streak/domain/streak_calculator.dart';

/// Semua kasus memakai epoch 1 September 2026 dan tinggal di dalam bulan itu
/// kecuali disebutkan lain, supaya deret hari mudah dibaca.
const epoch = 20260901;

/// Deret dayKey berurutan: `run(20260901, 5)` → 1,2,3,4,5 September.
Set<int> run(int from, int count) {
  final out = <int>{};
  var d = from;
  for (var i = 0; i < count; i++) {
    out.add(d);
    d = addDays(d, 1);
  }
  return out;
}

StreakSnapshot compute({
  Set<int> marked = const {},
  Set<int>? markedAll,
  Set<int> tx = const {},
  int epochDay = epoch,
  int? lastSeen,
  required int today,
}) => computeStreak(
  markedDays: marked,
  // Default: himpunan mentah = himpunan bersih. Test yang butuh baris
  // bertanda (T40) menyuntik `markedDaysAll` sendiri.
  markedDaysAll: markedAll ?? marked,
  transactionDays: tx,
  epochDay: epochDay,
  lastSeenDay: lastSeen ?? today,
  today: today,
);

void main() {
  group('T1 — hari berturut tanpa bolong', () {
    test('streak sama dengan jumlah hari aman', () {
      final s = compute(tx: run(20260901, 5), today: 20260905);
      expect(s.hasStarted, isTrue);
      expect(s.activatedDay, 20260901);
      expect(s.currentStreak, 5);
      expect(s.longestRuas, 5);
      expect(s.todayStatus, DayStatus.safe);
      expect(s.lastBreakDay, isNull);
      expect(
        s.today,
        20260905,
        reason: 'effectiveToday yang dipakai perhitungan',
      );
      expect(
        s.nextLastSeenDay,
        20260905,
        reason: 'nilai yang HARUS ditulis StreakBloc ke StreakMeta.lastSeenDay',
      );
    });
  });

  group('T2 — bolong 1 hari, jeda tersedia', () {
    test('ruas lanjut, jeda berkurang, hari tampil sebagai graceUsed', () {
      // 7 hari aman (panen 1 jeda) → 1 hari bolong → 2 hari aman.
      final safe = {...run(20260901, 7), 20260909, 20260910};
      final s = compute(tx: safe, today: 20260910);
      expect(s.currentStreak, 10, reason: '7 aman + 1 terserap + 2 aman');
      expect(s.graceAvailable, 0, reason: 'jeda satu-satunya sudah terpakai');
      expect(s.graceUsedDays, contains(20260908));
      expect(s.lastBreakDay, isNull, reason: 'terserap jeda ≠ putus');
    });
  });

  group('T3 — bolong 1 hari, jeda habis', () {
    test('streak nol, rekor terpanjang tetap tersimpan', () {
      // 3 hari aman (belum panen jeda) → bolong → 2 hari aman.
      final safe = {...run(20260901, 3), 20260905, 20260906};
      final s = compute(tx: safe, today: 20260906);
      expect(s.currentStreak, 2);
      expect(s.longestRuas, 3);
      expect(s.lastBreakDay, 20260904);
      expect(s.brokenRunLength, 3);
      expect(s.graceUsedDays, isEmpty);
    });
  });

  group('T4 — bolong 2 hari beruntun dengan jeda = 2', () {
    test('keduanya terserap, ruas lanjut', () {
      // 14 hari aman → panen 2 jeda → 2 hari bolong → 1 hari aman.
      final safe = {...run(20260901, 14), 20260917};
      final s = compute(tx: safe, today: 20260917);
      expect(s.graceUsedDays, {20260915, 20260916});
      expect(s.currentStreak, 17);
      expect(s.graceAvailable, 0);
      expect(s.lastBreakDay, isNull);
    });
  });

  group('T9 — penyusulan H-1 mengembalikan jeda', () {
    test('hari yang tadinya terserap jeda kini aman, jeda kembali', () {
      final sebelum = compute(
        tx: {...run(20260901, 7), 20260909},
        today: 20260909,
      );
      expect(sebelum.graceUsedDays, contains(20260908));
      expect(sebelum.graceAvailable, 0);

      // User mencatat mundur untuk 8 September.
      final sesudah = compute(
        tx: {...run(20260901, 7), 20260908, 20260909},
        today: 20260909,
      );
      expect(
        sesudah.graceUsedDays,
        isEmpty,
        reason: 'tak ada lagi yang diserap',
      );
      expect(
        sesudah.graceAvailable,
        1,
        reason: 'jeda kembali sendiri di replay',
      );
      expect(sesudah.currentStreak, 9);
    });
  });

  group('T10 — transaksi tunggal di hari D dihapus', () {
    test('D jadi bolong dan diserap jeda bila tersedia', () {
      final utuh = compute(tx: run(20260901, 10), today: 20260910);
      expect(utuh.currentStreak, 10);

      final tanpaHari8 = {...run(20260901, 10)}..remove(20260908);
      final s = compute(tx: tanpaHari8, today: 20260910);
      expect(s.graceUsedDays, contains(20260908));
      expect(s.currentStreak, 10, reason: 'ruas lanjut lewat jeda');
      expect(s.graceAvailable, 0);
    });
  });

  group('T12 — akumulasi jeda melewati batas 2', () {
    test('tetap 2, kelebihannya hangus', () {
      final s = compute(tx: run(20260901, 28), today: 20260928);
      expect(s.graceAvailable, 2, reason: '4 kali panen, plafon 2');
      expect(s.currentStreak, 28);
    });
  });

  group('T13 — hari sebelum epoch', () {
    test('diabaikan seluruhnya', () {
      final s = compute(
        tx: {20260828, 20260829, 20260830, 20260831, 20260901},
        today: 20260901,
      );
      expect(s.activatedDay, 20260901);
      expect(s.currentStreak, 1, reason: 'empat hari Agustus tidak ikut');
    });
  });

  group('T14 — penanda nihil dan transaksi di hari yang sama', () {
    test('aman, dihitung sekali', () {
      final s = compute(
        marked: {20260902},
        tx: {20260901, 20260902},
        today: 20260902,
      );
      expect(
        s.currentStreak,
        2,
        reason: 'bukan 3 — hari yang sama sekali hitung',
      );
    });
  });

  group('T17 — belum ada hari aman sama sekali', () {
    test('hasStarted false, activatedDay = hari ini, bukan deretan bolong', () {
      final s = compute(today: 20260915);
      expect(s.hasStarted, isFalse);
      expect(s.activatedDay, 20260915);
      expect(s.currentStreak, 0);
      expect(
        s.lastBreakDay,
        isNull,
        reason: 'user baru tak boleh disambut riwayat kegagalan',
      );
      expect(s.graceUsedDays, isEmpty);
    });
  });

  group('T20 — hari aman paling awal dihapus transaksinya', () {
    test('activatedDay bergeser maju, bukan meninggalkan hari bolong', () {
      final s = compute(tx: {20260910, 20260911}, today: 20260911);
      expect(s.activatedDay, 20260910);
      expect(s.currentStreak, 2);
      expect(
        s.lastBreakDay,
        isNull,
        reason: '1–9 September ada SEBELUM activatedDay, bukan bolong',
      );
    });
  });

  group('T23 — aturan jeda (A)(B)(C)', () {
    test('(A) panen jeda me-reset penghitung', () {
      // 13 hari aman: panen di hari ke-7, penghitung mulai lagi dari 0 →
      // panen kedua baru datang di hari ke-14, jadi di hari ke-13 jeda = 1.
      final s = compute(tx: run(20260901, 13), today: 20260913);
      expect(s.graceAvailable, 1);
    });

    test('(B) hari terserap jeda TIDAK menambah penghitung — pola 6+1 berulang '
        'tak memanen jeda tanpa henti', () {
      // 7 aman (panen 1) lalu pola berulang: 1 bolong + 6 aman, tiga kali.
      final safe = <int>{...run(20260901, 7)};
      var cursor = 20260908;
      for (var i = 0; i < 3; i++) {
        cursor = addDays(cursor, 1); // hari bolong dilompati
        safe.addAll(run(cursor, 6));
        cursor = addDays(cursor, 6);
      }
      final today = cursor;
      final s = compute(tx: safe, today: today);
      expect(
        s.graceAvailable,
        0,
        reason:
            'jeda pertama terpakai di bolong pertama dan tak pernah '
            'terpanen lagi — penghitung tak pernah menyentuh 7',
      );
      expect(
        s.lastBreakDay,
        isNotNull,
        reason: 'bolong kedua tak punya jeda → ruas putus',
      );
    });

    test('(C) setelah putus, jeda pertama datang di hari ke-7', () {
      // 3 aman → bolong (tanpa jeda, putus) → 6 aman.
      final safe = {...run(20260901, 3), ...run(20260905, 6)};
      final s = compute(tx: safe, today: 20260910);
      expect(s.currentStreak, 6);
      expect(
        s.graceAvailable,
        0,
        reason: 'penghitung mulai dari nol sesudah putus, belum 7',
      );

      final tujuh = {...run(20260901, 3), ...run(20260905, 7)};
      final s7 = compute(tx: tujuh, today: 20260911);
      expect(s7.graceAvailable, 1);
    });
  });

  group('T30 — hari ini belum selesai (keputusan plan D-1)', () {
    test(
      'hari ini yang belum aman TIDAK memutus ruas dan TIDAK memakai jeda',
      () {
        final s = compute(tx: run(20260901, 9), today: 20260910);
        expect(s.currentStreak, 9, reason: 'bukan 0 — hari ini belum lewat');
        expect(s.todayStatus, DayStatus.pending);
        expect(s.lastBreakDay, isNull);
        expect(s.graceUsedDays, isEmpty);
        expect(s.graceAvailable, 1, reason: 'jeda hasil panen hari ke-7 utuh');
      },
    );

    test('hari KEMARIN yang tak aman tetap dievaluasi seperti biasa', () {
      // 3 aman, kemarin bolong, hari ini aman.
      final s = compute(tx: {...run(20260901, 3), 20260905}, today: 20260905);
      expect(s.lastBreakDay, 20260904);
      expect(s.currentStreak, 1);
    });
  });

  group('T36 — hari di masa depan tidak pernah ikut dihitung', () {
    test(
      'hari aman yang jatuh SESUDAH hari ini tidak membuat hasStarted true',
      () {
        // Bisa terjadi tanpa kecurangan: jam device sempat maju (RTC kacau,
        // user menyetel tanggal), lalu dikembalikan. Transaksinya tertinggal
        // bertanggal masa depan.
        final s = compute(tx: {20260920}, today: 20260905);
        expect(
          s.hasStarted,
          isFalse,
          reason: 'belum ada satu pun hari aman yang SUDAH terjadi',
        );
        expect(
          s.activatedDay,
          20260905,
          reason: 'bukan 20260920 — window tidak boleh dimulai di masa depan',
        );
        expect(s.currentStreak, 0);
        expect(s.lastBreakDay, isNull);
      },
    );

    test(
      'hari masa depan tidak menggeser activatedDay ke belakang hari nyata',
      () {
        final s = compute(tx: {20260903, 20260904, 20260920}, today: 20260904);
        expect(s.activatedDay, 20260903);
        expect(s.currentStreak, 2, reason: '20 September belum terjadi');
      },
    );
  });

  group('pergantian bulan', () {
    test('replay melewati batas bulan tanpa kehilangan hari', () {
      final s = compute(
        tx: run(20260928, 6), // 28,29,30 Sep + 1,2,3 Okt
        epochDay: 20260928,
        today: 20261003,
      );
      expect(s.currentStreak, 6);
      expect(s.lastBreakDay, isNull);
    });
  });

  group('kekosongan lebih dari satu hari', () {
    test(
      'putus dicatat SEKALI di hari ruas patah, bukan ditimpa tiap hari bolong',
      () {
        // 5 hari aman (belum panen jeda, jadi tak ada yang menyerap) → 3 hari
        // bolong berturut → 1 hari aman. Pola "user hilang seminggu": akhir
        // pekan panjang atau mudik, bukan kasus tepi.
        final s = compute(tx: {...run(20260901, 5), 20260909}, today: 20260909);
        expect(
          s.lastBreakDay,
          20260906,
          reason: 'hari ruas PATAH, bukan hari terakhir kekosongan (20260908)',
        );
        expect(
          s.brokenRunLength,
          5,
          reason:
              'panjang ruas yang patah — bukan 0 hasil timpa hari bolong ke-2',
        );
        expect(s.currentStreak, 1);
        expect(s.longestRuas, 5);
        expect(s.graceUsedDays, isEmpty);
      },
    );
  });

  group('hari ini masih sebelum epoch', () {
    test('todayStatus beforeStart, activatedDay bertahan di epoch', () {
      final s = compute(today: 20260828);
      expect(s.todayStatus, DayStatus.beforeStart);
      expect(
        s.activatedDay,
        20260901,
        reason: 'epoch, bukan hari device yang masih di belakangnya',
      );
      expect(s.hasStarted, isFalse);
      expect(s.currentStreak, 0);
    });
  });

  // ── T46 — kemurnian pass-through `markedDaysAll` ───────────────────────────
  //
  // CATATAN PENYIMPANGAN DARI BRIEF: resep sabotase T46 di brief menyebut
  // "T26 dan T27" harus merah, tapi kedua test itu tidak ada di file ini —
  // keduanya milik task lain. Tanpa test di bawah, resep T46 tidak memerahkan
  // apa pun (helper `compute` default-nya `markedAll ?? marked`, jadi menukar
  // keduanya adalah no-op). Grup ini yang benar-benar mengunci invarian D-11 /
  // D-17: kalkulator DILARANG membaca `markedDaysAll`.
  group(
    'T46 — markedDaysAll murni pass-through, tak pernah dibaca kalkulator',
    () {
      test('baris viaClockCorrection tidak menyambung ruas yang putus', () {
        // 3 hari aman, 4 Sep bolong, 5 Sep aman. 4 Sep PUNYA penanda mentah
        // (ditekan saat jam device kacau) — penanda itu tidak boleh menghitung.
        final s = compute(
          tx: {...run(20260901, 3), 20260905},
          markedAll: {20260904},
          today: 20260905,
        );
        expect(
          s.lastBreakDay,
          20260904,
          reason: 'penanda dari jam kacau tidak menambal hari bolong',
        );
        expect(
          s.currentStreak,
          1,
          reason: 'bukan 5 — ruas tetap putus di 4 Sep',
        );
        expect(s.brokenRunLength, 3);
        expect(s.graceUsedDays, isEmpty);
      });

      test('baris viaClockCorrection tidak membuat hasStarted true', () {
        final s = compute(markedAll: {20260903}, today: 20260905);
        expect(
          s.hasStarted,
          isFalse,
          reason: 'penanda mentah bukan hari aman — riwayat belum dimulai',
        );
        expect(
          s.activatedDay,
          20260905,
          reason:
              'bukan 20260903 — window tak boleh dibuka oleh penanda mentah',
        );
        expect(s.currentStreak, 0);
      });

      test('tetap diteruskan utuh ke snapshot untuk aturan CTA Task 12', () {
        final s = compute(
          marked: {20260905},
          markedAll: {20260903, 20260905},
          today: 20260905,
        );
        expect(s.markedDays, {20260905}, reason: 'himpunan bersih');
        expect(s.markedDaysAll, {
          20260903,
          20260905,
        }, reason: 'himpunan mentah utuh');
      });
    },
  );

  group('T11 — jam mundur 1–2 hari (mode netral)', () {
    test('streak tidak berubah, tidak putus, todayStatus anomaly', () {
      // lastSeenDay 10 Sep, jam device menunjukkan 9 Sep (selisih 1).
      final safe = run(20260901, 10); // 1..10 Sep aman
      final s = compute(tx: safe, lastSeen: 20260910, today: 20260909);
      expect(s.todayStatus, DayStatus.anomaly);
      expect(s.today, 20260910, reason: 'effectiveToday = lastSeenDay');
      expect(s.currentStreak, 10, reason: 'tidak menyusut, tidak putus');
      expect(
        s.nextLastSeenDay,
        20260910,
        reason: 'lastSeenDay TIDAK diturunkan di mode netral',
      );
      expect(s.clockAnomalyDetected, isTrue);
    });

    test('selisih tepat 2 hari masih mode netral', () {
      final s = compute(
        tx: run(20260901, 10),
        lastSeen: 20260910,
        today: 20260908,
      );
      expect(s.todayStatus, DayStatus.anomaly);
      expect(s.nextLastSeenDay, 20260910);
    });
  });

  group('T21 — jam maju jauh lalu dikembalikan (selisih > 2 hari)', () {
    test(
      'TIDAK beku: lastSeenDay turun ke today, perhitungan lanjut normal',
      () {
        // lastSeenDay tertinggal di 30 Sep, waktu nyata 10 Sep.
        final s = compute(
          tx: run(20260901, 10),
          lastSeen: 20260930,
          today: 20260910,
        );
        expect(
          s.todayStatus,
          DayStatus.safe,
          reason: 'bukan anomaly — ini koreksi jam',
        );
        expect(
          s.today,
          20260910,
          reason: 'effectiveToday = today, bukan lastSeenDay',
        );
        expect(
          s.nextLastSeenDay,
          20260910,
          reason: 'penjaga melepaskan diri sendiri',
        );
        expect(s.currentStreak, 10);
        expect(
          s.clockAnomalyDetected,
          isTrue,
          reason: 'tetap dicatat sebagai anomali',
        );
      },
    );

    test('hari maju normal tidak pernah dianggap anomali', () {
      final s = compute(
        tx: run(20260901, 5),
        lastSeen: 20260903,
        today: 20260905,
      );
      expect(s.todayStatus, DayStatus.safe);
      expect(s.nextLastSeenDay, 20260905);
      expect(s.clockAnomalyDetected, isFalse);
    });
  });

  group('T19 — presedensi petak kalender', () {
    test('mengikuti tabel spec §5.3 persis', () {
      // 1–7 Sep aman lewat transaksi (panen 1 jeda), 8 Sep bolong (terserap
      // jeda), 9 Sep ditandai nihil, 10 Sep aman transaksi DAN ditandai nihil,
      // hari ini 12 Sep, 11 Sep bolong tanpa jeda.
      final s = compute(
        marked: {20260909, 20260910},
        tx: {...run(20260901, 7), 20260910},
        today: 20260912,
      );
      expect(s.cellFor(20260831), DayCell.beforeStart, reason: 'prioritas 1');
      expect(s.cellFor(20260913), DayCell.future, reason: 'prioritas 2');
      expect(s.cellFor(20260912), DayCell.today, reason: 'prioritas 3');
      expect(s.cellFor(20260903), DayCell.recorded, reason: 'prioritas 4');
      expect(
        s.cellFor(20260910),
        DayCell.recorded,
        reason: 'transaksi MENANG atas penanda nihil di hari yang sama',
      );
      expect(s.cellFor(20260909), DayCell.markedNihil, reason: 'prioritas 5');
      expect(s.cellFor(20260908), DayCell.graceUsed, reason: 'prioritas 6');
      expect(s.cellFor(20260911), DayCell.missed, reason: 'prioritas 7');
    });

    test('hari ini menang atas recorded — hari ini selalu petak "today"', () {
      final s = compute(tx: run(20260901, 3), today: 20260903);
      expect(s.cellFor(20260903), DayCell.today);
    });

    test(
      'graceUsed yang belakangan disusul transaksi berubah jadi recorded',
      () {
        final sebelum = compute(
          tx: {...run(20260901, 7), 20260909},
          today: 20260910,
        );
        expect(sebelum.cellFor(20260908), DayCell.graceUsed);

        final sesudah = compute(
          tx: {...run(20260901, 7), 20260908, 20260909},
          today: 20260910,
        );
        expect(sesudah.cellFor(20260908), DayCell.recorded);
      },
    );
  });

  // ── Ambang penjaga jam diukur dalam HARI, bukan jarak angka ────────────────
  //
  // Seluruh T11/T21 di atas memakai pasangan tanggal DALAM BULAN YANG SAMA,
  // dan di situlah pengurangan `yyyymmdd` mentah kebetulan benar (20260910 -
  // 20260909 = 1). Justru karena itu bug ini lolos. Grup di bawah memakai
  // pasangan yang melintasi pergantian bulan dan tahun — satu-satunya tempat
  // "jarak antar bilangan" berpisah jalan dari "jumlah hari".
  group('ambang penjaga jam melintasi pergantian bulan & tahun', () {
    test('mundur 1 hari melintasi pergantian bulan tetap mode netral', () {
      // 1 Okt vs 30 Sep: selisih SATU hari, walau bilangannya berjarak 71.
      final s = compute(
        tx: run(20260925, 6), // 25..30 Sep aman
        lastSeen: 20261001,
        today: 20260930,
      );
      expect(s.clockAnomalyDetected, isTrue);
      expect(s.todayStatus, DayStatus.anomaly);
      expect(s.today, 20261001, reason: 'effectiveToday = lastSeenDay');
      expect(
        s.nextLastSeenDay,
        20261001,
        reason: 'TIDAK diturunkan — penandaan harus tetap ditolak',
      );
      expect(s.currentStreak, 6, reason: 'streak beku, tidak putus');
    });

    test('mundur 2 hari melintasi pergantian bulan tetap mode netral', () {
      final s = compute(
        tx: run(20260925, 6),
        lastSeen: 20261001,
        today: 20260929,
      );
      expect(s.todayStatus, DayStatus.anomaly);
      expect(s.today, 20261001);
      expect(s.nextLastSeenDay, 20261001);
    });

    test(
      'mundur 3 hari melintasi pergantian bulan masuk cabang koreksi jam',
      () {
        // Penjaga ambang: memperbaiki aritmetika TIDAK boleh melebarkan mode
        // netral melewati 2 hari.
        final s = compute(
          tx: run(20260925, 6),
          lastSeen: 20261001,
          today: 20260928,
        );
        expect(s.todayStatus, DayStatus.safe, reason: 'bukan anomaly');
        expect(s.today, 20260928, reason: 'effectiveToday = today');
        expect(
          s.nextLastSeenDay,
          20260928,
          reason: 'penjaga melepaskan diri sendiri',
        );
      },
    );

    test('mundur 1 hari melintasi pergantian tahun tetap mode netral', () {
      // 1 Jan 2027 vs 31 Des 2026: bilangannya berjarak 8870.
      final s = compute(
        tx: run(20261226, 6), // 26..31 Des aman
        lastSeen: 20270101,
        today: 20261231,
      );
      expect(s.clockAnomalyDetected, isTrue);
      expect(s.todayStatus, DayStatus.anomaly);
      expect(s.today, 20270101);
      expect(s.nextLastSeenDay, 20270101);
      expect(s.currentStreak, 6);
    });
  });
}
