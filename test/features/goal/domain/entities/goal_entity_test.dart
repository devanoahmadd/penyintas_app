import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/goal/domain/entities/goal_entity.dart';

void main() {
  final baseDate = DateTime(2026, 12, 31);
  final pastDate = DateTime(2026, 1, 1);
  final createdAt = DateTime(2026, 5, 21);

  GoalEntity makeGoal({
    int id = 1,
    String title = 'Pulang kampung',
    int targetAmount = 1000000,
    int savedAmount = 0,
    DateTime? targetDate,
    bool isCompleted = false,
  }) =>
      GoalEntity(
        id: id,
        title: title,
        targetAmount: targetAmount,
        savedAmount: savedAmount,
        targetDate: targetDate ?? baseDate,
        isCompleted: isCompleted,
        createdAt: createdAt,
      );

  group('GoalEntity.progressPercent', () {
    test('returns 0 when savedAmount is 0', () {
      final goal = makeGoal(targetAmount: 1000000, savedAmount: 0);
      expect(goal.progressPercent, 0.0);
    });

    test('returns 0.5 when halfway saved', () {
      final goal = makeGoal(targetAmount: 1000000, savedAmount: 500000);
      expect(goal.progressPercent, 0.5);
    });

    test('returns 1.0 when fully saved', () {
      final goal = makeGoal(targetAmount: 1000000, savedAmount: 1000000);
      expect(goal.progressPercent, 1.0);
    });

    test('clamps to 1.0 when savedAmount exceeds target', () {
      final goal = makeGoal(targetAmount: 1000000, savedAmount: 1500000);
      expect(goal.progressPercent, 1.0);
    });

    test('returns 0 when targetAmount is 0 (guard division by zero)', () {
      final goal = makeGoal(targetAmount: 0, savedAmount: 0);
      expect(goal.progressPercent, 0.0);
    });
  });

  group('GoalEntity.isOverdue', () {
    test('returns false when not completed and targetDate is in the future', () {
      final goal = makeGoal(isCompleted: false, targetDate: baseDate);
      expect(goal.isOverdue, false);
    });

    test('returns true when not completed and targetDate is in the past', () {
      final goal = makeGoal(isCompleted: false, targetDate: pastDate);
      expect(goal.isOverdue, true);
    });

    test('returns false when completed even if targetDate is past', () {
      final goal =
          makeGoal(isCompleted: true, targetDate: pastDate);
      expect(goal.isOverdue, false);
    });
  });

  group('GoalEntity.copyWith', () {
    test('copies with updated title', () {
      final goal = makeGoal();
      final copy = goal.copyWith(title: 'Beli laptop');
      expect(copy.title, 'Beli laptop');
      expect(copy.id, goal.id);
      expect(copy.targetAmount, goal.targetAmount);
    });

    test('copies with updated savedAmount', () {
      final goal = makeGoal(savedAmount: 0);
      final copy = goal.copyWith(savedAmount: 250000);
      expect(copy.savedAmount, 250000);
      expect(copy.progressPercent, 0.25);
    });

    test('copies with isCompleted true', () {
      final goal = makeGoal(isCompleted: false);
      final copy = goal.copyWith(isCompleted: true);
      expect(copy.isCompleted, true);
      expect(copy.isOverdue, false);
    });
  });

  group('GoalEntity equality (Equatable)', () {
    test('two goals with same fields are equal', () {
      final g1 = makeGoal(id: 1, savedAmount: 500000);
      final g2 = makeGoal(id: 1, savedAmount: 500000);
      expect(g1, equals(g2));
    });

    test('goals with different savedAmount are not equal', () {
      final g1 = makeGoal(savedAmount: 0);
      final g2 = makeGoal(savedAmount: 100000);
      expect(g1, isNot(equals(g2)));
    });
  });
}
