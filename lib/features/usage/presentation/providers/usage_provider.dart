import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/usage_model.dart';

final usageProvider = StreamProvider<UsageModel>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.valueOrNull;

  if (Firebase.apps.isEmpty || user == null) {
    return Stream.value(_emptyUsage);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('usage')
      .doc('current')
      .snapshots()
      .map((doc) {
        if (!doc.exists) return _emptyUsage;
        return UsageModel.fromFirestore(doc.data()!);
      });
});

UsageModel get _emptyUsage => UsageModel(
  wordsUsedThisWeek: 0,
  weekResetDate: DateTime.now().add(const Duration(days: 7)),
  tier: 'free',
  filesUploaded: 0,
  reviewersGenerated: 0,
  streak: 0,
);

final usageControllerProvider = StateNotifierProvider<UsageController, UsageState>((ref) {
  return UsageController();
});

class UsageState {
  const UsageState({this.isChecking = false, this.wordCount = 0, this.canProceed = false, this.errorMessage});
  final bool isChecking;
  final int wordCount;
  final bool canProceed;
  final String? errorMessage;
}

class UsageController extends StateNotifier<UsageState> {
  UsageController() : super(const UsageState());

  Future<int> countWordsInText(String text) async {
    final words = text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    return words;
  }

  Future<bool> checkBeforeUpload(String fileText, UsageModel currentUsage) async {
    try {
      _ensureReady();
      state = const UsageState(isChecking: true);
      final wordCount = await countWordsInText(fileText);
      final canProceed = currentUsage.canUpload(wordCount);
      state = UsageState(isChecking: false, wordCount: wordCount, canProceed: canProceed, errorMessage: canProceed ? null : 'File exceeds your weekly limit.');
      return canProceed;
    } catch (error) {
      state = UsageState(isChecking: false, errorMessage: _friendlyError(error));
      return false;
    }
  }

  Future<void> recordUsage(int wordsAdded) async {
    try {
      _ensureReady();
      final user = FirebaseAuth.instance.currentUser!;
      final doc = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('usage').doc('current');
      final snapshot = await doc.get();
      
      if (!snapshot.exists) {
        await doc.set(UsageModel(
          wordsUsedThisWeek: wordsAdded,
          weekResetDate: _nextMonday(),
          tier: 'free',
          filesUploaded: 1,
          reviewersGenerated: 0,
        ).toFirestore());
        return;
      }

      final current = UsageModel.fromFirestore(snapshot.data()!);
      final needsReset = DateTime.now().isAfter(current.weekResetDate) || DateTime.now().isAtSameMomentAs(current.weekResetDate);
      
      final streakUpdate = _calculateStreakUpdate(current);

      final updates = <String, dynamic>{
        'files_uploaded': FieldValue.increment(1),
        ...streakUpdate,
      };

      if (needsReset) {
        updates['words_used_this_week'] = wordsAdded;
        updates['week_reset_date'] = Timestamp.fromDate(_nextMonday());
      } else {
        updates['words_used_this_week'] = FieldValue.increment(wordsAdded);
      }

      await doc.update(updates);
    } catch (error) {
      state = UsageState(errorMessage: _friendlyError(error));
    }
  }

  Future<void> recordReviewerGenerated() async {
    try {
      _ensureReady();
      final user = FirebaseAuth.instance.currentUser!;
      final doc = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('usage').doc('current');
      
      final snapshot = await doc.get();
      if (!snapshot.exists) return;
      
      final current = UsageModel.fromFirestore(snapshot.data()!);
      final streakUpdate = _calculateStreakUpdate(current);
      
      await doc.update({
        'reviewers_generated': FieldValue.increment(1),
        ...streakUpdate,
      });
    } catch (error) {
      state = UsageState(errorMessage: _friendlyError(error));
    }
  }

  Map<String, dynamic> _calculateStreakUpdate(UsageModel current) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (current.lastActiveDate == null) {
      return {'streak': 1, 'last_active_date': Timestamp.fromDate(today)};
    }
    
    final lastActive = DateTime(
      current.lastActiveDate!.year,
      current.lastActiveDate!.month,
      current.lastActiveDate!.day,
    );
    
    final difference = today.difference(lastActive).inDays;
    
    if (difference == 1) {
      // Consecutive day
      return {'streak': current.streak + 1, 'last_active_date': Timestamp.fromDate(today)};
    } else if (difference > 1) {
      // Missed a day
      return {'streak': 1, 'last_active_date': Timestamp.fromDate(today)};
    } else {
      // Same day activity, don't update streak
      return {};
    }
  }

  Future<void> upgradeToPro() async {
    try {
      _ensureReady();
      final user = FirebaseAuth.instance.currentUser!;
      final doc = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('usage').doc('current');
      await doc.set({'tier': 'pro'}, SetOptions(merge: true));
    } catch (error) {
      state = UsageState(errorMessage: _friendlyError(error));
    }
  }

  DateTime _nextMonday() {
    final now = DateTime.now();
    var daysUntilMonday = DateTime.monday - now.weekday;
    if (daysUntilMonday <= 0) daysUntilMonday += 7;
    return DateTime(now.year, now.month, now.day).add(Duration(days: daysUntilMonday));
  }

  void _ensureReady() {
    if (Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null) {
      throw StateError('Please sign in before using usage tracking.');
    }
  }

  String _friendlyError(dynamic error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('network') || msg.contains('connection') || msg.contains('socket')) {
      return 'Network error. Please check your internet connection.';
    }
    if (msg.contains('permission') || msg.contains('denied')) {
      return 'Permission denied. Please try again.';
    }
    if (msg.contains('sign in') || msg.contains('current user')) {
      return 'Please sign in to continue.';
    }
    if (msg.contains('quota') || msg.contains('limit')) {
      return 'You have reached your usage limit. Consider upgrading your plan.';
    }
    return 'Something went wrong. Please try again.';
  }
}
