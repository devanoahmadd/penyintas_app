import 'package:isar/isar.dart';

part 'sync_queue_isar_model.g.dart';

@collection
class SyncQueueIsarModel {
  Id id = Isar.autoIncrement;

  late String itemId; // UUID milik transaksi / settings
  late String collectionPath; // e.g. 'users/{uid}/transactions'
  late String data; // JSON string dari entity

  @enumerated
  late SyncOperation operation;

  late DateTime createdAt;
}

enum SyncOperation { create, update, delete }
