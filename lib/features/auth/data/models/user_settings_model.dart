import 'package:cloud_firestore/cloud_firestore.dart';

class UserSettingsModel {
  const UserSettingsModel({required this.onboardingCompleted});

  final bool onboardingCompleted;

  factory UserSettingsModel.fromFirestore(Map<String, dynamic> data) {
    return UserSettingsModel(
      onboardingCompleted: data['onboardingCompleted'] == true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'onboardingCompleted': onboardingCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
