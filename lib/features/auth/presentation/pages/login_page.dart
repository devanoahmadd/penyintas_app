import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
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

  bool _validate() {
    bool valid = true;
    setState(() {
      _emailError = null;
      _passwordError = null;
      if (_emailController.text.trim().isEmpty) {
        _emailError = 'Email tidak boleh kosong.';
        valid = false;
      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
          .hasMatch(_emailController.text.trim())) {
        _emailError = 'Format email tidak valid.';
        valid = false;
      }
      if (_passwordController.text.isEmpty) {
        _passwordError = 'Password tidak boleh kosong.';
        valid = false;
      }
    });
    return valid;
  }

  void _submit(BuildContext context) {
    if (!_validate()) return;
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
      listenWhen: (_, state) => state is Authenticated || state is AuthError,
      listener: (context, state) {
        if (state is Authenticated) {
          context.go('/dashboard');
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

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  const PenyintasLogo(size: 36),
                  const SizedBox(height: AppSpacing.xxl),
                  Text('Masuk', style: AppTextStyles.h1.copyWith(color: textColor)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Halo lagi, kamu.',
                    style: AppTextStyles.bodySmall.copyWith(color: textSoftColor),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    hintText: 'nama@email.com',
                    errorText: _emailError,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hintText: 'Password kamu',
                    errorText: _passwordError,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(context),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'Lupa password?',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: 'Masuk',
                    onPressed: () => _submit(context),
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: GestureDetector(
                      onTap: () => context.push('/register'),
                      child: RichText(
                        text: TextSpan(
                          text: 'Belum punya akun? ',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: textSoftColor),
                          children: [
                            TextSpan(
                              text: 'Daftar di sini.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
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
        );
      },
    );
  }
}
