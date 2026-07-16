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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppLockCubit, AppLockState>(
      builder: (context, state) {
        final showShade =
            state is AppLockUnknown ||
            (state is AppLockUnlocked && state.obscured);
        return Stack(
          children: [
            widget.child,
            if (showShade) const Positioned.fill(child: PrivacyShade()),
            if (state is AppLockLocked)
              const Positioned.fill(child: LockScreen()),
          ],
        );
      },
    );
  }
}
