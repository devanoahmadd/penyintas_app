import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/auth_validators.dart';
import 'package:penyintas_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:penyintas_app/widgets/common/app_text_field.dart';
import 'package:penyintas_app/widgets/common/penyintas_logo.dart';
import 'package:penyintas_app/widgets/common/primary_button.dart';

// Flip ke true saat google_sign_in package terintegrasi untuk free users.
const _googleSignInEnabled = false;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  bool _nameValid = false;
  bool _emailValid = false;
  bool _passwordValid = false;
  bool _confirmValid = false;

  static RegExp get _emailRegex => AuthValidators.emailRegex;

  late final AnimationController _anim;
  late final Animation<double> _fadeHeader;
  late final Animation<Offset> _slideHeader;
  late final Animation<double> _fadeBody;
  late final Animation<Offset> _slideBody;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeHeader = CurvedAnimation(
      parent: _anim,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );
    _slideHeader = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _anim,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    ));
    _fadeBody = CurvedAnimation(
      parent: _anim,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );
    _slideBody = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _anim,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _validate(BuildContext context) {
    final l10n = context.l10n;
    bool valid = true;
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmError = null;

      if (_nameController.text.trim().length < 2) {
        _nameError = l10n.errorNameMin;
        valid = false;
      }
      if (!_emailValid) {
        _emailError = l10n.errorEmailInvalid;
        valid = false;
      }
      if (_passwordController.text.length < 8) {
        _passwordError = l10n.errorPasswordMin;
        valid = false;
      }
      final confirmOk = _confirmController.text.isNotEmpty &&
          _confirmController.text == _passwordController.text;
      if (!confirmOk) {
        _confirmError = l10n.errorConfirmMismatch;
        valid = false;
      }
    });
    return valid;
  }

  void _submit(BuildContext context) {
    if (!_validate(context)) return;
    context.read<AuthBloc>().add(SignUpRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
        ));
  }

  SnackBar _buildErrorSnackBar(String message, bool isDark) {
    return SnackBar(
      content: Row(
        children: [
          Icon(Icons.warning_rounded, color: AppColors.warn, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final textSoftColor =
        isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final iconColor = isDark ? AppColors.textSoftDark : AppColors.textSoftLight;

    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (_, state) => state is AuthError,
      listener: (ctx, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(ctx)
            ..hideCurrentSnackBar()
            ..showSnackBar(_buildErrorSnackBar(state.message, isDark));
        }
      },
      buildWhen: (_, state) =>
          state is AuthLoading ||
          state is Unauthenticated ||
          state is AuthError,
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final l10n = context.l10n;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: iconColor,
                size: 20,
              ),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/login'),
              tooltip: 'Kembali',
            ),
          ),
          body: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Scrollable content ──────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: logo + heading + subtitle
                        FadeTransition(
                          opacity: _fadeHeader,
                          child: SlideTransition(
                            position: _slideHeader,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const PenyintasLogo(size: 48),
                                const SizedBox(height: AppSpacing.xxl),
                                Text(
                                  l10n.authRegisterTitle,
                                  style: AppTextStyles.h1.copyWith(
                                    color: textColor,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  l10n.authRegisterSubtitle,
                                  style: AppTextStyles.body
                                      .copyWith(color: textSoftColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        // Form
                        FadeTransition(
                          opacity: _fadeBody,
                          child: SlideTransition(
                            position: _slideBody,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppTextField(
                                  controller: _nameController,
                                  label: l10n.authNameLabel,
                                  hintText: l10n.authNameHint,
                                  errorText: _nameError,
                                  isValid: _nameValid,
                                  enabled: !isLoading,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (value) {
                                    final valid =
                                        value.trim().length >= 2;
                                    if (valid != _nameValid) {
                                      setState(() => _nameValid = valid);
                                    }
                                    if (_nameError != null && valid) {
                                      setState(() => _nameError = null);
                                    }
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppTextField(
                                  controller: _emailController,
                                  label: l10n.authEmailLabel,
                                  hintText: l10n.authEmailHint,
                                  errorText: _emailError,
                                  isValid: _emailValid,
                                  enabled: !isLoading,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (value) {
                                    final valid =
                                        _emailRegex.hasMatch(value.trim());
                                    if (valid != _emailValid) {
                                      setState(() => _emailValid = valid);
                                    }
                                    if (_emailError != null && valid) {
                                      setState(() => _emailError = null);
                                    }
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppTextField(
                                  controller: _passwordController,
                                  label: l10n.authPasswordLabel,
                                  hintText: l10n.authPasswordHintReg,
                                  helperText: 'Minimal 8 karakter',
                                  errorText: _passwordError,
                                  isValid: _passwordValid,
                                  isPassword: true,
                                  enabled: !isLoading,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (value) {
                                    final pwValid = value.length >= 8;
                                    if (pwValid != _passwordValid) {
                                      setState(() => _passwordValid = pwValid);
                                    }
                                    if (_passwordError != null && pwValid) {
                                      setState(() => _passwordError = null);
                                    }
                                    // Sinkronkan _confirmValid saat password berubah
                                    final confirmNowValid =
                                        _confirmController.text.isNotEmpty &&
                                            _confirmController.text == value;
                                    if (confirmNowValid != _confirmValid) {
                                      setState(
                                          () => _confirmValid = confirmNowValid);
                                    }
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppTextField(
                                  controller: _confirmController,
                                  label: l10n.authConfirmLabel,
                                  hintText: l10n.authConfirmHint,
                                  errorText: _confirmError,
                                  isValid: _confirmValid,
                                  isPassword: true,
                                  enabled: !isLoading,
                                  textInputAction: TextInputAction.done,
                                  onChanged: (value) {
                                    final valid = value.isNotEmpty &&
                                        value == _passwordController.text;
                                    if (valid != _confirmValid) {
                                      setState(() => _confirmValid = valid);
                                    }
                                    if (_confirmError != null && valid) {
                                      setState(() => _confirmError = null);
                                    }
                                  },
                                  onSubmitted: isLoading
                                      ? null
                                      : (_) => _submit(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Pinned bottom actions ───────────────────────────────
                FadeTransition(
                  opacity: _fadeBody,
                  child: SlideTransition(
                    position: _slideBody,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.sm,
                        AppSpacing.xl,
                        AppSpacing.xxl,
                      ),
                      child: Column(
                        children: [
                          PrimaryButton(
                            label: l10n.authCreateAccount,
                            onPressed: () => _submit(context),
                            isLoading: isLoading,
                          ),
                          if (_googleSignInEnabled) ...[
                            const SizedBox(height: AppSpacing.lg),
                            _OrDivider(mutedColor: mutedColor),
                            const SizedBox(height: AppSpacing.lg),
                            _GoogleButton(
                              label: 'Daftar dengan Google',
                              isLoading: isLoading,
                              onPressed: () => context
                                  .read<AuthBloc>()
                                  .add(const GoogleSignInRequested()),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                          Semantics(
                            button: true,
                            label:
                                '${l10n.authHasAccount} ${l10n.authSignInLink}',
                            child: TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => context.go('/login'),
                              style: TextButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.sm),
                              ),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  text: l10n.authHasAccount,
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: textSoftColor),
                                  children: [
                                    TextSpan(
                                      text: l10n.authSignInLink,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Shared auth screen widgets ─────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.mutedColor});
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: mutedColor.withAlpha(80))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'atau',
            style: AppTextStyles.caption.copyWith(color: mutedColor),
          ),
        ),
        Expanded(child: Container(height: 1, color: mutedColor.withAlpha(80))),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            splashColor: AppColors.primary.withAlpha(20),
            highlightColor: AppColors.primary.withAlpha(10),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'G',
                    style: AppTextStyles.label.copyWith(
                      color: const Color(0xFF4285F4),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    label,
                    style: AppTextStyles.label.copyWith(color: textColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
