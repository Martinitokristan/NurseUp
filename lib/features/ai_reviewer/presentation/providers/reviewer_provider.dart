import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/groq_remote_datasource.dart';
import '../../domain/entities/reviewer_entity.dart';

final reviewersProvider = StreamProvider<List<ReviewerEntity>>((ref) {
  if (Firebase.apps.isEmpty) return Stream.value(_demoReviewers);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(_demoReviewers);
  return FirebaseFirestore.instance.collection('reviewers').doc(user.uid).collection('docs').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ReviewerEntity(id: doc.id, title: data['title'] as String? ?? 'Generated Reviewer', summary: data['summary'] as String? ?? 'AI-generated nursing reviewer.');
    }).toList();
  });
});

final reviewerDocumentProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, reviewerId) {
  if (Firebase.apps.isEmpty || reviewerId.isEmpty) return Stream.value(null);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);
  return FirebaseFirestore.instance.collection('reviewers').doc(user.uid).collection('docs').doc(reviewerId).snapshots().map((doc) => doc.data());
});
final generateReviewerControllerProvider = StateNotifierProvider<GenerateReviewerController, GenerateReviewerState>((ref) {
  return GenerateReviewerController();
});

class GenerateReviewerState {
  const GenerateReviewerState({this.isGenerating = false, this.message, this.reviewerId, this.errorMessage});

  final bool isGenerating;
  final String? message;
  final String? reviewerId;
  final String? errorMessage;
}

class GenerateReviewerController extends StateNotifier<GenerateReviewerState> {
  GenerateReviewerController() : super(const GenerateReviewerState());

  final _groq = const GroqRemoteDatasource();

  Future<bool> generateFromFile(String fileId) async {
    try {
      _ensureReady();
      final user = FirebaseAuth.instance.currentUser!;
      state = const GenerateReviewerState(isGenerating: true, message: 'Reading your file...');
      final fileDoc = await FirebaseFirestore.instance.collection('study_files').doc(user.uid).collection('docs').doc(fileId).get();
      final fileData = fileDoc.data();
      if (fileData == null) throw const GroqReviewerException('missing_file');
      final extractedText = fileData['extractedText'] as String? ?? '';
      final fileName = fileData['name'] as String? ?? 'Uploaded material';
      if (extractedText.trim().isEmpty) throw const GroqReviewerException('empty_content');
      return generateReviewer(fileId: fileId, fileName: fileName, extractedText: extractedText);
    } catch (error) {
      state = GenerateReviewerState(errorMessage: _friendlyError(error));
      return false;
    }
  }

  Future<bool> generateReviewer({required String fileId, required String fileName, required String extractedText}) async {
    try {
      _ensureReady();
      state = const GenerateReviewerState(isGenerating: true, message: 'Creating your reviewer...');
      final result = await _groq.generateReviewer(extractedText, fileName);
      final parsed = _tryParseReviewerJson(result);
      final title = parsed['title'] as String? ?? 'Generated Reviewer';
      final summary = parsed['summary'] as String? ?? parsed['finalSummary'] as String? ?? 'Your reviewer is ready.';
      
      state = const GenerateReviewerState(isGenerating: true, message: 'Formatting your reviewer...');
      final user = FirebaseAuth.instance.currentUser!;
      final doc = FirebaseFirestore.instance.collection('reviewers').doc(user.uid).collection('docs').doc();
      await doc.set({
        'title': title,
        'summary': summary,
        'fullContent': result,
        'fileId': fileId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      state = GenerateReviewerState(message: 'Reviewer generated.', reviewerId: doc.id);
      return true;
    } catch (error) {
      state = GenerateReviewerState(errorMessage: _friendlyError(error));
      return false;
    }
  }

  void _ensureReady() {
    if (Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null) {
      throw StateError('Please sign in before generating reviewers.');
    }
  }

  Map<String, dynamic> _tryParseReviewerJson(String value) {
    try {
      final decoded = jsonDecode(value);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String _friendlyError(dynamic error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('network') || msg.contains('connection') || msg.contains('socket')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    if (msg.contains('empty_content')) {
      return 'I couldn’t read enough text from this file. Please try a clearer photo or another document.';
    }
    if (msg.contains('unsupported') || msg.contains('not supported')) {
      return 'This file type is not supported yet. Please upload a PDF, TXT, JPG, PNG, or WEBP file.';
    }
    if (msg.contains('invalid_key')) {
      return 'The AI service is not configured correctly. Please check the app setup.';
    }
    if (msg.contains('rate') || msg.contains('limit') || msg.contains('429')) {
      return 'Too many requests. Please wait a moment and try again.';
    }
    if (msg.contains('timeout') || msg.contains('deadline')) {
      return 'Request timed out. Please try again.';
    }
    if (msg.contains('sign in') || msg.contains('current user') || msg.contains('permission')) {
      return 'Please sign in before generating reviewers.';
    }
    if (msg.contains('groq') || msg.contains('api') || msg.contains('model')) {
      return 'AI service temporarily unavailable. Please try again later.';
    }
    return 'Something went wrong while generating the reviewer. Please try again.';
  }
}

const _demoReviewers = [
  ReviewerEntity(id: 'brain-reviewer', title: 'Brain Anatomy Reviewer', summary: 'Key brain anatomy concepts with exam tips.'),
  ReviewerEntity(id: 'cardio-reviewer', title: 'Cardiovascular Nursing Notes', summary: 'Cardiac assessment and nursing interventions.'),
];

