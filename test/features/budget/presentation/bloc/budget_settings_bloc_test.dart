import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/budget/domain/usecases/get_budget_settings_usecase.dart';
import 'package:penyintas_app/features/budget/domain/usecases/save_budget_settings_usecase.dart';
import 'package:penyintas_app/features/budget/presentation/bloc/budget_settings_bloc.dart';

class MockGetBudgetSettingsUseCase extends Mock
    implements GetBudgetSettingsUseCase {}

class MockSaveBudgetSettingsUseCase extends Mock
    implements SaveBudgetSettingsUseCase {}

class FakeBudgetSettingsEntity extends Fake implements BudgetSettingsEntity {}

final _tSettings = BudgetSettingsEntity(
  monthlyIncome: 5000000,
  paymentDate: 25,
  emergencyFundPct: 0.10,
  createdAt: DateTime(2026, 1, 1),
  rentExpense: 1000000,
);

void main() {
  setUpAll(() => registerFallbackValue(FakeBudgetSettingsEntity()));

  late BudgetSettingsBloc bloc;
  late MockGetBudgetSettingsUseCase mockGet;
  late MockSaveBudgetSettingsUseCase mockSave;

  setUp(() {
    mockGet = MockGetBudgetSettingsUseCase();
    mockSave = MockSaveBudgetSettingsUseCase();
    bloc = BudgetSettingsBloc(
      getBudgetSettings: mockGet,
      saveBudgetSettings: mockSave,
    );
  });

  tearDown(() => bloc.close());

  group('LoadBudgetSettings', () {
    blocTest<BudgetSettingsBloc, BudgetSettingsState>(
      'emits Loading → Loaded saat berhasil',
      build: () {
        when(
          () => mockGet(const NoParams()),
        ).thenAnswer((_) async => Right(_tSettings));
        return bloc;
      },
      act: (b) => b.add(const LoadBudgetSettings()),
      expect: () => [
        const BudgetSettingsLoading(),
        BudgetSettingsLoaded(_tSettings),
      ],
    );

    blocTest<BudgetSettingsBloc, BudgetSettingsState>(
      'emits Loading → Error saat gagal',
      build: () {
        when(
          () => mockGet(const NoParams()),
        ).thenAnswer((_) async => const Left(CacheFailure('Gagal.')));
        return bloc;
      },
      act: (b) => b.add(const LoadBudgetSettings()),
      expect: () => [
        const BudgetSettingsLoading(),
        const BudgetSettingsError('Gagal.'),
      ],
    );
  });

  group('SaveBudgetSettings', () {
    blocTest<BudgetSettingsBloc, BudgetSettingsState>(
      'emits Saving → Saved saat berhasil',
      build: () {
        when(() => mockSave(any())).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => BudgetSettingsLoaded(_tSettings),
      act: (b) => b.add(SaveBudgetSettings(_tSettings)),
      expect: () => [const BudgetSettingsSaving(), const BudgetSettingsSaved()],
    );

    blocTest<BudgetSettingsBloc, BudgetSettingsState>(
      'emits Saving → Error saat gagal',
      build: () {
        when(
          () => mockSave(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Gagal simpan.')));
        return bloc;
      },
      seed: () => BudgetSettingsLoaded(_tSettings),
      act: (b) => b.add(SaveBudgetSettings(_tSettings)),
      expect: () => [
        const BudgetSettingsSaving(),
        const BudgetSettingsError('Gagal simpan.'),
      ],
    );
  });
}
