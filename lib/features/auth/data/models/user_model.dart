import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({required super.uid, required super.email, required super.name, super.photoUrl});

  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(uid: user.uid, email: user.email ?? '', name: user.displayName ?? 'NurseUp Student', photoUrl: user.photoURL);
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserModel(uid: doc.id, email: data['email'] as String? ?? '', name: data['name'] as String? ?? 'NurseUp Student', photoUrl: data['photoUrl'] as String?);
  }

  Map<String, dynamic> toMap() => {'uid': uid, 'email': email, 'name': name, 'photoUrl': photoUrl};
}
