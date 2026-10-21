# Call Duration Calculation - Analysis & Current Implementation

## Overview
Your app tracks call duration, but there's a **critical issue**: duration is being captured **regardless of whether the call was answered or not**. The requirement is to **only calculate duration when the call is answered**.

---

## Current Flow - How Duration is Captured

### 1. **CallTrackingController** (`call_tracking_controller.dart`)
This is the main controller that manages all call tracking logic.

#### Key Properties:
```dart
bool _lastCallWasAnswered = false;  // Tracks if call was answered
int? _lastDuration;                 // Stores call duration in seconds
```

#### When Duration is Captured:

**For Outgoing Calls:**
```dart
PhoneCallService.initialize((phone, duration) {
  _lastPhone = phone;
  _lastDuration = duration;  // ❌ CAPTURED REGARDLESS OF ANSWER STATE
  _lastCallWasIncoming = false;
  _updateLeadWithDuration(phone, duration);
  notifyListeners();
});
```

**For Incoming Calls:**
```dart
if (call.method == 'onCallEnded') {
  final duration = call.arguments['duration'] as int? ?? 0;
  _lastDuration = duration;  // ❌ CAPTURED REGARDLESS OF ANSWER STATE
  
  // Only checks if duration > 0, NOT if call was answered
  if (duration > 0) {
    _lastCallWasAnswered = true;
  } else {
    _lastCallWasAnswered = false;
  }
}
```

#### When Call State is Tracked:
```dart
if (call.method == 'onCallStateChanged') {
  final state = call.arguments['state'] as String? ?? '';
  
  if (state == 'answered') {
    _lastCallWasAnswered = true;  // ✅ Correctly marked as answered
  }
}
```

---

## The Problem

### Issue 1: Duration Captured Before Checking Answer State
The duration is stored **immediately** when the call ends, but the `_lastCallWasAnswered` flag is only set **after** checking if duration > 0.

```dart
// Current Logic (WRONG):
_lastDuration = duration;  // Store immediately
if (duration > 0) {
  _lastCallWasAnswered = true;  // Set flag AFTER storing
}
```

### Issue 2: No Validation Against Answer State
When updating leads with duration, there's **no check** to ensure the call was actually answered:

```dart
void _updateLeadWithDuration(String phone, int duration) {
  if (lead != null && duration > 0) {  // ❌ Only checks duration > 0
    // Updates lead with duration
    // Does NOT verify _lastCallWasAnswered
  }
}
```

### Issue 3: Incoming Call Form Shows Even for Missed Calls
```dart
if (_lastCallWasIncoming && duration > 0 && phoneNumber != 'Unknown') {
  _showAddLeadBottomSheetForIncomingCall(phoneNumber, duration);
  // ❌ Shows form for ANY incoming call with duration > 0
  // Should also check: _lastCallWasAnswered
}
```

---

## How Call States Work

### CallState Enum (from `call_model.dart`):
```dart
enum CallState { 
  ringing,   // Call is ringing (not answered yet)
  answered,  // Call was answered
  ended      // Call ended
}
```

### Call Duration Display (`call_duration_display.dart`):
```dart
String _valueText(CallData data) {
  if (data.state == CallState.ended) {
    return FormatHelper.formatCallDurationWithUnits(data.duration);  // Shows duration
  }
  if (data.state == CallState.answered) {
    return 'Connected';  // Shows "Connected" while on call
  }
  return 'Ringing...';  // Shows "Ringing..." before answer
}
```

**This widget correctly shows duration ONLY after call ends**, but it doesn't validate if the call was actually answered.

---

## Duration Formatting Functions

### 1. `formatCallDuration()` - MM:SS or HH:MM:SS
```dart
static String formatCallDuration(int? seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remainingSeconds = seconds % 60;
  
  if (hours > 0) {
    return "HH:MM:SS";  // e.g., "01:23:45"
  } else {
    return "MM:SS";     // e.g., "23:45"
  }
}
```

### 2. `formatCallDurationWithUnits()` - Human-readable
```dart
static String formatCallDurationWithUnits(int? seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  
  if (minutes > 0) {
    return "${minutes}m ${remainingSeconds}s";  // e.g., "2m 30s"
  } else {
    return "${remainingSeconds}s";              // e.g., "45s"
  }
}
```

### 3. `_formatDuration()` in OutgoingCallBottomSheet - MM:SS Mins
```dart
String _formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final secs = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')} Mins';
}
```

---

## Outgoing Call Duration Tracking

### In `add_lead_outgoing_call_bottom_sheet.dart`:

```dart
void _onCallDurationUpdate() {
  final callTrackingController = Provider.of<CallTrackingController>(context, listen: false);
  
  // ❌ PROBLEM: No check for _lastCallWasAnswered
  if (callTrackingController.lastDuration != null &&
      callTrackingController.lastDuration! > 0) {
    setState(() {
      _callDuration = callTrackingController.lastDuration!;
      if (_selectedCallStatus == null) {
        _selectedCallStatus = "Connected";
      }
    });
  }
}
```

**Should be:**
```dart
void _onCallDurationUpdate() {
  final callTrackingController = Provider.of<CallTrackingController>(context, listen: false);
  
  // ✅ FIXED: Check both duration AND answered state
  if (callTrackingController.lastCallWasAnswered &&
      callTrackingController.lastDuration != null &&
      callTrackingController.lastDuration! > 0) {
    setState(() {
      _callDuration = callTrackingController.lastDuration!;
      if (_selectedCallStatus == null) {
        _selectedCallStatus = "Connected";
      }
    });
  }
}
```

---

## Recommended Fixes

### Fix 1: Update CallTrackingController
```dart
// In onCallEnded handler:
if (call.method == 'onCallEnded') {
  final duration = call.arguments['duration'] as int? ?? 0;
  
  // ✅ Only set duration if call was answered
  if (_lastCallWasAnswered && duration > 0) {
    _lastDuration = duration;
  } else {
    _lastDuration = 0;  // Reset if not answered
  }
}
```

### Fix 2: Update Lead Update Logic
```dart
void _updateLeadWithDuration(String phone, int duration) {
  final lead = _findLeadByPhone(phone);
  
  // ✅ Check BOTH answered state AND duration
  if (lead != null && _lastCallWasAnswered && duration > 0) {
    final newCallCount = lead.callCount + 1;
    final updatedLead = LeadModel(
      // ... update with duration
      callDuration: duration,
      callCount: newCallCount,
    );
    _leadRepository.updateLead(updatedLead);
  }
}
```

### Fix 3: Update Incoming Call Form Display
```dart
if (_lastCallWasIncoming && 
    _lastCallWasAnswered &&  // ✅ Add this check
    duration > 0 && 
    phoneNumber != 'Unknown' && 
    phoneNumber.isNotEmpty) {
  _showAddLeadBottomSheetForIncomingCall(phoneNumber, duration);
}
```

### Fix 4: Update Outgoing Call Duration Listener
```dart
void _onCallDurationUpdate() {
  final callTrackingController = Provider.of<CallTrackingController>(context, listen: false);
  
  // ✅ Check answered state
  if (callTrackingController.lastCallWasAnswered &&
      callTrackingController.lastDuration != null &&
      callTrackingController.lastDuration! > 0) {
    setState(() {
      _callDuration = callTrackingController.lastDuration!;
      if (_selectedCallStatus == null) {
        _selectedCallStatus = "Connected";
      }
    });
  }
}
```

---

## Summary

| Aspect | Current | Should Be |
|--------|---------|-----------|
| Duration Capture | Captured for all calls | Only for answered calls |
| Answer State Check | Only checks duration > 0 | Checks `_lastCallWasAnswered` flag |
| Lead Update | Updates for duration > 0 | Updates only if answered |
| Incoming Form | Shows for duration > 0 | Shows only if answered |
| Outgoing Duration | Captured regardless | Captured only if answered |

The key is to **always validate `_lastCallWasAnswered` before using the duration value**.
