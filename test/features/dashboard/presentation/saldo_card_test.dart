import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/bills/domain/usecases/calculate_bill_commitments.dart';
import 'package:penyintas_app/features/bills/presentation/widgets/tied_money_row.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/dashboard/presentation/widgets/saldo_card.dart';

/// M2 — mengunci PEMASANGAN `TiedMoneyRow` di dalam kartu saldo.
///
/// Sebelum test ini, baris pemasangannya bisa dihapus seluruhnya, atau
/// `hidden: _hidden` diganti `hidden: false`, dan seluruh suite tetap hijau.
/// Yang kedua adalah kebocoran privasi: pengguna menekan tombol mata, saldo
/// utama hilang, baris uang terikat tetap memamerkan nominal.
class _FakeL10nDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _FakeL10nDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) => SynchronousFuture(
    AppLocalizations(locale, const {
      'dashboard_saldo_label': 'SALDO TERKINI',
      'dashboard_balance_hidden': '••••••',
      'dashboard_balance_as_of': 'Per',
      'dashboard_balance_detail': 'Detail',
      'dashboard_tied_eyebrow': 'Sebelum gajian',
      'dashboard_tied_eyebrow_info': 'Tagihan sebelum gajian',
      'dashboard_tied_safe_label': 'Aman dipakai',
      'dashboard_tied_detail_flexible': 'terikat tagihan',
      'dashboard_tied_detail_budgeted': 'sudah dianggarkan',
      'dashboard_tied_info_suffix': 'sudah dianggarkan dari kebutuhan tetapmu.',
      'dashboard_tied_negative_hint': 'Tagihanmu melebihi sisa anggaran.',
      'dashboard_tied_nudge': 'Cek lagi, yuk.',
    }),
  );
  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

void main() {
  // `SaldoCard._timestamp` memanggil `DateFormat(pola, languageCode)` dengan
  // locale eksplisit. Di aplikasi nyata data locale intl disiapkan oleh
  // `GlobalMaterialLocalizations.delegate`; harness ini tidak memakainya,
  // jadi datanya disiapkan langsung di sini (pola sama seperti
  // `transaction_detail_sheet_test.dart:55`).
  setUpAll(initializeDateFormatting);

  Widget harness(DashboardEntity entity) => MaterialApp(
    localizationsDelegates: const [_FakeL10nDelegate()],
    home: Scaffold(
      body: SaldoCard(entity: entity, onDetailTap: () {}),
    ),
  );

  testWidgets('(a) TiedMoneyRow terpasang saat billCommitments tidak kosong', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        _entity(
          const BillCommitments(
            tiedTotal: 500000,
            tiedFlexible: 500000,
            safeRemaining: 700000,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(TiedMoneyRow), findsOneWidget);
  });

  testWidgets(
    '(b) hidden mengikuti toggle privasi saldo — tanpa ini, tombol mata '
    'menyembunyikan saldo utama tapi baris uang terikat tetap bocor',
    (tester) async {
      await tester.pumpWidget(
        harness(
          _entity(
            const BillCommitments(
              tiedTotal: 500000,
              tiedFlexible: 500000,
              safeRemaining: 700000,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        tester.widget<TiedMoneyRow>(find.byType(TiedMoneyRow)).hidden,
        isFalse,
      );

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TiedMoneyRow>(find.byType(TiedMoneyRow)).hidden,
        isTrue,
      );
    },
  );
}

/// Hanya empat field yang dibaca `SaldoCard`; sisanya nilai netral supaya
/// test ini tidak ikut mengunci hal yang bukan urusannya.
DashboardEntity _entity(BillCommitments commitments) => DashboardEntity(
  dailyBudget: 0,
  spentToday: 0,
  remainingToday: 0,
  totalMonthlyBudget: 0,
  totalSpentThisMonth: 0,
  totalRemaining: 1200000,
  daysToLive: 0,
  remainingDays: 0,
  avgDailySpend: 0,
  status: BudgetStatus.safe,
  lastUpdated: DateTime(2026, 8, 5, 9, 30),
  todayTransactions: const [],
  emergencyFundMonthly: 0,
  billCommitments: commitments,
);
