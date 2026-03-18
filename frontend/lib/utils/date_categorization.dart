/// Date categorization utility for filtering reports and leads
class DateCategorization {
  /// Date category types
  static const String today = 'Today';
  static const String last7Days = 'Last 7 Days';
  static const String thisMonth = 'This Month';
  static const String lastMonth = 'Last Month';

  /// Get date range for a category
  static DateRange getDateRange(String category) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (category) {
      case DateCategorization.today:
        return DateRange(
          start: today,
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );

      case DateCategorization.last7Days:
        final sevenDaysAgo = today.subtract(const Duration(days: 7));
        return DateRange(
          start: sevenDaysAgo,
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );

      case DateCategorization.thisMonth:
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        return DateRange(
          start: firstDayOfMonth,
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );

      case DateCategorization.lastMonth:
        final firstDayOfLastMonth = DateTime(now.year, now.month - 1, 1);
        final lastDayOfLastMonth = DateTime(now.year, now.month, 0);
        return DateRange(
          start: firstDayOfLastMonth,
          end: DateTime(
            lastDayOfLastMonth.year,
            lastDayOfLastMonth.month,
            lastDayOfLastMonth.day,
            23,
            59,
            59,
          ),
        );

      default:
        return DateRange(
          start: today,
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
    }
  }

  /// Check if a date falls within a category
  static bool isDateInCategory(DateTime date, String category) {
    final range = getDateRange(category);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final normalizedEnd = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
    );

    return normalizedDate.compareTo(normalizedStart) >= 0 &&
        normalizedDate.compareTo(normalizedEnd) <= 0;
  }

  /// Get all available categories
  static List<String> getAllCategories() {
    return [last7Days, today, thisMonth, lastMonth];
  }
}

/// Date range model
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});

  @override
  String toString() => 'DateRange($start to $end)';
}
