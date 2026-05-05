import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UsageModel extends Equatable {
  const UsageModel({
    required this.wordsUsedThisWeek,
    required this.weekResetDate,
    required this.tier,
    this.wordsUsedToday = 0,
    this.dailyResetDate,
    this.dailyFileUploads = 0,
    this.weeklyFileUploads = 0,
    this.filesUploaded = 0,
    this.reviewersGenerated = 0,
    this.streak = 0,
    this.lastActiveDate,
  });

  final int wordsUsedThisWeek;
  final DateTime weekResetDate;
  final String tier;
  final int wordsUsedToday;
  final DateTime? dailyResetDate;
  final int dailyFileUploads;
  final int weeklyFileUploads;
  final int filesUploaded;
  final int reviewersGenerated;
  final int streak;
  final DateTime? lastActiveDate;

  factory UsageModel.fromFirestore(Map<String, dynamic> data) {
    final resetDate = data['week_reset_date'];
    final weekReset = resetDate is Timestamp ? resetDate.toDate() : DateTime.now();
    final lastActive = data['last_active_date'];
    final lastActiveDate = lastActive is Timestamp ? lastActive.toDate() : null;
    final dailyReset = data['daily_reset_date'];
    final dailyResetDate = dailyReset is Timestamp ? dailyReset.toDate() : null;
    return UsageModel(
      wordsUsedThisWeek: data['words_used_this_week'] as int? ?? 0,
      weekResetDate: weekReset,
      tier: data['tier'] as String? ?? 'free',
      wordsUsedToday: data['words_used_today'] as int? ?? 0,
      dailyResetDate: dailyResetDate,
      dailyFileUploads: data['daily_file_uploads'] as int? ?? 0,
      weeklyFileUploads: data['weekly_file_uploads'] as int? ?? 0,
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
      'words_used_today': wordsUsedToday,
      'daily_reset_date': dailyResetDate != null ? Timestamp.fromDate(dailyResetDate!) : null,
      'daily_file_uploads': dailyFileUploads,
      'weekly_file_uploads': weeklyFileUploads,
      'files_uploaded': filesUploaded,
      'reviewers_generated': reviewersGenerated,
      'streak': streak,
      'last_active_date': lastActiveDate != null ? Timestamp.fromDate(lastActiveDate!) : null,
    };
  }

  int getDailyWordLimit({int? override}) => override ?? (tier == 'pro' ? 10000 : 500);

  int getDailyRemainingWords({int? override}) =>
      getDailyWordLimit(override: override) - wordsUsedToday;

  bool isDailyLimitReached({int? override}) =>
      wordsUsedToday >= getDailyWordLimit(override: override);

  int getDailyFileLimit({int? override}) => override ?? (tier == 'pro' ? 999999 : 3);

  bool isDailyFileLimitReached({int? override}) =>
      dailyFileUploads >= getDailyFileLimit(override: override);

  /// Deprecated static defaults. Prefer passing the plan's weeklyWordLimit
  /// from `activePlanProvider` so limits stay in sync with Firestore `plans/`.
  int getWeeklyLimit({int? weeklyLimitOverride}) =>
      weeklyLimitOverride ?? (tier == 'pro' ? 50000 : 1000);

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
  List<Object?> get props => [wordsUsedThisWeek, weekResetDate, tier, wordsUsedToday, dailyResetDate, dailyFileUploads, weeklyFileUploads, filesUploaded, reviewersGenerated, streak, lastActiveDate];
}
