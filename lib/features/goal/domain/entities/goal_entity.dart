import 'package:equatable/equatable.dart';

class GoalEntity extends Equatable {
  const GoalEntity({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    required this.targetDate,
    required this.isCompleted,
    required this.createdAt,
  });

  final int id;
  final String title;
  final int targetAmount;

  /// Computed — SUM(transactions WHERE goalId = id AND amount > 0).
  /// Tidak pernah disimpan di tabel Goals.
  final int savedAmount;

  final DateTime targetDate;
  final bool isCompleted;
  final DateTime createdAt;

  double get progressPercent =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  bool get isOverdue => !isCompleted && targetDate.isBefore(DateTime.now());

  GoalEntity copyWith({
    int? id,
    String? title,
    int? targetAmount,
    int? savedAmount,
    DateTime? targetDate,
    bool? isCompleted,
    DateTime? createdAt,
  }) => GoalEntity(
    id: id ?? this.id,
    title: title ?? this.title,
    targetAmount: targetAmount ?? this.targetAmount,
    savedAmount: savedAmount ?? this.savedAmount,
    targetDate: targetDate ?? this.targetDate,
    isCompleted: isCompleted ?? this.isCompleted,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    targetAmount,
    savedAmount,
    targetDate,
    isCompleted,
    createdAt,
  ];
}
