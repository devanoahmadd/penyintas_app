import 'dart:convert';

/// Batas panjang kolom `timezone` di dokumen Firestore — cermin
/// `timezone.size() <= 64` pada blok `challenges` dan `streak_marks` di
/// `firestore.rules`. Diukur dalam BYTE UTF-8, tafsiran terketat atas
/// `size()`, jadi aman apa pun cara rules menghitungnya.
const int kMaxZonaAuditBytes = 64;

/// Jejak audit zona waktu device saat sebuah baris DIBUAT (Tantangan dan
/// Streak). MURNI audit: tak pernah dibaca logika mana pun di app.
///
/// Bentuknya singkatan device ("WIB", "+07"), bukan id IANA — diputuskan
/// pemilik repo 2026-09-24 (butir 6): kolom ini tak punya pembaca, jadi
/// biaya IANA (kopling ke inisialisasi paket timezone lapisan notifikasi)
/// maupun kolom offset terpisah (bump schema) belum sepadan.
///
/// Nama kosong jatuh ke offset UTC; nama kepanjangan dipotong. Keduanya akan
/// DITOLAK rules, dan penolakan itu senyap — baris mengendap di antrian tanpa
/// satu pun pesan ke user.
String zonaAudit(String namaZona, Duration offsetUtc) {
  if (namaZona.isNotEmpty) return _potong(namaZona);
  final menit = offsetUtc.inMinutes;
  final tanda = menit < 0 ? '-' : '+';
  final jam = (menit.abs() ~/ 60).toString().padLeft(2, '0');
  final sisa = (menit.abs() % 60).toString().padLeft(2, '0');
  return 'UTC$tanda$jam:$sisa';
}

/// Gerbang KELUAR — dipanggil dari `toFirestore()` tiap model, sehingga
/// setiap jalur kirim (unggah langsung, `SyncQueue`, dorongan tertunda)
/// melewati penjaga yang sama, termasuk baris yang tidak lahir lewat
/// [zonaAudit] (mis. tarikan dokumen cloud yang tak lengkap).
///
/// Kosong → `'UTC'`: zona aslinya sudah tak diketahui, dan mengisinya dengan
/// offset device SAAT INI bisa keliru. Sama dengan fallback
/// `StreakMarkModel.fromFirestore`.
String zonaSiapKirim(String tersimpan) =>
    tersimpan.isEmpty ? 'UTC' : _potong(tersimpan);

/// Potong per karakter Unicode utuh sampai muat [kMaxZonaAuditBytes] byte
/// UTF-8. `substring` per unit UTF-16 bisa membelah surrogate pair (emoji)
/// dan menghasilkan string rusak.
String _potong(String s) {
  if (utf8.encode(s).length <= kMaxZonaAuditBytes) return s;
  final hasil = StringBuffer();
  var bytes = 0;
  for (final rune in s.runes) {
    final ch = String.fromCharCode(rune);
    final n = utf8.encode(ch).length;
    if (bytes + n > kMaxZonaAuditBytes) break;
    hasil.write(ch);
    bytes += n;
  }
  return hasil.toString();
}
