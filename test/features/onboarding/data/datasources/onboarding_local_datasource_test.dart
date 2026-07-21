import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/onboarding/data/datasources/onboarding_local_datasource.dart';

AppDatabase _openTestDb() => AppDatabase(NativeDatabase.memory());

// Seed baris appSettings completed=true + income (pengganti saveBudgetSettings
// yang sudah dihapus dari OnboardingLocalDataSource — #247).
Future<void> seedCompletedBudget(AppDatabase db, {int income = 3000000}) async {
  await db
      .into(db.appSettings)
      .insertOnConflictUpdate(
        AppSettingsCompanion(
          id: const Value(1),
          onboardingCompleted: const Value(true),
          monthlyIncome: Value(income),
          paymentDate: const Value(25),
          rentExpense: const Value(1000000),
          utilitiesExpense: const Value(150000),
          internetExpense: const Value(100000),
          phoneExpense: const Value(50000),
          otherFixedExpense: const Value(25000),
          emergencyFundPct: const Value(0.10),
          onboardingCreatedAt: Value(DateTime(2026, 5, 8)),
        ),
      );
}

void main() {
  late AppDatabase db;
  late OnboardingLocalDataSourceImpl datasource;

  setUp(() {
    db = _openTestDb();
    datasource = OnboardingLocalDataSourceImpl(db);
  });

  tearDown(() => db.close());

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
      await seedCompletedBudget(db);

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

  group('savePartialOnboarding + loadPartialOnboarding', () {
    test('load returns null sebelum ada partial state', () async {
      final result = await datasource.loadPartialOnboarding();
      expect(result, isNull);
    });

    test('save lalu load → state ter-restore', () async {
      await datasource.savePartialOnboarding(
        step: 1,
        income: 3000000,
        expenses: {
          'kos': 1000000,
          'listrik': 150000,
          'internet': 100000,
          'pulsa': 50000,
          'lain': 0,
        },
        pct: 10,
        payday: 25,
      );

      final result = await datasource.loadPartialOnboarding();
      expect(result, isNotNull);
      expect(result!.step, 1);
      expect(result.income, 3000000);
      expect(result.expenses['kos'], 1000000);
      expect(result.pct, 10);
      expect(result.payday, 25);
    });

    test('savedAt timestamp terisi', () async {
      final before = DateTime.now();
      await datasource.savePartialOnboarding(
        step: 0,
        income: 1000000,
        expenses: {
          'kos': 0,
          'listrik': 0,
          'internet': 0,
          'pulsa': 0,
          'lain': 0,
        },
        pct: 0,
        payday: 1,
      );
      final after = DateTime.now();
      final result = await datasource.loadPartialOnboarding();
      expect(
        result!.savedAt.isAfter(before.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(
        result.savedAt.isBefore(after.add(const Duration(seconds: 1))),
        true,
      );
    });

    test(
      'save memetakan expenses map → 5 kolom DB + fixedExpenses sum',
      () async {
        await datasource.savePartialOnboarding(
          step: 2,
          income: 4000000,
          expenses: {
            'kos': 1000000,
            'listrik': 150000,
            'internet': 100000,
            'pulsa': 50000,
            'lain': 25000,
          },
          pct: 10,
          payday: 1,
        );

        final row = await (db.select(
          db.appSettings,
        )..where((t) => t.id.equals(1))).getSingleOrNull();

        expect(row!.rentExpense, 1000000); // kos
        expect(row.utilitiesExpense, 150000); // listrik
        expect(row.internetExpense, 100000); // internet
        expect(row.phoneExpense, 50000); // pulsa
        expect(row.otherFixedExpense, 25000); // lain
        expect(row.fixedExpenses, 1325000); // sum semua
      },
    );
  });

  group('clearPartialOnboarding', () {
    test('setelah clear, load returns null', () async {
      await datasource.savePartialOnboarding(
        step: 2,
        income: 2000000,
        expenses: {
          'kos': 0,
          'listrik': 0,
          'internet': 0,
          'pulsa': 0,
          'lain': 0,
        },
        pct: 20,
        payday: 1,
      );

      await datasource.clearPartialOnboarding();

      final result = await datasource.loadPartialOnboarding();
      expect(result, isNull);
    });

    test('clear HANYA null-kan kolom partial — data budget tetap utuh', () async {
      // Mulai dari state "selesai" (completed=true + income) lalu simpan partial.
      await seedCompletedBudget(db);
      await datasource.savePartialOnboarding(
        step: 1,
        income: 3000000,
        expenses: {
          'kos': 1000000,
          'listrik': 150000,
          'internet': 100000,
          'pulsa': 50000,
          'lain': 25000,
        },
        pct: 10,
        payday: 25,
      );

      await datasource.clearPartialOnboarding();

      final row = await (db.select(
        db.appSettings,
      )..where((t) => t.id.equals(1))).getSingleOrNull();

      expect(row, isNotNull);
      // Invariant: kolom partial NULL...
      expect(row!.partialOnboardingStep, isNull);
      expect(row.partialOnboardingAt, isNull);
      // ...tapi SELURUH data budget tetap utuh (tak terhapus oleh clear).
      expect(row.monthlyIncome, 3000000);
      expect(row.rentExpense, 1000000);
      expect(row.utilitiesExpense, 150000);
      expect(row.internetExpense, 100000);
      expect(row.phoneExpense, 50000);
      expect(row.otherFixedExpense, 25000);
      expect(row.emergencyFundPct, 0.10);
      expect(row.paymentDate, 25);
      expect(row.onboardingCompleted, true);
    });
  });

  group('isOnboardingCompleted — income gating (#251)', () {
    test('income > 0 + completed → true', () async {
      await seedCompletedBudget(db);
      expect(await datasource.isOnboardingCompleted(), true);
    });

    test('income = 0 walau completed=true → false (cegah jebakan)', () async {
      await seedCompletedBudget(db, income: 0);
      expect(await datasource.isOnboardingCompleted(), false);
    });
  });

  group('loadPartialOnboarding — integrity guard (#235/#233)', () {
    const tExp = {
      'kos': 1000000,
      'listrik': 0,
      'internet': 0,
      'pulsa': 0,
      'lain': 0,
    };

    test(
      'step non-null tapi partialOnboardingAt null → return null (no crash)',
      () async {
        await datasource.savePartialOnboarding(
          step: 1,
          income: 3000000,
          expenses: tExp,
          pct: 10,
          payday: 25,
        );
        // Buat state inkonsisten: at = null, step tetap terisi.
        await (db.update(db.appSettings)..where((t) => t.id.equals(1))).write(
          const AppSettingsCompanion(partialOnboardingAt: Value(null)),
        );

        expect(await datasource.loadPartialOnboarding(), isNull);
      },
    );

    test(
      'step di luar 0..2 → return null (tidak restore step invalid)',
      () async {
        await datasource.savePartialOnboarding(
          step: 5,
          income: 3000000,
          expenses: tExp,
          pct: 10,
          payday: 25,
        );

        expect(await datasource.loadPartialOnboarding(), isNull);
      },
    );
  });
}
