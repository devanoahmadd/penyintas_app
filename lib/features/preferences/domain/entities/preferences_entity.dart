import 'package:equatable/equatable.dart';

/// Preferences user — sumber kebenaran timezone/language/profil.
/// Currency Spec 1 = IDR (base/home tak diubah user; UX currency → Spec 2).
class PreferencesEntity extends Equatable {
  const PreferencesEntity({
    required this.timezone,
    required this.baseCurrency,
    required this.homeCurrency,
    required this.language,
    this.displayName,
    this.status,
    required this.currentCountry,
    this.currentCity,
    required this.homeCountry,
    this.homeCity,
    required this.isPerantau,
    required this.profileCompleted,
    this.schemaVersion = 1,
  });

  final String timezone; // IANA
  final String baseCurrency; // ISO 4217 (Spec 1: 'IDR')
  final String homeCurrency; // ISO 4217 (Spec 1: 'IDR')
  final String language; // 'id' | 'en'
  final String? displayName;
  final String? status; // 'student' | 'worker'
  final String currentCountry; // ISO 3166-1 alpha-2
  final String? currentCity;
  final String homeCountry;
  final String? homeCity;
  final bool isPerantau;
  final bool profileCompleted;
  final int schemaVersion; // versi format dokumen (≠ Drift schemaVersion)

  static const defaults = PreferencesEntity(
    timezone: 'Asia/Jakarta',
    baseCurrency: 'IDR',
    homeCurrency: 'IDR',
    language: 'id',
    currentCountry: 'ID',
    homeCountry: 'ID',
    isPerantau: false,
    profileCompleted: false,
  );

  PreferencesEntity copyWith({
    String? timezone,
    String? baseCurrency,
    String? homeCurrency,
    String? language,
    String? displayName,
    String? status,
    String? currentCountry,
    String? currentCity,
    String? homeCountry,
    String? homeCity,
    bool? isPerantau,
    bool? profileCompleted,
    int? schemaVersion,
  }) {
    return PreferencesEntity(
      timezone: timezone ?? this.timezone,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      homeCurrency: homeCurrency ?? this.homeCurrency,
      language: language ?? this.language,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
      currentCountry: currentCountry ?? this.currentCountry,
      currentCity: currentCity ?? this.currentCity,
      homeCountry: homeCountry ?? this.homeCountry,
      homeCity: homeCity ?? this.homeCity,
      isPerantau: isPerantau ?? this.isPerantau,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  @override
  List<Object?> get props => [
        timezone, baseCurrency, homeCurrency, language, displayName, status,
        currentCountry, currentCity, homeCountry, homeCity, isPerantau,
        profileCompleted, schemaVersion,
      ];
}
