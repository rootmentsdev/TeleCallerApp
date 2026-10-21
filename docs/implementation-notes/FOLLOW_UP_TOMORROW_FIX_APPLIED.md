# Follow-Up Tomorrow Not Showing - FIX APPLIED

## Problem
When adding a follow-up for tomorrow, it doesn't appear in the "Tomorrow" tab. The logs showed:
```
LeadRepository: Added 6 new follow-up leads, failed to parse 32
```

**32 out of 38 leads were failing to parse!**

## Root Cause
In `lead_repository.dart` line 825-826, the parsing logic required BOTH `name` and `phone` fields to be non-empty:
```dart
if (name.isEmpty || phone.isEmpty) return null;
```

The backend was returning leads with empty `name` fields (newly added follow-ups), causing them to be skipped during parsing.

## Solution Applied

### Change 1: Make `name` Field Optional
**File**: `frontend/lib/controller/lead_repository.dart` (line 759)

**Before**:
```dart
final name =
    _extractField(leadData, [...]) ?? '';  // Empty string as default
```

**After**:
```dart
final name =
    _extractField(leadData, [...]) ?? 'Unknown';  // 'Unknown' as default
```

### Change 2: Only Require `phone` Field
**File**: `frontend/lib/controller/lead_repository.dart` (line 825-826)

**Before**:
```dart
if (name.isEmpty || phone.isEmpty) {
  print('LeadRepository: Skipping lead - name is empty: ${name.isEmpty}, phone is empty: ${phone.isEmpty}, name="$name", phone="$phone"');
  return null;
}
```

**After**:
```dart
if (phone.isEmpty) {
  print('LeadRepository: Skipping lead - phone is empty');
  return null;
}
```

## Expected Result

### Before Fix
```
LeadRepository: Added 6 new follow-up leads, failed to parse 32
FollowupController: Returning 0 leads for tab=2 (Tomorrow)
```

### After Fix
```
LeadRepository: Added 38 new follow-up leads, failed to parse 0
FollowupController: Lead - name=Unknown, followUpDate=2026-04-05 00:00:00.000Z
FollowupController: Returning 1 leads for tab=2 (Tomorrow)
```

## Testing Steps

1. **Add a follow-up for tomorrow**
   - Go to Follow-Up screen
   - Add a new follow-up with tomorrow's date
   - Save the follow-up

2. **Check the logs**
   - Look for: `LeadRepository: Added X new follow-up leads, failed to parse Y`
   - Y should be 0 (no failures)

3. **Verify in UI**
   - Go to "Tomorrow" tab
   - The newly added follow-up should appear
   - Name should show as "Unknown" if not provided by backend

4. **Verify date parsing**
   - Check that `followUpDate` is correctly parsed
   - Lead should be sorted by date

## Files Modified
- `frontend/lib/controller/lead_repository.dart`
  - Line 759: Changed default name from `''` to `'Unknown'`
  - Line 825-826: Changed validation to only require `phone` field

## Notes
- The `_parseDate()` function already handles MongoDB date format `{"$date": "..."}` and ISO 8601 formats
- The `followupDate` field (camelCase without "Up") is correctly parsed from backend response
- Leads without names will now display as "Unknown" instead of being skipped
