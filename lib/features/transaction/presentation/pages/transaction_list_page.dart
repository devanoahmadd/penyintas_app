import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/goal/domain/entities/goal_entity.dart';
import 'package:penyintas_app/features/goal/domain/usecases/load_goals_usecase.dart';
import 'package:penyintas_app/features/goal/presentation/bloc/goal_bloc.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/add_transaction_bloc.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/transaction_list_bloc.dart';
import 'package:penyintas_app/features/transaction/presentation/widgets/add_transaction_sheet.dart';
import 'package:penyintas_app/features/transaction/presentation/widgets/transaction_item.dart';
import 'package:penyintas_app/widgets/common/app_bottom_nav_bar.dart';

class TransactionListPage extends StatelessWidget {
  const TransactionListPage({super.key});

  @override
  Widget build(BuildContext context) => const _TransactionListView();
}

class _TransactionListView extends StatelessWidget {
  const _TransactionListView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/dashboard');
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
                child: Text(context.l10n.navTransactions, style: AppTextStyles.h1),
              ),
              BlocBuilder<TransactionListBloc, TransactionListState>(
                buildWhen: (p, n) =>
                    p.runtimeType != n.runtimeType ||
                    (p is TransactionListLoaded &&
                        n is TransactionListLoaded &&
                        (p.typeFilter != n.typeFilter || p.from != n.from)),
                builder: (context, state) {
                  final typeFilter =
                      state is TransactionListLoaded ? state.typeFilter : null;
                  final selectedMonth =
                      state is TransactionListLoaded ? state.from : DateTime.now();
                  return _FilterRow(
                      typeFilter: typeFilter, selectedMonth: selectedMonth);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: BlocBuilder<TransactionListBloc, TransactionListState>(
                  builder: (context, state) {
                    if (state is TransactionListLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is TransactionListError) {
                      return Center(
                          child:
                              Text(state.message, style: AppTextStyles.body));
                    }
                    if (state is TransactionListLoaded) {
                      return _LoadedBody(state: state);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: AppNavFab(onTap: () => _openAddSheet(context)),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: 1,
          onFabTap: () => _openAddSheet(context),
        ),
      ),
    );
  }

  Future<void> _openAddSheet(BuildContext context) async {
    final listBloc = context.read<TransactionListBloc>();

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
        child: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: AddTransactionSheet(activeGoals: activeGoals),
        ),
      ),
    );

    if (context.mounted) {
      listBloc.add(const RefreshTransactions());
      if (saved == true) sl<GoalBloc>().add(const LoadGoals());
    }
  }
}

// ── Filter row ────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.typeFilter, required this.selectedMonth});
  final TransactionType? typeFilter;
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          _TypeChip(label: 'Semua', type: null, active: typeFilter),
          const SizedBox(width: AppSpacing.sm),
          _TypeChip(
              label: 'Masuk', type: TransactionType.income, active: typeFilter),
          const SizedBox(width: AppSpacing.sm),
          _TypeChip(
              label: 'Keluar',
              type: TransactionType.expense,
              active: typeFilter),
          const Spacer(),
          _DateChip(selectedMonth: selectedMonth),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip(
      {required this.label, required this.type, required this.active});
  final String label;
  final TransactionType? type;
  final TransactionType? active;

  @override
  Widget build(BuildContext context) {
    final isActive = active == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () =>
          context.read<TransactionListBloc>().add(FilterChanged(type)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary
              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: isActive
              ? null
              : Border.all(
                  color:
                      isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: isActive
                ? Colors.white
                : (isDark
                    ? AppColors.textSoftDark
                    : AppColors.textSoftLight),
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.selectedMonth});
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = DateFormat('MMMM', 'id_ID').format(selectedMonth);

    return GestureDetector(
      onTap: () => _pickMonth(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 13,
                color: isDark ? AppColors.mutedDark : AppColors.mutedLight),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: isDark
                    ? AppColors.textSoftDark
                    : AppColors.textSoftLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMonth(BuildContext context) async {
    final bloc = context.read<TransactionListBloc>();
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MonthPickerSheet(initial: selectedMonth),
    );
    if (picked != null && context.mounted) {
      final now = DateTime.now();
      final isCurrentMonth =
          picked.year == now.year && picked.month == now.month;
      final to = isCurrentMonth
          ? now
          : DateTime(picked.year, picked.month + 1, 0);
      bloc.add(LoadTransactions(from: picked, to: to));
    }
  }
}

// ── Month picker bottom sheet ─────────────────────────────────────────────────

class _MonthPickerSheet extends StatefulWidget {
  const _MonthPickerSheet({required this.initial});
  final DateTime initial;

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _year--),
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
              Text('$_year', style: AppTextStyles.h3),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _year >= now.year
                    ? null
                    : () => setState(() => _year++),
                color: _year >= now.year
                    ? (isDark ? AppColors.mutedDark : AppColors.mutedLight)
                    : (isDark ? AppColors.textDark : AppColors.textLight),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 2.2,
            children: List.generate(12, (i) {
              final month = i + 1;
              final isFuture = DateTime(_year, month)
                  .isAfter(DateTime(now.year, now.month));
              final isSelected = _year == widget.initial.year &&
                  month == widget.initial.month;
              return GestureDetector(
                onTap: isFuture
                    ? null
                    : () => Navigator.pop(context, DateTime(_year, month)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    monthNames[i],
                    style: AppTextStyles.label.copyWith(
                      color: isSelected
                          ? Colors.white
                          : isFuture
                              ? (isDark
                                  ? AppColors.mutedDark
                                  : AppColors.mutedLight)
                              : (isDark
                                  ? AppColors.textDark
                                  : AppColors.textLight),
                    ),
                  ),
                ),
              );
            }),
          ),
          SizedBox(
              height: MediaQuery.of(context).padding.bottom + AppSpacing.sm),
        ],
      ),
    );
  }
}

// ── Loaded body ───────────────────────────────────────────────────────────────

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.state});
  final TransactionListLoaded state;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    if (state.filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'Belum ada catatan bulan ini.\nMulai dari satu pengeluaran kecil hari ini.',
            style: AppTextStyles.body.copyWith(color: mutedColor),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final grouped = _groupByDate(state.filtered);
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<TransactionListBloc>().add(const RefreshTransactions()),
      child: ListView.builder(
        padding: const EdgeInsets.only(
            top: AppSpacing.xs, bottom: AppSpacing.lg),
        itemCount: dates.length,
        itemBuilder: (context, i) {
          final date = dates[i];
          final items = grouped[date]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                child: Row(
                  children: [
                    Text(
                      _dateHeader(date),
                      style: AppTextStyles.caption.copyWith(
                        color: mutedColor,
                        fontSize: 11,
                        letterSpacing: 1.32,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                  ],
                ),
              ),
              ...items.map((t) => TransactionItem(
                    transaction: t,
                    onDelete: () => context
                        .read<TransactionListBloc>()
                        .add(DeleteTransactionRequested(t.id)),
                  )),
            ],
          );
        },
      ),
    );
  }

  Map<DateTime, List<TransactionEntity>> _groupByDate(
      List<TransactionEntity> list) {
    final map = <DateTime, List<TransactionEntity>>{};
    for (final t in list) {
      final key = DateTime(t.date.year, t.date.month, t.date.day);
      (map[key] ??= []).add(t);
    }
    return map;
  }

  String _dateHeader(DateTime date) {
    final today = DateUtils.dateOnly(DateTime.now());
    final diff = today.difference(date).inDays;
    if (diff == 0) {
      return 'HARI INI · ${DateFormat('d MMM', 'id_ID').format(date).toUpperCase()}';
    }
    if (diff == 1) {
      return 'KEMARIN · ${DateFormat('d MMM', 'id_ID').format(date).toUpperCase()}';
    }
    return DateFormat('d MMMM yyyy', 'id_ID').format(date).toUpperCase();
  }
}
