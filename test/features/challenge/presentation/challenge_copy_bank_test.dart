import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/presentation/utils/challenge_copy_bank.dart';

/// Delegate l10n SINKRON khusus test.
///
/// `AppLocalizations.delegateFor(...)` memuat terjemahan dari asset bundle
/// secara ASINKRON. Di dalam `testWidgets` itu membuat frame pertama dibangun
/// SEBELUM terjemahan siap, dan hasilnya bergantung pada urutan test di dalam
/// berkas: test yang sama LOLOS saat dijalankan sendiri (`--name`) tapi GAGAL
/// saat berkas dijalankan penuh, dengan callback `Builder` tidak pernah
/// berjalan sama sekali. Ketergantungan itu dibuang di sini: `SynchronousFuture`
/// membuat terjemahan tersedia pada build PERTAMA, jadi hasilnya sama persis
/// di kedua cara menjalankan.
class _DelegateSinkron extends LocalizationsDelegate<AppLocalizations> {
  const _DelegateSinkron(this.nilai);

  final AppLocalizations nilai;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) => SynchronousFuture(nilai);

  @override
  bool shouldReload(_DelegateSinkron old) => false;
}

void main() {
  late Map<String, dynamic> idJson;
  late Map<String, dynamic> enJson;
  late AppLocalizations l10nId;

  setUpAll(() {
    idJson =
        json.decode(File('assets/translations/id.json').readAsStringSync())
            as Map<String, dynamic>;
    enJson =
        json.decode(File('assets/translations/en.json').readAsStringSync())
            as Map<String, dynamic>;
    l10nId = AppLocalizations(
      const Locale('id'),
      Map<String, String>.from(idJson),
    );
  });

  /// Bungkus widget dengan l10n sinkron.
  ///
  /// `expect()` TIDAK PERNAH dipanggil di dalam `builder` — kegagalannya di
  /// fase build ditangkap Flutter sebagai galat build dan TERTELAN saat berkas
  /// dijalankan penuh, sehingga test tampak hijau padahal tidak mengunci apa
  /// pun. Nilai ditangkap saat build, ditegaskan sesudah `pumpWidget` selesai.
  Widget bungkus(WidgetBuilder builder) => MaterialApp(
    localizationsDelegates: [_DelegateSinkron(l10nId)],
    supportedLocales: const [Locale('id'), Locale('en')],
    home: Builder(builder: builder),
  );

  group('bank kalimat', () {
    test('K2 — 24 key ada (8×3 status, 2 bahasa)', () {
      const statuses = ['active', 'achieved', 'missed'];
      final missing = <String>[];
      for (final status in statuses) {
        for (int i = 1; i <= 8; i++) {
          final key = 'challenge_bank_${status}_$i';
          if (!idJson.containsKey(key)) missing.add('$key id');
          if (!enJson.containsKey(key)) missing.add('$key en');
        }
      }
      expect(missing, isEmpty);
    });

    test('U99 — nol digit', () {
      final withDigits = <String>[];
      for (final sumber in [idJson, enJson]) {
        sumber.forEach((k, v) {
          if (k.startsWith('challenge_bank_') &&
              (v as String).contains(RegExp(r'[0-9]'))) {
            withDigits.add(k);
          }
        });
      }
      expect(withDigits, isEmpty);
    });

    test('U100 — semua ≤ 120 char', () {
      final tooLong = <String>[];
      for (final sumber in [idJson, enJson]) {
        sumber.forEach((k, v) {
          if (k.startsWith('challenge_bank_') && (v as String).length > 120) {
            tooLong.add(k);
          }
        });
      }
      expect(tooLong, isEmpty);
    });

    testWidgets('U105 — same weekKey → same line', (tester) async {
      String? line1, line2;

      await tester.pumpWidget(
        bungkus((context) {
          line1 = challengeBankLine(
            context,
            status: ChallengeStatus.achieved,
            weekKey: 20260907,
          );
          line2 = challengeBankLine(
            context,
            status: ChallengeStatus.achieved,
            weekKey: 20260907,
          );
          return const Scaffold(body: SizedBox.shrink());
        }),
      );
      await tester.pumpAndSettle();

      expect(line1, isNotNull, reason: 'builder harus berjalan');
      expect(line1, isNotEmpty);
      expect(line1, equals(line2));
    });

    // Test PENGUNCI koreksi ordinal-minggu.
    //
    // Rencana meresepkan `((weekKey * 2654435761) & 0x7FFFFFFF) % kBankVariants`
    // dengan alasan "konstanta Knuth menyebarkannya". Itu SALAH:
    // `2654435761 % 8 == 1`, jadi perkalian tidak mengubah tiga bit terendah
    // dan `& 0x7FFFFFFF` juga tidak menyentuhnya — rumus itu identik PERSIS
    // dengan `weekKey % 8`. Pada delapan Senin di bawah, keduanya memberi
    // [3,2,1,0,5,4,3,2] = 6 unik (minggu ke-1 & ke-7 dan ke-2 & ke-8
    // bertabrakan). Ordinal minggu memberi [5,6,7,0,1,2,3,4] = 8 unik, dengan
    // pengulangan pertama tepat 8 minggu kemudian — maksimum teoretis untuk
    // 8 varian (pigeonhole).
    testWidgets(
      'K2 — 8 Senin berturut → 8 kalimat BERBEDA (mengunci ordinal minggu; '
      '`weekKey % 8` hanya memberi 6)',
      (tester) async {
        const senin = <int>[
          20260907,
          20260914,
          20260921,
          20260928,
          20261005,
          20261012,
          20261019,
          20261026,
        ];
        final lines = <String>[];

        await tester.pumpWidget(
          bungkus((context) {
            lines.clear();
            for (final weekKey in senin) {
              lines.add(
                challengeBankLine(
                  context,
                  status: ChallengeStatus.achieved,
                  weekKey: weekKey,
                ),
              );
            }
            return const Scaffold(body: SizedBox.shrink());
          }),
        );
        await tester.pumpAndSettle();

        expect(
          lines,
          hasLength(8),
          reason: 'kedelapan pemanggilan harus terjadi',
        );
        expect(
          lines.toSet().length,
          8,
          reason:
              'delapan Senin berturut harus memberi delapan kalimat berbeda. '
              '`weekKey % kBankVariants` hanya memberi 6 — minggu ke-1 & ke-7 '
              'dan ke-2 & ke-8 jatuh ke varian yang sama.',
        );
      },
    );

    testWidgets(
      'held/skipped/unknown → string KOSONG (kartu hasil tak muncul)',
      (tester) async {
        final hasil = <ChallengeStatus, String>{};

        await tester.pumpWidget(
          bungkus((context) {
            for (final s in const [
              ChallengeStatus.held,
              ChallengeStatus.skipped,
              ChallengeStatus.unknown,
            ]) {
              hasil[s] = challengeBankLine(
                context,
                status: s,
                weekKey: 20260907,
              );
            }
            return const Scaffold(body: SizedBox.shrink());
          }),
        );
        await tester.pumpAndSettle();

        expect(hasil, hasLength(3), reason: 'builder harus berjalan');
        for (final entry in hasil.entries) {
          expect(
            entry.value,
            isEmpty,
            reason:
                '${entry.key} bukan hasil yang bisa diceritakan — kartu hasil '
                'tidak muncul untuk status ini, jadi kalimatnya harus kosong.',
          );
        }
      },
    );

    // U103 — offline. Bank adalah SATU-SATUNYA jalur kalimat di fase ini
    // (Cloud Function ditunda, Keputusan 2), jadi ia yang dilewati setiap user
    // offline dan setiap kunjungan pertama tiap minggu. Dijaga di tingkat
    // SUMBER: kalau suatu saat ada yang menambahkan panggilan jaringan ke
    // berkas ini, test ini merah sebelum sempat rilis.
    test('U103 — challenge_copy_bank.dart tidak menyentuh jalur jaringan', () {
      final sumber = File(
        'lib/features/challenge/presentation/utils/challenge_copy_bank.dart',
      ).readAsStringSync();

      const terlarang = <String>[
        'dart:io',
        'package:http',
        'cloud_firestore',
        'firebase_',
        'HttpClient',
        'Future',
        'async',
        'await ',
      ];
      final ditemukan = terlarang.where(sumber.contains).toList();

      expect(
        ditemukan,
        isEmpty,
        reason:
            'bank kalimat harus murni sinkron & lokal — ditemukan: $ditemukan',
      );
    });
  });
}
