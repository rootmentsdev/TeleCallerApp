# Home Screen - Add New Lead Opens Outgoing Call Option

## Overview
Updated the "Add New Lead" quick action button on the home screen to open the outgoing call add lead bottom sheet instead of the regular add lead form.

## Changes Made

### File Updated
**File**: `frontend/lib/view/home_screen.dart`

### Changes

#### 1. Added Import
```dart
import 'package:telecaller_app/widgets.dart/add_lead_outgoing_call_bottom_sheet.dart';
```

#### 2. Updated "Add New Lead" Button
**Before**:
```dart
onTap: () {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => const AddLeadBottomSheet(),
  );
},
```

**After**:
```dart
onTap: () {
  showAddLeadOutgoingCallBottomSheet(context);
},
```

### What This Does

When users tap the "Add New Lead" quick action button on the home screen:
1. Opens the outgoing call add lead bottom sheet
2. Shows the "Outgoing Call" header with timestamp
3. Allows user to enter phone number
4. Prompts to make a call
5. After call, shows form to add lead details
6. Saves the lead with call information

### User Flow

1. **Home Screen** → User taps "Add New Lead"
2. **Outgoing Call Sheet Opens** → Shows call form
3. **Enter Phone Number** → User enters phone
4. **Make Call** → User taps "Call Now"
5. **Call Tracking** → System tracks call duration
6. **Add Details** → Form expands to show lead details
7. **Save Lead** → User saves the lead with call info

### Features of Outgoing Call Form

✅ Phone number input
✅ Customer name (optional)
✅ Call now button
✅ Call duration tracking
✅ Lead type selection (Enquiry, Booking)
✅ Store and location selection
✅ Function date picker
✅ Sub-category selection
✅ Close reason selection
✅ Item category selection
✅ Remarks/notes field
✅ Mark as complaint option
✅ Mark as follow-up option
✅ Follow-up date picker
✅ Save and cancel buttons

### Benefits

✅ Streamlined lead creation process
✅ Integrates call tracking automatically
✅ Captures call duration
✅ Ensures all leads have call information
✅ Better user experience
✅ Consistent with FAB (Floating Action Button) behavior

### Testing Checklist

- [x] File compiles without errors
- [x] No warnings
- [x] Import is correct
- [x] Function call is correct
- [ ] Test opening the outgoing call sheet
- [ ] Test phone number input
- [ ] Test making a call
- [ ] Test call duration tracking
- [ ] Test form expansion after call
- [ ] Test saving lead with call info
- [ ] Test on different screen sizes

## Related Files

- `frontend/lib/widgets.dart/add_lead_outgoing_call_bottom_sheet.dart` - The outgoing call form
- `frontend/lib/view/bottomnavigation_bar.dart` - Uses same function for FAB
- `frontend/lib/view/home_screen.dart` - Updated file

## Notes

- The outgoing call form is now the primary way to add leads from the home screen
- This matches the behavior of the FAB (Floating Action Button)
- Call tracking is automatically integrated
- All lead details are captured during the call process
