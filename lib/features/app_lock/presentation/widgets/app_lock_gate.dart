import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/features/app_lock/presentation/cubit/app_lock_cubit.dart';
import 'package:penyintas_app/features/app_lock/presentation/cubit/app_lock_state.dart';
import 'package:penyintas_app/features/app_lock/presentation/widgets/lock_screen.dart';
import 'package:penyintas_app/features/app_lock/presentation/widgets/privacy_shade.dart';

/// Overlay lock di atas seluruh route — dipasang di `MaterialApp.router`
/// `builder:` (Task 15), BUKAN sebagai route tersendiri. Meneruskan
/// lifecycle app ke [AppLockCubit] (single source of truth) dan memetakan
/// state cubit ke tampilan:
///
/// - [AppLockUnknown] → [PrivacyShade] (fail-closed: ragu = sembunyikan).
/// - [AppLockDisabled] → child (lock mati, app normal).
/// - [AppLockUnlocked] dengan `obscured: true` → [PrivacyShade]; `false` → child.
/// - [AppLockLocked] → [LockScreen].
///
/// [PrivacyShade] dan [LockScreen] dibungkus `Positioned.fill` karena
/// keduanya tidak memaksa ukurannya sendiri — tanpa ini, constraints
/// longgar dari Stack bisa membuat keduanya mengecil ke ukuran intrinsik,
/// menyisakan celah di tepi layar yang membocorkan konten finansial di
/// baliknya. `LockScreen` hanya ada di tree selama state == Locked; begitu
/// state berpindah, `if` di Stack meng-unmount-nya total (bukan sekadar
/// menyembunyikan) — WAJIB, karena `LockScreen` memakai
/// `buildWhen: (_, s) => s is AppLockLocked` sehingga tak akan rebuild
/// sendiri saat state pindah ke Unlocked selama masih ter-mount.
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  /// Penanda `Positioned` pembungkus overlay lock di `Stack`. Dipakai test
  /// urutan Stack agar assert-nya tak rapuh terhadap perubahan struktur
  /// internal overlay (kini `HeroControllerScope` → `Navigator` → route,
  /// bukan lagi `LockScreen` telanjang).
  static const lockOverlayKey = ValueKey<String>('app_lock_gate_lock_overlay');

  /// Konten aplikasi asli (root router/navigator).
  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    context.read<AppLockCubit>().onLifecycle(state);
  }

  /// Menelan tombol Back sistem selama terkunci.
  ///
  /// `PopScope` di dalam Navigator milik gate TIDAK bisa dipakai di sini —
  /// sudah dibuktikan lewat probe: Navigator itu bukan bagian dari rantai
  /// dispatch Back (`RootBackButtonDispatcher` → `Router` → GoRouter), jadi
  /// PopScope-nya tak pernah dikonsultasi dan Back tetap mem-pop rute DI BAWAH
  /// lock screen (lock tetap tampil — bukan kebocoran visual, tapi navigasi
  /// diam-diam terjadi di balik lock).
  ///
  /// `didPopRoute` observer inilah rantai yang benar: `handlePopRoute`
  /// menelusuri observer secara MAJU dan berhenti di yang pertama mengembalikan
  /// `true`. Gate ter-register lebih dulu daripada `RootBackButtonDispatcher`
  /// (gate adalah PARENT `Router` di tree, `initState` parent jalan lebih dulu),
  /// jadi gate menang. Urutan itu detail implementasi — dikunci test regresi.
  @override
  Future<bool> didPopRoute() async {
    if (!mounted) return false;
    return context.read<AppLockCubit>().state is AppLockLocked;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppLockCubit, AppLockState>(
      builder: (context, state) {
        final showShade =
            state is AppLockUnknown ||
            (state is AppLockUnlocked && state.obscured);
        final covered = showShade || state is AppLockLocked;
        return Stack(
          children: [
            // Menutupi child secara visual saja TIDAK cukup: tanpa
            // ExcludeSemantics, screen reader (TalkBack/VoiceOver) tetap
            // menelusuri & membacakan saldo/transaksi di balik shade maupun
            // lock screen — kebocoran privasi yang tak kasat mata. (Hit-test
            // sendiri sudah aman: `Material` bertipe canvas milik shade &
            // LockScreen menyerap tap.)
            ExcludeSemantics(excluding: covered, child: widget.child),
            if (showShade) const Positioned.fill(child: PrivacyShade()),
            if (state is AppLockLocked)
              Positioned.fill(
                key: AppLockGate.lockOverlayKey,
                // Navigator SENDIRI — bukan sekadar hiasan. Gate ini dipasang
                // di `MaterialApp.router` `builder:`, yang menerima Router
                // sebagai CHILD-nya (SDK app.dart:1721) — jadi gate adalah
                // ANCESTOR Navigator app, bukan keturunannya. Tanpa Navigator
                // lokal ini: `showDialog` di "Lupa PIN?" melempar "Navigator
                // operation requested with a context that does not include a
                // Navigator" (escape hatch satu-satunya MATI → user lupa PIN
                // terkunci permanen), dan `IconButton(tooltip:)` gagal
                // `debugCheckHasOverlay` → tombol biometrik jadi ErrorWidget.
                // Satu `Navigator` menyediakan Navigator + Overlay sekaligus,
                // menutup keduanya.
                //
                // JANGAN diganti `sl<GoRouter>().navigatorKey.currentContext`:
                // dialog akan terender di dalam Navigator app = DI BAWAH
                // LockScreen dalam Stack ini → tak terlihat.
                child: HeroControllerScope.none(
                  // WAJIB: MaterialApp memasang satu HeroController lewat
                  // HeroControllerScope. Navigator app & Navigator ini
                  // sama-sama hidup saat locked; bila keduanya mengklaim
                  // controller yang sama, Flutter melempar "A HeroController
                  // can not be shared by multiple Navigators".
                  child: Navigator(
                    onGenerateRoute: (_) => MaterialPageRoute<void>(
                      builder: (_) => const LockScreen(),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
