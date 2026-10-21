# Call Duration Not Updating in UI - Fixed

## The Problem

**Logs show:**
```
CallTrackingController: Call was answered - using duration=10 seconds from Android call log
CallTrackingController: Updating lead 7025743212 with duration=10, callCount=3
```

**But UI shows:** `00:00 Mins` ❌

The duration was captured correctly but **not displayed in the UI**.

---

## Root Cause

The issue was in the **order of operations** in `CallTrackingController.onCallEnded()`:

### Old Code (Wrong Order):
```dart
if (call.method == 'onCallEnded') {
  // 1. Set duration
  _lastDuration = duration;  // ✅ Duration set to 10
  
  // 2. Reset answered flag IMMEDIATELY
  _lastCallWasAnswered = false;  // ❌ Flag reset too early
  
  // 3. Update lead
  _updateLeadWithDuration(phoneNumber, _lastDuration ?? 0);
  
  // 4. Notify listeners
  notifyListeners();
}
```

### What Happened:
1. Duration set: `_lastDuration = 10`
2. Answered flag reset: `_lastCallWasAnswered = false`
3. Listeners notified
4. UI listener callback runs: `_onCallDurationUpdate()`
5. Callback checks: `if (callTrackingController.lastCallWasAnswered && ...)`
6. **Condition fails** because `_lastCallWasAnswered` is already false ❌
7. UI duration NOT updated

---

## The Fix

**Notify listeners BEFORE resetting the answered flag:**

```dart
if (call.method == 'onCallEnded') {
  // 1. Set duration
  _lastDuration = duration;  // ✅ Duration set to 10
  
  // 2. Update lead
  _updateLeadWithDuration(phoneNumber, _lastDuration ?? 0);
  
  // 3. Notify listeners FIRST (while _lastCallWasAnswered is still true)
  notifyListeners();  // ✅ Listeners called while flag is true
  
  // 4. Reset answered flag AFTER notifying
  _lastCallWasAnswered = false;  // ✅ Reset after listeners processed
}
```

### Why This Works:
1. Duration set: `_lastDuration = 10`
2. **Listeners notified** (while `_lastCallWasAnswered = true`)
3. UI listener callback runs: `_onCallDurationUpdate()`
4. Callback checks: `if (callTrackingController.lastCallWasAnswered && ...)`
5. **Condition passes** because flag is still true ✅
6. UI updates: `setState(() { _callDuration = 10; })`
7. **Then** answered flag is reset

---

## Code Changes

### Before:
```dart
if (call.method == 'onCallEnded') {
  _lastPhone = phoneNumber;
  
  if (_lastCallWasAnswered && duration > 0) {
    _lastDuration = duration;
  } else {
    _lastDuration = 0;
  }
  
  _lastCallWasIncoming = (callType == 'incoming');
  _outgoingCallInProgress = false;
  
  // ❌ WRONG: Reset flag before notifying
  _lastCallWasAnswered = false;
  
  _updateLeadWithDuration(phoneNumber, _lastDuration ?? 0);
  
  // Notify listeners (but flag already reset)
  notifyListeners();
}
```

### After:
```dart
if (call.method == 'onCallEnded') {
  _lastPhone = phoneNumber;
  
  if (_lastCallWasAnswered && duration > 0) {
    _lastDuration = duration;
  } else {
    _lastDuration = 0;
  }
  
  _lastCallWasIncoming = (callType == 'incoming');
  _outgoingCallInProgress = false;
  
  _updateLeadWithDuration(phoneNumber, _lastDuration ?? 0);
  
  // ✅ CORRECT: Notify listeners FIRST (while flag is true)
  notifyListeners();
  
  // ✅ CORRECT: Reset flag AFTER notifying
  _lastCallWasAnswered = false;
  
  // Show incoming call form if needed
  if (_lastCallWasIncoming && (_lastDuration ?? 0) > 0 && ...) {
    _showAddLeadBottomSheetForIncomingCall(phoneNumber, _lastDuration ?? 0);
  }
}
```

---

## How the UI Listener Works

### In `add_lead_outgoing_call_bottom_sheet.dart`:

```dart
void _onCallDurationUpdate() {
  final callTrackingController = Provider.of<CallTrackingController>(
    context,
    listen: false,
  );

  // This check now passes because flag is still true
  if (callTrackingController.lastCallWasAnswered &&
      callTrackingController.lastDuration != null &&
      callTrackingController.lastDuration! > 0) {
    if (mounted) {
      setState(() {
        _callDuration = callTrackingController.lastDuration!;  // ✅ Updates to 10
        if (_selectedCallStatus == null) {
          _selectedCallStatus = "Connected";
        }
      });
    }
  }
}
```

### UI Display:
```dart
Text(
  _callDuration > 0
      ? _formatDuration(_callDuration)  // ✅ Shows "00:10 Mins"
      : '00:00 Mins',
)
```

---

## Timeline of Events

### Before Fix (Duration Not Shown):
```
16:59:52 - Call ends
          ↓
          onCallEnded received
          ↓
          _lastDuration = 10
          _lastCallWasAnswered = false  ❌ Reset too early
          ↓
          notifyListeners()
          ↓
          _onCallDurationUpdate() called
          ↓
          Check: lastCallWasAnswered? NO ❌
          ↓
          UI NOT updated → Shows "00:00 Mins"
```

### After Fix (Duration Shown):
```
16:59:52 - Call ends
          ↓
          onCallEnded received
          ↓
          _lastDuration = 10
          ↓
          notifyListeners()  ✅ Notify FIRST
          ↓
          _onCallDurationUpdate() called
          ↓
          Check: lastCallWasAnswered? YES ✅
          ↓
          setState(() { _callDuration = 10; })
          ↓
          UI updated → Shows "00:10 Mins" ✅
          ↓
          _lastCallWasAnswered = false  ✅ Reset AFTER
```

---

## Expected Results

### Before Fix:
- Call duration: 10s (Android) ✅
- Lead updated: 10s ✅
- UI shows: "00:00 Mins" ❌

### After Fix:
- Call duration: 10s (Android) ✅
- Lead updated: 10s ✅
- UI shows: "00:10 Mins" ✅

---

## Key Takeaway

**Order matters in state management:**
1. Update state
2. Notify listeners (while state is valid)
3. Reset/cleanup state

Not:
1. Update state
2. Reset state
3. Notify listeners (state already invalid)

---

## Testing

After this fix:
- ✅ Make a call
- ✅ Call gets answered
- ✅ Duration should update in real-time in the UI
- ✅ Shows correct duration (e.g., "00:10 Mins")
- ✅ Lead saved with correct duration
