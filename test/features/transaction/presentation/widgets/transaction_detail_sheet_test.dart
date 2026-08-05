import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/transaction_list_bloc.dart';
import 'package:penyintas_app/features/transaction/presentation/widgets/transaction_detail_sheet.dart';

/// Konsekuensi yang DITERIMA SADAR dari C1 (spec §T3).
///
/// Sesudah C1, mengganti kategori transaksi ke "Kebutuhan Tetap" tidak lagi
/// menyalakan `isFixed`. Baris "Jenis" di sheet ini merender `isFixed`, jadi
/// sheet bisa menampilkan dua baris yang tampak bertentangan bagi pengguna:
///
///     Kategori : Kebutuhan Tetap
///     Jenis    : Variabel
///
/// Itu BENAR secara akuntansi — pengeluarannya memang belum dianggarkan di
/// muka. Test ini mengunci perilakunya supaya terdokumentasi dalam bentuk
/// yang tidak bisa membusuk. Pertanyaan "haruskah baris Jenis berhenti
/// merender konsep akuntansi" adalah perubahan UI tersendiri (roadmap §5).
class _MockTransactionListBloc
    extends MockBloc<TransactionListEvent, TransactionListState>
    implements TransactionListBloc {}

class _FakeL10nDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _FakeL10nDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) => SynchronousFuture(
    AppLocalizations(locale, const {
      'category_fixed': 'Kebutuhan Tetap',
      'tx_detail_type': 'Jenis',
      'tx_detail_type_variable': 'Variabel',
      'tx_detail_time': 'Waktu',
      'category_income': 'Pemasukan',
    }),
  );
  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

void main() {
  late _MockTransactionListBloc bloc;

  // Sheet ini memanggil `DateFormat(pola, languageCode)` dengan locale
  // eksplisit ('en'). Di aplikasi nyata data locale intl disiapkan oleh
  // `GlobalMaterialLocalizations.delegate` (app.dart:89); harness ini tidak
  // memakainya, jadi datanya disiapkan langsung di sini.
  setUpAll(initializeDateFormatting);

  setUp(() {
    bloc = _MockTransactionListBloc();
    // `TransactionListState` adalah sealed class abstrak — pakai varian
    // konkretnya. `TransactionListLoading` tak punya field wajib, jadi ia
    // state paling murah untuk harness ini.
    whenListen(
      bloc,
      const Stream<TransactionListState>.empty(),
      initialState: const TransactionListLoading(),
    );
  });

  Widget harness(TransactionEntity tx) => MaterialApp(
    localizationsDelegates: const [_FakeL10nDelegate()],
    home: BlocProvider<TransactionListBloc>.value(
      value: bloc,
      child: Scaffold(body: TransactionDetailSheet(transaction: tx)),
    ),
  );

  testWidgets(
    '(e) category="fixed" + isFixed=false → baris Jenis berbunyi "Variabel"',
    (tester) async {
      final tx = TransactionEntity(
        id: 'tx-1',
        amount: 150000,
        category: 'fixed',
        type: TransactionType.expense,
        date: DateTime(2026, 8, 5, 10, 30),
        isFixed: false,
        isSynced: true,
        createdAt: DateTime(2026, 8, 5),
        updatedAt: DateTime(2026, 8, 5),
      );

      await tester.pumpWidget(harness(tx));
      await tester.pump();

      expect(find.text('Variabel'), findsOneWidget);
    },
  );
}
