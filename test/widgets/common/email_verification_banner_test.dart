import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/auth/domain/entities/user_entity.dart';
import 'package:penyintas_app/features/auth/domain/usecases/send_email_verification_usecase.dart';
import 'package:penyintas_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:penyintas_app/features/auth/presentation/cubit/email_verification_cubit.dart';
import 'package:penyintas_app/widgets/common/email_verification_banner.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockSendEmailVerificationUseCase extends Mock
    implements SendEmailVerificationUseCase {}

// AuthEvent adalah sealed class — tidak bisa di-`implements` di luar library-nya,
// jadi fallback value memakai instance nyata AuthUserReloadRequested (const).
class FakeSendEmailVerificationParams extends Fake
    implements SendEmailVerificationParams {}

// Delegate sinkron — rootBundle.loadString (platform channel) tidak bisa
// didorong pump() setelah test pertama dalam satu file. Preseden:
// test/widgets/common/financial_slider_widget_test.dart.
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
  final sl = GetIt.instance;
  late AppLocalizations l10n;
  late MockAuthBloc bloc;
  late MockSendEmailVerificationUseCase mockSend;

  final unverifiedPasswordUser = UserEntity(
    uid: 'u1',
    email: 'a@b.com',
    displayName: 'A',
    createdAt: DateTime(2026),
    emailVerified: false,
    hasPasswordProvider: true,
  );
  final verifiedUser = UserEntity(
    uid: 'u1',
    email: 'a@b.com',
    displayName: 'A',
    createdAt: DateTime(2026),
    emailVerified: true,
    hasPasswordProvider: true,
  );
  final googleUser = UserEntity(
    uid: 'u2',
    email: 'g@gmail.com',
    displayName: 'G',
    createdAt: DateTime(2026),
    emailVerified: true,
    hasPasswordProvider: false,
  );

  setUpAll(() async {
    registerFallbackValue(const AuthUserReloadRequested());
    registerFallbackValue(FakeSendEmailVerificationParams());
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
  });

  setUp(() {
    bloc = MockAuthBloc();
    mockSend = MockSendEmailVerificationUseCase();
    when(() => mockSend(any())).thenAnswer((_) async => const Right(null));
    // Banner membuat cubit-nya sendiri via sl — daftarkan cubit ASLI dengan
    // usecase mock agar jalur BlocListener ikut teruji.
    sl.registerFactory<EmailVerificationCubit>(
      () => EmailVerificationCubit(mockSend),
    );
  });

  tearDown(() => sl.unregister<EmailVerificationCubit>());

  Widget harness() => MaterialApp(
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
        child: const EmailVerificationBanner(),
      ),
    ),
  );

  Future<void> pumpBanner(WidgetTester tester, AuthState initialState) async {
    whenListen(
      bloc,
      const Stream<AuthState>.empty(),
      initialState: initialState,
    );
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
  }

  testWidgets('tampil untuk password-user belum verified', (tester) async {
    await pumpBanner(tester, Authenticated(unverifiedPasswordUser));
    expect(find.text('Verifikasi email kamu'), findsOneWidget);
    expect(find.text('Kirim ulang'), findsOneWidget);
  });

  testWidgets('tersembunyi bila sudah verified', (tester) async {
    await pumpBanner(tester, Authenticated(verifiedUser));
    expect(find.text('Verifikasi email kamu'), findsNothing);
  });

  testWidgets('tersembunyi untuk akun Google', (tester) async {
    await pumpBanner(tester, Authenticated(googleUser));
    expect(find.text('Verifikasi email kamu'), findsNothing);
  });

  testWidgets('tersembunyi bila state bukan Authenticated', (tester) async {
    await pumpBanner(tester, const Unauthenticated());
    expect(find.text('Verifikasi email kamu'), findsNothing);
  });

  testWidgets(
    'mount (belum verified) → reload sekali — tutup celah cold start',
    (tester) async {
      await pumpBanner(tester, Authenticated(unverifiedPasswordUser));
      verify(
        () => bloc.add(any(that: isA<AuthUserReloadRequested>())),
      ).called(1);
    },
  );

  testWidgets('mount (sudah verified) → TIDAK reload (hemat network)', (
    tester,
  ) async {
    await pumpBanner(tester, Authenticated(verifiedUser));
    verifyNever(() => bloc.add(any(that: isA<AuthUserReloadRequested>())));
  });

  testWidgets('tap Kirim ulang sukses → snackbar terkirim + cooldown 60 dtk', (
    tester,
  ) async {
    await pumpBanner(tester, Authenticated(unverifiedPasswordUser));

    await tester.tap(find.text('Kirim ulang'));
    await tester.pump(); // proses resend (microtask usecase mock)
    await tester.pump(); // frame snackbar

    verify(() => mockSend(any())).called(1);
    expect(
      find.text('Email verifikasi terkirim. Cek inbox kamu ya.'),
      findsOneWidget,
    );
    // Cooldown aktif: CTA berubah jadi teks tunggu ("Tunggu 60 dtk")
    expect(find.text('Kirim ulang'), findsNothing);
    expect(find.textContaining('dtk'), findsOneWidget);

    // Setelah 60 detik CTA kembali aktif
    await tester.pump(const Duration(seconds: 61));
    await tester.pumpAndSettle();
    expect(find.text('Kirim ulang'), findsOneWidget);
  });

  testWidgets(
    'tap Kirim ulang gagal → snackbar pesan tenang + cooldown tetap',
    (tester) async {
      when(() => mockSend(any())).thenAnswer(
        (_) async => const Left(
          AuthFailure('Terlalu banyak percobaan. Tunggu sebentar ya.'),
        ),
      );
      await pumpBanner(tester, Authenticated(unverifiedPasswordUser));

      await tester.tap(find.text('Kirim ulang'));
      await tester.pump();
      await tester.pump();

      // Feedback JUJUR: pesan gagal tampil, bukan "terkirim"
      expect(
        find.text('Terlalu banyak percobaan. Tunggu sebentar ya.'),
        findsOneWidget,
      );
      expect(
        find.text('Email verifikasi terkirim. Cek inbox kamu ya.'),
        findsNothing,
      );
      // Cooldown tetap jalan (anti-spam) — cari 'dtk' agar tak bentrok
      // dengan kata "Tunggu" di pesan snackbar
      expect(find.textContaining('dtk'), findsOneWidget);

      // Habiskan timer cooldown agar test bersih
      await tester.pump(const Duration(seconds: 61));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('app resume → reload lagi', (tester) async {
    await pumpBanner(tester, Authenticated(unverifiedPasswordUser));
    clearInteractions(bloc); // buang dispatch reload saat mount

    // inactive dulu — guard duplicate-state binding menelan resumed→resumed
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    verify(() => bloc.add(any(that: isA<AuthUserReloadRequested>()))).called(1);
  });
}
