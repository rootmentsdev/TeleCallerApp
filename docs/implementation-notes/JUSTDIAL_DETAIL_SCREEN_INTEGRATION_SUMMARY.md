# JustDial Lead Detail Screen API Integration Summary

## Overview
Successfully integrated the `/leads/justdial/{id}` endpoint to fetch detailed JustDial lead information and display it on the JustDial detail screen.

## Changes Made

### 1. API Configuration (`frontend/lib/utils/api_config.dart`)
- Added `getJustDialLeadById(String id)` static method
- Constructs the endpoint URL: `{baseUrl}/api/leads/justdial/{id}`

### 2. API Service (`frontend/lib/services/api_service.dart`)
- Added `getJustDialLeadById(String id)` method to fetch individual JustDial lead details
- Handles authentication headers and error responses
- Normalizes response data from snake_case to camelCase using `_snakeToCamel()`
- Includes proper error handling and Firebase Crashlytics logging
- Returns normalized Map<String, dynamic> with lead details

### 3. JustDial Detail Screen (`frontend/lib/view/lead_screen/justdial_detail_screen.dart`)
- Added `justDialData` field to store fetched lead details
- Added `_isLoading` and `_error` fields for state management
- Added `_fetchJustDialLeadDetails()` method that:
  - Calls the API service to fetch lead details by ID
  - Handles loading and error states
  - Updates UI with fetched data
- Added `_getDisplayValue()` helper method to safely display API data with fallbacks
- Updated build method to:
  - Show loading spinner while fetching data
  - Show error message with retry button if fetch fails
  - Display fetched data in the detail card (Attended by, Booking Date, Pick Up Date, Advance Amount, Total Amount)
  - Support both snake_case and camelCase field names from API

## Features

✅ Fetches JustDial lead details from `/leads/justdial/{id}` endpoint
✅ Handles loading state with spinner
✅ Handles error state with retry button
✅ Displays dynamic data from API (not hardcoded)
✅ Supports multiple field name variations (snake_case and camelCase)
✅ Safe value extraction with fallback defaults
✅ Proper error handling and logging
✅ Maintains existing UI/UX design

## Data Flow

1. User taps on a JustDial lead from the list
2. JustDialDetailScreen is opened with the lead model
3. `initState()` calls `_fetchJustDialLeadDetails()`
4. Loading spinner is shown while fetching
5. API request is sent to `/leads/justdial/{leadId}`
6. Response is normalized and stored in `justDialData`
7. UI is updated with fetched data
8. User can view all lead details and make a call

## API Endpoint Details

**Endpoint:** `GET /leads/justdial/{id}`

**Path Parameters:**
- `id` (required): The JustDial lead ID

**Response Format:**
```json
{
  "_id": "lead_id",
  "lead_name": "Customer Name",
  "phone_number": "9876543210",
  "store": "Brand - Location",
  "attended_by": "Staff Name",
  "booking_date": "2025-10-30",
  "function_date": "2026-11-02",
  "advance": 5500,
  "total_amount": 7500,
  "product_amount": 7500,
  "call_status": "Not Called",
  "lead_status": "New Lead",
  "created_at": "2026-04-18T10:30:00Z",
  ...
}
```

## Field Mapping

The screen displays the following fields from the API response:

| Display Label | API Field Names (tried in order) |
|---|---|
| Attended by | `attendedBy`, `attended_by` |
| Booking Date | `bookingDate`, `booking_date` |
| Pick Up Date | `functionDate`, `function_date` |
| Advance Amount | `advance`, `advanceAmount` |
| Total Amount | `totalAmount`, `total_amount`, `productAmount`, `product_amount` |

## Error Handling

- Network errors are caught and displayed with a retry button
- Missing fields are handled gracefully with "N/A" defaults
- Loading state prevents user interaction during fetch
- Error messages are user-friendly

## Testing

The integration includes:
- Loading state indicator
- Error state with retry functionality
- Safe field extraction with fallbacks
- Support for multiple API response formats

## Notes

- Lead details are fetched automatically when the screen loads
- The screen maintains the existing call flow and form submission logic
- All fetched data is displayed dynamically instead of hardcoded values
- The API response is normalized to camelCase for consistency with the app
- Retry button allows users to refetch data if the initial request fails
