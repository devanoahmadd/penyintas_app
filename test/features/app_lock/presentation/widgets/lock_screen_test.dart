// test/features/app_lock/presentation/widgets/lock_screen_test.dart
import 'dart:async';
import 'package:bloc_test/bloc_test.dart'; // MockBloc — WAJIB, tanpa ini tak compile
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:penyintas_app/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:penyintas_app/features/app_lock/presentation/cubit/app_lock_cubit.dart';
import 'package:penyintas_app/features/app_lock/presentation/cubit/app_lock_state.dart';
import 'package:penyintas_app/features/app_lock/presentation/widgets/lock_screen.dart';
import 'package:penyintas_app/features/app_lock/presentation/widgets/pin_keypad.dart';
import 'package:penyintas_app/features/auth/presentation/bloc/auth_bloc.dart';

class _MockRepo extends Mock implements AppLockRepository {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _SyncL10nDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _SyncL10nDelegate(this._value);
  final AppLocalizations _value;
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => _value;
  @override
  bool shouldReload(_) => false;
}

void main() {
  late AppLocalizations l10n;
  late _MockRepo repo;
  late StreamController<String?> uidCtrl;
  late _MockAuthBloc authBloc;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
  });

  setUp(() {
    repo = _MockRepo();
    uidCtrl = StreamController<String?>.broadcast();
    authBloc = _MockAuthBloc();
    when(() => repo.readConfig()).thenAnswer(
      (_) async => const AppLockConfig(
        enabled: true,
        hasPin: true,
        biometricEnabled: false,
        ownerUid: 'u1',
      ),
    );
    when(() => repo.isBiometricAvailable()).thenAnswer((_) async => false);
    when(() => repo.getFailedAttempts()).thenAnswer((_) async => 0);
    when(() => repo.getLockedUntilMs()).thenAnswer((_) async => 0);
    when(() => repo.resetFailedAttempts()).thenAnswer((_) async {});
    when(() => repo.verifyPin(any())).thenAnswer((_) async => true);
  });

  tearDown(() => uidCtrl.close());

  Future<AppLockCubit> pumpLock(WidgetTester tester) async {
    final cubit = AppLockCubit(
      repo: repo,
      currentUid: () => 'u1',
      uidChanges: uidCtrl.stream,
    );
    await cubit.init();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AppLockCubit>.value(value: cubit),
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: MaterialApp(
          localizationsDelegates: [_SyncL10nDelegate(l10n)],
          locale: const Locale('id'),
          home: const LockScreen(),
        ),
      ),
    );
    await tester.pump();
    return cubit;
  }

  testWidgets('menampilkan judul "Masukkan PIN" & tombol Lupa PIN', (
    tester,
  ) async {
    await pumpLock(tester);
    expect(find.text(l10n.applockEnterTitle), findsOneWidget);
    expect(find.text(l10n.applockForgot), findsOneWidget);
  });

  testWidgets('memasukkan 6 digit benar → cubit unlocked', (tester) async {
    final cubit = await pumpLock(tester);
    for (final d in ['1', '2', '3', '4', '5', '6']) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
    await tester.pump();
    expect(cubit.state, isA<AppLockUnlocked>());
  });

  testWidgets('tap Lupa PIN → konfirmasi → forgotPin + SignOutRequested', (
    tester,
  ) async {
    when(() => repo.disableLock()).thenAnswer((_) async {});
    await pumpLock(tester);
    await tester.tap(find.text(l10n.applockForgot));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.applockForgotConfirm));
    await tester.pumpAndSettle();
    verify(() => repo.disableLock()).called(1);
    verify(() => authBloc.add(const SignOutRequested())).called(1);
  });

  testWidgets('tombol retry biometrik tampil & memicu authenticateBiometric', (
    tester,
  ) async {
    when(() => repo.readConfig()).thenAnswer(
      (_) async => const AppLockConfig(
        enabled: true,
        hasPin: true,
        biometricEnabled: true,
        ownerUid: 'u1',
      ),
    );
    when(() => repo.isBiometricAvailable()).thenAnswer((_) async => true);
    when(
      () => repo.authenticateBiometric(any()),
    ).thenAnswer((_) async => false);
    await pumpLock(tester);
    expect(find.byIcon(Icons.fingerprint), findsOneWidget);
    await tester.tap(find.byIcon(Icons.fingerprint));
    await tester.pump();
    // 2× — auto-prompt saat mount + retry manual via tombol.
    verify(() => repo.authenticateBiometric(any())).called(2);
  });

  testWidgets(
    'lockout aktif → keypad disabled + countdown tampil, tap keypad tidak memicu verifyPin',
    (tester) async {
      when(() => repo.getFailedAttempts()).thenAnswer((_) async => 5);
      final lockedUntil = DateTime.now().millisecondsSinceEpoch + 30000;
      when(() => repo.getLockedUntilMs()).thenAnswer((_) async => lockedUntil);
      await pumpLock(tester);

      // Countdown tampil — cocokkan pola teksnya (bukan angka detik persis,
      // karena ceil() bisa 29/30 tergantung timing eksekusi test) via getter
      // resmi applockLockedWait.
      final countdownPattern = RegExp(
        RegExp.escape(l10n.applockLockedWait(999)).replaceAll('999', r'\d+'),
      );
      expect(find.textContaining(countdownPattern), findsOneWidget);

      // Keypad harus disabled selama lockout. Dicek langsung ke prop
      // PinKeypad.enabled — bukan cuma lewat verifyNever di bawah, karena
      // `_onDigit` di LockScreen punya guard kedua (lockedSeconds > 0) yang
      // tetap menahan submitPin walau keypad "dipaksa" enabled oleh regresi.
      final keypad = tester.widget<PinKeypad>(find.byType(PinKeypad));
      expect(keypad.enabled, isFalse);

      for (final d in ['1', '2', '3', '4', '5', '6']) {
        await tester.tap(find.text(d));
        await tester.pump();
      }
      verifyNever(() => repo.verifyPin(any()));
    },
  );

  testWidgets(
    'lockout aktif → tombol Lupa PIN tetap bisa ditekan (jalan keluar satu-satunya)',
    (tester) async {
      when(() => repo.getFailedAttempts()).thenAnswer((_) async => 5);
      when(
        () => repo.getLockedUntilMs(),
      ).thenAnswer((_) async => DateTime.now().millisecondsSinceEpoch + 30000);
      when(() => repo.disableLock()).thenAnswer((_) async {});
      await pumpLock(tester);
      await tester.tap(find.text(l10n.applockForgot));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.applockForgotConfirm));
      await tester.pumpAndSettle();
      verify(() => repo.disableLock()).called(1);
      verify(() => authBloc.add(const SignOutRequested())).called(1);
    },
  );
}
