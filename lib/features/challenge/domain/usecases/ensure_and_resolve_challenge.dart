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
/// Task 10 baru mengisi langkah 1 dan 1c (menutup minggu lampau, merapikan
/// hasil lama). Langkah 2–6 (pembuatan tantangan baru, yang butuh `env` dan
/// `settings`) menyusul di Task 11 — karena itu `env` dan `settings` DITERIMA
/// di constructor (mengunci bentuk kontrak untuk Task 11) tapi BELUM disimpan
/// ke field: menyimpannya sekarang tanpa pernah dibaca memicu warning
/// `unused_field` dari `dart analyze`, dan codebase ini tidak punya preseden
/// `// ignore:` untuk melewatinya.
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
       _clock = clock;

  final ChallengeRepository _repo;
  final ChallengeLocalDatasource _local;
  final GetLimitableCategoriesUseCase _getLimitable;
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
    final belumDilihat = await _local.watchHistory(kChallengeHistoryWeeks).first;
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

    // langkah 2–6 ditambahkan di Task 11
    return Right(keluar());
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
