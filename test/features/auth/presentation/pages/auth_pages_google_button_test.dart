import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:penyintas_app/features/auth/presentation/pages/login_page.dart';
import 'package:penyintas_app/features/auth/presentation/pages/register_page.dart';
import 'package:penyintas_app/widgets/common/google_auth_button.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

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
  late MockAuthBloc bloc;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
  });

  setUp(() {
    bloc = MockAuthBloc();
    whenListen(bloc, const Stream<AuthState>.empty(),
        initialState: const Unauthenticated());
  });

  Widget harness(Widget page) => MaterialApp(
        locale: const Locale('id'),
        supportedLocales: const [Locale('id'), Locale('en')],
        localizationsDelegates: [
          _SyncL10nDelegate(l10n),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: BlocProvider<AuthBloc>.value(value: bloc, child: page),
      );

  Future<void> pumpPage(WidgetTester tester, Widget page) async {
    // Viewport tinggi agar tombol tidak tergeser keluar lazy viewport
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(harness(page));
    await tester.pumpAndSettle();
  }

  testWidgets('tombol Google tampil di halaman login', (tester) async {
    await pumpPage(tester, const LoginPage());
    expect(find.byType(GoogleAuthButton), findsOneWidget);
  });

  testWidgets('tombol Google tampil di halaman register', (tester) async {
    await pumpPage(tester, const RegisterPage());
    expect(find.byType(GoogleAuthButton), findsOneWidget);
  });
}
