import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/presentation/widgets/bill_item.dart';

// Delegate sinkron — rootBundle async bentrok dengan fakeAsync widget test.
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
  final todayStart = DateTime(2026, 12, 1);

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
  });

  BillEntity buildBill({
    required int id,
    required String name,
    required DateTime dueDate,
    int estimatedAmount = 10000,
    int? installmentTotal,
    int installmentsPaid = 0,
  }) => BillEntity(
    id: id,
    name: name,
    estimatedAmount: estimatedAmount,
    category: 'fixed',
    isFixedNeed: true,
    dueDate: dueDate,
    recurrence: Recurrence.monthly,
    installmentTotal: installmentTotal,
    installmentsPaid: installmentsPaid,
    reminderEnabled: true,
    status: BillStatus.active,
    createdAt: todayStart,
    updatedAt: todayStart,
  );

  Future<void> pumpItem(
    WidgetTester tester,
    BillEntity bill, {
    required double width,
  }) => tester.pumpWidget(
    MaterialApp(
      locale: const Locale('id'),
      supportedLocales: const [Locale('id'), Locale('en')],
      localizationsDelegates: [
        _SyncL10nDelegate(l10n),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: BillItem(
              bill: bill,
              todayStart: todayStart,
              onMenuTap: () {},
            ),
          ),
        ),
      ),
    ),
  );

  // Repro §4.3 checklist device: baris "C" — caption tanggal pendek (mis.
  // "10 DES") + label cicilan panjang ("Cicilan ke-4 dari 12"). Sebelum
  // fix, keduanya berbagi `Row` lewat `Flexible` berbobot SAMA — jatah 50/50
  // itu tak peduli "10 DES" sebenarnya tak butuh separuh ruang, jadi sisa
  // jatahnya tak pernah kembali ke label cicilan yang lebih panjang.
  //
  // Lebar 650 sengaja lega (bukan lebar HP asli) — test ini mengisolasi SATU
  // hal: begitu `dueLabel` berhenti ikut kompetisi flex, `installmentLabel`
  // menyerap SEMUA sisa ruang alih-alih dijatah rata. Di lebar HP sempit
  // (~360–411dp) label 20 karakter ini tetap bisa terpotong — itu bukan lagi
  // soal pembagian flex, tapi kolom nama+caption memang sesempit itu (chip
  // status + nominal di sebelah kanan menyisakan ~100dp saja). Itu keputusan
  // produk terpisah (lihat diskusi §4.3), bukan yang dikunci test ini.
  testWidgets(
    'label cicilan menyerap sisa ruang, tak lagi dijatah rata dengan caption tanggal pendek',
    (tester) async {
      final bill = buildBill(
        id: 1,
        name: 'C',
        dueDate: DateTime(2026, 12, 10),
        installmentTotal: 12,
        installmentsPaid: 3, // → "Cicilan ke-4 dari 12"
      );

      await pumpItem(tester, bill, width: 650);
      await tester.pump();

      final label = l10n.billsInstallmentProgress(4, 12).toUpperCase();
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text(label),
      );

      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason:
            'Label cicilan terpotong ellipsis padahal caption tanggal di '
            'sebelahnya jauh lebih pendek dan ruang totalnya lebih dari '
            'cukup — pembagian Flexible 50/50 tak memperhitungkan '
            'kebutuhan konten.',
      );
    },
  );
}
