import 'package:penyintas_app/features/streak/domain/entities/streak_snapshot.dart';
import 'package:penyintas_app/features/streak/domain/repositories/streak_repository.dart';

class WatchStreakSnapshotUseCase {
  const WatchStreakSnapshotUseCase(this._repository);
  final StreakRepository _repository;
  Stream<StreakSnapshot> call() => _repository.watchSnapshot();
}
