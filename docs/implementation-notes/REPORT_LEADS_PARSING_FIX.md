# Report Leads Not Showing - Parsing Error Fixed

## Problem
Reports were not displaying because of a **type casting error** when parsing the API response.

### Error Log:
```
type 'String' is not a subtype of type 'int?' in type cast
#0 new ReportModel.fromJson (package:telecaller_app/model/report_model.dart:156:65)
```

### Root Cause:
The API returns `callDuration` as a **String** (`"29"`), but the code was trying to cast it directly as an **int**:

```dart
// ❌ WRONG - Expects int, but API sends String
callDuration: json['call_duration'] as int? ?? json['callDuration'] as int?
```

When the API response contains:
```json
{
  "callDuration": "29",
  "followupcallDuration": "77"
}
```

The direct cast fails because `"29"` (String) cannot be cast to `int?`.

---

## Solution Applied

Updated the parsing logic to handle both String and int types:

```dart
// ✅ FIXED - Handles String, int, or null
callDuration: () {
  final callDur = json['call_duration'] ?? json['callDuration'];
  if (callDur == null) return null;
  if (callDur is int) return callDur;
  if (callDur is String) {
    try {
      return int.parse(callDur);  // Convert "29" → 29
    } catch (_) {
      return null;
    }
  }
  return null;
}(),
```

### How it works:
1. Gets `callDuration` from either `call_duration` or `callDuration` key
2. If null → returns null
3. If already int → returns as-is
4. If String → parses to int (e.g., `"29"` → `29`)
5. If parsing fails → returns null (graceful fallback)

---

## Why Reports Weren't Showing

The parsing error in `ReportModel.fromJson()` caused:
1. **Exception thrown** when creating ReportModel from API response
2. **Entire response rejected** - no reports added to list
3. **UI shows empty state** - "Total reports: 0"
4. **Error logged** to Firebase Crashlytics

The fix allows the parsing to succeed, so reports now display correctly.

---

## API Response Format

The API returns completed leads with this structure:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "leads": [
      {
        "_id": "69c364e14d45297cf261aff9",
        "leadtype": "bookingConfirmation",
        "customerName": "ANNA",
        "phone": "8590685376",
        "callDuration": "29",           // ← String, not int
        "followupcallDuration": "77",   // ← String, not int
        "followupremarks": "bookef",
        "updatedAt": "2026-03-25T10:00:22.855Z"
      }
    ]
  }
}
```

---

## Testing

After this fix:
- ✅ Reports should load without errors
- ✅ Call duration displays correctly (e.g., "29 seconds")
- ✅ No more "type 'String' is not a subtype of type 'int?'" errors
- ✅ Firebase Crashlytics should show no parsing errors

---

## Files Modified

- `frontend/lib/model/report_model.dart` - Line 156-165
  - Updated `callDuration` parsing to handle String → int conversion
