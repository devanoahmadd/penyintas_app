import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Hash PIN salted SHA-256. Bukan PBKDF2 — threat model App Lock mengecualikan
/// ekstraksi hash (hash tinggal di OS secure storage), jadi key-stretching tak
/// menambah proteksi yang diklaim. Lihat spec §4 & §15.
class PinHasher {
  static String generateSalt([Random? rng]) {
    final r = rng ?? Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    return base64Encode(bytes);
  }

  static String hash(String pin, String saltB64) {
    final salt = base64Decode(saltB64);
    final data = <int>[...salt, ...utf8.encode(pin)];
    return base64Encode(sha256.convert(data).bytes);
  }

  /// Bandingkan constant-time untuk hindari timing leak.
  static bool verify(String pin, String saltB64, String expectedHashB64) {
    final actual = hash(pin, saltB64);
    if (actual.length != expectedHashB64.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual.codeUnitAt(i) ^ expectedHashB64.codeUnitAt(i);
    }
    return diff == 0;
  }
}
