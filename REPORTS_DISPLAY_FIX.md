# Reports Display Fix - Enquiry Leads Not Showing

## Problem
- Enquiry leads were being counted correctly (4 enquiry leads shown in count)
- But they were NOT displaying in "Latest Call Report" section
- Only feedback lead was showing

## Root Cause
The `getFilteredLeads()` method in `ReportController` was filtering reports by call status:
```dart
.where((report) {
  final callStatus = leadData['callStatus']?.toString() ?? '';
  return callStatus.isEmpty || LeadConstants.isCalledStatus(callStatus);
})
```

This filter only included leads with specific "called" statuses (like "Connected", "Not Interested", etc.), but enquiry leads have `callStatus: "Not Called"` which doesn't match the `isCalledStatus()` check.

## Solution
Removed the call status filter entirely. Reports screen should display ALL reports from the backend regardless of call status:

```dart
// Before: Filtered by call status
List<Map<String, dynamic>> filteredReports =
    _reports
        .where((report) { ... })
        .map((report) { ... })

// After: Show all reports
List<Map<String, dynamic>> filteredReports =
    _reports.map((report) { ... })
```

## Changes Made
**File**: `frontend/lib/controller/report_controller.dart`

1. Removed `.where()` filter that checked `LeadConstants.isCalledStatus(callStatus)`
2. Changed to directly map all reports without filtering
3. Added debug logging to track which reports are being processed
4. Removed duplicate `callStatus` variable declaration

## Expected Behavior
✅ All 5 reports now display in "Latest Call Report" section
✅ 4 enquiry leads show with "Enquiry" badge
✅ 1 feedback lead shows with "Feedback" badge
✅ Counts remain correct (Enquiry: 4, Feedback: 1, Booking: 0)

## Debug Output
```
ReportController: Processing report - name: test, callStatus: Not Called, leadType: enquiry
ReportController: Processing report - name: test, callStatus: Not Called, leadType: enquiry
ReportController: Processing report - name: test, callStatus: Not Called, leadType: enquiry
ReportController: Processing report - name: test, callStatus: Not Called, leadType: enquiry
ReportController: Processing report - name: NIXON, callStatus: Connected, leadType: return
```

All reports are now processed and displayed regardless of call status.
