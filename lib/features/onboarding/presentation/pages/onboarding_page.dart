import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/onboarding/domain/entities/daily_budget_result.dart';
import 'package:penyintas_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:penyintas_app/features/onboarding/presentation/widgets/onboarding_progress_dots.dart';
import 'package:penyintas_app/widgets/common/app_text_field.dart';
import 'package:penyintas_app/widgets/common/penyintas_logo.dart';
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
                  curr is OnboardingError;
            },
            listener: (context, state) {
              if (state is OnboardingStep2) {
                _cachedIncome = state.income;
              } else if (state is OnboardingStep3) {
                _cachedIncome = state.income;
                _cachedFixedExpenses = state.fixedExpenses;
                _cachedRemainingDays = state.remainingDays;
              }

              final page = _stateToPage(state);
              if (_pageController.hasClients) {
                _pageController.animateToPage(
                  page,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }

              if (state is OnboardingSuccess) {
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

// ── Header dengan back button + progress dots ──────────────────────────────

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
    final iconColor = isDark ? AppColors.textDark : AppColors.textLight;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          if (canGoBack)
            GestureDetector(
              onTap: () =>
                  context.read<OnboardingBloc>().add(const OnboardingBackPressed()),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.arrow_back, color: iconColor, size: 22),
              ),
            )
          else
            const SizedBox(width: 44),
          Expanded(
            child: Center(
              child: OnboardingProgressDots(
                currentStep: currentStep,
                totalSteps: 3,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

// ── Step 1 — Income + Payment Date ────────────────────────────────────────

class _Step1Widget extends StatefulWidget {
  const _Step1Widget({required this.isDark});
  final bool isDark;

  @override
  State<_Step1Widget> createState() => _Step1WidgetState();
}

class _Step1WidgetState extends State<_Step1Widget> {
  final _incomeController = TextEditingController();
  final _dateController = TextEditingController();
  String? _incomeError;
  String? _dateError;

  @override
  void dispose() {
    _incomeController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String get _previewIncome {
    final raw = _incomeController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) return '';
    final amount = int.tryParse(raw) ?? 0;
    return amount > 0 ? formatRupiah(amount) : '';
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _incomeError = null;
      _dateError = null;

      final raw = _incomeController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final income = int.tryParse(raw) ?? 0;
      if (income <= 0) {
        _incomeError = 'Masukkan jumlah kiriman yang valid.';
        valid = false;
      } else if (income > 100000000) {
        _incomeError = 'Jumlah terlalu besar.';
        valid = false;
      }

      final date = int.tryParse(_dateController.text);
      if (date == null || date < 1 || date > 31) {
        _dateError = 'Tanggal harus antara 1 dan 31.';
        valid = false;
      }
    });
    return valid;
  }

  void _submit() {
    if (!_validate()) return;
    final income = int.parse(
      _incomeController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    final paymentDate = int.parse(_dateController.text);
    context.read<OnboardingBloc>().add(
          Step1Submitted(income: income, paymentDate: paymentDate),
        );
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.isDark ? AppColors.textDark : AppColors.textLight;
    final textSoftColor =
        widget.isDark ? AppColors.textSoftDark : AppColors.textSoftLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PenyintasLogo(size: 32),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Berapa kiriman\nbulananmu?',
            style: AppTextStyles.h1.copyWith(color: textColor),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Ini dasar hitung anggaran harian kamu.',
            style: AppTextStyles.bodySmall.copyWith(color: textSoftColor),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppTextField(
            controller: _incomeController,
            label: 'Kiriman bulanan',
            hintText: 'Contoh: 1500000',
            errorText: _incomeError,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          if (_previewIncome.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _previewIncome,
              style: AppTextStyles.h3.copyWith(
                color: AppColors.primary,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          AppTextField(
            controller: _dateController,
            label: 'Tanggal kiriman masuk',
            hintText: 'Contoh: 25',
            errorText: _dateError,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          PrimaryButton(
            label: 'Lanjut',
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ── Step 2 — Fixed Expenses ────────────────────────────────────────────────

class _Step2Widget extends StatefulWidget {
  const _Step2Widget({required this.isDark, required this.income});
  final bool isDark;
  final int income;

  @override
  State<_Step2Widget> createState() => _Step2WidgetState();
}

class _Step2WidgetState extends State<_Step2Widget> {
  final _fixedController = TextEditingController();
  String? _fixedError;

  @override
  void dispose() {
    _fixedController.dispose();
    super.dispose();
  }

  String get _previewFixed {
    final raw = _fixedController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) return '';
    final amount = int.tryParse(raw) ?? 0;
    return amount > 0 ? formatRupiah(amount) : '';
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _fixedError = null;

      final raw = _fixedController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final fixed = int.tryParse(raw) ?? 0;
      if (fixed < 0) {
        _fixedError = 'Pengeluaran tidak boleh negatif.';
        valid = false;
      } else if (widget.income > 0 && fixed >= widget.income) {
        _fixedError = 'Pengeluaran tetap tidak boleh melebihi kiriman.';
        valid = false;
      }
    });
    return valid;
  }

  void _submit() {
    if (!_validate()) return;
    final raw = _fixedController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final fixed = int.tryParse(raw) ?? 0;
    context.read<OnboardingBloc>().add(Step2Submitted(fixedExpenses: fixed));
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.isDark ? AppColors.textDark : AppColors.textLight;
    final textSoftColor =
        widget.isDark ? AppColors.textSoftDark : AppColors.textSoftLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PenyintasLogo(size: 32),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Pengeluaran tetap\ntiap bulan',
            style: AppTextStyles.h1.copyWith(color: textColor),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Kos, listrik, internet — yang pasti keluar tiap bulan.',
            style: AppTextStyles.bodySmall.copyWith(color: textSoftColor),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppTextField(
            controller: _fixedController,
            label: 'Total pengeluaran tetap',
            hintText: 'Contoh: 600000',
            errorText: _fixedError,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          if (_previewFixed.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _previewFixed,
              style: AppTextStyles.h3.copyWith(
                color: AppColors.warn,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.xxxl),
          PrimaryButton(
            label: 'Lanjut',
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ── Step 3 — Emergency Fund + Preview ─────────────────────────────────────

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

  DailyBudgetResult _calcPreview() {
    final available = widget.income - widget.fixedExpenses;
    final availablePositive = available < 0 ? 0 : available;
    final emergency = (availablePositive * _emergencyPct).round();
    final spendable = availablePositive - emergency;
    final daily = widget.remainingDays > 0
        ? (spendable / widget.remainingDays).floor()
        : 0;
    return DailyBudgetResult(
      dailyBudget: daily < 0 ? 0 : daily,
      totalAvailable: availablePositive,
      emergencyFund: emergency,
      remainingDays: widget.remainingDays,
    );
  }

  void _submit() {
    context.read<OnboardingBloc>().add(
          Step3Submitted(emergencyFundPct: _emergencyPct),
        );
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.isDark ? AppColors.textDark : AppColors.textLight;
    final textSoftColor =
        widget.isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
    final surfaceColor =
        widget.isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor =
        widget.isDark ? AppColors.borderDark : AppColors.borderLight;

    final pctInt = (_emergencyPct * 100).round();
    final preview = _calcPreview();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PenyintasLogo(size: 32),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Seberapa besar\ndana darurat?',
            style: AppTextStyles.h1.copyWith(color: textColor),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Disarankan 10% dari sisa. Tapi kamu yang menentukan.',
            style: AppTextStyles.bodySmall.copyWith(color: textSoftColor),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Percentage label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dana darurat',
                style: AppTextStyles.label.copyWith(color: textColor),
              ),
              Text(
                '$pctInt%',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.primary,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: borderColor,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withAlpha(30),
              trackHeight: 4,
            ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('5%',
                  style: AppTextStyles.caption.copyWith(color: textSoftColor)),
              Text('25%',
                  style: AppTextStyles.caption.copyWith(color: textSoftColor)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Preview card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                _PreviewRow(
                  label: 'Kiriman bulanan',
                  value: formatRupiah(widget.income),
                  textColor: textColor,
                  valueColor: textColor,
                ),
                const SizedBox(height: AppSpacing.sm),
                _PreviewRow(
                  label: 'Pengeluaran tetap',
                  value: '− ${formatRupiah(widget.fixedExpenses)}',
                  textColor: textSoftColor,
                  valueColor: AppColors.warn,
                ),
                const SizedBox(height: AppSpacing.sm),
                _PreviewRow(
                  label: 'Dana darurat ($pctInt%)',
                  value: '− ${formatRupiah(preview.emergencyFund)}',
                  textColor: textSoftColor,
                  valueColor: AppColors.caution,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Divider(color: borderColor, height: 1),
                ),
                _PreviewRow(
                  label: 'Anggaran harian',
                  value: formatRupiah(preview.dailyBudget),
                  textColor: textColor,
                  valueColor: AppColors.primary,
                  isHighlight: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),

          PrimaryButton(
            label: 'Mulai bertahan',
            onPressed: _submit,
            isLoading: widget.isLoading,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.label,
    required this.value,
    required this.textColor,
    required this.valueColor,
    this.isHighlight = false,
  });

  final String label;
  final String value;
  final Color textColor;
  final Color valueColor;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (isHighlight ? AppTextStyles.label : AppTextStyles.bodySmall)
              .copyWith(color: textColor),
        ),
        Text(
          value,
          style: (isHighlight ? AppTextStyles.label : AppTextStyles.bodySmall)
              .copyWith(
            color: valueColor,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
