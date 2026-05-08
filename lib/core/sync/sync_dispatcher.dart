import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:penyintas_app/core/database/app_database.dart';

class SyncDispatcher {
  const SyncDispatcher._();

  static Future<void> dispatch(
    SyncQueueData item,
    FirebaseFirestore firestore,
  ) async {
    final docRef = firestore.doc(item.collectionPath);

    switch (item.operation) {
      case SyncOperation.create:
        final data = jsonDecode(item.data) as Map<String, dynamic>;
        await docRef.set(data);
      case SyncOperation.update:
        final data = jsonDecode(item.data) as Map<String, dynamic>;
        await docRef.set(data, SetOptions(merge: true));
      case SyncOperation.delete:
        await docRef.delete();
    }
  }
}
