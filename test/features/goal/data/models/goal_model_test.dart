import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/goal/data/models/goal_model.dart';

void main() {
  final tModel = GoalModel(
    firestoreId: 'fid-123',
    title: 'Pulang kampung',
    targetAmount: 1500000,
    targetDate: DateTime.fromMillisecondsSinceEpoch(1798675200000),
    isCompleted: false,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1751700000000),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(1751700000000),
  );

  test('toFirestore: semua tanggal epoch millis, tanpa savedAmount/id lokal',
      () {
    final map = tModel.toFirestore();
    expect(map, {
      'title': 'Pulang kampung',
      'targetAmount': 1500000,
      'targetDate': 1798675200000,
      'isCompleted': false,
      'createdAt': 1751700000000,
      'updatedAt': 1751700000000,
    });
    expect(map.containsKey('savedAmount'), isFalse);
    expect(map.containsKey('id'), isFalse);
  });

  test('fromFirestore ∘ toFirestore = identitas (roundtrip)', () {
    final back = GoalModel.fromFirestore('fid-123', tModel.toFirestore());
    expect(back.firestoreId, tModel.firestoreId);
    expect(back.title, tModel.title);
    expect(back.targetAmount, tModel.targetAmount);
    expect(back.targetDate, tModel.targetDate);
    expect(back.isCompleted, tModel.isCompleted);
    expect(back.createdAt, tModel.createdAt);
    expect(back.updatedAt, tModel.updatedAt);
  });

  test('fromRow memetakan seluruh kolom termasuk firestoreId', () {
    final row = Goal(
      id: 7,
      title: 'Laptop baru',
      targetAmount: 8000000,
      targetDate: DateTime(2026, 12, 31),
      isCompleted: true,
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 5),
      firestoreId: 'fid-777',
    );
    final model = GoalModel.fromRow(row);
    expect(model.firestoreId, 'fid-777');
    expect(model.title, 'Laptop baru');
    expect(model.isCompleted, isTrue);
  });

  test('toCompanion: id absent, firestoreId & field lain terisi', () {
    final c = tModel.toCompanion();
    expect(c.id, const Value<int>.absent());
    expect(c.firestoreId, const Value('fid-123'));
    expect(c.title, const Value('Pulang kampung'));
    expect(c.isCompleted, const Value(false));
  });
}
