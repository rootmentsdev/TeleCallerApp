# Follow-Up Date Not Showing in Tomorrow Tab - Analysis

## Problem
When adding a follow-up for tomorrow, it doesn't appear in the "Tomorrow" tab of the Follow-Ups screen.

## Log Analysis

### Key Observations from Logs:

1. **Backend is sending the data:**
   ```
   LeadRepository: Lead keys: [_id, phone, store, functionDate, followupDate, updatedBy, updatedAt, name]
   ```
   ✓ Backend includes `followupDate` field

2. **But frontend is not parsing it:**
   ```
   FollowupController: Lead - name=name, followUpDate=null, category=Follow Up
   FollowupController: Lead - name=ANEESH V MOHAN, followUpDate=null, category=Follow Up
   FollowupController: Lead - name=ADHI, followUpDate=null, category=Follow Up
   ```
   ✗ Frontend shows `followUpDate=null` for newly added leads

3. **Existing leads work fine:**
   ```
   FollowupController: Lead - name=customer, followUpDate=2026-03-23 00:00:00.000Z, category=Follow Up
   FollowupController: Lead - name= STANIYA (SHEELA YESUDAS): followUpDate=2026-03-24 18:30:00.000Z, category=Follow Up
   ```
   ✓ Older leads have `followUpDate` parsed correctly

## Root Cause

The issue is in `lead_repository.dart` line 840-843:

```dart
final followUpDate =
    _parseDate(leadData['follow_up_date']) ??      // snake_case
    _parseDate(leadData['followUpDate']) ??        // camelCase with "Up"
    _parseDate(leadData['followupDate']);          // camelCase without "Up"
```

**The backend is sending `followupDate` (without "Up")**, but the code tries to parse it in this order:
1. `follow_up_date` - NOT in response ✗
2. `followUpDate` - NOT in response ✗
3. `followupDate` - IN response ✓ (should work)

However, the `_parseDate()` function might be failing silently if the date format is not ISO 8601.

## Solution

### Step 1: Add Logging (Already Done)
Added debug logging to see what's being sent:
```dart
print(
  'LeadRepository: Parsing followUpDate - follow_up_date=${leadData['follow_up_date']}, followUpDate=${leadData['followUpDate']}, followupDate=${leadData['followupDate']}, parsed=$followUpDate',
);
```

### Step 2: Check Backend Response Format
The backend might be sending the date in a format that `DateTime.parse()` can't handle. Common issues:
- MongoDB date format: `{"$date": "2026-04-05T00:00:00.000Z"}`
- Unix timestamp: `1712275200000`
- Custom format: `"2026-04-05"` or `"05-04-2026"`

### Step 3: Improve Date Parsing
Update `_parseDate()` to handle MongoDB date format:

```dart
DateTime? _parseDate(dynamic dateValue) {
  if (dateValue == null) return null;
  
  // Handle MongoDB date format: {"$date": "2026-04-05T..."}
  if (dateValue is Map) {
    final dateStr = dateValue['\$date']?.toString() ?? dateValue['date']?.toString();
    if (dateStr != null) {
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return null;
      }
    }
  }
  
  final dateStr = dateValue.toString().trim();
  if (dateStr.isEmpty) return null;

  try {
    return DateTime.parse(dateStr);
  } catch (e) {
    // Try manual parsing for non-ISO formats
    final parts = dateStr.split(RegExp(r'[-/]'));
    if (parts.length == 3) {
      try {
        final nums = parts.map((p) => int.parse(p)).toList();
        if (nums[0] > 31)
          return DateTime(nums[0], nums[1], nums[2]); // yyyy-MM-dd
        if (nums[2] > 31)
          return DateTime(nums[2], nums[1], nums[0]); // dd-MM-yyyy
        return DateTime(nums[2], nums[0], nums[1]); // MM/dd/yyyy
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
```

## Expected Behavior After Fix

```
Today: 2026-04-04
Tomorrow: 2026-04-05

When follow-up is added for tomorrow (2026-04-05):
  ✓ followUpDate will be parsed correctly
  ✓ Lead will appear in "Tomorrow" tab
  ✓ Lead will be sorted by date
```

## Files to Check/Modify

1. **frontend/lib/controller/lead_repository.dart**
   - Line 639-665: `_parseDate()` function
   - Line 840-843: followUpDate parsing
   - Add logging to verify date format

2. **Backend API Response**
   - Verify the exact format of `followupDate` field
   - Check if it's ISO 8601 or MongoDB format

## Testing Steps

1. Add a follow-up for tomorrow
2. Check the logs for the parsed date
3. Verify it appears in the "Tomorrow" tab
4. Check other tabs (Today, Upcoming, Overdue)
