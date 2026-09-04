sealed class StreakEvent {}

/// Dikirim tiap kali rute `/dashboard` atau `/consistency` dibangun.
final class StreakSubscribed extends StreakEvent {}

/// Timer tengah malam, `didChangeAppLifecycleState(resumed)`, dan
/// `BootstrapCoordinator.onComplete`.
final class StreakRefreshed extends StreakEvent {}

final class StreakTodayMarked extends StreakEvent {}

final class StreakTodayMarkUndone extends StreakEvent {}

final class StreakMilestoneShown extends StreakEvent {
  StreakMilestoneShown(this.ruas);
  final int ruas;
}

final class StreakBreakAcknowledged extends StreakEvent {}

/// INTERNAL — dikirim timer, tidak pernah oleh UI. Melepaskan `restoring`
/// yang menunggu bootstrap yang mungkin tidak akan pernah selesai (S6).
final class StreakRestoringTimedOut extends StreakEvent {}
