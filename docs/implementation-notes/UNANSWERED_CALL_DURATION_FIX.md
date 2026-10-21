# Unanswered Outgoing Call Duration - Fixed ✅

## Problem

When an outgoing call was **not answered** (Call Status: "Not Connected"), the app was still showing a duration like **00:33 Mins** instead of **00:00 Mins**.

This happened because:
1. Android's call log includes ringing time as duration, even if the call wasn't answered
2. The `_lastCallWasAnswered` flag wasn't being set correctly for outgoing calls
3. The duration was being displayed without checking if the call was actually answered

## Root Cause

The issue was in the call tracking logic:

1. **For outgoing calls**: The `onCallStateChanged` event might not fire with 'answered' state, so `_lastCallWasAnswered` remains `false`
2. **Android call log**: Returns duration even for unanswered calls (ringing time)
3. **No validation**: The outgoing call screen was displaying the duration without checking if the call was actually answered

## Solution Applied

### File 1: `frontend/lib/controller/call_tracking_controller.dart`

**Change 1**: Improved logging to show why duration is being set to 0:
```dart
if (_lastCallWasAnswered && duration > 0) {
  _lastDuration = duration;
  print('Call was answered - using duration=$_lastDuration');
} else {
  _lastDuration = 0;
  print('Call was NOT answered (_lastCallWasAnswered=$_lastCallWasAnswered) - duration set to 0, ignoring Android duration=$duration');
}
```

**Change 2**: Better logging for call state changes:
```dart
if (state == 'answered') {
  _lastCallWasAnswered = true;
  print('Call was answered - _lastCallWasAnswered set to true');
} else {
  print('Call state changed to: $state (not answered)');
}
```

### File 2: `frontend/lib/widgets.dart/add_lead_outgoing_call_bottom_sheet.dart`

**Change**: Enhanced `_onCallDurationUpdate()` to handle unanswered calls:
```dart
void _onCallDurationUpdate() {
  // Only capture duration if call was answered
  if (callTrackingController.lastCallWasAnswered &&
      callTrackingController.lastDuration != null &&
      callTrackingController.lastDuration! > 0) {
    setState(() {
      _callDuration = callTrackingController.lastDuration!;
      if (_selectedCallStatus == null) {
        _selectedCallStatus = "Connected";
      }
    });
  } else if (callTrackingController.lastDuration == null ||
      callTrackingController.lastDuration! == 0) {
    // Call was not answered, reset duration to 0
    setState(() {
      _callDuration = 0;
      // Don't auto-set call status for unanswered calls
    });
  }
}
```

## How It Works

### Call Duration Logic:

1. **Call starts**: `_lastCallWasAnswered = false`
2. **Call state changes to 'answered'**: `_lastCallWasAnswered = true`
3. **Call ends**: 
   - If `_lastCallWasAnswered == true` AND `duration > 0`: Use the duration
   - If `_lastCallWasAnswered == false`: Set duration to 0
4. **UI updates**: Display the duration (0 for unanswered, actual duration for answered)

### Expected Behavior:

| Call Type | Call Status | Duration | Reason |
|-----------|------------|----------|--------|
| Answered | Connected | 00:33 Mins | Call was answered, use actual duration |
| Not Answered | Not Connected | 00:00 Mins | Call was not answered, ignore Android duration |
| Rejected | Not Connected | 00:00 Mins | Call was rejected, duration = 0 |
| No Answer | Not Connected | 00:00 Mins | Call was not answered, duration = 0 |

## Logging

Debug logs now show:
```
CallTrackingController: Call was answered - _lastCallWasAnswered set to true
CallTrackingController: Call was answered - using duration=33 seconds from Android call log

OR

CallTrackingController: Call state changed to: disconnected (not answered)
CallTrackingController: Call was NOT answered (_lastCallWasAnswered=false) - duration set to 0, ignoring Android duration=33
```

## Testing

### Test 1: Answered Outgoing Call
1. Click "Make Call"
2. Call is answered
3. Call duration shows (e.g., 00:33 Mins)
4. Call Status shows "Connected"
5. **Expected**: Duration is displayed correctly

### Test 2: Unanswered Outgoing Call
1. Click "Make Call"
2. Call is NOT answered (rejected, no answer, etc.)
3. Call ends
4. **Expected**: Duration shows 00:00 Mins
5. **Expected**: Call Status is NOT auto-set to "Connected"

### Test 3: Incoming Call
1. Receive an incoming call
2. Call is answered
3. Call ends
4. **Expected**: Incoming call popup shows correct duration

## Files Modified

- `frontend/lib/controller/call_tracking_controller.dart`
  - Improved logging for duration handling
  - Better logging for call state changes

- `frontend/lib/widgets.dart/add_lead_outgoing_call_bottom_sheet.dart`
  - Enhanced `_onCallDurationUpdate()` to reset duration for unanswered calls
  - Added check to not auto-set call status for unanswered calls

## Why This Happens

Android's call log includes:
- **Answered calls**: Duration from answer to disconnect
- **Unanswered calls**: Duration from dial to disconnect (ringing time)

So a call that rings for 33 seconds but isn't answered will show 33 seconds in the Android call log. Our fix ensures we only use this duration if the call was actually answered.

## Future Improvements

1. Could add a check for minimum duration (e.g., < 3 seconds = not answered)
2. Could use Android's call state API to get more accurate answered status
3. Could add a manual "Mark as Answered" button for edge cases
