import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/add_transaction_bloc.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/transaction_list_bloc.dart';
import 'package:penyintas_app/features/transaction/presentation/widgets/add_transaction_sheet.dart';
import 'package:penyintas_app/features/transaction/presentation/widgets/transaction_item.dart';

class TransactionListPage extends StatelessWidget {
  const TransactionListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TransactionListBloc>()
        ..add(LoadTransactions(
          from: DateTime(
              DateTime.now().year, DateTime.now().month, 1),
          to: DateTime.now(),
        )),
      child: const _TransactionListView(),
    );
  }
}

class _TransactionListView extends StatelessWidget {
  const _TransactionListView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.bgDark : AppColors.bgLight,
        elevation: 0,
        title: Text('Transaksi', style: AppTextStyles.h3),
        actions: [
          BlocBuilder<TransactionListBloc, TransactionListState>(
            builder: (context, state) {
              if (state is! TransactionListLoaded) {
                return const SizedBox.shrink();
              }
              return _FilterChips(activeFilter: state.activeFilter);
            },
          ),
        ],
      ),
      body: BlocBuilder<TransactionListBloc, TransactionListState>(
        builder: (context, state) {
          if (state is TransactionListLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TransactionListError) {
            return Center(
              child: Text(state.message, style: AppTextStyles.body),
            );
          }
          if (state is TransactionListLoaded) {
            return _LoadedBody(state: state);
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openAddSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openAddSheet(BuildContext context) async {
    final listBloc = context.read<TransactionListBloc>();
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => sl<AddTransactionBloc>(),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: const AddTransactionSheet(),
        ),
      ),
    );
    if (context.mounted) {
      listBloc.add(const RefreshTransactions());
    }
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.state});
  final TransactionListLoaded state;

  @override
  Widget build(BuildContext context) {
    if (state.filtered.isEmpty) {
      return Center(
        child: Text(
          'Belum ada catatan.\nMulai dari satu pengeluaran kecil hari ini.',
          style: AppTextStyles.body,
          textAlign: TextAlign.center,
        ),
      );
    }

    final grouped = _groupByDate(state.filtered);
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<TransactionListBloc>().add(const RefreshTransactions()),
      child: ListView.builder(
        itemCount: dates.length,
        itemBuilder: (context, i) {
          final date = dates[i];
          final items = grouped[date]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
                child: Text(
                  _dateHeader(date),
                  style: AppTextStyles.caption,
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) return 'HARI INI';
    if (date == yesterday) return 'KEMARIN';
    return DateFormat('EEEE, d MMMM', 'id_ID').format(date).toUpperCase();
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.activeFilter});
  final TransactionCategory? activeFilter;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Row(
        children: [
          _chip(context, null, 'Semua'),
          _chip(context, TransactionCategory.food, 'Makan'),
          _chip(context, TransactionCategory.transport, 'Transport'),
          _chip(context, TransactionCategory.shopping, 'Belanja'),
        ],
      ),
    );
  }

  Widget _chip(
      BuildContext context, TransactionCategory? cat, String label) {
    final isActive = activeFilter == cat;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: FilterChip(
        label: Text(label, style: AppTextStyles.caption),
        selected: isActive,
        selectedColor: AppColors.primary.withAlpha(30),
        checkmarkColor: AppColors.primary,
        onSelected: (_) => context
            .read<TransactionListBloc>()
            .add(FilterChanged(cat)),
      ),
    );
  }
}
