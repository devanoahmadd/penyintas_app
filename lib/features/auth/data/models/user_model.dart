import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:penyintas_app/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  final String? fcmToken;

  const UserModel({
    required super.uid,
    required super.email,
    required super.displayName,
    super.photoUrl,
    required super.createdAt,
    super.emailVerified,
    super.hasPasswordProvider,
    this.fcmToken,
  });

  /// Flag verifikasi TIDAK tersimpan di dokumen Firestore — datasource
  /// menyuntikkannya dari FirebaseAuth User saat membangun model.
  factory UserModel.fromFirestore(
    DocumentSnapshot doc, {
    bool emailVerified = true,
    bool hasPasswordProvider = false,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      emailVerified: emailVerified,
      hasPasswordProvider: hasPasswordProvider,
      fcmToken: data['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  UserModel copyWith({String? fcmToken}) => UserModel(
        uid: uid,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        createdAt: createdAt,
        emailVerified: emailVerified,
        hasPasswordProvider: hasPasswordProvider,
        fcmToken: fcmToken ?? this.fcmToken,
      );
}
