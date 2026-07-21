import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/sync/firestore_op.dart';

/// Pure function — tidak bergantung pada Firestore instance.
/// Testable tanpa mock Firestore.
FirestoreOp toFirestoreOp(SyncQueueData item) {
  final path = item.collectionPath;
  // Guard #252: wajib doc path penuh ter-resolve (users/<uid>/<koleksi>/<docId>).
  // Placeholder '{uid}', path collection (segmen ganjil), atau segmen kosong =
  // item salah bentuk — gagal-cepat agar terdeteksi saat development, lalu
  // di-PURGE oleh SyncService (bukan diam-diam retry sampai TTL 7 hari).
  final segments = path.split('/');
  if (path.contains('{') ||
      segments.length.isOdd ||
      segments.any((s) => s.isEmpty)) {
    throw ArgumentError.value(
      path,
      'collectionPath',
      'Bukan doc path penuh ter-resolve',
    );
  }
  final data = jsonDecode(item.data) as Map<String, dynamic>;
  return switch (item.operation) {
    SyncOperation.create => SetOp(path: path, data: data),
    SyncOperation.update => SetOp(path: path, data: data, merge: true),
    SyncOperation.delete => DeleteOp(path: path),
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
