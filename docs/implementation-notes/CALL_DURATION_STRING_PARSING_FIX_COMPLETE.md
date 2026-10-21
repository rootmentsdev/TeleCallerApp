# Call Duration String Parsing - Complete Fix Applied

## Problem Summary
The API returns `callDuration` as a **String** (e.g., `"29"`), but the code was trying to cast it directly as an **int**, causing type casting errors and preventing reports from loading.

### Error:
```
type 'String' is not a subtype of type 'int?' in type cast
```

---

## Root Cause
Multiple files were using unsafe type casting:
```dart
// ❌ WRONG - Direct cast fails when API returns String
callDuration: json['callDuration'] as int?
```

When API returns: `"callDuration": "29"` (String), the cast fails.

---

## Solution Applied

Created a safe parsing function that handles **String, int, or null**:

```dart
// ✅ CORRECT - Handles all types
final callDuration = () {
  final callDur = json['callDuration'] ?? json['call_duration'];
  if (callDur == null) return null;
  if (callDur is int) return callDur;
  if (callDur is String) {
    try {
      return int.parse(callDur);  // "29" → 29
    } catch (_) {
      return null;
    }
  }
  return null;
}();
```

---

## Files Fixed

### 1. **report_model.dart** (Line 156-165)
```dart
// Before:
callDuration: json['call_duration'] as int? ?? json['callDuration'] as int?

// After:
callDuration: () {
  final callDur = json['call_duration'] ?? json['callDuration'];
  if (callDur == null) return null;
  if (callDur is int) return callDur;
  if (callDur is String) {
    try {
      return int.parse(callDur);
    } catch (_) {
      return null;
    }
  }
  return null;
}()
```

### 2. **complaint_model.dart** (Line 44-56)
```dart
// Before:
final callDuration = json['callDuration'] as int? ?? json['call_duration'] as int?;

// After:
final callDuration = () {
  final callDur = json['callDuration'] ?? json['call_duration'];
  if (callDur == null) return null;
  if (callDur is int) return callDur;
  if (callDur is String) {
    try {
      return int.parse(callDur);
    } catch (_) {
      return null;
    }
  }
  return null;
}();
```

### 3. **report_controller.dart** (Line 272-283)
```dart
// Before:
final callDuration = leadData['callDuration'] as int? ?? 
                     leadData['call_duration'] as int? ?? 
                     report.callDuration;

// After:
final callDuration = () {
  final callDur = leadData['callDuration'] ?? leadData['call_duration'] ?? report.callDuration;
  if (callDur == null) return null;
  if (callDur is int) return callDur;
  if (callDur is String) {
    try {
      return int.parse(callDur);
    } catch (_) {
      return null;
    }
  }
  return null;
}();
```

### 4. **lead_repository.dart** (Line 747-758)
```dart
// Before:
final callDuration = leadData['callDuration'] as int? ?? leadData['call_duration'] as int?;

// After:
final callDuration = () {
  final callDur = leadData['callDuration'] ?? leadData['call_duration'];
  if (callDur == null) return null;
  if (callDur is int) return callDur;
  if (callDur is String) {
    try {
      return int.parse(callDur);
    } catch (_) {
      return null;
    }
  }
  return null;
}();
```

### 5. **call_report_list_screen.dart** (Line 216-230)
Added helper method `_parseCallDuration()`:
```dart
int? _parseCallDuration(dynamic callDur) {
  if (callDur == null) return null;
  if (callDur is int) return callDur;
  if (callDur is String) {
    try {
      return int.parse(callDur);
    } catch (_) {
      return null;
    }
  }
  return null;
}
```

Updated usage:
```dart
// Before:
duration: _formatDuration(report['callDuration'] as int?)

// After:
duration: _formatDuration(_parseCallDuration(report['callDuration']))
```

---

## How It Works

### Parsing Logic:
1. **Get value** from JSON (could be String, int, or null)
2. **Check if null** → return null
3. **Check if already int** → return as-is
4. **Check if String** → parse to int (e.g., `"29"` → `29`)
5. **If parsing fails** → return null (graceful fallback)

### Examples:
```
Input: "29" (String)     → Output: 29 (int)
Input: 29 (int)          → Output: 29 (int)
Input: null              → Output: null
Input: "invalid" (String) → Output: null (parsing fails)
```

---

## Expected Results After Fix

✅ **Reports load successfully** - No more type casting errors  
✅ **Call duration displays correctly** - "29 seconds", "2m 30s", etc.  
✅ **Complaints load** - No parsing errors  
✅ **Lead data updates** - callDuration parsed correctly  
✅ **Call report list** - Duration formatted properly  
✅ **Firebase Crashlytics** - No more type casting exceptions  

---

## Testing Checklist

- [ ] Open Reports screen → Should show completed leads with call duration
- [ ] Check Complaints screen → Should load without errors
- [ ] View Lead details → Call duration should display
- [ ] Check Call Report List → Duration should format correctly
- [ ] Monitor Firebase Crashlytics → No type casting errors
- [ ] Verify API response parsing → All callDuration values handled

---

## API Response Format

The API returns completed leads with callDuration as String:
```json
{
  "data": {
    "leads": [
      {
        "_id": "69c364e14d45297cf261aff9",
        "customerName": "ANNA",
        "phone": "8590685376",
        "callDuration": "29",           // ← String, not int
        "followupcallDuration": "77",   // ← String, not int
        "updatedAt": "2026-03-25T10:00:22.855Z"
      }
    ]
  }
}
```

All instances now handle this correctly.
