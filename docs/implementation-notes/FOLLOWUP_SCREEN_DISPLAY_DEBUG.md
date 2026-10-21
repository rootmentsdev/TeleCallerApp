# Follow-Up Screen Display Debug

## Current Status
- ✓ Follow-up leads fetched from API correctly
- ✓ Leads stored in repository
- ✓ Leads shown in home screen
- ✗ Leads NOT shown in follow-up screen

## Debugging Steps

### 1. Check Tab Selection
The follow-up screen has 4 tabs:
- Tab 0: **Overdue** (default selected)
- Tab 1: **Today**
- Tab 2: **Tomorrow**
- Tab 3: **Upcoming**

**Issue**: If the lead has `followUpDate: 2026-03-29` and today is `2026-03-15`, it should be in Tab 3 (Upcoming), not Tab 0 (Overdue).

### 2. Expected Behavior
When screen loads:
1. Tab 0 (Overdue) is selected by default
2. Lead with March 29 date should NOT appear in Overdue tab
3. User must click "Upcoming" tab to see the lead

### 3. Logs to Check After Rebuild

**When screen loads:**
```
FollowupScreen: initState - fetchFollowUpLeads called
FollowupScreen: _buildCallsList called - currentLeads.length=0, selectedTab=0
```

**When user clicks "Upcoming" tab:**
```
FollowupScreen: Tab 3 (Upcoming) tapped
FollowupController: Filtering for Tab 3 (Upcoming)
FollowupController: Tab 3 (Upcoming) - Lead SAMKUTTY: followUpDate=2026-03-29 00:00:00.000Z, isUpcoming=true
FollowupScreen: _buildCallsList called - currentLeads.length=1, selectedTab=3
```

## Possible Issues

### Issue 1: Default Tab Shows No Leads
**Expected**: Tab 0 (Overdue) shows 0 leads because the lead is on March 29 (future date)
**Actual**: Should show "No follow-up calls" message

### Issue 2: Upcoming Tab Not Showing Leads
**Expected**: Tab 3 (Upcoming) shows 1 lead
**Actual**: Might show "No follow-up calls" if filtering logic is broken

### Issue 3: Badge Counts Wrong
**Expected**: 
- Overdue (0)
- Today (0)
- Tomorrow (0)
- Upcoming (1)

**Actual**: Check if counts are correct

## Solution
1. **Rebuild app**: `flutter clean && flutter pub get && flutter run`
2. **Check logs** when screen loads
3. **Click "Upcoming" tab** and check logs
4. **Share the logs** so we can identify the exact issue

## Files Modified for Debugging
- `frontend/lib/view/followup_screen/followup_screen.dart` - Added logging to tab clicks and list building
- `frontend/lib/controller/followup_controller.dart` - Already has detailed logging

## Key Points
- The lead MUST be in the repository (confirmed by logs)
- The lead MUST have a valid followUpDate (confirmed by logs)
- The filtering logic MUST work correctly (need to verify with logs)
- The UI MUST rebuild when tab changes (need to verify with logs)
