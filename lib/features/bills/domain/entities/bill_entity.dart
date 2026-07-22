import 'package:equatable/equatable.dart';

/// Pola perulangan tagihan.
///
/// Di-serialize via `.name` di layer data — JANGAN ubah urutan atau nama value
/// tanpa migrasi, karena akan merusak baris tersimpan.
enum Recurrence { none, monthly, yearly }

/// Status siklus hidup tagihan.
///
/// Di-serialize via `.name` di layer data — JANGAN ubah urutan atau nama value
/// tanpa migrasi.
enum BillStatus { active, completed }

/// Entity domain untuk sebuah tagihan/kewajiban rutin.
///
/// Mirror kolom tabel Drift `Bills` (schema v14), namun `recurrence` dan
/// `status` bertipe enum domain (bukan String) supaya layer domain tidak
/// bergantung pada representasi penyimpanan.
class BillEntity extends Equatable {
  const BillEntity({
    required this.id,
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

  /// PK lokal (autoIncrement Drift).
  final int id;

  /// Doc ID Firestore — null selama belum tersinkron ke cloud.
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

  /// True jika tagihan masih aktif dan sudah lewat jatuh tempo.
  ///
  /// [nowStartOfDay] diharapkan berupa awal-hari (00:00) agar perbandingan
  /// bebas dari komponen jam.
  bool isOverdue(DateTime nowStartOfDay) =>
      status == BillStatus.active && dueDate.isBefore(nowStartOfDay);

  BillEntity copyWith({
    int? id,
    String? cloudId,
    String? name,
    int? estimatedAmount,
    String? category,
    bool? isFixedNeed,
    String? notes,
    DateTime? dueDate,
    Recurrence? recurrence,
    int? installmentTotal,
    int? installmentsPaid,
    DateTime? recurrenceEndDate,
    int? dueDayOfMonth,
    int? reminderDaysBefore,
    bool? reminderEnabled,
    BillStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BillEntity(
    id: id ?? this.id,
    cloudId: cloudId ?? this.cloudId,
    name: name ?? this.name,
    estimatedAmount: estimatedAmount ?? this.estimatedAmount,
    category: category ?? this.category,
    isFixedNeed: isFixedNeed ?? this.isFixedNeed,
    notes: notes ?? this.notes,
    dueDate: dueDate ?? this.dueDate,
    recurrence: recurrence ?? this.recurrence,
    installmentTotal: installmentTotal ?? this.installmentTotal,
    installmentsPaid: installmentsPaid ?? this.installmentsPaid,
    recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
    dueDayOfMonth: dueDayOfMonth ?? this.dueDayOfMonth,
    reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    cloudId,
    name,
    estimatedAmount,
    category,
    isFixedNeed,
    notes,
    dueDate,
    recurrence,
    installmentTotal,
    installmentsPaid,
    recurrenceEndDate,
    dueDayOfMonth,
    reminderDaysBefore,
    reminderEnabled,
    status,
    createdAt,
    updatedAt,
  ];
}
