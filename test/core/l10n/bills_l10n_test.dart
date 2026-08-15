import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';

/// Jaring parity KHUSUS fitur Tagihan (F8).
///
/// `translations_parity_test.dart` hanya menjamin id.json & en.json punya set
/// key IDENTIK — key yang hilang dari KEDUANYA lolos diam-diam (`_t()` fallback
/// ke nama key, UI menampilkan "bills_undo" mentah). Daftar EKSPLISIT di bawah
/// menutup celah itu: kalau seseorang menghapus key dari dua file sekaligus,
/// test ini tetap gagal.
///
/// Sengaja baca file lewat `dart:io` (bukan `rootBundle`) supaya yang diuji
/// adalah file sumber di repo, bukan salinan asset bundle hasil build.
///
/// `billsKeys` sendiri diuji DUA ARAH: test di bawah membuktikan setiap
/// entrinya ada di JSON (arah maju), dan test "arah balik" di paling bawah
/// membuktikan setiap key `bills_` di id.json terdaftar di `billsKeys` —
/// tanpa arah balik, key baru yang lupa didaftarkan lolos diam-diam
/// (persis mekanisme yang melahirkan empat lubang [Audit S4] di gelombang
/// perbaikan 2026-08-08).
void main() {
  late Map<String, dynamic> id;
  late Map<String, dynamic> en;
  late AppLocalizations l10nEn;

  setUpAll(() {
    id =
        json.decode(File('assets/translations/id.json').readAsStringSync())
            as Map<String, dynamic>;
    en =
        json.decode(File('assets/translations/en.json').readAsStringSync())
            as Map<String, dynamic>;
    // Dibangun langsung dari Map yang sudah di-load — tanpa rootBundle,
    // tanpa TestWidgetsFlutterBinding — mengikuti preseden
    // test/core/utils/category_metadata_test.dart. Memakai `en` yang sama
    // dengan yang diuji test JSON di atas supaya method Dart diuji terhadap
    // isi produksi yang sesungguhnya, bukan fixture tangan.
    l10nEn = AppLocalizations(const Locale('en'), Map<String, String>.from(en));
  });

  /// Semua key berawalan `bills_` yang dipakai lapisan presentasi Tagihan
  /// (halaman daftar, sheet tambah/ubah, sheet tandai-lunas, snackbar undo).
  const billsKeys = [
    // Halaman daftar
    'bills_title',
    'bills_empty',
    'bills_add',
    'bills_error',
    // Pintu menu (⋮) tiap baris — Task 13
    'bills_actions_menu_a11y',
    // Chip status & badge cicilan
    'bills_status_overdue',
    'bills_status_upcoming',
    'bills_status_done',
    'bills_installment_progress',
    // Sheet tambah/ubah
    'bills_form_add_title',
    'bills_form_edit_title',
    'bills_form_name_label',
    'bills_form_name_hint',
    'bills_form_amount_label',
    'bills_form_amount_hint',
    'bills_form_amount_done',
    'bills_form_category_label',
    'bills_form_due_date_label',
    'bills_form_due_date_hint',
    'bills_form_recurrence_label',
    'bills_recurrence_none',
    'bills_recurrence_monthly',
    'bills_recurrence_yearly',
    'bills_form_tenor_label',
    'bills_tenor_unlimited',
    'bills_tenor_count',
    'bills_tenor_end_date',
    'bills_form_tenor_count_label',
    'bills_form_tenor_count_hint',
    'bills_form_tenor_end_date_label',
    'bills_form_tenor_end_date_hint',
    'bills_form_fixed_label',
    'bills_form_fixed_hint',
    'bills_form_reminder_label',
    'bills_reminder_default',
    'bills_reminder_d3',
    'bills_reminder_d1',
    'bills_reminder_day_of',
    'bills_reminder_off',
    'bills_form_notes_label',
    'bills_form_notes_optional',
    'bills_form_notes_hint',
    'bills_form_required',
    'bills_form_error_name',
    'bills_form_error_amount',
    'bills_form_error_category',
    'bills_form_error_due_date',
    'bills_form_error_tenor_count',
    'bills_form_error_tenor_end_date',
    'bills_form_save_failed',
    // Sheet tandai lunas
    'bills_paid_title',
    'bills_paid_amount_label',
    'bills_paid_amount_note',
    'bills_paid_date_label',
    'bills_paid_optout_label',
    'bills_paid_optout_hint',
    'bills_paid_submit',
    'bills_paid_error_amount',
    'bills_paid_failed',
    // Snackbar hasil pembayaran + undo (Task 5.4)
    'bills_paid_done',
    'bills_undo',
    // Tile Tagihan di dashboard (Task 7.1)
    'bills_due_today',
    'bills_upcoming_count',
    // ── Gelombang perbaikan 2026-08-08 (spec Rev 3 §6.2) ──
    // Catatan bersyarat di form
    'bills_form_amount_note',
    'bills_form_category_note',
    // Kotak gagal-muat di grid kategori (Task 8). Sengaja terpisah dari
    // `bills_error`: yang gagal kategorinya, bukan tagihannya.
    'bills_form_category_load_failed',
    'bills_form_due_date_monthly_note',
    'bills_form_due_date_yearly_note',
    // Catatan chip tenor
    'bills_tenor_unlimited_note',
    'bills_tenor_count_note',
    'bills_tenor_end_date_note',
    // Chip pengingat
    'bills_reminder_n_days_before',
    'bills_reminder_custom_label',
    // Baris selisih tanggal di sheet bayar
    'bills_paid_date_early',
    'bills_paid_date_late',
    'bills_paid_date_early_one',
    'bills_paid_date_late_one',
    // Dialog buang-perubahan (D15)
    'bills_form_discard_title',
    'bills_form_discard_body',
    'bills_form_discard_confirm',
    'bills_form_discard_cancel',
    // Sheet bantuan "kebutuhan tetap"
    'bills_fixed_help_title',
    'bills_fixed_help_body_1',
    'bills_fixed_help_body_2',
    'bills_fixed_help_locked_title',
    'bills_fixed_help_locked_body',
    'bills_fixed_help_a11y',
    // ── Lubang lama, ditemukan audit 2026-08-08 [Audit S4] ──
    // Keempatnya SUDAH ada di kedua JSON dan sudah punya getter; yang hilang
    // hanya penjaganya. Menghapusnya dari kedua berkas hari ini tidak
    // menggagalkan satu test pun — persis celah yang daftar ini ada untuk
    // menutupnya.
    'bills_form_fixed_hint_non_monthly',
    'bills_paid_fixed_empty_hint',
    'bills_paid_fixed_non_monthly_hint',
    'bills_paid_fixed_not_flagged_hint',
  ];

  /// Key TANPA prefiks `bills_` yang tetap dipakai layar Tagihan — kalau
  /// hilang, snackbar/aksi Tagihan ikut rusak.
  const sharedKeys = ['milestone_copy', 'retry'];

  test('id.json memuat semua key Tagihan', () {
    for (final k in [...billsKeys, ...sharedKeys]) {
      expect(id.containsKey(k), isTrue, reason: 'id.json kekurangan "$k"');
    }
  });

  test('en.json memuat semua key Tagihan', () {
    for (final k in [...billsKeys, ...sharedKeys]) {
      expect(en.containsKey(k), isTrue, reason: 'en.json kekurangan "$k"');
    }
  });

  test('nilai key Tagihan tidak kosong di kedua bahasa', () {
    for (final k in [...billsKeys, ...sharedKeys]) {
      expect(
        (id[k] as String?)?.trim(),
        isNotEmpty,
        reason: 'nilai "$k" kosong di id.json',
      );
      expect(
        (en[k] as String?)?.trim(),
        isNotEmpty,
        reason: 'nilai "$k" kosong di en.json',
      );
    }
  });

  test('placeholder key Tagihan sama persis di ID & EN', () {
    // Placeholder yang beda antar bahasa = string tampil mentah di UI.
    const withPlaceholder = {
      'bills_installment_progress': ['{x}', '{n}'],
      'bills_paid_amount_note': ['{amount}'],
      'bills_upcoming_count': ['{n}'],
      'bills_form_due_date_monthly_note': ['{day}'],
      'bills_form_due_date_yearly_note': ['{day}', '{month}'],
      'bills_reminder_n_days_before': ['{n}'],
      'bills_paid_date_early': ['{n}'],
      'bills_paid_date_late': ['{n}'],
    };
    withPlaceholder.forEach((key, tokens) {
      for (final token in tokens) {
        expect(
          id[key] as String,
          contains(token),
          reason: 'id.json "$key" kehilangan placeholder $token',
        );
        expect(
          en[key] as String,
          contains(token),
          reason: 'en.json "$key" kehilangan placeholder $token',
        );
      }
    });
  });

  test('kunci selisih tanggal tunggal tidak memakai bentuk jamak', () {
    for (final k in ['bills_paid_date_early_one', 'bills_paid_date_late_one']) {
      expect(
        en[k] as String,
        isNot(contains('days')),
        reason: '"$k" adalah bentuk TUNGGAL — "1 days" salah',
      );
      expect(en[k] as String, contains('1 day'));
    }
  });

  test('catatan tanggal bulanan EN bebas sufiks ordinal mati', () {
    // Bukan `contains('th')` polos — kata "month" sendiri mengandung "th",
    // jadi assertion sesempit itu merah bahkan untuk nilai yang BENAR.
    // Yang diuji adalah sufiks ordinal menempel ke placeholder ("{day}th"),
    // sesuai cacat yang dijelaskan di reason di bawah.
    expect(
      en['bills_form_due_date_monthly_note'] as String,
      isNot(contains('{day}th')),
      reason: '"The {day}th" menghasilkan "The 1th"/"The 3th"/"The 21th"',
    );
  });

  // ── Cabang n == 1 di AppLocalizations.billsPaidDateEarly/Late (Audit T2 fix-1) ──
  //
  // Test JSON di atas hanya membuktikan NILAI kunci `_one` benar — tak satu
  // pun memanggil method Dart-nya, jadi ternary `n == 1 ? ... : ...` di
  // app_localizations.dart bisa dihapus tanpa membuat satu test pun merah.
  // Test di bawah membangun AppLocalizations sungguhan dan memanggil
  // method-nya supaya cabangnya benar-benar tereksekusi.
  test('billsPaidDateEarly(1) mengambil kunci tunggal, bukan kunci jamak', () {
    expect(l10nEn.billsPaidDateEarly(1), 'You paid 1 day early.');
  });

  test('billsPaidDateEarly(2) mengambil kunci jamak berplaceholder', () {
    expect(l10nEn.billsPaidDateEarly(2), contains('2 days'));
  });

  test('billsPaidDateLate(1) mengambil kunci tunggal, bukan kunci jamak', () {
    expect(l10nEn.billsPaidDateLate(1), 'You paid 1 day late.');
  });

  test('billsPaidDateLate(2) mengambil kunci jamak berplaceholder', () {
    expect(l10nEn.billsPaidDateLate(2), contains('2 days'));
  });

  // ── Arah balik: id.json → billsKeys (Audit S4 fix-2) ──
  //
  // Semua test di atas beriterasi dari billsKeys ke JSON (arah maju) — kunci
  // yang ADA di JSON tapi lupa didaftarkan ke billsKeys lolos diam-diam.
  // Persis mekanisme yang melahirkan empat lubang [Audit S4] yang ditutup
  // manual di gelombang perbaikan 2026-08-08. Test ini menutup arah baliknya
  // supaya lubang kelima tak lahir dengan cara yang sama di task berikutnya.
  test(
    'billsKeys memuat semua key bills_ yang ada di id.json (arah balik)',
    () {
      final actualBillsKeys = id.keys
          .where((k) => k.startsWith('bills_'))
          .toSet();
      final missing = actualBillsKeys.difference(billsKeys.toSet());
      expect(
        missing,
        isEmpty,
        reason:
            'kunci bills_ ada di id.json tapi belum didaftarkan ke billsKeys: '
            '$missing',
      );
    },
  );
}
