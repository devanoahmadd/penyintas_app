import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class ReportRemoteDatasource {
  Future<(List<String>, String?)> getAiInsights({
    required Map<String, dynamic> reportData,
    required Map<String, dynamic> settingsData,
  });
}

class ReportRemoteDatasourceImpl implements ReportRemoteDatasource {
  const ReportRemoteDatasourceImpl({
    required FirebaseFunctions functions,
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _functions = functions,
       _firestore = firestore,
       _auth = auth;

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Future<(List<String>, String?)> getAiInsights({
    required Map<String, dynamic> reportData,
    required Map<String, dynamic> settingsData,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User tidak login.');

    final month = reportData['month'] as String;
    final cacheRef = _firestore.doc('users/$uid/insights/$month');
    final cached = await cacheRef.get();

    if (cached.exists) {
      final data = cached.data()!;
      final cachedAt =
          (data['cachedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      if (DateTime.now().difference(cachedAt).inHours < 24) {
        final insights = (data['insights'] as List).cast<String>();
        final savingTip = data['savingTip'] as String?;
        return (insights, savingTip);
      }
    }

    final callable = _functions.httpsCallable('generateInsight');
    final result = await callable.call({
      'transactions': reportData,
      'budgetSettings': settingsData,
    });
    final insights = (result.data['insights'] as List).cast<String>();
    final savingTip = result.data['savingTip'] as String?;

    // Update cache with savingTip
    await cacheRef.set({
      'insights': insights,
      'savingTip': savingTip,
      'cachedAt': Timestamp.now(),
    });

    return (insights, savingTip);
  }
}
