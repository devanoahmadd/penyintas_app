// lib/features/onboarding/presentation/pages/profile_leg_page.dart
//
// ProfileLegPage — mini-wizard 2 sub-langkah untuk leg profil onboarding.
//
// Dirancang via ui-ux-pro-max:
//   • Scaffold bg*; panel/input surfaceAlt*; chip surface*/aktif primary
//   • H2 Plus Jakarta Sans; body Inter Tight; CTA primary radius pill
//   • 1 CTA utama per layar; jarak antar-grup ≥ AppSpacing.xl; TANPA emoji
//   • Dark-mode hari pertama — semua token adaptive
//   • PopScope canPop:false (tiru onboarding_page.dart:455)
//   • BlocListener anti-loop B-1: resetOnboardingCache() SEBELUM go('/onboarding')
//   • sl<TimezoneResolver>() lazy — diambil HANYA di dalam onTap (bukan build())
//   • Error-state: retry + jalur sign-out terjangkau (B-7)
//
// Keys kontrak (6 wajib):
//   profile_lang_toggle, profile_next_cta, profile_country_btn,
//   profile_perantau_toggle, profile_home_country_btn, profile_finish_cta

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/routing/app_router.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/timezone_resolver.dart';
import 'package:penyintas_app/features/onboarding/presentation/cubit/profile_setup_cubit.dart';
import 'package:penyintas_app/features/onboarding/presentation/widgets/onboarding_ruas_progress.dart';
import 'package:penyintas_app/features/profile/presentation/widgets/city_picker.dart';
import 'package:penyintas_app/features/profile/presentation/widgets/country_picker.dart';

class ProfileLegPage extends StatelessWidget {
  const ProfileLegPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<ProfileSetupCubit, ProfileSetupState>(
      listenWhen: (p, c) => !p.saved && c.saved,
      listener: (ctx, _) {
        resetOnboardingCache(); // ← invalidasi cache SEBELUM navigasi (B-1)
        ctx.go('/onboarding'); // guard recompute → needsBudget → onboarding
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final cubit = context.read<ProfileSetupCubit>();
          final state = cubit.state;
          if (state.subStep == 1) {
            cubit.backToIdentity();
          } else {
            // Sub-A: dialog konfirmasi keluar
            _showExitDialog(context);
          }
        },
        child: Scaffold(
          backgroundColor:
              isDark ? AppColors.bgDark : AppColors.bgLight,
          body: SafeArea(
            child: BlocBuilder<ProfileSetupCubit, ProfileSetupState>(
              builder: (context, state) {
                if (state.error != null) {
                  return _ErrorState(error: state.error!, isDark: isDark);
                }
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: state.subStep == 0
                      ? _SubStepA(key: const ValueKey('sub-a'), isDark: isDark)
                      : _SubStepB(key: const ValueKey('sub-b'), isDark: isDark),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Dialog konfirmasi keluar dari onboarding profil (sub-A back)
  static void _showExitDialog(BuildContext context) {
    final loc = AppLocalizations.of(context);
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.profileExitDialogTitle),
        content: Text(loc.profileExitDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.profileExitDialogContinue),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
              context.go('/login');
            },
            child: Text(
              loc.profileExitDialogConfirm,
              style: TextStyle(
                color: AppColors.warn,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-A: "Kenalan dulu"
// Konten: segmented ID/EN · field nama · chip status · CTA Lanjut
// ─────────────────────────────────────────────────────────────────────────────

class _SubStepA extends StatelessWidget {
  const _SubStepA({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final state = context.watch<ProfileSetupCubit>().state;
    final cubit = context.read<ProfileSetupCubit>();

    final textMain = isDark ? AppColors.textDark : AppColors.textLight;
    final textMuted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final surfaceAlt =
        isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress ruas
          OnboardingRuasProgress(step: 0, total: 2, isDark: isDark),
          const SizedBox(height: AppSpacing.xl),

          // Judul
          Text(
            loc.profileStepATitle,
            style: AppTextStyles.h2.copyWith(color: textMain),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Segmented bahasa ID / EN ──────────────────────────────
          Text(
            loc.profileLangLabel,
            style: AppTextStyles.label.copyWith(color: textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          _LangToggle(
            key: const Key('profile_lang_toggle'),
            value: state.language,
            isDark: isDark,
            onChanged: cubit.setLanguage,
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Field nama tampilan ───────────────────────────────────
          Text(
            loc.profileNameLabel,
            style: AppTextStyles.label.copyWith(color: textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          _NameField(
            initialValue: state.displayName,
            surfaceAlt: surfaceAlt,
            border: border,
            textMain: textMain,
            hint: loc.profileNameHint,
            onChanged: cubit.setName,
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Chip status ───────────────────────────────────────────
          Text(
            loc.profileStatusLabel,
            style: AppTextStyles.label.copyWith(color: textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          _StatusChips(
            value: state.status,
            isDark: isDark,
            mahasiswaLabel: loc.profileStatusMahasiswa,
            pekerjaLabel: loc.profileStatusPekerja,
            onChanged: cubit.setStatus,
          ),
          const SizedBox(height: AppSpacing.xxxl),

          // ── CTA Lanjut ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              key: const Key('profile_next_cta'),
              onPressed: () => cubit.goToLocation(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: Text(
                loc.btnNext,
                style: AppTextStyles.label.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-B: "Kamu di mana?"
// Konten: tombol negara · tombol kota · chip TZ · toggle perantau (+reveal asal)
//         · CTA Selesai
// ─────────────────────────────────────────────────────────────────────────────

class _SubStepB extends StatelessWidget {
  const _SubStepB({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final state = context.watch<ProfileSetupCubit>().state;
    final cubit = context.read<ProfileSetupCubit>();

    final textMain = isDark ? AppColors.textDark : AppColors.textLight;
    final textMuted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress ruas
          OnboardingRuasProgress(step: 1, total: 2, isDark: isDark),
          const SizedBox(height: AppSpacing.xl),

          // Judul
          Text(
            loc.profileStepBTitle,
            style: AppTextStyles.h2.copyWith(color: textMain),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Negara sekarang ───────────────────────────────────────
          Text(
            loc.profileCountryLabel,
            style: AppTextStyles.label.copyWith(color: textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PickerButton(
            widgetKey: const Key('profile_country_btn'),
            label: state.currentCountry,
            surface: surface,
            border: border,
            textMain: textMain,
            onTap: () async {
              final result = await showCountryPicker(context);
              if (result != null && context.mounted) {
                cubit.setCurrentCountry(result);
              }
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Kota sekarang ─────────────────────────────────────────
          Text(
            loc.profileCityLabel,
            style: AppTextStyles.label.copyWith(color: textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PickerButton(
            widgetKey: const Key('profile_city_btn'),
            label: state.currentCity ?? '—',
            surface: surface,
            border: border,
            textMain: textMain,
            onTap: () async {
              // sl<TimezoneResolver>() lazy — diambil di onTap, BUKAN di build()
              final resolver = sl<TimezoneResolver>();
              final result = await showCityPicker(
                context,
                country: state.currentCountry,
                resolver: resolver,
              );
              if (result != null && context.mounted) {
                if (result is TimezonePick) {
                  cubit.setTimezone(result.iana);
                } else if (result is String) {
                  cubit.setCurrentCity(result);
                }
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Chip zona waktu ───────────────────────────────────────
          _TimezoneChip(
            timezone: state.timezone,
            isDark: isDark,
            label: loc.profileTimezoneLabel,
            changeLabel: loc.profileTimezoneChange,
            surface: surface,
            border: border,
            textMain: textMain,
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Toggle perantau ───────────────────────────────────────
          _PerantauToggle(
            widgetKey: const Key('profile_perantau_toggle'),
            value: state.isPerantau,
            label: loc.profilePerantauLabel,
            textMain: textMain,
            isDark: isDark,
            onChanged: cubit.togglePerantau,
          ),

          // ── Reveal: negara & kota asal (animasi) ─────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            child: state.isPerantau
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.profileHomeCountryLabel,
                          style: AppTextStyles.label.copyWith(color: textMuted),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _PickerButton(
                          widgetKey: const Key('profile_home_country_btn'),
                          label: state.homeCountry,
                          surface: surface,
                          border: border,
                          textMain: textMain,
                          onTap: () async {
                            final result = await showCountryPicker(context);
                            if (result != null && context.mounted) {
                              cubit.setHomeCountry(result);
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          loc.profileHomeCityLabel,
                          style: AppTextStyles.label.copyWith(color: textMuted),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _PickerButton(
                          widgetKey: const Key('profile_home_city_btn'),
                          label: state.homeCity ?? '—',
                          surface: surface,
                          border: border,
                          textMain: textMain,
                          onTap: () async {
                            // Kota asal: country = homeCountry; resolver lazy
                            final resolver = sl<TimezoneResolver>();
                            final result = await showCityPicker(
                              context,
                              country: state.homeCountry,
                              resolver: resolver,
                            );
                            if (result != null && context.mounted) {
                              if (result is String) {
                                cubit.setHomeCity(result);
                              }
                              // TimezonePick dari kota asal diabaikan — hanya kota
                            }
                          },
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: AppSpacing.xxxl),

          // ── CTA Selesai ───────────────────────────────────────────
          BlocBuilder<ProfileSetupCubit, ProfileSetupState>(
            buildWhen: (p, c) => p.saving != c.saving || p.saved != c.saved,
            builder: (context, saveState) {
              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  key: const Key('profile_finish_cta'),
                  onPressed: saveState.saving ? null : () => cubit.save(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.5),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: saveState.saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          loc.btnSave,
                          style: AppTextStyles.label.copyWith(color: Colors.white),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LangToggle — segmented ID/EN
// ─────────────────────────────────────────────────────────────────────────────

class _LangToggle extends StatelessWidget {
  const _LangToggle({
    super.key,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  final String value;
  final bool isDark;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          _LangOption(
            label: 'Indonesia',
            code: 'id',
            selected: value == 'id',
            isDark: isDark,
            onTap: () => onChanged('id'),
          ),
          _LangOption(
            label: 'English',
            code: 'en',
            selected: value == 'en',
            isDark: isDark,
            onTap: () => onChanged('en'),
          ),
        ],
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  const _LangOption({
    required this.label,
    required this.code,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final String code;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: selected
                  ? Colors.white
                  : (isDark ? AppColors.textSoftDark : AppColors.textSoftLight),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NameField — TextField nama tampilan
// ─────────────────────────────────────────────────────────────────────────────

class _NameField extends StatefulWidget {
  const _NameField({
    required this.initialValue,
    required this.surfaceAlt,
    required this.border,
    required this.textMain,
    required this.hint,
    required this.onChanged,
  });

  final String? initialValue;
  final Color surfaceAlt;
  final Color border;
  final Color textMain;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      maxLength: 80,
      onChanged: widget.onChanged,
      style: AppTextStyles.body.copyWith(color: widget.textMain),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: AppTextStyles.body.copyWith(
          color: widget.textMain.withValues(alpha: 0.4),
        ),
        filled: true,
        fillColor: widget.surfaceAlt,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: widget.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: widget.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatusChips — chip Mahasiswa / Pekerja
// ─────────────────────────────────────────────────────────────────────────────

class _StatusChips extends StatelessWidget {
  const _StatusChips({
    required this.value,
    required this.isDark,
    required this.mahasiswaLabel,
    required this.pekerjaLabel,
    required this.onChanged,
  });

  final String? value;
  final bool isDark;
  final String mahasiswaLabel;
  final String pekerjaLabel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatusChip(
          label: mahasiswaLabel,
          code: 'mahasiswa',
          selected: value == 'mahasiswa',
          isDark: isDark,
          onTap: () => onChanged('mahasiswa'),
        ),
        const SizedBox(width: AppSpacing.sm),
        _StatusChip(
          label: pekerjaLabel,
          code: 'pekerja',
          selected: value == 'pekerja',
          isDark: isDark,
          onTap: () => onChanged('pekerja'),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.code,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final String code;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textMuted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm2,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: selected ? Colors.white : textMuted,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PickerButton — tombol pilih negara / kota
// ─────────────────────────────────────────────────────────────────────────────

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.widgetKey,
    required this.label,
    required this.surface,
    required this.border,
    required this.textMain,
    required this.onTap,
  });

  final Key widgetKey;
  final String label;
  final Color surface;
  final Color border;
  final Color textMain;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: widgetKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(color: textMain),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: textMain.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TimezoneChip — chip zona waktu + tombol ubah
// ─────────────────────────────────────────────────────────────────────────────

class _TimezoneChip extends StatelessWidget {
  const _TimezoneChip({
    required this.timezone,
    required this.isDark,
    required this.label,
    required this.changeLabel,
    required this.surface,
    required this.border,
    required this.textMain,
  });

  final String timezone;
  final bool isDark;
  final String label;
  final String changeLabel;
  final Color surface;
  final Color border;
  final Color textMain;

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    // Format lebih readable: "Asia/Jakarta" → "Asia / Jakarta"
    final tzLabel = timezone.replaceAll('/', ' / ');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 16,
            color: textMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$label: $tzLabel',
              style: AppTextStyles.bodySmall.copyWith(color: textMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            changeLabel,
            style: AppTextStyles.label.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PerantauToggle — Switch dengan label
// ─────────────────────────────────────────────────────────────────────────────

class _PerantauToggle extends StatelessWidget {
  const _PerantauToggle({
    required this.widgetKey,
    required this.value,
    required this.label,
    required this.textMain,
    required this.isDark,
    required this.onChanged,
  });

  final Key widgetKey;
  final bool value;
  final String label;
  final Color textMain;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm2,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(color: textMain),
            ),
          ),
          Switch(
            key: widgetKey,
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primaryBright.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ErrorState — error + retry + sign-out terjangkau (B-7)
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.isDark});

  final String error;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<ProfileSetupCubit>();
    final textMain = isDark ? AppColors.textDark : AppColors.textLight;
    final textMuted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.warn, size: 48),
            const SizedBox(height: AppSpacing.lg),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: textMuted),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: cubit.save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  loc.profileErrorRetry,
                  style: AppTextStyles.label.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Escape hatch: sign-out — agar user tidak terjebak loop needsProfile
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) context.go('/login');
              },
              child: Text(
                loc.profileErrorSignout,
                style: AppTextStyles.label.copyWith(color: textMain),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
