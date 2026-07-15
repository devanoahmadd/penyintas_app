import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/features/app_lock/presentation/cubit/app_lock_cubit.dart';
import 'package:penyintas_app/features/app_lock/presentation/cubit/app_lock_state.dart';
import 'package:penyintas_app/features/app_lock/presentation/widgets/pin_dots.dart';
import 'package:penyintas_app/features/app_lock/presentation/widgets/pin_keypad.dart';
import 'package:penyintas_app/features/auth/presentation/bloc/auth_bloc.dart';

/// Layar yang dilihat user saat App Lock terkunci — PIN pad, retry
/// biometrik, dan jalan keluar "Lupa PIN?" (yang menonaktifkan lock lalu
/// sign-out, karena tanpa PIN yang diingat tak ada cara lain memverifikasi
/// pemilik akun).
///
/// Dibaca gate (mis. `AppLockGate`, di luar scope task ini) saat
/// `AppLockCubit` berada di state [AppLockLocked].
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  bool _autoBioTried = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Auto-prompt biometrik sekali saat layar muncul, bila tersedia.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AppLockCubit>().state;
      if (!_autoBioTried && state is AppLockLocked && state.biometricAvailable) {
        _autoBioTried = true;
        context
            .read<AppLockCubit>()
            .tryBiometric(context.l10n.applockBiometricReason);
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  /// `lockedUntilMs` adalah timestamp epoch MENTAH dan PASIF dari repository
  /// — repository tak pernah membersihkannya sendiri, jadi setelah jeda
  /// kedaluwarsa nilainya tetap ada tapi sudah lampau. WAJIB dibandingkan
  /// terhadap waktu sekarang (bukan `!= 0`), dan hasilnya di-clamp ke
  /// minimum 0 — kalau tidak, countdown tersangkut negatif dan keypad tak
  /// pernah aktif lagi.
  int _remainingSeconds(int lockedUntilMs) {
    final delta = lockedUntilMs - DateTime.now().millisecondsSinceEpoch;
    return delta > 0 ? (delta / 1000).ceil() : 0;
  }

  void _ensureTicking(int lockedUntilMs) {
    if (_remainingSeconds(lockedUntilMs) > 0 && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {});
        if (_remainingSeconds(lockedUntilMs) == 0) {
          _tick?.cancel();
          _tick = null;
        }
      });
    }
  }

  void _onDigit(String d, int lockedSeconds) {
    if (lockedSeconds > 0 || _pin.length >= 6) return;
    setState(() => _pin += d);
    if (_pin.length == 6) {
      final pin = _pin;
      _pin = '';
      context.read<AppLockCubit>().submitPin(pin);
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _onForgot() async {
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.applockForgotDialogTitle),
        content: Text(l.applockForgotDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.btnCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.applockForgotConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AppLockCubit>().forgotPin();
    if (!mounted) return;
    context.read<AuthBloc>().add(const SignOutRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final accent = isDark ? AppColors.shoot : AppColors.primary;

    return BlocBuilder<AppLockCubit, AppLockState>(
      buildWhen: (_, s) => s is AppLockLocked,
      builder: (context, state) {
        final locked = state is AppLockLocked ? state : const AppLockLocked();
        final seconds = _remainingSeconds(locked.lockedUntilMs);
        _ensureTicking(locked.lockedUntilMs);
        return Material(
          color: bg,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: AppSpacing.xxl, color: accent),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l.applockEnterTitle,
                    style: AppTextStyles.h2.copyWith(color: textColor),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PinDots(length: 6, filled: _pin.length),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: AppSpacing.xl,
                    child: Center(
                      child: seconds > 0
                          ? Text(
                              l.applockLockedWait(seconds),
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.warn),
                            )
                          : (locked.failedAttempts > 0
                              ? Text(
                                  l.applockWrong,
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.warn),
                                )
                              : const SizedBox.shrink()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PinKeypad(
                    enabled: seconds == 0,
                    onDigit: (d) => _onDigit(d, seconds),
                    onBackspace: _onBackspace,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: AppSpacing.huge,
                    child: locked.biometricAvailable
                        ? IconButton(
                            // Retry manual — auto-prompt hanya sekali per
                            // mount; user yang cancel prompt biometrik tak
                            // boleh dipaksa menunggu, harus bisa coba lagi.
                            onPressed: seconds == 0
                                ? () => context
                                    .read<AppLockCubit>()
                                    .tryBiometric(l.applockBiometricReason)
                                : null,
                            iconSize: AppSpacing.xxl,
                            icon: Icon(Icons.fingerprint, color: textColor),
                            tooltip: l.applockBiometricTitle,
                          )
                        : null,
                  ),
                  TextButton(
                    // Selalu aktif walau keypad terkunci — "Lupa PIN?" adalah
                    // satu-satunya jalan keluar bagi user tanpa biometrik;
                    // kalau ikut mati saat lockout, user terkunci total.
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, AppSpacing.xxxl),
                    ),
                    onPressed: _onForgot,
                    child: Text(
                      l.applockForgot,
                      style: AppTextStyles.label.copyWith(color: muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
