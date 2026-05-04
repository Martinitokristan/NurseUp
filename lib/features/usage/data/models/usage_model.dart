import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UsageModel extends Equatable {
  const UsageModel({
    required this.wordsUsedThisWeek,
    required this.weekResetDate,
    required this.tier,
    this.filesUploaded = 0,
    this.reviewersGenerated = 0,
    this.streak = 0,
    this.lastActiveDate,
  });

  final int wordsUsedThisWeek;
  final DateTime weekResetDate;
  final String tier;
  final int filesUploaded;
  final int reviewersGenerated;
  final int streak;
  final DateTime? lastActiveDate;

  factory UsageModel.fromFirestore(Map<String, dynamic> data) {
    final resetDate = data['week_reset_date'];
    final weekReset = resetDate is Timestamp ? resetDate.toDate() : DateTime.now();
    final lastActive = data['last_active_date'];
    final lastActiveDate = lastActive is Timestamp ? lastActive.toDate() : null;
    return UsageModel(
      wordsUsedThisWeek: data['words_used_this_week'] as int? ?? 0,
      weekResetDate: weekReset,
      tier: data['tier'] as String? ?? 'free',
      filesUploaded: data['files_uploaded'] as int? ?? 0,
      reviewersGenerated: data['reviewers_generated'] as int? ?? 0,
      streak: data['streak'] as int? ?? 0,
      lastActiveDate: lastActiveDate,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'words_used_this_week': wordsUsedThisWeek,
      'week_reset_date': Timestamp.fromDate(weekResetDate),
      'tier': tier,
      'files_uploaded': filesUploaded,
      'reviewers_generated': reviewersGenerated,
      'streak': streak,
      'last_active_date': lastActiveDate != null ? Timestamp.fromDate(lastActiveDate!) : null,
    };
  }

  /// Deprecated static defaults. Prefer passing the plan's weeklyWordLimit
  /// from `activePlanProvider` so limits stay in sync with Firestore `plans/`.
  int getWeeklyLimit({int? weeklyLimitOverride}) =>
      weeklyLimitOverride ?? (tier == 'pro' ? 50000 : 500);

  int getRemainingWords({int? weeklyLimitOverride}) =>
      getWeeklyLimit(weeklyLimitOverride: weeklyLimitOverride) -
      wordsUsedThisWeek;

  double getUsagePercentage({int? weeklyLimitOverride}) {
    final limit = getWeeklyLimit(weeklyLimitOverride: weeklyLimitOverride);
    if (limit <= 0) return 0;
    return wordsUsedThisWeek / limit;
  }

  bool canUpload(int newWords, {int? weeklyLimitOverride}) =>
      (wordsUsedThisWeek + newWords) <=
      getWeeklyLimit(weeklyLimitOverride: weeklyLimitOverride);

  bool isLimitReached({int? weeklyLimitOverride}) =>
      wordsUsedThisWeek >=
      getWeeklyLimit(weeklyLimitOverride: weeklyLimitOverride);

  @override
  List<Object?> get props => [wordsUsedThisWeek, weekResetDate, tier, filesUploaded, reviewersGenerated, streak, lastActiveDate];
}
