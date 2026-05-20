import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:drift/drift.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/network/network_info.dart';
import 'package:penyintas_app/core/sync/sync_dispatcher.dart';

class SyncService {
  SyncService({
    required AppDatabase db,
    required NetworkInfo networkInfo,
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    // Injectable untuk testing — default ke SyncDispatcher.dispatch
    Future<void> Function(SyncQueueData, FirebaseFirestore)? dispatchFn,
  })  : _db = db,
        _networkInfo = networkInfo,
        _auth = auth,
        _firestore = firestore,
        _dispatchFn = dispatchFn ?? SyncDispatcher.dispatch;

  final AppDatabase _db;
  final NetworkInfo _networkInfo;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final Future<void> Function(SyncQueueData, FirebaseFirestore) _dispatchFn;

  StreamSubscription<bool>? _connectivitySub;
  StreamSubscription<User?>? _authSub;
  bool _processing = false;

  void start() {
    _networkInfo.isConnected.then((online) {
      if (online) _processQueue();
    });

    _connectivitySub = _networkInfo.onConnectivityChanged.listen((online) {
      if (online) _processQueue();
    });

    _authSub = _auth.authStateChanges().listen((user) {
      if (user != null) _processQueue();
    });
  }

  void dispose() {
    _connectivitySub?.cancel();
    _authSub?.cancel();
  }

  Future<void> _processQueue() async {
    if (_processing) return;
    _processing = true;
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      // #28: hapus item yang lebih dari 7 hari — tidak bisa dispatch, log sebagai abandoned
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      final expired = await (_db.select(_db.syncQueue)
            ..where((t) => t.createdAt.isSmallerThanValue(cutoff)))
          .get();
      for (final item in expired) {
        try {
          FirebaseCrashlytics.instance.recordError(
            Exception('SyncQueue item abandoned after 7 days: ${item.itemId}'),
            StackTrace.current,
          );
        } catch (_) {}
        await (_db.delete(_db.syncQueue)..where((t) => t.id.equals(item.id))).go();
      }

      final items = await (_db.select(_db.syncQueue)
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
          .get();

      for (final item in items) {
        try {
          await _dispatchFn(item, _firestore);
          await (_db.delete(_db.syncQueue)..where((t) => t.id.equals(item.id)))
              .go();
        } catch (e, stack) {
          try {
            FirebaseCrashlytics.instance.recordError(e, stack);
          } catch (_) {}
          // Item tetap di queue — retry saat koneksi berikutnya
        }
      }
    } finally {
      _processing = false;
    }
  }
}
