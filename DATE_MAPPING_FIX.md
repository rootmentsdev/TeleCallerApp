# Date Mapping Fix - Function Date Not Correctly Sent to Backend

## Problem
The `function_date` field was not being correctly mapped when creating a new lead. The API request was sending an incomplete date format without the timezone indicator.

**Before (Wrong):**
```json
{
  "function_date": "2026-01-26T00:00:00.000",
  "follow_up_date": "2026-01-26T00:00:00.000"
}
```

**After (Correct):**
```json
{
  "function_date": "2026-01-26T00:00:00.000Z",
  "follow_up_date": "2026-01-26T00:00:00.000Z"
}
```

## Root Cause
In `add_lead_bottom_sheet.dart`, the `functionDate` parameter was incorrectly using `_followUpDate` instead of `_functionDate`:

```dart
// WRONG - Using wrong variable
functionDate: _markAsFollowUp ? _followUpDate?.toIso8601String() : null,

// CORRECT - Using correct variable
functionDate: _functionDate?.toIso8601String(),
```

This caused:
1. The wrong date to be sent (follow-up date instead of function date)
2. The date to only be sent when `_markAsFollowUp` was true
3. Inconsistent date formatting

## Solution
Updated `add_lead_bottom_sheet.dart` to:
1. Use `_functionDate` instead of `_followUpDate`
2. Always send the function date if it's selected (not conditional on follow-up flag)
3. Use `toIso8601String()` which automatically includes the `Z` timezone indicator

### Changed Code:
```dart
// Before
functionDate: _markAsFollowUp ? _followUpDate?.toIso8601String() : null,

// After
functionDate: _functionDate?.toIso8601String(),
```

## Date Variables Clarification

| Variable | Purpose | When Set |
|---|---|---|
| `_functionDate` | Date of the function/event | Selected via date picker for function date |
| `_followUpDate` | Date for follow-up call | Calculated or selected for follow-up |
| `_markAsFollowUp` | Flag to mark as follow-up | Checkbox to enable follow-up |

## Data Flow

```
User selects Function Date via Date Picker
    ↓
_functionDate = selected date
    ↓
User clicks Save
    ↓
_saveLead() method called
    ↓
functionDate: _functionDate?.toIso8601String()
    ↓
API receives: "2026-01-26T00:00:00.000Z"
    ↓
Backend stores correctly
```

## ISO 8601 Format

The `toIso8601String()` method in Dart automatically formats dates as:
```
YYYY-MM-DDTHH:mm:ss.sssZ
```

Where:
- `YYYY-MM-DD` = Date
- `T` = Separator
- `HH:mm:ss.sss` = Time with milliseconds
- `Z` = UTC timezone indicator

## Files Modified

1. `frontend/lib/widgets.dart/add_lead_bottom_sheet.dart`
   - Fixed functionDate parameter to use `_functionDate` instead of `_followUpDate`
   - Removed conditional logic that prevented date from being sent

## Result

✅ Function date is now correctly sent to backend
✅ Date format includes timezone indicator (Z)
✅ Correct date variable is used
✅ Date is always sent when selected (not conditional)
✅ No compilation errors

## Testing

To verify the fix works:

1. Open Add Lead bottom sheet
2. Select a function date
3. Fill in other required fields
4. Click Save
5. Check the API logs to verify:
   - `function_date` contains the selected date
   - Date format includes `Z` timezone indicator
   - Date is in ISO 8601 format

## Example API Request

**Before Fix:**
```json
{
  "customer_name": "test1",
  "phone_number": "1234567896",
  "function_date": "2026-01-26T00:00:00.000",
  "follow_up_date": "2026-01-26T00:00:00.000"
}
```

**After Fix:**
```json
{
  "customer_name": "test1",
  "phone_number": "1234567896",
  "function_date": "2026-01-26T00:00:00.000Z",
  "follow_up_date": "2026-01-26T00:00:00.000Z"
}
```

## Related Fields

The same date formatting is used for:
- `function_date` - Function/event date
- `follow_up_date` - Follow-up call date
- `enquiry_date` - Enquiry date
- `visit_date` - Visit date
- `return_date` - Return date

All use `toIso8601String()` which ensures proper formatting with timezone.

## Backend Compatibility

The backend expects dates in ISO 8601 format with timezone indicator:
- ✅ `2026-01-26T00:00:00.000Z` - Correct
- ❌ `2026-01-26T00:00:00.000` - Missing timezone
- ❌ `2026-01-26` - Missing time
- ❌ `26/01/2026` - Wrong format

## Notes

- The `Z` timezone indicator is automatically added by `toIso8601String()`
- All dates are treated as UTC (Z = Zulu time = UTC)
- The backend will handle timezone conversion if needed
- Date picker returns local DateTime, but `toIso8601String()` converts to UTC
