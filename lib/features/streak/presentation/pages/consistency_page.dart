import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/features/streak/domain/entities/streak_snapshot.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_bloc.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_event.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_state.dart';
import 'package:penyintas_app/features/streak/presentation/widgets/streak_calendar.dart';
import 'package:penyintas_app/features/streak/presentation/widgets/streak_rules_sheet.dart';
import 'package:penyintas_app/features/survival/presentation/bloc/survival_bloc.dart';
import 'package:penyintas_app/widgets/common/count_up_text.dart';

/// Halaman `/consistency` (spec §8). Konsumen `StreakBloc` & `SurvivalBloc`
/// yang SUDAH dipasang di provider rute (lihat `app_router.dart`) — halaman
/// ini TIDAK membuat bloc-nya sendiri.
///
/// Kalender sesungguhnya (petak, legend, aksesibilitas) milik Task 13. Yang
/// ada di sini hanya SLOT ber-`Key('consistency-calendar')` — lihat catatan
/// di `_ReadyBody`.
class ConsistencyPage extends StatelessWidget {
  const ConsistencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        title: Text(
          l10n.consistencyTitle,
          style: AppTextStyles.h2.copyWith(color: textColor),
        ),
        actions: [
          IconButton(
            key: const Key('consistency-help'),
            tooltip: l10n.consistencyRulesA11y,
            icon: Icon(Icons.help_outline, color: textColor),
            onPressed: () => StreakRulesSheet.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            // Sukses menandai — tawarkan "Urungkan". `persist: false` WAJIB
            // eksplisit: tombol di bawah ini diam-diam membatalkan `duration`
            // (lihat kelas bug yang sama di `bills_list_page.dart:242`).
            BlocListener<StreakBloc, StreakState>(
              listenWhen: (prev, curr) =>
                  prev.isMarking && !curr.isMarking && curr.failure == null,
              listener: (context, state) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.consistencyMarkedSnack),
                    duration: const Duration(seconds: 5),
                    persist: false,
                    action: SnackBarAction(
                      label: l10n.consistencyUndo,
                      onPressed: () => context.read<StreakBloc>().add(
                        StreakTodayMarkUndone(),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Gagal menandai — key l10n `consistency_mark_failed`, TIDAK
            // PERNAH `failure.message` mentah (K10 — lihat `_FailureBody`).
            BlocListener<StreakBloc, StreakState>(
              listenWhen: (prev, curr) =>
                  prev.isMarking && !curr.isMarking && curr.failure != null,
              listener: (context, state) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.consistencyMarkFailed,
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: AppColors.warn,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      duration: const Duration(seconds: 4),
                      persist: false,
                    ),
                  );
              },
            ),
          ],
          child: BlocBuilder<StreakBloc, StreakState>(
            builder: (context, state) {
              switch (state.status) {
                case StreakStatus.failure:
                  // K10: angka nol yang sebenarnya berarti "gagal baca"
                  // adalah kebohongan yang dilarang — tidak ada angka, tidak
                  // ada kalender di jalur ini.
                  return const _FailureBody();
                case StreakStatus.restoring:
                case StreakStatus.initial:
                case StreakStatus.loading:
                  return const _SkeletonBody();
                case StreakStatus.ready:
                  final snapshot = state.snapshot;
                  if (snapshot == null) return const _SkeletonBody();
                  return _ReadyBody(snapshot: snapshot, isMarking: state.isMarking);
              }
            },
          ),
        ),
      ),
    );
  }
}

class _FailureBody extends StatelessWidget {
  const _FailureBody();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.consistencyError,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: mutedColor),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () =>
                  context.read<StreakBloc>().add(StreakRefreshed()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: Text(
                l10n.consistencyRetry,
                style: AppTextStyles.label.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBody extends StatelessWidget {
  const _SkeletonBody();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skeletonColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: skeletonColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );

    return Padding(
      key: const Key('consistency-skeleton'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          bar(96, 40),
          const SizedBox(height: AppSpacing.sm),
          bar(120, 16),
          const SizedBox(height: AppSpacing.xl),
          bar(double.infinity, 220), // slot kalender
          const SizedBox(height: AppSpacing.lg),
          bar(double.infinity, 20),
          const SizedBox(height: AppSpacing.sm),
          bar(double.infinity, 20),
        ],
      ),
    );
  }
}

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({required this.snapshot, required this.isMarking});

  final StreakSnapshot snapshot;
  final bool isMarking;

  /// D-11 + aturan render Step 4: CTA hilang untuk TIGA alasan berbeda —
  /// masing-masing punya sabotase & test sendiri (S2/S3, T-D11/T-ANOM).
  /// Jangan gabungkan jadi satu kondisi tanpa alasan yang sama kuatnya.
  bool get _hideCta =>
      snapshot.todayStatus == DayStatus.safe ||
      snapshot.todayStatus == DayStatus.anomaly ||
      snapshot.markedDaysAll.contains(snapshot.today);

  String _chipText(AppLocalizations l10n) {
    if (snapshot.todayStatus == DayStatus.safe) return l10n.consistencyTodayDone;
    if (snapshot.todayStatus == DayStatus.anomaly) {
      return l10n.consistencyTodayAnomaly;
    }
    if (snapshot.markedDaysAll.contains(snapshot.today)) {
      return l10n.consistencyTodayMarked;
    }
    return l10n.consistencyTodayPending;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Column(
              children: [
                if (!snapshot.hasStarted)
                  // Empty state (§8.2): TIDAK menampilkan angka "0" — copy
                  // kanonik proyek saja.
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Text(
                      l10n.consistencyEmpty,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(color: mutedColor),
                    ),
                  )
                else
                  BlocBuilder<SurvivalBloc, SurvivalState>(
                    builder: (context, survivalState) {
                      final survivalActive = survivalState is SurvivalActive;
                      final style = AppTextStyles.numericLg.copyWith(
                        color: textColor,
                      );
                      final format = survivalActive
                          ? (int v) => l10n.consistencySurvivalDays(v)
                          : (int v) => '$v';
                      return Column(
                        children: [
                          _AnimatedOrPlainNumber(
                            value: snapshot.currentStreak,
                            style: style,
                            format: format,
                          ),
                          // Sentence "Hari ke-N kamu bertahan" sudah membawa
                          // makna label ini — dobel di bawahnya jadi redundan.
                          if (!survivalActive)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.xs,
                              ),
                              child: Text(
                                l10n.consistencyDaysLabel,
                                style: AppTextStyles.body.copyWith(
                                  color: mutedColor,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    _chipText(l10n),
                    style: AppTextStyles.bodySmall.copyWith(color: textColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SizedBox(height: AppSpacing.lg),
          // Kalender konsistensi (Task 13) — grid petak, legend & label
          // Semantics. `Key('consistency-calendar')` dipertahankan: jalur
          // galat (`_FailureBody`) mengasersi key ini HILANG sepenuhnya.
          KeyedSubtree(
            key: const Key('consistency-calendar'),
            child: StreakCalendar(snapshot: snapshot),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (snapshot.hasStarted) ...[
            Divider(color: borderColor, height: AppSpacing.xl),
            _StatRow(
              label: l10n.consistencyLongest,
              value: '${snapshot.longestRuas} hari',
            ),
            _StatRow(
              label: l10n.consistencyGraceLeft,
              value: '${snapshot.graceAvailable} hari',
              trailing: IconButton(
                key: const Key('consistency-grace-help'),
                tooltip: l10n.consistencyRulesA11y,
                icon: const Icon(Icons.help_outline, size: 18),
                onPressed: () => StreakRulesSheet.show(context),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (!_hideCta)
            ElevatedButton(
              key: const Key('consistency-cta'),
              onPressed: isMarking
                  ? null
                  : () =>
                        context.read<StreakBloc>().add(StreakTodayMarked()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withAlpha(100),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white70,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: Text(
                l10n.consistencyCtaNoSpend,
                style: AppTextStyles.label.copyWith(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

/// §8.3: semua gerak menghormati `MediaQuery.disableAnimations`. `true` →
/// `Text` biasa, bukan `CountUpText`.
class _AnimatedOrPlainNumber extends StatelessWidget {
  const _AnimatedOrPlainNumber({
    required this.value,
    required this.style,
    required this.format,
  });

  final int value;
  final TextStyle style;
  final String Function(int) format;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return Text(format(value), style: style);
    }
    return CountUpText(value: value, style: style, format: format);
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, this.trailing});

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(color: mutedColor),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.numericSm.copyWith(color: textColor),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
