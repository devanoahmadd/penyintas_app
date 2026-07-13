import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/widgets/common/google_auth_button.dart';

// Delegate sinkron — lihat catatan Global Constraints (rootBundle vs fakeAsync).
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

  Widget harness({required bool isLoading, required VoidCallback onPressed}) =>
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
          body: GoogleAuthButton(isLoading: isLoading, onPressed: onPressed),
        ),
      );

  testWidgets('label dari l10n + logo SVG asset (bukan teks G)', (
    tester,
  ) async {
    await tester.pumpWidget(harness(isLoading: false, onPressed: () {}));
    await tester.pumpAndSettle();
    expect(find.text('Lanjutkan dengan Google'), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('G'), findsNothing);
  });

  testWidgets('tap → onPressed terpanggil; isLoading → tidak', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      harness(isLoading: false, onPressed: () => tapped++),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(GoogleAuthButton));
    expect(tapped, 1);

    await tester.pumpWidget(
      harness(isLoading: true, onPressed: () => tapped++),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(GoogleAuthButton));
    expect(tapped, 1); // tidak bertambah
  });
}
