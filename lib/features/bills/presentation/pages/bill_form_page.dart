import 'package:flutter/material.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';

/// Halaman tambah/ubah tagihan (spec §5).
///
/// [bill] null → mode tambah; selain itu mode ubah.
///
/// KERANGKA SEMENTARA (Task 6): isinya dipindahkan dari `AddEditBillSheet`
/// pada Task 7. Rute yang menunjuk ke sini sudah hidup dan sudah diuji.
class BillFormPage extends StatefulWidget {
  const BillFormPage({super.key, this.bill});

  final BillEntity? bill;

  @override
  State<BillFormPage> createState() => _BillFormPageState();
}

class _BillFormPageState extends State<BillFormPage> {
  bool get _isEdit => widget.bill != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        title: Text(
          _isEdit ? l10n.billsFormEditTitle : l10n.billsFormAddTitle,
          style: AppTextStyles.h3.copyWith(
            color: isDark ? AppColors.textDark : AppColors.textLight,
          ),
        ),
      ),
      body: const SizedBox.shrink(),
    );
  }
}
