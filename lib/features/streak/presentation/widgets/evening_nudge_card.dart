import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/app_clock.dart';
import 'package:penyintas_app/features/streak/domain/entities/streak_snapshot.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_bloc.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_event.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_state.dart';
import 'package:penyintas_app/features/survival/presentation/bloc/survival_bloc.dart';

/// Kartu sore di dashboard (Task 17, spec §9.2) — bertanya, bukan menagih.
///
/// **Aturan tampil** (lima aturan, masing-masing terkunci sabotase sendiri —
/// lihat plan Task 17 Step 6):
/// - Muncul HANYA bila hari ini belum aman (`todayStatus != DayStatus.safe`)
///   DAN waktu lokal >= ambang `min(17:00, jam pengingat harian user)`.
/// - Pengingat mati -> ambang tetap 17:00 (bukan ambang tak berbatas).
/// - Hilang seketika begitu hari menjadi aman (dibaca ulang tiap emisi
///   `StreakBloc` lewat `BlocBuilder`, bukan snapshot beku).
/// - TIDAK PERNAH muncul saat `hasStarted == false` — pengguna yang baru
///   memasang app tidak ditagih pada sore pertamanya sebelum ia tahu fitur
///   ini ada.
///
/// Bukan alarm: latar `cardLight`/`cardDark`, BUKAN `AppColors.warn`. Saat
/// Survival Mode aktif (`SurvivalActive`) nadanya melunak (K8) — dua tombol
/// yang sama, hanya judulnya yang berganti.
///
/// Sumber waktu WAJIB disuntik lewat [clock] — ambangnya diuji pada
/// 16:59/17:00/16:00 dan `DateTime.now()` di dalam widget membuat itu
/// mustahil dijalankan deterministik.
class EveningNudgeCard extends StatelessWidget {
  const EveningNudgeCard({
    super.key,
    required this.reminderHour,
    required this.reminderMinute,
    required this.reminderEnabled,
    required this.clock,
    required this.onRecord,
  });

  final int reminderHour;
  final int reminderMinute;
  final bool reminderEnabled;
  final AppClock clock;

  /// Membuka sheet tambah transaksi. `DashboardPage` mengoper method
  /// privatnya sendiri (`_openAddSheet`) — jangan buka sheet kedua di sini.
  final VoidCallback onRecord;

  static const int _defaultThresholdMinutes = 17 * 60;

  int get _thresholdMinutes {
    if (!reminderEnabled) return _defaultThresholdMinutes;
    final reminderMinutes = reminderHour * 60 + reminderMinute;
    return reminderMinutes < _defaultThresholdMinutes
        ? reminderMinutes
        : _defaultThresholdMinutes;
  }

  bool get _isPastThreshold {
    final now = clock.now();
    return (now.hour * 60 + now.minute) >= _thresholdMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StreakBloc, StreakState>(
      builder: (context, streakState) {
        final snapshot = streakState.snapshot;
        if (snapshot == null) return const SizedBox.shrink();
        if (!snapshot.hasStarted) return const SizedBox.shrink();
        if (snapshot.todayStatus == DayStatus.safe) {
          return const SizedBox.shrink();
        }
        if (!_isPastThreshold) return const SizedBox.shrink();

        return BlocBuilder<SurvivalBloc, SurvivalState>(
          builder: (context, survivalState) {
            return _EveningNudgeCardBody(
              isSurvivalActive: survivalState is SurvivalActive,
              isMarking: streakState.isMarking,
              onRecord: onRecord,
            );
          },
        );
      },
    );
  }
}

class _EveningNudgeCardBody extends StatelessWidget {
  const _EveningNudgeCardBody({
    required this.isSurvivalActive,
    required this.isMarking,
    required this.onRecord,
  });

  final bool isSurvivalActive;
  final bool isMarking;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    final title = isSurvivalActive
        ? l10n.consistencyEveningTitleSurvival
        : l10n.consistencyEveningTitle;

    return Container(
      key: const Key('evening-nudge-card'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTextStyles.body.copyWith(color: textColor)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('evening-nudge-no-spend'),
                  onPressed: isMarking
                      ? null
                      : () =>
                            context.read<StreakBloc>().add(StreakTodayMarked()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(color: borderColor),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: Text(
                    l10n.consistencyCtaNoSpend,
                    style: AppTextStyles.label.copyWith(color: textColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  key: const Key('evening-nudge-record'),
                  onPressed: onRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: Text(
                    l10n.consistencyEveningRecord,
                    style: AppTextStyles.label.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
