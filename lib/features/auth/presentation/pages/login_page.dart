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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  bool _emailValid = false;

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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate(BuildContext context) {
    final l10n = context.l10n;
    bool valid = true;
    setState(() {
      _emailError = null;
      _passwordError = null;
      if (!_emailValid) {
        _emailError = _emailController.text.trim().isEmpty
            ? l10n.errorEmailEmpty
            : l10n.errorEmailInvalid;
        valid = false;
      }
      if (_passwordController.text.isEmpty) {
        _passwordError = l10n.errorPasswordEmpty;
        valid = false;
      }
    });
    return valid;
  }

  void _submit(BuildContext context) {
    if (!_validate(context)) return;
    context.read<AuthBloc>().add(SignInRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ));
  }

  void _onForgotPassword(BuildContext context) {
    final bloc = context.read<AuthBloc>();
    _showForgotPasswordSheet(context, bloc);
  }

  Future<void> _showForgotPasswordSheet(
      BuildContext context, AuthBloc bloc) async {
    final emailCtrl =
        TextEditingController(text: _emailController.text.trim());
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _ForgotPasswordSheet(
        emailCtrl: emailCtrl,
        onSend: (email) {
          Navigator.of(sheetCtx).pop();
          bloc.add(ForgotPasswordRequested(email: email));
        },
      ),
    );
    emailCtrl.dispose();
  }

  SnackBar _buildErrorSnackBar(String message, bool isDark) {
    return SnackBar(
      content: Row(
        children: [
          Icon(Icons.warning_rounded,
              color: AppColors.warn, size: 18),
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
      backgroundColor:
          isDark ? AppColors.cardDark : AppColors.cardLight,
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

  SnackBar _buildSuccessSnackBar(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: Colors.white, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style:
                  AppTextStyles.bodySmall.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
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
    final mutedColor =
        isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (_, state) =>
          state is AuthError || state is PasswordResetEmailSent,
      listener: (ctx, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(ctx)
            ..hideCurrentSnackBar()
            ..showSnackBar(_buildErrorSnackBar(state.message, isDark));
        } else if (state is PasswordResetEmailSent) {
          ScaffoldMessenger.of(ctx)
            ..hideCurrentSnackBar()
            ..showSnackBar(
                _buildSuccessSnackBar(ctx.l10n.authResetEmailSent));
        }
      },
      buildWhen: (_, state) =>
          state is AuthLoading ||
          state is Unauthenticated ||
          state is AuthError ||
          state is PasswordResetEmailSent,
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final l10n = context.l10n;

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Scrollable content ─────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.xxxl,
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
                                  l10n.authLoginTitle,
                                  style: AppTextStyles.h1.copyWith(
                                    color: textColor,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  l10n.authLoginSubtitle,
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
                                  hintText: l10n.authPasswordHint,
                                  errorText: _passwordError,
                                  isPassword: true,
                                  enabled: !isLoading,
                                  textInputAction: TextInputAction.done,
                                  onChanged: (_) {
                                    if (_passwordError != null) {
                                      setState(() => _passwordError = null);
                                    }
                                  },
                                  onSubmitted: isLoading
                                      ? null
                                      : (_) => _submit(context),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: isLoading
                                        ? null
                                        : () => _onForgotPassword(context),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: AppSpacing.sm,
                                      ),
                                      minimumSize: const Size(44, 44),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      l10n.authForgotPassword,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Pinned bottom actions ──────────────────────────────
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
                            label: l10n.authSignIn,
                            onPressed: () => _submit(context),
                            isLoading: isLoading,
                          ),
                          if (_googleSignInEnabled) ...[
                            const SizedBox(height: AppSpacing.lg),
                            _OrDivider(mutedColor: mutedColor),
                            const SizedBox(height: AppSpacing.lg),
                            _GoogleButton(
                              label: 'Lanjutkan dengan Google',
                              isLoading: isLoading,
                              onPressed: () => context
                                  .read<AuthBloc>()
                                  .add(const GoogleSignInRequested()),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                          Semantics(
                            button: true,
                            label: '${l10n.authNoAccount} ${l10n.authSignUpLink}',
                            child: TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => context.push('/register'),
                              style: TextButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.sm),
                              ),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  text: l10n.authNoAccount,
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: textSoftColor),
                                  children: [
                                    TextSpan(
                                      text: l10n.authSignUpLink,
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
        Expanded(
          child: Container(
            height: 1,
            color: mutedColor.withAlpha(80),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            context.l10n.authOr,
            style: AppTextStyles.caption.copyWith(color: mutedColor),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: mutedColor.withAlpha(80),
          ),
        ),
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
    final bgColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor =
        isDark ? AppColors.textDark : AppColors.textLight;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;

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
                  // Google G — placeholder until official asset is added
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

class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet({
    required this.emailCtrl,
    required this.onSend,
  });

  final TextEditingController emailCtrl;
  final void Function(String email) onSend;

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  String? _emailError;

  void _send() {
    final email = widget.emailCtrl.text.trim();
    if (!AuthValidators.emailRegex.hasMatch(email)) {
      setState(() => _emailError = context.l10n.authEmailInvalidShort);
      return;
    }
    widget.onSend(email);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.bgLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final textSoftColor =
        isDark ? AppColors.textSoftDark : AppColors.textSoftLight;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xxxl,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.borderDark : AppColors.borderLight),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              context.l10n.authResetPasswordTitle,
              style: AppTextStyles.h2.copyWith(color: textColor),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.authResetPasswordBody,
              style: AppTextStyles.bodySmall.copyWith(color: textSoftColor),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              controller: widget.emailCtrl,
              label: 'Email',
              hintText: context.l10n.authEmailHint,
              errorText: _emailError,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
              onSubmitted: (_) => _send(),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(label: context.l10n.authResetPasswordCta, onPressed: _send),
          ],
        ),
      ),
    );
  }
}
