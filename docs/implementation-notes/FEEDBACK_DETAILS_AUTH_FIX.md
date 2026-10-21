# Feedback Details Screen - Authentication Error Fix

## Problem
When opening a feedback (return lead) details screen, the app shows "Error loading feedback call" with message "Authentication failed. Please login again."

**Error Log:**
```
Exception: Authentication failed. Please login again.
#0 ApiService.getReturn (package:telecaller_app/services/api_service.dart:162:9)
#1 _ReturnLeadDetailsScreenState._fetchReturnLeadDetails (package:telecaller_app/view/lead_screen/return_lead_details_screen.dart:124:24)
```

## Root Cause
The authentication token is not being retrieved from SharedPreferences when the details screen tries to fetch lead data. This could be due to:

1. **Token not saved during login** - Token might not have been saved to SharedPreferences
2. **Token expired** - Token might have expired and needs refresh
3. **Token cleared** - Token might have been cleared by logout or app restart
4. **SharedPreferences issue** - Token might not be persisting properly

## Fixes Applied

### 1. Added Authentication Check in getReturn()
```dart
final headers = await _getAuthHeaders();

if (!headers.containsKey('Authorization')) {
  throw Exception('Authentication required. Please login again.');
}
```

This provides a clearer error message if the token is missing.

### 2. Added Logging to _getAuthHeaders()
```dart
final token = await AuthService.getToken();
print('ApiService: _getAuthHeaders - token=${token != null ? token.substring(0, 20) + '...' : 'NULL'}');
```

This will show in logs whether the token is being retrieved or not.

## Debugging Steps

### Step 1: Check if Token is Saved
After login, check the logs:
```
ApiService: _getAuthHeaders - token=eyJhbGciOiJIUzI1NiIs...
```

If you see `token=NULL`, the token was not saved during login.

### Step 2: Check Login Response
Verify that the login API response includes a token:
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {...}
}
```

### Step 3: Verify Token Persistence
After login, navigate away and come back. The token should still be available:
```
ApiService: _getAuthHeaders - token=eyJhbGciOiJIUzI1NiIs...
```

If token becomes NULL after navigation, SharedPreferences is not persisting it.

## Expected Behavior After Fix

### Scenario 1: User Logged In
1. User logs in successfully
2. Token is saved to SharedPreferences
3. User navigates to feedback details screen
4. `_getAuthHeaders()` retrieves token from SharedPreferences
5. API request includes Authorization header
6. Feedback details load successfully

### Scenario 2: Token Expired
1. User has old/expired token
2. API returns 401 Unauthorized
3. App should attempt token refresh
4. If refresh fails, show "Please login again" message

### Scenario 3: User Not Logged In
1. User tries to access feedback details without logging in
2. Token is NULL
3. App shows "Authentication required. Please login again."
4. User is redirected to login screen

## Files Modified
- `frontend/lib/services/api_service.dart`:
  - Added authentication check in `getReturn()` method
  - Added logging to `_getAuthHeaders()` method

## Testing Steps

1. **Rebuild app**: `flutter clean && flutter pub get && flutter run`
2. **Login** with valid credentials
3. **Check logs** for token retrieval:
   ```
   ApiService: _getAuthHeaders - token=eyJhbGciOiJIUzI1NiIs...
   ```
4. **Navigate to feedback screen** and click on a lead
5. **Verify** feedback details load without error
6. **Check logs** for successful API response

## If Issue Persists

If you still see "Authentication failed" error:

1. **Check login response** - Verify token is in login response
2. **Check SharedPreferences** - Verify token is being saved
3. **Check token format** - Verify token is not empty or malformed
4. **Check API endpoint** - Verify `/api/leads/{id}` endpoint is correct
5. **Check token expiry** - Verify token hasn't expired

## Next Steps
1. Rebuild and test
2. Share logs showing token retrieval
3. If token is NULL, check login flow
4. If token exists but API still fails, check backend API endpoint
