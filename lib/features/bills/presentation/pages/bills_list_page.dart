import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/presentation/bloc/bills_bloc.dart';
import 'package:penyintas_app/features/bills/presentation/widgets/add_edit_bill_sheet.dart';
import 'package:penyintas_app/features/bills/presentation/widgets/bill_item.dart';
import 'package:penyintas_app/features/bills/presentation/widgets/bill_status_chip.dart';
import 'package:penyintas_app/features/bills/presentation/widgets/mark_bill_paid_sheet.dart';
import 'package:penyintas_app/features/budget/domain/usecases/get_budget_settings_usecase.dart';

/// Urutan tampilan daftar tagihan (spec §5):
/// tagihan TERLAMBAT naik ke atas, sisanya urut `dueDate` menaik.
///
/// Sengaja tidak bergantung pada urutan yang datang dari stream — halaman ini
/// yang memegang kontrak urutan tampilan.
List<BillEntity> sortBillsForDisplay(
  List<BillEntity> bills,
  DateTime todayStart,
) {
  final sorted = [...bills];
  sorted.sort((a, b) {
    final aOverdue = a.isOverdue(todayStart);
    final bOverdue = b.isOverdue(todayStart);
    if (aOverdue != bOverdue) return aOverdue ? -1 : 1;
    return a.dueDate.compareTo(b.dueDate);
  });
  return sorted;
}

class BillsListPage extends StatefulWidget {
  const BillsListPage({super.key});

  @override
  State<BillsListPage> createState() => _BillsListPageState();
}

class _BillsListPageState extends State<BillsListPage> {
  @override
  void initState() {
    super.initState();
    context.read<BillsBloc>().add(const BillsSubscribed());
  }

  void _openAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<BillsBloc>(),
        child: const AddEditBillSheet(),
      ),
    );
  }

  Future<void> _openMarkPaidSheet(BillEntity bill) async {
    // Bloc dibaca SEBELUM await — setelah await, `context` tak lagi dijamin
    // hidup (lint `use_build_context_synchronously`).
    final bloc = context.read<BillsBloc>();
    // M1 §4.2: prefill "kebutuhan tetap" butuh fixedExpenses; gagal → null
    // (fail-open).
    final int? fixedExpenses = (await sl<GetBudgetSettingsUseCase>()(
      NoParams(),
    )).fold((_) => null, (s) => s.fixedExpenses);
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: MarkBillPaidSheet(bill: bill, fixedExpenses: fixedExpenses),
      ),
    );
  }

  /// Satu snackbar untuk DUA maksud: merayakan pembayaran DAN menyediakan
  /// jaring pengaman "Urungkan".
  ///
  /// Sengaja tidak memakai `MilestoneToast.show` dari sheet: toast itu
  /// memanggil `hideCurrentSnackBar()`, sehingga bila keduanya tampil, yang
  /// tergusur justru snackbar undo — jaring pengaman pengguna.
  void _showUndoSnackBar(BuildContext context, BillsState state) {
    final snapshot = state.lastUndo!;
    final l10n = context.l10n;
    final bloc = context.read<BillsBloc>();

    // `watchActiveBills` hanya mengalirkan tagihan AKTIF, jadi masih-tidaknya
    // bill di daftar hidup adalah penanda paling akurat bahwa tagihan belum
    // tamat — lebih tepercaya daripada menghitung ulang dari snapshot lama.
    final masihBerjalan = state.bills.any((b) => b.id == snapshot.billId);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            masihBerjalan ? l10n.milestoneCopy : l10n.billsPaidDone,
            style: AppTextStyles.body.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          // Cukup lama untuk sempat membaca DAN menekan "Urungkan".
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: l10n.billsUndo,
            textColor: Colors.white,
            onPressed: () => bloc.add(BillPaymentUndone(snapshot)),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final todayStart = startOfDay(DateTime.now());

    return BlocListener<BillsBloc, BillsState>(
      listenWhen: (prev, curr) => prev.lastUndo != curr.lastUndo,
      listener: (context, state) {
        // Undo yang sudah dipakai membuat bloc meng-clear `lastUndo` → tak ada
        // yang perlu ditawarkan lagi.
        if (state.lastUndo == null) return;
        _showUndoSnackBar(context, state);
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: bgColor,
              title: Text(
                context.l10n.billsTitle,
                style: AppTextStyles.h3.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: false,
            ),
            BlocBuilder<BillsBloc, BillsState>(
              builder: (context, state) {
                if (state.status == BillsStatus.initial ||
                    state.status == BillsStatus.loading) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }

                if (state.status == BillsStatus.failure) {
                  return SliverFillRemaining(
                    child: _ErrorBody(
                      message: context.l10n.billsError,
                      onRetry: () => context.read<BillsBloc>().add(
                        const BillsSubscribed(),
                      ),
                    ),
                  );
                }

                final bills = sortBillsForDisplay(state.bills, todayStart);

                if (bills.isEmpty) {
                  return SliverFillRemaining(child: _EmptyBody(isDark: isDark));
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: bills.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, i) {
                      final bill = bills[i];
                      // Tagihan yang sudah tamat tidak bisa ditandai lunas
                      // lagi — baris dibiarkan non-interaktif.
                      final canMarkPaid = bill.status != BillStatus.completed;
                      return BillItem(
                        bill: bill,
                        todayStart: todayStart,
                        onTap: canMarkPaid
                            ? () => _openMarkPaidSheet(bill)
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddSheet,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: Text(
            context.l10n.billsAdd,
            style: AppTextStyles.label.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ── Error state ──────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: AppTextStyles.body.copyWith(color: mutedColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: mutedColor),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.billsEmpty,
              style: AppTextStyles.body.copyWith(color: mutedColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
