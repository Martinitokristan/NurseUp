class PhilippineTime {
  const PhilippineTime._();

  static DateTime now() =>
      DateTime.now().toUtc().add(const Duration(hours: 8));

  static DateTime nextDailyReset() =>
      now().add(const Duration(hours: 24));

  static DateTime nextWeeklyReset() =>
      now().add(const Duration(days: 7));

  static DateTime toUtc(DateTime phTime) =>
      phTime.subtract(const Duration(hours: 8));

  static DateTime fromUtc(DateTime utcTime) =>
      utcTime.toUtc().add(const Duration(hours: 8));
}
