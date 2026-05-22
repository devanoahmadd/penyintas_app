import 'package:equatable/equatable.dart';

class SurvivalTip extends Equatable {
  const SurvivalTip({
    required this.title,
    required this.description,
    required this.estimatedSaving,
  });

  final String title;
  final String description;
  final int estimatedSaving; // estimasi penghematan per hari (rupiah)

  @override
  List<Object> get props => [title, description, estimatedSaving];
}
