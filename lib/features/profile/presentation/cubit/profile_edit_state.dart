part of 'profile_edit_cubit.dart';

class ProfileEditState extends Equatable {
  const ProfileEditState({
    this.loading = true,
    this.draft,
    this.loaded,
    this.currentLocationResolved = true,
    this.saving = false,
    this.saved = false,
    this.error,
  });

  final bool loading;
  final PreferencesEntity? draft;
  final PreferencesEntity? loaded; // M3: baseline immutable utk dirty-check
  final bool
  currentLocationResolved; // H2: false setelah ganti negara s/d kota/tz dipilih
  final bool saving;
  final bool saved;
  final String? error;

  /// M3: ada perubahan belum disimpan? (PreferencesEntity Equatable → `!=` akurat)
  bool get isDirty => draft != null && draft != loaded;

  ProfileEditState copyWith({
    bool? loading,
    PreferencesEntity? draft,
    PreferencesEntity? loaded,
    bool? currentLocationResolved,
    bool? saving,
    bool? saved,
    String? error, // sengaja tanpa `?? this` — copyWith mengosongkan error
  }) => ProfileEditState(
    loading: loading ?? this.loading,
    draft: draft ?? this.draft,
    loaded: loaded ?? this.loaded,
    currentLocationResolved:
        currentLocationResolved ?? this.currentLocationResolved,
    saving: saving ?? this.saving,
    saved: saved ?? this.saved,
    error: error,
  );

  @override
  List<Object?> get props => [
    loading,
    draft,
    loaded,
    currentLocationResolved,
    saving,
    saved,
    error,
  ];
}
