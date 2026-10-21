# Outgoing Call Detail Screen - Fixed (Version 2) ✅

## Problem

After an outgoing call completed, a new detail screen was being opened automatically. But the user wanted to use the **existing outgoing call detail screen** that's already shown when clicking the "Make Call" button.

## Solution

Instead of opening a new screen after call completion, we now:
1. Keep the user on the existing outgoing call detail screen
2. Only show a popup for incoming calls (which don't have a pre-existing screen)
3. Let the user fill in the form on the existing screen

## Implementation

**File**: `frontend/lib/controller/call_tracking_controller.dart`

### Changes:

1. **Updated call completion logic** to differentiate between incoming and outgoing calls:
   ```dart
   if (_lastCallWasIncoming) {
     // For incoming calls, show incoming call detail screen
     _showAddLeadBottomSheetForIncomingCall(phoneNumber, _lastDuration ?? 0);
   } else {
     // For outgoing calls, user is already on the outgoing call detail screen
     // Don't show a popup - let them use the existing screen
     print('Outgoing call completed - user is already on outgoing call detail screen');
   }
   ```

2. **Removed unnecessary method** `_showAddLeadBottomSheetForOutgoingCall()`

3. **Removed unnecessary import** for outgoing call bottom sheet

## How It Works

### Outgoing Call Flow:
```
User clicks "Make Call" button
    ↓
AddLeadOutgoingCallBottomSheet opens
    ↓
User makes the call
    ↓
Call completes
    ↓
Call duration is captured and displayed on the screen
    ↓
User fills in the form on the SAME screen
    ↓
User clicks "Save" to submit
```

### Incoming Call Flow:
```
Incoming call received
    ↓
Call completes
    ↓
IncomingCallHandler.handleIncomingCall() is called
    ↓
NewLeadPopupSheet opens (new popup)
    ↓
User fills in the form
    ↓
User clicks "Add Enquiry" or "Add Booked"
```

## Key Differences

| Aspect | Outgoing Call | Incoming Call |
|--------|---------------|---------------|
| Screen shown | Existing detail screen | New popup (NewLeadPopupSheet) |
| When shown | When user clicks "Make Call" | After call completes |
| User action | Fills form on existing screen | Fills form on new popup |
| Default lead type | "Booked" | "Enquiry" |

## Benefits

1. **No Duplicate Screens**: Uses the existing outgoing call detail screen
2. **Better UX**: User stays on the same screen they started with
3. **Consistent**: Outgoing calls use the outgoing detail screen, incoming calls use the incoming popup
4. **Simpler**: Less code, fewer screens to manage
5. **Cleaner**: No automatic popups for outgoing calls

## Testing

### Outgoing Call:
1. Click "Make Call" button
2. Outgoing call detail screen opens
3. Make a call (duration > 0)
4. Call completes
5. **Expected**: Stay on the same outgoing call detail screen
6. **NOT expected**: New popup should NOT appear
7. Fill in the form and click "Save"

### Incoming Call:
1. Receive an incoming call
2. Call completes
3. **Expected**: NewLeadPopupSheet popup appears
4. Fill in the form and click "Add Enquiry" or "Add Booked"

## Files Modified

- `frontend/lib/controller/call_tracking_controller.dart`
  - Updated call completion logic to check `_lastCallWasIncoming` flag
  - Removed `_showAddLeadBottomSheetForOutgoingCall()` method
  - Removed import for `add_lead_outgoing_call_bottom_sheet.dart`

## Logging

Debug logs show the flow:
```
CallTrackingController: Call completed with duration=X for phone=..., isIncoming=true/false
CallTrackingController: Showing incoming call form for phone=... (for incoming calls only)
CallTrackingController: Outgoing call completed - user is already on outgoing call detail screen, not showing popup
```

## Summary

The fix ensures that:
- **Outgoing calls** use the existing detail screen (no new popup)
- **Incoming calls** use the new popup (NewLeadPopupSheet)
- Users have a consistent experience for each call type
- No duplicate screens are opened
