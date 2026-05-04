import 'package:equatable/equatable.dart';

class AnatomyModelEntity extends Equatable {
  const AnatomyModelEntity({required this.id, required this.name, required this.assetPath, required this.parts, required this.iconCodePoint, this.category});

  final String id;
  final String name;
  final String assetPath;
  final int parts;
  final int iconCodePoint;
  final String? category;

  @override
  List<Object?> get props => [id, name, assetPath, parts, iconCodePoint, category];
}
