import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:penyintas_app/features/auth/presentation/cubit/email_verification_cubit.dart';

/// B4: banner soft verifikasi email — tampil hanya untuk akun email/password
/// yang belum verified. Tidak bisa di-dismiss; hilang sendiri begitu status
/// verified terbaca (reload saat mount / app resume).
class EmailVerificationBanner extends StatelessWidget {
  const EmailVerificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<EmailVerificationCubit>(),
      child: const _EmailVerificationBannerBody(),
    );
  }
}

class _EmailVerificationBannerBody extends StatefulWidget {
  const _EmailVerificationBannerBody();

  @override
  State<_EmailVerificationBannerBody> createState() =>
      _EmailVerificationBannerBodyState();
}

class _EmailVerificationBannerBodyState
    extends State<_EmailVerificationBannerBody> with WidgetsBindingObserver {
  static const _cooldownSeconds = 60;

  int _cooldownLeft = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Cold start: status verified di cache FirebaseAuth bisa basi (user
    // verifikasi saat app tertutup) — reload sekali saat banner relevan.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeRequestReload();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh status verified saat user kembali dari app email.
    if (state == AppLifecycleState.resumed && mounted) _maybeRequestReload();
  }

  /// Reload HANYA saat banner relevan — user verified/Google tidak perlu
  /// membayar `user.reload()` + baca Firestore tiap resume.
  void _maybeRequestReload() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated &&
        authState.user.hasPasswordProvider &&
        !authState.user.emailVerified) {
      context.read<AuthBloc>().add(const AuthUserReloadRequested());
    }
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldownLeft = _cooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldownLeft -= 1);
      if (_cooldownLeft <= 0) timer.cancel();
    });
  }

  void _onResend(BuildContext context) {
    context.read<EmailVerificationCubit>().resend(
          languageCode: Localizations.localeOf(context).languageCode,
        );
    // Cooldown mulai saat tap apa pun hasilnya — anti-spam tetap jalan;
    // feedback jujur menyusul lewat BlocListener cubit di build.
    _startCooldown();
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EmailVerificationCubit, EmailVerificationState>(
      listenWhen: (prev, curr) =>
          curr is EmailVerificationSent || curr is EmailVerificationFailed,
      listener: (context, verifState) {
        final message = verifState is EmailVerificationFailed
            ? verifState.message
            : context.l10n.authVerifyResent;
        _showSnackBar(context, message);
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! Authenticated ||
              !state.user.hasPasswordProvider ||
              state.user.emailVerified) {
            return const SizedBox.shrink();
          }

          final l10n = context.l10n;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final surface =
              isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
          final border =
              isDark ? AppColors.borderDark : AppColors.borderLight;
          final textColor =
              isDark ? AppColors.textDark : AppColors.textLight;
          final textSoft =
              isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
          final inCooldown = _cooldownLeft > 0;

          return Container(
            margin: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.mark_email_unread_outlined,
                    color: AppColors.caution, size: 20),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.authVerifyBannerTitle,
                        style:
                            AppTextStyles.label.copyWith(color: textColor),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.authVerifyBannerBody,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: textSoft),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed:
                            inCooldown ? null : () => _onResend(context),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          inCooldown
                              ? l10n.authVerifyResendWait(_cooldownLeft)
                              : l10n.authVerifyResendCta,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: inCooldown
                                ? (isDark
                                    ? AppColors.mutedDark
                                    : AppColors.mutedLight)
                                : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
