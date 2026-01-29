# Add Lead Bottom Sheet - Not Closing After Save Fix

## Problem
When clicking "Save Lead" button:
1. Circular loading indicator shows
2. Lead saves to backend successfully
3. BUT the bottom sheet doesn't close/pop back
4. User is stuck on the form with loading indicator

## Root Cause
The error handling in `_saveLead()` method had a `finally` block that was always executing `setState(() { _isLoading = false; })` even after successful save. This caused the loading state to be reset but the sheet wasn't properly closed in all scenarios.

Additionally, if an error occurred during the API call, the sheet would show an error snackbar but wouldn't close, leaving the user stuck.

## Solution
Restructured the error handling:

**Before:**
```dart
try {
  // API call and save logic
  if (mounted) {
    Navigator.pop(context); // Close sheet
  }
} catch (e) {
  // Show error snackbar
} finally {
  setState(() { _isLoading = false; }); // Always executes
}
```

**After:**
```dart
try {
  // API call and save logic
  if (mounted) {
    Navigator.pop(context); // Close sheet
  }
} catch (e) {
  print('Error: $e');
  if (mounted) {
    setState(() { _isLoading = false; }); // Only on error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error saving lead: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
```

## Changes Made
**File**: `frontend/lib/widgets.dart/add_lead_bottom_sheet.dart`

1. Removed `finally` block
2. Moved `setState(() { _isLoading = false; })` into the `catch` block
3. Added debug logging for errors
4. Added duration to error snackbar (3 seconds)
5. Only reset loading state when an error occurs

## Expected Behavior
✅ Click "Save Lead" → Loading indicator shows
✅ Lead saves to backend
✅ Bottom sheet automatically closes/pops
✅ User returns to previous screen
✅ If error occurs → Error message shows for 3 seconds, loading stops, sheet stays open for retry

## Flow
1. User fills form and clicks "Save Lead"
2. Loading indicator appears (button disabled)
3. API call to create lead
4. If successful:
   - Lead added to local repository
   - Bottom sheet closes automatically
   - If marked as follow-up → Navigate to Follow Up screen
5. If error:
   - Loading indicator stops
   - Error snackbar shows for 3 seconds
   - User can retry or cancel

## Testing
- Create a new lead with all required fields
- Click "Save Lead"
- Verify loading indicator shows
- Verify bottom sheet closes after save completes
- Verify navigation to Follow Up screen if marked as follow-up
- Test error scenario by disconnecting network and trying to save
