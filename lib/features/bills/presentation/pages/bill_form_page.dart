import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/bills/data/models/bill_model.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/domain/usecases/get_bill_reminder_settings_usecase.dart';
import 'package:penyintas_app/features/bills/presentation/bloc/bills_bloc.dart';
import 'package:penyintas_app/features/bills/presentation/widgets/bill_category_grid.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/category_bloc.dart';
import 'package:penyintas_app/widgets/common/amount_keypad.dart';
import 'package:penyintas_app/widgets/common/fixed_need_help_sheet.dart';
import 'package:penyintas_app/widgets/common/fixed_need_toggle_tile.dart';

/// Batas akhir perulangan — spec §4.1 mewajibkan MAKSIMAL SATU yang non-null.
enum _TenorMode { unlimited, count, endDate }

/// Pilihan pengingat di form. Pemetaan ke payload lihat [_reminderPayload].
enum _ReminderMode { followSettings, d3, d1, dayOf, off }

/// Bagian TERBESAR dari badan halaman yang boleh dipakai panel keypad.
///
/// Panel setinggi ±290dp muat nyaman di potret, tapi di lanskap ponsel (badan
/// ±300dp) ia bersama bilah Simpan melampaui layar — Column-nya meluap 69px.
/// Batas ini yang mencegahnya, dan yang menjamin form serta tombol Simpan
/// selalu kebagian sisa layar. Di potret ia tak pernah tercapai.
const _porsiMaksPanel = 0.55;

/// Halaman tambah/ubah tagihan (spec §5).
///
/// [bill] null → mode tambah (emit [BillAdded]); selain itu mode ubah
/// (emit [BillUpdated] dengan `cloudId`, progres cicilan, status, dan
/// `createdAt` milik tagihan lama dipertahankan).
///
/// ── Keputusan hierarki vertikal (gerbang ui-ux-pro-max) ────────────────────
///
/// Sembilan kontrol berurutan mudah berubah jadi dinding teks. Yang
/// membedakannya di sini adalah RITME JARAK, bukan gaya teks baru — token
/// teks sudah cukup berlapis (label 13 `textSoft` · isian 16 `text` · catatan
/// & error 12 `muted`/`warn`), jadi menambah gaya keempat hanya akan
/// menambah kebisingan.
///
/// Tiga tingkat jarak, semuanya token:
///   • `AppSpacing.sm` (8)  — label → kontrolnya. Satu kesatuan.
///   • `AppSpacing.md` (12) — blok bersyarat → induknya. Tenor menempel pada
///     "Pengulangan" supaya kemunculannya terbaca sebagai induk yang MEKAR,
///     bukan sebagai bagian baru yang tiba-tiba muncul.
///   • `AppSpacing.xl` (24) — antar kelompok kontrol. Ini yang memecah dinding.
///     Sheet lama memakai 12 untuk SEMUA jarak, sehingga "label → field" dan
///     "field → kontrol berikutnya" terbaca sama berat.
///
/// Tombol simpan menempel di bawah, DI LUAR area gulir (spec §5.1), dengan
/// garis rambut di sisi atasnya: tanpa batas itu, isi yang tergulir di
/// baliknya tampak seperti terpotong, bukan seperti berlanjut.
class BillFormPage extends StatefulWidget {
  const BillFormPage({super.key, this.bill});

  final BillEntity? bill;

  @override
  State<BillFormPage> createState() => _BillFormPageState();
}

class _BillFormPageState extends State<BillFormPage> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _installmentController = TextEditingController();

  String? _category;
  DateTime? _dueDate;

  /// Anchor hari jatuh tempo (1–31) yang TERSIMPAN di tagihan.
  ///
  /// Sengaja TIDAK diturunkan dari `_dueDate`: `dueDate` bisa terpangkas
  /// akhir-bulan (anchor 31 → 28 Feb) sementara anchornya tetap 31, dan
  /// menurunkannya ulang saat menyimpan menghapus anchor itu SELAMANYA —
  /// tanpa exception, tanpa pesan, tanpa jalan pulih dari UI mana pun.
  /// Kontrak anchornya sendiri ada di `roll_forward_due_date.dart:7-9`.
  ///
  /// Ia TIDAK ikut `_capSekarang` [D15]: ia hanya bisa bergerak bersama
  /// `_dueDate`, yang sudah ada di cap itu.
  int? _dueDayAnchor;

  Recurrence _recurrence = Recurrence.monthly;
  _TenorMode _tenorMode = _TenorMode.unlimited;
  DateTime? _recurrenceEndDate;
  bool _isFixedNeed = false;
  _ReminderMode _reminder = _ReminderMode.followSettings;

  /// Nilai bawaan pengingat GLOBAL, hanya untuk DITAMPILKAN di bawah chip
  /// "Bawaan aplikasi". Ia bukan isian form — memilih "Bawaan" tetap menyimpan
  /// `daysBefore == null` alias "warisi bawaan global" (I5).
  ///
  /// null = belum tiba ATAU gagal dibaca. Keduanya diperlakukan sama: chip
  /// Bawaan tampil tanpa baris bawah. Menampilkan "(1 hari sebelum)" sebagai
  /// tebakan sementara berarti angkanya bisa berubah sendiri di depan mata
  /// pengguna — hal terakhir yang boleh terjadi di layar keuangan.
  int? _bawaanDaysBefore;

  /// Pesan validasi baru ditampilkan setelah percobaan simpan pertama —
  /// jangan memarahi pengguna sebelum ia sempat mengisi.
  bool _showErrors = false;
  bool _isSubmitting = false;

  /// `seq` kegagalan terakhir yang SUDAH ditindaklanjuti halaman ini.
  ///
  /// Di-seed saat `_submit()` dari state saat itu — bukan dibiarkan null:
  /// kegagalan yang sudah menggantung sebelum halaman ini mengirim apa pun
  /// (mis. hapus yang gagal di daftar) bukan milik kiriman ini.
  int? _seqGalatTerakhir;

  /// Aksi tulis yang PERMUKAAN INI kirim. Kegagalan aksi lain diabaikan —
  /// tanpa penjaga ini, gagal hapus di daftar tampil sebagai "gagal menyimpan"
  /// di form yang belum menerima jawaban apa pun.
  static const _aksiMilikku = {BillWriteAction.add, BillWriteAction.update};

  /// Cap keadaan awal, diambil sekali di [initState] SETELAH prefill.
  /// D15 membandingkan NILAI, bukan "pernah menyentuh field" — mengetik lalu
  /// menghapus lagi bukan perubahan.
  ///
  /// SENGAJA `late`, BUKAN `late final` [Important 2, review T10 ronde 1]:
  /// prefill yang tiba SETELAH `initState` — usecase asinkron yang ikut
  /// menyemai isian form, `didChangeDependencies`, atau `BlocListener` yang
  /// menyemai default — WAJIB bisa menyegarkan nilai ini lewat
  /// `_capAwal = _capSekarang;` di titik yang sama. Tanpa itu, penjaga D15
  /// menuduh pengguna mengubah sesuatu yang tak pernah ia sentuh.
  /// `late final` melempar `LateInitializationError` pada penyetelan kedua —
  /// jadi field ini TIDAK BOLEH `final` walau hari ini baru diisi sekali.
  ///
  /// BATASNYA: penyegaran itu hanya perlu bila prefill menyentuh salah satu
  /// nilai yang ikut dirangkai [_capSekarang]. Tak semua prefill asinkron
  /// begitu — `_bawaanDaysBefore` misalnya cuma KETERANGAN yang digambar di
  /// chip Bawaan, bukan isian, jadi kedatangannya tak pernah menggeser cap.
  /// Jangan balik logikanya: memaksa prefill menyetel field form supaya
  /// "penjaganya kepakai" justru merusak — menyetel `_reminder` dari setelan
  /// global, umpamanya, membuat tagihan baru MENYALIN angka global alih-alih
  /// mewarisinya, dan itu memecah I5.
  late String _capAwal;

  /// Diset TEPAT SEBELUM `Navigator.pop()` imperatif pada sukses simpan.
  ///
  /// KEJUJURAN [Important review T10, ronde 1]: pada kode saat ini flag ini
  /// TAK PUNYA efek yang teramati. Pop di `BlocListener` adalah pop
  /// IMPERATIF — ia tak pernah mengonsultasi `PopScope.canPop` sama sekali
  /// (`canPop` hanya dibaca `Navigator.maybePop()`, yaitu jalur tombol back
  /// sistem/`BackButton`). Dan pada detik flag ini diset `true`,
  /// `_isSubmitting` SUDAH `true` sejak `_submit()` dipanggil, jadi cabang
  /// `if (_isSubmitting) return;` di `onPopInvokedWithResult` SUDAH menelan
  /// back apa pun isi flag ini.
  ///
  /// Tetap dipertahankan di `canPop` sebagai jaring pengaman MURAH kalau
  /// suatu hari pop-sukses dipindah ke jalur yang sungguhan melewati
  /// `canPop` (mis. dibungkus `Navigator.maybePop()`) — bukan karena ia
  /// melindungi apa pun hari ini.
  bool _sudahDisimpan = false;

  /// Panel keypad terbuka. Aturan K1 (§5.2): ia dan keyboard sistem TAK PERNAH
  /// tampil bersamaan — halaman ini cuma punya satu bawah layar.
  bool _keypadTerbuka = false;

  /// Panel baru saja dibuka dan belum satu digit pun diketuk.
  ///
  /// Ketukan digit PERTAMA sesudah panel terbuka MENGGANTI nominal lama, bukan
  /// menambah di belakangnya: pengguna yang membuka Rp 1.245.000 lalu menekan
  /// "7" bermaksud menulis ulang, bukan membuat Rp 12.450.007. Backspace TIDAK
  /// ikut aturan ini — ia tanda pengguna sedang menyunting angka yang ada,
  /// jadi ketukan sesudahnya menambah seperti biasa.
  ///
  /// Disimpan DI SINI, bukan di `applyAmountKey`: fungsi itu milik bersama
  /// dengan onboarding, dan mengubah semantiknya akan mengubah layar lain.
  bool _keypadKetukanPertama = false;

  /// Pegangan konteks field nominal untuk aturan K3. SENGAJA terpisah dari
  /// `ValueKey('bill_form_amount')`: yang satu identitas widget untuk finder,
  /// yang satu titik acuan `Scrollable.ensureVisible`. Satu `GlobalKey` tak
  /// bisa merangkap keduanya tanpa memaksa test ikut tahu tipe internalnya.
  final _amountFieldKey = GlobalKey();

  bool get _isEdit => widget.bill != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.bill;
    if (initial != null) {
      _nameController.text = initial.name;
      _amountController.text = '${initial.estimatedAmount}';
      _notesController.text = initial.notes ?? '';
      _category = initial.category;
      _dueDate = initial.dueDate;
      _dueDayAnchor = initial.dueDayOfMonth;
      _recurrence = initial.recurrence;
      _isFixedNeed = initial.isFixedNeed;
      _recurrenceEndDate = initial.recurrenceEndDate;
      if (initial.installmentTotal != null) {
        _tenorMode = _TenorMode.count;
        _installmentController.text = '${initial.installmentTotal}';
      } else if (initial.recurrenceEndDate != null) {
        _tenorMode = _TenorMode.endDate;
      }
      _reminder = _reminderModeOf(
        enabled: initial.reminderEnabled,
        daysBefore: initial.reminderDaysBefore,
      );
    }
    // WAJIB diambil SETELAH prefill di atas — mode ubah membandingkan dengan
    // nilai widget.bill, bukan dengan form kosong [D15].
    _capAwal = _capSekarang;

    // Sengaja TIDAK di-await: `initState` harus selesai seketika, dan
    // hasilnya cuma menambah baris keterangan di chip Bawaan. Selama ia
    // belum tiba, form sudah bisa dipakai penuh.
    _muatBawaanPengingat();
  }

  /// Ambil setelan pengingat GLOBAL lewat lapisan domain.
  ///
  /// Left (gagal baca) diperlakukan SAMA dengan "belum tiba": biarkan
  /// `_bawaanDaysBefore` null, chip Bawaan tampil tanpa baris bawah, form
  /// tetap bisa disimpan. Tak ada gunanya menakuti pengguna dengan pesan
  /// galat untuk keterangan yang sifatnya pelengkap.
  Future<void> _muatBawaanPengingat() async {
    final hasil = await sl<GetBillReminderSettingsUseCase>()(const NoParams());
    if (!mounted) return;
    hasil.fold(
      (_) {},
      (s) => setState(() {
        _bawaanDaysBefore = s.daysBefore;
        // Prefill yang tiba SETELAH `initState` WAJIB menyegarkan baseline
        // D15 di titik penyetelannya — lihat komentar panjang di deklarasi
        // `_capAwal`. Hari ini `_bawaanDaysBefore` bukan bagian dari
        // `_capSekarang` (ia keterangan, bukan isian), jadi baris ini belum
        // mengubah apa pun yang teramati. Ia dipasang karena INI titik
        // masuknya prefill asinkron pertama di halaman ini: begitu ada nilai
        // dari setelan yang ikut menyemai isian form, tanpa baris ini penjaga
        // buang-perubahan akan menuduh pengguna mengubah sesuatu yang tak
        // pernah ia sentuh. Sama jujurnya dengan `_sudahDisimpan` di atas:
        // jaring pengaman murah, bukan penjaga yang sedang bekerja.
        _capAwal = _capSekarang;
      }),
    );
  }

  /// Label nilai bawaan global untuk baris bawah chip "Bawaan aplikasi".
  ///
  /// Tiga nilai pertama sengaja memakai kunci chip yang sudah ada alih-alih
  /// kunci berparameter, supaya bentuk jamak sisi EN tetap benar —
  /// "1 day before", bukan "1 days before". Kunci berparameter hanya menangani
  /// nilai tanpa chip sendiri, dan di sana n >= 2 sehingga jamaknya aman.
  String? _labelBawaan(AppLocalizations l10n) => switch (_bawaanDaysBefore) {
    null => null,
    0 => l10n.billsReminderDayOf,
    1 => l10n.billsReminderD1,
    3 => l10n.billsReminderD3,
    final n => l10n.billsReminderNDaysBefore(n),
  };

  /// Baris bawah chip Bawaan, sudah berkurung. null → baris itu tak digambar
  /// sama sekali (belum tiba atau gagal dibaca). Kurungnya urusan tampilan,
  /// jadi ia tinggal di sini dan bukan di pemetaan nilai di atas.
  String? _sublabelBawaan(AppLocalizations l10n) {
    final teks = _labelBawaan(l10n);
    return teks == null ? null : '($teks)';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _installmentController.dispose();
    super.dispose();
  }

  // ── Turunan nilai ─────────────────────────────────────────────────────────

  int get _amount =>
      int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
      0;

  int? get _installmentTotal => int.tryParse(
    _installmentController.text.replaceAll(RegExp(r'[^0-9]'), ''),
  );

  bool get _isRecurring => _recurrence != Recurrence.none;

  /// null → tak ada catatan. Sekali-jalan tak punya pola berulang untuk
  /// dijelaskan, dan tanggal yang belum dipilih tak punya angka untuk disebut.
  String? _catatanTanggal(AppLocalizations l10n) {
    final due = _dueDate;
    if (due == null) return null;
    // Catatan ini menjanjikan pola BULAN DEPAN, jadi ia wajib menyebut anchor
    // — bukan `due.day` yang bisa sedang terpangkas. Anchor 31 yang tampil
    // "tiap tanggal 28" di Februari adalah kebohongan: Maret kembali ke 31.
    final hari = _dueDayAnchor ?? due.day;
    return switch (_recurrence) {
      Recurrence.monthly => l10n.billsFormDueDateMonthlyNote(hari),
      // `MMMM` — nama bulan penuh yang sudah dilokalkan. Ini PEMAKAI PERTAMA
      // `MMMM` di fitur Tagihan; tiga DateFormat lain memakai `MMM` singkat.
      // Bedanya menyeret data locale yang berbeda, jadi uji device wajib
      // memeriksa ia berbahasa Indonesia (§11).
      Recurrence.yearly => l10n.billsFormDueDateYearlyNote(
        hari,
        DateFormat(
          'MMMM',
          Localizations.localeOf(context).languageCode,
        ).format(due),
      ),
      Recurrence.none => null,
    };
  }

  // ── D15: buang-perubahan ─────────────────────────────────────────────────

  /// Cap seluruh nilai yang menentukan "form sudah berubah atau belum".
  /// Setiap field di sini WAJIB punya jalur yang memicu rebuild — kalau
  /// tidak, [PopScope.canPop] di `build` memakai nilai basi dan membuang
  /// isian pengguna tanpa bertanya [Audit B3].
  String get _capSekarang => [
    _nameController.text.trim(),
    '$_amount',
    _notesController.text.trim(),
    _installmentController.text.trim(),
    _category ?? '',
    _dueDate?.toIso8601String() ?? '',
    _recurrence.name,
    _tenorMode.name,
    _recurrenceEndDate?.toIso8601String() ?? '',
    '$_isFixedNeed',
    _reminder.name,
  ].join('|');

  bool get _adaPerubahan => _capSekarang != _capAwal;

  /// Pemetaan pilihan pengingat → payload.
  ///
  /// `daysBefore == null` saat aktif berarti "warisi default global" —
  /// diresolusi oleh scheduler (Task 6.1), BUKAN dibaca dari DB di sini.
  (bool enabled, int? daysBefore) get _reminderPayload => switch (_reminder) {
    _ReminderMode.off => (false, null),
    _ReminderMode.followSettings => (true, null),
    _ReminderMode.d3 => (true, 3),
    _ReminderMode.d1 => (true, 1),
    _ReminderMode.dayOf => (true, 0),
  };

  /// Kebalikan [_reminderPayload] untuk prefill mode ubah. Nilai `daysBefore`
  /// di luar {0,1,3} (mis. dari versi lama) jatuh ke "ikut pengaturan".
  static _ReminderMode _reminderModeOf({
    required bool enabled,
    required int? daysBefore,
  }) {
    if (!enabled) return _ReminderMode.off;
    return switch (daysBefore) {
      3 => _ReminderMode.d3,
      1 => _ReminderMode.d1,
      0 => _ReminderMode.dayOf,
      _ => _ReminderMode.followSettings,
    };
  }

  // ── Validasi ──────────────────────────────────────────────────────────────

  bool get _nameInvalid => _nameController.text.trim().isEmpty;
  bool get _amountInvalid => _amount <= 0;
  bool get _categoryInvalid => _category == null;
  bool get _dueDateInvalid => _dueDate == null;
  bool get _tenorCountInvalid =>
      _isRecurring &&
      _tenorMode == _TenorMode.count &&
      (_installmentTotal == null || _installmentTotal! <= 0);
  bool get _tenorEndDateInvalid =>
      _isRecurring &&
      _tenorMode == _TenorMode.endDate &&
      _recurrenceEndDate == null;

  bool get _isValid =>
      !_nameInvalid &&
      !_amountInvalid &&
      !_categoryInvalid &&
      !_dueDateInvalid &&
      !_tenorCountInvalid &&
      !_tenorEndDateInvalid;

  // ── Mutasi state (penjaga invariant) ──────────────────────────────────────

  void _selectCategory(String slug) {
    setState(() {
      _category = slug;
      // Default cerdas: kategori "kebutuhan tetap" menyalakan toggle sekali.
      // Pengguna tetap bebas mematikannya lagi — tidak ditimpa tiap rebuild.
      if (slug == 'fixed') _isFixedNeed = true;
    });
  }

  void _selectRecurrence(Recurrence value) {
    setState(() {
      _recurrence = value;
      if (value == Recurrence.none) {
        // Spec §4.1: tagihan sekali-jalan tidak punya tenor sama sekali.
        _tenorMode = _TenorMode.unlimited;
        _installmentController.clear();
        _recurrenceEndDate = null;
      }
    });
  }

  /// INVARIANT §4.1 (maks 1 batas tenor non-null) ditegakkan DI SINI:
  /// berpindah mode WAJIB mengosongkan field mode lain — bukan sekadar
  /// menyembunyikannya, supaya payload tidak pernah membawa dua batas.
  void _selectTenorMode(_TenorMode mode) {
    setState(() {
      _tenorMode = mode;
      if (mode != _TenorMode.count) _installmentController.clear();
      if (mode != _TenorMode.endDate) _recurrenceEndDate = null;
    });
  }

  // ── Panel keypad (aturan K1–K3, spec §5.2) ────────────────────────────────

  void _bukaKeypad() {
    // Field nominal tetap tombol hidup selagi panel terbuka — menyentuhnya
    // lagi BUKAN transisi tertutup → terbuka, jadi ia tak boleh menyalakan
    // ulang `_keypadKetukanPertama`. Tanpa penjaga ini, sentuhan tak sengaja
    // di tengah mengetik membuat digit berikutnya MENGGANTI angka yang sudah
    // diketik — hilang diam-diam, tanpa satu pun perubahan di layar yang
    // memberi tahu bahwa keadaannya bergeser.
    //
    // Tombolnya sengaja tidak dimatikan saat panel terbuka: `onTap` yang jadi
    // null akan mencabut simpul semantik tombolnya, dan pembaca layar
    // kehilangan satu-satunya cara mengenali field ini.
    if (_keypadTerbuka) return;

    // K1 arah pertama: keypad mengusir keyboard sistem.
    FocusScope.of(context).unfocus();
    setState(() {
      _keypadTerbuka = true;
      // Berlaku setiap kali panel BERPINDAH dari tertutup ke terbuka —
      // termasuk buka → tutup → buka lagi.
      _keypadKetukanPertama = true;
    });

    // Gerbang ui-ux-pro-max — `reduced-motion` (severity HIGH): gulirannya
    // ikut mati kalau sistem meminta gerak dikurangi.
    final durasi = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 220);

    // K3: field nominal digulirkan ke area yang masih terlihat, meniru
    // perilaku bawaan Scaffold terhadap keyboard sistem.
    //
    // DIJADWALKAN setelah frame, bukan langsung: sebelum frame berikutnya
    // viewport masih setinggi semula, jadi sasaran gulirnya meleset persis
    // setinggi panel yang baru saja muncul.
    //
    // Bergulir, bukan melompat (`state-transition` + `duration-timing`
    // 150–300ms, easing masuk `easeOut`) — geraknya yang memberi tahu
    // pengguna bahwa halaman menggeser dirinya, bukan berpindah.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _amountFieldKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.2,
        duration: durasi,
        curve: Curves.easeOut,
      );
    });
  }

  void _tutupKeypad() {
    if (!_keypadTerbuka) return;
    setState(() => _keypadTerbuka = false);
  }

  // ── Pemilih tanggal ───────────────────────────────────────────────────────

  Widget _datePickerTheme(BuildContext ctx, Widget? child) => Theme(
    data: Theme.of(ctx).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Theme.of(ctx).brightness,
      ),
    ),
    child: child!,
  );

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      // Tagihan terlambat boleh dicatat mundur.
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 10),
      builder: _datePickerTheme,
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
        // SATU-SATUNYA titik yang memindahkan anchor: pengguna sungguh
        // memilih tanggal baru. Invarian I8 di spec induk §8.
        _dueDayAnchor = picked.day;
      });
    }
  }

  Future<void> _pickRecurrenceEndDate() async {
    final base = _dueDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _recurrenceEndDate ?? DateTime(base.year + 1, base.month, base.day),
      firstDate: base,
      lastDate: DateTime(base.year + 20),
      builder: _datePickerTheme,
    );
    if (picked != null) setState(() => _recurrenceEndDate = picked);
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  BillModel _buildModel() {
    final now = DateTime.now();
    final initial = widget.bill;
    final notes = _notesController.text.trim();
    final (reminderEnabled, reminderDaysBefore) = _reminderPayload;

    return BillModel(
      cloudId: initial?.cloudId,
      name: _nameController.text.trim(),
      estimatedAmount: _amount,
      category: _category!,
      isFixedNeed: _isFixedNeed,
      notes: notes.isEmpty ? null : notes,
      dueDate: _dueDate!,
      recurrence: _recurrence,
      // Kedua batas tenor dibaca APA ADANYA — invariant "maks 1 non-null"
      // sudah dijaga di _selectTenorMode. Non-recurring → keduanya null.
      installmentTotal: _isRecurring ? _installmentTotal : null,
      recurrenceEndDate: _isRecurring ? _recurrenceEndDate : null,
      // Anchor dipertahankan apa adanya; ia hanya berpindah di `_pickDueDate`.
      // Fallback `?? _dueDate!.day` melayani tagihan yang memang belum punya
      // anchor: mode tambah, dan tagihan sekali-jalan yang baru dijadikan
      // berulang.
      dueDayOfMonth: _isRecurring ? (_dueDayAnchor ?? _dueDate!.day) : null,
      installmentsPaid: initial?.installmentsPaid ?? 0,
      reminderDaysBefore: reminderDaysBefore,
      reminderEnabled: reminderEnabled,
      status: initial?.status ?? BillStatus.active,
      createdAt: initial?.createdAt ?? now,
      updatedAt: now,
    );
  }

  void _submit() {
    if (_isSubmitting) return;
    if (!_isValid) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() {
      _showErrors = false;
      _isSubmitting = true;
    });
    final model = _buildModel();
    final bloc = context.read<BillsBloc>();
    _seqGalatTerakhir = bloc.state.actionFailure?.seq;
    bloc.add(_isEdit ? BillUpdated(model) : BillAdded(model));
    // Navigator.pop() dipanggil via BlocListener setelah simpan berhasil.
  }

  /// Dialog buang-perubahan (D15). Permukaannya sengaja SAMA dengan dialog
  /// hapus tagihan (§4.5): keputusan yang tak bisa dibatalkan selalu terlihat
  /// sama.
  Future<bool?> _tanyaBuangPerubahan() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          l10n.billsFormDiscardTitle,
          style: AppTextStyles.h3.copyWith(
            color: isDark ? AppColors.textDark : AppColors.textLight,
          ),
        ),
        content: Text(
          l10n.billsFormDiscardBody,
          style: AppTextStyles.body.copyWith(
            color: isDark ? AppColors.textSoftDark : AppColors.textSoftLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.billsFormDiscardCancel,
              style: AppTextStyles.label.copyWith(
                color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.billsFormDiscardConfirm,
              style: AppTextStyles.label.copyWith(color: AppColors.warn),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    // Panel input pakai token khusus panel — terasa lebih "bersih" saat
    // mengetik angka (lihat CLAUDE.md: surfaceAltLight/Dark).
    final panelColor = isDark
        ? AppColors.surfaceAltDark
        : AppColors.surfaceAltLight;

    final locale = Localizations.localeOf(context).languageCode;
    final dateFormat = DateFormat('d MMM yyyy', locale);

    return BlocListener<BillsBloc, BillsState>(
      listener: (context, state) {
        if (!_isSubmitting) return;

        // WAJIB DIPERIKSA LEBIH DULU. Sejak kanal galat dipisah (§2),
        // `status` tak lagi menandai gagal-tulis — ia masih `success` saat
        // aksi ini gagal. Memeriksa `status` duluan akan MEM-POP halaman atas
        // kegagalan: form menutup mulus, tak ada yang tersimpan, dan tak ada
        // satu pun tanda di layar.
        //
        // Dan JANGAN pasang `listenWhen` pada `actionFailure` di sini: simpan
        // yang BERHASIL tidak memancarkan apa pun dari handler — yang menutup
        // halaman adalah emisi stream daftar yang menyusul. Menyaringnya
        // membuat form tak pernah menutup sesudah simpan berhasil.
        final gagal = state.actionFailure;
        if (gagal != null &&
            gagal.seq != _seqGalatTerakhir &&
            _aksiMilikku.contains(gagal.aksi)) {
          _seqGalatTerakhir = gagal.seq;
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.billsFormSaveFailed)));
          return;
        }

        if (state.status == BillsStatus.success) {
          // `_sudahDisimpan` diset SEBELUM pop di baris berikutnya, tapi pop
          // itu IMPERATIF — ia tak melewati `PopScope.canPop` sama sekali,
          // jadi flag ini tak menggerbangi apa pun pada detik ini (lihat
          // komentar jujur di deklarasinya). Jendela sukses-simpan sudah
          // dijaga oleh `_isSubmitting` di `onPopInvokedWithResult`.
          _sudahDisimpan = true;
          Navigator.of(context).pop();
        }
      },
      child: PopScope(
        // Panel keypad terbuka DILIPAT dulu, bukan langsung ditawari "buang
        // perubahan?" — pengguna yang cuma ingin menutup panel tak boleh
        // disodori pertanyaan tentang nominal yang justru baru saja ia ketik
        // dengan sengaja. Back kedua, dengan panel sudah tertutup, baru
        // menempuh jalur pembanding nilai di bawah.
        //
        // `_isSubmitting` SENGAJA TIDAK ada di sini [Important 1, review
        // T10]. Kalau ia ikut membuka kunci, `canPop` bernilai `true` selagi
        // tagihan sedang disimpan, back mem-pop halaman SEKETIKA, state
        // ter-dispose bersamanya, dan jawaban BLoC — sukses ATAU GAGAL —
        // tak pernah sampai (termasuk snackbar gagal-simpan, yang jadi TAK
        // PERNAH tampil). Back selama submit sekarang ditelan di
        // `onPopInvokedWithResult` di bawah, bukan dibuka lewat `canPop`.
        canPop: _sudahDisimpan || (!_keypadTerbuka && !_adaPerubahan),
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          // [Audit S13] Menekan Simpan lalu back sebelum BLoC menjawab BUKAN
          // "membuang perubahan" — pekerjaannya justru sedang disimpan.
          // Telan diam-diam, jangan tanya — dan (lihat komentar `canPop` di
          // atas) jangan biarkan halaman ter-pop di tengah proses sama
          // sekali, supaya jawaban BLoC yang menyusul tetap sampai ke layar.
          if (_isSubmitting) return;
          if (_keypadTerbuka) {
            _tutupKeypad();
            return;
          }
          final buang = await _tanyaBuangPerubahan();
          if (buang == true && context.mounted) Navigator.of(context).pop();
        },
        child: Scaffold(
          backgroundColor: bgColor,
          // Papan ketik menaikkan isi lewat mekanisme Scaffold — tak perlu lagi
          // padding `viewInsets` manual seperti pada bentuk sheet dulu.
          appBar: AppBar(
            backgroundColor: bgColor,
            // Tanpa ini, M3 menyiram AppBar dengan surfaceTint saat isi
            // tergulir di baliknya — warna yang tak ada di token kita.
            surfaceTintColor: Colors.transparent,
            // Tombol back digambar otomatis oleh AppBar karena halaman ini
            // selalu DIDORONG di atas /bills. Ia menggantikan `_CloseButton`
            // lama sekaligus membawa label semantik bawaan platform, yang dulu
            // tak dimiliki ikon silang tanpa tooltip itu.
            title: Text(
              _isEdit ? l10n.billsFormEditTitle : l10n.billsFormAddTitle,
              style: AppTextStyles.h3.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ),
          body: Focus(
            // K1 arah kedua: fokus berpindah ke field teks apa pun → keypad
            // tutup. Dipasang di akar body, bukan per-field, supaya field yang
            // ditambah kelak ikut terjaga tanpa harus diingat.
            //
            // `canRequestFocus: false` + `skipTraversal: true` [Audit S12]:
            // tanpa keduanya, node pembungkus ini ikut jadi perhentian di urutan
            // Tab dan bisa menerima fokus sendiri — yang memicu
            // `onFocusChange(true)` lalu menutup keypad tanpa pengguna
            // menyentuh field mana pun. Ia harus MENDENGAR fokus, bukan ikut
            // memperebutkannya.
            canRequestFocus: false,
            skipTraversal: true,
            onFocusChange: (punyaFokus) {
              if (punyaFokus) _tutupKeypad();
            },
            child: SafeArea(
              top: false,
              // `LayoutBuilder` dipakai untuk SATU hal: membatasi tinggi panel
              // keypad terhadap tinggi badan halaman yang sebenarnya — lihat
              // `_porsiMaksPanel` di bawah. `MediaQuery` tak bisa
              // menggantikannya karena ia tak tahu tinggi AppBar & inset aman.
              child: LayoutBuilder(
                builder: (context, batas) => Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1 — Nama
                            _FieldLabel(
                              l10n.billsFormNameLabel,
                              isDark: isDark,
                              required: true,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextField(
                              key: const ValueKey('bill_form_name'),
                              controller: _nameController,
                              style: AppTextStyles.body.copyWith(
                                color: textColor,
                              ),
                              maxLength: 50,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: _inputDecoration(
                                hint: l10n.billsFormNameHint,
                                panelColor: panelColor,
                                borderColor: borderColor,
                                mutedColor: mutedColor,
                                hasError: _showErrors && _nameInvalid,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            _ErrorText(
                              show: _showErrors && _nameInvalid,
                              message: l10n.billsFormErrorName,
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // 2 — Nominal
                            _FieldLabel(
                              l10n.billsFormAmountLabel,
                              isDark: isDark,
                              required: true,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _AmountDisplayField(
                              key: const ValueKey('bill_form_amount'),
                              fieldKey: _amountFieldKey,
                              amount: _amount,
                              label: l10n.billsFormAmountLabel,
                              hint: l10n.billsFormAmountHint,
                              active: _keypadTerbuka,
                              panelColor: panelColor,
                              borderColor: borderColor,
                              textColor: textColor,
                              mutedColor: mutedColor,
                              hasError: _showErrors && _amountInvalid,
                              onTap: _bukaKeypad,
                            ),
                            _ErrorText(
                              show: _showErrors && _amountInvalid,
                              message: l10n.billsFormErrorAmount,
                            ),
                            // Catatan menetap di bawah field, bukan sekadar hint
                            // yang lenyap begitu ada isinya (`input-helper-text`):
                            // "kira-kira" cuma jujur kalau janji "nanti diisi yang
                            // asli" tetap terbaca setelah angkanya masuk.
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              l10n.billsFormAmountNote,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 12,
                                color: mutedColor,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // 3 — Kategori
                            _FieldLabel(
                              l10n.billsFormCategoryLabel,
                              isDark: isDark,
                              required: true,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            BlocBuilder<CategoryBloc, CategoryState>(
                              builder: (context, state) {
                                // CategoryActionLoading TIDAK terjangkau dari layar
                                // ini — ia hanya dipancarkan create/update/delete,
                                // sedangkan Tagihan hanya pernah mengirim
                                // LoadCategories, dan CategoryBloc adalah factory
                                // sehingga instance Tagihan tak menerima event
                                // mutasi dari layar Kategori. Ia tetap ditangani
                                // supaya switch lengkap tak terlihat seperti
                                // kelalaian — dan ia membawa `categories`, jadi
                                // menggambarnya sebagai placeholder justru
                                // mengosongkan grid yang isinya ada.
                                final daftar = switch (state) {
                                  CategoryLoaded(:final categories) =>
                                    categories,
                                  CategoryActionLoading(:final categories) =>
                                    categories,
                                  _ => null,
                                };

                                if (state is CategoryError) {
                                  return _CategoryLoadError(
                                    isDark: isDark,
                                    onRetry: () => context
                                        .read<CategoryBloc>()
                                        .add(const LoadCategories()),
                                  );
                                }
                                if (daftar == null) {
                                  return const _CategoryGridPlaceholder();
                                }
                                return BillCategoryGrid(
                                  categories: daftar,
                                  selectedSlug: _category,
                                  onSelected: _selectCategory,
                                );
                              },
                            ),
                            _ErrorText(
                              show: _showErrors && _categoryInvalid,
                              message: l10n.billsFormErrorCategory,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              l10n.billsFormCategoryNote,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 12,
                                color: mutedColor,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // 4 — Jatuh tempo
                            _FieldLabel(
                              l10n.billsFormDueDateLabel,
                              isDark: isDark,
                              required: true,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _DateField(
                              fieldKey: const ValueKey('bill_form_due_date'),
                              value: _dueDate != null
                                  ? dateFormat.format(_dueDate!)
                                  : null,
                              hint: l10n.billsFormDueDateHint,
                              panelColor: panelColor,
                              borderColor: borderColor,
                              textColor: textColor,
                              mutedColor: mutedColor,
                              hasError: _showErrors && _dueDateInvalid,
                              onTap: _pickDueDate,
                            ),
                            _ErrorText(
                              show: _showErrors && _dueDateInvalid,
                              message: l10n.billsFormErrorDueDate,
                            ),
                            // Menjawab langsung kebingungan "ini tanggal
                            // pertama atau tanggal tiap bulan?". Sengaja
                            // TIDAK menyebut penyesuaian bulan pendek —
                            // `clampDayOfMonth` sudah menanganinya diam-diam,
                            // dan menambah kalimat untuk tanggal 29-31
                            // membebani semua pengguna demi sebagian kecil.
                            if (_catatanTanggal(l10n) case final catatan?) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                catatan,
                                key: const ValueKey('bill_form_due_date_note'),
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 12,
                                  color: mutedColor,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xl),

                            // 5 — Pengulangan
                            _FieldLabel(
                              l10n.billsFormRecurrenceLabel,
                              isDark: isDark,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                for (final (value, label)
                                    in <(Recurrence, String)>[
                                      (
                                        Recurrence.none,
                                        l10n.billsRecurrenceNone,
                                      ),
                                      (
                                        Recurrence.monthly,
                                        l10n.billsRecurrenceMonthly,
                                      ),
                                      (
                                        Recurrence.yearly,
                                        l10n.billsRecurrenceYearly,
                                      ),
                                    ])
                                  _ChoicePill(
                                    label: label,
                                    selected: _recurrence == value,
                                    panelColor: panelColor,
                                    borderColor: borderColor,
                                    textColor: textColor,
                                    onTap: () => _selectRecurrence(value),
                                  ),
                              ],
                            ),

                            // 6 — Tenor: hanya relevan saat tagihan berulang.
                            // Jaraknya SENGAJA satu tingkat lebih rapat (md, bukan
                            // xl) supaya blok ini terbaca menempel pada
                            // "Pengulangan" — mekarnya induk, bukan bagian baru.
                            if (_isRecurring) ...[
                              const SizedBox(height: AppSpacing.md),
                              _FieldLabel(
                                l10n.billsFormTenorLabel,
                                isDark: isDark,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  for (final (value, label)
                                      in <(_TenorMode, String)>[
                                        (
                                          _TenorMode.unlimited,
                                          l10n.billsTenorUnlimited,
                                        ),
                                        (
                                          _TenorMode.count,
                                          l10n.billsTenorCount,
                                        ),
                                        (
                                          _TenorMode.endDate,
                                          l10n.billsTenorEndDate,
                                        ),
                                      ])
                                    _ChoicePill(
                                      label: label,
                                      selected: _tenorMode == value,
                                      panelColor: panelColor,
                                      borderColor: borderColor,
                                      textColor: textColor,
                                      onTap: () => _selectTenorMode(value),
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                switch (_tenorMode) {
                                  _TenorMode.unlimited =>
                                    l10n.billsTenorUnlimitedNote,
                                  _TenorMode.count => l10n.billsTenorCountNote,
                                  _TenorMode.endDate =>
                                    l10n.billsTenorEndDateNote,
                                },
                                key: const ValueKey('bill_form_tenor_note'),
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 12,
                                  color: mutedColor,
                                ),
                              ),
                              if (_tenorMode == _TenorMode.count) ...[
                                const SizedBox(height: AppSpacing.md),
                                _FieldLabel(
                                  l10n.billsFormTenorCountLabel,
                                  isDark: isDark,
                                  required: true,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                TextField(
                                  key: const ValueKey('bill_form_installment'),
                                  controller: _installmentController,
                                  style: AppTextStyles.numericSm.copyWith(
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                  keyboardType: TextInputType.number,
                                  maxLength: 3,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: _inputDecoration(
                                    hint: l10n.billsFormTenorCountHint,
                                    panelColor: panelColor,
                                    borderColor: borderColor,
                                    mutedColor: mutedColor,
                                    hasError: _showErrors && _tenorCountInvalid,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                _ErrorText(
                                  show: _showErrors && _tenorCountInvalid,
                                  message: l10n.billsFormErrorTenorCount,
                                ),
                              ],
                              if (_tenorMode == _TenorMode.endDate) ...[
                                const SizedBox(height: AppSpacing.md),
                                _FieldLabel(
                                  l10n.billsFormTenorEndDateLabel,
                                  isDark: isDark,
                                  required: true,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                _DateField(
                                  fieldKey: const ValueKey(
                                    'bill_form_end_date',
                                  ),
                                  value: _recurrenceEndDate != null
                                      ? dateFormat.format(_recurrenceEndDate!)
                                      : null,
                                  hint: l10n.billsFormTenorEndDateHint,
                                  panelColor: panelColor,
                                  borderColor: borderColor,
                                  textColor: textColor,
                                  mutedColor: mutedColor,
                                  hasError: _showErrors && _tenorEndDateInvalid,
                                  onTap: _pickRecurrenceEndDate,
                                ),
                                _ErrorText(
                                  show: _showErrors && _tenorEndDateInvalid,
                                  message: l10n.billsFormErrorTenorEndDate,
                                ),
                              ],
                            ],
                            const SizedBox(height: AppSpacing.xl),

                            // 7 — Kebutuhan tetap
                            FixedNeedToggleTile(
                              tileKey: const ValueKey('bill_form_fixed_row'),
                              switchKey: const ValueKey('bill_form_fixed'),
                              value: _isFixedNeed,
                              label: l10n.billsFormFixedLabel,
                              // Hint lama menjanjikan "bukan potong jatah harian
                              // kamu" — tidak benar untuk tagihan non-bulanan, yang
                              // sejak gelombang ini SELALU dihitung sebagai
                              // pengeluaran saat dibayar. Toggle-nya tetap hidup:
                              // `isFixedNeed` adalah pernyataan NIAT pengguna,
                              // penyempitannya terjadi di titik pakai.
                              //
                              // I3: hint WAJIB ikut `_recurrence` — jangan
                              // disederhanakan jadi tanpa syarat.
                              hint: _recurrence == Recurrence.monthly
                                  ? l10n.billsFormFixedHint
                                  : l10n.billsFormFixedHintNonMonthly,
                              panelColor: panelColor,
                              borderColor: borderColor,
                              textColor: textColor,
                              mutedColor: mutedColor,
                              onHelpTap: () => FixedNeedHelpSheet.show(context),
                              helpSemanticLabel: l10n.billsFixedHelpA11y,
                              // I4: TIDAK ada `enabled:` di sini. Toggle form
                              // adalah pernyataan NIAT pengguna; penyempitannya
                              // terjadi di sheet bayar, BUKAN di sini — jangan
                              // sampai menyambungkan (?) ikut membawa
                              // penguncian dari satu tempat ke tempat lain.
                              onChanged: (v) =>
                                  setState(() => _isFixedNeed = v),
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // 8 — Pengingat
                            _FieldLabel(
                              l10n.billsFormReminderLabel,
                              isDark: isDark,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            // D14: "Bawaan aplikasi" BERDIRI SENDIRI di
                            // barisnya, bukan chip pertama di deretan yang
                            // sama. Ia bukan pilihan sejenis: empat chip di
                            // bawah menyimpan angka, chip ini menyimpan
                            // "ikut apa pun yang berlaku nanti". Menyandingkan
                            // keduanya membuat perbedaan itu tak terlihat.
                            //
                            // D11: nilai bawaan yang sedang berlaku ditulis di
                            // baris kedua, supaya "Bawaan aplikasi" tak lagi
                            // jadi janji kosong yang harus dicari sendiri di
                            // layar pengaturan.
                            _ChoicePill(
                              label: l10n.billsReminderDefault,
                              sublabel: _sublabelBawaan(l10n),
                              selected:
                                  _reminder == _ReminderMode.followSettings,
                              panelColor: panelColor,
                              borderColor: borderColor,
                              textColor: textColor,
                              onTap: () => setState(
                                () => _reminder = _ReminderMode.followSettings,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // Pemisah, bukan label sejajar "Pengingat" —
                            // karena itu ia digambar setipis catatan (12,
                            // muted), bukan setebal label field.
                            Text(
                              l10n.billsReminderCustomLabel,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 12,
                                color: mutedColor,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                for (final (value, label)
                                    in <(_ReminderMode, String)>[
                                      (_ReminderMode.d3, l10n.billsReminderD3),
                                      (_ReminderMode.d1, l10n.billsReminderD1),
                                      (
                                        _ReminderMode.dayOf,
                                        l10n.billsReminderDayOf,
                                      ),
                                      (
                                        _ReminderMode.off,
                                        l10n.billsReminderOff,
                                      ),
                                    ])
                                  _ChoicePill(
                                    label: label,
                                    selected: _reminder == value,
                                    panelColor: panelColor,
                                    borderColor: borderColor,
                                    textColor: textColor,
                                    onTap: () =>
                                        setState(() => _reminder = value),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // 9 — Catatan
                            _FieldLabel(
                              l10n.billsFormNotesLabel,
                              isDark: isDark,
                              optionalNote: l10n.billsFormNotesOptional,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextField(
                              key: const ValueKey('bill_form_notes'),
                              controller: _notesController,
                              style: AppTextStyles.body.copyWith(
                                color: textColor,
                              ),
                              maxLength: 120,
                              maxLines: 2,
                              minLines: 1,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: _inputDecoration(
                                hint: l10n.billsFormNotesHint,
                                panelColor: panelColor,
                                borderColor: borderColor,
                                mutedColor: mutedColor,
                                hasError: false,
                              ),
                              // Catatan tak ikut validasi, tapi tetap butuh jalur
                              // rebuild: tanpa ini, apa pun yang membaca keadaan
                              // form (mis. penjaga "buang perubahan?") memakai nilai
                              // basi satu ketukan.
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Tombol Simpan MENEMPEL di bawah, di luar area gulir (spec
                    // §5.1). Ia harus tetap terlihat apa pun yang sedang terbuka —
                    // aturan K2 di §5.2 ditegakkan oleh posisinya di sini, bukan
                    // oleh padding. Garis rambut di atasnya menandai batas antara
                    // yang tergulir dan yang menetap.
                    Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        border: Border(top: BorderSide(color: borderColor)),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      // Kategori gagal dimuat → Simpan dimatikan. Menyimpan tagihan
                      // tanpa bisa memverifikasi kategorinya adalah menyimpan
                      // tebakan (spec §5.3).
                      //
                      // DITURUNKAN dari state, bukan disimpan di field. Field
                      // boolean di sini hanya akan jadi salinan basi yang lupa
                      // dikembalikan setelah retry berhasil [Audit T5]: pengguna
                      // menekan "Coba lagi", grid terisi penuh, dan tombol Simpan
                      // tetap mati tanpa penjelasan apa pun di layar.
                      child: BlocSelector<CategoryBloc, CategoryState, bool>(
                        selector: (state) => state is CategoryError,
                        builder: (context, kategoriGagal) => SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            key: const ValueKey('bill_form_submit'),
                            onPressed: _isSubmitting || kategoriGagal
                                ? null
                                : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.primary
                                  .withValues(alpha: 0.4),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    l10n.btnSave,
                                    style: AppTextStyles.label.copyWith(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    // Urutan Column: [gulir] → [Simpan] → [keypad].
                    //
                    // K2 ditegakkan oleh URUTAN ini, bukan oleh perhitungan padding.
                    // Menaruh keypad di atas Simpan, atau memakai `bottomSheet`
                    // Scaffold, akan menutupi tombolnya.
                    //
                    // Ia juga anak TERAKHIR di dalam `SafeArea`, jadi inset gestur
                    // bawah jatuh di bawah panel — bukan di antara Simpan dan
                    // keypad (`safe-area-awareness`).
                    if (_keypadTerbuka)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: batas.maxHeight * _porsiMaksPanel,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            // Panel input pakai `surfaceAlt*`, bukan `surface*`
                            // (CLAUDE.md). Di terang, ia nyaris sewarna latar —
                            // garis rambut di atasnya yang memisahkan panel dari
                            // bilah Simpan.
                            color: panelColor,
                            border: Border(top: BorderSide(color: borderColor)),
                          ),
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xl,
                            AppSpacing.sm,
                            AppSpacing.xl,
                            AppSpacing.md,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Satu-satunya jalan keluar EKSPLISIT dari panel
                              // (gerbang ui-ux-pro-max: `escape-routes` +
                              // `gesture-alternative`). Tanpa ini, menutup keypad
                              // cuma bisa lewat efek samping — menyentuh field teks
                              // lain — dan pengguna yang sudah selesai mengetik
                              // angka tak punya cara memulihkan ruang layarnya.
                              //
                              // Sengaja TextButton, bukan tombol terisi: satu layar
                              // satu CTA utama (`primary-action`), dan itu Simpan.
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  key: const ValueKey('bill_form_keypad_done'),
                                  onPressed: _tutupKeypad,
                                  // Hit target 48dp DISETEL EKSPLISIT — bawaan
                                  // TextButton 36dp, dan angka 48 dari
                                  // `MaterialTapTargetSize.padded` bergantung tema.
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(64, 48),
                                    foregroundColor: AppColors.primary,
                                  ),
                                  child: Text(
                                    l10n.billsFormAmountDone,
                                    style: AppTextStyles.label.copyWith(
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              // Yang MENGALAH saat panel dibatasi adalah gridnya —
                              // digulir, bukan dipangkas — sehingga "Selesai" di
                              // atasnya tetap terjangkau dan tinggi tombol tetap
                              // 48dp. Di potret normal batas itu tak pernah
                              // tercapai dan `Flexible` ini tak berefek apa pun.
                              Flexible(
                                child: SingleChildScrollView(
                                  child: AmountKeypad(
                                    isDark: isDark,
                                    // WAJIB sinkron dengan padding Container di
                                    // atas: 24 kiri + 24 kanan. `AmountKeypad`
                                    // menurunkan TINGGI tombol dari angka ini
                                    // [Audit S3]. Mengubah `AppSpacing.xl` di atas
                                    // tanpa mengubah nilai ini akan memecah hit
                                    // target 48dp diam-diam.
                                    horizontalPadding: AppSpacing.xl * 2,
                                    onKey: (k) => setState(() {
                                      // Lihat `_keypadKetukanPertama`. Backspace
                                      // dikecualikan dari "mulai angka baru",
                                      // tapi tetap MELUNASI penandanya: sesudah
                                      // ia ditekan, pengguna jelas sedang
                                      // menyunting angka lama.
                                      final dasar =
                                          _keypadKetukanPertama && k != 'back'
                                          ? 0
                                          : _amount;
                                      _keypadKetukanPertama = false;
                                      _amountController.text =
                                          '${applyAmountKey(dasar, k)}';
                                    }),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    String? prefixText,
    required Color panelColor,
    required Color borderColor,
    required Color mutedColor,
    required bool hasError,
  }) {
    final baseBorder = hasError ? AppColors.warn : borderColor;
    return InputDecoration(
      hintText: hint,
      prefixText: prefixText,
      hintStyle: AppTextStyles.body.copyWith(color: mutedColor),
      filled: true,
      fillColor: panelColor,
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: baseBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: baseBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(
          color: hasError ? AppColors.warn : AppColors.primary,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
    );
  }
}

// ── Sub-komponen ─────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(
    this.text, {
    required this.isDark,
    this.required = false,
    this.optionalNote,
  });

  final String text;
  final bool isDark;
  final bool required;

  /// Ditampilkan sebagai "(opsional)" untuk field yang boleh dikosongkan.
  final String? optionalNote;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Semantics(
      label: required
          ? '$text, ${context.l10n.billsFormRequired}'
          : (optionalNote != null ? '$text, $optionalNote' : text),
      excludeSemantics: true,
      child: Row(
        children: [
          Text(
            text,
            style: AppTextStyles.label.copyWith(fontSize: 13, color: color),
          ),
          if (required)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Text(
                '*',
                style: AppTextStyles.label.copyWith(
                  fontSize: 13,
                  color: AppColors.warn,
                ),
              ),
            ),
          if (optionalNote != null)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Text(
                '($optionalNote)',
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  color: mutedColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.show, required this.message});
  final bool show;
  final String message;

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: AppColors.warn,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 12,
                color: AppColors.warn,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kategori gagal dimuat. Bukan sekadar teks — ia membawa jalan keluarnya,
/// karena tanpa kategori form ini tak bisa disimpan sama sekali.
class _CategoryLoadError extends StatelessWidget {
  const _CategoryLoadError({required this.isDark, required this.onRetry});

  final bool isDark;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      // Kotak ini menggantikan grid SETELAH halaman tergambar. Tanpa
      // `liveRegion`, pembaca layar tak mengumumkan apa pun dan pengguna
      // hanya menemukan tombol Simpan yang mati tanpa sebab.
      liveRegion: true,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: BillCategoryGrid.tinggiTile,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                // BUKAN `billsError` ("Gagal memuat tagihan…") — tagihannya
                // baik-baik saja di layar ini; yang gagal kategorinya.
                l10n.billsFormCategoryLoadFailed,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              key: const ValueKey('bill_form_category_retry'),
              onPressed: onRetry,
              // Hit target 48dp DISETEL EKSPLISIT. Bawaan `TextButton` adalah
              // 36dp; angka 48 hanya datang dari `MaterialTapTargetSize.padded`
              // yang bergantung tema dan platform — terlalu rapuh untuk
              // menopang aturan yang wajib.
              style: TextButton.styleFrom(
                minimumSize: const Size(64, 48),
                foregroundColor: AppColors.primary,
              ),
              child: Text(
                l10n.retry,
                style: AppTextStyles.label.copyWith(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ruang yang DIPESAN selagi kategori dimuat.
///
/// Tingginya setara TIGA baris grid, bukan dua: seed produksi menyemai tujuh
/// kategori pengeluaran, dan tujuh tile di grid tiga kolom selalu jadi tiga
/// baris. Memesan dua baris seperti rancangan awal menyisakan lompatan ~84dp
/// tepat saat pengguna sedang mengisi form — cara termudah membuat orang
/// salah tekan (gerbang ui-ux-pro-max: `content-jumping`, severity HIGH).
class _CategoryGridPlaceholder extends StatelessWidget {
  const _CategoryGridPlaceholder();

  static const _barisTerpesan = 3;

  @override
  Widget build(BuildContext context) => SizedBox(
    height:
        BillCategoryGrid.tinggiTile * _barisTerpesan +
        AppSpacing.sm * (_barisTerpesan - 1),
    child: const Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      ),
    ),
  );
}

/// Chip pilihan tunggal. Selalu berteks — warna hanya penguat.
///
/// [sublabel] menambah baris kedua yang lebih redup di dalam chip yang sama —
/// dipakai chip "Bawaan aplikasi" untuk menyebut nilai global yang sedang
/// berlaku (D11). Warnanya DITURUNKAN dari warna teks utama, bukan token
/// baru: di keadaan terpilih latar chip adalah `primary`, dan warna redup
/// mana pun dari palet teks akan tenggelam di atasnya.
class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.panelColor,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
    this.sublabel,
  });

  final String label;
  final bool selected;
  final Color panelColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;
  final String? sublabel;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : textColor;
    final teksKedua = sublabel;

    return Material(
      color: selected ? AppColors.primary : panelColor,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? AppColors.primary : borderColor,
            ),
          ),
          child: Container(
            // Hit target minimum Android 48dp.
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md2,
              vertical: AppSpacing.sm,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 13,
                    color: fg,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (teksKedua != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    teksKedua,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 12,
                      color: fg.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Field nominal TANPA caret: ia bukan tempat mengetik, melainkan tombol yang
/// membuka panel keypad dan memantulkan kembali nilai yang sudah terformat.
///
/// ── Keputusan keadaan aktif (gerbang ui-ux-pro-max) ────────────────────────
///
/// Tanpa caret, satu-satunya penanda "field ini sedang aktif" adalah
/// garisnya. Karena itu ia ditandai DUA hal sekaligus — warna (primary) DAN
/// tebal (2, bukan 1). Warna saja melanggar `color-not-only`: pengguna yang
/// tak membedakan hijau dari krem hanya melihat kotak yang sama. Angka 2
/// bukan angka baru: itu tebal `focusedBorder` bawaan Material, yang persis
/// dipakai field teks lain di halaman ini saat mendapat fokus.
class _AmountDisplayField extends StatelessWidget {
  const _AmountDisplayField({
    super.key,
    required this.fieldKey,
    required this.amount,
    required this.label,
    required this.hint,
    required this.active,
    required this.panelColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedColor,
    required this.hasError,
    required this.onTap,
  });

  /// Dipakai [Scrollable.ensureVisible] pada aturan K3 — lihat `_bukaKeypad`.
  final Key fieldKey;
  final int amount;

  /// Nama field untuk pembaca layar. Field ini tak punya caret dan tak pernah
  /// jadi `TextField`, jadi tak ada label bawaan yang bisa diandalkan.
  final String label;
  final String hint;
  final bool active;
  final Color panelColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedColor;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final terisi = amount > 0;
    // `formatRupiah` sudah membawa simbol "Rp"; hint disandingkan dengan
    // simbol yang sama supaya posisi teksnya tak bergeser saat digit pertama
    // masuk — hanya gayanya yang berubah dari contoh redup jadi angka nyata.
    final teks = terisi ? formatRupiah(amount) : 'Rp $hint';
    final garis = hasError
        ? AppColors.warn
        : (active ? AppColors.primary : borderColor);

    return Semantics(
      button: true,
      // Nama field DIBAWA simpul ini sendiri. `excludeSemantics` di bawah
      // membuang semantik keturunan, jadi tanpa `label` pembaca layar hanya
      // mendengar angka tanpa tahu angka APA.
      label: label,
      // Placeholder BUKAN nilai. Kalau `'Rp 750.000'` yang redup itu
      // diumumkan sebagai `value`, form kosong terdengar PERSIS sama dengan
      // form yang benar-benar berisi Rp 750.000 — regresi dari `TextField`
      // lama, yang memetakan `hintText` ke `SemanticsProperties.hint`.
      value: terisi ? teks : null,
      hint: terisi ? null : teks,
      // `excludeSemantics` membuang seluruh semantik keturunan — TERMASUK
      // aksi ketuk milik InkWell. Tanpa `onTap` di simpul ini, pembaca layar
      // menemukan tombol yang tak bisa diaktifkan sama sekali.
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        key: fieldKey,
        color: panelColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: garis, width: active ? 2 : 1),
            ),
            child: Container(
              // 56 > 48dp: field uang adalah sasaran ketuk sekaligus tempat
              // angka terbesar di halaman ini.
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              alignment: Alignment.centerLeft,
              child: Text(
                teks,
                // Nominal pakai token numerik — tabular-nums sudah built-in,
                // jadi angkanya tak bergoyang tiap digit bertambah.
                style: terisi
                    ? AppTextStyles.numericMd.copyWith(color: textColor)
                    : AppTextStyles.body.copyWith(color: mutedColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.fieldKey,
    required this.value,
    required this.hint,
    required this.panelColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedColor,
    required this.hasError,
    required this.onTap,
  });

  final Key fieldKey;
  final String? value;
  final String hint;
  final Color panelColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedColor;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: fieldKey,
      color: panelColor,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: hasError ? AppColors.warn : borderColor),
          ),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: mutedColor,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  value ?? hint,
                  style: AppTextStyles.body.copyWith(
                    color: value != null ? textColor : mutedColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
