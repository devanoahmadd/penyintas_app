import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';

/// Apakah [bill] TERMASUK JENIS yang bisa diwakili `settings.fixedExpenses`?
/// MURNI soal bentuk tagihan — TIDAK melihat isi anggaran sama sekali.
///
/// `fixedExpenses` adalah rencana PER-BULAN dengan lima slot
/// (`rent/utilities/internet/phone/other`). Premi tahunan dan tagihan
/// sekali-jalan tak pernah tercakup olehnya, berapa pun isinya — bahkan bila
/// pengguna menyisihkan 1/12 premi tiap bulan, yang terwakili hanya 1/12-nya.
///
/// **INI SATU-SATUNYA TEMPAT ATURAN INI BOLEH DITULIS.**
/// Sebelum ekstraksi ini, aturannya hidup di dua file dalam bentuk yang saling
/// negasi: `bebas()` di `calculate_bill_commitments.dart` (sisi baca) dan
/// prefill di `mark_bill_paid_sheet.dart` (sisi tulis). Ketika sisi baca
/// disempitkan ke bulanan dan sisi tulis tidak, tagihan tahunan ber-isFixedNeed
/// dicatat "sudah dipotong di muka" padahal sisi baca tak pernah menganggapnya
/// begitu — pengguna membayar Rp 1,2 juta dan angka "Aman dipakai" justru NAIK
/// Rp 1,2 juta. Seluruh 1045 test tetap hijau saat itu terjadi.
///
/// JANGAN salin ekspresi ini ke tempat lain. Dua salinan aturan yang bebas
/// menyimpang adalah akar bug ini, bukan gejalanya. Impor fungsinya.
bool representedByFixedExpenses(BillEntity bill) =>
    bill.isFixedNeed && bill.recurrence == Recurrence.monthly;

/// Apakah [bill] BENAR-BENAR sudah dipotong di muka?
/// Jenisnya cocok DAN potongannya ada — aturan M1.
///
/// Dipakai di titik yang PUNYA akses ke `fixedExpenses` (sisi baca, prefill
/// sheet). Titik yang tidak punya — mis. `BillsBloc` — memakai
/// [representedByFixedExpenses] saja dan menyerahkan paruh anggaran ke gerbang
/// M1 di `AddTransactionUseCase`, yang memang membaca `BudgetSettings`.
bool coveredUpfront(BillEntity bill, int fixedExpenses) =>
    representedByFixedExpenses(bill) && fixedExpenses > 0;
