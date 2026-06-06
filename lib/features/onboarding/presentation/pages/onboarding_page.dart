import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/routing/app_router.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/core/utils/date_helper.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_event.dart';
import 'package:penyintas_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:penyintas_app/features/onboarding/presentation/widgets/grow_shoot.dart';
import 'package:penyintas_app/features/onboarding/presentation/widgets/onboarding_count_up.dart';
import 'package:penyintas_app/features/onboarding/presentation/widgets/onboarding_keypad.dart';
import 'package:penyintas_app/features/onboarding/presentation/widgets/onboarding_ruas_progress.dart';

// ── Constants ──────────────────────────────────────────────────────────────
const _kIncomePresets = [800000, 1500000, 3000000, 5000000];
const _kPaydayPresets = [1, 5, 15, 25];
const _kPctPresets = [0, 5, 10, 15]; // chip; 25 = Ekstrem

class _ExpRow {
  const _ExpRow(this.id, this.icon);
  final String id;
  final IconData icon;

  String label(AppLocalizations l) {
    switch (id) {
      case 'kos': return l.onboardingExpenseRent;
      case 'listrik': return l.onboardingExpenseUtilities;
      case 'internet': return l.onboardingExpenseInternet;
      case 'pulsa': return l.onboardingExpensePhone;
      default: return l.categoryOther;
    }
  }
}

const _kExpRows = [
  _ExpRow('kos', Icons.home_outlined),
  _ExpRow('listrik', Icons.bolt_outlined),
  _ExpRow('internet', Icons.wifi_rounded),
  _ExpRow('pulsa', Icons.phone_android_outlined),
  _ExpRow('lain', Icons.more_horiz_rounded),
];

// ── Calc ───────────────────────────────────────────────────────────────────
class _Calc {
  const _Calc({
    required this.fixed,
    required this.sisa,
    required this.cicilan,
    required this.spendable,
    required this.daily,
    required this.fixedPct,
  });
  final int fixed, sisa, cicilan, spendable, daily, fixedPct;
}

_Calc _calcBudget({
  required int income,
  required int payday,
  required Map<String, int> expenses,
  required int pct,
}) {
  final fixed = expenses.values.fold(0, (s, v) => s + v);
  final sisa = math.max(0, income - fixed);
  final cicilan = sisa > 0 ? (sisa * pct / 100).round() : 0;
  final spendable = math.max(0, sisa - cicilan);
  int days = remainingDaysInCycle(payday);
  if (days == 0) days = daysInCycle(payday);
  final daily = days > 0 ? (spendable / days).floor() : 0;
  final fixedPct = income > 0 ? (fixed / income * 100).round() : 0;
  return _Calc(
    fixed: fixed,
    sisa: sisa,
    cicilan: cicilan,
    spendable: spendable,
    daily: daily,
    fixedPct: fixedPct,
  );
}

// ── Helpers ────────────────────────────────────────────────────────────────
String _rpShort(int n) {
  if (n >= 1000000) {
    final jt = n / 1000000;
    final s = jt % 1 == 0
        ? '${jt.toInt()}'
        : jt.toStringAsFixed(1).replaceAll('.', ',');
    return 'Rp ${s}jt';
  }
  if (n >= 1000) return 'Rp ${(n / 1000).round()}rb';
  return formatRupiah(n);
}

String _fmtId(int n) => NumberFormat('#,##0', 'id_ID').format(n);

({String label, String note}) _pctFb(int pct, AppLocalizations l) {
  if (pct == 0) return (label: l.onboardingEmergencySkip, note: l.onboardingPctNoteSkip);
  if (pct <= 7) return (label: l.onboardingPctLabelLow, note: l.onboardingPctNoteLow);
  if (pct <= 12) return (label: l.onboardingPctLabelMid, note: l.onboardingPctNoteMid);
  if (pct <= 19) return (label: l.onboardingPctLabelHigh, note: l.onboardingPctNoteHigh);
  return (label: l.onboardingPctLabelMax, note: l.onboardingPctNoteMax);
}

// ── Exit dialog ─────────────────────────────────────────────────────────────
Future<void> _showExitDialog(BuildContext context) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
  final textColor = isDark ? AppColors.textDark : AppColors.textLight;
  final textSoftColor = isDark ? AppColors.textSoftDark : AppColors.textSoftLight;

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('Tutup setup sekarang?',
          style: AppTextStyles.h3.copyWith(color: textColor)),
      content: Text('Progress belum tersimpan.',
          style: AppTextStyles.bodySmall.copyWith(color: textSoftColor)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Lanjut isi',
              style: AppTextStyles.label.copyWith(color: AppColors.primary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text('Ya, keluar',
              style: AppTextStyles.label.copyWith(color: AppColors.warn)),
        ),
      ],
    ),
  );
  if (confirmed == true) SystemNavigator.pop();
}

// ══════════════════════════════════════════════════════════════════════════════
//  PAGE
// ══════════════════════════════════════════════════════════════════════════════

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  // ── Local reactive model ─────────────────────────────────────────
  int _income = 2500000;
  int _payday = 1;
  final Map<String, int> _exp = {
    'kos': 450000,
    'listrik': 0,
    'internet': 0,
    'pulsa': 0,
    'lain': 0,
  };
  int _pct = 10;
  int _step = 0;
  String? _activeRow; // step 1 sheet

  // ── Animation ────────────────────────────────────────────────────
  late final AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 585), // step 0 = 520+65
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _playEntrance());
    context.read<OnboardingBloc>().add(const OnboardingStarted());
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  void _playEntrance() {
    if (!mounted) return;
    if (MediaQuery.of(context).disableAnimations) {
      _staggerCtrl.value = 1.0;
      return;
    }
    final n = _childCount(_step);
    if (_step == 3) {
      _staggerCtrl.duration = const Duration(milliseconds: 670);
    } else {
      _staggerCtrl.duration = Duration(milliseconds: 520 + 65 * (n - 1));
    }
    _staggerCtrl.forward(from: 0);
  }

  int _childCount(int step) {
    switch (step) {
      case 0: return 2;
      case 1: return 3;
      case 2: return 6;
      default: return 5; // done = 5 reveal items
    }
  }

  void _next() {
    setState(() {
      _step = math.min(3, _step + 1);
      _activeRow = null;
    });
    _playEntrance();
  }

  void _back() {
    setState(() {
      _step = math.max(0, _step - 1);
      _activeRow = null;
    });
    _playEntrance();
  }

  _Calc get _calc => _calcBudget(
        income: _income,
        payday: _payday,
        expenses: _exp,
        pct: _pct,
      );

  // ── Animation helpers ─────────────────────────────────────────────
  Widget _stagger(Widget child, int i, int n) {
    if (MediaQuery.of(context).disableAnimations) return child;
    final base = 520.0, gap = 65.0;
    final total = base + gap * (n - 1);
    final start = (gap * i / total).clamp(0.0, 1.0);
    final end = ((gap * i + base) / total).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: _staggerCtrl,
      curve: Interval(start, end, curve: const Cubic(0.2, 0.7, 0.3, 1.0)),
    );
    return _FadeSlide(anim: anim, child: child);
  }

  Widget _reveal(Widget child, int delayMs) {
    if (MediaQuery.of(context).disableAnimations) return child;
    const total = 670.0, dur = 500.0;
    final start = (delayMs / total).clamp(0.0, 1.0);
    final end = ((delayMs + dur) / total).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: _staggerCtrl,
      curve: Interval(start, end, curve: const Cubic(0.2, 0.7, 0.3, 1.0)),
    );
    return _FadeSlide(anim: anim, child: child);
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (_step == 0) {
            _showExitDialog(context);
          } else {
            _back();
          }
        }
      },
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: BlocConsumer<OnboardingBloc, OnboardingState>(
            listenWhen: (_, c) =>
                c is OnboardingSuccess || c is OnboardingError,
            listener: (context, state) {
              if (state is OnboardingSuccess) {
                context.read<NotificationBloc>().add(const RequestPermission());
                resetOnboardingCache();
                context.go('/dashboard');
              } else if (state is OnboardingError) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    content: Text(state.message,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white)),
                    backgroundColor: AppColors.warn,
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: l.retry,
                      textColor: Colors.white,
                      onPressed: () => context
                          .read<OnboardingBloc>()
                          .add(const OnboardingRetryRequested()),
                    ),
                  ));
              }
            },
            builder: (context, state) {
              final isSubmitting = state is OnboardingCalculating;
              final calc = _calc;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_step < 3) _buildHeader(isDark, l),
                  Expanded(
                    child: _buildContent(isDark, l, calc, isSubmitting),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark, AppLocalizations l) {
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: _step == 0
                  ? GestureDetector(
                      onTap: () => _showExitDialog(context),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l.onboardingSkipLater,
                          style: TextStyle(
                            fontFamily: 'InterTight',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: muted,
                          ),
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: _back,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: textColor,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OnboardingRuasProgress(step: _step, isDark: isDark),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 28,
              child: Text(
                '${_step + 1}/3',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11,
                  color: muted,
                  height: 1,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step dispatcher ────────────────────────────────────────────────
  Widget _buildContent(
    bool isDark,
    AppLocalizations l,
    _Calc calc,
    bool isSubmitting,
  ) {
    switch (_step) {
      case 0:
        return _buildStep0(isDark, l);
      case 1:
        return _buildStep1(isDark, l, calc);
      case 2:
        return _buildStep2(isDark, l, calc);
      default:
        return _buildDone(isDark, l, calc, isSubmitting);
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  RUAS 1 · Pemasukan
  // ════════════════════════════════════════════════════════════════
  Widget _buildStep0(bool isDark, AppLocalizations l) {
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final surfaceAlt = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight;

    const n = 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // child 0: upper centered content
        Expanded(
          child: _stagger(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // eyebrow
                  Text(
                    l.onboardingEyebrowStep1,
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 11,
                      letterSpacing: 0.14 * 11,
                      color: AppColors.primary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // title
                  Text(
                    l.onboardingTitleIncome,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.02 * 20,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Rp + amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Rp',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: muted,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _fmtId(_income),
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: _income > 0 ? textColor : muted,
                          letterSpacing: -0.03 * 40,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // divider
                  Container(width: 176, height: 2, color: border),
                  const SizedBox(height: 14),
                  // income preset chips
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 7,
                    runSpacing: 7,
                    children: _kIncomePresets.map((v) {
                      final on = _income == v;
                      return _PresetChip(
                        label: _rpShort(v),
                        active: on,
                        isDark: isDark,
                        onTap: () => setState(() => _income = v),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  // payday label
                  Text(
                    l.onboardingPaydayLabel,
                    style: TextStyle(
                      fontFamily: 'InterTight',
                      fontSize: 12,
                      color: muted,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 9),
                  // payday chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ..._kPaydayPresets.map((d) {
                          final on = _payday == d;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _PaydayChipWidget(
                              label: '$d',
                              active: on,
                              isDark: isDark,
                              onTap: () => setState(() => _payday = d),
                            ),
                          );
                        }),
                        _PaydayChipWidget(
                          label: l.onboardingChipOtherDate,
                          active: !_kPaydayPresets.contains(_payday),
                          isDark: isDark,
                          wide: true,
                          onTap: () => _openPaydayPicker(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            0, n,
          ),
        ),
        // child 1: docked keypad panel
        _stagger(
          _DockedPanel(
            isDark: isDark,
            surfaceAlt: surfaceAlt,
            keypad: OnboardingKeypad(
              isDark: isDark,
              onKey: (k) => setState(() {
                _income = applyOnboardingKey(_income, k);
              }),
            ),
            cta: _CtaBtn(
              label: l.btnNext,
              height: 52,
              onPressed: _next,
            ),
          ),
          1, n,
        ),
      ],
    );
  }

  Future<void> _openPaydayPicker() async {
    final initial = _kPaydayPresets.contains(_payday) ? 28 : _payday;
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DatePickerSheet(
        initialDate: initial,
        onConfirm: (v) {},
      ),
    );
    if (picked != null && mounted) setState(() => _payday = picked);
  }

  // ════════════════════════════════════════════════════════════════
  //  RUAS 2 · Pengeluaran tetap
  // ════════════════════════════════════════════════════════════════
  Widget _buildStep1(bool isDark, AppLocalizations l, _Calc calc) {
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.cardLight;
    final surfaceAlt = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight;

    final activeRowDef = _kExpRows.where((r) => r.id == _activeRow).firstOrNull;
    const n = 3;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // child 0: eyebrow + title
            _stagger(
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                child: Column(
                  children: [
                    Text(
                      l.onboardingEyebrowStep2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 11,
                        letterSpacing: 0.14 * 11,
                        color: AppColors.primary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      l.onboardingTitleFixed,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.02 * 24,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              0, n,
            ),
            // child 1: expense rows
            Expanded(
              child: _stagger(
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(_kExpRows.length, (i) {
                      final row = _kExpRows[i];
                      final v = _exp[row.id] ?? 0;
                      final on = _activeRow == row.id;
                      return _ExpRowWidget(
                        row: row,
                        value: v,
                        active: on,
                        isDark: isDark,
                        isFirst: i == 0,
                        l: l,
                        onTap: () => setState(() {
                          _activeRow = on ? null : row.id;
                        }),
                      );
                    }),
                  ),
                ),
                1, n,
              ),
            ),
            // child 2: total card
            _stagger(
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: _TotalCard(
                  fixed: calc.fixed,
                  fixedPct: calc.fixedPct,
                  l: l,
                ),
              ),
              2, n,
            ),
            // CTA — only when sheet closed
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _activeRow == null
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
                      child: _CtaBtn(
                        label: l.btnNext,
                        height: 58,
                        onPressed: _next,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        // Bottom sheet keypad
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            ignoring: activeRowDef == null,
            child: AnimatedOpacity(
              opacity: activeRowDef != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.ease,
              child: AnimatedSlide(
                offset: activeRowDef != null
                    ? Offset.zero
                    : const Offset(0, 0.4),
                duration: const Duration(milliseconds: 250),
                curve: Curves.ease,
                child: activeRowDef != null
                    ? _SheetKeypad(
                        activeRow: activeRowDef,
                        value: _exp[_activeRow ?? 'kos'] ?? 0,
                        calc: calc,
                        isDark: isDark,
                        surfaceAlt: surfaceAlt,
                        surface: surface,
                        l: l,
                        onKey: (k) {
                          final id = _activeRow ?? 'kos';
                          setState(() {
                            _exp[id] = applyOnboardingKey(_exp[id] ?? 0, k);
                          });
                        },
                        onDone: () => setState(() => _activeRow = null),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  RUAS 3 · Dana darurat
  // ════════════════════════════════════════════════════════════════
  Widget _buildStep2(bool isDark, AppLocalizations l, _Calc calc) {
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSoft = isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
    final surfaceAlt = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight;
    final grow = (_pct / 25).clamp(0.12, 1.0);
    final fb = _pctFb(_pct, l);
    final fillColor = _pct >= 20 ? AppColors.primaryBright : AppColors.primary;
    const n = 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 0: eyebrow + title
                _stagger(
                  Column(children: [
                    const SizedBox(height: 14),
                    Text(l.onboardingEyebrowStep3,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                          letterSpacing: 0.14 * 11,
                          color: AppColors.primary,
                          height: 1,
                        )),
                    const SizedBox(height: 7),
                    Text(l.onboardingTitleDarurat,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.02 * 24,
                          height: 1.15,
                        )),
                  ]),
                  0, n,
                ),
                // 1: hero — GrowShoot + daily
                _stagger(
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(children: [
                      GrowShoot(grow: grow, size: 54, isDark: isDark),
                      const SizedBox(height: 12),
                      Text(
                        l.onboardingDailyBudgetLabel,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 10.5,
                          letterSpacing: 0.14 * 10.5,
                          color: muted,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      OnboardingCountUp(
                        value: calc.daily,
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 54,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: -0.04 * 54,
                          height: 0.95,
                        ),
                        format: formatRupiah,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '/hari · ${_pct == 0 ? l.onboardingDailySubNoEmergency : l.onboardingDailySubSaving(formatRupiah(calc.cicilan))}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'InterTight',
                          fontSize: 12.5,
                          color: textSoft,
                          height: 1.45,
                        ),
                      ),
                    ]),
                  ),
                  1, n,
                ),
                // 2: feedback + pct row
                _stagger(
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(fb.label,
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: fillColor,
                              height: 1,
                            )),
                        Text('$_pct%',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              height: 1,
                            )),
                      ],
                    ),
                  ),
                  2, n,
                ),
                // 3: slider
                _stagger(
                  _OSlider(
                    value: _pct,
                    fillColor: fillColor,
                    borderColor: border,
                    onChange: (v) => setState(() => _pct = v),
                  ),
                  3, n,
                ),
                // 4: note
                _stagger(
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 34),
                      child: Text(fb.note,
                          style: TextStyle(
                            fontFamily: 'InterTight',
                            fontSize: 12.5,
                            color: textSoft,
                            height: 1.45,
                          )),
                    ),
                  ),
                  4, n,
                ),
                // 5: pct chips
                _stagger(
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        ..._kPctPresets.map((p) {
                          final on = _pct == p;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 7),
                              child: _PctChipWidget(
                                label: p == 0 ? 'Lewati' : '$p%',
                                active: on,
                                isDark: isDark,
                                surfaceAlt: surfaceAlt,
                                onTap: () => setState(() => _pct = p),
                              ),
                            ),
                          );
                        }),
                        Expanded(
                          child: _ExtremChip(
                            active: _pct >= 20,
                            isDark: isDark,
                            surfaceAlt: surfaceAlt,
                            onTap: () => setState(() => _pct = 25),
                          ),
                        ),
                      ],
                    ),
                  ),
                  5, n,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        // CTA
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
          child: _CtaBtn(
            label: l.onboardingCtaStart,
            height: 58,
            onPressed: _next,
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  DONE screen
  // ════════════════════════════════════════════════════════════════
  Widget _buildDone(
    bool isDark,
    AppLocalizations l,
    _Calc calc,
    bool isSubmitting,
  ) {
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final textSoft = isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.cardLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // GrowShoot — delay 0
                _reveal(
                  Center(child: GrowShoot(grow: 1.0, size: 108, isDark: isDark)),
                  0,
                ),
                // eyebrow + title — delay 70
                _reveal(
                  Column(children: [
                    const SizedBox(height: 16),
                    Text(l.onboardingDoneEyebrow,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                          letterSpacing: 0.14 * 11,
                          color: AppColors.primary,
                          height: 1,
                        )),
                    const SizedBox(height: 6),
                    Text(l.onboardingDoneTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.025 * 24,
                          height: 1.12,
                        )),
                  ]),
                  70,
                ),
                // sub — delay 120
                _reveal(
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(l.onboardingDoneSub,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'InterTight',
                          fontSize: 13.5,
                          color: textSoft,
                          height: 1.5,
                        )),
                  ),
                  120,
                ),
                // stats card — delay 170
                _reveal(
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Row(children: [
                            Expanded(
                              child: _StatWidget(
                                label: l.onboardingStatDaily,
                                value: formatRupiah(calc.daily),
                                big: true,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _StatWidget(
                                label: l.onboardingStatEmergency,
                                value: '${formatRupiah(calc.cicilan)}/bln',
                                isDark: isDark,
                              ),
                            ),
                          ]),
                          const SizedBox(height: 14),
                          Row(children: [
                            Expanded(
                              child: _StatWidget(
                                label: l.onboardingStatIncome,
                                value: formatRupiah(_income),
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _StatWidget(
                                label: l.onboardingStatFixed,
                                value: formatRupiah(calc.fixed),
                                isDark: isDark,
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  170,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
          child: _CtaBtn(
            label: l.onboardingCtaEnter,
            height: 58,
            isLoading: isSubmitting,
            onPressed: isSubmitting ? null : _submitAll,
          ),
        ),
      ],
    );
  }

  // ── BLoC burst ─────────────────────────────────────────────────────
  void _submitAll() {
    final bloc = context.read<OnboardingBloc>();
    bloc.add(Step1Submitted(income: _income, paymentDate: _payday));
    bloc.add(Step2Submitted(
      rentExpense: _exp['kos'] ?? 0,
      utilitiesExpense: _exp['listrik'] ?? 0,
      internetExpense: _exp['internet'] ?? 0,
      phoneExpense: _exp['pulsa'] ?? 0,
      otherFixedExpense: _exp['lain'] ?? 0,
    ));
    bloc.add(Step3Submitted(emergencyFundPct: _pct / 100));
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ANIMATION HELPER
// ══════════════════════════════════════════════════════════════════════════════

class _FadeSlide extends StatelessWidget {
  const _FadeSlide({required this.anim, required this.child});

  final Animation<double> anim;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      child: child,
      builder: (_, child) => Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - anim.value)),
          child: child,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SUB-WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

// ── Docked bottom panel (step 0) ──────────────────────────────────────────
class _DockedPanel extends StatelessWidget {
  const _DockedPanel({
    required this.isDark,
    required this.surfaceAlt,
    required this.keypad,
    required this.cta,
  });

  final bool isDark;
  final Color surfaceAlt;
  final Widget keypad;
  final Widget cta;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: -0), // full bleed via padding below
      decoration: BoxDecoration(
        color: surfaceAlt,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1F14).withAlpha(71), // 28% opacity
            blurRadius: 28,
            spreadRadius: -16,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Column(
        children: [
          keypad,
          const SizedBox(height: 9),
          cta,
        ],
      ),
    );
  }
}

// ── CTA button ────────────────────────────────────────────────────────────
class _CtaBtn extends StatelessWidget {
  const _CtaBtn({
    required this.label,
    required this.height,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final double height;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primaryDeep,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          shadowColor: Colors.transparent,
        ).copyWith(
          overlayColor: WidgetStatePropertyAll(Colors.white.withAlpha(30)),
        ),
        child: isLoading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.01 * 16.5,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 18, color: Colors.white),
                ],
              ),
      ),
    );
  }
}

// ── Income preset chip ──────────────────────────────────────────────────────
class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final surfaceAlt = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : surfaceAlt,
          border: Border.all(
            color: active ? AppColors.primary : border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'InterTight',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : textColor,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ── Payday chip ─────────────────────────────────────────────────────────────
class _PaydayChipWidget extends StatelessWidget {
  const _PaydayChipWidget({
    required this.label,
    required this.active,
    required this.isDark,
    required this.onTap,
    this.wide = false,
  });

  final String label;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSoft = isDark ? AppColors.textSoftDark : AppColors.textSoftLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: wide ? null : 38,
        height: 38,
        padding: wide ? const EdgeInsets.symmetric(horizontal: 13) : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: active ? AppColors.primary : border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'InterTight',
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : textSoft,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ── Expense row (step 1) ────────────────────────────────────────────────────
class _ExpRowWidget extends StatelessWidget {
  const _ExpRowWidget({
    required this.row,
    required this.value,
    required this.active,
    required this.isDark,
    required this.isFirst,
    required this.l,
    required this.onTap,
  });

  final _ExpRow row;
  final int value;
  final bool active;
  final bool isDark;
  final bool isFirst;
  final AppLocalizations l;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.cardLight;
    final surfaceAlt = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        decoration: BoxDecoration(
          color: active ? surface : Colors.transparent,
          border: isFirst
              ? null
              : Border(top: BorderSide(color: border, width: 1)),
          borderRadius: active ? BorderRadius.circular(12) : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: active ? surfaceAlt : surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(row.icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                row.label(l),
                style: TextStyle(
                  fontFamily: 'InterTight',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  height: 1,
                ),
              ),
            ),
            Text(
              value > 0 ? formatRupiah(value) : 'Rp —',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: value > 0 ? textColor : muted,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Total card (step 1) ─────────────────────────────────────────────────────
class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.fixed,
    required this.fixedPct,
    required this.l,
  });

  final int fixed;
  final int fixedPct;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.onboardingTotalLabel,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 10.5,
                  letterSpacing: 0.12 * 10.5,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l.onboardingTotalPct(fixedPct),
                style: const TextStyle(
                  fontFamily: 'InterTight',
                  fontSize: 12,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),
          OnboardingCountUp(
            value: fixed,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.03 * 28,
              height: 1,
            ),
            format: formatRupiah,
          ),
        ],
      ),
    );
  }
}

// ── Keypad sheet (step 1 bottom sheet) ─────────────────────────────────────
class _SheetKeypad extends StatelessWidget {
  const _SheetKeypad({
    required this.activeRow,
    required this.value,
    required this.calc,
    required this.isDark,
    required this.surfaceAlt,
    required this.surface,
    required this.l,
    required this.onKey,
    required this.onDone,
  });

  final _ExpRow activeRow;
  final int value;
  final _Calc calc;
  final bool isDark;
  final Color surfaceAlt;
  final Color surface;
  final AppLocalizations l;
  final void Function(String) onKey;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceAlt,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1F14).withAlpha(64),
            blurRadius: 30,
            spreadRadius: -12,
            offset: const Offset(0, -12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // mini total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l.onboardingSheetTotalLabel(calc.fixedPct),
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 10,
                    letterSpacing: 0.12 * 10,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                OnboardingCountUp(
                  value: calc.fixed,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.02 * 20,
                    height: 1,
                  ),
                  format: formatRupiah,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // active row display + Selesai
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(activeRow.icon, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeRow.label(l),
                      style: TextStyle(
                        fontFamily: 'InterTight',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      formatRupiah(value),
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -0.02 * 21,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ]),
              FilledButton(
                onPressed: onDone,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: const StadiumBorder(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                ),
                child: Text(l.onboardingSheetDone,
                    style: const TextStyle(
                      fontFamily: 'InterTight',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // keypad
          OnboardingKeypad(isDark: isDark, onKey: onKey),
        ],
      ),
    );
  }
}

// ── Pct chip ─────────────────────────────────────────────────────────────────
class _PctChipWidget extends StatelessWidget {
  const _PctChipWidget({
    required this.label,
    required this.active,
    required this.isDark,
    required this.surfaceAlt,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool isDark;
  final Color surfaceAlt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : surfaceAlt,
          border: Border.all(
            color: active ? AppColors.primary : border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'InterTight',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : textColor,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Ekstrem chip ─────────────────────────────────────────────────────────────
class _ExtremChip extends StatelessWidget {
  const _ExtremChip({
    required this.active,
    required this.isDark,
    required this.surfaceAlt,
    required this.onTap,
  });

  final bool active;
  final bool isDark;
  final Color surfaceAlt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryBright : surfaceAlt,
          border: Border.all(
            color: active ? AppColors.primaryBright : border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bolt_rounded,
              size: 13,
              color: active ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'Ekstrem',
              style: TextStyle(
                fontFamily: 'InterTight',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.primary,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom slider (step 2) ────────────────────────────────────────────────
class _OSlider extends StatefulWidget {
  const _OSlider({
    required this.value,
    required this.fillColor,
    required this.borderColor,
    required this.onChange,
  });

  final int value;
  final Color fillColor;
  final Color borderColor;
  final void Function(int) onChange;

  @override
  State<_OSlider> createState() => _OSliderState();
}

class _OSliderState extends State<_OSlider> {
  static const _min = 0, _max = 25;
  static const _marks = [0, 5, 10, 15, 20, 25];
  static const _knobSize = 26.0;
  static const _trackH = 8.0;

  double _pct(int v) => (v - _min) / (_max - _min);

  void _fromDx(double dx, double width) {
    final p = (dx / width).clamp(0.0, 1.0);
    final raw = _min + p * (_max - _min);
    final snapped = (raw.round()).clamp(_min, _max);
    if (snapped != widget.value) widget.onChange(snapped);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      return GestureDetector(
        onHorizontalDragUpdate: (d) => _fromDx(d.localPosition.dx, w),
        onTapDown: (d) => _fromDx(d.localPosition.dx, w),
        child: SizedBox(
          height: _knobSize + 12,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // track
              Container(
                height: _trackH,
                decoration: BoxDecoration(
                  color: widget.borderColor,
                  borderRadius: BorderRadius.circular(_trackH),
                ),
              ),
              // fill
              Positioned(
                left: 0,
                child: Container(
                  width: w * _pct(widget.value),
                  height: _trackH,
                  decoration: BoxDecoration(
                    color: widget.fillColor,
                    borderRadius: BorderRadius.circular(_trackH),
                  ),
                ),
              ),
              // marks
              ..._marks.map((m) {
                return Positioned(
                  left: w * _pct(m) - 1.5,
                  child: Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(46),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
              // knob
              Positioned(
                left: (w * _pct(widget.value) - _knobSize / 2)
                    .clamp(0, w - _knobSize),
                child: Container(
                  width: _knobSize,
                  height: _knobSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B1F14).withAlpha(71),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ── Stat widget (done screen) ─────────────────────────────────────────────
class _StatWidget extends StatelessWidget {
  const _StatWidget({
    required this.label,
    required this.value,
    required this.isDark,
    this.big = false,
  });

  final String label;
  final String value;
  final bool isDark;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 9.5,
            letterSpacing: 0.1 * 9.5,
            color: muted,
            height: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: big ? 22 : 16,
            fontWeight: FontWeight.w800,
            color: big ? AppColors.primary : textColor,
            letterSpacing: -0.02 * (big ? 22 : 16),
            height: 1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  DATE PICKER SHEET (for payday "Lain" chip)
// ══════════════════════════════════════════════════════════════════════════════

class _DatePickerSheet extends StatefulWidget {
  const _DatePickerSheet({required this.onConfirm, this.initialDate});

  final int? initialDate;
  final ValueChanged<int> onConfirm;

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  late int? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final textSoftColor = isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 3,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pilih tanggal masuk',
                        style: AppTextStyles.h3.copyWith(color: textColor)),
                    const SizedBox(height: 2),
                    Text('Tanggal kiriman atau gaji tiba.',
                        style: AppTextStyles.bodySmall.copyWith(color: textSoftColor)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration:
                      BoxDecoration(color: surfaceColor, shape: BoxShape.circle),
                  child: Icon(Icons.close, size: 16, color: mutedColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: 31,
            itemBuilder: (_, i) {
              final date = i + 1;
              final isSelected = _selected == date;
              final isClamped = date >= 29;
              final fg = isSelected ? Colors.white : (isClamped ? mutedColor : textColor);
              return GestureDetector(
                onTap: () => setState(() => _selected = date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$date',
                          style: AppTextStyles.label.copyWith(color: fg)),
                      if (isClamped && !isSelected)
                        Text('*',
                            style: AppTextStyles.caption.copyWith(
                                fontSize: 8, color: mutedColor, height: 0.8)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '* Bulan tertentu (Feb, Apr, Jun, Sep, Nov) otomatis disesuaikan.',
            style: AppTextStyles.caption.copyWith(color: mutedColor, fontSize: 10),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Batal',
                    style: AppTextStyles.label.copyWith(color: textSoftColor)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _selected != null
                    ? () {
                        widget.onConfirm(_selected!);
                        Navigator.pop(context, _selected);
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: borderColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _selected != null
                      ? (_selected! >= 29
                          ? 'Gunakan ~tanggal $_selected*'
                          : 'Gunakan tanggal $_selected')
                      : 'Pilih tanggal dulu',
                  style: AppTextStyles.label.copyWith(
                    color: _selected != null ? Colors.white : mutedColor,
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
