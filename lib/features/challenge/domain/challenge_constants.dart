/// Seluruh angka fitur Tantangan Mingguan. Tidak boleh ada angka ajaib di luar
/// berkas ini (spec §3).
///
/// Berapa minggu penuh ke belakang yang membentuk basis (T2).
const int kBaselineWeeks = 4;

/// Minimal berapa dari [kBaselineWeeks] itu yang harus punya belanja (T3).
const int kMinBaselineWeeksWithData = 2;

/// Basis mingguan di bawah ini tidak layak ditantang: hemat 15% dari Rp 30.000
/// hanya Rp 4.500 (T3, O4 — sengaja satu baris agar mudah disetel).
const int kMinWeeklyBaseline = 50000;

/// Target = basis × rasio ini, lalu dibulatkan ke bawah (T4).
const double kTargetRatio = 0.85;

/// Kelipatan pembulatan target — selalu KE BAWAH (T4).
const int kRoundingStep = 5000;

/// Setelah sekian minggu berturut berhasil, kategori itu turun ke urutan
/// terakhir daftar kandidat — pengurutan, bukan larangan (T5).
const int kRotationWins = 3;

/// Berapa kandidat yang disodorkan ke user (T3).
const int kMaxCandidates = 3;

/// Jendela tarikan riwayat sekaligus panjang daftar riwayat (O6).
const int kChallengeHistoryWeeks = 12;

/// Berapa varian kalimat per status di bank lokal (Task 18).
///
/// Delapan, bukan lima: dengan lima varian, user yang berhasil delapan minggu
/// berturut sudah melihat kalimat berulang sebelum kuartal berakhir. Bank
/// lokal adalah SATU-SATUNYA jalur kalimat di fase ini (Keputusan 2), jadi
/// variasinya harus menanggung beban itu sendirian.
const int kBankVariants = 8;

/// Batas panjang satu kalimat bank (§6). Ditegakkan test U100.
const int kMaxCopyChars = 120;

/// Anggaran waktu membaca ChallengeEnvironmentPort. Habis = keadaan tak
/// diketahui, dan keadaan tak diketahui TIDAK PERNAH menulis baris (T11).
const Duration kEnvReadTimeout = Duration(seconds: 3);
