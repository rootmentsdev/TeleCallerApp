# Save Button Disabled Until Call is Made - COMPLETED

## Problem
The save button in add lead bottom sheets was enabled before a call was made, allowing users to save leads without actually making a call.

## Solution
Updated both add lead bottom sheets to disable the save button until a call is made:

### Changes Made

**File: `frontend/lib/widgets.dart/add_lead_bottom_sheet.dart`**
- Updated save button `onPressed` condition to check if `_callDuration` is null or 0
- Button now disabled until incoming call is received with call duration > 0
- Condition: `(_isLoading || _callDuration == null || _callDuration == 0) ? null : _saveLead`

**File: `frontend/lib/widgets.dart/add_lead_outgoing_call_bottom_sheet.dart`**
- Updated save button `onPressed` condition to check if `_hasCalled` is true and `_callDuration` > 0
- Button now disabled until "Call Now" button is clicked and call is completed
- Condition: `(_isLoading || !_hasCalled || _callDuration == 0) ? null : _saveLead`

## Behavior

### Incoming Call Sheet
- Save button is **disabled** when form first opens
- Save button becomes **enabled** only after incoming call is received (when `_callDuration` > 0)
- Button remains disabled if call duration is 0

### Outgoing Call Sheet
- Save button is **disabled** when form first opens
- User must click "Call Now" button to make a call
- Save button becomes **enabled** only after call is completed (when `_hasCalled` is true and `_callDuration` > 0)
- Button remains disabled if call duration is 0

## User Experience
- Prevents accidental lead creation without actual call
- Clear visual feedback (grayed out button) when save is not available
- Ensures all leads have associated call data
- Maintains data integrity

## Files Modified
- `frontend/lib/widgets.dart/add_lead_bottom_sheet.dart`
- `frontend/lib/widgets.dart/add_lead_outgoing_call_bottom_sheet.dart`

## Result
✅ Save button is now disabled until a call is made
✅ Both incoming and outgoing call sheets enforce call requirement
✅ All code compiles without errors
