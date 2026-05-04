import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  const ProfileEntity({required this.uid, required this.name, required this.email, required this.school});

  final String uid;
  final String name;
  final String email;
  final String school;

  @override
  List<Object?> get props => [uid, name, email, school];
}

