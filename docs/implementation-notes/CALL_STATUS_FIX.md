# Call Status Enum Fix

## Problem
Backend was rejecting lead creation with error:
```
"LeadMaster validation failed: callStatus: `not called` is not a valid enum value"
```

The backend only accepts these exact enum values:
- `connected`
- `not connected`
- `interested`
- `not interested`
- `forwarded`

## Root Causes

### Issue 1: callStatus Not Being Passed
In `AddLeadBottomSheet._saveLead()`, the `callStatus` parameter was NOT being passed to `apiService.createLead()`. This caused the API to use the default value `'Not Called'`, which is not a valid backend enum.

### Issue 2: Invalid Default Value
In `ApiService._normalizeCallStatus()`, the default case was returning `'not called'`, which the backend doesn't accept.

## Fixes Applied

### Fix 1: Pass callStatus to createLead
**File**: `frontend/lib/widgets.dart/add_lead_bottom_sheet.dart`

Added `callStatus: _selectedCallStatus` to the `createLead()` call:
```dart
final apiResponse = await apiService.createLead(
  // ... other parameters ...
  callStatus: _selectedCallStatus,  // ← ADDED
);
```

### Fix 2: Update Default Value
**File**: `frontend/lib/services/api_service.dart`

Changed the default case in `_normalizeCallStatus()` to return a valid enum value:
```dart
String _normalizeCallStatus(String status) {
  switch (status.toLowerCase()) {
    case 'connected':
      return 'connected';
    case 'not connected':
      return 'not connected';
    case 'interested':
      return 'interested';
    case 'not interested':
      return 'not interested';
    case 'forwarded':
      return 'forwarded';
    case 'not called':
    case '':
    default:
      // Backend doesn't accept 'not called', use 'not connected' as default
      return 'not connected';  // ← CHANGED FROM 'not called'
  }
}
```

## Expected Behavior After Fix

### When User Selects Call Status:
1. User selects from dropdown: Connected, Not Connected, Interested, Not Interested, or Forwarded
2. User clicks "Save Lead"
3. `_selectedCallStatus` is passed to API
4. API normalizes it to lowercase (e.g., "Connected" → "connected")
5. Backend accepts the valid enum value
6. Lead is created successfully (200/201 response)
7. If status is "Interested" or "Not Connected", FollowupDetailScreen opens

### When callStatus is null/empty:
- Defaults to `'not connected'` (valid backend enum)
- Lead creation succeeds

## Testing
1. Receive incoming call
2. Phone doesn't exist
3. Click "Add Enquiry"
4. Select "Interested" from Call Status dropdown
5. Click "Save Lead"
6. Should see 200/201 response (not 400)
7. FollowupDetailScreen should open
