// test/features/app_lock/presentation/widgets/app_lock_gate_test.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:penyintas_app/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:penyintas_app/features/app_lock/presentation/cubit/app_lock_cubit.dart';
import 'package:penyintas_app/features/app_lock/presentation/cubit/app_lock_state.dart';
import 'package:penyintas_app/features/app_lock/presentation/widgets/app_lock_gate.dart';
import 'package:penyintas_app/features/app_lock/presentation/widgets/lock_screen.dart';
import 'package:penyintas_app/features/app_lock/presentation/widgets/privacy_shade.dart';

class _MockRepo extends Mock implements AppLockRepository {}

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

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
  });

  setUp(() {
    repo = _MockRepo();
    uidCtrl = StreamController<String?>.broadcast();
    when(() => repo.isBiometricAvailable()).thenAnswer((_) async => false);
    when(() => repo.getFailedAttempts()).thenAnswer((_) async => 0);
    when(() => repo.getLockedUntilMs()).thenAnswer((_) async => 0);
    when(() => repo.verifyPin(any())).thenAnswer((_) async => true);
    when(() => repo.resetFailedAttempts()).thenAnswer((_) async {});
  });

  tearDown(() => uidCtrl.close());

  Widget app(AppLockCubit cubit) => BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          localizationsDelegates: [_SyncL10nDelegate(l10n)],
          locale: const Locale('id'),
          home: AppLockGate(child: const Text('KONTEN_RAHASIA')),
        ),
      );

  /// Pump normal — meng-init cubit (config resolve) lalu mem-build gate.
  /// Mengembalikan cubit agar test lanjutan bisa mendorong transisi state
  /// (submitPin/onLifecycle) tanpa menyentuh `emit` yang protected.
  Future<AppLockCubit> pump(
    WidgetTester tester, {
    required bool enabled,
    String? uid = 'u1',
  }) async {
    when(() => repo.readConfig()).thenAnswer((_) async => AppLockConfig(
        enabled: enabled,
        hasPin: enabled,
        biometricEnabled: false,
        ownerUid: enabled ? 'u1' : null));
    final cubit = AppLockCubit(
        repo: repo, currentUid: () => uid, uidChanges: uidCtrl.stream);
    await cubit.init();
    await tester.pumpWidget(app(cubit));
    await tester.pump();
    return cubit;
  }

  testWidgets('AppLockDisabled → child terlihat, tak ada shade/LockScreen',
      (tester) async {
    await pump(tester, enabled: false);
    expect(find.text('KONTEN_RAHASIA'), findsOneWidget);
    expect(find.byType(PrivacyShade), findsNothing);
    expect(find.byType(LockScreen), findsNothing);
  });

  testWidgets('AppLockLocked → LockScreen tampil, bukan shade',
      (tester) async {
    await pump(tester, enabled: true);
    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.text(l10n.applockEnterTitle), findsOneWidget);
    expect(find.byType(PrivacyShade), findsNothing);
  });

  testWidgets(
      'AppLockUnknown (belum init/cold start) → shade tampil, fail-closed',
      (tester) async {
    // Cubit SENGAJA tidak di-init(): constructor start di AppLockUnknown,
    // meniru jendela singkat sebelum readConfig() resolve saat cold start.
    // Regresi kritis bila ini jadi child: saldo/transaksi bocor di frame
    // pertama tiap kali app dibuka.
    final cubit = AppLockCubit(
        repo: repo, currentUid: () => 'u1', uidChanges: uidCtrl.stream);
    expect(cubit.state, isA<AppLockUnknown>()); // sanity precondition

    await tester.pumpWidget(app(cubit));
    await tester.pump();

    expect(find.byType(PrivacyShade), findsOneWidget);
    expect(find.byType(LockScreen), findsNothing);
  });

  testWidgets('AppLockUnlocked(obscured:false) → child terlihat, tak ada shade',
      (tester) async {
    final cubit = await pump(tester, enabled: true);
    await cubit.submitPin('123456'); // PIN benar (verifyPin di-stub true)
    await tester.pump();

    expect(cubit.state, isA<AppLockUnlocked>());
    expect((cubit.state as AppLockUnlocked).obscured, isFalse);
    expect(find.text('KONTEN_RAHASIA'), findsOneWidget);
    expect(find.byType(PrivacyShade), findsNothing);
    expect(find.byType(LockScreen), findsNothing);
  });

  testWidgets(
      'AppLockUnlocked(obscured:true) → shade tampil (background sekilas)',
      (tester) async {
    final cubit = await pump(tester, enabled: true);
    await cubit.submitPin('123456');
    await tester.pump();
    cubit.onLifecycle(AppLifecycleState.paused); // background sungguhan
    // WAJIB 2× pump di sini (bukan typo): onLifecycle dipanggil sinkron di
    // luar siklus build widget, jadi listener BlocBuilder baru terjadwal
    // lewat microtask — pump #1 mengalirkan microtask itu (memicu
    // setState), pump #2 baru benar-benar membangun ulang frame dengan
    // state terbaru. Dibuktikan lewat percobaan manual: dengan 1 pump,
    // shade masih 0 widget; baru muncul di pump ke-2.
    await tester.pump();
    await tester.pump();

    expect(cubit.state, isA<AppLockUnlocked>());
    expect((cubit.state as AppLockUnlocked).obscured, isTrue);
    expect(find.byType(PrivacyShade), findsOneWidget);
    expect(find.byType(LockScreen), findsNothing);
  });

  testWidgets(
      'PrivacyShade menutup seluruh layar tanpa celah (cakupan fail-closed)',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // State Unknown dipilih karena inilah shade fail-closed paling kritis;
    // bila gate memberi constraints longgar (bukan Positioned.fill/setara),
    // shade bisa mengecil ke ukuran intrinsik logonya saja — celah di tepi
    // membocorkan KONTEN_RAHASIA di baliknya.
    final cubit = AppLockCubit(
        repo: repo, currentUid: () => 'u1', uidChanges: uidCtrl.stream);
    await tester.pumpWidget(app(cubit));
    await tester.pump();

    final shadeSize = tester.getSize(find.byType(PrivacyShade));
    expect(shadeSize, const Size(400, 800));
  });

  testWidgets(
      'LockScreen ter-unmount total saat Locked → Unlocked, tanpa frame basi',
      (tester) async {
    final cubit = await pump(tester, enabled: true);
    expect(find.byType(LockScreen), findsOneWidget); // sanity: mulai Locked

    await cubit.submitPin('123456');
    await tester.pump();

    // WAJIB findsNothing (bukan sekadar "child ikut terlihat") — LockScreen
    // memakai buildWhen: (_, s) => s is AppLockLocked, jadi bila gate hanya
    // menumpuk child DI ATAS LockScreen (tanpa meng-unmount-nya), widget ini
    // tetap hidup di tree merender snapshot Locked terakhir walau sudah tak
    // terlihat — regresi senyap yang lolos assert visual biasa.
    expect(find.byType(LockScreen), findsNothing);
    expect(find.text(l10n.applockEnterTitle), findsNothing);
    expect(find.text('KONTEN_RAHASIA'), findsOneWidget);
  });
}
