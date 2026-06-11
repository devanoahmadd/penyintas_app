import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/network/network_info.dart';
import 'package:penyintas_app/features/budget/data/datasources/budget_local_datasource.dart';
import 'package:penyintas_app/features/budget/data/datasources/budget_remote_datasource.dart';
import 'package:penyintas_app/features/budget/data/models/budget_settings_model.dart';
import 'package:penyintas_app/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';

class MockBudgetLocalDatasource extends Mock implements BudgetLocalDatasource {}

class MockBudgetRemoteDatasource extends Mock implements BudgetRemoteDatasource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class FakeBudgetSettingsEntity extends Fake implements BudgetSettingsEntity {}

void main() {
  setUpAll(() => registerFallbackValue(FakeBudgetSettingsEntity()));

  late BudgetRepositoryImpl repository;
  late MockBudgetLocalDatasource local;
  late MockBudgetRemoteDatasource remote;
  late MockNetworkInfo network;

  final tEntity = BudgetSettingsEntity(
    monthlyIncome: 3000000,
    paymentDate: 25,
    otherFixedExpense: 800000,
    emergencyFundPct: 0.10,
    createdAt: DateTime(2026, 5, 8),
  );
  final tModel = BudgetSettingsModel(
    monthlyIncome: 3000000,
    paymentDate: 25,
    otherFixedExpense: 800000,
    emergencyFundPct: 0.10,
    createdAt: DateTime(2026, 5, 8),
  );

  setUp(() {
    local = MockBudgetLocalDatasource();
    remote = MockBudgetRemoteDatasource();
    network = MockNetworkInfo();
    repository = BudgetRepositoryImpl(
      local: local,
      remote: remote,
      networkInfo: network,
    );
  });

  group('syncBudgetFromRemote', () {
    test('local hit — returns local, tidak panggil remote', () async {
      when(() => local.getBudgetSettings()).thenAnswer((_) async => tEntity);

      final result = await repository.syncBudgetFromRemote();

      expect(result, Right<dynamic, BudgetSettingsEntity?>(tEntity));
      verifyNever(() => remote.getBudgetSettings());
    });

    test('local miss + online + remote ada — cache lokal lalu return remote',
        () async {
      when(() => local.getBudgetSettings()).thenAnswer((_) async => null);
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.getBudgetSettings()).thenAnswer((_) async => tModel);
      when(() => local.saveBudgetSettings(any())).thenAnswer((_) async {});

      final result = await repository.syncBudgetFromRemote();

      expect(result, Right<dynamic, BudgetSettingsEntity?>(tModel));
      verify(() => local.saveBudgetSettings(tModel)).called(1);
    });

    test('local miss + offline — return Right(null), tak sentuh remote',
        () async {
      when(() => local.getBudgetSettings()).thenAnswer((_) async => null);
      when(() => network.isConnected).thenAnswer((_) async => false);

      final result = await repository.syncBudgetFromRemote();

      expect(result, const Right<dynamic, BudgetSettingsEntity?>(null));
      verifyNever(() => remote.getBudgetSettings());
    });
  });
}
