import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';

class PreferencesModel extends PreferencesEntity {
  const PreferencesModel({
    required super.timezone,
    required super.baseCurrency,
    required super.homeCurrency,
    required super.language,
    super.displayName,
    super.status,
    required super.currentCountry,
    super.currentCity,
    required super.homeCountry,
    super.homeCity,
    required super.isPerantau,
    required super.profileCompleted,
    super.schemaVersion,
  });

  factory PreferencesModel.fromEntity(PreferencesEntity e) => PreferencesModel(
        timezone: e.timezone,
        baseCurrency: e.baseCurrency,
        homeCurrency: e.homeCurrency,
        language: e.language,
        displayName: e.displayName,
        status: e.status,
        currentCountry: e.currentCountry,
        currentCity: e.currentCity,
        homeCountry: e.homeCountry,
        homeCity: e.homeCity,
        isPerantau: e.isPerantau,
        profileCompleted: e.profileCompleted,
        schemaVersion: e.schemaVersion,
      );

  // `fromFirestore` = trust-boundary (M1): rules hanya menjaga WRITE, dokumen lama /
  // ter-tamper bisa berisi nilai liar yang kalau lolos akan bocor ke locale `app.dart`.
  // Clamp ke nilai dikenal — JANGAN percaya remote mentah-mentah.
  static String _oneOf(String? v, Set<String> allowed, String fallback) =>
      allowed.contains(v) ? v! : fallback;
  static String? _oneOfOrNull(String? v, Set<String> allowed) =>
      allowed.contains(v) ? v : null;
  static String _clampCurrency(String? v) =>
      (v != null && v.length == 3) ? v : 'IDR';
  static String _clampCountry(String? v) =>
      (v != null && v.length == 2) ? v : 'ID';
  // T-2: ekstraksi string aman — dokumen lama/ter-tamper bisa menyimpan tipe salah
  // (mis. timezone:123). `as String?` pada non-string MELEMPAR (bukan null) → satu
  // field rusak menggugurkan SELURUH fetch. Kembalikan null bila bukan String.
  static String? _str(Object? v) => v is String ? v : null;

  factory PreferencesModel.fromFirestore(Map<String, dynamic> d) => PreferencesModel(
        // T-2: semua ekstraksi lewat `_str`/`is`-check — tak pernah `as` mentah yg bisa
        // melempar pada tipe salah (trust-boundary: dokumen lama/ter-tamper).
        timezone: (_str(d['timezone'])?.isNotEmpty ?? false)
            ? _str(d['timezone'])!
            : 'Asia/Jakarta',
        baseCurrency: _clampCurrency(_str(d['baseCurrency'])),
        homeCurrency: _clampCurrency(_str(d['homeCurrency'])),
        language: _oneOf(_str(d['language']), const {'id', 'en'}, 'id'),
        displayName: _str(d['displayName']),
        status: _oneOfOrNull(_str(d['status']), const {'student', 'worker'}),
        currentCountry: _clampCountry(_str(d['currentCountry'])),
        currentCity: _str(d['currentCity']),
        homeCountry: _clampCountry(_str(d['homeCountry'])),
        homeCity: _str(d['homeCity']),
        isPerantau: d['isPerantau'] is bool ? d['isPerantau'] as bool : false,
        profileCompleted:
            d['profileCompleted'] is bool ? d['profileCompleted'] as bool : false,
        schemaVersion:
            d['schemaVersion'] is num ? (d['schemaVersion'] as num).toInt() : 1,
      );

  /// Full-doc (no merge). `updatedAt` = serverTimestamp; field opsional null di-skip.
  Map<String, dynamic> toFirestore() => {
        'timezone': timezone,
        'baseCurrency': baseCurrency,
        'homeCurrency': homeCurrency,
        'language': language,
        if (displayName != null) 'displayName': displayName,
        if (status != null) 'status': status,
        'currentCountry': currentCountry,
        if (currentCity != null) 'currentCity': currentCity,
        'homeCountry': homeCountry,
        if (homeCity != null) 'homeCity': homeCity,
        'isPerantau': isPerantau,
        'profileCompleted': profileCompleted,
        'schemaVersion': schemaVersion,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
