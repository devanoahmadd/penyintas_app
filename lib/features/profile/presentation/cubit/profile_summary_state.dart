part of 'profile_summary_cubit.dart';

class ProfileSummaryState extends Equatable {
  const ProfileSummaryState({this.loading = true, this.prefs});
  final bool loading;
  final PreferencesEntity? prefs;

  @override
  List<Object?> get props => [loading, prefs];
}
