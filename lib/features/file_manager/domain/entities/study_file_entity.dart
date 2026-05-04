import 'package:equatable/equatable.dart';

class StudyFileEntity extends Equatable {
  const StudyFileEntity({required this.id, required this.name, required this.sizeBytes, required this.type, this.downloadUrl});

  final String id;
  final String name;
  final int sizeBytes;
  final String type;
  final String? downloadUrl;

  @override
  List<Object?> get props => [id, name, sizeBytes, type, downloadUrl];
}
