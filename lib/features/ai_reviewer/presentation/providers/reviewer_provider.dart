import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/groq_remote_datasource.dart';
import '../../domain/entities/reviewer_entity.dart';

final flashcardsProvider = StreamProvider<List<FlashcardEntity>>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.valueOrNull;

  if (Firebase.apps.isEmpty || user == null) {
    return Stream.value(const <FlashcardEntity>[]);
  }

  return FirebaseFirestore.instance
      .collection('flashcards')
      .doc(user.uid)
      .collection('docs')
      .where('userId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => FlashcardEntity.fromDoc(doc)).toList();
      });
});

final reviewersProvider = StreamProvider<List<ReviewerEntity>>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.valueOrNull;

  if (Firebase.apps.isEmpty || user == null) {
    return Stream.value(const <ReviewerEntity>[]);
  }

  return FirebaseFirestore.instance
      .collection('reviewers')
      .doc(user.uid)
      .collection('docs')
      .where('userId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return ReviewerEntity(
            id: doc.id,
            title: data['title'] as String? ?? 'Generated Reviewer',
            summary: data['summary'] as String? ?? 'AI-generated nursing reviewer.',
          );
        }).toList();
      });
});

final reviewerDocumentProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, reviewerId) {
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.valueOrNull;

  if (Firebase.apps.isEmpty || user == null || reviewerId.isEmpty) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection('reviewers')
      .doc(user.uid)
      .collection('docs')
      .doc(reviewerId)
      .snapshots()
      .map((doc) {
        final data = doc.data();
        if (data == null) return null;
        if (data['userId'] != null && data['userId'] != user.uid) return null;
        return data;
      });
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
      final cleanResult = _cleanJsonResponse(result);
      final parsed = _tryParseReviewerJson(cleanResult);
      final title = parsed['title'] as String? ?? 'Study Reviewer';
      final overview = parsed['overview'] as String? ?? parsed['summary'] as String? ?? '';
      final sections = _parseSections(parsed['sections']);
      final keyTerms = _parseKeyTerms(parsed['keyTerms'] ?? parsed['importantTerms']);
      final mustRemember = _stringList(parsed['mustRemember']);
      final practiceQuestions = _parsePracticeQuestions(parsed['practiceQuestions']);
      final flashcards = _parseFlashcards(parsed['flashcards']);

      final hasContent = sections.isNotEmpty ||
          keyTerms.isNotEmpty ||
          mustRemember.isNotEmpty ||
          practiceQuestions.isNotEmpty ||
          flashcards.isNotEmpty ||
          (overview.trim().isNotEmpty && overview.trim() != 'Your reviewer is ready.');

      if (!hasContent) {
        throw const GroqReviewerException('empty_generated_content');
      }

      state = const GenerateReviewerState(isGenerating: true, message: 'Saving flashcards...');
      final user = FirebaseAuth.instance.currentUser!;
      final doc = FirebaseFirestore.instance.collection('reviewers').doc(user.uid).collection('docs').doc();

      await doc.set({
        'userId': user.uid,
        'title': title,
        'overview': overview,
        'summary': overview,
        'fullContent': cleanResult,
        'sections': sections,
        'keyTerms': keyTerms,
        'mustRemember': mustRemember,
        'practiceQuestions': practiceQuestions,
        'flashcards': flashcards,
        'fileId': fileId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _saveFlashcards(user.uid, doc.id, fileId, flashcards);
      await _recordReviewerGenerated(user.uid);

      state = GenerateReviewerState(message: 'Reviewer generated.', reviewerId: doc.id);
      return true;
    } catch (error) {
      state = GenerateReviewerState(errorMessage: _friendlyError(error));
      return false;
    }
  }

  Future<void> _saveFlashcards(String userId, String reviewerId, String fileId, List<Map<String, String>> flashcards) async {
    if (flashcards.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    final flashcardsCollection = FirebaseFirestore.instance.collection('flashcards').doc(userId).collection('docs');
    for (final card in flashcards) {
      final cardDoc = flashcardsCollection.doc();
      batch.set(cardDoc, {
        'userId': userId,
        'reviewerId': reviewerId,
        'fileId': fileId,
        'front': card['front'],
        'back': card['back'],
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'reviewer_generation',
      });
    }
    await batch.commit();
  }

  Future<void> _recordReviewerGenerated(String uid) async {
    final doc = FirebaseFirestore.instance.collection('users').doc(uid).collection('usage').doc('current');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await doc.set({
      'reviewers_generated': FieldValue.increment(1),
      'last_active_date': Timestamp.fromDate(today),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  List<Map<String, dynamic>> _parseSections(dynamic value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((item) => {
      'heading': item['heading']?.toString() ?? '',
      'bullets': _stringList(item['bullets']),
    }).where((s) => (s['heading'] as String).isNotEmpty).toList();
  }

  List<Map<String, String>> _parseKeyTerms(dynamic value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((item) {
      final term = item['term']?.toString().trim() ?? '';
      final definition = item['definition']?.toString().trim() ?? '';
      return {'term': term, 'definition': definition};
    }).where((t) => t['term']!.isNotEmpty).toList();
  }

  List<Map<String, String>> _parsePracticeQuestions(dynamic value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((item) {
      final question = item['question']?.toString().trim() ?? '';
      final answer = item['answer']?.toString().trim() ?? '';
      return {'question': question, 'answer': answer};
    }).where((q) => q['question']!.isNotEmpty).toList();
  }

  List<Map<String, String>> _parseFlashcards(dynamic value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((item) {
      final front = item['front']?.toString().trim() ?? '';
      final back = item['back']?.toString().trim() ?? '';
      return {'front': front, 'back': back};
    }).where((c) => c['front']!.isNotEmpty && c['back']!.isNotEmpty).toList();
  }

  List<String> _stringList(dynamic value) {
    if (value is List) return value.map((item) => item.toString()).where((item) => item.trim().isNotEmpty).toList();
    return [];
  }

  void _ensureReady() {
    if (Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null) {
      throw StateError('Please sign in before generating reviewers.');
    }
  }

  Map<String, dynamic> _tryParseReviewerJson(String value) {
    try {
      final decoded = jsonDecode(_cleanJsonResponse(value));
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
      return 'I could not read enough text from this file. Please try a clearer photo or another document.';
    }
    if (msg.contains('empty_generated_content')) {
      return 'The reviewer was created but did not contain readable study content. Please try a clearer file or photo.';
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
    if (msg.contains('permission-denied') || msg.contains('permission denied')) {
      return 'Your account does not have permission to save this reviewer. Please refresh the app and try again.';
    }
    if (msg.contains('sign in') || msg.contains('current user')) {
      return 'Please sign in before generating reviewers.';
    }
    if (msg.contains('groq') || msg.contains('api') || msg.contains('model')) {
      return 'AI service temporarily unavailable. Please try again later.';
    }
    return 'Something went wrong while generating the reviewer. Please try again.';
  }

  String _cleanJsonResponse(String value) {
    var cleaned = value.trim();

    cleaned = cleaned
        .replaceFirst(RegExp(r'^```json\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^```\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();

    final firstBrace = cleaned.indexOf('{');
    final lastBrace = cleaned.lastIndexOf('}');

    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      cleaned = cleaned.substring(firstBrace, lastBrace + 1).trim();
    }

    return cleaned;
  }
}


class FlashcardEntity {
  const FlashcardEntity({
    required this.id,
    required this.front,
    required this.back,
    required this.reviewerId,
    required this.fileId,
    this.createdAt,
  });

  final String id;
  final String front;
  final String back;
  final String reviewerId;
  final String fileId;
  final DateTime? createdAt;

  factory FlashcardEntity.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    final createdAt = data?['createdAt'];
    return FlashcardEntity(
      id: doc.id,
      front: data?['front'] as String? ?? '',
      back: data?['back'] as String? ?? '',
      reviewerId: data?['reviewerId'] as String? ?? '',
      fileId: data?['fileId'] as String? ?? '',
      createdAt: createdAt != null && createdAt.toString().contains('Timestamp') ? createdAt.toDate() : null,
    );
  }
}
