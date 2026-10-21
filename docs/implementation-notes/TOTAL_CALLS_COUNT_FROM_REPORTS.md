# Total Calls Count - Calculate from Reports Screen

## Overview

Added two new methods to calculate total calls metrics from the reports screen:

1. **`_getTotalCallsCount()`** - Counts how many reports have call duration > 0
2. **`_getTotalCallDuration()`** - Sums all call durations from reports

---

## Methods Added

### 1. `_getTotalCallsCount(ReportController controller)`

**Purpose:** Count total number of calls (reports with duration > 0)

```dart
int _getTotalCallsCount(ReportController controller) {
  final reports = controller.reports;
  int totalCalls = 0;
  
  for (var report in reports) {
    if (report.callDuration != null && report.callDuration! > 0) {
      totalCalls += 1;  // Count each report with duration > 0 as 1 call
    }
  }
  
  print('ReportsScreen: Total calls count from reports: $totalCalls');
  return totalCalls;
}
```

**Returns:** `int` - Total number of calls

**Example:**
```
Reports:
├─ Report 1: callDuration = 45s ✅ Counted
├─ Report 2: callDuration = 0s ❌ Not counted
├─ Report 3: callDuration = 120s ✅ Counted
└─ Report 4: callDuration = 30s ✅ Counted

Result: 3 calls
```

---

### 2. `_getTotalCallDuration(ReportController controller)`

**Purpose:** Sum all call durations from reports

```dart
int _getTotalCallDuration(ReportController controller) {
  final reports = controller.reports;
  int totalDuration = 0;
  
  for (var report in reports) {
    if (report.callDuration != null && report.callDuration! > 0) {
      totalDuration += report.callDuration!;
    }
  }
  
  print('ReportsScreen: Total call duration from reports: $totalDuration seconds');
  return totalDuration;
}
```

**Returns:** `int` - Total duration in seconds

**Example:**
```
Reports:
├─ Report 1: callDuration = 45s ✅ Added
├─ Report 2: callDuration = 0s ❌ Not added
├─ Report 3: callDuration = 120s ✅ Added
└─ Report 4: callDuration = 30s ✅ Added

Result: 45 + 120 + 30 = 195 seconds (3m 15s)
```

---

## How to Use

### In Reports Screen UI

To display total calls count in the UI:

```dart
Consumer<ReportController>(
  builder: (context, reportController, _) {
    final totalCalls = _getTotalCallsCount(reportController);
    final totalDuration = _getTotalCallDuration(reportController);
    
    return Column(
      children: [
        Text('Total Calls: $totalCalls'),
        Text('Total Duration: ${_formatDuration(totalDuration)}'),
      ],
    );
  },
)
```

### In Dashboard

To show total calls from reports in the home screen:

```dart
final reportController = Provider.of<ReportController>(context, listen: false);
final totalCallsFromReports = _getTotalCallsCount(reportController);

// Use this value in dashboard
Text('Total Calls: $totalCallsFromReports')
```

---

## Data Flow

### How Reports Get Call Duration

```
1. Call ends
   ↓
2. Android sends duration to Flutter
   ↓
3. CallTrackingController stores duration
   ↓
4. Lead/Report created with callDuration
   ↓
5. Report saved to database
   ↓
6. ReportController fetches reports
   ↓
7. _getTotalCallsCount() sums all durations
```

---

## Example Scenarios

### Scenario 1: Today's Reports
```
Date Range: Today (25/3/2026)
Reports:
├─ Enquiry 1: callDuration = 45s
├─ Booking 1: callDuration = 120s
├─ Return 1: callDuration = 0s (missed call)
└─ Feedback 1: callDuration = 30s

_getTotalCallsCount() = 3 calls
_getTotalCallDuration() = 195 seconds (3m 15s)
```

### Scenario 2: Last 7 Days
```
Date Range: Last 7 Days
Reports: 25 total
├─ With duration > 0: 18 calls
├─ With duration = 0: 7 calls
└─ Total duration: 2,450 seconds (40m 50s)

_getTotalCallsCount() = 18 calls
_getTotalCallDuration() = 2,450 seconds
```

### Scenario 3: Specific Store
```
Store: Z-Edappally
Reports: 12 total
├─ With duration > 0: 10 calls
├─ With duration = 0: 2 calls
└─ Total duration: 1,200 seconds (20m)

_getTotalCallsCount() = 10 calls
_getTotalCallDuration() = 1,200 seconds
```

---

## Integration Points

### 1. Reports Screen Header
Add total calls count to the reports screen header:

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text('Call Reports'),
    Text('Total: ${_getTotalCallsCount(reportController)} calls'),
  ],
)
```

### 2. Dashboard Widget
Show total calls from reports in dashboard:

```dart
DashboardCard(
  count: _getTotalCallsCount(reportController).toString(),
  title: 'Total Calls (Reports)',
  icon: Icons.phone,
)
```

### 3. Report Summary
Display summary statistics:

```dart
Column(
  children: [
    Text('Total Calls: ${_getTotalCallsCount(reportController)}'),
    Text('Total Duration: ${_formatDuration(_getTotalCallDuration(reportController))}'),
    Text('Average Duration: ${_getAverageDuration(reportController)}'),
  ],
)
```

---

## Filtering

The methods work with the current report filters:

- **Date Range:** Today, Last 7 Days, This Month, Last Month, Custom
- **Store:** All Stores or specific store
- **Lead Type:** Enquiry, Booking, Return, Feedback

```dart
// Example: Get total calls for specific store and date range
final reportController = Provider.of<ReportController>(context, listen: false);
final totalCalls = _getTotalCallsCount(reportController);
// This automatically uses the current filters from reportController
```

---

## Performance Considerations

- **Time Complexity:** O(n) where n = number of reports
- **Space Complexity:** O(1)
- **Optimization:** Methods iterate through reports once

For large datasets (1000+ reports), consider:
- Caching the result
- Calculating on background thread
- Pagination

---

## File Location

**File:** `frontend/lib/view/reports_screens/reports_screen.dart`  
**Lines:** 176-206  
**Class:** `_ReportsScreenState`

---

## Testing

### Test Case 1: Empty Reports
```dart
reports = []
_getTotalCallsCount() = 0
_getTotalCallDuration() = 0
```

### Test Case 2: All Missed Calls
```dart
reports = [
  {callDuration: 0},
  {callDuration: 0},
  {callDuration: 0},
]
_getTotalCallsCount() = 0
_getTotalCallDuration() = 0
```

### Test Case 3: Mixed Calls
```dart
reports = [
  {callDuration: 45},
  {callDuration: 0},
  {callDuration: 120},
  {callDuration: null},
  {callDuration: 30},
]
_getTotalCallsCount() = 3
_getTotalCallDuration() = 195
```

---

## Related Methods

- `_getReportCount()` - Get count by report type (enquiry, booking, etc.)
- `_getLatestReports()` - Get latest reports with filtering
- `_formatDuration()` - Format duration to readable format

---

## Future Enhancements

1. **Average Call Duration**
   ```dart
   int _getAverageDuration(ReportController controller) {
     final total = _getTotalCallDuration(controller);
     final count = _getTotalCallsCount(controller);
     return count > 0 ? total ~/ count : 0;
   }
   ```

2. **Call Duration Statistics**
   ```dart
   Map<String, int> _getCallStats(ReportController controller) {
     return {
       'total_calls': _getTotalCallsCount(controller),
       'total_duration': _getTotalCallDuration(controller),
       'average_duration': _getAverageDuration(controller),
       'max_duration': _getMaxDuration(controller),
       'min_duration': _getMinDuration(controller),
     };
   }
   ```

3. **Call Duration by Type**
   ```dart
   Map<String, int> _getCallsByType(ReportController controller) {
     // Group calls by lead type and sum durations
   }
   ```
