/// Hari mulai dihitungnya riwayat Konsistensi, sebagai INT yyyymmdd.
///
/// SEMUA user mulai dari nol pada hari ini — tidak ada backfill riwayat
/// transaksi (keputusan produk K11). Hari sebelum nilai ini tidak pernah ikut
/// dihitung; filternya konstanta, bukan scan riwayat.
///
/// BEKU SETELAH MERGE. Mengubahnya menulis ulang riwayat SEMUA user sekaligus:
/// hari yang tadinya aman berubah jadi `beforeStart`, ruas panjang terpotong,
/// dan tidak ada jalan memulihkannya. Nilai final diisi tanggal merge A4 ke
/// `main` sebagai langkah terakhir sebelum merge (Task 18).
const int kStreakEpochDay = 20260902;
