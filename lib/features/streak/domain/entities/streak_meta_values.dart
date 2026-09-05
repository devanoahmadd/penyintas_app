import 'package:equatable/equatable.dart';

/// Isi tabel `streak_meta` sebagai nilai domain.
///
/// SELURUH isinya boleh hilang tanpa merusak streak — `clearAllLocalData()`
/// menyapunya saat logout dan tidak membuatnya ulang. Karena itu [empty]
/// adalah keadaan sah, bukan galat.
class StreakMetaValues extends Equatable {
  const StreakMetaValues({
    required this.lastSeenDay,
    required this.maxSeenDay,
    required this.lastCelebratedRuas,
    required this.clockAnomalyCount,
    required this.acknowledgedBreakDay,
  });

  static const empty = StreakMetaValues(
    lastSeenDay: 0,
    maxSeenDay: 0,
    lastCelebratedRuas: 0,
    clockAnomalyCount: 0,
    acknowledgedBreakDay: 0,
  );

  final int lastSeenDay;

  /// Hari tertinggi yang pernah dilihat. HANYA NAIK — tidak pernah diturunkan
  /// oleh cabang koreksi jam.
  final int maxSeenDay;

  final int lastCelebratedRuas;
  final int clockAnomalyCount;
  final int acknowledgedBreakDay;

  StreakMetaValues copyWith({
    int? lastSeenDay,
    int? maxSeenDay,
    int? lastCelebratedRuas,
    int? clockAnomalyCount,
    int? acknowledgedBreakDay,
  }) => StreakMetaValues(
    lastSeenDay: lastSeenDay ?? this.lastSeenDay,
    maxSeenDay: maxSeenDay ?? this.maxSeenDay,
    lastCelebratedRuas: lastCelebratedRuas ?? this.lastCelebratedRuas,
    clockAnomalyCount: clockAnomalyCount ?? this.clockAnomalyCount,
    acknowledgedBreakDay: acknowledgedBreakDay ?? this.acknowledgedBreakDay,
  );

  @override
  List<Object?> get props => [
    lastSeenDay,
    maxSeenDay,
    lastCelebratedRuas,
    clockAnomalyCount,
    acknowledgedBreakDay,
  ];
}
