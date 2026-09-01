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

  // Redesign §4.3 (2026-09-01, ui-ux-pro-max): frasa penuh "Cicilan ke-4
  // dari 12" (20 karakter, font mono) tak pernah muat berdampingan dengan
  // caption tanggal di lebar HP nyata — dikonfirmasi lewat pengukuran
  // langsung, bukan cuma dugaan. Perbaikan sebelumnya (bobot Flexible 1:3)
  // cuma memperbaiki PEMBAGIAN ruang, bukan KEBUTUHAN ruangnya — jadi tetap
  // gagal di lebar realistis. Solusi sebenarnya: pangkas kebutuhannya.
  // Frasa lengkap dipindah ke sheet Tandai Lunas (ada ruang, konteksnya pas);
  // di list cukup "4/12" — bentuk pecahan singkat, tanpa kata sama sekali,
  // jadi tak perlu key l10n baru (sejajar `formatRupiah()`: murni format
  // angka, bukan konten bahasa).
  //
  // Test ini SENGAJA di lebar 360dp — HP sempit sungguhan, bukan lebar
  // artifisial seperti test lama. Kalau ini hijau, klaim "muat di HP nyata"
  // benar-benar terbukti, bukan diasumsikan.
  testWidgets('label cicilan dipadatkan jadi "4/12", muat di lebar HP 360dp', (
    tester,
  ) async {
    final bill = buildBill(
      id: 1,
      name: 'C',
      dueDate: DateTime(2026, 12, 10),
      installmentTotal: 12,
      installmentsPaid: 3, // → cicilan ke-4 dari 12 → "4/12"
    );

    await pumpItem(tester, bill, width: 360);
    await tester.pump();

    final paragraph = tester.renderObject<RenderParagraph>(find.text('4/12'));

    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: 'Bahkan bentuk pendek "4/12" tak boleh terpotong di lebar '
          'HP normal — kalau ini pun gagal, ada yang salah lebih dalam.',
    );
  });

  testWidgets(
    'frasa penuh "Cicilan ke-X dari Y" TIDAK lagi dipakai di list (pindah ke sheet)',
    (tester) async {
      final bill = buildBill(
        id: 1,
        name: 'C',
        dueDate: DateTime(2026, 12, 10),
        installmentTotal: 12,
        installmentsPaid: 3,
      );

      await pumpItem(tester, bill, width: 360);
      await tester.pump();

      expect(
        find.textContaining('CICILAN', findRichText: true),
        findsNothing,
        reason: 'Frasa panjang seharusnya sudah tak ada lagi di list item — '
            'kalau masih ada, redesign belum benar-benar diterapkan.',
      );
    },
  );
}
