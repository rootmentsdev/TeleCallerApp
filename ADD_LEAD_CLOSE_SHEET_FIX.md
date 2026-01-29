# Add Lead Bottom Sheet - Auto Close After Save Fix

## Problem
When clicking "Save Lead" button:
1. Circular loading indicator shows
2. Lead saves to backend successfully
3. BUT the bottom sheet doesn't close automatically
4. Loading indicator stays on indefinitely
5. User is stuck on the form

## Root Cause
After successful API call and local save, the code was calling `Navigator.pop(context)` to close the sheet, BUT the `_isLoading` state was never being reset to `false`. This caused:
- The button to remain disabled
- The loading indicator to keep spinning
- The UI to appear frozen

The `_isLoading` state was only being reset in the error catch block, not on success.

## Solution
Added `setState(() { _isLoading = false; })` BEFORE calling `Navigator.pop(context)` on successful save:

```dart
if (mounted) {
  setState(() {
    _isLoading = false;  // Reset loading state on success
  });
  
  if (_markAsFollowUp && _followUpDate != null) {
    Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BottomNavState.navigateToFollowUp();
    });
  } else {
    Navigator.pop(context);
  }
}
```

## Changes Made
**File**: `frontend/lib/widgets.dart/add_lead_bottom_sheet.dart`

Added `setState(() { _isLoading = false; })` in the success path before closing the sheet.

## Expected Behavior
✅ Click "Save Lead" → Loading indicator shows
✅ Lead saves to backend
✅ Loading indicator stops
✅ Bottom sheet automatically closes/pops
✅ User returns to previous screen
✅ If marked as follow-up → Navigate to Follow Up screen

## Flow
1. User fills form and clicks "Save Lead"
2. Loading indicator appears (button disabled)
3. API call to create lead
4. Lead added to local repository
5. **Loading state reset to false** ← NEW
6. Bottom sheet closes automatically
7. If marked as follow-up → Navigate to Follow Up screen
8. If error → Error message shows, loading stops, sheet stays open

## Testing
- Create a new lead with all required fields
- Click "Save Lead"
- Verify loading indicator shows briefly
- Verify loading indicator stops
- Verify bottom sheet closes automatically
- Verify user returns to previous screen
- Test with follow-up enabled to verify navigation works
