import 'package:equatable/equatable.dart';

class ReviewerEntity extends Equatable {
  const ReviewerEntity({required this.id, required this.title, required this.summary});

  final String id;
  final String title;
  final String summary;

  @override
  List<Object?> get props => [id, title, summary];
}

