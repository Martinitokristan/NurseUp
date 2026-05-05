import 'package:equatable/equatable.dart';

class StudyFileEntity extends Equatable {
  const StudyFileEntity({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.type,
    this.downloadUrl,
    this.anatomyTopic,
    this.anatomyModelId,
    this.anatomyModelName,
  });

  final String id;
  final String name;
  final int sizeBytes;
  final String type;
  final String? downloadUrl;
  final String? anatomyTopic;
  final String? anatomyModelId;
  final String? anatomyModelName;

  @override
  List<Object?> get props => [id, name, sizeBytes, type, downloadUrl, anatomyTopic, anatomyModelId, anatomyModelName];
}
