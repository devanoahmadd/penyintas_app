import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/utils/audit_timezone.dart';

void main() {
  group('zonaAudit · jejak audit zona waktu saat baris dibuat', () {
    test('nama zona device dipakai APA ADANYA', () {
      // Singkatan device, bukan id IANA — bentuk yang sama di Tantangan dan
      // Streak (butir 6: format tidak diubah).
      expect(zonaAudit('WIB', const Duration(hours: 7)), 'WIB');
      expect(zonaAudit('+07', const Duration(hours: 7)), '+07');
    });

    test('nama zona KOSONG jatuh ke offset UTC — tak pernah string kosong', () {
      // `firestore.rules` menuntut `timezone.size() > 0`. String kosong membuat
      // dokumennya ditolak: dorongan gagal diam-diam tanpa pesan ke user.
      expect(zonaAudit('', const Duration(hours: 7)), 'UTC+07:00');
      expect(zonaAudit('', const Duration(hours: 5, minutes: 30)), 'UTC+05:30');
      expect(zonaAudit('', const Duration(hours: -8)), 'UTC-08:00');
      expect(zonaAudit('', Duration.zero), 'UTC+00:00');
    });

    test('nama zona lebih dari batas dipotong — rules menolak > 64', () {
      final hasil = zonaAudit('x' * 100, const Duration(hours: 7));
      expect(hasil, 'x' * kMaxZonaAuditBytes);
    });
  });

  group('zonaSiapKirim · gerbang keluar sebelum Firestore', () {
    test('nilai sah diteruskan utuh', () {
      expect(zonaSiapKirim('WIB'), 'WIB');
      expect(zonaSiapKirim('x' * kMaxZonaAuditBytes), 'x' * kMaxZonaAuditBytes);
    });

    test('kosong → "UTC" (preseden StreakMarkModel.fromFirestore)', () {
      // Baris lokal bisa berisi '' lewat tarikan dokumen cloud yang tak
      // lengkap. Zona aslinya tak diketahui lagi, jadi yang dikirim penanda
      // netral — bukan offset device SAAT INI yang bisa jadi keliru.
      expect(zonaSiapKirim(''), 'UTC');
    });

    test('lebih dari 64 byte dipotong', () {
      expect(zonaSiapKirim('y' * 65), 'y' * kMaxZonaAuditBytes);
    });

    test('karakter multi-byte TIDAK dibelah dan hasilnya <= 64 byte UTF-8', () {
      // `substring` per unit UTF-16 bisa membelah emoji (surrogate pair) jadi
      // string rusak. Batas diukur dalam byte UTF-8 — tafsiran terketat atas
      // `size()` di rules — jadi aman apa pun cara rules menghitungnya.
      final masukan = '${'a' * 62}😀😀';
      final hasil = zonaSiapKirim(masukan);
      expect(utf8.encode(hasil).length, lessThanOrEqualTo(kMaxZonaAuditBytes));
      expect(hasil, 'a' * 62); // emoji 4 byte tak muat utuh → dibuang utuh
      expect(() => utf8.encode(hasil), returnsNormally);
      expect(hasil.runes.every((r) => r < 0xD800 || r > 0xDFFF), isTrue);
    });
  });
}
