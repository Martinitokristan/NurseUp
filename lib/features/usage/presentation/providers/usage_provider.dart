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
        final usage = UsageModel.fromFirestore(doc.data()!);
        if (usage.tier == 'free' &&
            (usage.wordsUsedToday > 500 ||
                usage.dailyFileUploads > 3 ||
                usage.wordsUsedThisWeek > 1000)) {
          final repaired = UsageModel(
            wordsUsedThisWeek: usage.wordsUsedThisWeek.clamp(0, 1000),
            weekResetDate: usage.weekResetDate,
            tier: usage.tier,
            wordsUsedToday: usage.wordsUsedToday.clamp(0, 500),
            dailyResetDate: usage.dailyResetDate,
            dailyFileUploads: usage.dailyFileUploads.clamp(0, 3),
            weeklyFileUploads: usage.weeklyFileUploads,
            filesUploaded: usage.filesUploaded,
            reviewersGenerated: usage.reviewersGenerated,
            streak: usage.streak,
            lastActiveDate: usage.lastActiveDate,
          );
          Future.microtask(() {
            doc.reference.set({
              'words_used_today': repaired.wordsUsedToday,
              'daily_file_uploads': repaired.dailyFileUploads,
              'words_used_this_week': repaired.wordsUsedThisWeek,
              'usage_repaired_at': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          });
          return repaired;
        }
        return usage;
      });
});

UsageModel get _emptyUsage => UsageModel(
  wordsUsedThisWeek: 0,
  weekResetDate: PhilippineTime.toUtc(PhilippineTime.nextWeeklyReset()),
  tier: 'free',
  wordsUsedToday: 0,
  dailyResetDate: PhilippineTime.toUtc(PhilippineTime.nextDailyReset()),
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

class UsageReservationResult {
  const UsageReservationResult({
    required this.allowed,
    this.reason,
    this.limitType,
    this.resetAt,
  });

  final bool allowed;
  final String? reason;
  final String? limitType;
  final DateTime? resetAt;
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
    final nowUtc = DateTime.now().toUtc();
    final dailyReset = usage.dailyResetDate;
    final weeklyReset = usage.weekResetDate;
    final dailyExpired = dailyReset != null && !nowUtc.isBefore(dailyReset);
    final weeklyExpired = !nowUtc.isBefore(weeklyReset);
    final effectiveTodayWords = dailyExpired ? 0 : usage.wordsUsedToday;
    final effectiveWeekWords = weeklyExpired ? 0 : usage.wordsUsedThisWeek;
    final effectiveTodayFiles = dailyExpired ? 0 : usage.dailyFileUploads;

    final weeklyWordMax = weeklyWordLimit ?? usage.getWeeklyLimit();
    if (effectiveWeekWords + newWords > weeklyWordMax) {
      final resetAt = usage.weekResetDate;
      return UsageLimitResult(
        allowed: false,
        limitType: 'weekly_words',
        resetAt: resetAt,
        reason: 'Weekly word limit reached ($weeklyWordMax words/week). Resets at ${formatPhReset(resetAt)}.',
      );
    }

    final dailyWordMax = dailyWordLimit ?? usage.getDailyWordLimit();
    if (effectiveTodayWords + newWords > dailyWordMax) {
      final resetAt = usage.dailyResetDate ?? PhilippineTime.toUtc(PhilippineTime.nextDailyReset());
      return UsageLimitResult(
        allowed: false,
        limitType: 'daily_words',
        resetAt: resetAt,
        reason: 'Daily word limit reached ($dailyWordMax words/day). Resets at ${formatPhReset(resetAt)}.',
      );
    }

    final dailyFileMax = dailyFileLimit ?? usage.getDailyFileLimit();
    if (effectiveTodayFiles + newFiles > dailyFileMax) {
      final resetAt = usage.dailyResetDate ?? PhilippineTime.toUtc(PhilippineTime.nextDailyReset());
      return UsageLimitResult(
        allowed: false,
        limitType: 'daily_files',
        resetAt: resetAt,
        reason: 'Daily file limit reached ($dailyFileMax files/day). Resets at ${formatPhReset(resetAt)}.',
      );
    }

    return const UsageLimitResult(allowed: true);
  }

  Future<void> recordUsage(int wordsAdded) async {
    await reserveUploadUsage(
      wordsAdded: wordsAdded,
      fileCount: 1,
      isPro: FirebaseAuth.instance.currentUser == null ? false : false,
      weeklyWordLimit: 1000,
      dailyWordLimit: 500,
      dailyFileLimit: 3,
    );
  }

  Future<UsageReservationResult> reserveUploadUsage({
    required int wordsAdded,
    required int fileCount,
    required bool isPro,
    required int weeklyWordLimit,
    required int dailyWordLimit,
    required int dailyFileLimit,
  }) async {
    try {
      _ensureReady();
      final user = FirebaseAuth.instance.currentUser!;
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('usage')
          .doc('current');

      return await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        final nowPh = PhilippineTime.now();
        final nowUtc = PhilippineTime.toUtc(nowPh);
        final nextDailyResetUtc = PhilippineTime.toUtc(PhilippineTime.nextDailyReset());
        final nextWeeklyResetUtc = PhilippineTime.toUtc(PhilippineTime.nextWeeklyReset());

        int currentWeekWords = 0;
        int currentTodayWords = 0;
        int currentTodayFiles = 0;
        int currentWeeklyFiles = 0;
        int currentFilesUploaded = 0;
        int currentReviewersGenerated = 0;
        int currentStreak = 0;
        DateTime? currentLastActiveDate;
        DateTime weekReset = nextWeeklyResetUtc;
        DateTime dailyReset = nextDailyResetUtc;
        String tier = isPro ? 'pro' : 'free';

        if (snap.exists) {
          final data = snap.data()!;
          final current = UsageModel.fromFirestore(data);
          tier = data['tier'] as String? ?? tier;
          currentWeekWords = current.wordsUsedThisWeek;
          currentTodayWords = current.wordsUsedToday;
          currentTodayFiles = current.dailyFileUploads;
          currentWeeklyFiles = current.weeklyFileUploads;
          currentFilesUploaded = current.filesUploaded;
          currentReviewersGenerated = current.reviewersGenerated;
          currentStreak = current.streak;
          currentLastActiveDate = current.lastActiveDate;
          weekReset = current.weekResetDate;
          dailyReset = current.dailyResetDate ?? nextDailyResetUtc;

          if (!nowUtc.isBefore(dailyReset)) {
            currentTodayWords = 0;
            currentTodayFiles = 0;
            dailyReset = nextDailyResetUtc;
          }

          if (!nowUtc.isBefore(weekReset)) {
            currentWeekWords = 0;
            currentWeeklyFiles = 0;
            weekReset = nextWeeklyResetUtc;
          }
        }

        if (currentWeekWords + wordsAdded > weeklyWordLimit) {
          return UsageReservationResult(
            allowed: false,
            limitType: 'weekly_words',
            resetAt: weekReset,
            reason: 'Weekly word limit reached ($weeklyWordLimit words/week). Please come back at ${formatPhReset(weekReset)}.',
          );
        }

        if (currentTodayWords + wordsAdded > dailyWordLimit) {
          return UsageReservationResult(
            allowed: false,
            limitType: 'daily_words',
            resetAt: dailyReset,
            reason: 'Daily word limit reached ($dailyWordLimit words/day). Please come back at ${formatPhReset(dailyReset)}.',
          );
        }

        if (currentTodayFiles + fileCount > dailyFileLimit) {
          return UsageReservationResult(
            allowed: false,
            limitType: 'daily_files',
            resetAt: dailyReset,
            reason: 'Daily file limit reached ($dailyFileLimit files/day). Please come back at ${formatPhReset(dailyReset)}.',
          );
        }

        final updatedUsage = UsageModel(
          wordsUsedThisWeek: currentWeekWords + wordsAdded,
          weekResetDate: weekReset,
          tier: tier,
          wordsUsedToday: currentTodayWords + wordsAdded,
          dailyResetDate: dailyReset,
          dailyFileUploads: currentTodayFiles + fileCount,
          weeklyFileUploads: currentWeeklyFiles + fileCount,
          filesUploaded: currentFilesUploaded + fileCount,
          reviewersGenerated: currentReviewersGenerated,
          streak: currentStreak,
          lastActiveDate: currentLastActiveDate,
        );
        final streakUpdate = _calculateStreakUpdate(updatedUsage, nowPh);

        tx.set(docRef, {
          'tier': tier,
          'words_used_this_week': currentWeekWords + wordsAdded,
          'week_reset_date': Timestamp.fromDate(weekReset),
          'words_used_today': currentTodayWords + wordsAdded,
          'daily_reset_date': Timestamp.fromDate(dailyReset),
          'daily_file_uploads': currentTodayFiles + fileCount,
          'weekly_file_uploads': currentWeeklyFiles + fileCount,
          'files_uploaded': currentFilesUploaded + fileCount,
          'reviewers_generated': currentReviewersGenerated,
          ...streakUpdate,
          'updated_at': FieldValue.serverTimestamp(),
          if (!snap.exists) 'created_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return const UsageReservationResult(allowed: true);
      });
    } catch (error) {
      final message = _friendlyError(error);
      state = UsageState(errorMessage: message);
      return UsageReservationResult(allowed: false, reason: message);
    }
  }

  Future<void> refundUploadUsage({
    required int words,
    required int fileCount,
  }) async {
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
        if (!snap.exists) return;
        final usage = UsageModel.fromFirestore(snap.data()!);
        tx.update(docRef, {
          'words_used_today': (usage.wordsUsedToday - words).clamp(0, 1 << 31),
          'words_used_this_week': (usage.wordsUsedThisWeek - words).clamp(0, 1 << 31),
          'daily_file_uploads': (usage.dailyFileUploads - fileCount).clamp(0, 1 << 31),
          'weekly_file_uploads': (usage.weeklyFileUploads - fileCount).clamp(0, 1 << 31),
          'files_uploaded': (usage.filesUploaded - fileCount).clamp(0, 1 << 31),
          'updated_at': FieldValue.serverTimestamp(),
        });
      });
    } catch (_) {}
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
    final todayUtc = PhilippineTime.toUtc(todayPh);

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
