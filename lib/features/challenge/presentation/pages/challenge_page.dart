import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/app_clock.dart';
import 'package:penyintas_app/features/challenge/domain/challenge_calculator.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_phase.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_snapshot.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_week.dart';
import 'package:penyintas_app/features/challenge/domain/repositories/challenge_repository.dart';
import 'package:penyintas_app/features/challenge/presentation/bloc/challenge_bloc.dart';
import 'package:penyintas_app/features/challenge/presentation/bloc/challenge_event.dart';
import 'package:penyintas_app/features/challenge/presentation/bloc/challenge_state.dart';
import 'package:penyintas_app/features/challenge/presentation/utils/challenge_week_range.dart';
import 'package:penyintas_app/features/challenge/presentation/widgets/active_challenge_card.dart';
import 'package:penyintas_app/features/challenge/presentation/widgets/candidate_picker_sheet.dart';
import 'package:penyintas_app/features/challenge/presentation/widgets/challenge_empty_card.dart';
import 'package:penyintas_app/features/challenge/presentation/widgets/challenge_history_list.dart';
import 'package:penyintas_app/features/challenge/presentation/widgets/challenge_result_card.dart';
import 'package:penyintas_app/features/challenge/presentation/widgets/challenge_rules_sheet.dart';

/// Halaman `/challenge` (spec §7.3). Konsumen `ChallengeBloc` yang SUDAH
/// dipasang di provider rute (`app_router.dart`, pola `/consistency`) —
/// halaman ini TIDAK membuat bloc-nya sendiri, dan `ChallengeStarted` sudah
/// di-`add` sebelum halaman ini dibangun (`restartable()`, Task 13, M4).
///
/// Urutan bagian (brief Task 16): kartu hasil (bila ada) → kartu utama/kosong
/// → "RIWAYAT" (Caption `muted*` di atas `bg*`) → daftar. SATU
/// `SingleChildScrollView` — tanpa scroll di dalam scroll; `ChallengeHistoryList`
/// (Task 16) sendiri TIDAK scrollable, ia cuma `Column` biasa.
class ChallengePage extends StatelessWidget {
  const ChallengePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    // T6/T7 — jendela Senin–Selasa. Dihitung SEKALI di sini (bukan di dalam
    // BlocBuilder) karena dipakai DUA tempat yang hidup di luar BlocBuilder
    // juga: ikon `[?]` (aksi "Lewati minggu ini") dan `ActiveChallengeCard`
    // ("Ganti pos") — keduanya harus sepakat pada nilai yang SAMA persis.
    final creationWindow = isCreationWindow(sl<AppClock>().now());

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        title: Text(
          l10n.challengePageTitle,
          style: AppTextStyles.h3.copyWith(color: textColor),
        ),
        actions: [
          IconButton(
            key: const Key('challenge-help'),
            tooltip: l10n.challengeRulesA11y,
            icon: Icon(Icons.help_outline, color: textColor),
            onPressed: () => ChallengeRulesSheet.show(
              context,
              showSkip: creationWindow,
              onSkip: () => context.read<ChallengeBloc>().add(
                const ChallengeWeekSkipped(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocListener<ChallengeBloc, ChallengeState>(
          // Keputusan produk (lihat laporan Task 16) — `state.failure`
          // dikonsumsi lewat SnackBar SEKALI per kemunculan baru (edge di
          // `failure`, BUKAN gated oleh `status`: K-1 di `challenge_bloc.dart`
          // sudah mendokumentasikan kenapa syarat `status == failure` nyaris
          // tak pernah benar). SnackBar SELALU auto-dismiss — pesan galat
          // tidak pernah dirender sebagai widget permanen di pohon ini, jadi
          // ia tidak pernah "menempel selamanya" walau field `failure` di
          // state sendiri bisa bertahan sampai aksi berikutnya (perilaku
          // bawaan `ChallengeBloc`, Task 13 — di luar file yang boleh diubah
          // task ini).
          listenWhen: (prev, curr) =>
              curr.failure != null && prev.failure != curr.failure,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.challengeActionFailed,
                    style: AppTextStyles.body.copyWith(color: Colors.white),
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
          child: BlocBuilder<ChallengeBloc, ChallengeState>(
            builder: (context, state) {
              switch (state.status) {
                case ChallengeViewStatus.failure:
                  return const _FailureBody();
                case ChallengeViewStatus.initial:
                case ChallengeViewStatus.loading:
                  return const _SkeletonBody();
                case ChallengeViewStatus.ready:
                  final snapshot = state.snapshot;
                  if (snapshot == null) return const _SkeletonBody();
                  return _ReadyBody(
                    snapshot: snapshot,
                    creationWindow: creationWindow,
                  );
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
              l10n.challengeError,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: mutedColor),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              key: const Key('challenge-retry-button'),
              onPressed: () =>
                  context.read<ChallengeBloc>().add(const ChallengeStarted()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: Text(
                l10n.challengeRetry,
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
    final skeletonColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;

    Widget bar(double? width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: skeletonColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );

    return Padding(
      key: const Key('challenge-skeleton'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          bar(140, 20),
          const SizedBox(height: AppSpacing.md),
          bar(null, 180),
          const SizedBox(height: AppSpacing.xl),
          bar(80, 14),
          const SizedBox(height: AppSpacing.md),
          bar(null, 56),
        ],
      ),
    );
  }
}

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({required this.snapshot, required this.creationWindow});

  final ChallengeSnapshot snapshot;
  final bool creationWindow;

  /// U91 — TIDAK ADA `challengeBankLine` (Task 18) saat berkas ini ditulis.
  /// Placeholder yang JELAS asalnya, bukan string kosong: Task 18 menyambung
  /// penyuplai sungguhan di sini, menggantikan fungsi ini.
  String _placeholderLine(ChallengeWeek week, AppLocalizations l10n) {
    return week.status == ChallengeStatus.achieved
        ? l10n.challengeResultPlaceholderAchieved
        : l10n.challengeResultPlaceholderMissed;
  }

  Future<void> _openCandidateSheet(
    BuildContext context, {
    required ChallengeWeek week,
    required int spentThisWeek,
  }) async {
    final l10n = context.l10n;
    final bloc = context.read<ChallengeBloc>();
    final hasil = await sl<ChallengeRepository>().getCandidates(week.weekKey);
    if (!context.mounted) return;
    hasil.fold(
      (failure) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                l10n.challengeActionFailed,
                style: AppTextStyles.body.copyWith(color: Colors.white),
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
      (candidates) => CandidatePickerSheet.show(
        context,
        candidates: candidates,
        currentCategory: week.category,
        spentThisWeek: spentThisWeek,
        onPakai: (category) => bloc.add(ChallengeCategoryChanged(category)),
      ),
    );
  }

  Widget _mainCard(BuildContext context) {
    final phase = snapshot.phase;
    if (phase is PhaseActive || phase is PhaseOver) {
      final week = switch (phase) {
        PhaseActive(week: final w) => w,
        PhaseOver(week: final w) => w,
        _ => throw StateError('tidak tercapai — sudah dijaga is-check di atas'),
      };
      return ActiveChallengeCard(
        phase: phase,
        excludedSpent: snapshot.excludedThisWeek,
        daysLeft: snapshot.daysLeft,
        showChangeCategory: creationWindow,
        onChangeCategory: () => _openCandidateSheet(
          context,
          week: week,
          spentThisWeek: snapshot.spentThisWeek,
        ),
      );
    }
    return ChallengeEmptyCard(
      phase: phase,
      onEnable: phase is PhaseDisabled
          ? () => context.read<ChallengeBloc>().add(
              const ChallengeEnabledToggled(true),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final pending = snapshot.pendingResult;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pending != null) ...[
            ChallengeResultCard(
              week: pending,
              rangeLabel: challengeWeekRange(context, pending.weekKey),
              line: _placeholderLine(pending, l10n),
              onDismiss: () => context.read<ChallengeBloc>().add(
                ChallengeResultDismissed(pending.weekKey),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          _mainCard(context),
          if (snapshot.history.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.challengeHistoryTitle.toUpperCase(),
              style: AppTextStyles.caption.copyWith(color: mutedColor),
            ),
            const SizedBox(height: AppSpacing.md),
            ChallengeHistoryList(history: snapshot.history),
          ],
        ],
      ),
    );
  }
}
