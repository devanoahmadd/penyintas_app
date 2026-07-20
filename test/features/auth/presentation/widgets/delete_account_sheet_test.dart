import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/auth/domain/entities/user_entity.dart';
import 'package:penyintas_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:penyintas_app/features/auth/presentation/widgets/delete_account_sheet.dart';
import 'package:penyintas_app/widgets/common/app_text_field.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

// Delegate sinkron — pola sama dengan auth_pages_google_button_test.dart.
// rootBundle bisa hang di test kedua bila delegate asinkron dipakai langsung.
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

UserEntity _makeUser({required bool hasPasswordProvider}) => UserEntity(
      uid: 'uid-1',
      email: 'a@b.com',
      displayName: 'Andi',
      photoUrl: null,
      createdAt: DateTime(2026, 7, 1),
      emailVerified: true,
      hasPasswordProvider: hasPasswordProvider,
    );

void main() {
  late AppLocalizations l10n;
  late MockAuthBloc bloc;

  setUpAll(() async {
    // Wajib untuk matcher any() pada bloc.add (mocktail).
    registerFallbackValue(const DeleteAccountRequested());
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
  });

  Widget harness({required bool hasPasswordProvider}) {
    bloc = MockAuthBloc();
    whenListen(
      bloc,
      const Stream<AuthState>.empty(),
      initialState:
          Authenticated(_makeUser(hasPasswordProvider: hasPasswordProvider)),
    );
    return MaterialApp(
      locale: const Locale('id'),
      supportedLocales: const [Locale('id'), Locale('en')],
      localizationsDelegates: [
        _SyncL10nDelegate(l10n),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: BlocProvider<AuthBloc>.value(
          value: bloc,
          child: const SingleChildScrollView(child: DeleteAccountSheet()),
        ),
      ),
    );
  }

  // Delegate l10n resolve lewat Future, jadi frame pertama masih kosong —
  // butuh settle sebelum assertion (pola sama dengan test referensi).
  Future<void> pumpSheet(
    WidgetTester tester, {
    required bool hasPasswordProvider,
  }) async {
    await tester.pumpWidget(harness(hasPasswordProvider: hasPasswordProvider));
    await tester.pumpAndSettle();
  }

  testWidgets('akun berpassword → field password tampil (perilaku lama)',
      (tester) async {
    await pumpSheet(tester, hasPasswordProvider: true);

    expect(find.byType(AppTextField), findsOneWidget);
    expect(find.text(l10n.deleteAccountGoogleHint), findsNothing);
  });

  testWidgets(
      'akun Google-only → tanpa field password, hint Google tampil, '
      'centang → dispatch password null', (tester) async {
    await pumpSheet(tester, hasPasswordProvider: false);

    expect(find.byType(AppTextField), findsNothing);
    expect(find.text(l10n.deleteAccountGoogleHint), findsOneWidget);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.text(l10n.deleteAccountConfirm));
    await tester.pump();

    verify(() => bloc.add(any(
        that: isA<DeleteAccountRequested>()
            .having((e) => e.password, 'password', isNull)))).called(1);
  });
}
