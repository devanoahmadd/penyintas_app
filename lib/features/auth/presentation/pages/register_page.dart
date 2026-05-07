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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmError = null;

      if (_nameController.text.trim().length < 2) {
        _nameError = 'Nama minimal 2 karakter.';
        valid = false;
      }
      if (_emailController.text.trim().isEmpty ||
          !RegExp(r'^[^@]+@[^@]+\.[^@]+')
              .hasMatch(_emailController.text.trim())) {
        _emailError = 'Format email tidak valid.';
        valid = false;
      }
      if (_passwordController.text.length < 8) {
        _passwordError = 'Password minimal 8 karakter.';
        valid = false;
      }
      if (_confirmController.text != _passwordController.text) {
        _confirmError = 'Konfirmasi password tidak cocok.';
        valid = false;
      }
    });
    return valid;
  }

  void _submit(BuildContext context) {
    if (!_validate()) return;
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
                  Text('Daftar',
                      style: AppTextStyles.h1.copyWith(color: textColor)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Mulai perjalananmu bersama Penyintas.',
                    style:
                        AppTextStyles.bodySmall.copyWith(color: textSoftColor),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppTextField(
                    controller: _nameController,
                    label: 'Nama',
                    hintText: 'Nama panggilanmu',
                    errorText: _nameError,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                    hintText: 'Minimal 8 karakter',
                    errorText: _passwordError,
                    isPassword: true,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _confirmController,
                    label: 'Konfirmasi Password',
                    hintText: 'Ulangi password',
                    errorText: _confirmError,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(context),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: 'Daftar',
                    onPressed: () => _submit(context),
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: RichText(
                        text: TextSpan(
                          text: 'Sudah punya akun? ',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: textSoftColor),
                          children: [
                            TextSpan(
                              text: 'Masuk.',
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
