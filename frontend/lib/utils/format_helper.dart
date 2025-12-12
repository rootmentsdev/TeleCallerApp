/// Helper functions for formatting data
class FormatHelper {
  /// Format call duration from seconds to readable format
  /// Returns "00:00" for null or 0 seconds
  /// Returns "MM:SS" for durations less than 1 hour
  /// Returns "HH:MM:SS" for durations 1 hour or more
  static String formatCallDuration(int? seconds) {
    if (seconds == null || seconds <= 0) {
      return "00:00";
    }

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
    } else {
      return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
    }
  }

  /// Format call duration to human-readable format with units
  /// Returns "Xm Ys" format (e.g., "2m 30s", "45s")
  static String formatCallDurationWithUnits(int? seconds) {
    if (seconds == null || seconds <= 0) {
      return "0s";
    }

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes > 0) {
      return "${minutes}m ${remainingSeconds}s";
    } else {
      return "${remainingSeconds}s";
    }
  }
}
