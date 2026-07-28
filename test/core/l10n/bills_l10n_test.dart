import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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
void main() {
  late Map<String, dynamic> id;
  late Map<String, dynamic> en;

  setUpAll(() {
    id =
        json.decode(File('assets/translations/id.json').readAsStringSync())
            as Map<String, dynamic>;
    en =
        json.decode(File('assets/translations/en.json').readAsStringSync())
            as Map<String, dynamic>;
  });

  /// Semua key berawalan `bills_` yang dipakai lapisan presentasi Tagihan
  /// (halaman daftar, sheet tambah/ubah, sheet tandai-lunas, snackbar undo).
  const billsKeys = [
    // Halaman daftar
    'bills_title',
    'bills_empty',
    'bills_add',
    'bills_error',
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
}
