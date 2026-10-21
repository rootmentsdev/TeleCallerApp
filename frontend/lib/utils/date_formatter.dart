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
    final local = date.toLocal();
    return "${local.day} ${_months[local.month - 1]} ${local.year}";
  }

  /// Format date as "DD/MM/YYYY" (e.g., "15/01/2025")
  static String formatDateShort(DateTime date) {
    final local = date.toLocal();
    return "${local.day}/${local.month}/${local.year}";
  }
}
