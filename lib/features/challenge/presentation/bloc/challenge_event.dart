import 'package:equatable/equatable.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_snapshot.dart';

sealed class ChallengeEvent extends Equatable {
  const ChallengeEvent();

  @override
  List<Object?> get props => const [];
}

/// Dipasang di DUA tempat pada bloc singleton yang sama: scope dashboard dan
/// rute `/challenge`. Karena itu handler-nya WAJIB `restartable()` — lihat
/// catatan M4 di `challenge_bloc.dart`.
final class ChallengeStarted extends ChallengeEvent {
  const ChallengeStarted();
}

/// Bahan baru dari stream. Sengaja event, bukan `emit` langsung dari callback
/// stream: dengan begini tidak ada satu pun `emit` di luar handler terdaftar.
final class ChallengeInputsUpdated extends ChallengeEvent {
  const ChallengeInputsUpdated(this.inputs);

  final ChallengeInputs inputs;

  @override
  List<Object?> get props => [inputs];
}

/// Pasangan gagal [ChallengeInputsUpdated]. Ada karena aturan yang sama:
/// jalur galat pun tidak boleh meng-`emit` dari dalam callback stream.
final class ChallengeInputsFailed extends ChallengeEvent {
  const ChallengeInputsFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// M3 — app kembali dari background. Pergantian minggu yang terjadi selagi app
/// di background TIDAK mengubah satu tabel pun, jadi stream tak meng-emit dan
/// minggu lalu tak pernah ditutup sampai user kebetulan mencatat transaksi.
final class ChallengeAppResumed extends ChallengeEvent {
  const ChallengeAppResumed();
}

/// T7/T14 — ganti pos minggu berjalan. `weekKey` sengaja TIDAK dibawa event:
/// ia selalu minggu yang sedang berjalan menurut `AppClock`, dan sheet yang
/// terbuka melewati tengah malam Senin tidak boleh menulis ke minggu basi.
final class ChallengeCategoryChanged extends ChallengeEvent {
  const ChallengeCategoryChanged(this.category);

  final String category;

  @override
  List<Object?> get props => [category];
}

/// T15 — lewati minggu berjalan.
final class ChallengeWeekSkipped extends ChallengeEvent {
  const ChallengeWeekSkipped();
}

/// D11 — tombol ✕ di kartu hasil. `weekKey` WAJIB dibawa: kartu hasil bicara
/// tentang minggu LAMPAU, bukan minggu berjalan.
final class ChallengeResultDismissed extends ChallengeEvent {
  const ChallengeResultDismissed(this.weekKey);

  final int weekKey;

  @override
  List<Object?> get props => [weekKey];
}

/// T16 — sakelar fitur di Pengaturan.
final class ChallengeEnabledToggled extends ChallengeEvent {
  const ChallengeEnabledToggled(this.enabled);

  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}
