import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/features/budget/presentation/bloc/budget_settings_bloc.dart';
import 'package:penyintas_app/features/budget/presentation/pages/budget_edit_settings_page.dart';

class _MockBudgetSettingsBloc
    extends MockBloc<BudgetSettingsEvent, BudgetSettingsState>
    implements BudgetSettingsBloc {}

void main() {
  group('canSaveBudget (#251 A1b)', () {
    test('income 0 → tidak bisa simpan walau ada perubahan', () {
      expect(canSaveBudget(income: 0, hasChanges: true), false);
    });
    test('income negatif → tidak bisa simpan', () {
      expect(canSaveBudget(income: -5, hasChanges: true), false);
    });
    test('income > 0 tanpa perubahan → tidak bisa simpan', () {
      expect(canSaveBudget(income: 1500000, hasChanges: false), false);
    });
    test('income > 0 + ada perubahan → bisa simpan', () {
      expect(canSaveBudget(income: 1500000, hasChanges: true), true);
    });
  });

  group('budget-edit income helper (#251 A1b)', () {
    testWidgets('income kosong → helper error muncul; terisi → hilang',
        (tester) async {
      final bloc = _MockBudgetSettingsBloc();
      whenListen(
        bloc,
        const Stream<BudgetSettingsState>.empty(),
        initialState: const BudgetSettingsLoading(),
      );

      await tester.pumpWidget(MaterialApp(
        home: BlocProvider<BudgetSettingsBloc>.value(
          value: bloc,
          child: const BudgetEditSettingsPage(),
        ),
      ));
      await tester.pump();

      expect(find.text('Penghasilan harus diisi dulu, ya.'), findsOneWidget);

      // Isi income → helper hilang (field income = TextField pertama).
      await tester.enterText(find.byType(TextField).first, '1500000');
      await tester.pump();
      expect(find.text('Penghasilan harus diisi dulu, ya.'), findsNothing);
    });
  });
}
