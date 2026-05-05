import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/philippine_time.dart';
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
  weekResetDate: PhilippineTime.nextWeeklyReset(),
  tier: 'free',
  wordsUsedToday: 0,
  dailyResetDate: PhilippineTime.nextDailyReset(),
  dailyFileUploads: 0,
  weeklyFileUploads: 0,
  filesUploaded: 0,
  reviewersGenerated: 0,
  streak: 0,
);

/// Formats a UTC reset DateTime as a human-readable PH-time string.
String formatPhReset(DateTime utcResetDate) {
  final ph = PhilippineTime.fromUtc(utcResetDate);
  final fmt = DateFormat('MMM d, h:mm a');
  return '${fmt.format(ph)} PHT';
}

class UsageLimitResult {
  const UsageLimitResult({required this.allowed, this.reason, this.resetAt, this.limitType});
  final bool allowed;
  final String? reason;
  final DateTime? resetAt;
  final String? limitType;
}

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

  UsageLimitResult checkUploadLimit({
    required UsageModel usage,
    required int newWords,
    int? weeklyWordLimit,
    int? dailyWordLimit,
    int? dailyFileLimit,
    int newFiles = 1,
  }) {
    final dailyFileMax = dailyFileLimit ?? usage.getDailyFileLimit();
    if (usage.dailyFileUploads + newFiles > dailyFileMax) {
      final resetAt = usage.dailyResetDate ?? PhilippineTime.nextDailyReset();
      return UsageLimitResult(
        allowed: false,
        limitType: 'daily_files',
        resetAt: resetAt,
        reason: 'Daily file limit reached ($dailyFileMax/day). Resets at ${formatPhReset(resetAt)}.',
      );
    }

    final dailyWordMax = dailyWordLimit ?? usage.getDailyWordLimit();
    if (usage.wordsUsedToday + newWords > dailyWordMax) {
      final resetAt = usage.dailyResetDate ?? PhilippineTime.nextDailyReset();
      return UsageLimitResult(
        allowed: false,
        limitType: 'daily_words',
        resetAt: resetAt,
        reason: 'Daily word limit reached ($dailyWordMax words/day). Resets at ${formatPhReset(resetAt)}.',
      );
    }

    final weeklyWordMax = weeklyWordLimit ?? usage.getWeeklyLimit();
    if (usage.wordsUsedThisWeek + newWords > weeklyWordMax) {
      final resetAt = usage.weekResetDate;
      return UsageLimitResult(
        allowed: false,
        limitType: 'weekly_words',
        resetAt: resetAt,
        reason: 'Weekly word limit reached ($weeklyWordMax words/week). Resets at ${formatPhReset(resetAt)}.',
      );
    }

    return const UsageLimitResult(allowed: true);
  }

  Future<void> recordUsage(int wordsAdded) async {
    try {
      _ensureReady();
      final user = FirebaseAuth.instance.currentUser!;
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('usage')
          .doc('current');

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        final nowPh = PhilippineTime.now();
        final nowUtc = nowPh.toUtc();

        if (!snap.exists) {
          tx.set(docRef, {
            'words_used_this_week': wordsAdded,
            'week_reset_date': Timestamp.fromDate(PhilippineTime.toUtc(PhilippineTime.nextWeeklyReset())),
            'tier': 'free',
            'words_used_today': wordsAdded,
            'daily_reset_date': Timestamp.fromDate(PhilippineTime.toUtc(PhilippineTime.nextDailyReset())),
            'daily_file_uploads': 1,
            'weekly_file_uploads': 1,
            'files_uploaded': 1,
            'reviewers_generated': 0,
            'streak': 1,
            'last_active_date': Timestamp.fromDate(nowUtc),
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });
          return;
        }

        final data = snap.data()!;
        final weekResetTs = data['week_reset_date'];
        final weekReset = weekResetTs is Timestamp ? weekResetTs.toDate() : nowUtc;
        final dailyResetTs = data['daily_reset_date'];
        final dailyReset = dailyResetTs is Timestamp ? dailyResetTs.toDate() : nowUtc;

        final needsDailyReset = nowUtc.isAfter(dailyReset) || nowUtc.isAtSameMomentAs(dailyReset);
        final needsWeeklyReset = nowUtc.isAfter(weekReset) || nowUtc.isAtSameMomentAs(weekReset);

        final updates = <String, dynamic>{
          'files_uploaded': FieldValue.increment(1),
          'updated_at': FieldValue.serverTimestamp(),
        };

        if (needsDailyReset) {
          updates['words_used_today'] = wordsAdded;
          updates['daily_file_uploads'] = 1;
          updates['daily_reset_date'] = Timestamp.fromDate(
            PhilippineTime.toUtc(PhilippineTime.nextDailyReset()),
          );
        } else {
          updates['words_used_today'] = FieldValue.increment(wordsAdded);
          updates['daily_file_uploads'] = FieldValue.increment(1);
        }

        if (needsWeeklyReset) {
          updates['words_used_this_week'] = wordsAdded;
          updates['weekly_file_uploads'] = 1;
          updates['week_reset_date'] = Timestamp.fromDate(
            PhilippineTime.toUtc(PhilippineTime.nextWeeklyReset()),
          );
        } else {
          updates['words_used_this_week'] = FieldValue.increment(wordsAdded);
          updates['weekly_file_uploads'] = FieldValue.increment(1);
        }

        final current = UsageModel.fromFirestore(data);
        updates.addAll(_calculateStreakUpdate(current, nowPh));

        tx.update(docRef, updates);
      });
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
      final streakUpdate = _calculateStreakUpdate(current, PhilippineTime.now());
      
      await doc.update({
        'reviewers_generated': FieldValue.increment(1),
        ...streakUpdate,
      });
    } catch (error) {
      state = UsageState(errorMessage: _friendlyError(error));
    }
  }

  Map<String, dynamic> _calculateStreakUpdate(UsageModel current, DateTime nowPh) {
    final todayPh = DateTime(nowPh.year, nowPh.month, nowPh.day);
    final todayUtc = todayPh.toUtc();

    if (current.lastActiveDate == null) {
      return {'streak': 1, 'last_active_date': Timestamp.fromDate(todayUtc)};
    }

    final lastActivePh = PhilippineTime.fromUtc(current.lastActiveDate!);
    final lastActiveDayPh = DateTime(lastActivePh.year, lastActivePh.month, lastActivePh.day);
    final difference = todayPh.difference(lastActiveDayPh).inDays;

    if (difference == 1) {
      return {'streak': current.streak + 1, 'last_active_date': Timestamp.fromDate(todayUtc)};
    } else if (difference > 1) {
      return {'streak': 1, 'last_active_date': Timestamp.fromDate(todayUtc)};
    } else {
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
