import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/cloudinary_service.dart';

class ProfileEditController extends StateNotifier<AsyncValue<void>> {
  ProfileEditController() : super(const AsyncValue.data(null));

  Future<bool> updateDisplayName(String name) async {
    state = const AsyncValue.loading();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        state = AsyncValue.error('Not signed in', StackTrace.current);
        return false;
      }
      final trimmed = name.trim();
      await user.updateDisplayName(trimmed);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'name': trimmed,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await user.reload();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateProfileImage() async {
    state = const AsyncValue.loading();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        state = AsyncValue.error('Not signed in', StackTrace.current);
        return false;
      }
      final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      if (result == null || result.files.isEmpty) {
        state = const AsyncValue.data(null);
        return false;
      }
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        state = AsyncValue.error('Unable to read selected image', StackTrace.current);
        return false;
      }
      final extension = (file.extension ?? 'jpg').toLowerCase();
      final upload = await CloudinaryService.instance.uploadProfileImage(
        bytes: Uint8List.fromList(bytes),
        fileName: 'avatar.$extension',
        userId: user.uid,
      );
      final photoUrl = upload.secureUrl;
      await user.updatePhotoURL(photoUrl);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'photoUrl': photoUrl,
          'profileImagePublicId': upload.publicId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await user.reload();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final profileEditControllerProvider = StateNotifierProvider<ProfileEditController, AsyncValue<void>>(
  (ref) => ProfileEditController(),
);
