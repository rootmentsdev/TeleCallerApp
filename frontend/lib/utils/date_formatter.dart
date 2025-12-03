/// Utility class for date formatting
class DateFormatter {
  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Format date as "DD MMM YYYY" (e.g., "15 Jan 2025")
  static String formatDate(DateTime date) {
    return "${date.day} ${_months[date.month - 1]} ${date.year}";
  }

  /// Format date as "DD/MM/YYYY" (e.g., "15/01/2025")
  static String formatDateShort(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
