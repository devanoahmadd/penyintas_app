import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';
import 'package:penyintas_app/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:penyintas_app/features/profile/presentation/cubit/profile_summary_cubit.dart';

class _MockRepo extends Mock implements PreferencesRepository {}

void main() {
  test('memuat preferences saat dibuat & refresh()', () async {
    final repo = _MockRepo();
    when(() => repo.read()).thenAnswer(
        (_) async => PreferencesEntity.defaults.copyWith(displayName: 'Devano'));
    final c = ProfileSummaryCubit(repo);
    await Future<void>.delayed(Duration.zero);
    expect(c.state.loading, false);
    expect(c.state.prefs!.displayName, 'Devano');

    when(() => repo.read()).thenAnswer(
        (_) async => PreferencesEntity.defaults.copyWith(displayName: 'Baru'));
    await c.refresh();
    expect(c.state.prefs!.displayName, 'Baru');
  });
}
