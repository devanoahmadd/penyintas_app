import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/report/domain/entities/report_entity.dart';
import 'package:penyintas_app/features/report/presentation/pages/report_page.dart';

ReportEntity _makeReport({
  int totalSpent = 0,
  int totalIncome = 0,
  double? comparedToPreviousMonth,
  bool hasPreviousMonthData = false,
}) => ReportEntity(
  month: DateTime(2025, 11),
  totalSpent: totalSpent,
  totalIncome: totalIncome,
  netBalance: totalIncome - totalSpent,
  categoryBreakdown: const {},
  dailyAverageSpend: 0,
  topCategory: null,
  weeklyBreakdown: const [],
  comparedToPreviousMonth: comparedToPreviousMonth,
  hasPreviousMonthData: hasPreviousMonthData,
);

void main() {
  group('comparedLabelText #99', () {
    test('dua bulan sama-sama kosong → "Belum ada catatan bulan ini"', () {
      expect(comparedLabelText(_makeReport()), 'Belum ada catatan bulan ini');
    });

    test('bulan pertama sejati (bulan ini ada catatan) → "Bulan pertama"', () {
      expect(
        comparedLabelText(_makeReport(totalSpent: 50000)),
        'Bulan pertama',
      );
    });

    test(
      'bulan lalu ada data tapi 0 pengeluaran → "Bulan lalu tanpa pengeluaran"',
      () {
        expect(
          comparedLabelText(
            _makeReport(totalSpent: 50000, hasPreviousMonthData: true),
          ),
          'Bulan lalu tanpa pengeluaran',
        );
      },
    );

    test('pengeluaran persis sama → "Sama dengan bulan lalu"', () {
      expect(
        comparedLabelText(
          _makeReport(
            totalSpent: 100000,
            comparedToPreviousMonth: 0.0,
            hasPreviousMonthData: true,
          ),
        ),
        'Sama dengan bulan lalu',
      );
    });

    test('naik/turun → persentase bertanda', () {
      expect(
        comparedLabelText(
          _makeReport(
            totalSpent: 150000,
            comparedToPreviousMonth: 0.5,
            hasPreviousMonthData: true,
          ),
        ),
        '+50.0% dari bulan lalu',
      );
      expect(
        comparedLabelText(
          _makeReport(
            totalSpent: 50000,
            comparedToPreviousMonth: -0.5,
            hasPreviousMonthData: true,
          ),
        ),
        '-50.0% dari bulan lalu',
      );
    });
  });
}
