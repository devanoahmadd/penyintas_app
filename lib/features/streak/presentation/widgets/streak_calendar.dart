import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/date_helper.dart';
import 'package:penyintas_app/features/streak/domain/entities/streak_snapshot.dart';
import 'package:penyintas_app/widgets/common/dashed_border_painter.dart';

/// Kalender konsistensi — petak, legend, aksesibilitas (spec §8.2 & §8.4).
///
/// Petak hari TIDAK interaktif — ambang sentuh 44/48dp tidak berlaku
/// untuknya (§8.4). Chevron navigasi bulan ADALAH interaktif dan wajib
/// ≥48dp bahkan saat disabled — tombol mati di sini justru informatif
/// (menandai ujung riwayat).
///
/// State internalnya HANYA bulan yang sedang ditampilkan.
class StreakCalendar extends StatefulWidget {
  const StreakCalendar({super.key, required this.snapshot});

  final StreakSnapshot snapshot;

  @override
  State<StreakCalendar> createState() => _StreakCalendarState();
}

class _StreakCalendarState extends State<StreakCalendar> {
  late int _displayedMonthKey; // yyyymm

  @override
  void initState() {
    super.initState();
    _displayedMonthKey = _monthKeyOf(widget.snapshot.today);
  }

  static int _monthKeyOf(int dayKey) => dayKey ~/ 100;

  static int _shiftMonth(int monthKey, int delta) {
    final year = monthKey ~/ 100;
    final month = monthKey % 100;
    final total = year * 12 + (month - 1) + delta;
    final newYear = total ~/ 12;
    final newMonth = total % 12 + 1;
    return newYear * 100 + newMonth;
  }

  static int _firstDayOfMonthKey(int monthKey) =>
      (monthKey ~/ 100) * 10000 + (monthKey % 100) * 100 + 1;

  void _goPrev() =>
      setState(() => _displayedMonthKey = _shiftMonth(_displayedMonthKey, -1));

  void _goNext() =>
      setState(() => _displayedMonthKey = _shiftMonth(_displayedMonthKey, 1));

  /// Sel bulan yang ditampilkan — null = padding perataan minggu, BUKAN hari
  /// sungguhan (hari dari bulan sebelum/sesudah tidak ikut dirender).
  List<int?> _buildMonthCells(int monthKey) {
    final year = monthKey ~/ 100;
    final month = monthKey % 100;
    final firstWeekday = DateTime(year, month, 1).weekday; // 1=Senin..7=Minggu
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leading = firstWeekday - 1;
    final cells = <int?>[
      for (var i = 0; i < leading; i++) null,
      for (var d = 1; d <= daysInMonth; d++) year * 10000 + month * 100 + d,
    ];
    final trailing = (7 - cells.length % 7) % 7;
    cells.addAll(List<int?>.filled(trailing, null));
    return cells;
  }

  String _statusText(AppLocalizations l10n, DayCell cell) {
    switch (cell) {
      case DayCell.beforeStart:
        return l10n.consistencyCellBeforeStart;
      case DayCell.recorded:
        return l10n.consistencyCellRecorded;
      case DayCell.markedNihil:
        return l10n.consistencyCellMarkedNihil;
      case DayCell.graceUsed:
        return l10n.consistencyCellGraceUsed;
      case DayCell.missed:
        return l10n.consistencyCellMissed;
      case DayCell.today:
        return l10n.consistencyCellToday;
      case DayCell.future:
        return l10n.consistencyCellFuture;
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    final activatedMonthKey = _monthKeyOf(snapshot.activatedDay);
    final todayMonthKey = _monthKeyOf(snapshot.today);
    final canGoBack = _displayedMonthKey > activatedMonthKey;
    final canGoForward = _displayedMonthKey < todayMonthKey;

    final monthTitle = DateFormat(
      'MMMM yyyy',
      locale,
    ).format(localMidnightOf(_firstDayOfMonthKey(_displayedMonthKey)));

    // Kepala kolom hari — DateFormat('EEEEE', locale) atas 7 hari berurutan
    // mulai Senin (2024-01-01 adalah Senin — basis netral, tak tersandung
    // DST). BUKAN array nama hari diketik tangan.
    final weekdayHeaders = List<String>.generate(
      7,
      (i) => DateFormat('EEEEE', locale).format(DateTime(2024, 1, 1 + i)),
    );

    final cells = _buildMonthCells(_displayedMonthKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              key: const Key('cal-prev'),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: canGoBack ? _goPrev : null,
              icon: Icon(Icons.chevron_left, color: textColor),
            ),
            Expanded(
              child: Text(
                monthTitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.h3.copyWith(color: textColor),
              ),
            ),
            IconButton(
              key: const Key('cal-next'),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: canGoForward ? _goNext : null,
              icon: Icon(Icons.chevron_right, color: textColor),
            ),
          ],
        ),
        Row(
          key: const Key('cal-weekday-header'),
          children: weekdayHeaders
              .map(
                (h) => Expanded(
                  child: Center(
                    child: Text(
                      h,
                      style: AppTextStyles.caption.copyWith(color: mutedColor),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.xs),
        GridView.count(
          crossAxisCount: 7,
          mainAxisSpacing: 0,
          crossAxisSpacing: 0,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cells.map((dayKey) {
            if (dayKey == null) return const SizedBox.shrink();

            final isToday = dayKey == snapshot.today;
            final isAnomalyToday =
                isToday && snapshot.todayStatus == DayStatus.anomaly;
            final isSafeToday =
                isToday && snapshot.todayStatus == DayStatus.safe;
            final cell = snapshot.cellFor(dayKey);
            final dateLabel = DateFormat(
              'd MMMM',
              locale,
            ).format(localMidnightOf(dayKey));
            final semanticsLabel = l10n.consistencyCellSemantics(
              dateLabel,
              _statusText(l10n, cell),
            );

            if (isToday && !isAnomalyToday) {
              return _TodayCellPop(
                dayKey: dayKey,
                isSafe: isSafeToday,
                disableAnimations: disableAnimations,
                isDark: isDark,
                semanticsLabel: semanticsLabel,
              );
            }

            return _DayCell(
              dayKey: dayKey,
              // Koreksi C #2: saat jam device kacau, petak "hari ini" TIDAK
              // pernah dirender — dipaksa netral (null), bukan `cellFor`
              // apa adanya. `cellFor` sendiri tidak tahu soal anomaly.
              cell: isAnomalyToday ? null : cell,
              isDark: isDark,
              semanticsLabel: semanticsLabel,
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.md),
        _Legend(key: const Key('consistency-legend'), l10n: l10n, isDark: isDark),
      ],
    );
  }
}

/// Petak hari biasa (statis, tanpa animasi). `cell == null` berarti dipaksa
/// netral — dipakai satu-satunya oleh Koreksi C #2 (hari ini saat anomaly).
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.dayKey,
    required this.cell,
    required this.isDark,
    required this.semanticsLabel,
  });

  final int dayKey;
  final DayCell? cell;
  final bool isDark;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Semantics(
        label: semanticsLabel,
        // Ganti seluruh semantics deskendan (angka tanggal, ikon centang)
        // dengan SATU label utuh — tanpa ini pembaca layar mengucapkan
        // "2" dulu lalu label ini, dobel dan membingungkan.
        excludeSemantics: true,
        child: _shape(),
      ),
    );
  }

  Widget _shape() {
    final key = Key('cell-$dayKey');
    final tintFill = isDark
        ? AppColors.shoot.withValues(alpha: 0.07)
        : AppColors.primary.withValues(alpha: 0.06);
    final tintBorder = isDark
        ? AppColors.shoot.withValues(alpha: 0.3)
        : AppColors.primary.withValues(alpha: 0.25);
    final mutedBorder = isDark ? AppColors.borderDark : AppColors.borderLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final day = dayKey % 100;
    final numStyle = AppTextStyles.numericSm.copyWith(
      fontSize: 11,
      color: textColor,
    );

    switch (cell) {
      case null:
      case DayCell.beforeStart:
        // Kosong netral, TANPA outline (spec §5.3 baris 1 & Koreksi C).
        return SizedBox.expand(key: key);
      case DayCell.future:
        return Container(
          key: key,
          alignment: Alignment.center,
          child: Text(
            '·',
            style: TextStyle(
              color: mutedColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case DayCell.recorded:
        return Container(
          key: key,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tintFill,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text('$day', style: numStyle),
        );
      case DayCell.markedNihil:
        return Container(
          key: key,
          decoration: BoxDecoration(
            color: tintFill,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Stack(
            children: [
              Center(child: Text('$day', style: numStyle)),
              Positioned(
                right: 1,
                bottom: 1,
                child: Icon(Icons.check, size: 8, color: tintBorder),
              ),
            ],
          ),
        );
      case DayCell.graceUsed:
        return CustomPaint(
          key: key,
          foregroundPainter: DashedBorderPainter(
            color: tintBorder,
            radius: AppRadius.sm,
          ),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tintFill,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text('$day', style: numStyle),
          ),
        );
      case DayCell.missed:
        return Container(
          key: key,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: mutedBorder),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text('$day', style: numStyle.copyWith(color: mutedColor)),
        );
      case DayCell.today:
        // Tak pernah dicapai lewat rute normal — `StreakCalendar` selalu
        // mengarahkan `dayKey == today` (non-anomaly) ke `_TodayCellPop`.
        return SizedBox.expand(key: key);
    }
  }
}

/// Petak "hari ini" — satu-satunya elemen kalender yang bergerak
/// (`excessive-motion`, spec §8.3): scale-pop SEKALI saat `todayStatus`
/// bertransisi menjadi `safe`, dideteksi lewat `didUpdateWidget`.
class _TodayCellPop extends StatefulWidget {
  const _TodayCellPop({
    required this.dayKey,
    required this.isSafe,
    required this.disableAnimations,
    required this.isDark,
    required this.semanticsLabel,
  });

  final int dayKey;
  final bool isSafe;
  final bool disableAnimations;
  final bool isDark;
  final String semanticsLabel;

  @override
  State<_TodayCellPop> createState() => _TodayCellPopState();
}

class _TodayCellPopState extends State<_TodayCellPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        weight: 45,
        tween: Tween(
          begin: 1.0,
          end: 1.35,
        ).chain(CurveTween(curve: Curves.easeOut)),
      ),
      TweenSequenceItem(
        weight: 55,
        tween: Tween(
          begin: 1.35,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
      ),
    ]).animate(_ctrl);
  }

  @override
  void didUpdateWidget(covariant _TodayCellPop old) {
    super.didUpdateWidget(old);
    // Pop HANYA pada transisi pending/anomaly -> safe, SEKALI. Rebuild lain
    // (mis. tema berganti, atau state tetap safe) tidak boleh memicu ulang.
    final justBecameSafe = !old.isSafe && widget.isSafe;
    if (!justBecameSafe) return;
    if (widget.disableAnimations) {
      // §8.3: semua gerak menghormati `disableAnimations` — langsung ke
      // skala akhir, tanpa frame antara.
      _ctrl.value = 1.0;
    } else {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markerColor = widget.isDark ? AppColors.shoot : AppColors.primary;
    final onMarker = widget.isDark ? AppColors.bgDark : Colors.white;
    final day = widget.dayKey % 100;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Semantics(
        label: widget.semanticsLabel,
        excludeSemantics: true,
        child: ScaleTransition(
          key: const Key('today-cell-scale'),
          scale: _scale,
          child: Container(
            key: Key('cell-${widget.dayKey}'),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: markerColor, shape: BoxShape.circle),
            child: Text(
              '$day',
              style: AppTextStyles.numericSm.copyWith(
                fontSize: 11,
                color: onMarker,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Legend empat status yang dibedakan bentuk (`color-not-only`). Selalu
/// tampil, tidak di balik scroll — `Wrap` sendiri tidak scrollable.
class _Legend extends StatelessWidget {
  const _Legend({super.key, required this.l10n, required this.isDark});

  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final tintFill = isDark
        ? AppColors.shoot.withValues(alpha: 0.07)
        : AppColors.primary.withValues(alpha: 0.06);
    final tintBorder = isDark
        ? AppColors.shoot.withValues(alpha: 0.3)
        : AppColors.primary.withValues(alpha: 0.25);
    final mutedBorder = isDark ? AppColors.borderDark : AppColors.borderLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    Widget swatch(Widget glyph) => SizedBox(width: 14, height: 14, child: glyph);

    // Setiap entri dibungkus `Expanded` di level BARIS (bukan `Wrap`
    // ber-`mainAxisSize.min`) supaya label terpanjang ("ditandai tanpa
    // pengeluaran") bisa membungkus baris tanpa RenderFlex overflow di
    // layar sempit (320dp) — lihat sabotase/percobaan sebelumnya.
    Widget item(Widget glyph, String label) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          swatch(glyph),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              softWrap: true,
              style: AppTextStyles.caption.copyWith(color: mutedColor),
            ),
          ),
        ],
      ),
    );

    final entries = [
      item(
        DecoratedBox(
          decoration: BoxDecoration(
            color: tintFill,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        l10n.consistencyCellRecorded,
      ),
      item(
        DecoratedBox(
          decoration: BoxDecoration(
            color: tintFill,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Center(child: Icon(Icons.check, size: 8, color: tintBorder)),
        ),
        l10n.consistencyCellMarkedNihil,
      ),
      item(
        CustomPaint(
          foregroundPainter: DashedBorderPainter(
            color: tintBorder,
            radius: AppRadius.sm,
          ),
        ),
        l10n.consistencyCellGraceUsed,
      ),
      item(
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: mutedBorder),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        l10n.consistencyCellMissed,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: entries[0]),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: entries[1]),
          ],
        ),
        Row(
          children: [
            Expanded(child: entries[2]),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: entries[3]),
          ],
        ),
      ],
    );
  }
}
