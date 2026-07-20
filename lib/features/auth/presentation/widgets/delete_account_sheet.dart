import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:penyintas_app/widgets/common/app_text_field.dart';

class DeleteAccountSheet extends StatefulWidget {
  const DeleteAccountSheet({super.key});

  @override
  State<DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<DeleteAccountSheet> {
  bool _confirmed = false;
  final _passwordController = TextEditingController();
  String? _errorText;
  bool _isLoading = false;

  /// Dibaca SEKALI saat mount — state AuthBloc berubah jadi
  /// DeleteAccountInProgress selama alur, jangan sampai UI ikut berubah.
  late final bool _hasPasswordProvider;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    // Fail-safe: bila bukan Authenticated, tampilkan form password (perilaku lama).
    _hasPasswordProvider =
        authState is! Authenticated || authState.user.hasPasswordProvider;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  bool get _active =>
      _confirmed &&
      !_isLoading &&
      (!_hasPasswordProvider || _passwordController.text.isNotEmpty);

  void _onDelete(BuildContext context) {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    context.read<AuthBloc>().add(
          DeleteAccountRequested(
            password: _hasPasswordProvider ? _passwordController.text : null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom +
        AppSpacing.xl;
    final l10n = AppLocalizations.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          prev is DeleteAccountInProgress &&
          (curr is DeleteAccountFailure || curr is Unauthenticated),
      listener: (context, state) {
        if (state is DeleteAccountFailure) {
          setState(() {
            _isLoading = false;
            _errorText = state.message;
          });
        } else if (state is Unauthenticated) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.deleteAccountDone,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                  ),
                ),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          // GoRouterRefreshStream handles navigation to /login automatically
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          bottomPad,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ──────────────────────────────────────────────
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Title ────────────────────────────────────────────────────
            Text(
              l10n.deleteAccountTitle,
              style: AppTextStyles.h3.copyWith(color: textColor),
            ),

            // ── Body ─────────────────────────────────────────────────────
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.deleteAccountBody,
              style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
            ),

            // ── Divider ──────────────────────────────────────────────────
            const SizedBox(height: AppSpacing.lg),
            Divider(height: 1, color: borderColor),
            const SizedBox(height: AppSpacing.lg),

            // ── Acknowledgment checkbox ──────────────────────────────────
            // Material transparan: sheet ini dibuka dengan latar Container
            // berwarna, sehingga ink splash tile tertutup tanpa pembungkus ini.
            Material(
              type: MaterialType.transparency,
              child: CheckboxListTile(
                value: _confirmed,
                title: Text(
                  l10n.deleteAccountAck,
                  style: AppTextStyles.bodySmall.copyWith(color: textColor),
                ),
                activeColor: AppColors.warn,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (v) => setState(() => _confirmed = v ?? false),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Konfirmasi identitas: password ATAU Google (#254) ────────
            if (_hasPasswordProvider) ...[
              Text(
                l10n.deleteAccountPasswordLabel,
                style: AppTextStyles.label.copyWith(color: mutedColor),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppTextField(
                controller: _passwordController,
                isPassword: true,
                errorText: _errorText,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.done,
              ),
            ] else ...[
              Text(
                l10n.deleteAccountGoogleHint,
                style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _errorText!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warn,
                  ),
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.xl),

            // ── Delete button ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Material(
                color: _active
                    ? AppColors.warn
                    : AppColors.warn.withAlpha(100),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: InkWell(
                  onTap: _active ? () => _onDelete(context) : null,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            l10n.deleteAccountConfirm,
                            style: AppTextStyles.label.copyWith(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
