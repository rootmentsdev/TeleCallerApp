# Report Display Bug Analysis - Last Month Shows Data But View All Shows Empty

## Problem Summary

When viewing the Reports screen:
- **Last Month button**: Shows data in the summary (4 Booking Confirmation Calls, 28 Enquiry Calls, etc.)
- **View All button**: Shows "No call reports found" when clicking to see the full list

## Root Cause Analysis

### Issue 1: Two Different Data Sources
The reports screen uses **two different data sources** that are not synchronized:

1. **Summary Section** (reports_screen.dart):
   - Uses `ReportController.reports` (from API)
   - Fetches from `/leads/completed` endpoint
   - Shows aggregated counts

2. **View All Section** (call_report_list_screen.dart):
   - Uses `ReportController.reports` (same source)
   - But applies **local date filtering** using `DateCategorization.isDateInCategory()`
   - Filters by `callDate` field which is a **formatted string** (e.g., "25 Mar, 2026")

### Issue 2: Date Filtering Logic Mismatch

**In call_report_list_screen.dart** (lines 100-120):
```dart
List<Map<String, dynamic>> _getFilteredReports(...) {
  final dateFilteredReports = allReports.where((report) {
    try {
      dynamic callDateValue = report['callDate'];
      
      if (callDateValue == null) return false;
      
      // callDate is formatted as string (e.g., "25 Mar, 2026")
      DateTime reportDate;
      if (callDateValue is String) {
        try {
          reportDate = DateTime.parse(callDateValue);  // ❌ FAILS!
        } catch (_) {
          reportDate = DateTime.now();  // Falls back to today
        }
      }
      
      // Then filters using DateCategorization
      return DateCategorization.isDateInCategory(
        normalizedReportDate,
        _selectedTimeRange,
      );
    } catch (e) {
      return false;  // ❌ Returns false on error
    }
  }).toList();
}
```

**The Problem**:
1. `callDate` is formatted as "25 Mar, 2026" (from `_formatDate()`)
2. `DateTime.parse()` expects ISO 8601 format: "2026-03-25"
3. Parsing fails → falls back to `DateTime.now()`
4. If today is not in "Last Month", the report is filtered out
5. Result: Empty list

### Issue 3: API Response Format Mismatch

**In report_controller.dart** (line 360):
```dart
"callDate": report.editedAt != null
    ? _formatDate(report.editedAt!)
    : _formatDate(createdAt),
```

The `callDate` is stored as a **formatted string**, not a DateTime object.

But in **call_report_list_screen.dart**, it tries to parse this formatted string as ISO 8601:
```dart
reportDate = DateTime.parse(callDateValue);  // Expects "2026-03-25"
// But gets "25 Mar, 2026" instead
```

## Why Summary Works But View All Doesn't

### Summary Section (Works ✅)
```dart
// reports_screen.dart
String _getReportCount(ReportController controller, String type) {
  final reports = controller.reports;  // Gets all reports from API
  
  switch (type) {
    case 'enquiry':
      return reports
          .where((r) => r.leadType?.toLowerCase() == 'enquiry')
          .length
          .toString();
  }
}
```
- Directly counts from `controller.reports`
- No date filtering applied
- Shows all reports regardless of date

### View All Section (Broken ❌)
```dart
// call_report_list_screen.dart
List<Map<String, dynamic>> _getFilteredReports(...) {
  final dateFilteredReports = allReports.where((report) {
    dynamic callDateValue = report['callDate'];  // "25 Mar, 2026"
    
    DateTime reportDate;
    if (callDateValue is String) {
      try {
        reportDate = DateTime.parse(callDateValue);  // ❌ FAILS
      } catch (_) {
        reportDate = DateTime.now();  // Falls back to today
      }
    }
    
    return DateCategorization.isDateInCategory(
      reportDate,
      _selectedTimeRange,  // "Last Month"
    );
  }).toList();
}
```
- Tries to parse formatted date string
- Parsing fails → falls back to today's date
- Today is not in "Last Month" → filtered out
- Result: Empty list

## Solution

### Fix 1: Store Date as ISO 8601 String (Recommended)
**File**: `frontend/lib/controller/report_controller.dart`

Change from:
```dart
"callDate": report.editedAt != null
    ? _formatDate(report.editedAt!)
    : _formatDate(createdAt),
```

To:
```dart
"callDate": report.editedAt != null
    ? report.editedAt!.toIso8601String()
    : createdAt.toIso8601String(),
"callDateFormatted": report.editedAt != null
    ? _formatDate(report.editedAt!)
    : _formatDate(createdAt),
```

Then use `callDate` for filtering and `callDateFormatted` for display.

### Fix 2: Use DateFormatterUtil for Parsing
**File**: `frontend/lib/view/reports_screens/call_report_list_screen.dart`

Change from:
```dart
if (callDateValue is String) {
  try {
    reportDate = DateTime.parse(callDateValue);
  } catch (_) {
    reportDate = DateTime.now();
  }
}
```

To:
```dart
if (callDateValue is String) {
  reportDate = DateFormatterUtil.parseDate(callDateValue) ?? DateTime.now();
}
```

### Fix 3: Use Actual DateTime Objects
**File**: `frontend/lib/view/reports_screens/call_report_list_screen.dart`

Store the actual DateTime in the report map:
```dart
"callDateObj": report.editedAt ?? createdAt,
```

Then filter using the DateTime object:
```dart
DateTime reportDate = report['callDateObj'] as DateTime;
return DateCategorization.isDateInCategory(reportDate, _selectedTimeRange);
```

## Implementation Steps

1. **Update report_controller.dart**:
   - Add `callDateObj` field with actual DateTime
   - Keep `callDate` as ISO 8601 string for filtering
   - Keep `callDateFormatted` for display

2. **Update call_report_list_screen.dart**:
   - Use `callDateObj` for date filtering
   - Use `callDateFormatted` for display
   - Remove the problematic `DateTime.parse()` call

3. **Test**:
   - Select "Last Month" in reports screen
   - Click "View All"
   - Verify reports are displayed correctly

## Files to Modify
- `frontend/lib/controller/report_controller.dart` (line ~360)
- `frontend/lib/view/reports_screens/call_report_list_screen.dart` (line ~100-120)

## Expected Outcome
After fix:
- ✅ Summary shows correct counts
- ✅ View All shows reports with correct date filtering
- ✅ All date ranges work (Today, Last 7 Days, This Month, Last Month)
- ✅ Custom date ranges work correctly
