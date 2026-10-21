# Incoming Call Handler - API Path Fix

## Problem
The API calls were returning 404 errors because the paths were missing the `/api` prefix.

**Error Log:**
```
ApiService: getLeadDetails → URL: https://rootstele.onrender.com/leads/followups/69bd16f77e7966dbbaea4217
ApiService: getLeadDetails → status=404
ApiService: getLeadDetails → body={"success":false,"message":"Route not found: /leads/followups/69bd16f77e7966dbbaea4217","data":null}
```

## Root Cause
The `IncomingCallHandler` was calling `getLeadDetails()` with paths like:
- `/leads/followups/{id}` ❌
- `/leads/returns/{id}` ❌
- `/leads/booking-confirmation/{id}` ❌
- `/leads/complaints/{id}` ❌

But the correct paths should be:
- `/api/leads/followups/{id}` ✅
- `/api/leads/returns/{id}` ✅
- `/api/leads/booking-confirmation/{id}` ✅
- `/api/leads/complaints/{id}` ✅

## Solution
Updated all API path calls in `IncomingCallHandler` to include `/api` prefix:

```dart
// OLD (WRONG):
await _api.getLeadDetails('/leads/followups/$leadId');

// NEW (CORRECT):
await _api.getLeadDetails('/api/leads/followups/$leadId');
```

## Files Modified
- `frontend/lib/services/incoming_call_handler.dart`
  - `_openReturnScreen()` → `/api/leads/returns/{id}`
  - `_openBookingConfirmationScreen()` → `/api/leads/booking-confirmation/{id}`
  - `_openFollowupScreen()` → `/api/leads/followups/{id}`
  - `_openComplaintScreen()` → `/api/leads/complaints/{id}`
  - `_openReportScreen()` → `/api/leads/{id}`

## Expected Behavior After Fix
When an incoming call is received:
1. ✅ API returns lead data with `leadStatus: "followup"`
2. ✅ Handler correctly extracts lead info
3. ✅ Handler calls `_openFollowupScreen(context, leadId)`
4. ✅ Fetches full lead details from `/api/leads/followups/{leadId}` (200 OK)
5. ✅ Creates `LeadModel` from API response
6. ✅ Navigates to `FollowupDetailScreen` with prefilled data

## Testing
Next incoming call should:
- Show loading dialog
- Fetch lead details successfully (200 OK)
- Open FollowupDetailScreen with the lead data
- NOT show error or "New Customer" popup
