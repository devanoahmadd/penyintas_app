import 'package:cloud_firestore/cloud_firestore.dart';

class UserSettingsModel {
  const UserSettingsModel({
    required this.onboardingCompleted,
    required this.rentExpense,
    required this.utilitiesExpense,
    required this.internetExpense,
    required this.phoneExpense,
    required this.otherFixedExpense,
  });

  final bool onboardingCompleted;
  final int rentExpense;
  final int utilitiesExpense;
  final int internetExpense;
  final int phoneExpense;
  final int otherFixedExpense;

  factory UserSettingsModel.fromFirestore(Map<String, dynamic> data) {
    return UserSettingsModel(
      onboardingCompleted: data['onboardingCompleted'] as bool? ?? false,
      rentExpense: (data['rentAmount'] as num?)?.toInt() ?? 0,
      utilitiesExpense: (data['utilitiesAmount'] as num?)?.toInt() ?? 0,
      internetExpense: (data['internetAmount'] as num?)?.toInt() ?? 0,
      phoneExpense: (data['phoneAmount'] as num?)?.toInt() ?? 0,
      otherFixedExpense: (data['otherFixedAmount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'onboardingCompleted': onboardingCompleted,
        'rentAmount': rentExpense,
        'utilitiesAmount': utilitiesExpense,
        'internetAmount': internetExpense,
        'phoneAmount': phoneExpense,
        'otherFixedAmount': otherFixedExpense,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
