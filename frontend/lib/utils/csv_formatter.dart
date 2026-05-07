import 'package:intl/intl.dart';

class CsvFormatter {
  /// Format reports to CSV with metadata, summary, and detailed data
  static String formatReportsToCsv({
    required List<Map<String, dynamic>> reports,
    required String dateRangeLabel,
    required DateTime exportDate,
    String? storeFilter,
  }) {
    final buffer = StringBuffer();

    // Add metadata section
    buffer.writeln('CALL REPORT EXPORT');
    buffer.writeln('Date Range,${dateRangeLabel}');
    buffer.writeln(
      'Export Date,${DateFormat('dd MMM, yyyy HH:mm').format(exportDate)}',
    );
    buffer.writeln('Total Records,${reports.length}');
    if (storeFilter != null) {
      buffer.writeln('Store Filter,$storeFilter');
    }
    buffer.writeln('');

    // Add summary section
    buffer.writeln('SUMMARY');
    final summaryByType = _calculateSummary(reports);
    for (final entry in summaryByType.entries) {
      buffer.writeln('${entry.key},${entry.value}');
    }
    buffer.writeln('');

    // Add detailed report header
    buffer.writeln('DETAILED REPORT');
    buffer.writeln(
      'ID,Name,Phone,Store,Type,Status,Duration (sec),Call Date,Remarks',
    );

    // Add report rows
    for (final report in reports) {
      final id = _escapeCsv(report['id']?.toString() ?? '');
      final name = _escapeCsv(report['name']?.toString() ?? '');
      // Force phone as text by prefixing with single quote to prevent scientific notation
      final phone = "'${_escapeCsv(report['phone']?.toString() ?? '')}";
      final store = _escapeCsv(report['storeName']?.toString() ?? '');
      final typeRaw = report['type']?.toString() ?? '';
      final type = _escapeCsv(_convertTypeToDisplayLabel(typeRaw));
      final status = _escapeCsv(report['leadStatus']?.toString() ?? '');
      final duration = report['callDuration']?.toString() ?? '0';
      final callDate = _escapeCsv(
        report['callDateFormatted']?.toString() ?? '',
      );
      final remarks = _escapeCsv(report['remarks']?.toString() ?? '');

      buffer.writeln(
        '$id,$name,$phone,$store,$type,$status,$duration,$callDate,$remarks',
      );
    }

    return buffer.toString();
  }

  /// Generate filename for CSV export
  static String generateFileName(String dateRangeLabel) {
    final now = DateTime.now();
    final dateStr = DateFormat('ddMMyyyy').format(now);
    final timeStr = DateFormat('HHmmss').format(now);
    return 'CallReport_${dateRangeLabel}_${dateStr}_$timeStr.csv';
  }

  /// Calculate summary statistics by call type
  static Map<String, int> _calculateSummary(
    List<Map<String, dynamic>> reports,
  ) {
    final summary = <String, int>{};
    for (final report in reports) {
      final typeRaw = report['type']?.toString() ?? 'general';
      final type = _convertTypeToDisplayLabel(typeRaw);
      summary[type] = (summary[type] ?? 0) + 1;
    }
    return summary;
  }

  /// Convert internal type value to display label
  static String _convertTypeToDisplayLabel(String type) {
    switch (type.toLowerCase()) {
      case 'hardout':
        return 'Feedback';
      case 'enquiry':
        return 'Enquiry';
      case 'booking':
        return 'Booked';
      case 'return':
        return 'Feedback';
      case 'bookingconfirmation':
        return 'Booking Confirmation';
      case 'general':
        return 'General';
      default:
        return type;
    }
  }

  /// Escape CSV values (handle commas, quotes, newlines)
  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
