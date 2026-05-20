import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/onboarding/data/datasources/onboarding_local_datasource.dart';
import 'package:penyintas_app/features/onboarding/domain/entities/budget_settings_entity.dart';

AppDatabase _openTestDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late OnboardingLocalDataSourceImpl datasource;

  final tSettings = BudgetSettingsEntity(
    monthlyIncome: 3000000,
    paymentDate: 25,
    otherFixedExpense: 800000,
    emergencyFundPct: 0.10,
    createdAt: DateTime(2026, 5, 8),
  );

  setUp(() {
    db = _openTestDb();
    datasource = OnboardingLocalDataSourceImpl(db);
  });

  tearDown(() => db.close());

  group('saveBudgetSettings', () {
    test('persists all fields dan sets onboardingCompleted = true', () async {
      await datasource.saveBudgetSettings(tSettings);

      final saved =
          await (db.select(db.appSettings)..where((t) => t.id.equals(1)))
              .getSingleOrNull();

      expect(saved, isNotNull);
      expect(saved!.monthlyIncome, 3000000);
      expect(saved.paymentDate, 25);
      expect(saved.fixedExpenses, 800000);
      expect(saved.emergencyFundPct, 0.10);
      expect(saved.onboardingCompleted, true);
      expect(saved.onboardingCreatedAt, DateTime(2026, 5, 8));
    });

    test('tidak overwrite onboardingCreatedAt jika sudah ada', () async {
      final originalDate = DateTime(2026, 1, 1);
      final firstSettings = BudgetSettingsEntity(
        monthlyIncome: 2000000,
        paymentDate: 1,
        otherFixedExpense: 500000,
        emergencyFundPct: 0.10,
        createdAt: originalDate,
      );
      await datasource.saveBudgetSettings(firstSettings);

      // Save kedua dengan tanggal berbeda
      final secondSettings = BudgetSettingsEntity(
        monthlyIncome: 3000000,
        paymentDate: 25,
        otherFixedExpense: 800000,
        emergencyFundPct: 0.15,
        createdAt: DateTime(2026, 5, 8),
      );
      await datasource.saveBudgetSettings(secondSettings);

      final saved =
          await (db.select(db.appSettings)..where((t) => t.id.equals(1)))
              .getSingleOrNull();

      // onboardingCreatedAt tetap dari save pertama
      expect(saved!.onboardingCreatedAt, originalDate);
      // Data budget diupdate ke save kedua
      expect(saved.monthlyIncome, 3000000);
    });

    test('mempertahankan locale dan themeMode yang sudah ada', () async {
      // Set locale & theme terlebih dahulu
      await db.into(db.appSettings).insert(AppSettingsCompanion.insert(
            id: const Value(1),
            locale: const Value('en'),
            themeMode: const Value('dark'),
          ));

      await datasource.saveBudgetSettings(tSettings);

      final saved =
          await (db.select(db.appSettings)..where((t) => t.id.equals(1)))
              .getSingleOrNull();

      expect(saved!.locale, 'en');
      expect(saved.themeMode, 'dark');
    });
  });

  group('getBudgetSettings', () {
    test('returns null jika belum ada data', () async {
      final result = await datasource.getBudgetSettings();
      expect(result, isNull);
    });

    test('returns null jika monthlyIncome == 0', () async {
      await datasource.saveBudgetSettings(BudgetSettingsEntity(
        monthlyIncome: 0,
        paymentDate: 1,
        otherFixedExpense: 0,
        emergencyFundPct: 0.10,
        createdAt: DateTime(2026, 5, 8),
      ));

      final result = await datasource.getBudgetSettings();
      expect(result, isNull);
    });

    test('returns entity dengan data yang benar setelah save', () async {
      await datasource.saveBudgetSettings(tSettings);

      final result = await datasource.getBudgetSettings();

      expect(result, isNotNull);
      expect(result!.monthlyIncome, 3000000);
      expect(result.paymentDate, 25);
      expect(result.fixedExpenses, 800000);
      expect(result.emergencyFundPct, 0.10);
      expect(result.createdAt, DateTime(2026, 5, 8));
    });
  });

  group('addToSyncQueue', () {
    test('inserts create op jika onboarding belum selesai', () async {
      // Belum ada row di appSettings → onboardingCompleted default false
      await datasource.addToSyncQueue(
        itemId: 'user-1',
        collectionPath: 'users/user-1/settings',
        data: {'income': 3000000},
      );

      final items = await db.select(db.syncQueue).get();
      expect(items.length, 1);
      expect(items.first.operation, SyncOperation.create);
      expect(items.first.itemId, 'user-1');
    });

    test('inserts update op jika onboarding sudah selesai', () async {
      await datasource.saveBudgetSettings(tSettings);

      await datasource.addToSyncQueue(
        itemId: 'user-1',
        collectionPath: 'users/user-1/settings',
        data: {'income': 4000000},
      );

      final items = await db.select(db.syncQueue).get();
      expect(items.length, 1);
      expect(items.first.operation, SyncOperation.update);
    });
  });
}
