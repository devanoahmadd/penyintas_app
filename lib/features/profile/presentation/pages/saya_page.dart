import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/goal/domain/entities/goal_entity.dart';
import 'package:penyintas_app/features/goal/domain/usecases/load_goals_usecase.dart';
import 'package:penyintas_app/features/goal/presentation/bloc/goal_bloc.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/features/profile/presentation/cubit/profile_summary_cubit.dart';
import 'package:penyintas_app/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/add_transaction_bloc.dart';
import 'package:penyintas_app/features/transaction/presentation/widgets/add_transaction_sheet.dart';
import 'package:penyintas_app/features/auth/presentation/widgets/delete_account_sheet.dart';
import 'package:penyintas_app/widgets/common/app_bottom_nav_bar.dart';

class SayaPage extends StatelessWidget {
  const SayaPage({super.key});

  Future<void> _openAddSheet(BuildContext context) async {
    final goalsResult =
        await sl<LoadGoalsUseCase>().call(const NoParams());
    final activeGoals = goalsResult.fold(
      (_) => <GoalEntity>[],
      (goals) => goals.where((g) => !g.isCompleted).toList(),
    );

    if (!context.mounted) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => sl<AddTransactionBloc>(),
        child: AddTransactionSheet(activeGoals: activeGoals),
      ),
    );

    if (saved == true) sl<GoalBloc>().add(const LoadGoals());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;

    return BlocProvider<ProfileSummaryCubit>(
      create: (_) => sl<ProfileSummaryCubit>(),
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, settingsState) {
              return ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                children: [
                  _ProfileHeader(isDark: isDark),
                  const SizedBox(height: AppSpacing.lg),
                  _QuickAccess(isDark: isDark),
                  _SettingsSection(isDark: isDark, settingsState: settingsState),
                  _AccountSection(isDark: isDark),
                  _DangerZoneSection(isDark: isDark),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: 4,
          onFabTap: () => _openAddSheet(context),
        ),
      ),
    );
  }
}

// ── Profile Header ─────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.isDark});
  final bool isDark;

  Future<void> _onTap(BuildContext context) async {
    final changed = await context.push<bool>('/profile/edit');
    if (changed == true && context.mounted) {
      context.read<ProfileSummaryCubit>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return BlocBuilder<ProfileSummaryCubit, ProfileSummaryState>(
      builder: (context, summary) {
        // Nama: dari cubit prefs jika tersedia, fallback FirebaseAuth, fallback 'Penyintas'
        final user = FirebaseAuth.instance.currentUser;
        final name = summary.prefs?.displayName ??
            user?.displayName ??
            'Penyintas';
        final email = user?.email ?? '';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

        // Lokasi dan badge hanya ditampilkan saat data siap (nol layout-jump)
        final prefs = summary.loading ? null : summary.prefs;
        final locationText = prefs?.currentCity ?? prefs?.currentCountry;
        final showPerantau = prefs?.isPerantau == true;

        return Semantics(
          button: true,
          label: l10n.sayaEditProfile,
          child: InkWell(
            key: const Key('saya_edit_profile'),
            onTap: () => _onTap(context),
            splashColor: AppColors.primary.withValues(alpha: 0.08),
            highlightColor: AppColors.primary.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar monogram
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Nama, email, lokasi, badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: AppTextStyles.h3.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (email.isNotEmpty)
                            Text(
                              email,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: mutedColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          // Baris lokasi + badge — hanya saat data siap
                          if (locationText != null || showPerantau)
                            const SizedBox(height: AppSpacing.xs),
                          if (locationText != null || showPerantau)
                            Row(
                              children: [
                                if (locationText != null) ...[
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: mutedColor,
                                  ),
                                  const SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                      locationText,
                                      style: AppTextStyles.caption.copyWith(
                                        color: mutedColor,
                                        letterSpacing: 0,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                if (showPerantau) ...[
                                  if (locationText != null)
                                    const SizedBox(width: AppSpacing.xs),
                                  // Badge Perantau
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: surfaceColor,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                      border: Border.all(
                                        color: borderColor,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      l10n.sayaPerantauBadge,
                                      style: AppTextStyles.caption.copyWith(
                                        color: mutedColor,
                                        letterSpacing: 0,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                        ],
                      ),
                    ),
                    // Trailing: label + chevron
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.sayaEditProfile,
                          style: AppTextStyles.caption.copyWith(
                            color: mutedColor,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: mutedColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Quick Access ───────────────────────────────────────────────────────────

class _QuickAccess extends StatelessWidget {
  const _QuickAccess({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.sayaSectionQuick,
            style: AppTextStyles.caption.copyWith(color: mutedColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _QuickCard(
                  icon: Icons.flag_outlined,
                  label: l10n.sayaQuickGoals,
                  onTap: () => context.go('/goals'),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _QuickCard(
                  icon: Icons.bar_chart_rounded,
                  label: l10n.sayaQuickReport,
                  onTap: () => context.go('/report'),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _QuickCard(
                  icon: Icons.shield_outlined,
                  label: l10n.sayaQuickSurvival,
                  onTap: () => context.go('/survival/tips'),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor =
        isDark ? AppColors.textSoftDark : AppColors.textSoftLight;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: textColor,
                letterSpacing: 0,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Settings Section ───────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.isDark,
    required this.settingsState,
  });

  final bool isDark;
  final SettingsState settingsState;

  String _themeLabel(BuildContext context, ThemeMode mode) {
    final l10n = AppLocalizations.of(context);
    return switch (mode) {
      ThemeMode.light => l10n.settingsThemeLight,
      ThemeMode.dark => l10n.settingsThemeDark,
      ThemeMode.system => l10n.settingsThemeSystem,
    };
  }

  String _localeLabel(String locale) =>
      locale == 'id' ? 'Indonesia' : 'English';

  void _showThemePicker(BuildContext outerCtx, ThemeMode current) {
    final sheetBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final l10n = AppLocalizations.of(outerCtx);

    showModalBottomSheet<void>(
      context: outerCtx,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          _SheetHandle(isDark: isDark),
          _SheetOption(
            title: l10n.settingsThemeLight,
            selected: current == ThemeMode.light,
            isDark: isDark,
            onTap: () {
              outerCtx.read<SettingsBloc>().add(ChangeTheme(ThemeMode.light));
              Navigator.of(sheetCtx).pop();
            },
          ),
          _SheetOption(
            title: l10n.settingsThemeDark,
            selected: current == ThemeMode.dark,
            isDark: isDark,
            onTap: () {
              outerCtx.read<SettingsBloc>().add(ChangeTheme(ThemeMode.dark));
              Navigator.of(sheetCtx).pop();
            },
          ),
          _SheetOption(
            title: l10n.settingsThemeSystem,
            selected: current == ThemeMode.system,
            isDark: isDark,
            onTap: () {
              outerCtx.read<SettingsBloc>().add(ChangeTheme(ThemeMode.system));
              Navigator.of(sheetCtx).pop();
            },
          ),
          SizedBox(
            height: MediaQuery.of(sheetCtx).padding.bottom + AppSpacing.lg,
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext outerCtx, String current) {
    final sheetBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    showModalBottomSheet<void>(
      context: outerCtx,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          _SheetHandle(isDark: isDark),
          _SheetOption(
            title: 'Indonesia',
            selected: current == 'id',
            isDark: isDark,
            onTap: () {
              outerCtx.read<SettingsBloc>().add(ChangeLanguage('id'));
              Navigator.of(sheetCtx).pop();
            },
          ),
          _SheetOption(
            title: 'English',
            selected: current == 'en',
            isDark: isDark,
            onTap: () {
              outerCtx.read<SettingsBloc>().add(ChangeLanguage('en'));
              Navigator.of(sheetCtx).pop();
            },
          ),
          SizedBox(
            height: MediaQuery.of(sheetCtx).padding.bottom + AppSpacing.lg,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.sayaSectionSettings,
            style: AppTextStyles.caption.copyWith(color: mutedColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          Material(
            color: surfaceColor,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(color: borderColor),
            ),
            child: Column(
              children: [
                _SettingsTile(
                  title: l10n.sayaThemeLabel,
                  trailingLabel: _themeLabel(context, settingsState.themeMode),
                  textColor: textColor,
                  mutedColor: mutedColor,
                  borderColor: borderColor,
                  showDivider: true,
                  onTap: () =>
                      _showThemePicker(context, settingsState.themeMode),
                ),
                _SettingsTile(
                  title: l10n.sayaLanguageLabel,
                  trailingLabel: _localeLabel(settingsState.locale),
                  textColor: textColor,
                  mutedColor: mutedColor,
                  borderColor: borderColor,
                  showDivider: true,
                  onTap: () =>
                      _showLanguagePicker(context, settingsState.locale),
                ),
                _SettingsTile(
                  title: l10n.sayaNotifLabel,
                  trailingLabel: '',
                  textColor: textColor,
                  mutedColor: mutedColor,
                  borderColor: borderColor,
                  showDivider: false,
                  onTap: () => context.push('/settings'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Account Section ────────────────────────────────────────────────────────

class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.isDark});
  final bool isDark;

  Future<void> _onLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final textSoftColor =
        isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
    final sheetBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: sheetBg,
        title: Text(
          l10n.sayaLogout,
          style: AppTextStyles.h3.copyWith(color: textColor),
        ),
        content: Text(
          l10n.sayaLogoutConfirm,
          style: AppTextStyles.body.copyWith(color: textSoftColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              l10n.btnCancel,
              style: AppTextStyles.label.copyWith(
                color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(
              l10n.sayaLogoutConfirmYes,
              style: AppTextStyles.label.copyWith(color: AppColors.warn),
            ),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    if (confirmed == true) {
      // Gunakan AuthBloc agar SignOutUseCase dijalankan dengan error handling
      // dan tidak bypass event pipeline.
      context.read<AuthBloc>().add(const SignOutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.sayaSectionAccount,
            style: AppTextStyles.caption.copyWith(color: mutedColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          Material(
            color: surfaceColor,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(color: borderColor),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  title: Text(
                    l10n.sayaVersionLabel,
                    style: AppTextStyles.body.copyWith(color: textColor),
                  ),
                  trailing: Text(
                    'v0.1.0+1',
                    style:
                        AppTextStyles.bodySmall.copyWith(color: mutedColor),
                  ),
                ),
                Divider(height: 1, color: borderColor),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  title: Text(
                    l10n.sayaLogout,
                    style: AppTextStyles.body.copyWith(color: AppColors.warn),
                  ),
                  trailing: Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: AppColors.warn,
                  ),
                  onTap: () => _onLogout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Danger Zone Section ────────────────────────────────────────────────────

class _DangerZoneSection extends StatelessWidget {
  const _DangerZoneSection({required this.isDark});
  final bool isDark;

  Future<void> _onDeleteAccount(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: const DeleteAccountSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.sayaSectionDanger,
            style: AppTextStyles.caption.copyWith(color: mutedColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          Material(
            color: surfaceColor,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(color: borderColor),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              title: Text(
                l10n.sayaDeleteAccount,
                style: AppTextStyles.body.copyWith(color: AppColors.warn),
              ),
              trailing: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: AppColors.warn,
              ),
              onTap: () => _onDeleteAccount(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared sheet widgets ───────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.title,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      title: Text(
        title,
        style: AppTextStyles.body.copyWith(
          color: selected ? AppColors.primary : textColor,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 20)
          : null,
      onTap: onTap,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.trailingLabel,
    required this.onTap,
    required this.textColor,
    required this.mutedColor,
    required this.borderColor,
    required this.showDivider,
  });

  final String title;
  final String trailingLabel;
  final VoidCallback onTap;
  final Color textColor;
  final Color mutedColor;
  final Color borderColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          title: Text(
            title,
            style: AppTextStyles.body.copyWith(color: textColor),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingLabel.isNotEmpty)
                Text(
                  trailingLabel,
                  style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
                ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: mutedColor,
              ),
            ],
          ),
          onTap: onTap,
        ),
        if (showDivider) Divider(height: 1, color: borderColor),
      ],
    );
  }
}
