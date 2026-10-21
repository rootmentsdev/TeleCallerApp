# Outgoing Call Detail Screen - Fixed ✅

## Problem

When an outgoing call completed, the app was showing the **incoming call detail screen** instead of the **outgoing call detail screen**. This happened because the code was not differentiating between incoming and outgoing calls.

## Root Cause

In `call_tracking_controller.dart`, the method `_showAddLeadBottomSheetForIncomingCall()` was being called for BOTH incoming AND outgoing calls:

```dart
// Show add lead bottom sheet for both incoming AND outgoing calls with duration > 0
if ((_lastDuration ?? 0) > 0 && phoneNumber != 'Unknown' && phoneNumber.isNotEmpty) {
  _showAddLeadBottomSheetForIncomingCall(phoneNumber, _lastDuration ?? 0);
}
```

This method always showed the incoming call handler, which displays the `NewLeadPopupSheet` (incoming call detail screen).

## Solution Applied

**File**: `frontend/lib/controller/call_tracking_controller.dart`

### Changes:

1. **Added import** for outgoing call bottom sheet:
   ```dart
   import 'package:telecaller_app/widgets.dart/add_lead_outgoing_call_bottom_sheet.dart';
   ```

2. **Updated call completion logic** to check call type:
   ```dart
   if (_lastCallWasIncoming) {
     // For incoming calls, show incoming call detail screen
     _showAddLeadBottomSheetForIncomingCall(phoneNumber, _lastDuration ?? 0);
   } else {
     // For outgoing calls, show outgoing call detail screen
     _showAddLeadBottomSheetForOutgoingCall(phoneNumber, _lastDuration ?? 0);
   }
   ```

3. **Created new method** `_showAddLeadBottomSheetForOutgoingCall()`:
   - Shows the outgoing call detail screen
   - Uses `showAddLeadOutgoingCallBottomSheet()` function
   - Includes proper logging and context handling
   - Follows the same pattern as the incoming call method

## How It Works

### Call Type Detection

The `_lastCallWasIncoming` flag is set based on the `callType` from the Android call tracking:

```dart
if (callType == 'incoming') {
  _lastCallWasIncoming = true;
} else {
  _lastCallWasIncoming = false;  // outgoing call
}
```

### Screen Selection

After call completion:
1. Check if `_lastCallWasIncoming` is true or false
2. If true → Show incoming call detail screen (NewLeadPopupSheet)
3. If false → Show outgoing call detail screen (AddLeadOutgoingCallBottomSheet)

## Data Flow

### Incoming Call:
```
Call Ends
    ↓
_lastCallWasIncoming = true
    ↓
_showAddLeadBottomSheetForIncomingCall()
    ↓
IncomingCallHandler.handleIncomingCall()
    ↓
NewLeadPopupSheet (Incoming Call Detail Screen)
```

### Outgoing Call:
```
Call Ends
    ↓
_lastCallWasIncoming = false
    ↓
_showAddLeadBottomSheetForOutgoingCall()
    ↓
showAddLeadOutgoingCallBottomSheet()
    ↓
AddLeadOutgoingCallBottomSheet (Outgoing Call Detail Screen)
```

## Screens Shown

### Incoming Call Detail Screen:
- Shows "Incoming Call" header
- Lead type defaults to "Enquiry"
- Shows all fields: Call Status, Store, Location, Function Date, etc.
- Used for new incoming calls

### Outgoing Call Detail Screen:
- Shows "Outgoing Call" header
- Lead type defaults to "Booked"
- Shows relevant fields for outgoing calls
- Used for new outgoing calls

## Testing

1. **Make an outgoing call**:
   - Dial a number
   - Let it connect (duration > 0)
   - End the call

2. **Verify correct screen appears**:
   - Should show "Outgoing Call" header
   - Should show "Add New Lead" form with "Booked" as default lead type
   - Should NOT show incoming call detail screen

3. **Make an incoming call**:
   - Receive a call
   - Let it connect (duration > 0)
   - End the call

4. **Verify correct screen appears**:
   - Should show "Incoming Call" header
   - Should show "Add New Lead" form with "Enquiry" as default lead type

## Files Modified

- `frontend/lib/controller/call_tracking_controller.dart`
  - Added import for `add_lead_outgoing_call_bottom_sheet.dart`
  - Updated call completion logic to check `_lastCallWasIncoming` flag
  - Added new method `_showAddLeadBottomSheetForOutgoingCall()`

## Logging

Debug logs added to track the flow:

```
CallTrackingController: Showing form for phone=..., duration=..., isIncoming=true/false
CallTrackingController: _showAddLeadBottomSheetForOutgoingCall()
CallTrackingController: Showing outgoing call bottom sheet for phone=..., duration=...
```

## Benefits

1. **Correct Screen**: Users see the appropriate detail screen for their call type
2. **Better UX**: Outgoing calls show "Booked" as default, incoming calls show "Enquiry"
3. **Consistent**: Follows the same pattern for both call types
4. **Maintainable**: Clear separation of logic for incoming vs outgoing calls

## Future Improvements

1. Could add more customization based on call type
2. Could track call direction in the lead model
3. Could add analytics to track incoming vs outgoing call patterns
