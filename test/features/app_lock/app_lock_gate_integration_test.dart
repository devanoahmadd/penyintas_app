// test/features/app_lock/app_lock_gate_integration_test.dart
//
// Menguji WIRING app.dart (Task 15) — BUKAN test AppLockGate itu sendiri
// (sudah diuji tuntas di
// test/features/app_lock/presentation/widgets/app_lock_gate_test.dart).
// File ini mem-pump `PenyintasApp` NYATA (import `lib/app.dart`), dengan
// dependency-nya (SettingsBloc/AuthBloc/NotificationBloc/GoRouter/SyncService)
// disubstitusi via `sl` (get_it) memakai fake/mock — pola identik dengan
// test/features/auth/presentation/pages/splash_ordering_test.dart.
//
// Tujuannya: memastikan `builder:` di MaterialApp.router BENAR-BENAR
// memasang AppLockGate di sekitar rute asli, dan bahwa AppLockCubit yang
// di-`init()` di initState() adalah instance yang SAMA dengan yang
// di-provide lewat BlocProvider.value ke AppLockGate — dibuktikan dengan
// memaksa transisi state lewat cubit itu sendiri (bukan widget lain) dan
// mengecek LockScreen sungguh menutup rute asli. Bila `builder:` dilepas,
// atau BlocProvider.value diganti sumbernya, test ini GAGAL.
//
// SENGAJA hanya SATU testWidgets di file ini: `AppLocalizations.delegateFor`
// asli (baked-in di app.dart, tak bisa disubstitusi dari test) memuat lewat
// rootBundle — memuatnya berkali-kali dalam satu proses test memicu hang
// (lihat catatan pola _SyncL10nDelegate di lock_screen_test.dart). Dengan
// satu test saja, `build()` cuma berjalan sekali sehingga muatan itu juga
// cuma terjadi sekali.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/app.dart';
import 'package:penyintas_app/core/sync/sync_service.dart';
import 'package:penyintas_app/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:penyintas_app/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:penyintas_app/features/app_lock/presentation/cubit/app_lock_cubit.dart';
import 'package:penyintas_app/features/app_lock/presentation/widgets/app_lock_gate.dart';
import 'package:penyintas_app/features/app_lock/presentation/widgets/lock_screen.dart';
import 'package:penyintas_app/features/app_lock/presentation/widgets/privacy_shade.dart';
import 'package:penyintas_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_event.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_state.dart';
import 'package:penyintas_app/features/settings/presentation/bloc/settings_bloc.dart';

class _MockRepo extends Mock implements AppLockRepository {}

class _FakeSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class _FakeAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _FakeNotificationBloc
    extends MockBloc<NotificationEvent, NotificationState>
    implements NotificationBloc {}

class _FakeSyncService extends Mock implements SyncService {}

void main() {
  final sl = GetIt.instance; // sama dgn `sl` di injection_container.dart

  testWidgets('app.dart: builder MaterialApp.router memasang AppLockGate yang '
      'terhubung ke AppLockCubit singleton sungguhan — lock ON benar2 '
      'mengunci rute asli lewat gate itu', (tester) async {
    final repo = _MockRepo();
    when(() => repo.readConfig()).thenAnswer(
      (_) async => const AppLockConfig(
        enabled: false,
        hasPin: false,
        biometricEnabled: false,
      ),
    );
    when(() => repo.isBiometricAvailable()).thenAnswer((_) async => false);
    when(() => repo.getFailedAttempts()).thenAnswer((_) async => 0);
    when(() => repo.getLockedUntilMs()).thenAnswer((_) async => 0);

    // Clock palsu — agar transisi grace 60 detik (background→resume) bisa
    // diuji tanpa benar-benar menunggu 60 detik nyata.
    var fakeNow = DateTime(2026, 1, 1, 12, 0, 0);
    final cubit = AppLockCubit(
      repo: repo,
      currentUid: () => 'u1',
      uidChanges: const Stream<String?>.empty(),
      clock: () => fakeNow,
    );

    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const Text('RUTE_ASLI'))],
    );

    final settingsBloc = _FakeSettingsBloc();
    whenListen(
      settingsBloc,
      const Stream<SettingsState>.empty(),
      initialState: const SettingsState.initial(),
    );
    final authBloc = _FakeAuthBloc();
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const Unauthenticated(),
    );
    final notificationBloc = _FakeNotificationBloc();
    whenListen(
      notificationBloc,
      const Stream<NotificationState>.empty(),
      initialState: const NotificationInitial(),
    );

    sl.registerLazySingleton<SettingsBloc>(() => settingsBloc);
    sl.registerLazySingleton<AuthBloc>(() => authBloc);
    sl.registerLazySingleton<NotificationBloc>(() => notificationBloc);
    sl.registerLazySingleton<GoRouter>(() => router);
    sl.registerLazySingleton<AppLockCubit>(() => cubit);
    sl.registerLazySingleton<SyncService>(() => _FakeSyncService());
    addTearDown(sl.reset);

    await tester.pumpWidget(const PenyintasApp());
    await tester.pumpAndSettle();

    // --- Fase 1: lock OFF → rute asli tampil, AppLockGate NYATA (dari
    // app.dart, bukan replika) sudah terpasang tapi transparan.
    expect(
      find.byType(AppLockGate),
      findsOneWidget,
      reason: 'AppLockGate harus terpasang lewat builder: di app.dart',
    );
    expect(
      find.descendant(
        of: find.byType(AppLockGate),
        matching: find.text('RUTE_ASLI'),
      ),
      findsOneWidget,
      reason: 'child hasil routerConfig WAJIB mengalir sbg child AppLockGate',
    );
    expect(find.byType(LockScreen), findsNothing);
    expect(find.byType(PrivacyShade), findsNothing);

    // Invariant Temuan 2: init() WAJIB terpanggil TEPAT SEKALI seumur proses.
    // AppLockCubit adalah singleton get_it; init() melakukan
    // `_uidSub = _uidChanges.listen(...)` tanpa cancel() sebelumnya — dipanggil
    // 2x akan menimpa subscription lama (kebocoran senyap + _reevaluate()
    // dobel). initState() PenyintasApp menjamin ini sekali (dijamin framework:
    // State.initState() tepat sekali seumur instance), TAPI tak ada test yang
    // menjaganya — bila kelak seseorang memindahkan init() balik ke
    // `BlocProvider(create: (_) => sl<AppLockCubit>()..init())` (yang bisa
    // terpanggil ulang, mis. tiap kali SettingsBloc emit lewat BlocBuilder di
    // atasnya), test lain tetap PASS tanpa assert ini. init() memanggil
    // repo.readConfig() PERSIS sekali di awal badannya — assert di sini SEBELUM
    // Fase 2 (yang men-trigger onSettingsChanged(), pemanggil readConfig()
    // kedua yang sah) supaya tak salah tangkap.
    verify(() => repo.readConfig()).called(1);

    // --- Fase 2: dorong cubit yang PERSIS sama (via sl singleton, tanpa
    // pernah memanggil init() lagi) melalui siklus "lock baru dinyalakan →
    // background >60 detik → resume" sampai ke AppLockLocked.
    when(() => repo.readConfig()).thenAnswer(
      (_) async => const AppLockConfig(
        enabled: true,
        hasPin: true,
        biometricEnabled: false,
        ownerUid: 'u1',
      ),
    );
    await cubit.onSettingsChanged();
    await tester.pump();
    cubit.onLifecycle(AppLifecycleState.paused);
    await tester.pump();
    await tester.pump();
    fakeNow = fakeNow.add(const Duration(seconds: 61));
    cubit.onLifecycle(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();

    expect(
      find.byType(LockScreen),
      findsOneWidget,
      reason:
          'AppLockCubit yang SAMA (via sl singleton) harus benar2 '
          'mengendalikan AppLockGate nyata dari app.dart — bukan cuma '
          'widget kosong yang tak terhubung ke provider manapun',
    );
    expect(
      find.descendant(
        of: find.byType(AppLockGate),
        matching: find.byType(LockScreen),
      ),
      findsOneWidget,
      reason:
          'LockScreen harus tampil DI DALAM AppLockGate yang sama, '
          'bukan di tempat lain di tree',
    );
  });
}
