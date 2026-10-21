# Enquiry and Booking Reports Fix

## Problem
- Enquiry leads were showing in "Enquiry Calls" count but also mixed with "Booking Calls"
- Booking leads were not appearing in reports
- The counts were incorrect

## Root Cause
When creating a booking lead, the API service normalizes the leadType from "Booking" to "booked" before sending to backend:
```dart
if (normalizedLeadType == 'booking') {
  normalizedLeadType = 'booked';
}
```

However, the reports screen was only checking for `"bookingconfirmation"` when counting booking leads, not `"booked"`.

## Fixes Applied

### 1. Reports Screen - Updated Booking Count Logic
**File**: `frontend/lib/view/reports_screens/reports_screen.dart`

Changed from:
```dart
case 'booking':
  final count = reports
      .where((r) => r.leadType?.toLowerCase() == 'bookingconfirmation')
      .length;
```

To:
```dart
case 'booking':
  final count = reports
      .where((r) {
        final lt = r.leadType?.toLowerCase() ?? '';
        return lt == 'bookingconfirmation' || lt == 'booked';
      })
      .length;
```

### 2. Report Controller - Updated Type Conversion
**File**: `frontend/lib/controller/report_controller.dart`

Added "booked" case to `_getTypeFromLeadType()`:
```dart
case "bookingconfirmation":
case "booked": // Backend returns "booked" when we send "booked"
  return "booking";
```

### 3. Report Model - Added Debug Logging
**File**: `frontend/lib/model/report_model.dart`

Added logging to track what leadType values are being extracted:
```dart
print('ReportModel: Extracted leadType: "$extractedLeadType" from JSON keys: ${json.keys.toList()}');
```

### 4. Reports Screen - Added Debug Logging
**File**: `frontend/lib/view/reports_screens/reports_screen.dart`

Added logging to see all reports and their leadType values:
```dart
print('ReportsScreen: Total reports: ${reports.length}');
for (var r in reports) {
  print('ReportsScreen: Report leadType: "${r.leadType}" (name: ${r.leadData?['name']})');
}
```

## Expected Behavior After Fix

✅ Enquiry leads show correct count in "Enquiry Calls"
✅ Booking leads show correct count in "Booking Calls"
✅ Feedback leads show correct count in "Feedback Calls"
✅ No mixing of lead types in counts
✅ All leads display correctly in Latest Call Report section

## Data Flow

1. User creates Booking lead → API sends `lead_type: "booked"`
2. Backend stores and returns `leadType: "booked"`
3. ReportModel extracts `leadType: "booked"`
4. Reports screen checks for both "booked" and "bookingconfirmation"
5. Booking count increments correctly
6. Display shows "Booking" label via `_getTypeFromLeadType()`

## Debug Output

When running the app, check logs for:
```
ReportModel: Extracted leadType: "enquiry" from JSON keys: [...]
ReportModel: Extracted leadType: "booked" from JSON keys: [...]
ReportModel: Extracted leadType: "return" from JSON keys: [...]
ReportsScreen: Total reports: 5
ReportsScreen: Report leadType: "enquiry" (name: John)
ReportsScreen: Enquiry count: 2
ReportsScreen: Booking count: 2
ReportsScreen: Feedback count: 1
```
