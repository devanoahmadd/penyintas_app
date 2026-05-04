import 'package:isar/isar.dart';

part 'transaction_isar_model.g.dart';

@collection
class TransactionIsarModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String txId;

  late int amount;

  @enumerated
  late TransactionCategoryIsar category;

  @enumerated
  late TransactionTypeIsar type;

  String? note;

  @Index()
  late DateTime date;

  late bool isFixed;
  late bool isSynced;
  DateTime? syncedAt;
  late DateTime createdAt;
  late DateTime updatedAt;
}

enum TransactionCategoryIsar {
  food,
  transport,
  campus,
  data,
  shopping,
  fixed,
  income,
  other,
}

enum TransactionTypeIsar {
  expense,
  income,
}
