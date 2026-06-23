import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';
import 'package:penyintas_app/features/preferences/domain/repositories/preferences_repository.dart';

part 'profile_summary_state.dart';

/// Ringkasan profil read-only untuk header Saya hub.
/// [refresh] dipanggil setelah kembali dari editor agar header
/// langsung mutakhir tanpa perlu reload halaman.
class ProfileSummaryCubit extends Cubit<ProfileSummaryState> {
  ProfileSummaryCubit(this._repo) : super(const ProfileSummaryState()) {
    refresh();
  }

  final PreferencesRepository _repo;

  Future<void> refresh() async {
    try {
      final p = await _repo.read();
      if (!isClosed) emit(ProfileSummaryState(loading: false, prefs: p));
    } catch (_) {
      if (!isClosed) emit(const ProfileSummaryState(loading: false));
    }
  }
}
