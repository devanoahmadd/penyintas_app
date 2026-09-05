/// Hari mulai dihitungnya riwayat Konsistensi, sebagai INT yyyymmdd.
///
/// SEMUA user mulai dari nol pada hari ini — tidak ada backfill riwayat
/// transaksi (keputusan produk K11). Hari sebelum nilai ini tidak pernah ikut
/// dihitung; filternya konstanta, bukan scan riwayat.
///
/// BEKU SETELAH MERGE. Mengubahnya menulis ulang riwayat SEMUA user sekaligus:
/// hari yang tadinya aman berubah jadi `beforeStart`, ruas panjang terpotong,
/// dan tidak ada jalan memulihkannya.
///
/// BAHAYANYA ASIMETRIS — pahami arahnya sebelum menyentuh nilai ini. Konstanta
/// ini batas bawah MUTLAK penarikan penanda (lihat `streak_repository_impl`).
/// Nilai yang LEBIH AWAL dari tanggal rilis hanya melebarkan jendela tarikan:
/// tidak ada data yang hilang, karena tidak ada penanda apa pun sebelum fitur
/// ini hidup. Nilai yang LEBIH BELAKANGAN dari tanggal rilis membuang penanda
/// nyata milik user, permanen.
///
/// Karena itu isinya tanggal penyelesaian gerbang akhir (2026-09-06), bukan
/// tanggal merge yang belum diketahui: ia dijamin <= tanggal merge, jadi ia
/// selalu berada di sisi yang aman. Pemilik repo boleh menaikkannya sampai
/// tanggal merge sesungguhnya bila merge mundur — TAPI JANGAN PERNAH
/// MELEWATINYA.
const int kStreakEpochDay = 20260906;
