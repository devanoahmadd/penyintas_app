import 'package:equatable/equatable.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_snapshot.dart';
import 'package:penyintas_app/features/challenge/domain/entities/ensure_outcome.dart';

/// SENGAJA bukan `ChallengeStatus` — itu milik BARIS minggu (Task 1). Dua enum
/// sebernama di satu fitur adalah sumber bug impor yang senyap: `ready` dan
/// `active` kebetulan sama-sama masuk akal di kedua tempat.
enum ChallengeViewStatus { initial, loading, ready, failure }

class ChallengeState extends Equatable {
  const ChallengeState({
    this.status = ChallengeViewStatus.initial,
    this.snapshot,
    this.failure,
    this.lastEnsuredWeekKey,
    this.lastOutcome,
  });

  final ChallengeViewStatus status;

  /// Satu-satunya bentuk yang dirender tile dashboard DAN halaman (S1).
  final ChallengeSnapshot? snapshot;

  final Failure? failure;

  /// Penjaga titik-3 (§4): satu weekKey = SATU panggilan ensure, dari jalur
  /// mana pun ia datang (stream maupun resume). Disimpan di state — bukan di
  /// field privat — supaya penjaganya ikut terbaca test dan ikut terbawa
  /// `copyWith` yang sama dengan sisa keadaan.
  final int? lastEnsuredWeekKey;

  /// S-B — apa yang ensure sempat ketahui pada panggilan terakhirnya.
  /// `weekKey`-nya BUKAN hiasan: perakit phase memperlakukan outcome dari
  /// minggu lain sebagai tak diketahui.
  final EnsureOutcome? lastOutcome;

  ChallengeState copyWith({
    ChallengeViewStatus? status,
    ChallengeSnapshot? snapshot,
    Failure? failure,
    bool clearFailure = false,
    int? lastEnsuredWeekKey,
    EnsureOutcome? lastOutcome,
  }) => ChallengeState(
    status: status ?? this.status,
    snapshot: snapshot ?? this.snapshot,
    failure: clearFailure ? null : (failure ?? this.failure),
    lastEnsuredWeekKey: lastEnsuredWeekKey ?? this.lastEnsuredWeekKey,
    lastOutcome: lastOutcome ?? this.lastOutcome,
  );

  @override
  List<Object?> get props => [
    status,
    snapshot,
    failure,
    lastEnsuredWeekKey,
    lastOutcome,
  ];
}
