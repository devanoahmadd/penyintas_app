import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/routing/app_router.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/core/utils/date_helper.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_event.dart';
import 'package:penyintas_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:penyintas_app/features/onboarding/presentation/widgets/onboarding_progress_dots.dart' show OnboardingProgressBar;
import 'package:penyintas_app/widgets/common/app_text_field.dart';
import 'package:penyintas_app/widgets/common/primary_button.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final PageController _pageController;

  // Cached data for rendering during state transitions
  int _cachedIncome = 0;
  int _cachedFixedExpenses = 0;
  int _cachedRemainingDays = 30;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    context.read<OnboardingBloc>().add(const OnboardingStarted());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _stateToPage(OnboardingState state) {
    if (state is OnboardingStep2) return 1;
    if (state is OnboardingStep3) return 2;
    if (state is OnboardingCalculating) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.read<OnboardingBloc>().add(const OnboardingBackPressed());
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: BlocConsumer<OnboardingBloc, OnboardingState>(
            listenWhen: (prev, curr) {
              return _stateToPage(prev) != _stateToPage(curr) ||
                  curr is OnboardingSuccess ||
                  curr is OnboardingError ||
                  prev is OnboardingError;
            },
            listener: (context, state) {
              if (state is OnboardingStep2) {
                _cachedIncome = state.income;
              } else if (state is OnboardingStep3) {
                _cachedIncome = state.income;
                _cachedFixedExpenses = state.fixedExpenses;
                _cachedRemainingDays = state.remainingDays;
              }

              // Jangan animate page untuk terminal states — OnboardingError
              // mengembalikan 0 dari _stateToPage (default), yang menyebabkan
              // PageController kembali ke Step 1 saat submit gagal.
              if (state is! OnboardingError && state is! OnboardingSuccess) {
                final page = _stateToPage(state);
                if (_pageController.hasClients) {
                  _pageController.animateToPage(
                    page,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              }

              if (state is OnboardingSuccess) {
                // Minta izin notifikasi setelah onboarding selesai
                context
                    .read<NotificationBloc>()
                    .add(const RequestPermission());
                // Invalidasi cache agar router baca ulang DB (onboardingCompleted=true)
                resetOnboardingCache();
                context.go('/dashboard');
              } else if (state is OnboardingError) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    content: Text(
                      state.message,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.white),
                    ),
                    backgroundColor: AppColors.warn,
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'Coba lagi',
                      textColor: Colors.white,
                      onPressed: () => context
                          .read<OnboardingBloc>()
                          .add(const OnboardingRetryRequested()),
                    ),
                  ));
              }
            },
            builder: (context, state) {
              final currentPage = _stateToPage(state);
              final isLoading = state is OnboardingCalculating;

              return Column(
                children: [
                  _OnboardingHeader(
                    currentStep: currentPage,
                    canGoBack: currentPage > 0 && !isLoading,
                    isDark: isDark,
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _Step1Widget(isDark: isDark),
                        _Step2Widget(
                          isDark: isDark,
                          income: _cachedIncome,
                        ),
                        _Step3Widget(
                          isDark: isDark,
                          income: _cachedIncome,
                          remainingDays: _cachedRemainingDays,
                          fixedExpenses: _cachedFixedExpenses,
                          isLoading: isLoading,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Header dengan step counter + segmented progress bar ───────────────────

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.currentStep,
    required this.canGoBack,
    required this.isDark,
  });

  final int currentStep;
  final bool canGoBack;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textSoftColor =
        isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
    final iconColor = isDark ? AppColors.textDark : AppColors.textLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${currentStep + 1} dari 3',
                style: AppTextStyles.caption.copyWith(color: textSoftColor),
              ),
              const Spacer(),
              if (canGoBack)
                GestureDetector(
                  onTap: () => context
                      .read<OnboardingBloc>()
                      .add(const OnboardingBackPressed()),
                  child: SizedBox(
                    width: 44,
                    height: 32,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.arrow_back, color: iconColor, size: 20),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          OnboardingProgressBar(
            currentStep: currentStep,
            totalSteps: 3,
          ),
        ],
      ),
    );
  }
}

// ── Step 1 — Pemasukan & Tanggal ─────────────────────────────────────────

const _kIncomePresets = <int>[1000000, 2000000, 3000000, 5000000];
const _kDatePresets = <int>[1, 5, 15, 25];

String _chipLabel(int amount) =>
    amount >= 1000000 ? 'Rp ${amount ~/ 1000000}jt' : 'Rp ${amount ~/ 1000}rb';

class _Step1Widget extends StatefulWidget {
  const _Step1Widget({required this.isDark});
  final bool isDark;

  @override
  State<_Step1Widget> createState() => _Step1WidgetState();
}

class _Step1WidgetState extends State<_Step1Widget> {
  final _incomeController = TextEditingController();
  String? _incomeError;
  String? _dateError;
  int? _selectedDatePreset;

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  int get _incomeAmount {
    final raw = _incomeController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(raw) ?? 0;
  }

  int get _dailyIncome => _incomeAmount > 0
      ? (_incomeAmount /
              (_selectedDatePreset != null
                  ? daysInCycle(_selectedDatePreset!)
                  : 30))
          .floor()
      : 0;

  String _contextMsg() {
    final d = _dailyIncome;
    if (d <= 0) return '';
    if (d < 30000) return 'Ketat, tapi bisa diatur dengan disiplin.';
    if (d < 80000) return 'Pas untuk anggaran mahasiswa kos.';
    if (d < 150000) return 'Cukup nyaman untuk hidup mandiri.';
    return 'Ruang gerak anggaran yang luas.';
  }

  void _selectPreset(int amount) {
    _incomeController.text = formatRupiah(amount);
    setState(() => _incomeError = null);
  }

  void _selectDate(int? date) {
    if (date == null) {
      _openDatePicker();
      return;
    }
    setState(() {
      _selectedDatePreset = date;
      _dateError = null;
    });
  }

  void _openDatePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: const Color(0x72000000),
      builder: (_) => _DatePickerSheet(
        initialDate: _selectedDatePreset,
        onConfirm: (date) {
          setState(() {
            _selectedDatePreset = date;
            _dateError = null;
          });
        },
      ),
    );
  }

  bool _validate() {
    final l10n = AppLocalizations.of(context);
    bool valid = true;
    setState(() {
      _incomeError = null;
      _dateError = null;

      final income = _incomeAmount;
      if (income <= 0) {
        _incomeError = l10n.onboardingErrorInvalidAmount;
        valid = false;
      } else if (income > 100000000) {
        _incomeError = l10n.onboardingErrorAmountTooLarge;
        valid = false;
      }

      final date = _selectedDatePreset;
      if (date == null || date < 1 || date > 31) {
        _dateError = l10n.onboardingErrorSelectDate;
        valid = false;
      }
    });
    return valid;
  }

  void _submit() {
    if (!_validate()) return;
    context.read<OnboardingBloc>().add(
          Step1Submitted(income: _incomeAmount, paymentDate: _selectedDatePreset!),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textColor =
        widget.isDark ? AppColors.textDark : AppColors.textLight;
    final textSoftColor =
        widget.isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
    final surfaceColor =
        widget.isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor =
        widget.isDark ? AppColors.borderDark : AppColors.borderLight;

    final income = _incomeAmount;
    final daily = _dailyIncome;
    final ctxMsg = _contextMsg();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.sm),
                // Eyebrow
                Row(
                  children: [
                    const Icon(Icons.attach_money,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      l10n.onboardingEyebrowIncome,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.onboardingIncomeTitle,
                  style: AppTextStyles.h1.copyWith(
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Kiriman orang tua, gaji, atau pemasukan rutin lain. '
                  'Ini jadi dasar kami menghitung anggaran harianmu.',
                  style: AppTextStyles.bodySmall.copyWith(color: textSoftColor),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Income field dengan Rupiah formatter
                AppTextField(
                  controller: _incomeController,
                  label: l10n.onboardingIncomeLabel,
                  hintText: l10n.onboardingIncomeHint,
                  errorText: _incomeError,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_RupiahInputFormatter()],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() { _incomeError = null; }),
                  onClear: _incomeController.text.isNotEmpty
                      ? () {
                          _incomeController.clear();
                          setState(() { _incomeError = null; });
                        }
                      : null,
                ),

                // Quick chips — preset nominal
                const SizedBox(height: AppSpacing.xs),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _kIncomePresets
                        .map((amt) => _QuickChip(
                              label: _chipLabel(amt),
                              selected: income == amt,
                              isDark: widget.isDark,
                              onTap: () => _selectPreset(amt),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Date segmented picker
                Text(
                  l10n.onboardingDateTitle,
                  style: AppTextStyles.label.copyWith(color: textColor),
                ),
                const SizedBox(height: AppSpacing.sm),
                _DateSegmentPicker(
                  presets: _kDatePresets,
                  selected: _selectedDatePreset,
                  isDark: widget.isDark,
                  onSelect: _selectDate,
                ),
                if (_dateError != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _dateError!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.warn, height: 1.3),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Pakai untuk hitung mundur Days-to-Live tiap siklus.',
                  style: AppTextStyles.caption.copyWith(color: textSoftColor),
                ),

                // Preview card — muncul setelah income diisi
                if (income > 0 && daily > 0) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.timer_outlined,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              text: 'Pemasukan harian rata-rata ',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: textSoftColor),
                              children: [
                                TextSpan(
                                  text: formatRupiah(daily),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                    fontFeatures: [
                                      const FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                if (ctxMsg.isNotEmpty)
                                  TextSpan(
                                    text: '. $ctxMsg',
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: textSoftColor),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),

        // CTA pinned ke bawah
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl,
          ),
          child: PrimaryButton(
            label: 'Lanjut →',
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}

// ── Step 2 — Pengeluaran Tetap ────────────────────────────────────────────

class _Step2Widget extends StatefulWidget {
  const _Step2Widget({required this.isDark, required this.income});
  final bool isDark;
  final int income;

  @override
  State<_Step2Widget> createState() => _Step2WidgetState();
}

class _Step2WidgetState extends State<_Step2Widget>
    with AutomaticKeepAliveClientMixin {
  final _rentCtrl = TextEditingController();
  final _utilitiesCtrl = TextEditingController();
  final _internetCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otherCtrl = TextEditingController();
  String? _submitError;

  @override
  bool get wantKeepAlive => true;

  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _rentCtrl.dispose();
    _utilitiesCtrl.dispose();
    _internetCtrl.dispose();
    _phoneCtrl.dispose();
    _otherCtrl.dispose();
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  int _parseCtrl(TextEditingController c) =>
      int.tryParse(c.text.replaceAll('.', '')) ?? 0;

  int get _totalExpenses =>
      _parseCtrl(_rentCtrl) +
      _parseCtrl(_utilitiesCtrl) +
      _parseCtrl(_internetCtrl) +
      _parseCtrl(_phoneCtrl) +
      _parseCtrl(_otherCtrl);

  double get _percentageOfIncome =>
      widget.income > 0 ? (_totalExpenses / widget.income) * 100 : 0;

  Color get _valueColor {
    final pct = _percentageOfIncome;
    if (pct > 90) return AppColors.warn;
    if (pct > 70) return AppColors.caution;
    return AppColors.shoot;
  }

  bool _validate() {
    final l10n = AppLocalizations.of(context);
    String? error;
    if (_totalExpenses == 0) {
      error = l10n.onboardingErrorEmptyExpenses;
    } else if (widget.income > 0 && _totalExpenses > widget.income) {
      error = l10n.onboardingErrorExpensesExceedIncome;
    }
    setState(() => _submitError = error);
    return error == null;
  }

  void _submit() {
    if (!_validate()) return;
    context.read<OnboardingBloc>().add(Step2Submitted(
          rentExpense: _parseCtrl(_rentCtrl),
          utilitiesExpense: _parseCtrl(_utilitiesCtrl),
          internetExpense: _parseCtrl(_internetCtrl),
          phoneExpense: _parseCtrl(_phoneCtrl),
          otherFixedExpense: _parseCtrl(_otherCtrl),
        ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final textColor =
        widget.isDark ? AppColors.textDark : AppColors.textLight;
    final textSoftColor =
        widget.isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
    final borderColor =
        widget.isDark ? AppColors.borderDark : AppColors.borderLight;
    final cardBg = widget.isDark ? AppColors.surfaceDark : AppColors.cardLight;

    final total = _totalExpenses;
    final pct = _percentageOfIncome;
    final isOverBudget = widget.income > 0 && total > widget.income;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.sm),
                // Eyebrow
                Row(
                  children: [
                    const Icon(Icons.home_outlined,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      l10n.onboardingEyebrowFixed,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.onboardingFixedTitle,
                  style: AppTextStyles.h1.copyWith(
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.onboardingFixedHint,
                  style:
                      AppTextStyles.bodySmall.copyWith(color: textSoftColor),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Expense list card
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _ExpenseInputRow(
                          icon: Icons.home_outlined,
                          name: l10n.onboardingExpenseRent,
                          hint: l10n.onboardingExpenseRentHint,
                          controller: _rentCtrl,
                          focusNode: _focusNodes[0],
                          nextFocusNode: _focusNodes[1],
                          isDark: widget.isDark,
                          onChanged: (_) => setState(() { _submitError = null; }),
                        ),
                        Divider(height: 1, color: borderColor),
                        _ExpenseInputRow(
                          icon: Icons.bolt_outlined,
                          name: l10n.onboardingExpenseUtilities,
                          hint: l10n.onboardingExpenseUtilitiesHint,
                          controller: _utilitiesCtrl,
                          focusNode: _focusNodes[1],
                          nextFocusNode: _focusNodes[2],
                          isDark: widget.isDark,
                          onChanged: (_) => setState(() { _submitError = null; }),
                        ),
                        Divider(height: 1, color: borderColor),
                        _ExpenseInputRow(
                          icon: Icons.wifi,
                          name: l10n.onboardingExpenseInternet,
                          hint: l10n.onboardingExpenseInternetHint,
                          controller: _internetCtrl,
                          focusNode: _focusNodes[2],
                          nextFocusNode: _focusNodes[3],
                          isDark: widget.isDark,
                          onChanged: (_) => setState(() { _submitError = null; }),
                        ),
                        Divider(height: 1, color: borderColor),
                        _ExpenseInputRow(
                          icon: Icons.smartphone_outlined,
                          name: l10n.onboardingExpensePhone,
                          hint: l10n.onboardingExpensePhoneHint,
                          controller: _phoneCtrl,
                          focusNode: _focusNodes[3],
                          nextFocusNode: _focusNodes[4],
                          isDark: widget.isDark,
                          onChanged: (_) => setState(() { _submitError = null; }),
                        ),
                        Divider(height: 1, color: borderColor),
                        _ExpenseInputRow(
                          icon: Icons.work_outline,
                          name: l10n.categoryOther,
                          hint: l10n.onboardingExpenseOtherHint,
                          controller: _otherCtrl,
                          focusNode: _focusNodes[4],
                          isDark: widget.isDark,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() { _submitError = null; }),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Summary card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.isDark
                          ? [AppColors.surfaceDark, AppColors.borderDark]
                          : [AppColors.textLight, AppColors.textSoftLight],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: widget.isDark
                        ? Border.all(
                            color: AppColors.shoot.withValues(alpha: 0.4),
                          )
                        : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL TETAP',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.income > 0
                                ? '≈ ${pct.toStringAsFixed(1)}% dari pemasukan'
                                : 'Isi pemasukan di langkah 1',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        formatRupiah(total),
                        style: AppTextStyles.h2.copyWith(
                          color: isOverBudget ? AppColors.warn : _valueColor,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),

                // Warnings
                if (_percentageOfIncome > 90 && total > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Pengeluaran tetap cukup tinggi — pertimbangkan mana yang bisa dikurangi.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.warn),
                  ),
                ],
                if (_submitError != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _submitError!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.warn),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),

        // CTA pinned ke bawah
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl,
          ),
          child: PrimaryButton(
            label: 'Lanjut →',
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}

// ── Step 3 — Dana Darurat & Cicilan ───────────────────────────────────────

class _Step3Widget extends StatefulWidget {
  const _Step3Widget({
    required this.isDark,
    required this.income,
    required this.remainingDays,
    required this.fixedExpenses,
    required this.isLoading,
  });

  final bool isDark;
  final int income;
  final int remainingDays;
  final int fixedExpenses;
  final bool isLoading;

  @override
  State<_Step3Widget> createState() => _Step3WidgetState();
}

class _Step3WidgetState extends State<_Step3Widget> {
  double _emergencyPct = 0.10;
  final _targetController = TextEditingController();

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  int get _available {
    final a = widget.income - widget.fixedExpenses;
    return a < 0 ? 0 : a;
  }

  int get _monthlyInstallment => (_available * _emergencyPct).round();
  int get _monthlyRemaining => _available - _monthlyInstallment;
  int get _dailyBudget => widget.remainingDays > 0
      ? (_monthlyRemaining / widget.remainingDays).floor()
      : 0;
  int get _targetAmount =>
      int.tryParse(_targetController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
      0;
  int get _monthsToTarget =>
      _monthlyInstallment > 0 && _targetAmount > 0
          ? (_targetAmount / _monthlyInstallment).ceil()
          : 0;

  String _buildSubtext() {
    final parts = <String>[];
    if (widget.remainingDays == 0) {
      parts.add('Siklus baru dimulai hari ini');
    } else if (_dailyBudget > 0) {
      parts.add('≈ ${formatRupiah(_dailyBudget)} / hari');
    }
    if (_monthsToTarget > 0) {
      parts.add('target tercapai dalam $_monthsToTarget bulan');
    }
    return parts.join(' · ');
  }

  void _submit() {
    context.read<OnboardingBloc>().add(
          Step3Submitted(emergencyFundPct: _emergencyPct),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textColor =
        widget.isDark ? AppColors.textDark : AppColors.textLight;
    final textSoftColor =
        widget.isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
    final surfaceColor =
        widget.isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor =
        widget.isDark ? AppColors.borderDark : AppColors.borderLight;

    final pctInt = (_emergencyPct * 100).round();
    final targetAmount = _targetAmount;
    final subtext = _buildSubtext();

    final isOverBudget =
        widget.income > 0 && widget.fixedExpenses >= widget.income;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Dana darurat & cicilan',
                  style: AppTextStyles.h1.copyWith(
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Sisihkan untuk hari tak terduga. Lentur, tak patah.',
                  style: AppTextStyles.bodySmall.copyWith(color: textSoftColor),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Over-budget warning (#49)
                if (isOverBudget) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warn.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warn.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warn,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            l10n.onboardingErrorFixedExceedsIncome,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.warn),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Target dana darurat
                AppTextField(
                  controller: _targetController,
                  label: l10n.onboardingEmergencyTargetLabel,
                  hintText: 'Contoh: 5.000.000',
                  keyboardType: TextInputType.number,
                  inputFormatters: [_DotFormatter()],
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                ),
                if (targetAmount > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    formatRupiah(targetAmount),
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.primary,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.sm),

                // Alokasi label (dinamis, berubah dengan slider)
                Text(
                  l10n.onboardingEmergencyPerMonth(pctInt),
                  style: AppTextStyles.label.copyWith(color: textColor),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    formatRupiah(_monthlyInstallment),
                    style: AppTextStyles.body.copyWith(color: textColor),
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: borderColor,
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withAlpha(30),
                    trackHeight: 4,
                  ),
                  child: Semantics(
                    label: l10n.onboardingEmergencyTargetLabel,
                    value: '$pctInt%',
                    child: Slider(
                      value: _emergencyPct,
                      min: 0.05,
                      max: 0.25,
                      divisions: 20,
                      onChanged: widget.isLoading
                          ? null
                          : (val) => setState(() => _emergencyPct = val),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.onboardingSliderMin,
                      style: AppTextStyles.caption
                          .copyWith(color: textSoftColor),
                    ),
                    Text(
                      l10n.onboardingSliderMax,
                      style: AppTextStyles.caption
                          .copyWith(color: textSoftColor),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Kalkulasi bulanan card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KALKULASI BULANAN',
                        style: AppTextStyles.caption
                            .copyWith(color: textSoftColor),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _CalcRow(
                        label: 'Kiriman / gaji',
                        value: '+ ${formatRupiah(widget.income)}',
                        textColor: textColor,
                        valueColor: textColor,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _CalcRow(
                        label: 'Pengeluaran tetap',
                        value: '− ${formatRupiah(widget.fixedExpenses)}',
                        textColor: textSoftColor,
                        valueColor: AppColors.warn,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _CalcRow(
                        label: 'Alokasi dana darurat',
                        value: '− ${formatRupiah(_monthlyInstallment)}',
                        textColor: textSoftColor,
                        valueColor: AppColors.caution,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Divider(color: borderColor, height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Sisa harian',
                            style:
                                AppTextStyles.label.copyWith(color: textColor),
                          ),
                          Text(
                            formatRupiah(_monthlyRemaining),
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.primary,
                              fontFeatures: [
                                const FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (subtext.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtext,
                          style: AppTextStyles.caption
                              .copyWith(color: textSoftColor),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // DTL preview card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? AppColors.primaryDeep
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SISA HARI SIKLUS INI',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '≈ ${widget.remainingDays} hari',
                              style: AppTextStyles.h2.copyWith(
                                color: Colors.white,
                                fontFeatures: [
                                  const FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Prediksi DTL tersedia setelah riwayat belanja terbentuk',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.6),
                                letterSpacing: 0,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),

        // CTA pinned ke bawah (#48)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          child: PrimaryButton(
            label: 'Mulai Bertahan',
            onPressed: _submit,
            isLoading: widget.isLoading,
          ),
        ),
      ],
    );
  }
}

class _CalcRow extends StatelessWidget {
  const _CalcRow({
    required this.label,
    required this.value,
    required this.textColor,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color textColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodySmall.copyWith(color: textColor)),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: valueColor,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ── Quick chip ────────────────────────────────────────────────────────────

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 44,
          margin: const EdgeInsets.only(right: AppSpacing.sm),
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color: selected ? AppColors.primary : borderColor,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: selected ? Colors.white : textColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Date segmented picker ─────────────────────────────────────────────────

class _DateSegmentPicker extends StatelessWidget {
  const _DateSegmentPicker({
    required this.presets,
    required this.selected,
    required this.isDark,
    required this.onSelect,
  });

  final List<int> presets;
  final int? selected;
  final bool isDark;
  final void Function(int?) onSelect; // null = buka bottom sheet

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final selectedBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    final isCustomSelected =
        selected != null && !presets.contains(selected);
    final options = [...presets, null]; // [1, 5, 15, 25, null=Lain]

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: options.map((date) {
          final isLain = date == null;
          final isSelected =
              isLain ? isCustomSelected : date == selected;

          final label = isLain
              ? (isCustomSelected ? 'Tgl $selected ✓' : 'Lain')
              : date.toString();

          final bgSegment = isSelected
              ? (isLain && isCustomSelected ? AppColors.primary : selectedBg)
              : Colors.transparent;

          final fgSegment = isSelected
              ? (isLain && isCustomSelected ? Colors.white : textColor)
              : mutedColor;

          final semanticLabel = isLain
              ? (isCustomSelected ? 'Tanggal $selected' : 'Lain')
              : 'Tanggal $date';

          return Expanded(
            child: Semantics(
              button: true,
              selected: isSelected,
              label: isSelected ? '$semanticLabel, dipilih' : semanticLabel,
              child: GestureDetector(
                onTap: () => onSelect(date),
                child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 44,
                decoration: BoxDecoration(
                  color: bgSegment,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected && !(isLain && isCustomSelected)
                      ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(18),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    label,
                    style: AppTextStyles.label.copyWith(
                      color: fgSegment,
                      fontFeatures: !isLain
                          ? [const FontFeature.tabularFigures()]
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Date picker bottom sheet ──────────────────────────────────────────────

class _DatePickerSheet extends StatefulWidget {
  const _DatePickerSheet({
    required this.onConfirm,
    this.initialDate,
  });

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
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final textSoftColor =
        isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
    final mutedColor =
        isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 28,
            height: 3,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih tanggal masuk',
                      style: AppTextStyles.h3.copyWith(color: textColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tanggal kiriman atau gaji tiba.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: textSoftColor),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 16, color: mutedColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Grid 1–31
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
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
              final fgColor = isSelected
                  ? Colors.white
                  : isClamped
                      ? mutedColor
                      : textColor;
              return GestureDetector(
                onTap: () => setState(() => _selected = date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          date.toString(),
                          style: AppTextStyles.label.copyWith(
                            color: fgColor,
                            fontFeatures: [
                              const FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                        if (isClamped && !isSelected)
                          Text(
                            '*',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 8,
                              color: mutedColor,
                              height: 0.8,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '* Bulan tertentu (Feb, Apr, Jun, Sep, Nov) otomatis disesuaikan.',
            style: AppTextStyles.caption.copyWith(
              color: mutedColor,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Batal',
                    style: AppTextStyles.label
                        .copyWith(color: textSoftColor),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _selected != null
                      ? () {
                          widget.onConfirm(_selected!);
                          Navigator.pop(context);
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: borderColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    _selected != null
                        ? (_selected! >= 29
                            ? 'Gunakan ~tanggal $_selected*'
                            : 'Gunakan tanggal $_selected')
                        : 'Pilih tanggal dulu',
                    style: AppTextStyles.label.copyWith(
                      color: _selected != null
                          ? Colors.white
                          : mutedColor,
                    ),
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

// ── Expense input row ─────────────────────────────────────────────────────

class _ExpenseInputRow extends StatelessWidget {
  const _ExpenseInputRow({
    required this.icon,
    required this.name,
    required this.hint,
    required this.controller,
    required this.isDark,
    required this.onChanged,
    this.focusNode,
    this.nextFocusNode,
    this.textInputAction = TextInputAction.next,
  });

  final IconData icon;
  final String name;
  final String hint;
  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          // Meta column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.label.copyWith(color: textColor),
                ),
                Text(
                  hint,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Input column (right-aligned)
          Semantics(
            label: name,
            child: SizedBox(
              width: 130,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_DotFormatter()],
                  textInputAction: textInputAction,
                  onChanged: onChanged,
                  onSubmitted: (_) {
                    if (nextFocusNode != null) {
                      nextFocusNode!.requestFocus();
                    }
                  },
                  style: AppTextStyles.label.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                  decoration: InputDecoration(
                    hintText: '—',
                    hintStyle: AppTextStyles.label.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: mutedColor.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Text(
                  'Rp / bulan',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }
}

// ── Dot number formatter (separates thousands with dots, no Rp prefix) ────

class _DotFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) return const TextEditingValue();
    final amount = int.tryParse(raw);
    if (amount == null) return const TextEditingValue();
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ── Rupiah input formatter ────────────────────────────────────────────────

class _RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) return const TextEditingValue();
    final amount = int.tryParse(raw);
    if (amount == null) return const TextEditingValue();
    final formatted = formatRupiah(amount);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
