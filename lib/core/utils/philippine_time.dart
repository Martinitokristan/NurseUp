class PhilippineTime {
  const PhilippineTime._();

  static const Duration offset = Duration(hours: 8);

  static DateTime now() => DateTime.now().toUtc().add(offset);

  static DateTime toUtc(DateTime phTime) => phTime.subtract(offset);

  static DateTime fromUtc(DateTime utcTime) => utcTime.toUtc().add(offset);

  static DateTime startOfToday() {
    final current = now();
    return DateTime(current.year, current.month, current.day);
  }

  static DateTime nextDailyReset() {
    final today = startOfToday();
    return today.add(const Duration(days: 1));
  }

  static DateTime startOfWeek() {
    final current = now();
    final today = DateTime(current.year, current.month, current.day);
    return today.subtract(Duration(days: current.weekday - DateTime.monday));
  }

  static DateTime nextWeeklyReset() {
    final start = startOfWeek();
    return start.add(const Duration(days: 7));
  }

  /// Calculates the rolling daily reset time: 24 hours from the given UTC start time.
  static DateTime rollingDailyResetFrom(DateTime startUtc) =>
      startUtc.add(const Duration(hours: 24));

  /// Calculates the rolling weekly reset time: 7 days from the given UTC start time.
  static DateTime rollingWeeklyResetFrom(DateTime startUtc) =>
      startUtc.add(const Duration(days: 7));
}
