import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/domain/repositories/bill_repository.dart';
import 'package:penyintas_app/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/dashboard/domain/usecases/calculate_days_to_live_usecase.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/budget/domain/repositories/budget_repository.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/transaction_repository.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockBillRepository extends Mock implements BillRepository {}

void main() {
  late MockTransactionRepository mockTxRepo;
  late MockBudgetRepository mockBudget;
  late MockBillRepository mockBills;
  late DashboardRepositoryImpl repo;

  // Settings: income 3_000_000, fixed 500_000, emergency 10% → safeMonthly = 2_200_000
  final settings = BudgetSettingsEntity(
    monthlyIncome: 3000000,
    paymentDate: 1,
    otherFixedExpense: 500000,
    emergencyFundPct: 0.10,
    createdAt: DateTime(2026, 5, 1),
  );

  TransactionEntity makeTxn({
    String id = 'id',
    required int amount,
    required String category,
    TransactionType type = TransactionType.expense,
    DateTime? date,
    bool isFixed = false,
  }) {
    final d = date ?? DateTime.now();
    return TransactionEntity(
      id: id,
      amount: amount,
      category: category,
      type: type,
      date: d,
      isFixed: isFixed,
      isSynced: false,
      createdAt: d,
      updatedAt: d,
    );
  }

  // Jatuh tempo default = HARI INI. Dengan paymentDate = 1, hari ini selalu
  // lebih awal dari gajian berikutnya (tanggal 1 bulan depan), jadi bill-nya
  // pasti "terikat" di hari apa pun test dijalankan. "Besok" polos pecah di
  // akhir bulan: 31 Juli + 1 hari = 1 Agustus = TEPAT hari gajian, dan
  // horizon calculateTiedMoney memakai `<` (bill di hari gajian tidak terikat).
  BillEntity makeBill({
    int id = 1,
    required int amount,
    required bool isFixedNeed,
    DateTime? dueDate,
  }) => BillEntity(
    id: id,
    name: 'Bill $id',
    estimatedAmount: amount,
    category: 'fixed',
    isFixedNeed: isFixedNeed,
    dueDate: dueDate ?? DateTime.now(),
    recurrence: Recurrence.monthly,
    installmentsPaid: 0,
    reminderEnabled: false,
    status: BillStatus.active,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  setUp(() {
    mockTxRepo = MockTransactionRepository();
    mockBudget = MockBudgetRepository();
    mockBills = MockBillRepository();
    repo = DashboardRepositoryImpl(
      transactionRepository: mockTxRepo,
      budgetRepository: mockBudget,
      billRepository: mockBills,
      calculateDtl: const CalculateDaysToLiveUseCase(),
    );

    when(
      () => mockBills.watchActiveBills(),
    ).thenAnswer((_) => Stream.value(const Right(<BillEntity>[])));
    when(
      () => mockBudget.getBudgetSettings(),
    ).thenAnswer((_) async => Right(settings));
    when(
      () => mockTxRepo.getTransactions(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => const Right([]));
  });

  group('_compute — totalSpentThisMonth', () {
    test('bill txn (category fixed, isFixed=false) MASUK totalSpentThisMonth '
        '(P1 §4.1 — menggantikan fix #25)', () async {
      // Transaksi hasil bayar tagihan dgn includeAsFixed=false (jalur M1):
      final billTxn = makeTxn(id: 'f1', amount: 400000, category: 'fixed');
      final foodTxn = makeTxn(id: 'f2', amount: 50000, category: 'food');

      when(
        () => mockTxRepo.watchTodayTransactions(),
      ).thenAnswer((_) => Stream.value(const Right([])));
      when(
        () => mockTxRepo.getTransactions(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => Right([billTxn, foodTxn]));

      final result = await repo.watchDashboard().first;
      final entity = result.getOrElse(() => throw StateError('Left'));

      // 400rb + 50rb dua-duanya masuk — kategori tak lagi jadi proxy.
      expect(entity.totalSpentThisMonth, 450000);
      expect(entity.totalRemaining, 2200000 - 450000);
    });

    test(
      'transaksi manual kategori fixed (isFixed=true) TETAP dikecualikan',
      () async {
        final manualFixed = makeTxn(
          id: 'm1',
          amount: 300000,
          category: 'fixed',
          isFixed: true,
        );
        when(
          () => mockTxRepo.watchTodayTransactions(),
        ).thenAnswer((_) => Stream.value(const Right([])));
        when(
          () => mockTxRepo.getTransactions(
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenAnswer((_) async => Right([manualFixed]));

        final result = await repo.watchDashboard().first;
        final entity = result.getOrElse(() => throw StateError('Left'));
        expect(entity.totalSpentThisMonth, 0);
      },
    );

    test(
      'income-type transactions do not affect totalSpentThisMonth',
      () async {
        final incomeTxn = makeTxn(
          id: 'i1',
          amount: 500000,
          category: 'income',
          type: TransactionType.income,
        );
        final foodTxn = makeTxn(id: 'f1', amount: 30000, category: 'food');

        when(
          () => mockTxRepo.watchTodayTransactions(),
        ).thenAnswer((_) => Stream.value(const Right([])));
        when(
          () => mockTxRepo.getTransactions(
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenAnswer((_) async => Right([incomeTxn, foodTxn]));

        final result = await repo.watchDashboard().first;
        final entity = result.getOrElse(() => throw Exception());
        expect(entity.totalSpentThisMonth, 30000);
      },
    );
  });

  group('_compute — totalRemaining', () {
    test('clamps totalRemaining to 0 when over budget', () async {
      // safeMonthlyBudget = 2_200_000; spend 3_000_000 → remaining should be 0
      final bigSpend = makeTxn(id: 'b1', amount: 3000000, category: 'food');

      when(
        () => mockTxRepo.watchTodayTransactions(),
      ).thenAnswer((_) => Stream.value(const Right([])));
      when(
        () => mockTxRepo.getTransactions(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => Right([bigSpend]));

      final result = await repo.watchDashboard().first;
      final entity = result.getOrElse(() => throw Exception());
      expect(
        entity.totalRemaining,
        0,
        reason: 'totalRemaining must not go negative in entity',
      );
    });
  });

  group('_compute — negative safeMonthlyBudget', () {
    test(
      'clamps safeMonthlyBudget to 0 when fixedExpenses exceed income',
      () async {
        final overSettings = BudgetSettingsEntity(
          monthlyIncome: 500000,
          paymentDate: 1,
          otherFixedExpense: 600000,
          emergencyFundPct: 0.10,
          createdAt: DateTime(2026, 5, 1),
        );
        when(
          () => mockBudget.getBudgetSettings(),
        ).thenAnswer((_) async => Right(overSettings));
        when(
          () => mockTxRepo.watchTodayTransactions(),
        ).thenAnswer((_) => Stream.value(const Right([])));

        final result = await repo.watchDashboard().first;
        final entity = result.getOrElse(() => throw Exception());
        expect(entity.totalMonthlyBudget, 0);
        expect(entity.dailyBudget, 0);
      },
    );
  });

  group('_compute — spentToday', () {
    test('sums only expense-type today transactions', () async {
      final expense = makeTxn(id: 'e1', amount: 25000, category: 'food');
      final income = makeTxn(
        id: 'i1',
        amount: 100000,
        category: 'income',
        type: TransactionType.income,
      );

      when(
        () => mockTxRepo.watchTodayTransactions(),
      ).thenAnswer((_) => Stream.value(Right([expense, income])));

      final result = await repo.watchDashboard().first;
      final entity = result.getOrElse(() => throw Exception());
      expect(entity.spentToday, 25000);
    });

    test('todayTransactions list is passed through to entity', () async {
      final txn = makeTxn(id: 'x1', amount: 15000, category: 'food');

      when(
        () => mockTxRepo.watchTodayTransactions(),
      ).thenAnswer((_) => Stream.value(Right([txn])));

      final result = await repo.watchDashboard().first;
      final entity = result.getOrElse(() => throw Exception());
      expect(entity.todayTransactions, [txn]);
    });
  });

  group('_compute — avgDailySpend', () {
    test('uses last-7-days sum divided by 7', () async {
      final txns = List.generate(
        7,
        (i) => makeTxn(
          id: 'w$i',
          amount: 70000,
          category: 'food',
          date: DateTime.now().subtract(Duration(days: i)),
        ),
      );

      when(
        () => mockTxRepo.watchTodayTransactions(),
      ).thenAnswer((_) => Stream.value(const Right([])));
      when(
        () => mockTxRepo.getTransactions(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => Right(txns));

      final result = await repo.watchDashboard().first;
      final entity = result.getOrElse(() => throw Exception());
      expect(entity.avgDailySpend, 70000.0);
    });

    test('falls back to dailyBudget when no last-7-day transactions', () async {
      when(
        () => mockTxRepo.watchTodayTransactions(),
      ).thenAnswer((_) => Stream.value(const Right([])));
      // getTransactions returns [] by default from setUp

      final result = await repo.watchDashboard().first;
      final entity = result.getOrElse(() => throw Exception());
      expect(entity.avgDailySpend, entity.dailyBudget.toDouble());
    });
  });

  group('_compute — BudgetStatus', () {
    test('status is safe when remaining > 30% of budget', () async {
      // No spending → remaining = safeMonthlyBudget = 2_200_000 → 100% → safe
      when(
        () => mockTxRepo.watchTodayTransactions(),
      ).thenAnswer((_) => Stream.value(const Right([])));

      final result = await repo.watchDashboard().first;
      final entity = result.getOrElse(() => throw Exception());
      expect(entity.status, BudgetStatus.safe);
    });

    test('status is caution when remaining 15–30% of budget', () async {
      // safeMonthly = 2_200_000; spend 1_595_001 → remaining = 604_999 ≈ 27.5% → caution
      final spend = makeTxn(id: 'c1', amount: 1595001, category: 'food');
      when(
        () => mockTxRepo.watchTodayTransactions(),
      ).thenAnswer((_) => Stream.value(const Right([])));
      when(
        () => mockTxRepo.getTransactions(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => Right([spend]));

      final result = await repo.watchDashboard().first;
      final entity = result.getOrElse(() => throw Exception());
      expect(entity.status, BudgetStatus.caution);
    });

    test('status is danger when remaining < 15% of budget', () async {
      // safeMonthly = 2_200_000; spend 1_871_001 → remaining = 328_999 ≈ 14.9% → danger
      final spend = makeTxn(id: 'd1', amount: 1871001, category: 'food');
      when(
        () => mockTxRepo.watchTodayTransactions(),
      ).thenAnswer((_) => Stream.value(const Right([])));
      when(
        () => mockTxRepo.getTransactions(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => Right([spend]));

      final result = await repo.watchDashboard().first;
      final entity = result.getOrElse(() => throw Exception());
      expect(entity.status, BudgetStatus.danger);
    });
  });

  group('_compute — kecualikan transaksi isFixed (tagihan) — spec §7', () {
    // Tagihan sudah diwakili settings.fixedExpenses (500.000) di formula
    // budget. Kalau transaksinya ikut dihitung di akumulator pengeluaran →
    // double-count: burn-rate melonjak → Days-to-Live jatuh drastis.
    test(
      'burn-rate: tagihan tidak masuk penyebut avgDailySpend & DTL tidak jatuh',
      () async {
        // 6 transaksi operasional kecil (total 120.000) + 1 tagihan besar.
        final operational = List.generate(
          6,
          (i) => makeTxn(
            id: 'op$i',
            amount: 20000,
            category: 'food',
            date: DateTime.now().subtract(Duration(days: i)),
          ),
        );
        final bill = makeTxn(
          id: 'bill1',
          amount: 1500000,
          category: 'fixed',
          isFixed: true,
          date: DateTime.now().subtract(const Duration(days: 2)),
        );

        when(
          () => mockTxRepo.watchTodayTransactions(),
        ).thenAnswer((_) => Stream.value(const Right([])));
        when(
          () => mockTxRepo.getTransactions(
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenAnswer((_) async => Right([...operational, bill]));

        final result = await repo.watchDashboard().first;
        final entity = result.getOrElse(() => throw Exception());

        // Hanya 120.000 operasional yang jadi penyebut burn-rate.
        expect(
          entity.avgDailySpend,
          closeTo(120000 / 7, 0.0001),
          reason:
              'tagihan isFixed tidak boleh masuk penyebut burn-rate; '
              'kalau ikut → (120.000 + 1.500.000) / 7 = 231.428,57',
        );

        // safeMonthlyBudget = 2.200.000; totalSpentThisMonth = 120.000 →
        // totalRemaining = 2.080.000. DTL = floor(2.080.000 / 17.142,857) = 121.
        expect(
          entity.totalSpentThisMonth,
          120000,
          reason: 'tagihan tidak masuk pengeluaran bulan ini',
        );
        expect(
          entity.daysToLive,
          121,
          reason:
              'DTL tidak boleh jatuh; kalau tagihan ikut burn-rate DTL anjlok '
              'ke floor(2.080.000 / 231.428,57) = 8',
        );
      },
    );

    test('decoupling: isFixed=true dgn category non-"fixed" tetap dikecualikan '
        'dari ketiga akumulator', () async {
      final operational = makeTxn(id: 'op1', amount: 20000, category: 'food');
      // Tagihan internet — category BUKAN 'fixed', jadi hanya filter
      // !t.isFixed yang bisa mengecualikannya.
      final bill = makeTxn(
        id: 'bill-internet',
        amount: 900000,
        category: 'internet',
        isFixed: true,
      );

      when(
        () => mockTxRepo.watchTodayTransactions(),
      ).thenAnswer((_) => Stream.value(Right([operational, bill])));
      when(
        () => mockTxRepo.getTransactions(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => Right([operational, bill]));

      final result = await repo.watchDashboard().first;
      final entity = result.getOrElse(() => throw Exception());

      expect(
        entity.spentToday,
        20000,
        reason: 'filter harus memakai isFixed, bukan category == "fixed"',
      );
      expect(entity.totalSpentThisMonth, 20000);
      expect(entity.avgDailySpend, closeTo(20000 / 7, 0.0001));
    });

    test('spentToday mengecualikan transaksi tagihan', () async {
      final operational = makeTxn(id: 'op1', amount: 50000, category: 'food');
      final bill = makeTxn(
        id: 'bill1',
        amount: 800000,
        category: 'fixed',
        isFixed: true,
      );

      when(
        () => mockTxRepo.watchTodayTransactions(),
      ).thenAnswer((_) => Stream.value(Right([operational, bill])));

      final result = await repo.watchDashboard().first;
      final entity = result.getOrElse(() => throw Exception());

      expect(entity.spentToday, 50000);
      expect(
        entity.remainingToday,
        entity.dailyBudget - 50000,
        reason: 'bar "sisa hari ini" tidak boleh tergerus tagihan',
      );
    });

    test('totalSpentThisMonth mengecualikan transaksi tagihan', () async {
      final operational = makeTxn(id: 'op1', amount: 100000, category: 'food');
      final bill = makeTxn(
        id: 'bill-internet',
        amount: 900000,
        category: 'internet',
        isFixed: true,
      );

      when(
        () => mockTxRepo.watchTodayTransactions(),
      ).thenAnswer((_) => Stream.value(const Right([])));
      when(
        () => mockTxRepo.getTransactions(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => Right([operational, bill]));

      final result = await repo.watchDashboard().first;
      final entity = result.getOrElse(() => throw Exception());

      expect(entity.totalSpentThisMonth, 100000);
    });

    test('riwayat 7 hari yang hanya berisi tagihan → fallback konservatif '
        'dailyBudget (bukan 0.0)', () async {
      final bill = makeTxn(
        id: 'bill1',
        amount: 1200000,
        category: 'fixed',
        isFixed: true,
      );

      when(
        () => mockTxRepo.watchTodayTransactions(),
      ).thenAnswer((_) => Stream.value(const Right([])));
      when(
        () => mockTxRepo.getTransactions(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => Right([bill]));

      final result = await repo.watchDashboard().first;
      final entity = result.getOrElse(() => throw Exception());

      expect(
        entity.avgDailySpend,
        entity.dailyBudget.toDouble(),
        reason:
            'tak ada sinyal belanja operasional → fallback dailyBudget, '
            'bukan 0.0 yang bikin DTL optimistis penuh',
      );
      expect(entity.avgDailySpend, greaterThan(0));
    });
  });

  group('watchDashboard — error handling', () {
    test('yields CacheFailure when settings fetch fails', () async {
      when(() => mockBudget.getBudgetSettings()).thenAnswer(
        (_) async =>
            const Left(CacheFailure('Pengaturan anggaran tidak ditemukan.')),
      );
      when(
        () => mockTxRepo.watchTodayTransactions(),
      ).thenAnswer((_) => Stream.value(const Right([])));

      final result = await repo.watchDashboard().first;
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('BillCommitments di dashboard (P1 §5)', () {
    test('bill non-tetap due sebelum gajian → tiedFlexible terisi & '
        'safeRemaining turun', () async {
      when(() => mockBills.watchActiveBills()).thenAnswer(
        (_) =>
            Stream.value(Right([makeBill(amount: 200000, isFixedNeed: false)])),
      );
      when(
        () => mockTxRepo.watchTodayTransactions(),
      ).thenAnswer((_) => Stream.value(const Right([])));

      final entity = (await repo.watchDashboard().firstWhere(
        (e) => e.fold((_) => false, (r) => r.billCommitments.tiedTotal > 0),
      )).getOrElse(() => throw StateError('Left'));
      expect(entity.billCommitments.tiedFlexible, 200000);
      expect(entity.billCommitments.safeRemaining, 2200000 - 200000);
    });

    test('B2 pra-clamp: anggaran jebol → entity.totalRemaining=0 TAPI '
        'safeRemaining dihitung dari nilai MENTAH', () async {
      // spent 2.5jt > safeMonthly 2.2jt → mentah = -300rb.
      final overspend = makeTxn(id: 'o1', amount: 2500000, category: 'food');
      when(
        () => mockTxRepo.watchTodayTransactions(),
      ).thenAnswer((_) => Stream.value(const Right([])));
      when(
        () => mockTxRepo.getTransactions(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => Right([overspend]));
      when(() => mockBills.watchActiveBills()).thenAnswer(
        (_) =>
            Stream.value(Right([makeBill(amount: 100000, isFixedNeed: false)])),
      );

      final entity = (await repo.watchDashboard().firstWhere(
        (e) => e.fold((_) => false, (r) => r.billCommitments.tiedTotal > 0),
      )).getOrElse(() => throw StateError('Left'));
      expect(entity.totalRemaining, 0); // clamp UI tetap
      expect(entity.billCommitments.safeRemaining, -400000); // -300rb - 100rb
    });

    test('§5.1: event bills BARU memicu recompute (emisi tambahan)', () async {
      final billsCtrl =
          StreamController<Either<Failure, List<BillEntity>>>.broadcast();
      when(
        () => mockBills.watchActiveBills(),
      ).thenAnswer((_) => billsCtrl.stream);
      when(
        () => mockTxRepo.watchTodayTransactions(),
      ).thenAnswer((_) => Stream.value(const Right([])));

      final emissions = <int>[];
      final sub = repo.watchDashboard().listen(
        (e) =>
            e.fold((_) {}, (r) => emissions.add(r.billCommitments.tiedTotal)),
      );

      await pumpEventQueue();
      billsCtrl.add(Right([makeBill(amount: 150000, isFixedNeed: false)]));
      await pumpEventQueue();

      expect(emissions, [0, 150000]); // tx-event dulu, lalu recompute krn bills
      await sub.cancel();
      await billsCtrl.close();
    });

    test(
      '§5.1 recompute SERIAL: hasil lambat-basi TIDAK menimpa hasil baru',
      () async {
        final txCtrl =
            StreamController<
              Either<Failure, List<TransactionEntity>>
            >.broadcast();
        final billsCtrl =
            StreamController<Either<Failure, List<BillEntity>>>.broadcast();
        when(
          () => mockTxRepo.watchTodayTransactions(),
        ).thenAnswer((_) => txCtrl.stream);
        when(
          () => mockBills.watchActiveBills(),
        ).thenAnswer((_) => billsCtrl.stream);

        // Recompute #1 (2 query pertama) DITAHAN dan kelak mengembalikan data
        // LAMA (spent 100rb); query berikutnya instan dengan data BARU (200rb).
        // Tanpa serialisasi: #2 selesai duluan (200rb), lalu #1 menimpanya
        // dengan 100rb basi → emisi terakhir salah.
        final tahan = Completer<void>();
        final lama = makeTxn(id: 'lama', amount: 100000, category: 'food');
        final baru = makeTxn(id: 'baru', amount: 200000, category: 'food');
        var panggilan = 0;
        when(
          () => mockTxRepo.getTransactions(
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenAnswer((_) async {
          panggilan++;
          if (panggilan <= 2) {
            await tahan.future;
            return Right([lama]);
          }
          return Right([baru]);
        });

        final spentEmisi = <int>[];
        final sub = repo.watchDashboard().listen(
          (e) => e.fold((_) {}, (r) => spentEmisi.add(r.totalSpentThisMonth)),
        );

        txCtrl.add(const Right([])); // memicu recompute #1 (tertahan)
        await pumpEventQueue();
        billsCtrl.add(const Right([])); // event kedua SAAT #1 masih berjalan
        await pumpEventQueue();
        tahan.complete(); // #1 selesai → putaran dirty membaca data baru
        await pumpEventQueue();

        expect(
          spentEmisi.last,
          200000,
        ); // emisi TERAKHIR = data terbaru, bukan basi
        await sub.cancel();
        await txCtrl.close();
        await billsCtrl.close();
      },
    );

    test(
      '§5.1 close: recompute in-flight pasca-cancel TIDAK melempar/menimbun',
      () async {
        final txCtrl =
            StreamController<
              Either<Failure, List<TransactionEntity>>
            >.broadcast();
        when(
          () => mockTxRepo.watchTodayTransactions(),
        ).thenAnswer((_) => txCtrl.stream);
        when(
          () => mockBills.watchActiveBills(),
        ).thenAnswer((_) => Stream.value(const Right(<BillEntity>[])));

        final tahan = Completer<void>();
        when(
          () => mockTxRepo.getTransactions(
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenAnswer((_) async {
          await tahan.future;
          return const Right(<TransactionEntity>[]);
        });

        final sub = repo.watchDashboard().listen((_) {});
        txCtrl.add(const Right([])); // recompute mulai, tertahan di query
        await pumpEventQueue();

        await sub.cancel(); // onCancel: cancel subs + controller.close()
        tahan.complete(); // query selesai SETELAH close
        await pumpEventQueue(); // guard isClosed → tanpa StateError, tanpa buffer

        await txCtrl.close();
      },
    );

    // Paritas perilaku lama: pada `await for`, error event dari stream sumber
    // merambat keluar generator `async*` → DashboardBloc menangkapnya di
    // `onError` → DashboardError. Dengan StreamController manual, `listen()`
    // tanpa `onError` membuang error itu ke zone: stream dashboard tak emit
    // apa-apa, tak error, tak pernah close → BLoC tersangkut DashboardLoading
    // SELAMANYA (spinner abadi, tanpa jalur pulih).
    test('error stream transaksi → dashboard emit Left (bukan hilang '
        'diam-diam ke zone)', () async {
      when(() => mockTxRepo.watchTodayTransactions()).thenAnswer(
        (_) => Stream<Either<Failure, List<TransactionEntity>>>.error(
          Exception('DB tertutup'),
        ),
      );

      final result = await repo.watchDashboard().first;

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<UnknownFailure>()),
        (_) => fail('Error stream sumber WAJIB jadi Left, bukan Right'),
      );
    });

    test('error stream bills → dashboard emit Left (bukan hilang '
        'diam-diam ke zone)', () async {
      when(
        () => mockTxRepo.watchTodayTransactions(),
      ).thenAnswer((_) => Stream.value(const Right([])));
      when(() => mockBills.watchActiveBills()).thenAnswer(
        (_) => Stream<Either<Failure, List<BillEntity>>>.error(
          Exception('DB tertutup'),
        ),
      );

      final result = await repo.watchDashboard().firstWhere((e) => e.isLeft());

      result.fold(
        (f) => expect(f, isA<UnknownFailure>()),
        (_) => fail('Error stream sumber WAJIB jadi Left, bukan Right'),
      );
    });

    test('§5.1 onCancel: KEDUA subscription dibatalkan', () async {
      final txCtrl =
          StreamController<
            Either<Failure, List<TransactionEntity>>
          >.broadcast();
      final billsCtrl =
          StreamController<Either<Failure, List<BillEntity>>>.broadcast();
      when(
        () => mockTxRepo.watchTodayTransactions(),
      ).thenAnswer((_) => txCtrl.stream);
      when(
        () => mockBills.watchActiveBills(),
      ).thenAnswer((_) => billsCtrl.stream);

      final sub = repo.watchDashboard().listen((_) {});
      await pumpEventQueue();
      expect(txCtrl.hasListener, isTrue);
      expect(billsCtrl.hasListener, isTrue);

      await sub.cancel();
      await pumpEventQueue();
      expect(txCtrl.hasListener, isFalse);
      expect(billsCtrl.hasListener, isFalse);

      await txCtrl.close();
      await billsCtrl.close();
    });

    test(
      '§5.2: invalidateSettingsCache MEMICU recompute dgn settings BARU',
      () async {
        final settingsBaru = BudgetSettingsEntity(
          monthlyIncome: 3000000,
          paymentDate: 1,
          otherFixedExpense: 0, // FE 500rb → 0
          emergencyFundPct: 0.10,
          createdAt: DateTime(2026, 5, 1),
        );
        when(
          () => mockTxRepo.watchTodayTransactions(),
        ).thenAnswer((_) => Stream.value(const Right([])));
        when(() => mockBills.watchActiveBills()).thenAnswer(
          (_) => Stream.value(
            Right([makeBill(amount: 500000, isFixedNeed: true)]),
          ),
        );

        final emissions = <int>[];
        final sub = repo.watchDashboard().listen(
          (e) => e.fold(
            (_) {},
            (r) => emissions.add(r.billCommitments.tiedFlexible),
          ),
        );
        await pumpEventQueue();

        // FE 500rb → bill fixed TIDAK flexible; setelah FE=0, M1 → flexible.
        when(
          () => mockBudget.getBudgetSettings(),
        ).thenAnswer((_) async => Right(settingsBaru));
        repo.invalidateSettingsCache();
        await pumpEventQueue();

        expect(emissions.first, 0);
        expect(
          emissions.last,
          500000,
        ); // recompute terpicu + nilai segar terpakai
        await sub.cancel();
      },
    );
  });
}
