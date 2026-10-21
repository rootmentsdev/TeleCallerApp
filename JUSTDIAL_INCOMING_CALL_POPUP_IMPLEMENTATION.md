# JustDial Incoming Call Popup & Detail Screen Implementation

## Overview
- **When on Lead Screen (JustDial tab)**: Incoming call shows the JustDial incoming popup
- **When on Report Screen (viewing JustDial report details)**: Incoming call navigates to the JustDial detail screen

## Changes Made

### 1. New File: `justdial_detail_screen.dart`
**Location:** `frontend/lib/view/reports_screens/report_details_screen/justdial_detail_screen.dart`

Created a dedicated detail screen for JustDial reports with:
- JustDial-specific styling (orange color scheme: `#FFF3E0` background, `#E65100` button)
- Display of lead information (name, phone, location, etc.)
- Call details section showing call date, duration, sub-category, and closing action
- Remarks/notes display
- Share call report button with JustDial theme
- Back navigation to reports list

### 2. New File: `incoming_call_justdial_popup_sheet.dart`
**Location:** `frontend/lib/widgets.dart/incoming_call_justdial_popup_sheet.dart`

Created a dedicated popup sheet for JustDial incoming calls with:
- JustDial-specific styling (orange color scheme)
- Display of lead information (name, phone, location, source, etc.)
- Call details section showing call date and time
- Editable remarks field for additional notes
- Save and Cancel buttons

### 3. Updated: `incoming_call_handler.dart`
**Location:** `frontend/lib/services/incoming_call_handler.dart`

#### Changes:
1. **Added imports** for the new JustDial detail screen and popup sheet:
   ```dart
   import 'package:telecaller_app/view/reports_screens/report_details_screen/justdial_detail_screen.dart';
   import 'package:telecaller_app/widgets.dart/incoming_call_justdial_popup_sheet.dart';
   import 'package:telecaller_app/widgets.dart/incoming_call_report_popup_sheet.dart';
   ```

2. **Enhanced `_showReportPopup()` method**:
   - Now accepts optional `leadDataFromResponse` parameter
   - Detects if the report is a JustDial lead
   - **Routes to `JustDialDetailScreen` for JustDial leads** (navigates instead of showing popup)
   - Routes to generic `IncomingCallReportPopupSheet` for other report types
   - Handles cases where leadId is empty but lead data is provided in the response

3. **Updated `_showJustDialPopup()` method**:
   - Now accepts optional `leadDataFromResponse` parameter
   - Dedicated handler for JustDial popup display
   - Fetches lead details from `/api/leads/{id}` only if leadId is provided
   - Uses lead data from response if available (avoids 404 errors)
   - Shows the JustDial popup with save callback

4. **Updated switch statement cases**:
   - `'reportPopup'` case now passes `data` to `_showReportPopup()`
   - `'justdialPopup'` case now passes `data` to `_showJustDialPopup()`

### 4. Updated: `call_report_list_screen.dart`
**Location:** `frontend/lib/view/reports_screens/call_report_list_screen.dart`

#### Changes:
1. **Added import** for JustDialDetailScreen
2. **Updated navigation logic**:
   - Changed JustDial case to use `JustDialDetailScreen` instead of `EnquiryDetailScreen`
   - Now navigates to dedicated JustDial detail screen when clicking on JustDial reports

## How It Works

### Scenario 1: Lead Screen (JustDial Tab)
1. User is on Lead Screen viewing JustDial leads
2. Incoming call arrives
3. Incoming call handler shows `IncomingCallJustDialPopupSheet` (popup)
4. User can add remarks and save

### Scenario 2: Report Screen (JustDial Report Details)
1. User is on Report Screen viewing JustDial report details
2. Incoming call arrives
3. Incoming call handler **navigates to `JustDialDetailScreen`** (full screen)
4. User can view complete report details and share

## Flow Diagram

```
Incoming Call
    ↓
Check Phone API
    ↓
popupType = 'reportPopup' or 'justdialPopup'
    ↓
Is JustDial Lead?
    ├─ YES → Navigate to JustDialDetailScreen (full screen)
    └─ NO → Show IncomingCallReportPopupSheet (popup)
```

## API Integration

The implementation expects the backend to return one of:
1. `popupType: 'justdialPopup'` with lead data in the response, OR
2. `popupType: 'reportPopup'` with `leadType: 'justdial'` and lead data in the response, OR
3. `popupType: 'reportPopup'` with `leadId` to fetch lead details separately

### Response Structure:
```json
{
  "success": true,
  "data": {
    "popupType": "justdialPopup",
    "leadId": "optional-lead-id",
    "name": "Customer Name",
    "phone": "9876543210",
    "leadType": "justdial",
    "location": "Store Location",
    "source": "JustDial",
    "subCategory": "Category",
    "closingAction": "Status",
    ...
  }
}
```

## Error Handling

The implementation now handles:
- **Empty leadId with lead data in response**: Uses the provided lead data (no API call)
- **Empty leadId without lead data**: Shows error message
- **Valid leadId**: Fetches lead details from `/api/leads/{id}`
- **API errors**: Catches and displays error messages

## Testing

### Test Case 1: JustDial Lead on Lead Screen
1. Open Lead Screen → JustDial Tab
2. Simulate incoming call to a JustDial lead
3. Verify: JustDial popup appears with remarks field
4. Add remarks and save

### Test Case 2: JustDial Report on Report Screen
1. Open Report Screen → Call Reports
2. Click on a JustDial report to view details
3. Simulate incoming call to the same customer
4. Verify: JustDialDetailScreen opens (full screen, not popup)
5. Verify: Can see complete report details and share button

## Files Modified
- `frontend/lib/services/incoming_call_handler.dart` - Enhanced to navigate to detail screen for JustDial reports
- `frontend/lib/view/reports_screens/call_report_list_screen.dart` - Updated to use JustDialDetailScreen
- `frontend/lib/widgets.dart/incoming_call_justdial_popup_sheet.dart` - New file (created)
- `frontend/lib/view/reports_screens/report_details_screen/justdial_detail_screen.dart` - New file (created)

## Backward Compatibility
- Existing report popup functionality remains unchanged
- Generic reports continue to use `IncomingCallReportPopupSheet`
- Only JustDial leads are routed to the new detail screen
- Supports both old API responses (with leadId) and new responses (with lead data)
