# Follow-Up Date Parsing Fix

## Problem
Follow-up leads were being fetched from the API but not displayed in the Follow-ups screen. The logs showed:
- API returns 1 follow-up lead ✓
- Repository stores 1 follow-up lead ✓
- But `getCurrentLeads()` returns 0 leads for all tabs ✗

## Root Cause
The API returns `"followupDate"` (lowercase 'u') but the code was only checking for:
- `follow_up_date` (snake_case)
- `followUpDate` (camelCase with uppercase 'U')

So the `followUpDate` field was being parsed as NULL, and leads with NULL followUpDate are filtered out by all tabs.

## API Response Structure
```json
{
  "data": {
    "leads": [
      {
        "_id": "69b679bd05c2cb405e025972",
        "customerName": "SAMKUTTY",
        "phone": "7559959449",
        "followupDate": "2026-03-29T10:00:00.000Z",  // ← lowercase 'u'
        ...
      }
    ]
  }
}
```

## Fix Applied
Updated `_parseApiLeadToLeadModel()` in `lead_repository.dart` to check for lowercase variant:

```dart
final followUpDate =
    _parseDate(leadData['follow_up_date']) ??      // snake_case
    _parseDate(leadData['followUpDate']) ??        // camelCase (uppercase U)
    _parseDate(leadData['followupDate']);          // lowercase u (API returns this)
```

## Files Modified
- `frontend/lib/controller/lead_repository.dart` - Added lowercase `followupDate` check

## Expected Result After Fix
1. Follow-up date will be parsed correctly from API response
2. Leads will be filtered into correct tabs based on followUpDate
3. Follow-ups screen will display leads in appropriate tabs:
   - **Overdue** - Leads with followUpDate < today
   - **Today** - Leads with followUpDate = today
   - **Tomorrow** - Leads with followUpDate = tomorrow
   - **Upcoming** - Leads with followUpDate > tomorrow

## Testing
1. Rebuild app: `flutter clean && flutter pub get && flutter run`
2. Navigate to Follow-ups screen
3. Verify leads now appear in the correct tab based on their followUpDate
4. Check that badge counts are correct
5. Verify leads are sorted by date (earliest first)

## Key Takeaway
Always check for multiple case variations when parsing API responses:
- `snake_case` (backend standard)
- `camelCase` (JavaScript standard)
- `lowercase` (sometimes used in APIs)
