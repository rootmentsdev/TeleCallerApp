# Follow-Up Date Not Showing - Root Cause Analysis

## Problem Summary
When adding a follow-up for tomorrow, it doesn't appear in the "Tomorrow" tab. The logs show:
- Newly added leads have `followUpDate=null`
- Existing leads have `followUpDate=2026-03-23 00:00:00.000Z` (with timezone)

## Root Cause Identified

### 1. API Response Format
The backend is returning `followupDate` field (without "Up"):
```
Lead keys: [_id, phone, store, functionDate, followupDate, updatedBy, updatedAt, name]
```

### 2. Current Parsing Logic (lead_repository.dart, line ~840)
```dart
final followUpDate =
    _parseDate(leadData['follow_up_date']) ??
    _parseDate(leadData['followUpDate']) ??
    _parseDate(leadData['followupDate']);
```

This SHOULD work because it tries `followupDate` as the third option. However, there's a critical issue:

### 3. The Real Problem: Date Format Handling
Looking at the logs, existing leads show dates with timezone: `2026-03-23 00:00:00.000Z`

But the `_parseDate()` function may not be handling the MongoDB date format correctly when it's nested in an object like `{"$date": "2026-04-05T..."}`.

### 4. Why Newly Added Leads Show null
When a new follow-up is added:
1. The API response includes `followupDate` field
2. But `_parseDate()` might be failing to parse it
3. The function returns `null` silently
4. No error is logged about the parsing failure

## Solution Required

The `_parseDate()` function needs to:
1. Handle MongoDB date format: `{"$date": "ISO8601_STRING"}`
2. Handle ISO 8601 strings with timezone: `2026-04-05T00:00:00.000Z`
3. Handle plain date strings: `2026-04-05`
4. Log failures for debugging

## Files to Check
1. `frontend/lib/controller/lead_repository.dart` - `_parseDate()` function (lines 639-665)
2. Backend API response format - verify what format it's actually sending
3. `frontend/lib/controller/followup_controller.dart` - Tab filtering logic (lines 118-184)

## Next Steps
1. Add comprehensive logging to `_parseDate()` to see what format is being received
2. Verify backend is sending `followupDate` field in the API response
3. Test with actual app logs to confirm date parsing
4. Fix date parsing if needed
