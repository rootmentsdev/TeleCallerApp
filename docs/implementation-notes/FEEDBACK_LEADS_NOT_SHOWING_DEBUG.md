# Feedback Leads Not Showing - Debugging Guide

## Problem
When selecting date 13/3/2026, the feedback leads are fetched from the API (21 leads) but not displayed in the UI.

**Logs Show:**
```
ApiService: Return response status: 200
LeadRepository: Fetched 21 Return leads successfully, 0 failed
LeadRepository: Return leads in repository: 21
```

But the UI shows no leads.

## Root Cause Analysis
The leads are being fetched and stored correctly, but they're being filtered out somewhere in the UI layer. The issue is likely one of:

1. **Date filtering** - Leads are being filtered by date and not matching
2. **Category filtering** - Leads are not being recognized as "Feedback" category
3. **Follow-up date filtering** - Leads with follow-up dates are being excluded
4. **Starred filtering** - Leads are being marked as starred and excluded

## Debugging Steps

### Step 1: Check Tab Selection
When you select date 13/3/2026, verify you're on the **Feedback Calls** tab (Tab 1).

### Step 2: Check Logs After Rebuild
After rebuilding with the new logging, select date 13/3/2026 and check for these logs:

```
LeadScreenController: Tab 1 (Feedback) - Total return leads in repo: 21
LeadScreenController: Tab 1 - Applying date range filter: 2026-03-13 00:00:00.000Z to 2026-03-13 23:59:59.999Z
LeadScreenController: Tab 1 - After date range filter: X leads
LeadScreenController: Tab 1 - After excluding starred: X leads
LeadScreenController: Tab 1 - After excluding follow-up dates: X leads
```

### Step 3: Identify Where Leads Are Filtered Out

**If "Total return leads in repo: 0"**
- Problem: Leads are not being stored with correct category
- Solution: Check if `leadtype: "return"` is being mapped to `categoryRentOut`

**If "After date range filter: 0"**
- Problem: Date filtering is removing all leads
- Logs will show: `Lead ${name} date ${date} NOT in range`
- Solution: Check if lead dates match the selected date range

**If "After excluding starred: 0"**
- Problem: All leads are marked as starred
- Solution: Check why leads are being marked as starred

**If "After excluding follow-up dates: 0"**
- Problem: All leads have follow-up dates set
- Solution: Check if follow-up dates are being set incorrectly

## Expected Behavior

For date 13/3/2026, the logs should show:
```
LeadScreenController: Tab 1 (Feedback) - Total return leads in repo: 21
LeadScreenController: Tab 1 - Applying date range filter: 2026-03-13 00:00:00.000Z to 2026-03-13 23:59:59.999Z
LeadScreenController: Tab 1 - After date range filter: 21 leads (or some number > 0)
LeadScreenController: Tab 1 - After excluding starred: 21 leads
LeadScreenController: Tab 1 - After excluding follow-up dates: 21 leads
```

Then the 21 leads should be displayed in the UI.

## Common Issues

### Issue 1: Date Mismatch
**Symptom**: Logs show "Lead X date 2026-03-15 does NOT match 2026-03-13"

**Cause**: The lead's effective date doesn't match the selected date

**Solution**: Check `lead.getEffectiveDate()` method to see which date field it's using

### Issue 2: All Leads Have Follow-up Dates
**Symptom**: "After excluding follow-up dates: 0 leads"

**Cause**: All return leads have `followUpDate` set

**Solution**: Check if follow-up dates are being set incorrectly during parsing

### Issue 3: Category Not Matching
**Symptom**: "Total return leads in repo: 0"

**Cause**: Leads are not being stored with `categoryRentOut`

**Solution**: Check if `leadtype: "return"` is being mapped correctly

## Next Steps

1. **Rebuild app**: `flutter clean && flutter pub get && flutter run`
2. **Select date 13/3/2026** and go to Feedback Calls tab
3. **Check the logs** for the filtering steps
4. **Share the logs** showing where leads are being filtered out
5. Based on the logs, we'll identify and fix the exact issue

## Files Modified
- `frontend/lib/controller/lead_screen_controller.dart` - Added detailed logging to feedback leads filtering
