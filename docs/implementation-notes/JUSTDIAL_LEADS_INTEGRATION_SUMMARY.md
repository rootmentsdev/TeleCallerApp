# JustDial Leads API Integration Summary

## Overview
Successfully integrated the `/leads/justdial` endpoint to fetch JustDial leads from the backend and display them on the JustDial leads screen.

## Changes Made

### 1. API Configuration (`frontend/lib/utils/api_config.dart`)
- Added `getJustDialLeads()` static method to construct the JustDial endpoint URL
- Supports optional parameters: `store`, `fromDate`, `toDate`, `page`, `limit`
- Endpoint: `{baseUrl}/api/leads/justdial`

### 2. API Service (`frontend/lib/services/api_service.dart`)
- Added `getJustDialLeads()` method to fetch JustDial leads from the backend
- Handles authentication headers and error responses
- Parses response data and returns normalized format
- Includes proper error handling and Firebase Crashlytics logging

### 3. Lead Repository (`frontend/lib/controller/lead_repository.dart`)
- Added `fetchJustDialLeadsFromApi()` method to:
  - Fetch JustDial leads from the API
  - Parse API response data to LeadModel objects
  - Remove existing JustDial leads to avoid duplicates
  - Categorize leads with `LeadConstants.categoryJustDial`
  - Persist changes to local storage
  - Notify listeners of updates

### 4. Lead Screen Controller (`frontend/lib/controller/lead_screen_controller.dart`)
- Added `fetchJustDialLeadsFromApi()` method to:
  - Call the repository's fetch method
  - Handle errors with Firebase Crashlytics
  - Notify UI listeners of changes

### 5. Lead Screen UI (`frontend/lib/view/lead_screen/lead_screen.dart`)
- Added `_fetchJustDialLeads()` method to:
  - Format date parameters for API calls
  - Handle store filtering
  - Manage loading state
  - Display error messages if fetch fails
- Updated `initState()` to fetch JustDial leads on screen initialization
- Updated `didChangeDependencies()` to refetch JustDial leads when dependencies change

## Features

✅ Fetches JustDial leads from `/leads/justdial` endpoint
✅ Supports date range filtering
✅ Supports store filtering
✅ Handles pagination (page, limit parameters)
✅ Proper error handling and logging
✅ Loading state management
✅ Automatic duplicate prevention
✅ Local storage persistence
✅ UI updates on data changes

## Data Flow

1. User navigates to JustDial tab on Lead Screen
2. `_fetchJustDialLeads()` is called with current filters (store, date range)
3. Request is sent to `/leads/justdial` endpoint via `ApiService`
4. Response is parsed and stored in `LeadRepository`
5. Leads are categorized as "Just Dial" and persisted locally
6. UI is updated with new leads
7. User can view and interact with JustDial leads

## API Endpoint Details

**Endpoint:** `GET /leads/justdial`

**Query Parameters:**
- `store` (optional): Filter by store location
- `fromDate` (optional): Start date for filtering (ISO 8601 format)
- `toDate` (optional): End date for filtering (ISO 8601 format)
- `page` (optional): Page number for pagination
- `limit` (optional): Number of leads per page

**Response Format:**
```json
{
  "data": [
    {
      "_id": "lead_id",
      "lead_name": "Customer Name",
      "phone_number": "9876543210",
      "store": "Brand - Location",
      "call_status": "Not Called",
      "lead_status": "New Lead",
      "created_at": "2026-04-18T10:30:00Z",
      ...
    }
  ]
}
```

## Testing

The integration includes:
- Test JustDial leads in debug mode (via `_addTestJustDialLeadsIfNeeded()`)
- Proper error handling for network failures
- Loading state indicators
- User-friendly error messages

## Notes

- JustDial leads are fetched automatically when the screen loads
- Leads are refetched when date range or store filter changes
- Existing JustDial leads are removed before fetching new ones to prevent duplicates
- All leads are persisted to local storage for offline access
- The category for JustDial leads is set to `LeadConstants.categoryJustDial` ("Just Dial")
