// test/features/settings/security_section_test.dart
//
// Uji section "Keamanan" di Settings (Task 16). Diuji lewat widget
// [SecuritySection] yang berdiri sendiri — bukan lewat SettingsPage penuh —
// supaya tak perlu menyeret AppDatabase/SettingsBloc/NotificationBloc hanya
// untuk menguji App Lock.
//
// Fokus utama: `AppLockCubit.onSettingsChanged()` WAJIB dipanggil setelah
// SETIAP perubahan state lock. Tanpa itu cache config cubit basi → user bisa
// terkunci di LockScreen oleh PIN yang sudah terhapus.
import 'package:bloc_test/bloc_test.dart'; // MockCubit — WAJIB, tanpa ini tak compile
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:penyintas_app/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:penyintas_app/features/app_lock/presentation/cubit/app_lock_cubit.dart';
import 'package:penyintas_app/features/app_lock/presentation/cubit/app_lock_state.dart';
import 'package:penyintas_app/features/settings/presentation/pages/settings_page.dart';

class _MockRepo extends Mock implements AppLockRepository {}

class _MockAppLockCubit extends MockCubit<AppLockState>
    implements AppLockCubit {}

class _MockAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

/// Delegate l10n sinkron — WAJIB. Delegate asli membaca rootBundle dan
/// menggantung di test kedua dan seterusnya.
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

const _disabledConfig = AppLockConfig(
  enabled: false,
  hasPin: false,
  biometricEnabled: false,
);
const _enabledConfig = AppLockConfig(
  enabled: true,
  hasPin: true,
  biometricEnabled: false,
  ownerUid: 'u1',
);

/// Bersihkan registrasi DI milik test ini — `sl` global & dipakai bersama
/// test lain, jadi wajib dilepas lagi di tearDown.
void unregisterAll() {
  if (sl.isRegistered<AppLockRepository>()) {
    sl.unregister<AppLockRepository>();
  }
  if (sl.isRegistered<AppLockCubit>()) {
    sl.unregister<AppLockCubit>();
  }
  if (sl.isRegistered<FirebaseAuth>()) {
    sl.unregister<FirebaseAuth>();
  }
}

void main() {
  late AppLocalizations l10n;
  late _MockRepo repo;
  late _MockAppLockCubit cubit;
  late _MockAuth auth;
  late AppLockConfig config;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
  });

  setUp(() {
    repo = _MockRepo();
    cubit = _MockAppLockCubit();
    auth = _MockAuth();
    config = _disabledConfig;

    final user = _MockUser();
    when(() => user.uid).thenReturn('u1');
    when(() => auth.currentUser).thenReturn(user);

    when(() => repo.readConfig()).thenAnswer((_) async => config);
    when(() => repo.isBiometricAvailable()).thenAnswer((_) async => false);
    when(() => repo.getLockedUntilMs()).thenAnswer((_) async => 0);
    when(() => repo.getFailedAttempts()).thenAnswer((_) async => 0);
    when(() => repo.resetFailedAttempts()).thenAnswer((_) async {});
    when(() => repo.verifyPin(any())).thenAnswer((_) async => true);
    // setPin/disableLock/setBiometricEnabled memutakhirkan `config` seperti
    // repository sungguhan, supaya _loadLock() setelahnya membaca state baru.
    when(() => repo.setPin(any(), any())).thenAnswer((_) async {
      config = _enabledConfig;
    });
    when(() => repo.disableLock()).thenAnswer((_) async {
      config = _disabledConfig;
    });
    when(() => repo.setBiometricEnabled(any())).thenAnswer((inv) async {
      config = AppLockConfig(
        enabled: config.enabled,
        hasPin: config.hasPin,
        biometricEnabled: inv.positionalArguments.first as bool,
        ownerUid: config.ownerUid,
      );
    });
    when(() => cubit.onSettingsChanged()).thenAnswer((_) async {});

    unregisterAll();
    sl.registerLazySingleton<AppLockRepository>(() => repo);
    sl.registerLazySingleton<AppLockCubit>(() => cubit);
    sl.registerLazySingleton<FirebaseAuth>(() => auth);
  });

  tearDown(unregisterAll);

  Future<void> pumpSection(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [_SyncL10nDelegate(l10n)],
        locale: const Locale('id'),
        home: const Scaffold(body: SecuritySection()),
      ),
    );
    await tester
        .pumpAndSettle(); // selesaikan _loadLock (readConfig + isBiometricAvailable)
  }

  Future<void> enterPin(WidgetTester tester, String pin) async {
    for (final d in pin.split('')) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Finder lockSwitch() =>
      find.widgetWithText(SwitchListTile, l10n.applockToggleTitle);
  Finder biometricSwitch() =>
      find.widgetWithText(SwitchListTile, l10n.applockBiometricTitle);

  testWidgets(
    'lock OFF → hanya toggle utama; biometrik & Ubah PIN tersembunyi',
    (tester) async {
      await pumpSection(tester);

      expect(
        find.text(l10n.settingsSectionSecurity.toUpperCase()),
        findsOneWidget,
      );
      expect(
        tester.widget<SwitchListTile>(lockSwitch()).value,
        isFalse,
      ); // default OFF
      expect(biometricSwitch(), findsNothing);
      expect(find.text(l10n.applockChangePin), findsNothing);
    },
  );

  testWidgets('lock ON + biometrik tersedia → sub-toggle & Ubah PIN tampil', (
    tester,
  ) async {
    config = const AppLockConfig(
      enabled: true,
      hasPin: true,
      biometricEnabled: true,
      ownerUid: 'u1',
    );
    when(() => repo.isBiometricAvailable()).thenAnswer((_) async => true);
    await pumpSection(tester);

    expect(tester.widget<SwitchListTile>(lockSwitch()).value, isTrue);
    expect(tester.widget<SwitchListTile>(biometricSwitch()).value, isTrue);
    expect(find.text(l10n.applockChangePin), findsOneWidget);
  });

  testWidgets('lock ON tapi biometrik tak tersedia → sub-toggle tersembunyi', (
    tester,
  ) async {
    config = _enabledConfig;
    when(() => repo.isBiometricAvailable()).thenAnswer((_) async => false);
    await pumpSection(tester);

    expect(tester.widget<SwitchListTile>(lockSwitch()).value, isTrue);
    expect(biometricSwitch(), findsNothing);
    expect(find.text(l10n.applockChangePin), findsOneWidget);
  });

  testWidgets(
    'menyalakan lock → SetPinPage → setPin(uid) lalu onSettingsChanged',
    (tester) async {
      await pumpSection(tester);
      await tester.tap(lockSwitch());
      await tester.pumpAndSettle();

      expect(find.text(l10n.applockSetTitle), findsOneWidget);
      await enterPin(tester, '123456'); // PIN baru
      await enterPin(tester, '123456'); // konfirmasi

      verifyInOrder([
        () => repo.setPin('123456', 'u1'),
        () => cubit.onSettingsChanged(),
      ]);
      // _loadLock() ulang → UI mencerminkan config baru.
      expect(tester.widget<SwitchListTile>(lockSwitch()).value, isTrue);
    },
  );

  testWidgets('batal di SetPinPage → tak ada setPin & toggle tetap OFF', (
    tester,
  ) async {
    await pumpSection(tester);
    await tester.tap(lockSwitch());
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    verifyNever(() => repo.setPin(any(), any()));
    expect(tester.widget<SwitchListTile>(lockSwitch()).value, isFalse);
  });

  testWidgets(
    'mematikan lock → VerifyPinPage dulu → disableLock lalu onSettingsChanged',
    (tester) async {
      config = _enabledConfig;
      await pumpSection(tester);
      await tester.tap(lockSwitch());
      await tester.pumpAndSettle();

      // WAJIB verifikasi PIN dulu — bukan langsung mati.
      expect(find.text(l10n.applockVerifyToDisable), findsOneWidget);
      verifyNever(() => repo.disableLock());

      await enterPin(tester, '123456');

      verifyInOrder([
        () => repo.disableLock(),
        () => cubit.onSettingsChanged(),
      ]);
      expect(tester.widget<SwitchListTile>(lockSwitch()).value, isFalse);
    },
  );

  testWidgets(
    'PIN salah saat mematikan lock → disableLock TIDAK dipanggil, toggle tetap ON',
    (tester) async {
      config = _enabledConfig;
      when(() => repo.verifyPin(any())).thenAnswer((_) async => false);
      when(() => repo.recordFailedAttempt()).thenAnswer((_) async {});
      when(() => repo.getFailedAttempts()).thenAnswer((_) async => 1);
      await pumpSection(tester);
      await tester.tap(lockSwitch());
      await tester.pumpAndSettle();
      await enterPin(tester, '000000');

      expect(find.text(l10n.applockWrong), findsOneWidget);
      verifyNever(() => repo.disableLock());
      verifyNever(() => cubit.onSettingsChanged());
    },
  );

  testWidgets(
    'batal verifikasi → disableLock TIDAK dipanggil, toggle tetap ON',
    (tester) async {
      config = _enabledConfig;
      await pumpSection(tester);
      await tester.tap(lockSwitch());
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      verifyNever(() => repo.disableLock());
      expect(tester.widget<SwitchListTile>(lockSwitch()).value, isTrue);
    },
  );

  testWidgets('toggle biometrik → setBiometricEnabled lalu onSettingsChanged', (
    tester,
  ) async {
    config = _enabledConfig;
    when(() => repo.isBiometricAvailable()).thenAnswer((_) async => true);
    await pumpSection(tester);

    expect(tester.widget<SwitchListTile>(biometricSwitch()).value, isFalse);
    await tester.tap(biometricSwitch());
    await tester.pumpAndSettle();

    verifyInOrder([
      () => repo.setBiometricEnabled(true),
      () => cubit.onSettingsChanged(),
    ]);
    expect(tester.widget<SwitchListTile>(biometricSwitch()).value, isTrue);
  });

  testWidgets(
    'Ubah PIN → ChangePinPage → PIN baru tersimpan + onSettingsChanged',
    (tester) async {
      config = _enabledConfig;
      await pumpSection(tester);
      await tester.tap(find.text(l10n.applockChangePin));
      await tester.pumpAndSettle();

      expect(find.text(l10n.applockChangeCurrent), findsOneWidget);
      await enterPin(tester, '123456'); // PIN lama
      expect(find.text(l10n.applockSetTitle), findsOneWidget);
      await enterPin(tester, '654321'); // PIN baru
      await enterPin(tester, '654321'); // konfirmasi

      verifyInOrder([
        () => repo.setPin('654321', 'u1'),
        () => cubit.onSettingsChanged(),
      ]);
      // Kembali ke Settings, section tetap utuh.
      expect(find.text(l10n.applockChangePin), findsOneWidget);
    },
  );

  testWidgets(
    'uid null (belum login) → toggle tak membuka halaman PIN apa pun',
    (tester) async {
      when(() => auth.currentUser).thenReturn(null);
      await pumpSection(tester);
      await tester.tap(lockSwitch());
      await tester.pumpAndSettle();

      expect(find.text(l10n.applockSetTitle), findsNothing);
      verifyNever(() => repo.setPin(any(), any()));
    },
  );
}
