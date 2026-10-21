# Call Duration Fix - Only Count Answered Time

## Changes Applied

### 1. **CallTrackingController** - Added Timestamp Tracking
Added two new properties to track when call was answered and ended:
```dart
DateTime? _callAnsweredAt;  // Track when call was answered
DateTime? _callEndedAt;     // Track when call ended
```

### 2. **Outgoing Call Handler** - Calculate Duration from Answered Time
```dart
PhoneCallService.initialize((phone, duration) {
  // CRITICAL: Only use duration if call was answered
  if (_lastCallWasAnswered && _callAnsweredAt != null) {
    _callEndedAt = DateTime.now();
    final answeredDuration = _callEndedAt!.difference(_callAnsweredAt!).inSeconds;
    _lastDuration = answeredDuration > 0 ? answeredDuration : 0;
  } else {
    _lastDuration = 0;  // Not answered = 0 duration
  }
});
```

### 3. **Incoming Call Handler** - Calculate Duration from Answered Time
```dart
if (call.method == 'onCallEnded') {
  _callEndedAt = DateTime.now();
  
  // CRITICAL: Only calculate duration if call was answered
  if (_lastCallWasAnswered && _callAnsweredAt != null) {
    final answeredDuration = _callEndedAt!.difference(_callAnsweredAt!).inSeconds;
    _lastDuration = answeredDuration > 0 ? answeredDuration : 0;
  } else {
    _lastDuration = 0;  // Not answered = 0 duration
  }
}
```

### 4. **Call State Changed Handler** - Capture Answer Timestamp
```dart
if (call.method == 'onCallStateChanged') {
  if (state == 'answered') {
    _lastCallWasAnswered = true;
    _callAnsweredAt = DateTime.now();  // ✅ Capture exact answer time
  }
}
```

### 5. **Start Outgoing Call** - Reset Timestamps
```dart
void startOutgoingCall(String phone) {
  _lastCallWasAnswered = false;
  _callAnsweredAt = null;      // ✅ Reset for new call
  _callEndedAt = null;         // ✅ Reset for new call
  _outgoingCallInProgress = true;
}
```

### 6. **Update Lead Duration** - Only Update if Duration > 0
```dart
void _updateLeadWithDuration(String phone, int duration) {
  // CRITICAL: Only update if duration > 0 (call was answered)
  if (lead != null && duration > 0) {
    // Update lead with duration
  } else if (duration == 0) {
    print('NOT updating lead - call was not answered');
  }
}
```

### 7. **Outgoing Call Bottom Sheet** - Check Answered State
```dart
void _onCallDurationUpdate() {
  // CRITICAL: Only capture duration if call was answered
  if (callTrackingController.lastCallWasAnswered &&
      callTrackingController.lastDuration != null &&
      callTrackingController.lastDuration! > 0) {
    setState(() {
      _callDuration = callTrackingController.lastDuration!;
    });
  }
}
```

---

## How It Works Now

### Call Flow:
1. **Call Initiated** → `startOutgoingCall()` resets timestamps
2. **Call Ringing** → `onCallStateChanged('ringing')` 
3. **Call Answered** → `onCallStateChanged('answered')` captures `_callAnsweredAt = DateTime.now()`
4. **Call Ended** → `onCallEnded()` calculates:
   ```
   duration = _callEndedAt - _callAnsweredAt (in seconds)
   ```
5. **Lead Updated** → Only if duration > 0

### Examples:

**Scenario 1: Call Answered for 2 minutes 30 seconds**
- Call answered at: 10:00:00
- Call ended at: 10:02:30
- Duration calculated: 150 seconds (2m 30s) ✅

**Scenario 2: Call Not Answered (Missed Call)**
- `_lastCallWasAnswered` = false
- Duration set to: 0 seconds ✅
- Lead NOT updated ✅
- Incoming form NOT shown ✅

**Scenario 3: Call Answered for 5 seconds**
- Call answered at: 10:00:00
- Call ended at: 10:00:05
- Duration calculated: 5 seconds ✅

---

## Benefits

✅ **Accurate Duration** - Only counts time from answer to end  
✅ **No Missed Calls** - Missed calls have 0 duration  
✅ **Lead Data Integrity** - Only answered calls update lead records  
✅ **Correct Forms** - Incoming call forms only show for answered calls  
✅ **Timestamp Precision** - Uses actual system timestamps, not Android duration  

---

## Testing Checklist

- [ ] Make an outgoing call and hang up before answering → Duration should be 0
- [ ] Make an outgoing call, answer, talk for 30 seconds, hang up → Duration should be ~30s
- [ ] Receive an incoming call and hang up before answering → Duration should be 0
- [ ] Receive an incoming call, answer, talk for 1 minute, hang up → Duration should be ~60s
- [ ] Check lead records → Only answered calls should have duration > 0
- [ ] Check incoming call forms → Should only appear for answered calls
