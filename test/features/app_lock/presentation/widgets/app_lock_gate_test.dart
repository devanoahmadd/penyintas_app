// test/features/app_lock/presentation/widgets/app_lock_gate_test.dart
import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:penyintas_app/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:penyintas_app/features/app_lock/presentation/cubit/app_lock_cubit.dart';
import 'package:penyintas_app/features/app_lock/presentation/cubit/app_lock_state.dart';
import 'package:penyintas_app/features/app_lock/presentation/widgets/app_lock_gate.dart';
import 'package:penyintas_app/features/app_lock/presentation/widgets/lock_screen.dart';
import 'package:penyintas_app/features/app_lock/presentation/widgets/privacy_shade.dart';
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

  /// Router yang dibangun [pumpRouterWiring] — dipakai test tombol Back untuk
  /// mendorong/membaca lokasi rute di BAWAH gate.
  late GoRouter router;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
  });

  setUp(() {
    repo = _MockRepo();
    authBloc = _MockAuthBloc();
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

  /// Pump memakai WIRING PRODUKSI PERSIS: `MaterialApp.router` + `routerConfig:`
  /// + `builder: (c, ch) => AppLockGate(child: ch!)` — tiruan `lib/app.dart`.
  ///
  /// WAJIB dipakai untuk apa pun yang menyentuh Navigator/Overlay (dialog,
  /// tooltip). Helper `app()` di bawah memakai `MaterialApp(home: ...)`, yang
  /// menempatkan gate sebagai route DI DALAM Navigator — kebalikan total dari
  /// produksi, di mana `builder:` menerima Router sebagai CHILD-nya sehingga
  /// gate justru jadi ANCESTOR Navigator (lihat `app.dart:1721` di SDK).
  /// Akibatnya `showDialog`/`tooltip` yang HIJAU lewat `app()` bisa MELEDAK di
  /// produksi. Aturan: widget yang dipasang di `MaterialApp.builder` WAJIB
  /// diuji lewat `builder:`, BUKAN `home:`.
  Future<AppLockCubit> pumpRouterWiring(
    WidgetTester tester, {
    required bool enabled,
    bool biometric = false,
    String childLabel = 'KONTEN_RAHASIA',
  }) async {
    when(() => repo.readConfig()).thenAnswer(
      (_) async => AppLockConfig(
        enabled: enabled,
        hasPin: enabled,
        biometricEnabled: biometric,
        ownerUid: enabled ? 'u1' : null,
      ),
    );
    final cubit = AppLockCubit(
      repo: repo,
      currentUid: () => 'u1',
      uidChanges: uidCtrl.stream,
    );
    await cubit.init();
    // Rute '/detail' ada agar test tombol Back punya sesuatu untuk di-pop.
    router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => Text(childLabel)),
        GoRoute(path: '/detail', builder: (_, _) => const Text('DETAIL')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AppLockCubit>.value(value: cubit),
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: MaterialApp.router(
          localizationsDelegates: [_SyncL10nDelegate(l10n)],
          locale: const Locale('id'),
          routerConfig: router,
          builder: (context, child) =>
              AppLockGate(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  /// Pump normal — meng-init cubit (config resolve) lalu mem-build gate.
  /// Mengembalikan cubit agar test lanjutan bisa mendorong transisi state
  /// (submitPin/onLifecycle) tanpa menyentuh `emit` yang protected.
  Future<AppLockCubit> pump(
    WidgetTester tester, {
    required bool enabled,
    String? uid = 'u1',
  }) async {
    when(() => repo.readConfig()).thenAnswer(
      (_) async => AppLockConfig(
        enabled: enabled,
        hasPin: enabled,
        biometricEnabled: false,
        ownerUid: enabled ? 'u1' : null,
      ),
    );
    final cubit = AppLockCubit(
      repo: repo,
      currentUid: () => uid,
      uidChanges: uidCtrl.stream,
    );
    await cubit.init();
    await tester.pumpWidget(app(cubit));
    await tester.pump();
    return cubit;
  }

  testWidgets('AppLockDisabled → child terlihat, tak ada shade/LockScreen', (
    tester,
  ) async {
    await pump(tester, enabled: false);
    expect(find.text('KONTEN_RAHASIA'), findsOneWidget);
    expect(find.byType(PrivacyShade), findsNothing);
    expect(find.byType(LockScreen), findsNothing);
  });

  testWidgets('AppLockLocked → LockScreen tampil, bukan shade', (tester) async {
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
        repo: repo,
        currentUid: () => 'u1',
        uidChanges: uidCtrl.stream,
      );
      expect(cubit.state, isA<AppLockUnknown>()); // sanity precondition

      await tester.pumpWidget(app(cubit));
      await tester.pump();

      expect(find.byType(PrivacyShade), findsOneWidget);
      expect(find.byType(LockScreen), findsNothing);
    },
  );

  testWidgets(
    'AppLockUnlocked(obscured:false) → child terlihat, tak ada shade',
    (tester) async {
      final cubit = await pump(tester, enabled: true);
      await cubit.submitPin('123456'); // PIN benar (verifyPin di-stub true)
      await tester.pump();

      expect(cubit.state, isA<AppLockUnlocked>());
      expect((cubit.state as AppLockUnlocked).obscured, isFalse);
      expect(find.text('KONTEN_RAHASIA'), findsOneWidget);
      expect(find.byType(PrivacyShade), findsNothing);
      expect(find.byType(LockScreen), findsNothing);
    },
  );

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
    },
  );

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
        repo: repo,
        currentUid: () => 'u1',
        uidChanges: uidCtrl.stream,
      );
      await tester.pumpWidget(app(cubit));
      await tester.pump();

      final shadeSize = tester.getSize(find.byType(PrivacyShade));
      expect(shadeSize, const Size(400, 800));
    },
  );

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
    },
  );

  testWidgets('Urutan Stack: widget.child di BAWAH PrivacyShade (bukan sekadar '
      'sama-sama ada di tree)', (tester) async {
    // Ketujuh test di atas semua pakai find.byType/find.text — itu cuma
    // membuktikan widget ADA di element tree, bukan bahwa ia digambar DI
    // ATAS child. Bila urutan children Stack dibalik jadi
    // [shade, child] (mis. saat "merapikan" kode), ketujuh test itu tetap
    // HIJAU (semua widget tetap "ada"), padahal secara visual konten
    // finansial akan tergambar DI ATAS shade — kebocoran privasi yang
    // justru ingin dicegah fitur ini. Test ini memeriksa INDEX children
    // Stack secara eksplisit, bukan cuma keberadaannya.
    final cubit = AppLockCubit(
      repo: repo,
      currentUid: () => 'u1',
      uidChanges: uidCtrl.stream,
    );
    await tester.pumpWidget(app(cubit)); // AppLockUnknown → shade aktif
    await tester.pump();

    final stackFinder = find.descendant(
      of: find.byType(AppLockGate),
      matching: find.byType(Stack),
    );
    expect(stackFinder, findsOneWidget);
    final stack = tester.widget<Stack>(stackFinder);

    // `w.child is Text`: widget.child kini dibungkus ExcludeSemantics (agar
    // screen reader tak menembus shade) — yang dijaga test ini URUTAN-nya.
    final childIndex = stack.children.indexWhere(
      (w) => w is ExcludeSemantics && w.child is Text,
    );
    final shadeIndex = stack.children.indexWhere(
      (w) => w is Positioned && w.child is PrivacyShade,
    );

    expect(
      childIndex,
      isNot(-1),
      reason: 'widget.child tak ditemukan di Stack.children',
    );
    expect(
      shadeIndex,
      isNot(-1),
      reason: 'PrivacyShade tak ditemukan di Stack.children',
    );
    expect(
      childIndex,
      lessThan(shadeIndex),
      reason:
          'widget.child WAJIB digambar sebelum (di bawah) '
          'PrivacyShade, kalau tidak konten finansial tembus di atas '
          'shade',
    );
  });

  testWidgets('Urutan Stack: widget.child di BAWAH LockScreen (bukan sekadar '
      'sama-sama ada di tree)', (tester) async {
    await pump(tester, enabled: true); // AppLockLocked

    final stackFinder = find.descendant(
      of: find.byType(AppLockGate),
      matching: find.byType(Stack),
    );
    expect(stackFinder, findsOneWidget);
    final stack = tester.widget<Stack>(stackFinder);

    final childIndex = stack.children.indexWhere(
      (w) => w is ExcludeSemantics && w.child is Text,
    );
    // Dicocokkan lewat key, bukan `w.child is LockScreen`: overlay lock kini
    // dibungkus HeroControllerScope → Navigator → MaterialPageRoute (agar
    // showDialog & tooltip punya Navigator/Overlay), jadi LockScreen tak lagi
    // jadi child langsung Positioned. Yang dijaga test ini adalah URUTAN-nya.
    final lockIndex = stack.children.indexWhere(
      (w) => w is Positioned && w.key == AppLockGate.lockOverlayKey,
    );

    expect(
      childIndex,
      isNot(-1),
      reason: 'widget.child tak ditemukan di Stack.children',
    );
    expect(
      lockIndex,
      isNot(-1),
      reason: 'LockScreen tak ditemukan di Stack.children',
    );
    expect(
      childIndex,
      lessThan(lockIndex),
      reason:
          'widget.child WAJIB digambar sebelum (di bawah) '
          'LockScreen, kalau tidak konten finansial tembus di atas '
          'lock screen',
    );
  });

  // --- Wiring produksi (MaterialApp.router + builder:) ---------------------
  // Ketiga test di bawah menutup celah yang meloloskan Critical "Lupa PIN?
  // mati": Task 11 menguji LockScreen sendirian (via `home:` = DI DALAM
  // Navigator), Task 15 menguji wiring tapi tak pernah menyentuh dialog /
  // tooltip. Tak ada yang menguji IRISANNYA — dan justru di irisan itulah
  // bug-nya hidup.

  testWidgets(
    'wiring produksi: tap "Lupa PIN?" → dialog SUNGGUH muncul → konfirmasi '
    'memicu disableLock + SignOutRequested',
    (tester) async {
      when(() => repo.disableLock()).thenAnswer((_) async {});
      await pumpRouterWiring(tester, enabled: true);
      expect(find.byType(LockScreen), findsOneWidget); // sanity: mulai Locked

      await tester.tap(find.text(l10n.applockForgot));
      await tester.pumpAndSettle();

      // Inti Critical: tanpa Navigator milik gate, showDialog() melempar
      // "Navigator operation requested with a context that does not include a
      // Navigator" dan dialog TAK PERNAH muncul — user yang lupa PIN terkunci
      // permanen (pulih hanya lewat reinstall/clear-data). Ini satu-satunya
      // escape hatch, sekaligus yang diandalkan mitigasi fail-closed init().
      expect(
        find.text(l10n.applockForgotDialogTitle),
        findsOneWidget,
        reason:
            'dialog "Lupa PIN?" WAJIB benar-benar terender di wiring '
            'produksi — gate berada di ATAS Navigator app, jadi gate '
            'HARUS menyediakan Navigator-nya sendiri',
      );

      await tester.tap(find.text(l10n.applockForgotConfirm));
      await tester.pumpAndSettle();

      verify(() => repo.disableLock()).called(1);
      verify(() => authBloc.add(const SignOutRequested())).called(1);
    },
  );

  testWidgets(
    'wiring produksi: biometrik tersedia → tombol sidik jari SUNGGUH terender '
    '(bukan ErrorWidget karena Overlay hilang)',
    (tester) async {
      when(
        () => repo.authenticateBiometric(any()),
      ).thenAnswer((_) async => false);
      when(() => repo.isBiometricAvailable()).thenAnswer((_) async => true);
      await pumpRouterWiring(tester, enabled: true, biometric: true);

      // `IconButton(tooltip: ...)` butuh Overlay ancestor. Tanpa Navigator
      // milik gate, `debugCheckHasOverlay` di build() gagal → subtree
      // IconButton diganti ErrorWidget (kotak merah / tombol hilang) di debug,
      // dan long-press melempar di release. Efeknya: user biometrik kehilangan
      // tombol retry-nya.
      expect(
        find.byIcon(Icons.fingerprint),
        findsOneWidget,
        reason:
            'tombol retry biometrik WAJIB terender di wiring produksi — '
            'tooltip-nya menuntut Overlay yang hanya ada bila gate '
            'menyediakan Navigator sendiri',
      );
      expect(
        find.byType(ErrorWidget),
        findsNothing,
        reason: 'tak boleh ada ErrorWidget menggantikan subtree manapun',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AppLockLocked → semantics child DIKECUALIKAN (screen reader tak boleh '
    'membacakan konten finansial di balik lock)',
    (tester) async {
      // dispose() eksplisit di akhir badan test, BUKAN addTearDown:
      // _endOfTestVerifications berjalan SEBELUM tearDown, jadi handle yang
      // baru dilepas di tearDown tetap dianggap bocor dan test gagal.
      final handle = tester.ensureSemantics();

      await pumpRouterWiring(
        tester,
        enabled: true,
        childLabel: 'SALDO_RP_9_JUTA',
      );
      expect(find.byType(LockScreen), findsOneWidget); // sanity: mulai Locked

      // Hit-test sudah aman (Material bertipe canvas menyerap tap), TAPI
      // semantics menembus: Stack tak mengecualikan semantics child, jadi
      // TalkBack/VoiceOver tetap membacakan saldo & transaksi di balik lock
      // screen — kebocoran privasi yang tak terlihat mata.
      expect(
        find.bySemanticsLabel('SALDO_RP_9_JUTA'),
        findsNothing,
        reason:
            'konten finansial di balik lock WAJIB tak terjangkau screen '
            'reader saat state Locked',
      );

      handle.dispose();
    },
  );

  testWidgets(
    'AppLockLocked → tombol Back sistem DITELAN (tak mem-pop rute di bawah '
    'lock)',
    (tester) async {
      await pumpRouterWiring(tester, enabled: true);
      router.push('/detail');
      await tester.pumpAndSettle();
      expect(router.state.uri.toString(), '/detail'); // prasyarat
      expect(find.byType(LockScreen), findsOneWidget);

      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Tanpa didPopRoute di gate, Back menembus ke GoRouter dan mem-pop
      // /detail → / DI BALIK lock screen: user terkunci tapi tetap bisa
      // menavigasi app secara buta. PopScope di Navigator milik gate TIDAK
      // menutup ini (Navigator itu di luar rantai dispatch Back) — sudah
      // dibuktikan lewat probe.
      expect(
        handled,
        isTrue,
        reason:
            'Back WAJIB dianggap tertangani saat locked — bila false, '
            'Android malah menutup aplikasi',
      );
      expect(
        router.state.uri.toString(),
        '/detail',
        reason: 'rute di bawah lock TIDAK boleh ikut ter-pop',
      );
      expect(find.byType(LockScreen), findsOneWidget);
    },
  );

  testWidgets(
    'AppLockDisabled → tombol Back sistem TETAP diteruskan (gate tak boleh '
    'menelan Back saat tak terkunci)',
    (tester) async {
      // Sisi lain koin: gate yang menelan Back tanpa syarat akan mematikan
      // navigasi Back seluruh aplikasi — regresi jauh lebih parah daripada
      // Minor yang diperbaiki. Guard `state is AppLockLocked` dikunci di sini.
      await pumpRouterWiring(tester, enabled: false);
      router.push('/detail');
      await tester.pumpAndSettle();
      expect(router.state.uri.toString(), '/detail'); // prasyarat

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(
        router.state.uri.toString(),
        '/',
        reason:
            'saat lock mati, Back WAJIB mem-pop rute seperti biasa — gate '
            'harus transparan',
      );
    },
  );
}
