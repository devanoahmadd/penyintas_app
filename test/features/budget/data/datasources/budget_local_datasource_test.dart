import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/budget/data/datasources/budget_local_datasource.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';

void main() {
  late AppDatabase db;
  late BudgetLocalDatasourceImpl datasource;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    datasource = BudgetLocalDatasourceImpl(db);
  });
  tearDown(() => db.close());

  group('saveBudgetSettings round-trip guard (#247-C)', () {
    test(
      'semua field non-default round-trip lewat getBudgetSettings',
      () async {
        // Setiap kolom budget diberi nilai DISTINCT & non-zero agar field yang
        // hilang dari mapping langsung terdeteksi.
        final settings = BudgetSettingsEntity(
          monthlyIncome: 7654321,
          paymentDate: 17,
          emergencyFundPct: 0.23,
          createdAt: DateTime(2026, 3, 14),
          rentExpense: 1111111,
          utilitiesExpense: 222222,
          internetExpense: 333333,
          phoneExpense: 44444,
          otherFixedExpense: 555555,
        );

        await datasource.saveBudgetSettings(settings);
        final result = await datasource.getBudgetSettings();

        expect(result, isNotNull);
        expect(result!.monthlyIncome, 7654321);
        expect(result.paymentDate, 17);
        expect(result.emergencyFundPct, 0.23);
        expect(result.createdAt, DateTime(2026, 3, 14));
        expect(result.rentExpense, 1111111);
        expect(result.utilitiesExpense, 222222);
        expect(result.internetExpense, 333333);
        expect(result.phoneExpense, 44444);
        expect(result.otherFixedExpense, 555555);
        // fixedExpenses computed = sum breakdown
        expect(
          result.fixedExpenses,
          1111111 + 222222 + 333333 + 44444 + 555555,
        );
      },
    );

    test('onboardingCreatedAt set-once — save kedua tak overwrite', () async {
      final first = BudgetSettingsEntity(
        monthlyIncome: 1000000,
        paymentDate: 1,
        emergencyFundPct: 0.10,
        createdAt: DateTime(2026, 1, 1),
        otherFixedExpense: 100000,
      );
      await datasource.saveBudgetSettings(first);

      final second = BudgetSettingsEntity(
        monthlyIncome: 2000000,
        paymentDate: 5,
        emergencyFundPct: 0.15,
        createdAt: DateTime(2026, 6, 1),
        otherFixedExpense: 200000,
      );
      await datasource.saveBudgetSettings(second);

      final result = await datasource.getBudgetSettings();
      expect(result!.createdAt, DateTime(2026, 1, 1)); // dari save pertama
      expect(result.monthlyIncome, 2000000); // budget terupdate
    });
  });

  group('getBudgetSettings partial-onboarding guard', () {
    test('partial state (onboardingCompleted=false, income>0) → null', () async {
      // Simulasi user yang masuk step-2 onboarding (income diisi via
      // savePartialOnboarding) tapi belum submit → onboardingCompleted masih false.
      // syncBudgetFromRemote TIDAK boleh short-circuit di state ini.
      await db
          .into(db.appSettings)
          .insertOnConflictUpdate(
            AppSettingsCompanion(
              id: const Value(1),
              onboardingCompleted: const Value(false),
              monthlyIncome: const Value(3000000),
            ),
          );

      final result = await datasource.getBudgetSettings();

      expect(result, isNull);
    });

    test('state valid (onboardingCompleted=true, income>0) → data', () async {
      final settings = BudgetSettingsEntity(
        monthlyIncome: 5000000,
        paymentDate: 25,
        emergencyFundPct: 0.10,
        createdAt: DateTime(2026, 1, 1),
      );
      await datasource.saveBudgetSettings(
        settings,
      ); // sets onboardingCompleted=true

      final result = await datasource.getBudgetSettings();

      expect(result, isNotNull);
      expect(result!.monthlyIncome, 5000000);
    });
  });
}
