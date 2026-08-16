import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/presentation/widgets/bill_actions_sheet.dart';

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

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);

  // Fixture disalin per berkas — konvensi test repo ini.
  BillEntity billContoh({
    int id = 1,
    String name = 'Kos Bu Tini',
    int estimatedAmount = 750000,
  }) => BillEntity(
    id: id,
    name: name,
    estimatedAmount: estimatedAmount,
    category: 'fixed',
    isFixedNeed: true,
    dueDate: todayStart,
    recurrence: Recurrence.monthly,
    installmentsPaid: 0,
    reminderEnabled: true,
    status: BillStatus.active,
    createdAt: todayStart,
    updatedAt: todayStart,
  );

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
  });

  // ── Helper interaksi (A.5 dari perkakas test bersama) ──────────────────────
  late BillAction? hasil;

  Future<void> bukaSheet(
    WidgetTester tester, {
    required BillEntity bill,
    ThemeData? theme,
  }) async {
    hasil = null;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('id'),
        supportedLocales: const [Locale('id'), Locale('en')],
        localizationsDelegates: [
          _SyncL10nDelegate(l10n),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: theme,
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: TextButton(
                onPressed: () async {
                  hasil = await BillActionsSheet.show(ctx, bill: bill);
                },
                child: const Text('buka'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  final kos = billContoh();

  testWidgets('sheet menampilkan nama tagihan dan dua aksi', (tester) async {
    await bukaSheet(tester, bill: kos);

    expect(find.text('Kos Bu Tini'), findsOneWidget);
    expect(find.text(l10n.billsActionEdit), findsOneWidget);
    expect(find.text(l10n.billsActionDelete), findsOneWidget);
  });

  testWidgets('memilih Ubah mengembalikan BillAction.edit', (tester) async {
    await bukaSheet(tester, bill: kos);

    await tester.tap(find.text(l10n.billsActionEdit));
    await tester.pumpAndSettle();

    expect(hasil, BillAction.edit);
  });

  testWidgets('memilih Hapus mengembalikan BillAction.delete', (tester) async {
    await bukaSheet(tester, bill: kos);

    await tester.tap(find.text(l10n.billsActionDelete));
    await tester.pumpAndSettle();

    expect(hasil, BillAction.delete);
  });

  testWidgets('menutup sheet tanpa memilih mengembalikan null', (tester) async {
    await bukaSheet(tester, bill: kos);

    Navigator.of(tester.element(find.text(l10n.billsActionEdit))).pop();
    await tester.pumpAndSettle();

    expect(hasil, isNull);
  });

  testWidgets('tiap baris aksi memenuhi 48dp', (tester) async {
    await bukaSheet(tester, bill: kos);

    for (final key in ['bill_action_edit', 'bill_action_delete']) {
      expect(
        tester.getSize(find.byKey(ValueKey(key))).height,
        greaterThanOrEqualTo(48),
        reason: 'baris "$key" di bawah hit target minimum',
      );
    }
  });

  // Aksi merusak dibedakan DUA cara — warna DAN ikon. Pengguna yang tak
  // membedakan warna tetap terbantu (aturan `color-not-only`).
  testWidgets('teks Hapus memakai AppColors.warn', (tester) async {
    await bukaSheet(tester, bill: kos);

    final teks = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('bill_action_delete')),
        matching: find.byType(Text),
      ),
    );
    expect(teks.style?.color, AppColors.warn);
  });

  testWidgets('baris Hapus punya ikon pembeda, bukan hanya warna', (
    tester,
  ) async {
    await bukaSheet(tester, bill: kos);

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('bill_action_delete')),
        matching: find.byIcon(Icons.delete_outline_rounded),
      ),
      findsOneWidget,
    );
    // Baris Ubah memakai ikon yang BERBEDA — kalau keduanya sama, ikon berhenti
    // jadi pembeda dan tinggal warna yang bekerja sendirian.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('bill_action_edit')),
        matching: find.byIcon(Icons.delete_outline_rounded),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('bill_action_edit')),
        matching: find.byIcon(Icons.edit_outlined),
      ),
      findsOneWidget,
    );
  });

  testWidgets('permukaan sheet memakai token surface, bukan warna card', (
    tester,
  ) async {
    await bukaSheet(tester, bill: kos);

    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(sheet.backgroundColor, AppColors.surfaceLight);
  });

  testWidgets('dark mode memakai surfaceDark dan render tanpa error', (
    tester,
  ) async {
    await bukaSheet(tester, bill: kos, theme: ThemeData.dark());

    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(sheet.backgroundColor, AppColors.surfaceDark);
    expect(tester.takeException(), isNull);
    expect(find.text('Kos Bu Tini'), findsOneWidget);
  });

  // Judul BUKAN sekadar hiasan: sheet ini muncul dari baris mana pun, jadi
  // nama tagihanlah satu-satunya penanda "yang mana yang akan kuhapus".
  testWidgets('nama tagihan panjang tidak terpotong di lebar 320dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await bukaSheet(tester, bill: billContoh(name: 'Cicilan motor Honda Beat'));

    final paragraph = tester.renderObject<RenderParagraph>(
      find.text('Cicilan motor Honda Beat'),
    );
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: 'judul sheet tak boleh terpotong — ia penanda tagihan mana',
    );
  });
}
