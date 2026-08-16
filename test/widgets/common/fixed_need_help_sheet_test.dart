import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/widgets/common/fixed_need_help_sheet.dart';

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

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
  });

  // ── Helper interaksi (pola bill_actions_sheet_test.dart) ────────────────
  Future<void> bukaSheet(WidgetTester tester, {ThemeData? theme}) async {
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
                onPressed: () => FixedNeedHelpSheet.show(ctx),
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

  testWidgets('sheet menampilkan lima blok teks sesuai urutan spec', (
    tester,
  ) async {
    await bukaSheet(tester);
    expect(find.text(l10n.billsFixedHelpTitle), findsOneWidget);
    expect(find.text(l10n.billsFixedHelpBody1), findsOneWidget);
    expect(find.text(l10n.billsFixedHelpBody2), findsOneWidget);
    expect(find.text(l10n.billsFixedHelpLockedTitle), findsOneWidget);
    expect(find.text(l10n.billsFixedHelpLockedBody), findsOneWidget);

    final yJudul = tester.getTopLeft(find.text(l10n.billsFixedHelpTitle)).dy;
    final yTerkunci = tester
        .getTopLeft(find.text(l10n.billsFixedHelpLockedTitle))
        .dy;
    expect(yJudul, lessThan(yTerkunci));
  });

  testWidgets('latar sheet memakai surfaceLight di tema terang', (
    tester,
  ) async {
    await bukaSheet(tester, theme: ThemeData.light());
    final sheet = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(sheet.color, AppColors.surfaceLight);
  });

  testWidgets('latar sheet memakai surfaceDark di tema gelap', (tester) async {
    await bukaSheet(tester, theme: ThemeData.dark());
    final sheet = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(sheet.color, AppColors.surfaceDark);
  });

  testWidgets('teks judul memakai token gelap, bukan token terang', (
    tester,
  ) async {
    await bukaSheet(tester, theme: ThemeData.dark());
    final judul = tester.widget<Text>(find.text(l10n.billsFixedHelpTitle));
    expect(judul.style?.color, AppColors.textDark);
  });

  // ── Gerbang ui-ux-pro-max: "Modal Escape" (severity High) — sheet bacaan
  // pasif tetap wajib punya jalan keluar EKSPLISIT, bukan cuma swipe/scrim.
  testWidgets('sheet punya tombol tutup eksplisit dengan hit target 48dp', (
    tester,
  ) async {
    await bukaSheet(tester);
    expect(find.byIcon(Icons.close), findsOneWidget);

    final size = tester.getSize(
      find
          .ancestor(
            of: find.byIcon(Icons.close),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('menekan tombol tutup menutup sheet', (tester) async {
    await bukaSheet(tester);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text(l10n.billsFixedHelpTitle), findsNothing);
  });

  // ── Review ronde 1, Important 1 ─────────────────────────────────────────
  // `InkResponse` TIDAK menyumbang peran tombol sendiri (beda dari
  // `IconButton`, yang membungkus dirinya dengan `Semantics(button: true)`
  // otomatis) — tanpa pembungkus eksplisit, tombol tutup tak terbaca sama
  // sekali maupun tak dikenali sebagai tombol oleh pembaca layar.
  testWidgets('tombol tutup punya peran tombol dan label semantik', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await bukaSheet(tester);

    final closeLabel = MaterialLocalizations.of(
      tester.element(find.byIcon(Icons.close)),
    ).closeButtonLabel;

    expect(
      tester.getSemantics(find.byIcon(Icons.close)),
      matchesSemantics(
        label: closeLabel,
        isButton: true,
        hasTapAction: true,
        // `InkResponse` bisa difokus (mis. navigasi keyboard/switch access)
        // secara bawaan — bukan sesuatu yang task ini tambahkan sendiri.
        isFocusable: true,
        hasFocusAction: true,
      ),
    );

    handle.dispose();
  });
}
