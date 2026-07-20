import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/survival/domain/entities/survival_mode_entity.dart';
import 'package:penyintas_app/features/survival/domain/entities/survival_tip_entity.dart';
import 'package:penyintas_app/features/survival/domain/usecases/clear_survival_activated_usecase.dart';
import 'package:penyintas_app/features/survival/domain/usecases/get_survival_mode_usecase.dart';
import 'package:penyintas_app/features/survival/domain/usecases/get_survival_tips_usecase.dart';
import 'package:penyintas_app/features/survival/domain/usecases/record_survival_activated_usecase.dart';
import 'package:penyintas_app/features/survival/presentation/bloc/survival_bloc.dart';

class MockGetSurvivalModeUseCase extends Mock
    implements GetSurvivalModeUseCase {}

class MockGetSurvivalTipsUseCase extends Mock
    implements GetSurvivalTipsUseCase {}

class MockRecordSurvivalActivatedUseCase extends Mock
    implements RecordSurvivalActivatedUseCase {}

class MockClearSurvivalActivatedUseCase extends Mock
    implements ClearSurvivalActivatedUseCase {}

class FakeDashboardEntity extends Fake implements DashboardEntity {}

class FakeSurvivalTipsParams extends Fake implements SurvivalTipsParams {}

// ── Helpers ───────────────────────────────────────────────────────────────

DashboardEntity _makeEntity({required BudgetStatus status}) => DashboardEntity(
      dailyBudget: 50000,
      spentToday: 0,
      remainingToday: 50000,
      totalMonthlyBudget: 1000000,
      totalSpentThisMonth: status == BudgetStatus.danger ? 870000 : 300000,
      totalRemaining: status == BudgetStatus.danger ? 80000 : 700000,
      daysToLive: status == BudgetStatus.danger ? 2 : 14,
      remainingDays: 10,
      avgDailySpend: 30000,
      status: status,
      lastUpdated: DateTime(2026, 5, 21),
      todayTransactions: const [],
      emergencyFundMonthly: 50000,
    );

const _tSurvivalEntity = SurvivalModeEntity(
  isActive: true,
  remainingAmount: 80000,
  remainingDays: 10,
  suggestedDailyBudget: 8000,
  tips: [],
);

const _tInactiveEntity = SurvivalModeEntity(
  isActive: false,
  remainingAmount: 700000,
  remainingDays: 10,
  suggestedDailyBudget: 70000,
  tips: [],
);

const _tTips = [
  SurvivalTip(
    title: 'Masak sendiri',
    description: 'Hemat dengan beli bahan di pasar.',
    estimatedSaving: 15000,
  ),
  SurvivalTip(
    title: 'Kurangi transportasi',
    description: 'Gabungkan perjalanan dalam satu trip.',
    estimatedSaving: 10000,
  ),
];

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDashboardEntity());
    registerFallbackValue(FakeSurvivalTipsParams());
  });

  late SurvivalBloc bloc;
  late MockGetSurvivalModeUseCase mockGetMode;
  late MockGetSurvivalTipsUseCase mockGetTips;
  late MockRecordSurvivalActivatedUseCase mockRecord;
  late MockClearSurvivalActivatedUseCase mockClear;

  setUp(() {
    mockGetMode = MockGetSurvivalModeUseCase();
    mockGetTips = MockGetSurvivalTipsUseCase();
    mockRecord = MockRecordSurvivalActivatedUseCase();
    mockClear = MockClearSurvivalActivatedUseCase();

    when(() => mockRecord()).thenAnswer((_) async => const Right(null));
    when(() => mockClear()).thenAnswer((_) async => const Right(null));

    bloc = SurvivalBloc(
      getSurvivalMode: mockGetMode,
      getSurvivalTips: mockGetTips,
      recordActivated: mockRecord,
      clearActivated: mockClear,
    );
  });

  tearDown(() => bloc.close());

  // ── LoadSurvivalMode ────────────────────────────────────────────────────

  group('LoadSurvivalMode', () {
    blocTest<SurvivalBloc, SurvivalState>(
      'emits SurvivalInactive saat budget status bukan danger',
      build: () {
        when(() => mockGetMode(any()))
            .thenAnswer((_) async => const Right(_tInactiveEntity));
        return bloc;
      },
      act: (b) =>
          b.add(LoadSurvivalMode(_makeEntity(status: BudgetStatus.safe))),
      expect: () => [const SurvivalInactive()],
    );

    blocTest<SurvivalBloc, SurvivalState>(
      'emits SurvivalActive saat danger dan activatedAt null — panggil recordActivated',
      build: () {
        when(() => mockGetMode(any()))
            .thenAnswer((_) async => const Right(_tSurvivalEntity));
        return bloc;
      },
      act: (b) =>
          b.add(LoadSurvivalMode(_makeEntity(status: BudgetStatus.danger))),
      expect: () => [const SurvivalActive(_tSurvivalEntity)],
      verify: (_) => verify(() => mockRecord()).called(1),
    );

    blocTest<SurvivalBloc, SurvivalState>(
      'emits SurvivalActive saat danger dan activatedAt sudah ada — tidak panggil recordActivated',
      build: () {
        final entityWithTs = _tSurvivalEntity.copyWith(
          activatedAt: DateTime(2026, 5, 20),
        );
        when(() => mockGetMode(any()))
            .thenAnswer((_) async => Right(entityWithTs));
        return bloc;
      },
      act: (b) =>
          b.add(LoadSurvivalMode(_makeEntity(status: BudgetStatus.danger))),
      verify: (_) => verifyNever(() => mockRecord()),
    );

    blocTest<SurvivalBloc, SurvivalState>(
      'emits SurvivalInactive dan panggil clearActivated saat keluar dari danger dengan activatedAt ada',
      build: () {
        final inactiveWithTs = _tInactiveEntity.copyWith(
          activatedAt: DateTime(2026, 5, 20),
        );
        when(() => mockGetMode(any()))
            .thenAnswer((_) async => Right(inactiveWithTs));
        return bloc;
      },
      act: (b) =>
          b.add(LoadSurvivalMode(_makeEntity(status: BudgetStatus.safe))),
      expect: () => [const SurvivalInactive()],
      verify: (_) => verify(() => mockClear()).called(1),
    );

    blocTest<SurvivalBloc, SurvivalState>(
      'mempertahankan tips yang sudah di-cache saat dashboard refresh dengan data baru',
      build: () {
        // Simulasi dashboard refresh: saldo berkurang (70000 dari sebelumnya 80000)
        final refreshedEntity =
            _tSurvivalEntity.copyWith(remainingAmount: 70000);
        when(() => mockGetMode(any()))
            .thenAnswer((_) async => Right(refreshedEntity));
        return bloc;
      },
      seed: () => SurvivalTipsLoaded(_tSurvivalEntity.copyWith(tips: _tTips)),
      act: (b) =>
          b.add(LoadSurvivalMode(_makeEntity(status: BudgetStatus.danger))),
      expect: () => [
        // Entity baru (remainingAmount=70000) tapi tips tetap sama
        SurvivalTipsLoaded(
          _tSurvivalEntity.copyWith(remainingAmount: 70000, tips: _tTips),
        ),
      ],
    );

    blocTest<SurvivalBloc, SurvivalState>(
      'emits SurvivalError saat getSurvivalMode gagal',
      build: () {
        when(() => mockGetMode(any())).thenAnswer(
            (_) async => Left(CacheFailure('Gagal memuat.')));
        return bloc;
      },
      act: (b) =>
          b.add(LoadSurvivalMode(_makeEntity(status: BudgetStatus.danger))),
      expect: () => [const SurvivalError('Gagal memuat.')],
    );
  });

  // ── FetchSurvivalTips ───────────────────────────────────────────────────

  group('FetchSurvivalTips', () {
    blocTest<SurvivalBloc, SurvivalState>(
      'emits TipsLoading → TipsLoaded saat fetch berhasil',
      build: () {
        when(() => mockGetTips(any()))
            .thenAnswer((_) async => const Right(_tTips));
        return bloc;
      },
      seed: () => const SurvivalActive(_tSurvivalEntity),
      act: (b) => b.add(const FetchSurvivalTips(language: 'id')),
      expect: () => [
        const SurvivalTipsLoading(_tSurvivalEntity),
        SurvivalTipsLoaded(_tSurvivalEntity.copyWith(tips: _tTips)),
      ],
    );

    blocTest<SurvivalBloc, SurvivalState>(
      'tidak re-fetch jika state sudah SurvivalTipsLoaded',
      build: () => bloc,
      seed: () =>
          SurvivalTipsLoaded(_tSurvivalEntity.copyWith(tips: _tTips)),
      act: (b) => b.add(const FetchSurvivalTips(language: 'id')),
      expect: () => <SurvivalState>[],
      verify: (_) => verifyNever(() => mockGetTips(any())),
    );

    blocTest<SurvivalBloc, SurvivalState>(
      'emits SurvivalError dengan entity saat fetch gagal',
      build: () {
        when(() => mockGetTips(any())).thenAnswer(
            (_) async => Left(ServerFailure('Gagal mengambil tips.')));
        return bloc;
      },
      seed: () => const SurvivalActive(_tSurvivalEntity),
      act: (b) => b.add(const FetchSurvivalTips(language: 'id')),
      expect: () => [
        const SurvivalTipsLoading(_tSurvivalEntity),
        const SurvivalError('Gagal mengambil tips.', _tSurvivalEntity),
      ],
    );

    blocTest<SurvivalBloc, SurvivalState>(
      'tidak fetch jika state bukan SurvivalActive atau SurvivalError',
      build: () => bloc,
      seed: () => const SurvivalInactive(),
      act: (b) => b.add(const FetchSurvivalTips(language: 'id')),
      expect: () => <SurvivalState>[],
      verify: (_) => verifyNever(() => mockGetTips(any())),
    );
  });

  // ── SurvivalSessionReset (#152) ─────────────────────────────────────────

  group('SurvivalSessionReset (#152)', () {
    late StreamController<String?> uidController;
    late Completer<Either<Failure, List<SurvivalTip>>> tipsCompleter;

    setUp(() {
      uidController = StreamController<String?>.broadcast();
      tipsCompleter = Completer<Either<Failure, List<SurvivalTip>>>();
    });
    tearDown(() => uidController.close());

    // Bloc BARU per test (bukan `bloc` dari setUp global) karena uidChanges
    // hanya bisa dipasang lewat constructor. blocTest menutup bloc ini sendiri.
    SurvivalBloc buildWithUidStream() => SurvivalBloc(
          getSurvivalMode: mockGetMode,
          getSurvivalTips: mockGetTips,
          recordActivated: mockRecord,
          clearActivated: mockClear,
          uidChanges: uidController.stream,
        );

    blocTest<SurvivalBloc, SurvivalState>(
      'emisi pertama (sesi berjalan) TIDAK me-reset state',
      build: buildWithUidStream,
      seed: () => const SurvivalActive(_tSurvivalEntity),
      act: (bloc) async {
        uidController.add('uid-a');
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => <SurvivalState>[],
    );

    blocTest<SurvivalBloc, SurvivalState>(
      'uid sama berulang (token refresh) TIDAK me-reset state',
      build: buildWithUidStream,
      seed: () => const SurvivalActive(_tSurvivalEntity),
      act: (bloc) async {
        uidController.add('uid-a'); // sesi berjalan — diabaikan (skip 1)
        uidController.add('uid-a'); // refresh token — disaring distinct()
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => <SurvivalState>[],
    );

    blocTest<SurvivalBloc, SurvivalState>(
      'uid berubah (logout) → reset ke SurvivalInitial',
      build: buildWithUidStream,
      seed: () => const SurvivalActive(_tSurvivalEntity),
      act: (bloc) async {
        uidController.add('uid-a'); // sesi berjalan — diabaikan (skip 1)
        uidController.add(null); // logout
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [const SurvivalInitial()],
    );

    blocTest<SurvivalBloc, SurvivalState>(
      'ganti akun (uid-a → uid-b) → reset ke SurvivalInitial',
      build: buildWithUidStream,
      seed: () => const SurvivalActive(_tSurvivalEntity),
      act: (bloc) async {
        uidController.add('uid-a');
        uidController.add('uid-b');
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [const SurvivalInitial()],
    );

    blocTest<SurvivalBloc, SurvivalState>(
      'fetch tips yang masih berjalan TIDAK menimpa state setelah reset sesi',
      build: () {
        // Fetch ditahan lewat Completer: kita yang menentukan kapan selesai,
        // meniru jawaban jaringan/AI yang datang setelah user logout.
        when(() => mockGetTips(any()))
            .thenAnswer((_) => tipsCompleter.future);
        return buildWithUidStream();
      },
      seed: () => const SurvivalActive(_tSurvivalEntity),
      act: (bloc) async {
        bloc.add(const FetchSurvivalTips(language: 'id'));
        await Future<void>.delayed(Duration.zero);

        uidController.add('uid-a'); // sesi berjalan — diabaikan (skip 1)
        uidController.add(null); // logout saat fetch masih menggantung
        await Future<void>.delayed(Duration.zero);

        // Jawaban user lama baru tiba — harus dibuang, bukan di-emit.
        tipsCompleter.complete(const Right(_tTips));
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        const SurvivalTipsLoading(_tSurvivalEntity),
        const SurvivalInitial(),
      ],
    );
  });
}
