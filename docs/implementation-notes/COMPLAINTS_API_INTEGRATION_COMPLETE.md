# Complaints API Integration - Complete

## Overview
Integrated backend API to fetch complaints data and display them dynamically on the Complaints screen.

## Changes Made

### 1. API Service (`frontend/lib/services/api_service.dart`)

#### Added `getComplaints()` Method
```dart
Future<Map<String, dynamic>> getComplaints({
  String? store,
  String? dateFrom,
  String? dateTo,
  int? page,
  int? limit,
}) async
```

**Features:**
- Fetches complaints from backend API
- Supports filtering by store, date range
- Supports pagination (page, limit)
- Handles authentication headers
- Error handling with Firebase Crashlytics
- Supports both Map and List response formats

#### Added `getComplaintById()` Method
```dart
Future<Map<String, dynamic>> getComplaintById(String id) async
```

**Features:**
- Fetches single complaint by ID
- Handles 404 (not found) errors
- Returns parsed complaint data

### 2. Complaints Controller (`frontend/lib/controller/complaints_controller.dart`)

**Features:**
- Manages complaint data state
- Fetches complaints from API
- Parses complaint data
- Handles loading and error states
- Formats dates for display
- Provides getters for UI

**Key Methods:**
- `fetchComplaints()` - Fetch complaints from API
- `getComplaintById()` - Fetch single complaint
- `refresh()` - Refresh complaint list
- `clear()` - Clear all complaints

**State Management:**
- `_complaints` - List of complaints
- `_isLoading` - Loading state
- `_error` - Error message
- `_totalComplaints` - Total count

### 3. Complaints Screen (`frontend/lib/view/complaints_screen/complaints_screen.dart`)

**Updates:**
- Integrated ComplaintsController
- Replaced hardcoded data with API data
- Added loading state UI
- Added error state UI
- Added empty state UI
- Uses ListenableBuilder for reactive updates

**Features:**
- Fetches complaints on screen load
- Shows loading indicator while fetching
- Shows error message if fetch fails
- Shows empty state if no complaints
- Displays complaint count dynamically
- All existing features (expand/collapse, share, double-tap) work with API data

## API Endpoints

### Get Complaints
```
GET /api/pages/complaints
Query Parameters:
  - store: string (optional)
  - dateFrom: string (optional)
  - dateTo: string (optional)
  - page: number (optional)
  - limit: number (optional)

Response:
{
  "complaints": [
    {
      "_id": "string",
      "name": "string",
      "phone": "string",
      "store": "string",
      "leadType": "string",
      "subCategory": "string",
      "remarks": "string",
      "callStatus": "string",
      "leadStatus": "string",
      "createdAt": "ISO8601",
      "functionDate": "ISO8601",
      ...
    }
  ],
  "pagination": { ... }
}
```

### Get Single Complaint
```
GET /api/pages/complaints/{id}

Response:
{
  "_id": "string",
  "name": "string",
  "phone": "string",
  ...
}
```

## Data Mapping

Backend Response → Parsed Complaint Object:
```dart
{
  'id': complaint._id,
  'name': complaint.name,
  'phone': complaint.phone,
  'store': complaint.store,
  'type': complaint.leadType,
  'date': formatted_date,
  'functionDate': complaint.functionDate,
  'subCategory': complaint.subCategory,
  'remarks': complaint.remarks,
  'callStatus': complaint.callStatus,
  'leadStatus': complaint.leadStatus,
  'isExpanded': false,
  'rawData': complaint (full object)
}
```

## Features

✅ **Dynamic Data**: Complaints fetched from backend API
✅ **Loading State**: Shows spinner while fetching
✅ **Error Handling**: Displays error message with retry button
✅ **Empty State**: Shows message when no complaints
✅ **Pagination**: Supports page and limit parameters
✅ **Filtering**: Filter by store and date range
✅ **Date Formatting**: Converts ISO dates to readable format
✅ **Expand/Collapse**: Works with API data
✅ **Share**: Share complaint details via native share
✅ **Double-Tap**: Close expanded cards with double-tap

## Usage

### Fetch All Complaints
```dart
await _complaintsController.fetchComplaints();
```

### Fetch with Filters
```dart
await _complaintsController.fetchComplaints(
  store: 'Zorucci Edappally',
  dateFrom: '2026-01-01',
  dateTo: '2026-01-31',
  page: 1,
  limit: 50,
);
```

### Fetch Single Complaint
```dart
final complaint = await _complaintsController.getComplaintById(complaintId);
```

### Refresh Data
```dart
await _complaintsController.refresh();
```

## Error Handling

- **401 Unauthorized**: Shows "Authentication failed" message
- **404 Not Found**: Shows "Complaint not found" message
- **Network Error**: Shows error message with retry button
- **Parse Error**: Shows "Unexpected response format" message

## Testing

1. Open Complaints screen
2. Verify loading indicator shows
3. Verify complaints load from API
4. Verify complaint count displays
5. Verify expand/collapse works
6. Verify share button works
7. Verify double-tap closes expanded card
8. Test with different filters
9. Test error scenarios (disconnect network)

## Next Steps

1. Implement store filter dropdown
2. Implement date range picker
3. Implement pagination (load more)
4. Add complaint status management
5. Add complaint update functionality
6. Add complaint delete functionality
7. Add search functionality
8. Add sorting options

## Files Modified

1. `frontend/lib/services/api_service.dart` - Added getComplaints() and getComplaintById()
2. `frontend/lib/controller/complaints_controller.dart` - Created new controller
3. `frontend/lib/view/complaints_screen/complaints_screen.dart` - Integrated API

## Dependencies

- `share_plus` - For sharing complaint details
- `firebase_crashlytics` - For error tracking
- `http` - For API calls
- `provider` - For state management (via ListenableBuilder)
