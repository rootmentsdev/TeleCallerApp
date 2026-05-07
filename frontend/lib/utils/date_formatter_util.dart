/// Centralized date formatting utility
/// Eliminates duplication of date formatting logic across the app

class DateFormatterUtil {
  /// Month abbreviations for formatting
  static const List<String> _monthAbbreviations = [
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

  /// Format date as "DD MMM, YYYY" (e.g., "20 Apr, 2026")
  static String formatDate(DateTime date) {
    final month = _monthAbbreviations[date.month - 1];
    return "${date.day} $month, ${date.year}";
  }

  /// Format date for API calls as "YYYY-MM-DD"
  static String formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Format date and time as "DD MMM, YYYY HH:mm"
  static String formatDateTime(DateTime dateTime) {
    final date = formatDate(dateTime);
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  /// Format call duration in seconds to readable format
  /// Returns "HH:mm:ss" or "mm:ss" if less than an hour
  static String formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '0s';

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  /// Parse date from various formats
  /// Handles ISO 8601, MongoDB format, and manual parsing
  static DateTime? parseDate(dynamic dateValue) {
    if (dateValue == null) return null;

    // Handle MongoDB date format: {"$date": "2026-04-05T..."}
    if (dateValue is Map) {
      final dateStr =
          dateValue['\$date']?.toString() ?? dateValue['date']?.toString();
      if (dateStr != null && dateStr.isNotEmpty) {
        try {
          return DateTime.parse(dateStr);
        } catch (e) {
          return null;
        }
      }
    }

    final dateStr = dateValue.toString().trim();
    if (dateStr.isEmpty) return null;

    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      // Try manual parsing for non-ISO formats
      final parts = dateStr.split(RegExp(r'[-/]'));
      if (parts.length == 3) {
        try {
          final nums = parts.map((p) => int.parse(p)).toList();
          // Try different orderings: yyyy-MM-dd, dd-MM-yyyy, MM/dd/yyyy
          if (nums[0] > 31) return DateTime(nums[0], nums[1], nums[2]);
          if (nums[2] > 31) return DateTime(nums[2], nums[1], nums[0]);
          return DateTime(nums[2], nums[0], nums[1]);
        } catch (e) {
          return null;
        }
      }
      return null;
    }
  }

  /// Get relative time string (e.g., "2 days ago", "in 3 hours")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      // Future date
      final absDiff = difference.abs();
      if (absDiff.inSeconds < 60) return 'in a few seconds';
      if (absDiff.inMinutes < 60) return 'in ${absDiff.inMinutes} minutes';
      if (absDiff.inHours < 24) return 'in ${absDiff.inHours} hours';
      if (absDiff.inDays < 7) return 'in ${absDiff.inDays} days';
      return 'in ${(absDiff.inDays / 7).ceil()} weeks';
    } else {
      // Past date
      if (difference.inSeconds < 60) return 'just now';
      if (difference.inMinutes < 60)
        return '${difference.inMinutes} minutes ago';
      if (difference.inHours < 24) return '${difference.inHours} hours ago';
      if (difference.inDays < 7) return '${difference.inDays} days ago';
      if (difference.inDays < 30)
        return '${(difference.inDays / 7).floor()} weeks ago';
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Get date range label (e.g., "Apr 18 - Apr 25, 2026")
  static String formatDateRange(DateTime startDate, DateTime endDate) {
    if (startDate.year == endDate.year && startDate.month == endDate.month) {
      // Same month
      final month = _monthAbbreviations[startDate.month - 1];
      return '${startDate.day} - ${endDate.day} $month, ${startDate.year}';
    } else if (startDate.year == endDate.year) {
      // Same year, different month
      final startMonth = _monthAbbreviations[startDate.month - 1];
      final endMonth = _monthAbbreviations[endDate.month - 1];
      return '${startDate.day} $startMonth - ${endDate.day} $endMonth, ${startDate.year}';
    } else {
      // Different year
      final startMonth = _monthAbbreviations[startDate.month - 1];
      final endMonth = _monthAbbreviations[endDate.month - 1];
      return '${startDate.day} $startMonth, ${startDate.year} - ${endDate.day} $endMonth, ${endDate.year}';
    }
  }
}
