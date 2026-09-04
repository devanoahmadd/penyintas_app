import 'package:equatable/equatable.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/streak/domain/entities/streak_snapshot.dart';

enum StreakStatus { initial, loading, restoring, ready, failure }

/// `extends Equatable` WAJIB: tanpa itu setiap emisi dianggap state baru,
/// sehingga `StreakSubscribed` yang didispatch ulang tiap masuk rute
/// memancarkan state identik berulang kali dan seluruh tile/halaman rebuild
/// tanpa sebab. `StreakSnapshot` sudah Equatable, jadi perbandingannya dalam.
final class StreakState extends Equatable {
  const StreakState({
    this.status = StreakStatus.initial,
    this.snapshot,
    this.failure,
    this.pendingCelebration,
    this.unacknowledgedBreakRun,
    this.isMarking = false,
  });

  final StreakStatus status;
  final StreakSnapshot? snapshot;
  final Failure? failure;

  /// Ruas yang baru tercapai dan BELUM ditampilkan. Dikonsumsi BlocListener
  /// lewat `StreakMilestoneShown`, bukan builder — lihat catatan sekali-pakai
  /// di `StreakBloc._onMilestoneShown`.
  final int? pendingCelebration;

  /// Panjang ruas yang putus dan belum diakui user. null = tidak ada.
  final int? unacknowledgedBreakRun;

  /// Guard tap-ganda CTA (constraint PK dayKey).
  final bool isMarking;

  StreakState copyWith({
    StreakStatus? status,
    StreakSnapshot? snapshot,
    Failure? failure,
    bool clearFailure = false,
    int? pendingCelebration,
    bool clearCelebration = false,
    int? unacknowledgedBreakRun,
    bool clearBreak = false,
    bool? isMarking,
  }) => StreakState(
    status: status ?? this.status,
    snapshot: snapshot ?? this.snapshot,
    failure: clearFailure ? null : (failure ?? this.failure),
    pendingCelebration: clearCelebration
        ? null
        : (pendingCelebration ?? this.pendingCelebration),
    unacknowledgedBreakRun: clearBreak
        ? null
        : (unacknowledgedBreakRun ?? this.unacknowledgedBreakRun),
    isMarking: isMarking ?? this.isMarking,
  );

  @override
  List<Object?> get props => [
    status,
    snapshot,
    failure,
    pendingCelebration,
    unacknowledgedBreakRun,
    isMarking,
  ];
}
