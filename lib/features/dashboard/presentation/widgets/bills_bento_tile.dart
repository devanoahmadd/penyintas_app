import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/presentation/bloc/bills_bloc.dart';
import 'package:penyintas_app/features/bills/presentation/widgets/bill_status_chip.dart';
import 'package:penyintas_app/features/dashboard/presentation/widgets/bento_feat_tile.dart';

/// Tile bento "Tagihan" di dashboard (Task 7.1).
///
/// Tap → navigasi ke halaman daftar tagihan (`/bills`) lewat `context.push`
/// (bukan `go`) supaya tombol back kembali ke dashboard.
///
/// Sub & badge SELALU data nyata dari `BillsBloc` — tidak pernah string
/// fiktif:
/// - Ada tagihan aktif → sub = "{nama tagihan terdekat} · {relatif jatuh
///   tempo}", badge = jumlah tagihan aktif ("N akan datang").
/// - Tidak ada tagihan (atau state belum `success`: initial/loading/failure)
///   → sub = copy kosong yang jujur, badge = '' (tidak dirender —
///   lihat `BentoFeatTile`).
class BillsBentoTile extends StatelessWidget {
  const BillsBentoTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<BillsBloc, BillsState>(
      builder: (context, state) {
        // Non-success (initial/loading/failure) → jangan tampilkan angka
        // palsu; perlakukan seolah belum ada data.
        final bills = state.status == BillsStatus.success
            ? state.bills
            : const <BillEntity>[];

        // Tagihan terdekat = dueDate paling awal. Bill terlambat otomatis
        // menang (dueDate-nya paling kecil) — itu memang yang paling
        // mendesak.
        BillEntity? nearest;
        for (final bill in bills) {
          if (nearest == null || bill.dueDate.isBefore(nearest.dueDate)) {
            nearest = bill;
          }
        }

        final String sub;
        final String badge;
        if (nearest == null) {
          sub = l10n.dashboardBentoBillsSub;
          badge = '';
        } else {
          final todayStart = startOfDay(DateTime.now());
          final daysUntil = nearest.dueDate.difference(todayStart).inDays;
          final String relative;
          if (daysUntil < 0) {
            relative = l10n.billsStatusOverdue;
          } else if (daysUntil == 0) {
            relative = l10n.billsDueToday;
          } else {
            relative = l10n.daysLeft(daysUntil);
          }
          sub = '${nearest.name} · $relative';
          badge = l10n.billsUpcomingCount(bills.length);
        }

        return BentoFeatTile(
          bg: AppColors.primary,
          icon: Icons.receipt_long_outlined,
          label: l10n.dashboardBentoBillsLabel,
          sub: sub,
          badge: badge,
          onTap: () => context.push('/bills'),
        );
      },
    );
  }
}
