import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:penyintas_app/widgets/common/app_text_field.dart';
import 'package:penyintas_app/widgets/common/penyintas_logo.dart';
import 'package:penyintas_app/widgets/common/primary_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  // Live valid state — ditampilkan sebagai checkmark hijau
  bool _emailValid = false;
  bool _confirmValid = false;

  static final _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

  @override
  void dispose() {
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
      if (!_confirmValid) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final textSoftColor =
        isDark ? AppColors.textSoftDark : AppColors.textSoftLight;

    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (_, state) => state is Authenticated || state is AuthError,
      listener: (context, state) {
        if (state is Authenticated) {
          context.go('/onboarding');
        } else if (state is AuthError) {
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
                        const PenyintasLogo(size: 48),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          l10n.authRegisterTitle,
                          style: AppTextStyles.h1.copyWith(
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.authRegisterSubtitle,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: textSoftColor),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        AppTextField(
                          controller: _nameController,
                          label: l10n.authNameLabel,
                          hintText: l10n.authNameHint,
                          errorText: _nameError,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppTextField(
                          controller: _emailController,
                          label: l10n.authEmailLabel,
                          hintText: l10n.authEmailHint,
                          errorText: _emailError,
                          isValid: _emailValid,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onChanged: (value) {
                            final valid =
                                _emailRegex.hasMatch(value.trim());
                            if (valid != _emailValid) {
                              setState(() => _emailValid = valid);
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppTextField(
                          controller: _passwordController,
                          label: l10n.authPasswordLabel,
                          hintText: l10n.authPasswordHintReg,
                          errorText: _passwordError,
                          isPassword: true,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppTextField(
                          controller: _confirmController,
                          label: l10n.authConfirmLabel,
                          hintText: l10n.authConfirmHint,
                          errorText: _confirmError,
                          isValid: _confirmValid,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          onChanged: (value) {
                            final valid = value.isNotEmpty &&
                                value == _passwordController.text;
                            if (valid != _confirmValid) {
                              setState(() => _confirmValid = valid);
                            }
                          },
                          onSubmitted: (_) => _submit(context),
                        ),
                      ],
                    ),
                  ),
                ),
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
                        label: l10n.authCreateAccount,
                        onPressed: () => _submit(context),
                        isLoading: isLoading,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      GestureDetector(
                        onTap: () => context.pop(),
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
