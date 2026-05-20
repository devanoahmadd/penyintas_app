sealed class FirestoreOp {
  const FirestoreOp();
  String get path;
}

class SetOp extends FirestoreOp {
  const SetOp({required this.path, required this.data, this.merge = false});
  @override
  final String path;
  final Map<String, dynamic> data;
  final bool merge;
}

class DeleteOp extends FirestoreOp {
  const DeleteOp({required this.path});
  @override
  final String path;
}
