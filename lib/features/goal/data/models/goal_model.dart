import 'package:drift/drift.dart';
import 'package:penyintas_app/core/database/app_database.dart';

/// Model data-layer untuk sinkronisasi Goal ↔ Firestore.
/// SENGAJA bukan turunan GoalEntity: `savedAmount` dihitung dari transaksi
/// lokal (lihat GoalEntity) dan TIDAK pernah disimpan di dokumen remote.
/// Semua tanggal diserialisasi epoch millis (pola BudgetLimitModel.updatedAt).
class GoalModel {
  const GoalModel({
    required this.firestoreId,
    required this.title,
    required this.targetAmount,
    required this.targetDate,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  final String firestoreId;
  final String title;
  final int targetAmount;
  final DateTime targetDate;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// row.firestoreId nullable di SQL; pasca-backfill migrasi 12→13 selalu
  /// terisi — fallback '' hanya defensive (dicek pemanggil sebelum push).
  factory GoalModel.fromRow(Goal row) => GoalModel(
    firestoreId: row.firestoreId ?? '',
    title: row.title,
    targetAmount: row.targetAmount,
    targetDate: row.targetDate,
    isCompleted: row.isCompleted,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  factory GoalModel.fromFirestore(String docId, Map<String, dynamic> data) =>
      GoalModel(
        firestoreId: docId,
        title: data['title'] as String,
        targetAmount: (data['targetAmount'] as num).toInt(),
        targetDate: DateTime.fromMillisecondsSinceEpoch(
          (data['targetDate'] as num).toInt(),
        ),
        isCompleted: data['isCompleted'] as bool,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (data['createdAt'] as num).toInt(),
        ),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          (data['updatedAt'] as num).toInt(),
        ),
      );

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'targetAmount': targetAmount,
    'targetDate': targetDate.millisecondsSinceEpoch,
    'isCompleted': isCompleted,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  /// Untuk hydrate lokal dari remote. `id` sengaja absent — autoincrement
  /// lokal; identitas lintas-device satu-satunya adalah [firestoreId].
  GoalsCompanion toCompanion() => GoalsCompanion(
    title: Value(title),
    targetAmount: Value(targetAmount),
    targetDate: Value(targetDate),
    isCompleted: Value(isCompleted),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
    firestoreId: Value(firestoreId),
  );
}
