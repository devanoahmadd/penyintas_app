import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/streak/domain/entities/streak_snapshot.dart';
import 'package:penyintas_app/features/streak/presentation/widgets/streak_calendar.dart';
import 'package:penyintas_app/widgets/common/dashed_border_painter.dart';

/// Kalender konsistensi (Task 13, spec §8.2 & §8.4).
///
/// `setUpAll(initializeDateFormatting)` WAJIB — widget ini memakai
/// `DateFormat('d MMMM', locale)` & `DateFormat('MMMM yyyy', locale)`. Tanpa
/// ini, `DateFormat` melempar `LocaleDataException` karena tidak ada
/// `GlobalMaterialLocalizations` yang memuat simbol tanggal di widget test.
/// Preseden: `test/features/dashboard/presentation/saldo_card_test.dart:49`.
class _SyncL10nDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _SyncL10nDelegate(this._l10n);
  final AppLocalizations _l10n;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async => _l10n;

  @override
  bool shouldReload(covariant _SyncL10nDelegate old) => true;
}

void main() {
  late AppLocalizations l10nId;
  late AppLocalizations l10nEn;

  setUpAll(() async {
    initializeDateFormatting();
    l10nId = await AppLocalizations.delegate.load(const Locale('id'));
    l10nEn = await AppLocalizations.delegate.load(const Locale('en'));
  });

  /// Fixture dasar: streak berjalan, `today` = 2 September 2026 (Rabu),
  /// `activatedDay` = 1 Agustus 2026 supaya bulan tampilan awal (September)
  /// punya hari-hari SEBELUM `activatedDay` di bulan sebelumnya saja — bulan
  /// September sendiri seluruhnya >= activatedDay.
  StreakSnapshot buildSnapshot({
    bool hasStarted = true,
    int activatedDay = 20260801,
    int today = 20260902,
    DayStatus todayStatus = DayStatus.pending,
    Set<int> transactionDays = const {},
    Set<int> markedDays = const {},
    Set<int> graceUsedDays = const {},
  }) => StreakSnapshot(
    hasStarted: hasStarted,
    activatedDay: activatedDay,
    currentStreak: 12,
    longestRuas: 21,
    graceAvailable: 2,
    graceUsedDays: graceUsedDays,
    todayStatus: todayStatus,
    today: today,
    nextLastSeenDay: today,
    lastBreakDay: null,
    brokenRunLength: 0,
    markedDays: markedDays,
    markedDaysAll: markedDays,
    transactionDays: transactionDays,
    clockAnomalyDetected: todayStatus == DayStatus.anomaly,
  );

  Widget harness({
    required StreakSnapshot snapshot,
    AppLocalizations? l10n,
    Locale locale = const Locale('id'),
    bool disableAnimations = false,
  }) => MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('id'), Locale('en')],
    localizationsDelegates: [
      _SyncL10nDelegate(l10n ?? l10nId),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: MediaQuery(
      data: const MediaQueryData().copyWith(
        disableAnimations: disableAnimations,
      ),
      child: Scaffold(
        body: SingleChildScrollView(
          child: StreakCalendar(snapshot: snapshot),
        ),
      ),
    ),
  );

  // ── Semantics label per petak ──

  testWidgets('tiap petak punya Semantics label utuh, bukan sekadar angka', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      harness(
        snapshot: buildSnapshot(
          today: 20260910,
          transactionDays: {20260902},
          markedDays: {20260903},
          graceUsedDays: {20260904},
          // 5 September sengaja dibiarkan kosong -> missed.
        ),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('2 September, tercatat'), findsOneWidget);
    expect(find.bySemanticsLabel('3 September, ditandai tanpa pengeluaran'), findsOneWidget);
    expect(find.bySemanticsLabel('4 September, jeda terpakai'), findsOneWidget);
    expect(find.bySemanticsLabel('5 September, terlewat'), findsOneWidget);
    expect(find.bySemanticsLabel('10 September, hari ini'), findsOneWidget);
    expect(find.bySemanticsLabel('30 September, belum tiba'), findsOneWidget);

    handle.dispose();
  });

  // ── Legend ──

  testWidgets('legend selalu tampil', (tester) async {
    await tester.pumpWidget(harness(snapshot: buildSnapshot()));
    await tester.pump();

    expect(find.byKey(const Key('consistency-legend')), findsOneWidget);
  });

  // ── Chevron bulan ──

  testWidgets('chevron mundur disabled di bulan activatedDay', (tester) async {
    await tester.pumpWidget(
      harness(
        snapshot: buildSnapshot(activatedDay: 20260901, today: 20260902),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('cal-prev')), findsOneWidget);
    final btn = tester.widget<IconButton>(find.byKey(const Key('cal-prev')));
    expect(btn.onPressed, isNull);
  });

  testWidgets('chevron maju disabled di bulan berjalan', (tester) async {
    await tester.pumpWidget(harness(snapshot: buildSnapshot()));
    await tester.pump();

    expect(find.byKey(const Key('cal-next')), findsOneWidget);
    final btn = tester.widget<IconButton>(find.byKey(const Key('cal-next')));
    expect(btn.onPressed, isNull);
  });

  testWidgets('chevron memenuhi 48dp bahkan saat disabled', (tester) async {
    await tester.pumpWidget(
      harness(
        snapshot: buildSnapshot(activatedDay: 20260901, today: 20260902),
      ),
    );
    await tester.pump();

    expect(
      tester.getSize(find.byKey(const Key('cal-prev'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byKey(const Key('cal-prev'))).width,
      greaterThanOrEqualTo(48),
    );
  });

  // ── Ukuran petak & overflow ──

  testWidgets('petak ≥32dp pada lebar 320dp', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(snapshot: buildSnapshot()));
    await tester.pump();

    expect(
      tester.getSize(find.byKey(const Key('cell-20260902'))).width,
      greaterThanOrEqualTo(32),
    );
    expect(
      tester.getSize(find.byKey(const Key('cell-20260902'))).height,
      greaterThanOrEqualTo(32),
    );
  });

  testWidgets('tidak ada overflow pada 320dp maupun 430dp', (tester) async {
    addTearDown(tester.view.reset);

    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(harness(snapshot: buildSnapshot()));
    await tester.pump();
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(430, 900);
    await tester.pumpWidget(harness(snapshot: buildSnapshot()));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  // ── T-LOCALE (Koreksi A) ──

  testWidgets(
    'judul bulan & kepala kolom hari mengikuti locale — Agustus vs August',
    (tester) async {
      await tester.pumpWidget(
        harness(
          snapshot: buildSnapshot(
            activatedDay: 20260101,
            today: 20260815,
          ),
          l10n: l10nEn,
          locale: const Locale('en'),
        ),
      );
      await tester.pump();

      expect(find.text('August 2026'), findsOneWidget, reason: 'harus lewat DateFormat(locale), bukan array diketik tangan');
      expect(find.text('Agustus 2026'), findsNothing);

      // Kepala kolom hari: EEEEE narrow, Senin..Minggu, mengikuti locale EN —
      // dihitung lewat DateFormat sungguhan, BUKAN array Indonesia hardcode.
      final expectedHeaders = List<String>.generate(
        7,
        (i) => DateFormat('EEEEE', 'en').format(DateTime(2024, 1, 1 + i)),
      );
      final headerTexts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(const Key('cal-weekday-header')),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .toList();
      expect(headerTexts, expectedHeaders);
    },
  );

  // ── Petak hari ini: scale-pop sekali (Koreksi B, S4/S5) ──

  testWidgets('petak hari ini scale-pop SEKALI saat baru ditandai', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(snapshot: buildSnapshot(todayStatus: DayStatus.pending)),
    );
    await tester.pump();

    double scaleAt() =>
        tester.widget<ScaleTransition>(find.byKey(const Key('today-cell-scale'))).scale.value;

    expect(scaleAt(), 1.0);

    // Transisi pending -> safe: pop dimulai.
    await tester.pumpWidget(
      harness(snapshot: buildSnapshot(todayStatus: DayStatus.safe)),
    );
    await tester.pump(const Duration(milliseconds: 80));
    expect(
      scaleAt(),
      isNot(1.0),
      reason: 'mid-animasi skala harus menjauh dari 1.0 — pop sedang berjalan',
    );

    await tester.pumpAndSettle();
    expect(scaleAt(), 1.0);

    // Pump ulang dengan snapshot SAMA (masih safe) — TIDAK boleh pop lagi.
    await tester.pumpWidget(
      harness(snapshot: buildSnapshot(todayStatus: DayStatus.safe)),
    );
    await tester.pump(const Duration(milliseconds: 80));
    expect(
      scaleAt(),
      1.0,
      reason: 'snapshot tak berubah — tidak boleh ada pop baru',
    );
  });

  testWidgets('disableAnimations mematikan scale-pop', (tester) async {
    await tester.pumpWidget(
      harness(
        snapshot: buildSnapshot(todayStatus: DayStatus.pending),
        disableAnimations: true,
      ),
    );
    await tester.pump();

    double scaleAt() =>
        tester.widget<ScaleTransition>(find.byKey(const Key('today-cell-scale'))).scale.value;

    await tester.pumpWidget(
      harness(
        snapshot: buildSnapshot(todayStatus: DayStatus.safe),
        disableAnimations: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));
    expect(
      scaleAt(),
      1.0,
      reason: 'disableAnimations: langsung skala akhir, tanpa frame antara',
    );
    await tester.pumpAndSettle();
    expect(scaleAt(), 1.0);
  });

  // ── T-BENTUK (Koreksi A) ──

  testWidgets(
    'recorded, markedNihil, graceUsed, missed berbeda BENTUK — bukan hanya warna',
    (tester) async {
      // today didorong jauh ke depan supaya 10-13 September semua berstatus
      // "lewat" (bukan today/future), dan dapat mengambil salah satu dari
      // 4 kategori lewat urutan presedensi cellFor.
      await tester.pumpWidget(
        harness(
          snapshot: buildSnapshot(
            today: 20260920,
            transactionDays: {20260910}, // recorded
            markedDays: {20260911}, // markedNihil
            graceUsedDays: {20260912}, // graceUsed
            // 20260913 tanpa apa pun -> missed
          ),
        ),
      );
      await tester.pump();

      final recordedKey = find.byKey(const Key('cell-20260910'));
      final markedNihilKey = find.byKey(const Key('cell-20260911'));
      final graceUsedKey = find.byKey(const Key('cell-20260912'));
      final missedKey = find.byKey(const Key('cell-20260913'));

      bool hasIcon(Finder cellFinder) => tester
          .widgetList(
            find.descendant(of: cellFinder, matching: find.byType(Icon)),
          )
          .isNotEmpty;
      bool isDashedPainter(Finder cellFinder) {
        final w = tester.widget(cellFinder);
        return w is CustomPaint && w.foregroundPainter is DashedBorderPainter;
      }
      bool hasFill(Finder cellFinder) {
        final w = tester.widget(cellFinder);
        if (w is Container) {
          final deco = w.decoration;
          if (deco is BoxDecoration) return deco.color != null;
        }
        if (w is CustomPaint) {
          // graceUsed: fill ada di Container anak, bukan di CustomPaint-nya
          // sendiri — dicek lewat descendant.
          final inner = tester.widgetList<Container>(
            find.descendant(of: cellFinder, matching: find.byType(Container)),
          );
          return inner.any((c) => (c.decoration as BoxDecoration?)?.color != null);
        }
        return false;
      }
      bool hasBorder(Finder cellFinder) {
        final w = tester.widget(cellFinder);
        if (w is Container) {
          final deco = w.decoration;
          if (deco is BoxDecoration) return deco.border != null;
        }
        return false;
      }

      // Signature bentuk per status: (icon, dashedPainter, fill, border-only).
      final signatures = <String, (bool, bool, bool, bool)>{
        'recorded': (
          hasIcon(recordedKey),
          isDashedPainter(recordedKey),
          hasFill(recordedKey),
          hasBorder(recordedKey),
        ),
        'markedNihil': (
          hasIcon(markedNihilKey),
          isDashedPainter(markedNihilKey),
          hasFill(markedNihilKey),
          hasBorder(markedNihilKey),
        ),
        'graceUsed': (
          hasIcon(graceUsedKey),
          isDashedPainter(graceUsedKey),
          hasFill(graceUsedKey),
          hasBorder(graceUsedKey),
        ),
        'missed': (
          hasIcon(missedKey),
          isDashedPainter(missedKey),
          hasFill(missedKey),
          hasBorder(missedKey),
        ),
      };

      // Bukti positif tiap ciri (bukan cuma pairwise-distinct — kalau
      // semuanya kebetulan false, tesnya lolos tanpa membuktikan apa pun).
      expect(signatures['recorded'], (false, false, true, false));
      expect(signatures['markedNihil'], (true, false, true, false));
      expect(signatures['graceUsed'], (false, true, true, false));
      expect(signatures['missed'], (false, false, false, true));

      // Pairwise distinct — empat status, empat bentuk berbeda.
      final values = signatures.values.toList();
      for (var i = 0; i < values.length; i++) {
        for (var j = i + 1; j < values.length; j++) {
          expect(
            values[i],
            isNot(values[j]),
            reason:
                '${signatures.keys.elementAt(i)} dan '
                '${signatures.keys.elementAt(j)} punya bentuk identik',
          );
        }
      }
    },
  );

  // ── Koreksi C ──

  testWidgets(
    'Koreksi C #1: hasStarted == false -> seluruh hari beforeStart, bukan missed',
    (tester) async {
      await tester.pumpWidget(
        harness(
          snapshot: buildSnapshot(
            hasStarted: false,
            activatedDay: 20260902, // diturunkan = max(today, epoch)
            today: 20260902,
          ),
        ),
      );
      await tester.pump();

      // Tidak ada satu pun PETAK berlabel "terlewat" (format "<tgl>, terlewat").
      // Regex diikat ke bentuk komposit label petak supaya tidak ikut
      // menangkap caption legend "terlewat" yang memang sengaja tampil.
      expect(
        find.bySemanticsLabel(RegExp(r'^\d+ \w+, terlewat$')),
        findsNothing,
      );
      // Hari sebelum `today` di bulan yang sama harus positif "sebelum mulai".
      expect(find.bySemanticsLabel('1 September, sebelum mulai'), findsOneWidget);
    },
  );

  testWidgets(
    'Koreksi C #2: todayStatus anomaly -> tidak ada marker lingkaran "hari '
    'ini", dan hari itu tidak pernah "terlewat"',
    (tester) async {
      await tester.pumpWidget(
        harness(
          snapshot: buildSnapshot(
            today: 20260902,
            todayStatus: DayStatus.anomaly,
          ),
        ),
      );
      await tester.pump();

      // Tidak ada label "terlewat" untuk tanggal hari ini.
      expect(
        find.bySemanticsLabel('2 September, terlewat'),
        findsNothing,
      );
      // Tidak ada marker lingkaran (BoxShape.circle) di seluruh kalender —
      // itulah petak "hari ini" yang dilarang dirender saat anomaly.
      final hasCircleMarker = tester
          .widgetList<Container>(find.byType(Container))
          .any((c) => (c.decoration as BoxDecoration?)?.shape == BoxShape.circle);
      expect(hasCircleMarker, isFalse);
    },
  );
}
