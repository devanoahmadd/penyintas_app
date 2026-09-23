import 'package:flutter/material.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/utils/date_helper.dart';
import 'package:penyintas_app/features/challenge/domain/challenge_constants.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';

/// Pilih satu kalimat penyemangat dari bank lokal berdasarkan status & weekKey.
///
/// Bank berisi 8 varian per status (active, achieved, missed), dipilih secara
/// **deterministik** dari weekKey menggunakan ordinal minggu.
///
/// Ordinal minggu: berapa minggu telah lewat sejak Senin epoch (1970-01-05).
/// Dengan ordinal minggu—bukan hash atas weekKey—kita menjamin:
/// - Tidak ada pengulangan dalam 8 minggu berturut (maksimum teoretis untuk 8 varian)
/// - Varian berputar **tepat satu** tiap minggu, bukan melompat-lompat
///
/// Contoh: Delapan Senin berturut (2026-09-07 hingga 2026-10-26) menghasilkan
/// ordinal minggu [5, 6, 7, 8, 9, 10, 11, 12] → indeks varian [5, 6, 7, 0, 1, 2, 3, 4]
/// (semua 8 unik). Dengan hash Fibonacci atas weekKey, hasilnya hanya [3, 2, 1, 0, 5, 4, 3, 2]
/// (6 unik + pengulangan di minggu 1 dan 7).
///
/// Status `held`, `skipped`, `unknown` mengembalikan string kosong — kartu hasil
/// tidak dirender untuk status itu.
String challengeBankLine(
  BuildContext context, {
  required ChallengeStatus status,
  required int weekKey,
}) {
  // Status yang tidak menampilkan kartu hasil
  if (status == ChallengeStatus.held ||
      status == ChallengeStatus.skipped ||
      status == ChallengeStatus.unknown) {
    return '';
  }

  final variantIndex = _indeksVarian(weekKey);
  final variantNumber = variantIndex + 1; // 1-indexed untuk key

  final statusName = _statusToKeyName(status);
  final key = 'challenge_bank_${statusName}_$variantNumber';

  return _getLocalizedString(context, key);
}

/// Ordinal minggu: berapa minggu sejak Senin epoch (1970-01-05).
///
/// weekKey adalah yyyymmdd Senin, jadi pembagian selalu pas.
/// Epoch dipilih sebagai Senin (1970-01-05, bukan 1970-01-01 Kamis)
/// agar pembagian minggu selalu bulat.
int _ordinalMinggu(int weekKey) {
  final dt = localMidnightOf(weekKey);
  final epochSenin = DateTime(1970, 1, 5); // Senin pertama epoch
  final hari = dt.difference(epochSenin).inDays;
  return hari ~/ 7;
}

/// Indeks varian (0-7) untuk weekKey.
///
/// Menggunakan ordinal minggu, bukan hash:
/// - Hash memberi 6 dari 8 unik pada 8 Senin berturut (pengulangan di minggu 1 & 7)
/// - Ordinal memberi 8 dari 8 unik (maksimum teoretis), pengulangan pertama tepat minggu ke-9
int _indeksVarian(int weekKey) => _ordinalMinggu(weekKey) % kBankVariants;

/// Konversi ChallengeStatus ke nama key (untuk URL JSON).
String _statusToKeyName(ChallengeStatus status) {
  return switch (status) {
    ChallengeStatus.active => 'active',
    ChallengeStatus.achieved => 'achieved',
    ChallengeStatus.missed => 'missed',
    _ => '', // held, skipped, unknown sudah disaring di atas
  };
}

/// Ambil string terlokalisasi dari context dengan fallback.
String _getLocalizedString(BuildContext context, String key) {
  final l10n = context.l10n;
  return switch (key) {
    // Active — 8 varian
    'challenge_bank_active_1' => l10n.challengeBankActive1,
    'challenge_bank_active_2' => l10n.challengeBankActive2,
    'challenge_bank_active_3' => l10n.challengeBankActive3,
    'challenge_bank_active_4' => l10n.challengeBankActive4,
    'challenge_bank_active_5' => l10n.challengeBankActive5,
    'challenge_bank_active_6' => l10n.challengeBankActive6,
    'challenge_bank_active_7' => l10n.challengeBankActive7,
    'challenge_bank_active_8' => l10n.challengeBankActive8,

    // Achieved — 8 varian
    'challenge_bank_achieved_1' => l10n.challengeBankAchieved1,
    'challenge_bank_achieved_2' => l10n.challengeBankAchieved2,
    'challenge_bank_achieved_3' => l10n.challengeBankAchieved3,
    'challenge_bank_achieved_4' => l10n.challengeBankAchieved4,
    'challenge_bank_achieved_5' => l10n.challengeBankAchieved5,
    'challenge_bank_achieved_6' => l10n.challengeBankAchieved6,
    'challenge_bank_achieved_7' => l10n.challengeBankAchieved7,
    'challenge_bank_achieved_8' => l10n.challengeBankAchieved8,

    // Missed — 8 varian
    'challenge_bank_missed_1' => l10n.challengeBankMissed1,
    'challenge_bank_missed_2' => l10n.challengeBankMissed2,
    'challenge_bank_missed_3' => l10n.challengeBankMissed3,
    'challenge_bank_missed_4' => l10n.challengeBankMissed4,
    'challenge_bank_missed_5' => l10n.challengeBankMissed5,
    'challenge_bank_missed_6' => l10n.challengeBankMissed6,
    'challenge_bank_missed_7' => l10n.challengeBankMissed7,
    'challenge_bank_missed_8' => l10n.challengeBankMissed8,

    _ => '',
  };
}
