part of 'profile_setup_cubit.dart';

class ProfileSetupState extends Equatable {
  const ProfileSetupState({
    this.subStep = 0, // 0 = identitas, 1 = lokasi
    this.language = 'id',
    this.displayName,
    this.status,
    this.currentCountry = 'ID',
    this.currentCity,
    this.timezone = 'Asia/Jakarta',
    this.isPerantau = false,
    this.homeCountry = 'ID',
    this.homeCity,
    this.saving = false,
    this.saved = false,
    this.error,
  });

  final int subStep;
  final String language;
  final String? displayName;
  final String? status;
  final String currentCountry;
  final String? currentCity;
  final String timezone;
  final bool isPerantau;
  final String homeCountry;
  final String? homeCity;
  final bool saving;
  final bool saved;
  final String? error;

  ProfileSetupState copyWith({
    int? subStep,
    String? language,
    String? displayName,
    String? status,
    String? currentCountry,
    String? currentCity,
    bool clearCurrentCity = false,
    String? timezone,
    bool? isPerantau,
    String? homeCountry,
    String? homeCity,
    bool clearHomeCity = false,
    bool? saving,
    bool? saved,
    String? error,
  }) {
    return ProfileSetupState(
      subStep: subStep ?? this.subStep,
      language: language ?? this.language,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
      currentCountry: currentCountry ?? this.currentCountry,
      currentCity: clearCurrentCity ? null : (currentCity ?? this.currentCity),
      timezone: timezone ?? this.timezone,
      isPerantau: isPerantau ?? this.isPerantau,
      homeCountry: homeCountry ?? this.homeCountry,
      homeCity: clearHomeCity ? null : (homeCity ?? this.homeCity),
      saving: saving ?? this.saving,
      saved: saved ?? this.saved,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        subStep, language, displayName, status, currentCountry, currentCity,
        timezone, isPerantau, homeCountry, homeCity, saving, saved, error,
      ];
}
