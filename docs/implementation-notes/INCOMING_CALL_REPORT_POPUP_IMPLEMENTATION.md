# Incoming Call Report Popup Implementation

## Overview
Implemented support for `reportPopup` type in the incoming call handler. When a call comes in from a phone number that exists in the completed leads (reports), the system now shows a report popup instead of defaulting to a new lead popup.

## Changes Made

### 1. Created New Report Popup Sheet
**File**: `frontend/lib/widgets.dart/incoming_call_report_popup_sheet.dart`

- New widget: `IncomingCallReportPopupSheet`
- Displays completed lead information in a bottom sheet
- Shows: Name, Phone, Call Date, Location, Source, Sub Category, Status
- Allows user to add remarks/notes
- Simpler than other popups since report leads are already completed
- No complex fields like closing action or follow-up date

### 2. Updated Incoming Call Handler
**File**: `frontend/lib/services/incoming_call_handler.dart`

#### Added Import
```dart
import 'package:telecaller_app/widgets.dart/incoming_call_report_popup_sheet.dart';
```

#### Updated Class Documentation
Added `reportPopup` to the list of supported popup types:
```
- reportPopup → IncomingCallReportPopupSheet (completed leads from reports)
```

#### Added Switch Case
Added new case in `handleIncomingCall()` method:
```dart
case 'reportPopup':
  print('IncomingCallHandler: → Showing report popup');
  if (!_tryUpdateExistingLeadScreen(context, leadId, callDuration)) {
    await _showReportPopup(context, leadId, callDuration);
  }
  break;
```

#### Added Methods
1. **`_showReportPopup()`** - Fetches report lead data from `/api/leads/{id}` and displays the popup
2. **`_saveReport()`** - Saves remarks and call duration to the report lead via POST to `/api/leads/{id}`

### 3. Extended API Service
**File**: `frontend/lib/services/api_service.dart`

Added new method: `postLeadUpdate()`
- Generic method for updating any lead via POST to `/api/leads/{id}`
- Follows the same pattern as other update methods (followup, complaint, return, booking confirmation)
- Handles authentication, error handling, and logging

## Flow

### When Incoming Call Arrives
1. Phone number is normalized and sent to `/api/customers/check-phone`
2. Backend returns `popupType: "reportPopup"` if phone exists in completed leads
3. `IncomingCallHandler.handleIncomingCall()` routes to `_showReportPopup()`
4. Lead data is fetched from `/api/leads/{id}`
5. `IncomingCallReportPopupSheet` is displayed with lead details
6. User can add remarks and save
7. Data is saved via `postLeadUpdate()` to `/api/leads/{id}`

## API Endpoints Used

- **Fetch Report Lead**: `GET /api/leads/{id}`
- **Update Report Lead**: `POST /api/leads/{id}`
  - Body: `{ remarks: string, callDuration?: string }`

## UI Components

### IncomingCallReportPopupSheet
- Header section with lead name, phone, and lead type badge
- Call details section showing call date
- Lead information section showing location, source, sub category, status
- Editable remarks field
- Cancel and Save buttons

## Error Handling

- If lead fetch fails: Shows error snackbar and closes popup
- If save fails: Shows error snackbar but keeps popup open for retry
- All errors are logged and sent to Firebase Crashlytics

## Testing Scenarios

1. **New Lead**: Phone not in system → Shows new lead popup ✓
2. **Followup Lead**: Phone in followups → Shows followup popup ✓
3. **Complaint Lead**: Phone in complaints → Shows complaint popup ✓
4. **Return Lead**: Phone in returns → Shows return popup ✓
5. **Booking Confirmation**: Phone in booking confirmations → Shows booking popup ✓
6. **Report Lead**: Phone in completed leads → Shows report popup ✓ (NEW)

## Files Modified

1. `frontend/lib/services/incoming_call_handler.dart` - Added reportPopup case and methods
2. `frontend/lib/services/api_service.dart` - Added postLeadUpdate() method
3. `frontend/lib/widgets.dart/incoming_call_report_popup_sheet.dart` - New file

## Notes

- Report leads are read-only in terms of lead type/status (they're already completed)
- Users can only add remarks and the system records the call duration
- The implementation follows the same pattern as other popup types for consistency
- All print statements use the same logging format as other methods
