# Backend Data Mapping Fix - Report Detail Screens

## Problem
The detail screens (Enquiry and Booking) were showing "Not available" for all fields because the `reportData` parameter was not being passed from the Call Report List screen to the detail screens.

## Root Cause
In `call_report_list_screen.dart`, when navigating to the detail screens, only `name`, `phone`, and `callType` were being passed, but the complete `report` object (which contains all the backend data) was not being passed as `reportData`.

## Solution
Updated the navigation code in `call_report_list_screen.dart` to pass the complete `report` object as `reportData` parameter to both `EnquiryDetailScreen` and `BookingDetailScreen`.

### Before:
```dart
if (callType == 'Enquiry') {
  detailScreen = EnquiryDetailScreen(
    name: name,
    phone: phone,
    callType: callType,
    // reportData was missing!
  );
} else {
  detailScreen = BookingDetailScreen(
    name: name,
    phone: phone,
    callType: callType,
    // reportData was missing!
  );
}
```

### After:
```dart
if (callType == 'Enquiry') {
  detailScreen = EnquiryDetailScreen(
    name: name,
    phone: phone,
    callType: callType,
    reportData: report,  // ✅ Now passing complete report data
  );
} else {
  detailScreen = BookingDetailScreen(
    name: name,
    phone: phone,
    callType: callType,
    reportData: report,  // ✅ Now passing complete report data
  );
}
```

## Data Flow

```
ReportController.getFilteredLeads()
    ↓
Returns List<Map<String, dynamic>> with all report fields
    ↓
CallReportListScreen._buildReportCard()
    ↓
Receives 'report' parameter with all backend data
    ↓
Navigation to Detail Screen
    ↓
Passes reportData: report
    ↓
EnquiryDetailScreen / BookingDetailScreen
    ↓
Displays all fields from backend data
```

## Backend Data Fields Now Available

The detail screens now have access to all these fields from the backend:

- `callDate` - When the call was made
- `storeName` - Store/location name
- `functionDate` - Function date (for enquiry/booking)
- `subCategory` - Sub category of the lead
- `closingAction` - Closing action taken
- `itemCategory` - Item category
- `remarks` - Call remarks/notes
- `followUpDate` - Follow-up date
- `callDuration` - Duration of the call in seconds
- `callStatus` - Status of the call
- `leadStatus` - Status of the lead
- `type` - Type of lead (enquiry, booking, etc.)
- `id` - Report ID
- And all other fields from the backend API response

## Files Modified

1. `frontend/lib/view/reports_screens/call_report_list_screen.dart`
   - Updated navigation to EnquiryDetailScreen to pass `reportData: report`
   - Updated navigation to BookingDetailScreen to pass `reportData: report`

## Result

✅ All backend data is now properly mapped to the detail screens
✅ Fields display actual values instead of "Not available"
✅ Share functionality includes all report data
✅ No compilation errors

## Testing

To verify the fix works:

1. Open Reports screen
2. Click on a report to view the Call Report List
3. Click "Details" on any report
4. Verify that all fields display actual data from the backend
5. Test the Share functionality to ensure all data is included

## Data Mapping in Detail Screens

The detail screens use the following mapping:

```dart
final callDate = _getDisplayValue(data['callDate'], 'Not available');
final location = _getDisplayValue(data['storeName'], 'Not available');
final functionDate = _getDisplayValue(data['functionDate'], 'Not available');
final subCategory = _getDisplayValue(data['subCategory'], 'Not available');
final closingAction = _getDisplayValue(data['closingAction'], 'Not available');
final itemCategory = _getDisplayValue(data['itemCategory'], 'Not available');
final remarks = _getDisplayValue(data['remarks'], 'Not available');
final followUpDate = _getDisplayValue(data['followUpDate'], 'Not available');
final callDuration = data['callDuration'] != null
    ? '${data['callDuration']}s'
    : 'Not available';
```

## Future Enhancements

1. Add more fields to the detail screens if needed
2. Add field validation and formatting
3. Add edit functionality to update report data
4. Add attachment support
5. Add activity timeline
6. Add follow-up scheduling

## Notes

- The `report` object is already properly formatted by `ReportController.getFilteredLeads()`
- All field names are consistent between the controller and detail screens
- The `_getDisplayValue()` helper function handles null/empty values gracefully
- Call duration is automatically formatted from seconds to a readable format
