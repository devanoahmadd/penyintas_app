import 'package:drift/drift.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';

/// Model data-layer untuk sinkronisasi Bill ↔ Firestore.
/// Mirror pola GoalModel: SENGAJA bukan turunan BillEntity, murni pembawa
/// field yang benar-benar tersimpan (lokal maupun cloud). Semua tanggal
/// diserialisasi epoch millis (pola BudgetLimitModel.updatedAt), enum
/// (`recurrence`, `status`) via `.name`.
///
/// Beda dari GoalModel: identitas remote di sini dinamai [cloudId] (bukan
/// `firestoreId`) dan sejumlah field memang nullable ([installmentTotal],
/// [recurrenceEndDate], [dueDayOfMonth], [notes], [cloudId] sendiri) —
/// GoalModel tidak punya kasus ini.
class BillModel {
  const BillModel({
    this.cloudId,
    required this.name,
    required this.estimatedAmount,
    required this.category,
    required this.isFixedNeed,
    this.notes,
    required this.dueDate,
    required this.recurrence,
    this.installmentTotal,
    required this.installmentsPaid,
    this.recurrenceEndDate,
    this.dueDayOfMonth,
    this.reminderDaysBefore,
    required this.reminderEnabled,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Doc ID Firestore — identitas remote. Null selama belum tersinkron.
  final String? cloudId;
  final String name;
  final int estimatedAmount;
  final String category;
  final bool isFixedNeed;
  final String? notes;
  final DateTime dueDate;
  final Recurrence recurrence;

  /// Total tenor cicilan. Null = bukan cicilan (tagihan biasa).
  final int? installmentTotal;
  final int installmentsPaid;

  /// Batas akhir perulangan. Null = tanpa batas.
  final DateTime? recurrenceEndDate;

  /// Anchor hari jatuh tempo (1–31) untuk roll-forward. Null = non-recurring.
  final int? dueDayOfMonth;

  final int? reminderDaysBefore;
  final bool reminderEnabled;
  final BillStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory BillModel.fromRow(Bill row) => BillModel(
    cloudId: row.cloudId,
    name: row.name,
    estimatedAmount: row.estimatedAmount,
    category: row.category,
    isFixedNeed: row.isFixedNeed,
    notes: row.notes,
    dueDate: row.dueDate,
    recurrence: Recurrence.values.byName(row.recurrence),
    installmentTotal: row.installmentTotal,
    installmentsPaid: row.installmentsPaid,
    recurrenceEndDate: row.recurrenceEndDate,
    dueDayOfMonth: row.dueDayOfMonth,
    reminderDaysBefore: row.reminderDaysBefore,
    reminderEnabled: row.reminderEnabled,
    status: BillStatus.values.byName(row.status),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  /// Cast field nullable secara aman (`as num?`, cek null eksplisit sebelum
  /// `DateTime.fromMillisecondsSinceEpoch`) — dokumen Firestore lama/parsial
  /// atau bill tanpa cicilan/pengingat/batas perulangan TIDAK BOLEH crash.
  factory BillModel.fromFirestore(String docId, Map<String, dynamic> data) =>
      BillModel(
        cloudId: docId,
        name: data['name'] as String,
        estimatedAmount: (data['estimatedAmount'] as num).toInt(),
        category: data['category'] as String,
        isFixedNeed: data['isFixedNeed'] as bool,
        notes: data['notes'] as String?,
        dueDate: DateTime.fromMillisecondsSinceEpoch(
          (data['dueDate'] as num).toInt(),
        ),
        recurrence: Recurrence.values.byName(data['recurrence'] as String),
        installmentTotal: (data['installmentTotal'] as num?)?.toInt(),
        installmentsPaid: (data['installmentsPaid'] as num).toInt(),
        recurrenceEndDate: data['recurrenceEndDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                (data['recurrenceEndDate'] as num).toInt(),
              )
            : null,
        dueDayOfMonth: (data['dueDayOfMonth'] as num?)?.toInt(),
        reminderDaysBefore: (data['reminderDaysBefore'] as num?)?.toInt(),
        reminderEnabled: data['reminderEnabled'] as bool,
        status: BillStatus.values.byName(data['status'] as String),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (data['createdAt'] as num).toInt(),
        ),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          (data['updatedAt'] as num).toInt(),
        ),
      );

  /// `cloudId` SENGAJA tidak diulang di dalam map — ia sudah menjadi doc ID
  /// dokumen itu sendiri (pola sama dengan `GoalModel.toFirestore`).
  Map<String, dynamic> toFirestore() => {
    'name': name,
    'estimatedAmount': estimatedAmount,
    'category': category,
    'isFixedNeed': isFixedNeed,
    'notes': notes,
    'dueDate': dueDate.millisecondsSinceEpoch,
    'recurrence': recurrence.name,
    'installmentTotal': installmentTotal,
    'installmentsPaid': installmentsPaid,
    'recurrenceEndDate': recurrenceEndDate?.millisecondsSinceEpoch,
    'dueDayOfMonth': dueDayOfMonth,
    'reminderDaysBefore': reminderDaysBefore,
    'reminderEnabled': reminderEnabled,
    'status': status.name,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  /// Untuk hydrate lokal dari remote. `id` sengaja absent — autoincrement
  /// lokal; identitas lintas-device satu-satunya adalah [cloudId].
  BillsCompanion toCompanion() => BillsCompanion(
    cloudId: Value(cloudId),
    name: Value(name),
    estimatedAmount: Value(estimatedAmount),
    category: Value(category),
    isFixedNeed: Value(isFixedNeed),
    notes: Value(notes),
    dueDate: Value(dueDate),
    recurrence: Value(recurrence.name),
    installmentTotal: Value(installmentTotal),
    installmentsPaid: Value(installmentsPaid),
    recurrenceEndDate: Value(recurrenceEndDate),
    dueDayOfMonth: Value(dueDayOfMonth),
    reminderDaysBefore: Value(reminderDaysBefore),
    reminderEnabled: Value(reminderEnabled),
    status: Value(status.name),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
  );
}
