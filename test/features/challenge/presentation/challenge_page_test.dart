// Task 16 — halaman `/challenge`: perakitan kartu hasil, kartu utama,
// riwayat, dan dua sheet (kandidat & aturan).
//
// Aturan mengikat yang test ini kunci (lihat juga `challenge_week_range_test.dart`
// dan `challenge_history_list_test.dart` untuk bagian yang sudah dikunci
// terpisah):
// - Urutan bagian: kartu hasil (bila ada) → kartu utama/kosong → "RIWAYAT" →
//   daftar riwayat.
// - `rangeLabel` di eyebrow kartu hasil memakai `challengeWeekRange` ASLI
//   (bukan string tulisan tangan).
// - U83: "Ganti pos" TIDAK ADA di pohon widget di luar jendela Senin–Selasa.
// - Sheet kandidat: basis & target tampil SEBELUM user memilih, dan baris
//   "sudah terpakai" (U111) hanya untuk kandidat = kategori aktif dengan
//   `spentThisWeek > 0`. Angka target DIHITUNG (`computeTarget`), bukan
//   dicocokkan string.
// - Sheet aturan: contoh angka WAJIB "140.000" & "115.000", TIDAK PERNAH
//   "141.000"/"120.000". Aksi "Lewati minggu ini" hanya Senin–Selasa,
//   didahului dialog konfirmasi.
// - `state.failure` dikonsumsi SnackBar sekali per kemunculan baru, tidak
//   pernah dirender sebagai widget permanen.
// - Pohon widget TIDAK mengimpor `app_database.dart` (S-C, P5).
// - Langkah 6: nol overflow di 320dp dan 430dp.
import 'dart:async';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/utils/app_clock.dart';
import 'package:penyintas_app/features/challenge/domain/challenge_calculator.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_candidate.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_phase.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_snapshot.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_week.dart';
import 'package:penyintas_app/features/challenge/domain/repositories/challenge_repository.dart';
import 'package:penyintas_app/features/challenge/presentation/bloc/challenge_bloc.dart';
import 'package:penyintas_app/features/challenge/presentation/bloc/challenge_event.dart';
import 'package:penyintas_app/features/challenge/presentation/bloc/challenge_state.dart';
import 'package:penyintas_app/features/challenge/presentation/pages/challenge_page.dart';

class MockChallengeBloc extends MockBloc<ChallengeEvent, ChallengeState>
    implements ChallengeBloc {}

class MockChallengeRepository extends Mock implements ChallengeRepository {}

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
  late AppLocalizations l10n;
  late MockChallengeBloc bloc;
  late MockChallengeRepository repo;

  setUpAll(() async {
    initializeDateFormatting();
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
    registerFallbackValue(const ChallengeStarted());
  });

  setUp(() {
    bloc = MockChallengeBloc();
    repo = MockChallengeRepository();
    if (sl.isRegistered<ChallengeRepository>()) {
      sl.unregister<ChallengeRepository>();
    }
    sl.registerFactory<ChallengeRepository>(() => repo);
    if (sl.isRegistered<AppClock>()) sl.unregister<AppClock>();
    // Senin 2026-09-07, 09:00 — DI DALAM jendela T6/T7. Test spesifik
    // U83 mengganti registrasi ini ke Rabu.
    sl.registerFactory<AppClock>(() => FixedClock(DateTime(2026, 9, 7, 9)));
  });

  tearDown(() {
    if (sl.isRegistered<ChallengeRepository>()) {
      sl.unregister<ChallengeRepository>();
    }
    if (sl.isRegistered<AppClock>()) sl.unregister<AppClock>();
  });

  // ── Fixture ──────────────────────────────────────────────────────────────

  ChallengeWeek week({
    int weekKey = 20260907,
    ChallengeStatus status = ChallengeStatus.active,
    String? category = 'food',
    int? target = 115000,
    int? baseline = 140000,
    int? finalSpent,
    DateTime? resultSeenAt,
  }) => ChallengeWeek(
    weekKey: weekKey,
    category: category,
    targetAmount: target,
    baselineAmount: baseline,
    status: status,
    finalSpent: finalSpent,
    resolvedAt: finalSpent == null ? null : DateTime(2026, 9, 7, 6),
    resultSeenAt: resultSeenAt,
  );

  ChallengeSnapshot snapshot({
    ChallengePhase? phase,
    ChallengeWeek? pendingResult,
    int spentThisWeek = 34000,
    int excludedThisWeek = 0,
    List<ChallengeWeek> history = const [],
    int daysLeft = 5,
  }) => ChallengeSnapshot(
    phase: phase ?? PhaseActive(week: week(), spent: spentThisWeek),
    pendingResult: pendingResult,
    spentThisWeek: spentThisWeek,
    excludedThisWeek: excludedThisWeek,
    history: history,
    daysLeft: daysLeft,
  );

  ChallengeState state({
    ChallengeViewStatus status = ChallengeViewStatus.ready,
    ChallengeSnapshot? snapshot,
    Failure? failure,
  }) => ChallengeState(status: status, snapshot: snapshot, failure: failure);

  Widget bungkus(ChallengeState awal, {Stream<ChallengeState>? aliran}) {
    whenListen(
      bloc,
      aliran ?? Stream<ChallengeState>.value(awal),
      initialState: awal,
    );
    return MaterialApp(
      locale: const Locale('id'),
      supportedLocales: const [Locale('id'), Locale('en')],
      localizationsDelegates: [
        _SyncL10nDelegate(l10n),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: BlocProvider<ChallengeBloc>.value(
        value: bloc,
        child: const ChallengePage(),
      ),
    );
  }

  // ── Kartu hasil di atas kartu utama ───────────────────────────────────────

  testWidgets('kartu hasil tampil DI ATAS kartu utama saat ada pendingResult', (
    tester,
  ) async {
    final pending = week(
      weekKey: 20260824,
      status: ChallengeStatus.achieved,
      finalSpent: 90000,
    );
    await tester.pumpWidget(
      bungkus(state(snapshot: snapshot(pendingResult: pending))),
    );
    await tester.pump();

    expect(find.byKey(const Key('challenge-result-card')), findsOneWidget);
    final yHasil = tester
        .getTopLeft(find.byKey(const Key('challenge-result-card')))
        .dy;
    final yUtama = tester
        .getTopLeft(find.byKey(const Key('challenge-change-category-row')))
        .dy;
    expect(
      yHasil,
      lessThan(yUtama),
      reason: 'kartu hasil harus di atas kartu utama',
    );
  });

  testWidgets('TIDAK ADA kartu hasil saat pendingResult null', (tester) async {
    await tester.pumpWidget(bungkus(state(snapshot: snapshot())));
    await tester.pump();

    expect(find.byKey(const Key('challenge-result-card')), findsNothing);
  });

  // ── Validasi rangeLabel ASLI di eyebrow kartu hasil ───────────────────────

  testWidgets(
    'eyebrow kartu hasil memakai challengeWeekRange asli (weekKey 20260824 '
    '→ "24–30 Agu")',
    (tester) async {
      final pending = week(
        weekKey: 20260824,
        status: ChallengeStatus.achieved,
        finalSpent: 90000,
      );
      await tester.pumpWidget(
        bungkus(state(snapshot: snapshot(pendingResult: pending))),
      );
      await tester.pump();

      final eyebrow =
          (tester.widget(find.byKey(const Key('challenge-result-eyebrow')))
                  as Text)
              .data;
      expect(
        eyebrow,
        '${l10n.challengeResultEyebrow.toUpperCase()} · 24–30 AGU',
        reason:
            '20260824 (Senin) rentangnya Senin..Minggu = 24–30 Agu — '
            'diverifikasi lewat `date -d 2026-08-24` (Monday) dan '
            '`date -d 2026-08-30` (Sunday), BUKAN dihitung dari brief.',
      );
    },
  );

  // ── Riwayat ────────────────────────────────────────────────────────────

  testWidgets('bagian RIWAYAT tersembunyi saat history kosong', (tester) async {
    await tester.pumpWidget(bungkus(state(snapshot: snapshot(history: []))));
    await tester.pump();

    expect(find.text(l10n.challengeHistoryTitle.toUpperCase()), findsNothing);
    expect(find.byKey(const Key('challenge-history-list')), findsNothing);
  });

  testWidgets(
    'bagian RIWAYAT tampil SESUDAH kartu utama saat history tidak kosong',
    (tester) async {
      await tester.pumpWidget(
        bungkus(
          state(
            snapshot: snapshot(
              history: [
                week(
                  weekKey: 20260831,
                  status: ChallengeStatus.achieved,
                  finalSpent: 90000,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text(l10n.challengeHistoryTitle.toUpperCase()),
        findsOneWidget,
      );
      expect(find.byKey(const Key('challenge-history-list')), findsOneWidget);

      final yUtama = tester
          .getTopLeft(find.byKey(const Key('challenge-change-category-row')))
          .dy;
      final yRiwayat = tester
          .getTopLeft(find.text(l10n.challengeHistoryTitle.toUpperCase()))
          .dy;
      expect(yUtama, lessThan(yRiwayat));
    },
  );

  // ── U83 · jendela Senin–Selasa untuk "Ganti pos" ─────────────────────────

  testWidgets('U83 · "Ganti pos" ADA saat clock Senin (dalam jendela)', (
    tester,
  ) async {
    // Sudah Senin dari `setUp()` — tidak perlu override.
    await tester.pumpWidget(bungkus(state(snapshot: snapshot())));
    await tester.pump();

    expect(
      find.byKey(const Key('challenge-change-category-row')),
      findsOneWidget,
    );
  });

  testWidgets(
    'U83 · "Ganti pos" TIDAK ADA di pohon widget saat clock Rabu (luar jendela)',
    (tester) async {
      sl.unregister<AppClock>();
      sl.registerFactory<AppClock>(
        () => FixedClock(DateTime(2026, 9, 9, 9)), // Rabu
      );

      await tester.pumpWidget(bungkus(state(snapshot: snapshot())));
      await tester.pump();

      expect(
        find.byKey(const Key('challenge-change-category-row')),
        findsNothing,
      );
    },
  );

  // ── Sheet kandidat ────────────────────────────────────────────────────────

  List<ChallengeCandidate> kandidatContoh() => [
    ChallengeCandidate(
      category: 'food',
      baseline: 140000,
      target: computeTarget(140000),
    ),
    ChallengeCandidate(
      category: 'transport',
      baseline: 96000,
      target: computeTarget(96000),
    ),
  ];

  testWidgets(
    'sheet kandidat · basis & target tampil SEBELUM user memilih apa pun',
    (tester) async {
      when(
        () => repo.getCandidates(any()),
      ).thenAnswer((_) async => Right(kandidatContoh()));
      await tester.pumpWidget(bungkus(state(snapshot: snapshot())));
      await tester.pump();

      await tester.tap(find.byKey(const Key('challenge-change-category-row')));
      await tester.pumpAndSettle();

      // Rev 5 desain: test yang MENGHITUNG, bukan mencocokkan string —
      // `computeTarget` dipanggil ULANG di sini, independen dari fixture.
      expect(computeTarget(140000), 115000);
      expect(
        find.byKey(const Key('challenge-candidate-target-food')),
        findsOneWidget,
      );
      expect(
        (tester.widget(find.byKey(const Key('challenge-candidate-target-food')))
                as Text)
            .data,
        contains('115.000'),
      );
      expect(
        find.byKey(const Key('challenge-candidate-target-transport')),
        findsOneWidget,
      );
      expect(
        (tester.widget(
                  find.byKey(const Key('challenge-candidate-target-transport')),
                )
                as Text)
            .data,
        contains('80.000'),
        reason: 'computeTarget(96000) = 80.000, bukan 81.000',
      );
    },
  );

  testWidgets(
    'U111 · kandidat = kategori aktif dengan spentThisWeek > 0 → baris '
    '"sudah terpakai" hadir',
    (tester) async {
      when(
        () => repo.getCandidates(any()),
      ).thenAnswer((_) async => Right(kandidatContoh()));
      await tester.pumpWidget(
        bungkus(state(snapshot: snapshot(spentThisWeek: 18000))),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('challenge-change-category-row')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('challenge-candidate-spent-food')),
        findsOneWidget,
        reason: 'kategori aktif snapshot() adalah food',
      );
      expect(
        find.byKey(const Key('challenge-candidate-spent-transport')),
        findsNothing,
        reason:
            'transport bukan kategori aktif — tidak pernah "sudah terpakai"',
      );
    },
  );

  testWidgets(
    'kandidat = kategori aktif TAPI spentThisWeek == 0 → baris "sudah '
    'terpakai" TIDAK ADA',
    (tester) async {
      when(
        () => repo.getCandidates(any()),
      ).thenAnswer((_) async => Right(kandidatContoh()));
      await tester.pumpWidget(
        bungkus(state(snapshot: snapshot(spentThisWeek: 0))),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('challenge-change-category-row')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('challenge-candidate-spent-food')),
        findsNothing,
      );
    },
  );

  testWidgets('sheet kandidat · pilih kategori lain lalu "Pakai ini" → '
      'ChallengeCategoryChanged terkirim', (tester) async {
    when(
      () => repo.getCandidates(any()),
    ).thenAnswer((_) async => Right(kandidatContoh()));
    await tester.pumpWidget(bungkus(state(snapshot: snapshot())));
    await tester.pump();

    await tester.tap(find.byKey(const Key('challenge-change-category-row')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('challenge-candidate-radio-transport')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('challenge-candidate-submit')));
    await tester.pumpAndSettle();

    verify(
      () => bloc.add(const ChallengeCategoryChanged('transport')),
    ).called(1);
    expect(find.byKey(const Key('challenge-candidate-submit')), findsNothing);
  });

  testWidgets('baris kandidat tinggi ≥ 56dp', (tester) async {
    when(
      () => repo.getCandidates(any()),
    ).thenAnswer((_) async => Right(kandidatContoh()));
    await tester.pumpWidget(bungkus(state(snapshot: snapshot())));
    await tester.pump();

    await tester.tap(find.byKey(const Key('challenge-change-category-row')));
    await tester.pumpAndSettle();

    final size = tester.getSize(
      find.byKey(const Key('challenge-candidate-target-food')).hitTestable(),
    );
    // Kolom teks itu sendiri bisa < 56 (tinggi intrinsik teks) — yang wajib
    // ≥56 adalah BARIS pembungkusnya. Cari ancestor `InkWell` lewat
    // `find.ancestor` supaya diuji dimensi baris sungguhan, bukan label.
    expect(size.height, greaterThanOrEqualTo(0)); // guard: widget ditemukan
    final rowFinder = find.ancestor(
      of: find.byKey(const Key('challenge-candidate-radio-food')),
      matching: find.byType(InkWell),
    );
    expect(tester.getSize(rowFinder).height, greaterThanOrEqualTo(56));
  });

  // ── Sheet aturan ──────────────────────────────────────────────────────────

  testWidgets('sheet aturan · contoh angka WAJIB "140.000" & "115.000"', (
    tester,
  ) async {
    await tester.pumpWidget(bungkus(state(snapshot: snapshot())));
    await tester.pump();

    await tester.tap(find.byKey(const Key('challenge-help')));
    await tester.pumpAndSettle();

    final body =
        (tester.widget(find.byKey(const Key('challenge-rules-body'))) as Text)
            .data!;
    expect(body, contains('140.000'));
    expect(body, contains('115.000'));
  });

  testWidgets(
    'sheet aturan · TIDAK PERNAH "141.000" atau "120.000" (pasangan keliru)',
    (tester) async {
      await tester.pumpWidget(bungkus(state(snapshot: snapshot())));
      await tester.pump();

      await tester.tap(find.byKey(const Key('challenge-help')));
      await tester.pumpAndSettle();

      final body =
          (tester.widget(find.byKey(const Key('challenge-rules-body'))) as Text)
              .data!;
      expect(body, isNot(contains('141.000')));
      expect(body, isNot(contains('120.000')));
    },
  );

  testWidgets('sheet aturan · "Lewati minggu ini" ADA saat Senin', (
    tester,
  ) async {
    await tester.pumpWidget(bungkus(state(snapshot: snapshot())));
    await tester.pump();

    await tester.tap(find.byKey(const Key('challenge-help')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('challenge-skip-action')), findsOneWidget);
  });

  testWidgets(
    'sheet aturan · "Lewati minggu ini" TIDAK ADA saat Rabu (luar jendela)',
    (tester) async {
      sl.unregister<AppClock>();
      sl.registerFactory<AppClock>(() => FixedClock(DateTime(2026, 9, 9, 9)));

      await tester.pumpWidget(bungkus(state(snapshot: snapshot())));
      await tester.pump();

      await tester.tap(find.byKey(const Key('challenge-help')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('challenge-skip-action')), findsNothing);
    },
  );

  testWidgets(
    'sheet aturan · "Lewati minggu ini" → BATAL pada dialog konfirmasi → '
    'ChallengeWeekSkipped TIDAK terkirim',
    (tester) async {
      await tester.pumpWidget(bungkus(state(snapshot: snapshot())));
      await tester.pump();

      await tester.tap(find.byKey(const Key('challenge-help')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('challenge-skip-action')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('challenge-skip-confirm-dialog')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('challenge-skip-confirm-cancel')));
      await tester.pumpAndSettle();

      verifyNever(() => bloc.add(const ChallengeWeekSkipped()));
      // Sheet aturan masih terbuka — batal cuma menutup dialog.
      expect(find.byKey(const Key('challenge-skip-action')), findsOneWidget);
    },
  );

  testWidgets(
    'sheet aturan · "Lewati minggu ini" → KONFIRMASI → ChallengeWeekSkipped '
    'terkirim, sheet tertutup',
    (tester) async {
      await tester.pumpWidget(bungkus(state(snapshot: snapshot())));
      await tester.pump();

      await tester.tap(find.byKey(const Key('challenge-help')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('challenge-skip-action')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('challenge-skip-confirm-confirm')));
      await tester.pumpAndSettle();

      verify(() => bloc.add(const ChallengeWeekSkipped())).called(1);
      expect(find.byKey(const Key('challenge-skip-action')), findsNothing);
    },
  );

  // ── Kegagalan (status.failure & failure snackbar) ────────────────────────

  testWidgets(
    'status failure (snapshot null) → pesan + tombol coba lagi, TANPA kartu',
    (tester) async {
      await tester.pumpWidget(
        bungkus(
          state(
            status: ChallengeViewStatus.failure,
            failure: const CacheFailure(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('challenge-retry-button')), findsOneWidget);
      expect(find.byKey(const Key('challenge-result-card')), findsNothing);

      await tester.tap(find.byKey(const Key('challenge-retry-button')));
      verify(() => bloc.add(const ChallengeStarted())).called(1);
    },
  );

  testWidgets('status initial/loading → skeleton, BUKAN kartu', (tester) async {
    await tester.pumpWidget(
      bungkus(state(status: ChallengeViewStatus.loading)),
    );
    await tester.pump();

    expect(find.byKey(const Key('challenge-skeleton')), findsOneWidget);
    expect(find.byKey(const Key('challenge-result-card')), findsNothing);
  });

  testWidgets('failure baru (edge null→non-null) → SnackBar tampil sekali', (
    tester,
  ) async {
    final controller = StreamController<ChallengeState>();
    addTearDown(controller.close);
    final awal = state(snapshot: snapshot());

    await tester.pumpWidget(bungkus(awal, aliran: controller.stream));
    await tester.pump();

    controller.add(state(snapshot: snapshot(), failure: const CacheFailure()));
    await tester.pump();

    expect(find.text(l10n.challengeActionFailed), findsOneWidget);
  });

  // ── S-C · pohon widget tidak mengimpor modul database Drift ─────────────

  test('S-C · challenge_page.dart, candidate_picker_sheet.dart, dan '
      'challenge_rules_sheet.dart tidak mengimpor app_database.dart', () async {
    final result = await Process.run('grep', [
      '-F',
      '-l',
      'app_database.dart',
      'lib/features/challenge/presentation/pages/challenge_page.dart',
      'lib/features/challenge/presentation/widgets/candidate_picker_sheet.dart',
      'lib/features/challenge/presentation/widgets/challenge_rules_sheet.dart',
    ]);
    expect(
      result.exitCode,
      1,
      reason:
          'ada berkas Task 16 yang mengimpor app_database.dart. '
          'stdout: ${result.stdout}',
    );
  });

  // ── Langkah 6 · nol overflow di 320dp dan 430dp ──────────────────────────

  testWidgets('nol overflow pada 320dp maupun 430dp', (tester) async {
    addTearDown(tester.view.reset);
    when(
      () => repo.getCandidates(any()),
    ).thenAnswer((_) async => Right(kandidatContoh()));

    final snapshotPenuh = snapshot(
      pendingResult: week(
        weekKey: 20260824,
        status: ChallengeStatus.achieved,
        finalSpent: 90000,
      ),
      history: [
        week(
          weekKey: 20260831,
          status: ChallengeStatus.missed,
          finalSpent: 132000,
        ),
        week(weekKey: 20260817, status: ChallengeStatus.held, category: null),
        week(weekKey: 20260810, status: ChallengeStatus.unknown),
      ],
    );

    tester.view.physicalSize = const Size(320, 1200);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(bungkus(state(snapshot: snapshotPenuh)));
    await tester.pump();
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(430, 1200);
    await tester.pumpWidget(bungkus(state(snapshot: snapshotPenuh)));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
