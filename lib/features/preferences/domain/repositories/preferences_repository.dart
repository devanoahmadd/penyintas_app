import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';

abstract class PreferencesRepository {
  /// Local-first; kembalikan defaults bila belum ada.
  Future<PreferencesEntity> read();

  /// Tulis local (canonical) lalu mirror Firestore best-effort (non-fatal).
  Future<Either<Failure, Unit>> save(PreferencesEntity prefs);

  /// Bootstrap saat launch/login (A2/§5): pulihkan profil dari remote saat local
  /// belum selesai (reinstall/ganti-device), smart-default akun lama (§9), lalu
  /// mirror best-effort. **Non-fatal** (selalu `Right`); kegagalan → guard fail-safe
  /// `needsProfile`. Dipanggil splash SEBELUM redirect.
  /// [budgetOnboardingCompleted] = `onboardingCompleted` (budget) — sinyal akun lama.
  Future<Either<Failure, Unit>> syncOnLaunch({
    required bool budgetOnboardingCompleted,
  });
}
