// lib/features/profile/presentation/pages/profile_edit_page.dart
//
// ProfileEditPage — editor profil satu-halaman (C3).
//
// Dirancang via ui-ux-pro-max:
//   • Minimal Single Column — spacing lapang, satu CTA utama, tanpa noise
//   • surfaceAlt* untuk field/input; surface* untuk chip & picker-button
//   • AppTextStyles.label (muted) sebagai section header — ringan tapi terstruktur
//   • Hit target ≥ 48dp semua elemen interaktif
//   • Dark-mode hari pertama — semua token adaptive
//   • PopScope canPop:!isDirty + dialog konfirmasi buang perubahan (M3)
//   • listener saved → SnackBar + context.pop(true) IMPERATIF (anti-deadlock)
//   • sl<TimezoneResolver>() lazy — hanya di onTap, BUKAN build()
//   • TANPA emoji (aturan global CLAUDE.md)
//
// Keys kontrak (7 wajib):
//   pe_retry, pe_name, pe_status_student, pe_status_worker,
//   pe_location_hint, pe_perantau, pe_save

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/timezone_resolver.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';
import 'package:penyintas_app/features/profile/presentation/cubit/profile_edit_cubit.dart';
import 'package:penyintas_app/features/profile/presentation/widgets/city_picker.dart';
import 'package:penyintas_app/features/profile/presentation/widgets/country_picker.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — membungkus diri dengan BlocProvider agar route bisa `const`
// ─────────────────────────────────────────────────────────────────────────────

class ProfileEditPage extends StatelessWidget {
  const ProfileEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileEditCubit>(),
      child: const _ProfileEditView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// View — konten sesungguhnya (mempunyai akses cubit via context)
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileEditView extends StatelessWidget {
  const _ProfileEditView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;

    return BlocConsumer<ProfileEditCubit, ProfileEditState>(
      listenWhen: (prev, curr) {
        // Trigger listener saat:
        // • baru tersimpan (saved flip true)
        // • ada error baru DAN draft tidak null (tetap di halaman, tampil SnackBar)
        final savedFlip = !prev.saved && curr.saved;
        final newError =
            curr.error != null &&
            curr.error != prev.error &&
            curr.draft != null;
        return savedFlip || newError;
      },
      listener: (context, state) {
        final loc = AppLocalizations.of(context);
        if (state.saved) {
          // M3 pop imperatif — lewat listener, bukan tombol back, agar PopScope
          // tidak memblok (pop system-initiated) vs pop kode (selalu lolos).
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.profileSaved),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          context.pop(true);
          return;
        }
        if (state.error != null && state.draft != null) {
          final msg = state.error == 'unresolved_location'
              ? loc.profileSelectCityFirst
              : state.error!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: AppColors.warn,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      builder: (context, state) {
        final loc = AppLocalizations.of(context);

        return PopScope(
          // M3: cegah back sistem bila ada perubahan belum disimpan
          canPop: !state.isDirty,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _showDiscardDialog(context, loc);
          },
          child: Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: bg,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: Text(
                loc.profileEditTitle,
                style: AppTextStyles.h3.copyWith(
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
                onPressed: () {
                  if (state.isDirty) {
                    _showDiscardDialog(context, loc);
                  } else {
                    context.pop();
                  }
                },
                tooltip: loc.btnBack,
              ),
            ),
            body: SafeArea(child: _buildBody(context, state, loc, isDark)),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProfileEditState state,
    AppLocalizations loc,
    bool isDark,
  ) {
    // Loading terpusat
    if (state.loading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    // H1: load gagal → panel error (TANPA tombol Simpan)
    if (state.draft == null) {
      return _ErrorPanel(isDark: isDark, loc: loc);
    }

    // Body form (hanya saat draft != null)
    return _FormBody(state: state, isDark: isDark, loc: loc);
  }

  static void _showDiscardDialog(BuildContext context, AppLocalizations loc) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.profileDiscardTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.profileDiscardKeep),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
              // pop imperatif — lolos walau canPop==false (M3 defense-in-depth)
              if (context.mounted) context.pop();
            },
            child: Text(
              loc.profileDiscardLeave,
              style: TextStyle(color: AppColors.warn),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// H1: Panel error (load gagal) — tombol Simpan TIDAK ADA di state ini
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.isDark, required this.loc});

  final bool isDark;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final textMain = isDark ? AppColors.textDark : AppColors.textLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.warn),
            const SizedBox(height: AppSpacing.lg),
            Text(
              loc.profileLoadError,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: textMain),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                key: const Key('pe_retry'),
                onPressed: () => context.read<ProfileEditCubit>().reload(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                ),
                child: Text(
                  loc.profileErrorRetry,
                  style: AppTextStyles.label.copyWith(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form body — scroll, satu kolom, spacing lapang
// ─────────────────────────────────────────────────────────────────────────────

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.state,
    required this.isDark,
    required this.loc,
  });

  final ProfileEditState state;
  final bool isDark;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final draft = state.draft!;
    final textMain = isDark ? AppColors.textDark : AppColors.textLight;
    final textMuted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final surfaceAlt = isDark
        ? AppColors.surfaceAltDark
        : AppColors.surfaceAltLight;
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
          // ── Seksi: Identitas ────────────────────────────────────────
          _SectionHeader(label: loc.profileNameLabel, textMuted: textMuted),
          const SizedBox(height: AppSpacing.sm),
          _NameField(
            key: const Key('pe_name'),
            initialValue: draft.displayName ?? '',
            surfaceAlt: surfaceAlt,
            border: border,
            textMain: textMain,
            hint: loc.profileNameHint,
            onChanged: (v) => context.read<ProfileEditCubit>().setName(v),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Seksi: Status ───────────────────────────────────────────
          _SectionHeader(label: loc.profileStatusLabel, textMuted: textMuted),
          const SizedBox(height: AppSpacing.sm),
          _StatusChips(
            value: draft.status,
            isDark: isDark,
            studentKey: const Key('pe_status_student'),
            workerKey: const Key('pe_status_worker'),
            mahasiswaLabel: loc.profileStatusMahasiswa,
            pekerjaLabel: loc.profileStatusPekerja,
            onChanged: (v) => context.read<ProfileEditCubit>().setStatus(v),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Seksi: Lokasi saat ini ──────────────────────────────────
          _SectionHeader(label: loc.profileCountryLabel, textMuted: textMuted),
          const SizedBox(height: AppSpacing.sm),
          _LocationRow(
            draft: draft,
            isDark: isDark,
            surface: surface,
            border: border,
            textMain: textMain,
            textMuted: textMuted,
            loc: loc,
          ),

          // H2: Inline-hint PERSISTEN saat kota belum dipilih setelah ganti negara
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: state.currentLocationResolved
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      key: const Key('pe_location_hint'),
                      loc.profileSelectCityFirst,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.warn,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Seksi: Zona waktu ───────────────────────────────────────
          _TimezoneRow(
            tzLabel:
                sl<TimezoneResolver>().labelForIana(draft.timezone) ??
                draft.timezone,
            isDark: isDark,
            surface: surface,
            border: border,
            textMain: textMain,
            textMuted: textMuted,
            loc: loc,
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Toggle perantau ─────────────────────────────────────────
          _PerantauSection(
            draft: draft,
            isDark: isDark,
            surface: surface,
            border: border,
            textMain: textMain,
            textMuted: textMuted,
            loc: loc,
          ),

          // ── CTA Simpan ──────────────────────────────────────────────
          const SizedBox(height: AppSpacing.xxxl),
          _SaveButton(saving: state.saving, loc: loc),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header — label kecil muted sebagai pemisah visual ringan
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.textMuted});

  final String label;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.label.copyWith(color: textMuted));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Field nama — TextFormField dengan maxLength 80
// ─────────────────────────────────────────────────────────────────────────────

class _NameField extends StatefulWidget {
  const _NameField({
    super.key,
    required this.initialValue,
    required this.surfaceAlt,
    required this.border,
    required this.textMain,
    required this.hint,
    required this.onChanged,
  });

  final String initialValue;
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
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _ctrl,
      maxLength: 80,
      style: AppTextStyles.body.copyWith(color: widget.textMain),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: AppTextStyles.body.copyWith(
          color: widget.textMain.withValues(alpha: 0.4),
        ),
        filled: true,
        fillColor: widget.surfaceAlt,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          borderSide: BorderSide(color: widget.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          borderSide: BorderSide(color: widget.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md2,
        ),
      ),
      onChanged: widget.onChanged,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip status mahasiswa/pekerja
// ─────────────────────────────────────────────────────────────────────────────

class _StatusChips extends StatelessWidget {
  const _StatusChips({
    required this.value,
    required this.isDark,
    required this.studentKey,
    required this.workerKey,
    required this.mahasiswaLabel,
    required this.pekerjaLabel,
    required this.onChanged,
  });

  final String? value;
  final bool isDark;
  final Key studentKey;
  final Key workerKey;
  final String mahasiswaLabel;
  final String pekerjaLabel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textMain = isDark ? AppColors.textDark : AppColors.textLight;

    return Row(
      children: [
        Expanded(
          child: _ChipOption(
            widgetKey: studentKey,
            label: mahasiswaLabel,
            selected: value == 'student',
            surface: surface,
            border: border,
            textMain: textMain,
            isDark: isDark,
            onTap: () => onChanged('student'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ChipOption(
            widgetKey: workerKey,
            label: pekerjaLabel,
            selected: value == 'worker',
            surface: surface,
            border: border,
            textMain: textMain,
            isDark: isDark,
            onTap: () => onChanged('worker'),
          ),
        ),
      ],
    );
  }
}

class _ChipOption extends StatelessWidget {
  const _ChipOption({
    required this.widgetKey,
    required this.label,
    required this.selected,
    required this.surface,
    required this.border,
    required this.textMain,
    required this.isDark,
    required this.onTap,
  });

  final Key widgetKey;
  final String label;
  final bool selected;
  final Color surface;
  final Color border;
  final Color textMain;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: widgetKey,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48, // hit target ≥ 48dp
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : surface,
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: Border.all(
            color: selected ? AppColors.primary : border,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: selected ? Colors.white : textMain,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Baris lokasi — negara + kota (side-by-side)
// ─────────────────────────────────────────────────────────────────────────────

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.draft,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.textMain,
    required this.textMuted,
    required this.loc,
  });

  final PreferencesEntity draft;
  final bool isDark;
  final Color surface;
  final Color border;
  final Color textMain;
  final Color textMuted;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Negara
        Expanded(
          child: _PickerButton(
            label: draft.currentCountry,
            sublabel: loc.profileCountryLabel,
            surface: surface,
            border: border,
            textMain: textMain,
            textMuted: textMuted,
            onTap: () async {
              final result = await showCountryPicker(context);
              if (result != null && context.mounted) {
                context.read<ProfileEditCubit>().setCurrentCountry(result);
              }
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Kota
        Expanded(
          child: _PickerButton(
            label: draft.currentCity ?? '—',
            sublabel: loc.profileCityLabel,
            surface: surface,
            border: border,
            textMain: textMain,
            textMuted: textMuted,
            onTap: () async {
              // sl<TimezoneResolver>() lazy — diambil di onTap, BUKAN di build()
              final resolver = sl<TimezoneResolver>();
              final result = await showCityPicker(
                context,
                country: draft.currentCountry,
                resolver: resolver,
              );
              if (result != null && context.mounted) {
                if (result is TimezonePick) {
                  context.read<ProfileEditCubit>().setTimezone(result.iana);
                } else if (result is String) {
                  context.read<ProfileEditCubit>().setCurrentCity(result);
                }
              }
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Baris zona waktu — read-only display dengan label IANA
// ─────────────────────────────────────────────────────────────────────────────

class _TimezoneRow extends StatelessWidget {
  const _TimezoneRow({
    required this.tzLabel,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.textMain,
    required this.textMuted,
    required this.loc,
  });

  final String tzLabel;
  final bool isDark;
  final Color surface;
  final Color border;
  final Color textMain;
  final Color textMuted;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.profileTimezoneLabel,
          style: AppTextStyles.label.copyWith(color: textMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md2,
          ),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppSpacing.md),
            border: Border.all(color: border),
          ),
          child: Text(
            tzLabel,
            style: AppTextStyles.bodySmall.copyWith(color: textMain),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toggle perantau + reveal asal (AnimatedSize)
// ─────────────────────────────────────────────────────────────────────────────

class _PerantauSection extends StatelessWidget {
  const _PerantauSection({
    required this.draft,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.textMain,
    required this.textMuted,
    required this.loc,
  });

  final PreferencesEntity draft;
  final bool isDark;
  final Color surface;
  final Color border;
  final Color textMain;
  final Color textMuted;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final isPerantau = draft.isPerantau;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle — SwitchListTile memiliki hit target ≥ 48dp bawaan
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppSpacing.md),
            border: Border.all(color: border),
          ),
          child: SwitchListTile(
            key: const Key('pe_perantau'),
            value: isPerantau,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            title: Text(
              loc.profilePerantauLabel,
              style: AppTextStyles.body.copyWith(color: textMain),
            ),
            onChanged: (v) =>
                context.read<ProfileEditCubit>().togglePerantau(v),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
          ),
        ),

        // AnimatedSize reveal baris asal saat isPerantau = true
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          child: isPerantau
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        label: loc.profileHomeCountryLabel,
                        textMuted: textMuted,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _PickerButton(
                        label: draft.homeCountry,
                        sublabel: loc.profileHomeCountryLabel,
                        surface: surface,
                        border: border,
                        textMain: textMain,
                        textMuted: textMuted,
                        onTap: () async {
                          final result = await showCountryPicker(context);
                          if (result != null && context.mounted) {
                            context.read<ProfileEditCubit>().setHomeCountry(
                              result,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionHeader(
                        label: loc.profileHomeCityLabel,
                        textMuted: textMuted,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _PickerButton(
                        label: draft.homeCity ?? '—',
                        sublabel: loc.profileHomeCityLabel,
                        surface: surface,
                        border: border,
                        textMain: textMain,
                        textMuted: textMuted,
                        onTap: () async {
                          // sl lazy — diambil di onTap, BUKAN di build()
                          final resolver = sl<TimezoneResolver>();
                          final result = await showCityPicker(
                            context,
                            country: draft.homeCountry,
                            resolver: resolver,
                          );
                          if (result != null && context.mounted) {
                            if (result is String) {
                              context.read<ProfileEditCubit>().setHomeCity(
                                result,
                              );
                            }
                            // TimezonePick dari kota asal diabaikan (hanya kota)
                          }
                        },
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PickerButton — tombol pilih negara / kota (secondary surface)
// ─────────────────────────────────────────────────────────────────────────────

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.label,
    required this.sublabel,
    required this.surface,
    required this.border,
    required this.textMain,
    required this.textMuted,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final Color surface;
  final Color border;
  final Color textMain;
  final Color textMuted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: Ink(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppSpacing.md),
            border: Border.all(color: border),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 52,
            ), // hit target ≥ 48dp
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sublabel,
                          style: AppTextStyles.caption.copyWith(
                            color: textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          style: AppTextStyles.body.copyWith(color: textMain),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(Icons.expand_more, size: 20, color: textMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA Simpan — lebar penuh, pill, primary, disable + spinner saat saving
// ─────────────────────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.saving, required this.loc});

  final bool saving;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        key: const Key('pe_save'),
        onPressed: saving
            ? null
            : () => context.read<ProfileEditCubit>().save(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                loc.btnSave,
                style: AppTextStyles.label.copyWith(color: Colors.white),
              ),
      ),
    );
  }
}
