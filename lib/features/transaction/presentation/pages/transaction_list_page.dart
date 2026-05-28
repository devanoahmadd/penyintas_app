import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/goal/domain/entities/goal_entity.dart';
import 'package:penyintas_app/features/goal/domain/usecases/load_goals_usecase.dart';
import 'package:penyintas_app/features/goal/presentation/bloc/goal_bloc.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/update_transaction_usecase.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/add_transaction_bloc.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/edit_transaction_bloc.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/transaction_list_bloc.dart';
import 'package:penyintas_app/features/transaction/presentation/widgets/add_transaction_sheet.dart';
import 'package:penyintas_app/features/transaction/presentation/widgets/edit_transaction_sheet.dart';
import 'package:penyintas_app/features/transaction/presentation/widgets/transaction_detail_sheet.dart';
import 'package:penyintas_app/features/transaction/presentation/widgets/transaction_filter_sheet.dart';
import 'package:penyintas_app/features/transaction/presentation/widgets/transaction_item.dart';
import 'package:penyintas_app/widgets/common/app_bottom_nav_bar.dart';

// ── V2 spec constants ─────────────────────────────────────────────────────────
const double _spineX = 18;
const double _spineW = 2;
const double _spineOpacity = 0.3;
const double _dayNodeD = 38;
const double _connectorW = 14;
const double _connectorH = 1.5;
const double _dotD = 6;
const double _rowGap = 6;
const double _groupGap = 16;
const double _filterPillH = 36;
// Left of connector area = dayNode(38) + gap(12) - connectorAreaW(16) = 34
const double _txOffset = 34;
const double _connectorAreaW = 16;

// ── Color helpers ─────────────────────────────────────────────────────────────

Color _txColor(bool isDark, bool isIncome) {
  if (isIncome) return isDark ? AppColors.incomeDark : AppColors.success;
  return isDark ? AppColors.expenseDark : AppColors.warn;
}

Color _txBg(bool isDark, bool isIncome) {
  if (isDark) {
    return isIncome
        // ignore: deprecated_member_use
        ? const Color(0xFF6EE7A0).withOpacity(0.12)
        // ignore: deprecated_member_use
        : const Color(0xFFFF8F70).withOpacity(0.10);
  }
  return isIncome
      // ignore: deprecated_member_use
      ? const Color(0xFF16A34A).withOpacity(0.10)
      // ignore: deprecated_member_use
      : const Color(0xFFE07A3C).withOpacity(0.08);
}

// ── Page ──────────────────────────────────────────────────────────────────────

class TransactionListPage extends StatelessWidget {
  const TransactionListPage({super.key});

  @override
  Widget build(BuildContext context) => const _TransactionListView();
}

class _TransactionListView extends StatefulWidget {
  const _TransactionListView();
  @override
  State<_TransactionListView> createState() => _TransactionListViewState();
}

class _TransactionListViewState extends State<_TransactionListView> {
  bool _searchActive = false;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchActive = !_searchActive;
      if (!_searchActive) {
        _searchQuery = '';
        _searchCtrl.clear();
      }
    });
  }

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
              // Title row or search bar
              if (_searchActive)
                _V2SearchBar(
                  controller: _searchCtrl,
                  searchQuery: _searchQuery,
                  onChanged: (q) => setState(() => _searchQuery = q),
                  onClose: _toggleSearch,
                )
              else
                BlocBuilder<TransactionListBloc, TransactionListState>(
                  buildWhen: (p, n) =>
                      p.runtimeType != n.runtimeType ||
                      (p is TransactionListLoaded &&
                          n is TransactionListLoaded &&
                          p.from != n.from),
                  builder: (context, state) => _V2TitleRow(
                    selectedMonth:
                        state is TransactionListLoaded ? state.from : DateTime.now(),
                  ),
                ),
              // Summary row — rebuilds only when all-transactions list changes
              BlocBuilder<TransactionListBloc, TransactionListState>(
                buildWhen: (p, n) =>
                    n is TransactionListLoaded &&
                    (p is! TransactionListLoaded ||
                        p.transactions != n.transactions),
                builder: (context, state) {
                  if (state is! TransactionListLoaded) {
                    return const SizedBox.shrink();
                  }
                  return _V2SummaryRow(transactions: state.transactions);
                },
              ),
              // Filter row — rebuilds only on filter change
              BlocBuilder<TransactionListBloc, TransactionListState>(
                buildWhen: (p, n) =>
                    p.runtimeType != n.runtimeType ||
                    (p is TransactionListLoaded &&
                        n is TransactionListLoaded &&
                        p.typeFilter != n.typeFilter),
                builder: (context, state) {
                  if (state is! TransactionListLoaded) {
                    return const SizedBox.shrink();
                  }
                  return _V2FilterRow(
                    typeFilter: state.typeFilter,
                    onSearchTap: _toggleSearch,
                    onFilterTap: () {
                      final s = context.read<TransactionListBloc>().state;
                      if (s is TransactionListLoaded) _openFilterSheet(s);
                    },
                  );
                },
              ),
              // Timeline
              Expanded(
                child: BlocBuilder<TransactionListBloc, TransactionListState>(
                  builder: (context, state) {
                    if (state is TransactionListLoading) {
                      return const _V2Skeleton();
                    }
                    if (state is TransactionListError) {
                      return Center(
                          child:
                              Text(state.message, style: AppTextStyles.body));
                    }
                    if (state is TransactionListLoaded) {
                      return _V2Timeline(
                        state: state,
                        onAddTap: _openAddSheet,
                        onTap: _openDetailSheet,
                        searchQuery: _searchQuery,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: AppNavFab(onTap: _openAddSheet),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: 1,
          onFabTap: _openAddSheet,
        ),
      ),
    );
  }

  Future<void> _openAddSheet() async {
    final listBloc = context.read<TransactionListBloc>();

    final goalsResult = await sl<LoadGoalsUseCase>().call(const NoParams());
    final activeGoals = goalsResult.fold(
      (_) => <GoalEntity>[],
      (goals) => goals.where((g) => !g.isCompleted).toList(),
    );

    if (!mounted) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => sl<AddTransactionBloc>(),
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: AddTransactionSheet(activeGoals: activeGoals),
        ),
      ),
    );

    if (mounted) {
      listBloc.add(const RefreshTransactions());
      if (saved == true) sl<GoalBloc>().add(const LoadGoals());
    }
  }

  Future<void> _openFilterSheet(TransactionListLoaded state) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<TransactionListBloc>(),
        child: TransactionFilterSheet(currentState: state),
      ),
    );
  }

  Future<void> _openDetailSheet(TransactionEntity tx) async {
    final goalsResult = await sl<LoadGoalsUseCase>().call(const NoParams());
    final activeGoals = goalsResult.fold(
      (_) => <GoalEntity>[],
      (goals) => goals.where((g) => !g.isCompleted).toList(),
    );

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<TransactionListBloc>(),
        child: TransactionDetailSheet(
          transaction: tx,
          activeGoals: activeGoals,
          onDuplicate: (t) => _openDuplicateSheet(t, activeGoals),
          onEdit: (t) => _openEditSheet(t, activeGoals),
        ),
      ),
    );
  }

  Future<void> _openDuplicateSheet(
      TransactionEntity tx, List<GoalEntity> activeGoals) async {
    final listBloc = context.read<TransactionListBloc>();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => sl<AddTransactionBloc>(),
        child: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: AddTransactionSheet(
            activeGoals: activeGoals,
            initial: tx,
          ),
        ),
      ),
    );

    if (mounted && saved == true) {
      listBloc.add(const RefreshTransactions());
      sl<GoalBloc>().add(const LoadGoals());
    }
  }

  Future<void> _openEditSheet(
      TransactionEntity tx, List<GoalEntity> activeGoals) async {
    final listBloc = context.read<TransactionListBloc>();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => EditTransactionBloc(
          updateTransaction: sl<UpdateTransactionUseCase>(),
          initial: tx,
        ),
        child: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: EditTransactionSheet(activeGoals: activeGoals),
        ),
      ),
    );

    if (mounted && saved == true) {
      listBloc.add(const RefreshTransactions());
      sl<GoalBloc>().add(const LoadGoals());
    }
  }
}

// ── V2 Title row ──────────────────────────────────────────────────────────────

class _V2TitleRow extends StatelessWidget {
  const _V2TitleRow({required this.selectedMonth});
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Transaksi',
            style: AppTextStyles.h1.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.05,
              letterSpacing: -0.7,
              color: textColor,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _pickMonth(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 13, color: textColor),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('MMMM yyyy', 'id_ID').format(selectedMonth),
                    style: AppTextStyles.label.copyWith(
                      fontSize: 12,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 13, color: mutedColor),
                ],
              ),
            ),
          ),
        ],
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

// ── V2 Summary row ────────────────────────────────────────────────────────────

class _V2SummaryRow extends StatelessWidget {
  const _V2SummaryRow({required this.transactions});
  final List<TransactionEntity> transactions;

  @override
  Widget build(BuildContext context) {
    final totalMasuk = transactions
        .where((t) => t.type == TransactionType.income)
        .fold<int>(0, (s, t) => s + t.amount);
    final totalKeluar = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold<int>(0, (s, t) => s + t.amount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _SummaryStat(
                isIncome: false, label: 'KELUAR', value: totalKeluar),
          ),
          const SizedBox(width: AppSpacing.sm2),
          Expanded(
            child: _SummaryStat(
                isIncome: true, label: 'MASUK', value: totalMasuk),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.isIncome,
    required this.label,
    required this.value,
  });

  final bool isIncome;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amtColor = _txColor(isDark, isIncome);
    final amtBgColor = _txBg(isDark, isIncome);
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: amtBgColor, shape: BoxShape.circle),
                child: Icon(
                  isIncome
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  size: 11,
                  color: amtColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: mutedColor,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            formatRupiah(value),
            style: AppTextStyles.numericSm.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: amtColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── V2 Filter row ─────────────────────────────────────────────────────────────

class _V2FilterRow extends StatelessWidget {
  const _V2FilterRow({
    required this.typeFilter,
    required this.onSearchTap,
    required this.onFilterTap,
  });
  final TransactionType? typeFilter;
  final VoidCallback onSearchTap;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          _TypePill(label: 'Semua', type: null, active: typeFilter),
          const SizedBox(width: AppSpacing.sm),
          _TypePill(
              label: 'Masuk',
              type: TransactionType.income,
              active: typeFilter),
          const SizedBox(width: AppSpacing.sm),
          _TypePill(
              label: 'Keluar',
              type: TransactionType.expense,
              active: typeFilter),
          const Spacer(),
          _IconRoundButton(
              icon: Icons.search_rounded,
              borderColor: borderColor,
              iconColor: textColor,
              onTap: onSearchTap),
          const SizedBox(width: AppSpacing.sm),
          _IconRoundButton(
              icon: Icons.tune_rounded,
              borderColor: borderColor,
              iconColor: textColor,
              onTap: onFilterTap),
        ],
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill(
      {required this.label, required this.type, required this.active});
  final String label;
  final TransactionType? type;
  final TransactionType? active;

  @override
  Widget build(BuildContext context) {
    final isActive = active == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return GestureDetector(
      onTap: () =>
          context.read<TransactionListBloc>().add(FilterChanged(type)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: _filterPillH,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: isActive ? null : Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            fontSize: 12,
            color: isActive ? Colors.white : textColor,
          ),
        ),
      ),
    );
  }
}

class _IconRoundButton extends StatelessWidget {
  const _IconRoundButton({
    required this.icon,
    required this.borderColor,
    required this.iconColor,
    this.onTap,
  });
  final IconData icon;
  final Color borderColor;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor),
        ),
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }
}

// ── V2 Timeline ───────────────────────────────────────────────────────────────

class _V2Timeline extends StatelessWidget {
  const _V2Timeline({
    required this.state,
    required this.onAddTap,
    required this.onTap,
    this.searchQuery = '',
  });
  final TransactionListLoaded state;
  final VoidCallback onAddTap;
  final void Function(TransactionEntity) onTap;
  final String searchQuery;

  static bool _matchesSearch(TransactionEntity t, String q) {
    final lower = q.toLowerCase();
    if (t.note?.toLowerCase().contains(lower) ?? false) { return true; }
    return t.category.label.toLowerCase().contains(lower);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayList = searchQuery.isEmpty
        ? state.filtered
        : state.filtered.where((t) => _matchesSearch(t, searchQuery)).toList();

    if (displayList.isEmpty) {
      return _V2EmptyState(
        onAddTap: onAddTap,
        isFiltered: state.transactions.isNotEmpty || searchQuery.isNotEmpty,
      );
    }

    final grouped = _groupByDate(displayList);
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final bloc = context.read<TransactionListBloc>();

    return RefreshIndicator(
      onRefresh: () async => bloc.add(const RefreshTransactions()),
      child: ListView.builder(
        padding: const EdgeInsets.only(
            top: AppSpacing.md2, bottom: AppSpacing.xxxl),
        itemCount: dates.length + 1,
        itemBuilder: (context, i) {
          if (i == dates.length) {
            return _V2EndCap(isDark: isDark);
          }
          final date = dates[i];
          final items = grouped[date]!;
          return _V2DayGroup(
            date: date,
            items: items,
            isDark: isDark,
            isLast: i == dates.length - 1,
            onDelete: (id) => bloc.add(DeleteTransactionRequested(id)),
            onTap: onTap,
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
}

// ── V2 Day group ──────────────────────────────────────────────────────────────

class _V2DayGroup extends StatelessWidget {
  const _V2DayGroup({
    required this.date,
    required this.items,
    required this.isDark,
    required this.isLast,
    required this.onDelete,
    required this.onTap,
  });

  final DateTime date;
  final List<TransactionEntity> items;
  final bool isDark;
  final bool isLast;
  final void Function(String id) onDelete;
  final void Function(TransactionEntity) onTap;

  @override
  Widget build(BuildContext context) {
    final subtotal = items.fold<int>(
      0,
      (s, t) =>
          t.type == TransactionType.income ? s + t.amount : s - t.amount,
    );
    final isPositive = subtotal >= 0;
    final subtotalColor = _txColor(isDark, isPositive);
    final subtotalBg = _txBg(isDark, isPositive);
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Padding(
      padding: EdgeInsets.only(
          left: AppSpacing.lg, right: AppSpacing.lg, bottom: _groupGap),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Spine — behind content
          Positioned(
            left: _spineX,
            top: 0,
            bottom: isLast ? 0 : -_groupGap / 2,
            width: _spineW,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    // ignore: deprecated_member_use
                    AppColors.primary.withOpacity(_spineOpacity),
                    // ignore: deprecated_member_use
                    AppColors.primary.withOpacity(isLast ? 0 : _spineOpacity),
                  ],
                  stops: isLast ? const [0.65, 1.0] : const [0.0, 1.0],
                ),
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day node row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _DayNode(date: date, isDark: isDark),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _dayLabel(date),
                          style: AppTextStyles.label.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${items.length} transaksi',
                          style: AppTextStyles.caption.copyWith(
                            color: mutedColor,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Daily subtotal pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm2, vertical: 5),
                    decoration: BoxDecoration(
                      color: subtotalBg,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      '${isPositive ? '+' : '−'} ${formatRupiah(subtotal.abs())}',
                      style: AppTextStyles.numericSm.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: subtotalColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm2),
              // Transaction rows
              Padding(
                padding: const EdgeInsets.only(left: _txOffset),
                child: Column(
                  children: [
                    for (int i = 0; i < items.length; i++) ...[
                      _V2TxRow(
                        transaction: items[i],
                        isDark: isDark,
                        onDelete: () => onDelete(items[i].id),
                        onTap: () => onTap(items[i]),
                      ),
                      if (i < items.length - 1)
                        const SizedBox(height: _rowGap),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _dayLabel(DateTime date) {
    final today = DateUtils.dateOnly(DateTime.now());
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return DateFormat('EEEE, d MMMM', 'id_ID').format(date);
  }
}

// ── Day node circle ───────────────────────────────────────────────────────────

class _DayNode extends StatelessWidget {
  const _DayNode({required this.date, required this.isDark});
  final DateTime date;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final monthAbbr = DateFormat('MMM', 'id_ID')
        .format(date)
        .toUpperCase()
        .replaceAll('.', '');

    return Container(
      width: _dayNodeD,
      height: _dayNodeD,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: bgColor, spreadRadius: 4, blurRadius: 0),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${date.day}',
            style: AppTextStyles.h3.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.0,
              color: Colors.white,
            ),
          ),
          Text(
            monthAbbr,
            style: AppTextStyles.caption.copyWith(
              fontSize: 7,
              fontWeight: FontWeight.w500,
              height: 1.2,
              letterSpacing: 0.4,
              color: AppColors.shoot,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Transaction row V2 (connector + dot + dismissible card) ───────────────────

class _V2TxRow extends StatelessWidget {
  const _V2TxRow({
    required this.transaction,
    required this.isDark,
    this.onDelete,
    this.onTap,
  });

  final TransactionEntity transaction;
  final bool isDark;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final amtColor = _txColor(isDark, isIncome);
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Connector + dot area
          SizedBox(
            width: _connectorAreaW,
            child: Stack(
              children: [
                // Horizontal connector line (centered)
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: _connectorW,
                    height: _connectorH,
                    color: borderColor,
                  ),
                ),
                // Colored dot at spine end (left-center)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: _dotD,
                      height: _dotD,
                      decoration: BoxDecoration(
                        color: amtColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: bgColor, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Card with swipe-to-delete
          Expanded(
            child: Dismissible(
              key: Key(transaction.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.warn,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.delete_outline,
                    color: Colors.white, size: 18),
              ),
              onDismissed: (_) => onDelete?.call(),
              child: GestureDetector(
                onTap: onTap,
                child: TransactionItem(transaction: transaction),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timeline end cap ──────────────────────────────────────────────────────────

class _V2EndCap extends StatelessWidget {
  const _V2EndCap({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;

    return Padding(
      padding: const EdgeInsets.only(
          left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: _dayNodeD,
            height: _dayNodeD,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 1.5),
              color: bgColor,
            ),
            child: Icon(Icons.more_horiz_rounded, size: 14, color: mutedColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Awal bulan',
            style: AppTextStyles.bodySmall.copyWith(
              color: mutedColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
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
    const monthNames = [
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
                onPressed:
                    _year >= now.year ? null : () => setState(() => _year++),
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
              final isSelected =
                  _year == widget.initial.year && month == widget.initial.month;
              return GestureDetector(
                onTap: isFuture
                    ? null
                    : () => Navigator.pop(context, DateTime(_year, month)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.primary : Colors.transparent,
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

// ── Loading skeleton ──────────────────────────────────────────────────────────

class _V2Skeleton extends StatefulWidget {
  const _V2Skeleton();
  @override
  State<_V2Skeleton> createState() => _V2SkeletonState();
}

class _V2SkeletonState extends State<_V2Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _opacity = Tween(begin: 0.6, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skColor = isDark ? AppColors.cardDark : AppColors.cardLight;

    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, _) => Opacity(
        opacity: _opacity.value,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: _SkBox(skColor,
                        height: 72, radius: AppRadius.md)),
                const SizedBox(width: AppSpacing.sm2),
                Expanded(
                    child: _SkBox(skColor,
                        height: 72, radius: AppRadius.md)),
              ]),
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                _SkBox(skColor,
                    width: 64, height: _filterPillH, radius: AppRadius.pill),
                const SizedBox(width: AppSpacing.sm),
                _SkBox(skColor,
                    width: 54, height: _filterPillH, radius: AppRadius.pill),
                const SizedBox(width: AppSpacing.sm),
                _SkBox(skColor,
                    width: 58, height: _filterPillH, radius: AppRadius.pill),
                const Spacer(),
                _SkBox(skColor,
                    width: 36, height: 36, radius: AppRadius.pill),
                const SizedBox(width: AppSpacing.sm),
                _SkBox(skColor,
                    width: 36, height: 36, radius: AppRadius.pill),
              ]),
              const SizedBox(height: AppSpacing.md2),
              for (final rowCount in [3, 2, 4]) ...[
                _SkDayGroup(skColor: skColor, rowCount: rowCount),
                const SizedBox(height: _groupGap),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SkBox extends StatelessWidget {
  const _SkBox(this.color,
      {this.width, required this.height, this.radius = AppRadius.sm});
  final Color color;
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

class _SkDayGroup extends StatelessWidget {
  const _SkDayGroup({required this.skColor, required this.rowCount});
  final Color skColor;
  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _SkBox(skColor,
              width: _dayNodeD, height: _dayNodeD, radius: _dayNodeD),
          const SizedBox(width: AppSpacing.md),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _SkBox(skColor, width: 90, height: 13, radius: AppRadius.sm),
            const SizedBox(height: 4),
            _SkBox(skColor, width: 54, height: 10, radius: AppRadius.sm),
          ]),
        ]),
        const SizedBox(height: AppSpacing.sm2),
        Padding(
          padding: const EdgeInsets.only(left: _txOffset),
          child: Column(children: [
            for (int i = 0; i < rowCount; i++) ...[
              _SkBox(skColor, height: 52, radius: AppRadius.md),
              if (i < rowCount - 1) const SizedBox(height: _rowGap),
            ],
          ]),
        ),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _V2EmptyState extends StatelessWidget {
  const _V2EmptyState({
    required this.onAddTap,
    this.isFiltered = false,
  });
  final VoidCallback onAddTap;
  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              children: [
                Container(
                  width: _spineW,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        // ignore: deprecated_member_use
                        AppColors.primary.withOpacity(_spineOpacity),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                      Icons.add_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: _dotD,
                  height: _dotD,
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: mutedColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              isFiltered ? 'Tidak ada hasil' : 'Belum ada transaksi',
              style: AppTextStyles.h2.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isFiltered
                  ? 'Coba ubah filter atau pilih periode lain.'
                  : 'Catat pengeluaran pertama kamu hari ini.',
              style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
              textAlign: TextAlign.center,
            ),
            if (!isFiltered) ...[
              const SizedBox(height: AppSpacing.xl),
              GestureDetector(
                onTap: onAddTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'Tambah Transaksi',
                    style: AppTextStyles.label.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _V2SearchBar extends StatelessWidget {
  const _V2SearchBar({
    required this.controller,
    required this.searchQuery,
    required this.onChanged,
    required this.onClose,
  });
  final TextEditingController controller;
  final String searchQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: Icon(Icons.search_rounded,
                        size: 16, color: mutedColor),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onChanged: onChanged,
                      autofocus: true,
                      style: AppTextStyles.body.copyWith(
                        color: textColor,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari transaksi...',
                        hintStyle: AppTextStyles.body.copyWith(
                          color: mutedColor,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm2),
                      ),
                    ),
                  ),
                  if (searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        controller.clear();
                        onChanged('');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: mutedColor),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onClose,
            child: Text(
              'Batal',
              style: AppTextStyles.label.copyWith(
                color: AppColors.primary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
