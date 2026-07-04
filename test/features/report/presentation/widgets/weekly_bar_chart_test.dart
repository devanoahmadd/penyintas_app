import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/report/domain/entities/report_entity.dart';
import 'package:penyintas_app/features/report/presentation/widgets/weekly_bar_chart.dart';

void main() {
  const data = [
    WeeklySpendEntity(weekNumber: 1, totalSpent: 150000),
    WeeklySpendEntity(weekNumber: 2, totalSpent: 80000),
  ];

  testWidgets('bar chart punya tooltip aktif berformat Rupiah',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: WeeklyBarChart(weeklyData: data)),
    ));
    final chart = tester.widget<BarChart>(find.byType(BarChart));
    final touch = chart.data.barTouchData;
    expect(touch.enabled, isTrue,
        reason: 'barTouchData harus enabled untuk tooltip (#98)');

    final group = chart.data.barGroups.first;
    final item = touch.touchTooltipData
        .getTooltipItem(group, 0, group.barRods.first, 0);
    expect(item, isNotNull);
    expect(item!.text, formatRupiah(150000));
  });
}
