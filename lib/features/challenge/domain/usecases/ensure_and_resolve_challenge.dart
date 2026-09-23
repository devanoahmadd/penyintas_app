import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/core/utils/app_clock.dart';
import 'package:penyintas_app/features/challenge/data/datasources/challenge_local_datasource.dart';
import 'package:penyintas_app/features/challenge/data/datasources/challenge_settings_datasource.dart';
import 'package:penyintas_app/features/challenge/domain/challenge_calculator.dart';
import 'package:penyintas_app/features/challenge/domain/challenge_constants.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_environment.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/domain/entities/ensure_outcome.dart';
import 'package:penyintas_app/features/challenge/domain/ports/challenge_environment_port.dart';
import 'package:penyintas_app/features/challenge/domain/repositories/challenge_repository.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/get_limitable_categories_usecase.dart';

/// Satu-satunya jalur tulis fitur ini. Dipanggil di tiga titik: bootstrap,
/// resume, dan pergantian minggu (penjaga `lastEnsuredWeekKey` di BLoC).
///
/// Isinya berurutan & IDEMPOTEN — memanggilnya dua kali berturut tidak boleh
/// menghasilkan baris kedua.
///
/// Tujuh langkah, berurutan, dan urutannya adalah kontraknya: 1 (tutup minggu
/// lampau), 1c (rapikan hasil lama), lalu 2–6 (pembuatan). Tiap jalan keluar
/// melaporkan APA YANG SEMPAT DIKETAHUI lewat [EnsureOutcome], dan daftar
/// jalan keluar itu adalah CERMIN urutan tingkat 3 `resolveChallengePhase`.
/// Kalau salah satunya berubah tanpa yang lain, gejalanya bukan error yang
/// terlihat — melainkan skeleton yang tak kunjung selesai di layar user.
class EnsureAndResolveChallenge implements UseCase<EnsureOutcome, NoParams> {
  EnsureAndResolveChallenge({
    required ChallengeRepository repo,
    required ChallengeLocalDatasource local,
    required GetLimitableCategoriesUseCase getLimitable,
    required ChallengeEnvironmentPort env,
    required ChallengeSettingsDatasource settings,
    required AppClock clock,
  }) : _repo = repo,
       _local = local,
       _getLimitable = getLimitable,
       _env = env,
       _settings = settings,
       _clock = clock;

  final ChallengeRepository _repo;
  final ChallengeLocalDatasource _local;
  final GetLimitableCategoriesUseCase _getLimitable;
  final ChallengeEnvironmentPort _env;
  final ChallengeSettingsDatasource _settings;
  final AppClock _clock;

  @override
  Future<Either<Failure, EnsureOutcome>> call(NoParams _) async {
    final now = _clock.now();
    final mingguIni = weekKeyOf(now);

    // S-B — apa pun jalan keluarnya, usecase ini melaporkan APA YANG SEMPAT
    // IA KETAHUI. `null` berarti "tidak sempat dihitung", bukan "nol".
    EnsureOutcome keluar({int? kandidat, ChallengeEnvironment? env}) =>
        EnsureOutcome(weekKey: mingguIni, candidateCount: kandidat, env: env);

    // ── 1. Tutup SEMUA baris lampau yang masih active ──────────────────────
    // Jamak dengan sungguh-sungguh: dua baris lampau `active` sekaligus bisa
    // terjadi lewat jam device yang dimundurkan atau merge lintas-device.
    final slugAda = await _slugKategoriYangMasihAda();
    for (final row in await _local.activeWeeksBefore(mingguIni)) {
      final kategori = row.category;
      final terpakai = kategori == null
          ? 0
          : await _local.spentInWeek(weekKey: row.weekKey, category: kategori);

      // T13 — kategori lenyap: dicatat `skipped`, BUKAN `missed`. User tak bisa
      // lagi bertindak pada pos itu, jadi mencatatnya sebagai kegagalan user
      // adalah tuduhan yang salah alamat. finalSpent TETAP diisi: transaksinya
      // masih hidup (deleteCategory hanya menyapu budget_limits + categories).
      final status = (kategori == null || !slugAda.contains(kategori))
          ? ChallengeStatus.skipped
          : evaluateResult(target: row.targetAmount ?? 0, finalSpent: terpakai);

      await _repo.resolveWeek(
        weekKey: row.weekKey,
        status: status,
        finalSpent: terpakai,
      );
    }

    // ── 1b DIHAPUS (Keputusan 1) ───────────────────────────────────────────
    // JANGAN menutup baris minggu INI karena sakelar mati. Keadaan itu tak bisa
    // lahir lokal — SetChallengeEnabled menutup baris dulu dan tidak membalik
    // sakelar bila gagal (U75), logout menyapu keduanya, instalasi baru punya
    // keduanya kosong. Satu-satunya penghasilnya adalah tarikan dari device
    // lain, dan menutupnya di sini membunuh minggu yang sedang berjalan di
    // sana — permanen, karena mergeRank membuat `skipped` menang atas `active`.
    //
    // Langkah 1 di atas TETAP dan tetap aman lintas device: ia deterministik
    // dari transaksi yang sudah tersinkron, jadi device mana pun sampai pada
    // jawaban yang sama.

    // ── 1c. Rapikan hasil lama (D22) ───────────────────────────────────────
    // Aturan ini HIDUP DI SINI, bukan di snapshot. Snapshot lahir dari stream,
    // dan menulis dari stream yang mengawasi tabelnya sendiri menghidupkan
    // kembali loop tulis→emit→hitung→tulis (D-2 Fase 1).
    final belumDilihat = await _local
        .watchHistory(kChallengeHistoryWeeks)
        .first;
    final hasilBaru = belumDilihat
        .where(
          (r) =>
              r.resultSeenAt == null &&
              (r.status == ChallengeStatus.achieved ||
                  r.status == ChallengeStatus.missed),
        )
        .toList();
    if (hasilBaru.length > 1) {
      final terbaru = hasilBaru
          .map((r) => r.weekKey)
          .reduce((a, b) => a > b ? a : b);
      await _repo.markOlderResultsSeen(keepWeekKey: terbaru);
    }

    // ── 2. Idempoten ───────────────────────────────────────────────────────
    // PALING ATAS di antara gerbang pembuatan, dan sengaja di atas bacaan
    // lingkungan: minggu yang sudah punya baris tidak boleh disentuh apa pun
    // lagi — termasuk tidak boleh membelanjakan satu pun bacaan dashboard.
    if (await _local.findWeek(mingguIni) != null) return Right(keluar());

    // ── 3–4. Gerbang murah lebih dulu ──────────────────────────────────────
    final aktif = await _settings.isEnabled();
    if (!aktif) return Right(keluar());
    if (!isCreationWindow(now)) return Right(keluar());

    // ── 5. Kandidat ────────────────────────────────────────────────────────
    // S-B/M11 — `Left` TIDAK dipadatkan jadi daftar kosong. "Gagal dibaca" dan
    // "memang tak ada yang layak" adalah dua jawaban berbeda, dan user berhak
    // tidak dituduh kurang data ketika yang gagal sebetulnya database.
    final kandidatHasil = await _repo.getCandidates(mingguIni);
    if (kandidatHasil.isLeft()) return Right(keluar()); // kandidat tetap null
    final kandidat = kandidatHasil.getOrElse(() => const []);
    // `0`, bukan `keluar()` polos: nol di sini berarti SUDAH DIHITUNG dan
    // memang tak ada yang layak — jawaban terminal, bukan "belum sempat".
    if (kandidat.isEmpty) return Right(keluar(kandidat: 0));

    // ── 6. SATU bacaan lingkungan, tiga keputusan ──────────────────────────
    // Dipanggil HANYA di sini: maksimal sekali per minggu yang berhasil.
    //
    // Ditulis dengan `if (isLeft())` + pencocokan pola, BUKAN `fold` bercabang
    // `async` sebelah. `fold` yang satu cabangnya sinkron dan satunya `Future`
    // tidak menyatukan tipe dan berkas ini tidak akan kompilasi.
    final envHasil = await _env.read();

    // Fail-safe: keadaan tak diketahui TIDAK menghasilkan baris. Minggu ini
    // masih bisa dicoba lagi hari Selasa — diam lebih aman daripada menebak,
    // karena `held` bersifat FINAL dan tak bisa dibatalkan.
    if (envHasil.isLeft()) return Right(keluar(kandidat: kandidat.length));

    final e = envHasil.getOrElse(
      () => const ChallengeEnvironment(
        budgetConfigured: false,
        survivalActive: false,
      ),
    );
    final hasil = keluar(kandidat: kandidat.length, env: e);

    // D16 — tanpa menulis apa pun. Kalau ini menulis `held`, user tanpa
    // anggaran ter-`held` permanen tiap Senin, selamanya, tanpa penjelasan.
    if (!e.budgetConfigured) return Right(hasil);

    if (e.survivalActive) {
      // T11 — FINAL. Tidak pernah di-upgrade jadi `active` di hari berikutnya;
      // yang menegakkannya adalah langkah 2 di atas.
      final r = await _repo.holdWeek(mingguIni);
      return r.map((_) => hasil);
    }

    final pilihan = kandidat.first; // sudah deterministik (T17 aturan 1)
    final r = await _repo.createChallenge(
      weekKey: mingguIni,
      category: pilihan.category,
      targetAmount: pilihan.target,
      baselineAmount: pilihan.baseline,
    );
    return r.map((_) => hasil);
  }

  /// Kategori yang tak terbaca diperlakukan seperti lenyap (set kosong):
  /// jalurnya (`skipped`) memang jalur yang tidak menghukum.
  Future<Set<String>> _slugKategoriYangMasihAda() async {
    final hasil = await _getLimitable(const NoParams());
    return hasil.fold(
      (_) => <String>{},
      (categories) => categories.map((c) => c.slug).toSet(),
    );
  }
}
