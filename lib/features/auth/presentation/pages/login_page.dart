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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
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
      if (_emailController.text.trim().isEmpty) {
        _emailError = l10n.errorEmailEmpty;
        valid = false;
      } else if (!AuthValidators.emailRegex
          .hasMatch(_emailController.text.trim())) {
        _emailError = l10n.errorEmailInvalid;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final textSoftColor =
        isDark ? AppColors.textSoftDark : AppColors.textSoftLight;

    return BlocConsumer<AuthBloc, AuthState>(
      // Navigasi pasca-auth ditangani oleh go_router redirect (GoRouterRefreshStream
      // mendengar Firebase authStateChanges) — tidak perlu context.go manual di sini.
      listenWhen: (_, state) => state is AuthError,
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(state.message,
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white)),
              backgroundColor: AppColors.warn,
              behavior: SnackBarBehavior.floating,
            ));
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
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Konten form — scrollable ──────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.xl,
                      AppSpacing.xl,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.xl),
                        const PenyintasLogo(size: 56),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          l10n.authLoginTitle,
                          style: AppTextStyles.h1.copyWith(
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.authLoginSubtitle,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: textSoftColor),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        AppTextField(
                          controller: _emailController,
                          label: l10n.authEmailLabel,
                          hintText: l10n.authEmailHint,
                          errorText: _emailError,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppTextField(
                          controller: _passwordController,
                          label: l10n.authPasswordLabel,
                          hintText: l10n.authPasswordHint,
                          errorText: _passwordError,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          // Gate enter-key seperti tombol PrimaryButton
                          onSubmitted: isLoading ? null : (_) => _submit(context),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: AppSpacing.xs,
                              ),
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

                // ── Aksi — pinned ke bawah ────────────────────────────────
                Padding(
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
                      const SizedBox(height: AppSpacing.lg),
                      GestureDetector(
                        onTap: () => context.push('/register'),
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
                    ],
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
