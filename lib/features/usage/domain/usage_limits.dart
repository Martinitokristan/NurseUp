class UsageLimits {
  const UsageLimits({
    required this.dailyWords,
    required this.weeklyWords,
    required this.dailyFiles,
  });

  final int dailyWords;
  final int weeklyWords;
  final int dailyFiles;
}

const freeUsageLimits = UsageLimits(
  dailyWords: 500,
  weeklyWords: 1000,
  dailyFiles: 3,
);

const proUsageLimits = UsageLimits(
  dailyWords: 1000,
  weeklyWords: 5000,
  dailyFiles: 999999,
);

UsageLimits usageLimitsForPlan(bool isPro) => isPro ? proUsageLimits : freeUsageLimits;
