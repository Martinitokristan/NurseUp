import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/cloudinary_service.dart';
import '../../data/services/study_text_extraction_service.dart';
import '../../domain/entities/study_file_entity.dart';

final userFilesProvider = StreamProvider<List<StudyFileEntity>>((ref) {
  if (Firebase.apps.isEmpty) return Stream.value(const []);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(const []);
  return FirebaseFirestore.instance.collection('study_files').doc(user.uid).collection('docs').orderBy('uploadedAt', descending: true).snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return StudyFileEntity(id: doc.id, name: data['name'] as String? ?? 'Study file', sizeBytes: data['sizeBytes'] as int? ?? 0, type: data['type'] as String? ?? 'pdf', downloadUrl: data['downloadUrl'] as String?);
    }).toList();
  });
});

final freeTierUsageProvider = Provider<int>((ref) {
  return ref.watch(userFilesProvider).valueOrNull?.length ?? 0;
});

final fileUploadControllerProvider = StateNotifierProvider<FileUploadController, FileUploadState>((ref) {
  return FileUploadController();
});

class FileUploadState {
  const FileUploadState({this.isUploading = false, this.message, this.fileId, this.fileIds = const [], this.errorMessage});

  final bool isUploading;
  final String? message;
  final String? fileId;
  final List<String> fileIds;
  final String? errorMessage;
}

class PickedFileResult {
  const PickedFileResult({required this.name, required this.text});
  final String name;
  final String text;
}

class PickedUploadFile {
  const PickedUploadFile({
    required this.name,
    required this.bytes,
    required this.extension,
    this.mimeType,
    this.path,
  });

  final String name;
  final Uint8List bytes;
  final String extension;
  final String? mimeType;
  final String? path;
}

class FileUploadController extends StateNotifier<FileUploadState> {
  FileUploadController() : super(const FileUploadState());

  final _extractor = const StudyTextExtractionService();

  /// Supported file extensions for study files.
  static const _supportedExtensions = ['pdf', 'docx', 'doc', 'txt', 'jpg', 'jpeg', 'png', 'webp'];

  /// Pick a file from the device — uses FileType.any so users can choose from
  /// file managers, WPS Office, Google Drive, or any other installed app.
  Future<PickedFileResult?> pickFileOnly({bool fromOtherApps = true}) async {
    try {
      _ensureReady();
      final result = await FilePicker.platform.pickFiles(
        type: fromOtherApps ? FileType.any : FileType.custom,
        allowedExtensions: fromOtherApps ? null : _supportedExtensions,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;
      final platformFile = result.files.single;

      // Validate the file extension after picking
      final extension = platformFile.extension?.toLowerCase() ?? '';
      if (!_supportedExtensions.contains(extension)) {
        state = FileUploadState(
          errorMessage: 'Unsupported file type ".$extension". Please choose a PDF, DOCX, TXT, PPTX, or other document file.',
        );
        return null;
      }

      final bytes = await _readBytes(platformFile);
      final text = String.fromCharCodes(bytes);
      return PickedFileResult(name: platformFile.name, text: text);
    } catch (error) {
      state = FileUploadState(errorMessage: _friendlyFileError(error));
      return null;
    }
  }

  Future<bool> uploadWithText(String fileText, String fileName) async {
    try {
      _ensureReady();
      state = const FileUploadState(isUploading: true, message: 'Reading text...');
      final cleanedText = StudyTextExtractionService.clean(fileText);
      if (cleanedText.length < StudyTextExtractionService.minimumReadableCharacters) {
        state = const FileUploadState(errorMessage: 'I could not read enough text from this file. Please try a clearer document.');
        return false;
      }
      final bytes = Uint8List.fromList(fileText.codeUnits);
      final user = FirebaseAuth.instance.currentUser!;
      final type = fileName.split('.').last.toLowerCase();
      final fileDoc = FirebaseFirestore.instance.collection('study_files').doc(user.uid).collection('docs').doc();

      state = const FileUploadState(isUploading: true, message: 'Uploading...');
      final upload = await CloudinaryService.instance.uploadPdf(
        bytes: bytes,
        fileName: fileName,
      );

      state = const FileUploadState(isUploading: true, message: 'Saving...');
      await fileDoc.set({
        'userId': user.uid,
        'name': fileName,
        'sizeBytes': bytes.length,
        'type': type,
        'mimeType': 'text/plain',
        'extractedText': cleanedText,
        'extractionMethod': 'plain_text',
        'cloudinaryPublicId': upload.publicId,
        'cloudinaryResourceType': upload.resourceType,
        'downloadUrl': upload.secureUrl,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      state = FileUploadState(message: 'File uploaded.', fileId: fileDoc.id);
      return true;
    } catch (error) {
      state = FileUploadState(errorMessage: _friendlyFileError(error));
      return false;
    }
  }

  Future<List<String>> uploadSelectedFiles(List<PickedUploadFile> files) async {
    try {
      _ensureReady();
      if (files.isEmpty) return const [];
      state = const FileUploadState(isUploading: true, message: 'Uploading to Cloudinary...');
      final user = FirebaseAuth.instance.currentUser!;
      final uploadedIds = <String>[];

      for (final selectedFile in files) {
        state = FileUploadState(isUploading: true, message: 'Reading ${selectedFile.name}...');
        final extraction = await _extractor.extract(
          bytes: selectedFile.bytes,
          fileName: selectedFile.name,
          mimeType: selectedFile.mimeType,
          path: selectedFile.path,
        );

        state = FileUploadState(isUploading: true, message: 'Uploading ${selectedFile.name}...');
        final fileDoc = FirebaseFirestore.instance.collection('study_files').doc(user.uid).collection('docs').doc();
        final upload = await CloudinaryService.instance.uploadPdf(
          bytes: selectedFile.bytes,
          fileName: selectedFile.name,
        );

        state = FileUploadState(isUploading: true, message: 'Saving ${selectedFile.name}...');
        await fileDoc.set({
          'userId': user.uid,
          'name': selectedFile.name,
          'sizeBytes': selectedFile.bytes.length,
          'type': selectedFile.extension,
          'mimeType': selectedFile.mimeType,
          'extractedText': extraction.text,
          'extractionMethod': extraction.method,
          'cloudinaryPublicId': upload.publicId,
          'cloudinaryResourceType': upload.resourceType,
          'downloadUrl': upload.secureUrl,
          'uploadedAt': FieldValue.serverTimestamp(),
        });
        uploadedIds.add(fileDoc.id);
      }

      state = FileUploadState(message: 'Files uploaded.', fileId: uploadedIds.isEmpty ? null : uploadedIds.first, fileIds: uploadedIds);
      return uploadedIds;
    } catch (error) {
      state = FileUploadState(errorMessage: _friendlyFileError(error));
      return const [];
    }
  }

  /// Pick, upload and generate reviewer — also uses FileType.any for
  /// broader app compatibility. Now includes text extraction.
  Future<bool> pickUploadAndGenerate() async {
    try {
      _ensureReady();
      state = const FileUploadState(isUploading: true, message: 'Choosing file...');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        state = const FileUploadState();
        return false;
      }

      final platformFile = result.files.single;

      // Validate the file extension
      final extension = platformFile.extension?.toLowerCase() ?? '';
      if (!_supportedExtensions.contains(extension)) {
        state = FileUploadState(
          errorMessage: 'Please upload PDF, TXT, JPG, PNG, or WEBP.',
        );
        return false;
      }

      final bytes = await _readBytes(platformFile);
      final user = FirebaseAuth.instance.currentUser!;
      final type = platformFile.extension?.toLowerCase() ?? 'file';
      final fileDoc = FirebaseFirestore.instance.collection('study_files').doc(user.uid).collection('docs').doc();

      // Extract text before uploading
      state = FileUploadState(isUploading: true, message: 'Reading ${platformFile.name}...');
      final extraction = await _extractor.extract(
        bytes: bytes,
        fileName: platformFile.name,
        mimeType: platformFile.extension != null ? 'application/${platformFile.extension}' : null,
        path: platformFile.path,
      );

      state = FileUploadState(isUploading: true, message: 'Uploading ${platformFile.name}...');
      final upload = await CloudinaryService.instance.uploadPdf(
        bytes: bytes,
        fileName: platformFile.name,
      );

      state = FileUploadState(isUploading: true, message: 'Saving ${platformFile.name}...');
      await fileDoc.set({
        'userId': user.uid,
        'name': platformFile.name,
        'sizeBytes': bytes.length,
        'type': type,
        'mimeType': platformFile.extension != null ? 'application/${platformFile.extension}' : null,
        'extractedText': extraction.text,
        'extractionMethod': extraction.method,
        'cloudinaryPublicId': upload.publicId,
        'cloudinaryResourceType': upload.resourceType,
        'downloadUrl': upload.secureUrl,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      state = FileUploadState(message: 'File uploaded.', fileId: fileDoc.id);
      return true;
    } catch (error) {
      state = FileUploadState(errorMessage: _friendlyFileError(error));
      return false;
    }
  }

  Future<Uint8List> _readBytes(PlatformFile file) async {
    if (file.bytes != null) return file.bytes!;
    final path = file.path;
    if (path == null) throw StateError('Unable to read selected file bytes.');
    return File(path).readAsBytes();
  }

  void _ensureReady() {
    if (Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null) {
      throw StateError('Please configure Firebase and sign in before uploading files.');
    }
  }

  /// Convert file operation errors to user-friendly messages.
  String _friendlyFileError(dynamic error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('permission') || msg.contains('denied')) {
      return 'Permission denied. Please allow access in your device settings.';
    }
    if (msg.contains('storage') && msg.contains('quota')) {
      return 'Storage quota exceeded. Please upgrade your plan or free up space.';
    }
    if (msg.contains('network') || msg.contains('connection') || msg.contains('socket')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    if (msg.contains('too large') || msg.contains('size')) {
      return 'File is too large. Please choose a smaller file.';
    }
    if (msg.contains('firebase') && msg.contains('not configured')) {
      return 'App configuration error. Please restart the app.';
    }
    if (msg.contains('sign in') || msg.contains('current user')) {
      return 'Please sign in before uploading files.';
    }
    if (msg.contains("couldn't read") || msg.contains('could not read')) {
      return 'I could not read enough text from this file. Please try a clearer photo or another document.';
    }
    if (msg.contains('unsupported') || msg.contains('not supported')) {
      return 'Please upload PDF, TXT, JPG, PNG, or WEBP.';
    }
    if (msg.contains('word documents') || msg.contains('doc') || msg.contains('docx')) {
      return 'Word documents are not supported yet. Please export as PDF or TXT, then upload.';
    }
    if (msg.contains('unable to read')) {
      return 'Unable to read the selected file. Please try a different file.';
    }
    return 'Something went wrong while processing the file. Please try again.';
  }
}
