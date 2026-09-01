import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/presentation/bloc/bills_bloc.dart';
import 'package:penyintas_app/features/bills/presentation/widgets/mark_bill_paid_sheet.dart';
import 'package:penyintas_app/widgets/common/milestone_toast.dart';

class MockBillsBloc extends MockBloc<BillsEvent, BillsState>
    implements BillsBloc {}

// Delegate sinkron — rootBundle async bentrok dengan fakeAsync widget test.
class _SyncL10nDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _SyncL10nDelegate(this._l10n);
  final AppLocalizations _l10n;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async => _l10n;

  @override
  bool shouldReload(covariant _SyncL10nDelegate old) => true;
}

void main() {
  late AppLocalizations l10n;
  late MockBillsBloc bloc;
  late StreamController<BillsState> stateController;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
    // BillsEvent sealed — pakai event konkret sebagai fallback.
    registerFallbackValue(const BillsSubscribed());
  });

  setUp(() {
    bloc = MockBillsBloc();
    // Broadcast: `close()` pada controller single-subscription yang tak pernah
    // di-listen tidak pernah selesai → tear-down menggantung.
    stateController = StreamController<BillsState>.broadcast();
    whenListen(
      bloc,
      stateController.stream,
      initialState: const BillsState(status: BillsStatus.success),
    );
  });

  tearDown(() {
    stateController.close();
  });

  final createdAt = DateTime(2026, 1, 5);

  /// Tagihan bulanan berjalan (cicilan 3 dari 12) — setelah dibayar sekali
  /// masih `active`, jadi milestone WAJIB muncul.
  BillEntity billBerjalan({
    int estimatedAmount = 750000,
    bool isFixedNeed = false,
    String category = 'internet',
    Recurrence recurrence = Recurrence.monthly,
    DateTime? dueDate,
  }) => BillEntity(
    id: 7,
    cloudId: 'cloud-7',
    name: 'Wifi Indihome',
    estimatedAmount: estimatedAmount,
    category: category,
    isFixedNeed: isFixedNeed,
    dueDate: dueDate ?? DateTime(2026, 8, 10),
    recurrence: recurrence,
    installmentTotal: 12,
    installmentsPaid: 3,
    dueDayOfMonth: 10,
    reminderEnabled: true,
    status: BillStatus.active,
    createdAt: createdAt,
    updatedAt: createdAt,
  );

  /// Tagihan sekali-jalan — setelah dibayar langsung `completed`, jadi
  /// milestone TIDAK boleh muncul.
  BillEntity billSekaliJalan() => BillEntity(
    id: 9,
    name: 'Servis Motor',
    estimatedAmount: 200000,
    category: 'transport',
    isFixedNeed: false,
    dueDate: DateTime(2026, 8, 10),
    recurrence: Recurrence.none,
    installmentsPaid: 0,
    reminderEnabled: true,
    status: BillStatus.active,
    createdAt: createdAt,
    updatedAt: createdAt,
  );

  Widget harness({
    required BillEntity bill,
    ThemeData? theme,
    int? fixedExpenses,
  }) => MaterialApp(
    locale: const Locale('id'),
    supportedLocales: const [Locale('id'), Locale('en')],
    localizationsDelegates: [
      _SyncL10nDelegate(l10n),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: theme,
    home: Scaffold(
      body: Builder(
        builder: (ctx) => Center(
          child: TextButton(
            onPressed: () => Navigator.of(ctx).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  body: BlocProvider<BillsBloc>.value(
                    value: bloc,
                    child: MarkBillPaidSheet(
                      bill: bill,
                      fixedExpenses: fixedExpenses,
                    ),
                  ),
                ),
              ),
            ),
            child: const Text('buka'),
          ),
        ),
      ),
    ),
  );

  Future<void> pumpSheet(
    WidgetTester tester, {
    required BillEntity bill,
    ThemeData? theme,
    // Default anggaran "sehat" — pemanggil lama tidak peduli M1. Nilai > 0
    // hanya melepas paruh anggaran: untuk tagihan BULANAN prefill jadi
    // `bill.isFixedNeed`, tapi tagihan non-bulanan tetap terkunci OFF berapa
    // pun nilainya.
    int? fixedExpenses = 500000,
  }) async {
    // Layar tinggi supaya sheet muat tanpa banyak scroll.
    tester.view.physicalSize = const Size(600, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      harness(bill: bill, theme: theme, fixedExpenses: fixedExpenses),
    );
    // Delegate l10n resolve di frame berikutnya — tanpa pump ekstra body
    // MaterialApp belum terbangun sama sekali.
    await tester.pumpAndSettle();
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  /// Tekan tombol konfirmasi. SENGAJA tanpa `pumpAndSettle`: saat submit valid,
  /// tombol berganti jadi CircularProgressIndicator yang berputar selamanya.
  Future<void> tapSubmit(WidgetTester tester) async {
    final finder = find.byKey(const ValueKey('bill_paid_submit'));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  BillsEvent captureLastEvent(WidgetTester tester) {
    final captured = verify(() => bloc.add(captureAny())).captured;
    return captured.last as BillsEvent;
  }

  BillMarkedPaid captureMarkedPaid(WidgetTester tester) {
    final event = captureLastEvent(tester);
    expect(event, isA<BillMarkedPaid>());
    return event as BillMarkedPaid;
  }

  String fieldText(WidgetTester tester, String key) =>
      tester.widget<TextField>(find.byKey(ValueKey(key))).controller!.text;

  bool switchValue(WidgetTester tester, String key) =>
      tester.widget<Switch>(find.byKey(ValueKey(key))).value;

  DateTime hariIni() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Tekan tombol OK pada `showDatePicker` yang sedang terbuka.
  /// Label diambil dari MaterialLocalizations agar bebas dari bahasa aktif.
  Future<void> confirmDatePicker(WidgetTester tester) async {
    final ctx = tester.element(find.byType(DatePickerDialog));
    final okLabel = MaterialLocalizations.of(ctx).okButtonLabel;
    await tester.tap(find.widgetWithText(TextButton, okLabel));
    await tester.pumpAndSettle();
  }

  /// Pilih [date] sebagai tanggal bayar lewat mode INPUT TEKS pada
  /// `showDatePicker` — bukan navigasi grid kalender. Navigasi grid rawan
  /// lintas bulan (tombol "bulan sebelumnya" perlu ditekan berkali-kali kalau
  /// [date] beda bulan dari `initialDate`); mode input bebas dari itu karena
  /// tanggalnya diketik langsung, diformat via `MaterialLocalizations` yang
  /// sama supaya cocok dengan parser tanggal locale aktif.
  Future<void> pilihTanggal(WidgetTester tester, DateTime date) async {
    await tapKey(tester, 'bill_paid_date');
    final ctx = tester.element(find.byType(DatePickerDialog));
    final localizations = MaterialLocalizations.of(ctx);
    await tester.tap(find.byTooltip(localizations.inputDateModeButtonLabel));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField),
      localizations.formatCompactDate(date),
    );
    await tester.pumpAndSettle();
    await confirmDatePicker(tester);
  }

  // ── Fixture selisih tanggal (group "baris selisih tanggal") ──────────────
  //
  // `_paidDate` DEFAULT selalu hari ini (lihat `initState` sheet) dan tak
  // bisa dimajukan ke masa depan — jadi bill dengan dueDate di MASA DEPAN
  // menghasilkan selisih POSITIF ("lebih awal") secara otomatis lewat
  // default, sedangkan dueDate di MASA LALU menghasilkan selisih NEGATIF
  // ("terlambat"). Beberapa fixture sengaja diberi jam non-tengah-malam
  // (23:00) pada dueDate-nya — lihat catatan di masing-masing.

  /// Jatuh tempo persis hari ini (tengah malam) → bayar (default) TEPAT pada
  /// jatuh tempo, selisih 0.
  final billJatuhTempoHariIni = billBerjalan(dueDate: hariIni());

  /// Jatuh tempo 3 hari lagi → bayar (default: hari ini) 3 hari LEBIH AWAL.
  final billJatuhTempo3HariLagi = billBerjalan(
    dueDate: hariIni().add(const Duration(days: 3)),
  );

  /// Jatuh tempo 3 hari lalu (tengah malam, tanpa jam) → dipakai KHUSUS test
  /// "mengubah tanggal ke jatuh tempo menghilangkan barisnya": `_paidDate`
  /// tak bisa dimajukan ke masa depan, jadi skenario "pilih tanggal = dueDate
  /// via picker" cuma bisa diuji kalau dueDate-nya ada di masa lalu/hari ini
  /// — bukan `billJatuhTempo3HariLagi` yang dueDate-nya di luar jangkauan
  /// `lastDate` picker.
  final billJatuhTempo3HariLalu = billBerjalan(
    dueDate: hariIni().subtract(const Duration(days: 3)),
  );

  /// Jatuh tempo 2 hari lalu, jam 23:00 → bayar (default) 2 hari TERLAMBAT.
  /// Jam 23 SENGAJA bukan tengah malam: raw `difference` tanpa `startOfDay`
  /// menghitung -25 jam (bukan -48 jam) yang `inDays`-nya truncate ke -1,
  /// bukan -2 — kalau baris memakai kunci `billsPaidDateLate(1)` alih-alih
  /// `billsPaidDateLate(2)`, sabotase "hapus startOfDay" tertangkap di sini.
  final billJatuhTempo2HariLalu = billBerjalan(
    dueDate: hariIni()
        .subtract(const Duration(days: 2))
        .add(const Duration(hours: 23)),
  );

  /// Jatuh tempo hari ini, jam 23:00 → hanya beda JAM dari `_paidDate` (yang
  /// selalu tengah malam), BUKAN beda tanggal kalender. Baris TIDAK boleh
  /// muncul sama sekali.
  final billJatuhTempoHariIniJam23 = billBerjalan(
    dueDate: hariIni().add(const Duration(hours: 23)),
  );

  /// Jatuh tempo besok (tengah malam) → bayar (default) 1 hari LEBIH AWAL.
  /// Kasus tepi n==1 di sisi EARLY.
  final billJatuhTempo1HariLagi = billBerjalan(
    dueDate: hariIni().add(const Duration(days: 1)),
  );

  /// Jatuh tempo kemarin, jam 23:00 → bayar (default) 1 hari TERLAMBAT.
  /// Kasus tepi n==1 di sisi LATE, jam 23 dengan alasan sama seperti
  /// `billJatuhTempo2HariLalu` — di sini efeknya malah lebih tajam: raw
  /// `difference` cuma -1 jam, `inDays`-nya truncate ke 0, jadi baris HILANG
  /// TOTAL di bawah sabotase "hapus startOfDay" alih-alih salah kunci.
  final billJatuhTempo1HariLalu = billBerjalan(
    dueDate: hariIni()
        .subtract(const Duration(days: 1))
        .add(const Duration(hours: 23)),
  );

  // ── Progres cicilan di kartu ringkasan (redesign §4.3, 2026-09-01) ────────
  //
  // Frasa penuh "Cicilan ke-X dari Y" dipindah ke sini dari list item —
  // di list, 20 karakter itu tak pernah muat berdampingan dengan caption
  // tanggal (lihat bill_item_test.dart); di sini ruangnya cukup dan
  // konteksnya pas (pengguna sedang mau bayar, wajar ingin tahu ini
  // pembayaran keberapa).

  testWidgets('tagihan bertenor → kartu ringkasan menampilkan progres cicilan', (
    tester,
  ) async {
    // installmentTotal: 12, installmentsPaid: 3 → pembayaran BERIKUTNYA ke-4.
    await pumpSheet(tester, bill: billBerjalan());

    expect(
      find.text(l10n.billsInstallmentProgress(4, 12)),
      findsOneWidget,
      reason: 'Progres cicilan harus tampil persis seperti frasa l10n — '
          'dulu tak pernah dipakai di sheet ini sama sekali.',
    );
  });

  testWidgets(
    'tagihan tanpa tenor (sekali-jalan) → TIDAK ada progres cicilan',
    (tester) async {
      await pumpSheet(tester, bill: billSekaliJalan());

      expect(
        find.textContaining('Cicilan ke-'),
        findsNothing,
        reason: 'Tagihan tanpa installmentTotal tak punya progres untuk '
            'ditampilkan — memaksakan teksnya akan menyesatkan.',
      );
    },
  );

  // ── (a) Nominal default = estimasi, dan EDITABLE ──────────────────────────

  testWidgets('nominal default = estimatedAmount tagihan', (tester) async {
    await pumpSheet(tester, bill: billBerjalan(estimatedAmount: 750000));

    expect(
      fieldText(tester, 'bill_paid_amount'),
      '750000',
      reason: 'nominal aktual diprefill dari perkiraan tagihan',
    );
  });

  testWidgets(
    'nominal editable → payload memakai nilai yang diketik pengguna',
    (tester) async {
      await pumpSheet(tester, bill: billBerjalan(estimatedAmount: 750000));

      await tester.enterText(
        find.byKey(const ValueKey('bill_paid_amount')),
        '812500',
      );
      await tester.pump();

      await tapSubmit(tester);

      final event = captureMarkedPaid(tester);
      expect(
        event.actualAmount,
        812500,
        reason:
            'pengguna bisa bayar beda dari perkiraan — nominal harus editable',
      );
    },
  );

  // ── (b) Opt-out — TITIK ANTI-SABOTASE ─────────────────────────────────────

  testWidgets('toggle opt-out ON → BillMarkedPaid.optOutTransaction == true', (
    tester,
  ) async {
    await pumpSheet(tester, bill: billBerjalan());

    expect(
      switchValue(tester, 'bill_paid_optout'),
      isFalse,
      reason: 'default: transaksi tetap dibuat',
    );

    await tapKey(tester, 'bill_paid_optout');
    expect(switchValue(tester, 'bill_paid_optout'), isTrue);

    await tapSubmit(tester);

    final event = captureMarkedPaid(tester);
    expect(
      event.optOutTransaction,
      isTrue,
      reason:
          'opt-out ON WAJIB diteruskan ke BLoC — kalau tidak, transaksi ganda '
          'tercatat padahal pengguna sudah mencatat manual',
    );
  });

  testWidgets('opt-out OFF (default) → optOutTransaction == false', (
    tester,
  ) async {
    await pumpSheet(tester, bill: billBerjalan());
    await tapSubmit(tester);

    expect(captureMarkedPaid(tester).optOutTransaction, isFalse);
  });

  // ── (c) Payload lengkap ───────────────────────────────────────────────────

  testWidgets('konfirmasi emit BillMarkedPaid dengan payload yang benar', (
    tester,
  ) async {
    final bill = billBerjalan(estimatedAmount: 750000, isFixedNeed: true);
    await pumpSheet(tester, bill: bill);

    await tapSubmit(tester);

    final event = captureMarkedPaid(tester);
    expect(event.billId, bill.id);
    expect(event.actualAmount, 750000);
    expect(
      event.paidDate,
      hariIni(),
      reason: 'tanggal bayar default = hari ini (awal hari)',
    );
    expect(
      event.includeAsFixed,
      isTrue,
      reason:
          'toggle kebutuhan tetap diprefill ON: bulanan + ditandai + '
          'anggaran ada (coveredUpfront)',
    );
    expect(event.optOutTransaction, isFalse);
  });

  // ── Toggle kebutuhan tetap ────────────────────────────────────────────────

  testWidgets('toggle kebutuhan tetap diprefill ON saat bulanan + ditandai + '
      'anggaran ada', (tester) async {
    await pumpSheet(tester, bill: billBerjalan(isFixedNeed: true));
    expect(switchValue(tester, 'bill_paid_fixed'), isTrue);
  });

  testWidgets('toggle kebutuhan tetap bisa diubah → payload ikut berubah', (
    tester,
  ) async {
    // Tagihan yang toggle-nya BERHAK hidup: bulanan + ditandai + anggaran ada.
    // Arahnya ON→OFF — opt-out sadar, perilaku yang gerbang M1 lindungi.
    await pumpSheet(
      tester,
      bill: billBerjalan(isFixedNeed: true),
      fixedExpenses: 500000,
    );

    expect(switchValue(tester, 'bill_paid_fixed'), isTrue);
    await tapKey(tester, 'bill_paid_fixed');
    expect(switchValue(tester, 'bill_paid_fixed'), isFalse);

    await tapSubmit(tester);

    expect(captureMarkedPaid(tester).includeAsFixed, isFalse);
  });

  // ── Mitigasi M1: prefill sadar-anggaran + hint ────────────────────────────
  //
  // Kalau kebutuhan tetap di anggaran masih 0, tak ada potongan di muka yang
  // menaungi tagihan ini. Menandainya "kebutuhan tetap" akan membuat
  // transaksinya dikecualikan dari akuntansi pengeluaran — uangnya lenyap dari
  // saldo tanpa pernah tercatat di mana pun.

  group('M1 prefill (§4.2) + hint (§4.3)', () {
    Switch fixedSwitch(WidgetTester t) =>
        t.widget<Switch>(find.byKey(const ValueKey('bill_paid_fixed')));
    final hint = find.byKey(const ValueKey('bill_paid_m1_hint'));

    testWidgets('fixedExpenses > 0 → prefill = flag, tanpa hint', (t) async {
      await pumpSheet(
        t,
        bill: billBerjalan(isFixedNeed: true),
        fixedExpenses: 500000,
      );
      expect(fixedSwitch(t).value, isTrue);
      expect(fixedSwitch(t).onChanged, isNotNull);
      expect(hint, findsNothing);
    });

    testWidgets(
      'fixedExpenses == 0 + isFixedNeed → prefill DIPAKSA false + hint',
      (t) async {
        await pumpSheet(
          t,
          bill: billBerjalan(isFixedNeed: true),
          fixedExpenses: 0,
        );
        expect(fixedSwitch(t).value, isFalse);
        expect(fixedSwitch(t).onChanged, isNotNull);
        expect(hint, findsOneWidget);
        expect(
          find.textContaining('Kebutuhan tetapmu masih kosong'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'fixedExpenses == null (fetch gagal) → FAIL-OPEN ke flag, tanpa hint',
      (t) async {
        await pumpSheet(
          t,
          bill: billBerjalan(isFixedNeed: true),
          fixedExpenses: null,
        );
        expect(fixedSwitch(t).value, isTrue);
        expect(hint, findsNothing);
      },
    );

    testWidgets(
      'monthly tanpa flag → prefill false, toggle TERKUNCI + hint "belum ditandai"',
      (t) async {
        await pumpSheet(
          t,
          bill: billBerjalan(isFixedNeed: false),
          fixedExpenses: 0,
        );
        expect(fixedSwitch(t).value, isFalse);
        expect(fixedSwitch(t).onChanged, isNull);
        expect(
          find.textContaining('belum ditandai kebutuhan tetap'),
          findsOneWidget,
        );
        // Hint M1 tetap TIDAK muncul — alasannya bentuk/flag, bukan anggaran.
        expect(hint, findsNothing);
      },
    );
  });

  group('Toggle terkunci untuk tagihan tak terwakili (spec §5.1)', () {
    Switch fixedSwitch(WidgetTester t) =>
        t.widget<Switch>(find.byKey(const ValueKey('bill_paid_fixed')));
    final hintM1 = find.byKey(const ValueKey('bill_paid_m1_hint'));

    testWidgets('(a) yearly + isFixedNeed + fe>0 → OFF dan TERKUNCI', (
      t,
    ) async {
      await pumpSheet(
        t,
        bill: billBerjalan(isFixedNeed: true, recurrence: Recurrence.yearly),
        fixedExpenses: 500000,
      );
      expect(fixedSwitch(t).value, isFalse);
      expect(fixedSwitch(t).onChanged, isNull);
    });

    testWidgets('(b) yearly → hint bentuk tagihan, hint normal hilang', (
      t,
    ) async {
      await pumpSheet(
        t,
        bill: billBerjalan(isFixedNeed: true, recurrence: Recurrence.yearly),
        fixedExpenses: 500000,
      );
      expect(find.textContaining('dihitung per bulan'), findsOneWidget);
      expect(
        find.textContaining('bukan potong jatah harian kamu'),
        findsNothing,
      );
    });

    testWidgets('(d) fe == null (fetch gagal) + yearly → tetap OFF', (t) async {
      await pumpSheet(
        t,
        bill: billBerjalan(isFixedNeed: true, recurrence: Recurrence.yearly),
        fixedExpenses: null,
      );
      expect(fixedSwitch(t).value, isFalse);
      expect(fixedSwitch(t).onChanged, isNull);
    });

    testWidgets(
      '(f) tile terkunci: tak punya aksi tap, tap tak mengubah apa pun',
      (t) async {
        await pumpSheet(
          t,
          bill: billBerjalan(isFixedNeed: true, recurrence: Recurrence.yearly),
          fixedExpenses: 500000,
        );

        // PRASYARAT — jangan hapus meski terasa tumpang-tindih dengan (a).
        // Tanpa baris ini test lolos lewat jalan yang salah: pra-perbaikan
        // prefill masih ON, tap menjadikannya OFF, dan assertion sesudah tap
        // ikut hijau padahal tile-nya masih bisa ditekan.
        expect(
          fixedSwitch(t).value,
          isFalse,
          reason: 'prefill harus sudah OFF',
        );

        // `verifyNever(() => bloc.add(any()))` SENGAJA tidak dipakai: tile ini
        // tak pernah menyentuh BLoC di state mana pun — ia hanya `setState` —
        // jadi assertion itu hampa di kedua arah. Yang membedakan tile terkunci
        // dari tile hidup adalah `onTap`.
        final tile = t.widget<InkWell>(
          find
              .descendant(
                of: find.byKey(const ValueKey('bill_paid_fixed_row')),
                matching: find.byType(InkWell),
              )
              .first,
        );
        expect(tile.onTap, isNull);

        await tapKey(t, 'bill_paid_fixed_row');
        expect(fixedSwitch(t).value, isFalse);
      },
    );

    testWidgets(
      '(g) yearly + isFixedNeed + fe==0 → hint terkunci, BUKAN hint M1',
      (t) async {
        await pumpSheet(
          t,
          bill: billBerjalan(isFixedNeed: true, recurrence: Recurrence.yearly),
          fixedExpenses: 0,
        );
        expect(find.textContaining('dihitung per bulan'), findsOneWidget);
        expect(hintM1, findsNothing);
      },
    );

    testWidgets('(i) yearly TANPA flag → alasan BENTUK menang atas alasan FLAG', (
      t,
    ) async {
      // Irisan yang jadi alasan adanya presedensi: kedua alasan kunci
      // berlaku sekaligus. Alasan BENTUK tak punya jalan keluar, alasan FLAG
      // punya — menawarkan yang bisa diperbaiki lebih dulu mengirim pengguna
      // menyalakan flag pada tagihan tahunan, yang tak menolongnya sama sekali.
      await pumpSheet(
        t,
        bill: billBerjalan(isFixedNeed: false, recurrence: Recurrence.yearly),
        fixedExpenses: 500000,
      );
      expect(find.textContaining('dihitung per bulan'), findsOneWidget);
      expect(find.textContaining('belum ditandai'), findsNothing);
    });
  });

  // ── Kategori read-only ────────────────────────────────────────────────────

  testWidgets('kategori tampil read-only — tidak ada pilihan kategori lain', (
    tester,
  ) async {
    await pumpSheet(tester, bill: billBerjalan(category: 'internet'));

    expect(find.text(l10n.categoryInternet), findsOneWidget);
    // Kategori bukan field editable di sheet ini.
    expect(find.text(l10n.categoryFood), findsNothing);
    expect(find.text(l10n.categoryTransport), findsNothing);
    expect(find.text(l10n.categoryShopping), findsNothing);
  });

  // ── Validasi ──────────────────────────────────────────────────────────────

  testWidgets('nominal kosong → tervalidasi, BillMarkedPaid TIDAK ter-emit', (
    tester,
  ) async {
    await pumpSheet(tester, bill: billBerjalan());

    await tester.enterText(find.byKey(const ValueKey('bill_paid_amount')), '');
    await tester.pump();

    await tapSubmit(tester);

    verifyNever(() => bloc.add(any(that: isA<BillMarkedPaid>())));
    expect(
      find.text(l10n.billsPaidErrorAmount),
      findsOneWidget,
      reason: 'pesan validasi nominal harus terlihat pengguna',
    );
  });

  // ── Umpan balik submit ────────────────────────────────────────────────────

  testWidgets('gagal → SnackBar tampil & tombol konfirmasi aktif lagi', (
    tester,
  ) async {
    await pumpSheet(tester, bill: billBerjalan());
    await tapSubmit(tester);

    // Kanal galat tulis (Task 1-3): `status` TIDAK menyentuh kegagalan aksi
    // lagi — sheet harus membaca `actionFailure`, bukan `status.failure`.
    stateController.add(
      const BillsState(
        status: BillsStatus.success,
        actionFailure: BillActionFailure(
          aksi: BillWriteAction.markPaid,
          failure: CacheFailure('db mati'),
          seq: 1,
          billId: 1,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(l10n.billsPaidFailed), findsOneWidget);
    expect(find.byType(MarkBillPaidSheet), findsOneWidget);
    // 'buka' milik rute DI BAWAH sheet — offstage selama sheet menindihnya
    // sebagai rute opaque, dan onstage SEKETIKA begitu pop dimulai. Tak
    // bergantung durasi transisi seperti `find.byType(MarkBillPaidSheet)`.
    expect(find.text('buka'), findsNothing);
    // Tombol WAJIB aktif lagi — kalau `_isSubmitting` tak di-reset, pengguna
    // terkunci di sheet tanpa bisa mencoba ulang.
    final submit = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('bill_paid_submit')),
    );
    expect(
      submit.onPressed,
      isNotNull,
      reason: 'setelah gagal, konfirmasi harus bisa ditekan ulang',
    );
  });

  testWidgets('gagal tandai lunas → snackbar tampil DAN sheet tidak menutup', (
    tester,
  ) async {
    await pumpSheet(tester, bill: billBerjalan());
    await tapSubmit(tester);

    stateController.add(
      const BillsState(
        status: BillsStatus.success,
        actionFailure: BillActionFailure(
          aksi: BillWriteAction.markPaid,
          failure: CacheFailure('db mati'),
          seq: 1,
          billId: 1,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(l10n.billsPaidFailed), findsOneWidget);
    expect(find.byType(MarkBillPaidSheet), findsOneWidget);
    // 'buka' milik rute DI BAWAH sheet — sheet TIDAK boleh ter-pop atas
    // kegagalan. Pegangan ini onstage SEKETIKA begitu pop dimulai, jadi
    // ia menangkap pop tanpa bergantung durasi transisi sama sekali.
    expect(find.text('buka'), findsNothing);
  });

  // Regresi layar-hitam (laporan device 2026-08-31): menandai lunas membuat
  // layar menghitam lalu aplikasi keluar sendiri. Sebabnya sama persis dengan
  // pop ganda di `BillFormPage` — sheet yang di-pop tetap hidup di pohon
  // sepanjang transisi, `BillsBloc` adalah lazySingleton yang dibagi dengan
  // halaman daftar, dan `BillsStatus.success` adalah status ISTIRAHAT daftar
  // (bisa datang berkali-kali), bukan sinyal sekali-jalan. Pop kedua membuang
  // halaman daftar, pop ketiga menembus akar → stack kosong → layar hitam →
  // activity selesai.
  testWidgets('sukses tandai lunas → emisi susulan TIDAK mem-pop dua kali', (
    tester,
  ) async {
    await pumpSheet(tester, bill: billBerjalan());
    await tapSubmit(tester);

    stateController.add(const BillsState(status: BillsStatus.success));
    await tester.pump(); // pop #1 dimulai, transisi BELUM selesai

    // Daftar berlangganan ulang saat rute kembali → loading lalu success lagi.
    stateController.add(const BillsState(status: BillsStatus.loading));
    await tester.pump();
    stateController.add(const BillsState(status: BillsStatus.success));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MarkBillPaidSheet), findsNothing);
    expect(
      find.text('buka'),
      findsOneWidget,
      reason:
          'pop kedua ikut membuang halaman di bawah sheet → stack navigasi '
          'terkuras sampai akar, layar menghitam, aplikasi keluar sendiri',
    );
  });

  testWidgets('sukses tandai lunas → sheet TETAP menutup', (tester) async {
    await pumpSheet(tester, bill: billBerjalan());
    await tapSubmit(tester);

    stateController.add(const BillsState(status: BillsStatus.success));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MarkBillPaidSheet), findsNothing);
    // Sheet MEMANG menutup di sini — 'buka' onstage lagi.
    expect(find.text('buka'), findsOneWidget);
  });

  testWidgets('sukses → sheet ditutup', (tester) async {
    await pumpSheet(tester, bill: billBerjalan());
    await tapSubmit(tester);

    stateController.add(const BillsState(status: BillsStatus.success));
    await tester.pump();
    // Loncat melewati transisi pop sekali frame — `pumpAndSettle` akan
    // menggantung selama indikator loading masih ikut ter-render.
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MarkBillPaidSheet), findsNothing);
    expect(find.text('buka'), findsOneWidget);
  });

  // ── Milestone dipindah ke halaman daftar (Task 5.4) ───────────────────────
  //
  // Sampai Task 5.3 sheet ini menampilkan `MilestoneToast` sendiri. Task 5.4
  // menyatukan perayaan + tawaran "Urungkan" jadi SATU snackbar milik
  // `BillsListPage`, karena `MilestoneToast.show` memanggil
  // `hideCurrentSnackBar()` — dua surface saling menggusur dan yang hilang
  // justru undo, jaring pengaman pengguna.
  //
  // Dua test lama ("MilestoneToast tampil" / "TANPA MilestoneToast") diganti
  // penjaga di bawah: sheet WAJIB diam. Pasangannya (isi & aksi snackbar) ada
  // di `bills_list_page_test.dart` grup "snackbar undo".

  testWidgets('sukses → sheet TIDAK menampilkan surface apa pun sendiri', (
    tester,
  ) async {
    await pumpSheet(tester, bill: billBerjalan());
    await tapSubmit(tester);

    stateController.add(const BillsState(status: BillsStatus.success));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.byType(MilestoneToast),
      findsNothing,
      reason: 'perayaan kini digabung ke snackbar undo di BillsListPage',
    );
    expect(find.text(l10n.milestoneCopy), findsNothing);
  });

  testWidgets('sukses & tagihan sekali jalan → sheet tetap diam', (
    tester,
  ) async {
    await pumpSheet(tester, bill: billSekaliJalan());
    await tapSubmit(tester);

    stateController.add(const BillsState(status: BillsStatus.success));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MilestoneToast), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  // ── Aksesibilitas & tema ──────────────────────────────────────────────────

  testWidgets('tombol konfirmasi & baris toggle memenuhi hit target 48dp', (
    tester,
  ) async {
    await pumpSheet(tester, bill: billBerjalan());

    final submitSize = tester.getSize(
      find.byKey(const ValueKey('bill_paid_submit')),
    );
    expect(submitSize.height, greaterThanOrEqualTo(48.0));

    final optOutRow = tester.getSize(
      find.byKey(const ValueKey('bill_paid_optout_row')),
    );
    expect(optOutRow.height, greaterThanOrEqualTo(48.0));

    final dateSize = tester.getSize(
      find.byKey(const ValueKey('bill_paid_date')),
    );
    expect(dateSize.height, greaterThanOrEqualTo(48.0));
  });

  testWidgets('dark mode render tanpa error', (tester) async {
    await pumpSheet(tester, bill: billBerjalan(), theme: ThemeData.dark());

    expect(tester.takeException(), isNull);
    expect(find.text(l10n.billsPaidTitle), findsOneWidget);
  });

  // ── (?) sheet penjelasan kebutuhan tetap (Task 15) ────────────────────────

  group('(?) kebutuhan tetap di sheet bayar', () {
    testWidgets('(?) di sheet bayar membuka sheet penjelasan yang SAMA', (
      tester,
    ) async {
      // Tagihan yang tile-nya TIDAK terkunci — mengikuti pola `kos` di
      // fixture bersama task ini: bulanan + ditandai kebutuhan tetap.
      await pumpSheet(tester, bill: billBerjalan(isFixedNeed: true));
      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.text(l10n.billsFixedHelpTitle), findsOneWidget);
      expect(find.text(l10n.billsFixedHelpLockedBody), findsOneWidget);
    });

    testWidgets('(?) tetap ada meski toggle TERKUNCI — penjelasan justru '
        'paling dibutuhkan di sana', (tester) async {
      // Tahunan + ditandai + anggaran ada → tile TERKUNCI (lihat grup
      // "Toggle terkunci untuk tagihan tak terwakili (spec §5.1)" di atas).
      await pumpSheet(
        tester,
        bill: billBerjalan(isFixedNeed: true, recurrence: Recurrence.yearly),
      );
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.text(l10n.billsFixedHelpLockedTitle), findsOneWidget);
    });
  });

  // ── Baris selisih tanggal bayar (Task 16) ─────────────────────────────────

  group('baris selisih tanggal', () {
    testWidgets('bayar tepat pada jatuh tempo → TIDAK ada baris sama sekali', (
      tester,
    ) async {
      await pumpSheet(tester, bill: billJatuhTempoHariIni);
      expect(find.byKey(const ValueKey('bill_paid_date_diff')), findsNothing);
    });

    testWidgets('bayar 3 hari lebih awal → baris "lebih awal"', (tester) async {
      await pumpSheet(tester, bill: billJatuhTempo3HariLagi);
      expect(find.text(l10n.billsPaidDateEarly(3)), findsOneWidget);
    });

    testWidgets('bayar 2 hari terlambat → baris "terlambat"', (tester) async {
      await pumpSheet(tester, bill: billJatuhTempo2HariLalu);
      expect(find.text(l10n.billsPaidDateLate(2)), findsOneWidget);
    });

    testWidgets('mengubah tanggal ke jatuh tempo MENGHILANGKAN barisnya', (
      tester,
    ) async {
      // `billJatuhTempo3HariLalu`, BUKAN `billJatuhTempo3HariLagi`: dueDate
      // yang terakhir ada di MASA DEPAN, sedangkan `_paidDate` tak pernah
      // bisa dimajukan melewati hari ini (`lastDate: startOfDay(now)` di
      // `_pickPaidDate`) — tak ada cara memilihnya lewat picker sungguhan.
      await pumpSheet(tester, bill: billJatuhTempo3HariLalu);
      expect(find.text(l10n.billsPaidDateLate(3)), findsOneWidget);
      await pilihTanggal(tester, billJatuhTempo3HariLalu.dueDate);
      expect(find.byKey(const ValueKey('bill_paid_date_diff')), findsNothing);
    });

    testWidgets('selisih dihitung dari AWAL HARI, bukan jam — '
        'beda jam dalam hari yang sama bukan selisih', (tester) async {
      // dueDate jam 23:00 hari ini; `_paidDate` (default) selalu tengah
      // malam hari ini juga — tanggal kalendernya SAMA, cuma jamnya beda.
      await pumpSheet(tester, bill: billJatuhTempoHariIniJam23);
      expect(find.byKey(const ValueKey('bill_paid_date_diff')), findsNothing);
    });
  });

  // ── [Audit T2] Bentuk tunggal — kasus paling umum, bukan kasus tepi ────
  //
  // Harness ini memuat locale `id`, tempat "1 hari" dan "{n} hari" tak beda
  // bentuk. Yang dikunci di sini adalah RANTAI widget → l10n, BUKAN
  // percabangan `n == 1` itu sendiri — percabangan itu sudah terjaga di level
  // dispatch oleh `bills_l10n_test.dart` (T5), yang memanggil
  // `AppLocalizations.billsPaidDateEarly/Late` langsung di locale EN, tempat
  // sisi jamak vs tunggal benar-benar beda string ("1 day" vs "1 days").
  testWidgets('bayar 1 hari lebih awal memakai kunci TUNGGAL', (tester) async {
    await pumpSheet(tester, bill: billJatuhTempo1HariLagi);
    expect(find.text(l10n.billsPaidDateEarly(1)), findsOneWidget);
    expect(
      l10n.billsPaidDateEarly(1),
      isNot(contains('{n}')),
      reason: 'kunci tunggal tak berplaceholder — kalau ada, salah kunci',
    );
  });

  testWidgets('bayar 1 hari terlambat memakai kunci TUNGGAL', (tester) async {
    await pumpSheet(tester, bill: billJatuhTempo1HariLalu);
    expect(find.text(l10n.billsPaidDateLate(1)), findsOneWidget);
  });

  testWidgets('perilaku lama tak berubah: tanggal bayar default hari ini, '
      'tak bisa maju', (tester) async {
    await pumpSheet(tester, bill: billBerjalan());
    expect(
      fieldText(tester, 'bill_paid_amount'),
      '750000',
      reason: 'nominal masih diprefill seperti sebelumnya',
    );
    await tapSubmit(tester);
    expect(
      captureMarkedPaid(tester).paidDate,
      hariIni(),
      reason:
          'tanggal bayar default tetap hari ini setelah baris selisih '
          'ditambahkan',
    );
  });
}
