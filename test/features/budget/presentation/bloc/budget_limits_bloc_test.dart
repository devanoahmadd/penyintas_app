import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_cycle.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_limit_entity.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_overview_entity.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/budget/domain/usecases/delete_budget_limit_usecase.dart';
import 'package:penyintas_app/features/budget/domain/usecases/get_budget_limits_usecase.dart';
import 'package:penyintas_app/features/budget/domain/usecases/get_budget_overview_usecase.dart';
import 'package:penyintas_app/features/budget/domain/usecases/get_budget_settings_usecase.dart';
import 'package:penyintas_app/features/budget/domain/usecases/save_budget_limit_usecase.dart';
import 'package:penyintas_app/features/budget/presentation/bloc/budget_limits_bloc.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/get_limitable_categories_usecase.dart';

class MockGetBudgetSettings extends Mock implements GetBudgetSettingsUseCase {}
class MockGetBudgetLimits extends Mock implements GetBudgetLimitsUseCase {}
class MockSaveBudgetLimit extends Mock implements SaveBudgetLimitUseCase {}
class MockDeleteBudgetLimit extends Mock implements DeleteBudgetLimitUseCase {}
class MockTransactionRepository extends Mock implements TransactionRepository {}
class MockGetLimitableCategories extends Mock implements GetLimitableCategoriesUseCase {}
class FakeBudgetLimitEntity extends Fake implements BudgetLimitEntity {}
class FakeDeleteLimitParams extends Fake implements DeleteLimitParams {}
class FakeNoParams extends Fake implements NoParams {}

final _tSettings = BudgetSettingsEntity(
  monthlyIncome: 5000000,
  paymentDate: 25,
  emergencyFundPct: 0.10,
  createdAt: DateTime(2026, 1, 1),
  rentExpense: 1000000,
);

final _tLimit = BudgetLimitEntity(
  id: 1,
  category: 'food',
  limitAmount: 1000000,
  cycleType: BudgetCycle.monthly,
  isEnabled: true,
  updatedAt: DateTime(2026, 5, 1),
);

BudgetOverviewEntity _emptyOverview() => const BudgetOverviewEntity(
  monthlyIncome: 5000000,
  totalFixedExpenses: 1000000,
  emergencyFundMonthly: 500000,
  totalSpendable: 3500000,
  categoryItems: [],
  totalLimitSet: 0,
  totalSpentInLimited: 0,
  overallStatus: BudgetStatus.safe,
  remainingDays: 10,
  daysElapsed: 20,
);

void main() {
  setUpAll(() {
    registerFallbackValue(FakeBudgetLimitEntity());
    registerFallbackValue(FakeDeleteLimitParams());
    registerFallbackValue(FakeNoParams());
  });

  late BudgetLimitsBloc bloc;
  late MockGetBudgetSettings mockGetSettings;
  late MockGetBudgetLimits mockGetLimits;
  late MockSaveBudgetLimit mockSave;
  late MockDeleteBudgetLimit mockDelete;
  late MockTransactionRepository mockTxRepo;
  late MockGetLimitableCategories mockGetLimitableCategories;

  setUp(() {
    mockGetSettings = MockGetBudgetSettings();
    mockGetLimits = MockGetBudgetLimits();
    mockSave = MockSaveBudgetLimit();
    mockDelete = MockDeleteBudgetLimit();
    mockTxRepo = MockTransactionRepository();
    mockGetLimitableCategories = MockGetLimitableCategories();

    when(() => mockTxRepo.getTransactions(from: any(named: 'from'), to: any(named: 'to')))
        .thenAnswer((_) async => const Right(<TransactionEntity>[]));
    // Default: kembalikan daftar kosong → overview tanpa categoryItems
    when(() => mockGetLimitableCategories(any()))
        .thenAnswer((_) async => const Right(<CategoryEntity>[]));

    bloc = BudgetLimitsBloc(
      getBudgetSettings: mockGetSettings,
      getBudgetLimits: mockGetLimits,
      saveBudgetLimit: mockSave,
      deleteBudgetLimit: mockDelete,
      getBudgetOverview: const GetBudgetOverviewUseCase(),
      transactionRepository: mockTxRepo,
      getLimitableCategories: mockGetLimitableCategories,
    );
  });

  tearDown(() => bloc.close());

  group('LoadBudgetLimits', () {
    blocTest<BudgetLimitsBloc, BudgetLimitsState>(
      'emits Loading → Loaded saat berhasil',
      build: () {
        when(() => mockGetSettings(any()))
            .thenAnswer((_) async => Right(_tSettings));
        when(() => mockGetLimits(any()))
            .thenAnswer((_) async => Right([_tLimit]));
        return bloc;
      },
      act: (b) => b.add(const LoadBudgetLimits()),
      expect: () => [
        const BudgetLimitsLoading(),
        isA<BudgetLimitsLoaded>(),
      ],
    );

    blocTest<BudgetLimitsBloc, BudgetLimitsState>(
      'emits Loading → Error saat settings gagal',
      build: () {
        when(() => mockGetSettings(any()))
            .thenAnswer((_) async => const Left(CacheFailure('Gagal.')));
        return bloc;
      },
      act: (b) => b.add(const LoadBudgetLimits()),
      expect: () => [
        const BudgetLimitsLoading(),
        const BudgetLimitsError('Gagal.'),
      ],
    );
  });

  group('SaveBudgetLimit', () {
    blocTest<BudgetLimitsBloc, BudgetLimitsState>(
      'update state limits setelah save berhasil',
      build: () {
        when(() => mockSave(any())).thenAnswer((_) async => const Right(1));
        when(() => mockGetLimits(any())).thenAnswer((_) async => Right([_tLimit]));
        when(() => mockGetSettings(any())).thenAnswer((_) async => Right(_tSettings));
        return bloc;
      },
      seed: () => BudgetLimitsLoaded(limits: [_tLimit], overview: _emptyOverview()),
      act: (b) => b.add(SaveBudgetLimit(_tLimit)),
      expect: () => [isA<BudgetLimitsLoaded>()],
    );
  });

  group('DeleteBudgetLimit', () {
    blocTest<BudgetLimitsBloc, BudgetLimitsState>(
      'remove limit dari state setelah delete berhasil',
      build: () {
        when(() => mockDelete(any())).thenAnswer((_) async => const Right(null));
        // _onDelete sekarang memanggil _getSettings untuk recompute overview
        when(() => mockGetSettings(any()))
            .thenAnswer((_) async => Right(_tSettings));
        return bloc;
      },
      seed: () => BudgetLimitsLoaded(limits: [_tLimit], overview: _emptyOverview()),
      act: (b) => b.add(const DeleteBudgetLimit(id: 1, categoryName: 'food')),
      expect: () => [
        isA<BudgetLimitsLoaded>().having((s) => s.limits, 'limits', isEmpty),
      ],
    );

    blocTest<BudgetLimitsBloc, BudgetLimitsState>(
      'emits Error jika settings gagal setelah delete berhasil',
      build: () {
        when(() => mockDelete(any())).thenAnswer((_) async => const Right(null));
        when(() => mockGetSettings(any()))
            .thenAnswer((_) async => const Left(CacheFailure('Gagal.')));
        return bloc;
      },
      seed: () => BudgetLimitsLoaded(limits: [_tLimit], overview: _emptyOverview()),
      act: (b) => b.add(const DeleteBudgetLimit(id: 1, categoryName: 'food')),
      expect: () => [const BudgetLimitsError('Gagal.')],
    );
  });
}
