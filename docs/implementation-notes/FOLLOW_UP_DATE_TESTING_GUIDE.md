# Follow-Up Date Testing Guide

## Changes Made

Enhanced logging has been added to `frontend/lib/controller/lead_repository.dart` to help diagnose why follow-up dates are not being parsed correctly:

### 1. Enhanced `_parseDate()` Function
- Added detailed logging for each parsing attempt
- Logs successful and failed date parsing
- Shows the raw date value and the parsed result
- Helps identify date format issues

### 2. Enhanced `_parseApiLeadToLeadModel()` Function
- Added logging before parsing followUpDate
- Shows all three field name variations being checked
- Logs the final parsed followUpDate value
- Helps identify which field name the backend is using

### 3. Enhanced `fetchFollowUpLeadsFromApi()` Function
- Added logging of the first lead's complete data structure
- Helps verify the API response format

## Testing Steps

### Step 1: Run the App with Enhanced Logging
1. Run the app in debug mode
2. Open the Follow-Up screen
3. Check the console logs for messages starting with "LeadRepository:"

### Step 2: Add a New Follow-Up for Tomorrow
1. Go to the Lead screen
2. Add a new lead or select an existing lead
3. Add a follow-up for tomorrow (2026-04-05)
4. Check the logs for:
   - `LeadRepository: Parsing followUpDate for lead "..."` - Shows what values are being checked
   - `LeadRepository: Final followUpDate for lead "..."` - Shows the parsed result
   - `LeadRepository: Attempting to parse date string: "..."` - Shows the raw date value

### Step 3: Check the Follow-Up Screen
1. Go to the Follow-Up screen
2. Click on the "Tomorrow" tab
3. Verify the newly added lead appears in the list

## Expected Log Output

### If Date Parsing Works:
```
LeadRepository: Parsing followUpDate for lead "John Doe" - follow_up_date=null, followUpDate=null, followupDate=2026-04-05T00:00:00.000Z
LeadRepository: Attempting to parse date string: "2026-04-05T00:00:00.000Z"
LeadRepository: Successfully parsed date: 2026-04-05T00:00:00.000Z => 2026-04-05 00:00:00.000Z
LeadRepository: Final followUpDate for lead "John Doe": 2026-04-05 00:00:00.000Z
```

### If Date Parsing Fails:
```
LeadRepository: Parsing followUpDate for lead "John Doe" - follow_up_date=null, followUpDate=null, followupDate=2026-04-05
LeadRepository: Attempting to parse date string: "2026-04-05"
LeadRepository: Successfully parsed date: 2026-04-05 => 2026-04-05 00:00:00.000
LeadRepository: Final followUpDate for lead "John Doe": 2026-04-05 00:00:00.000
```

### If Date Parsing Completely Fails:
```
LeadRepository: Parsing followUpDate for lead "John Doe" - follow_up_date=null, followUpDate=null, followupDate={"$date":"2026-04-05T00:00:00.000Z"}
LeadRepository: Attempting to parse date string: "{"$date":"2026-04-05T00:00:00.000Z"}"
LeadRepository: DateTime.parse failed for "{"$date":"2026-04-05T00:00:00.000Z"}", error: ..., attempting manual parsing
LeadRepository: Could not parse date "{"$date":"2026-04-05T00:00:00.000Z"}" - not in expected format
LeadRepository: Final followUpDate for lead "John Doe": null
```

## Troubleshooting

### If followUpDate is still null:
1. Check the API response format - look for "First lead data structure" log
2. Verify the backend is returning the `followupDate` field
3. Check if the date format is different from expected
4. Report the exact log output to the development team

### If the date is parsed but still not showing in Tomorrow tab:
1. Check the tab filtering logic in `followup_controller.dart`
2. Verify the date comparison logic is correct
3. Check if the lead's category is "Follow Up"

## Files Modified
- `frontend/lib/controller/lead_repository.dart`
  - Enhanced `_parseDate()` function with detailed logging
  - Enhanced `_parseApiLeadToLeadModel()` function with logging
  - Enhanced `fetchFollowUpLeadsFromApi()` function with logging

## Next Steps After Testing
1. Run the app and add a follow-up for tomorrow
2. Check the console logs
3. Share the log output if the issue persists
4. If logs show the date is being parsed correctly but still not appearing, the issue is in the tab filtering logic
