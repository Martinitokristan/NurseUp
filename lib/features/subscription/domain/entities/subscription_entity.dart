import 'package:equatable/equatable.dart';

class SubscriptionEntity extends Equatable {
  const SubscriptionEntity({required this.isActive, required this.tier});

  final bool isActive;
  final String tier;

  @override
  List<Object?> get props => [isActive, tier];
}

