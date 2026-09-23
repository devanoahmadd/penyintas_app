import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:penyintas_app/features/challenge/data/models/challenge_model.dart';

abstract class ChallengeRemoteDatasource {
  Future<void> upsertChallenge(String uid, ChallengeModel model);
  Future<List<ChallengeModel>> fetchChallenges(String uid, int sinceWeekKey);
}

class ChallengeRemoteDatasourceImpl implements ChallengeRemoteDatasource {
  ChallengeRemoteDatasourceImpl(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('challenges');

  @override
  Future<void> upsertChallenge(String uid, ChallengeModel model) =>
      _col(uid).doc('${model.weekKey}').set(model.toFirestore());

  @override
  Future<List<ChallengeModel>> fetchChallenges(
    String uid,
    int sinceWeekKey,
  ) async {
    final snap = await _col(
      uid,
    ).where('weekKey', isGreaterThanOrEqualTo: sinceWeekKey).get();
    return snap.docs
        .map(
          (d) => ChallengeModel.fromFirestore(
            d.data(),
            weekKey: int.tryParse(d.id) ?? 0,
          ),
        )
        .where((m) => m.weekKey > 0)
        .toList();
  }
}
