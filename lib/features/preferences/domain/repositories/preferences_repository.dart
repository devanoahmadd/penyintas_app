import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';

abstract class PreferencesRepository {
  /// Local-first; kembalikan defaults bila belum ada.
  Future<PreferencesEntity> read();

  /// Tulis local (canonical) lalu mirror Firestore best-effort (non-fatal).
  Future<Either<Failure, Unit>> save(PreferencesEntity prefs);
}
