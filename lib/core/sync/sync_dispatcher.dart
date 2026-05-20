import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/sync/firestore_op.dart';

/// Pure function — tidak bergantung pada Firestore instance.
/// Testable tanpa mock Firestore.
FirestoreOp toFirestoreOp(SyncQueueData item) {
  final data = jsonDecode(item.data) as Map<String, dynamic>;
  return switch (item.operation) {
    SyncOperation.create => SetOp(path: item.collectionPath, data: data),
    SyncOperation.update =>
      SetOp(path: item.collectionPath, data: data, merge: true),
    SyncOperation.delete => DeleteOp(path: item.collectionPath),
  };
}

class SyncDispatcher {
  const SyncDispatcher._();

  static Future<void> dispatch(
    SyncQueueData item,
    FirebaseFirestore firestore,
  ) async {
    final op = toFirestoreOp(item);
    final docRef = firestore.doc(op.path);

    switch (op) {
      case SetOp(:final data, :final merge):
        await docRef.set(data, merge ? SetOptions(merge: true) : null);
      case DeleteOp():
        await docRef.delete();
    }
  }
}
