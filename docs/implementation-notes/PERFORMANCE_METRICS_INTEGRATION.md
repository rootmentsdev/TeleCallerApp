# Performance Metrics Integration - Implementation Complete

## Overview
Integrated the `/leads/performance` endpoint to fetch total call count and today's calls in the home screen dashboard.

## Changes Made

### 1. API Service Enhancement
**File**: `frontend/lib/services/api_service.dart`

Added new method `getPerformanceMetrics()`:
```dart
Future<Map<String, dynamic>> getPerformanceMetrics({
  DateTime? fromDate,
  DateTime? toDate,
}) async
```

**Features**:
- Accepts optional date range parameters (fromDate, toDate)
- Formats dates as YYYY-MM-DD for API compatibility
- Handles both wrapped and unwrapped API responses
- Includes error handling and Firebase Crashlytics logging
- 15-second timeout for network requests

**Endpoint**: `GET /leads/performance?fromDate=YYYY-MM-DD&toDate=YYYY-MM-DD`

### 2. Performance Controller
**File**: `frontend/lib/controller/performance_controller.dart` (NEW)

Created new controller to manage performance metrics:
- `totalCallCount`: Total number of calls
- `callsToday`: Number of calls made today
- `isLoading`: Loading state
- `error`: Error message if any

**Key Methods**:
- `fetchPerformanceMetrics(fromDate, toDate)`: Fetch metrics for date range
- `fetchTodayMetrics()`: Convenience method to fetch today's metrics
- `reset()`: Clear metrics and error state

### 3. Home Screen Integration
**File**: `frontend/lib/view/home_screen/home_screen.dart`

**Changes**:
- Added import for `PerformanceController`
- Initialize `_performanceController` in `initState()`
- Call `_fetchPerformanceMetrics()` on app load
- Dispose controller in `dispose()`
- Updated `build()` method to use `Consumer4` (added PerformanceController)
- Dashboard now displays backend metrics if available, falls back to local calculation
- Extracted local calculation logic to `_calculateCallsTodayCount()` method

**Data Flow**:
```
Home Screen Load
    ↓
_fetchPerformanceMetrics() called
    ↓
PerformanceController.fetchTodayMetrics()
    ↓
ApiService.getPerformanceMetrics(fromDate, toDate)
    ↓
GET /leads/performance?fromDate=YYYY-MM-DD&toDate=YYYY-MM-DD
    ↓
Backend returns: { totalCallCount: X, callsToday: Y }
    ↓
Dashboard displays metrics
```

## API Response Format

Expected response from `/leads/performance`:
```json
{
  "totalCallCount": 150,
  "callsToday": 12,
  "completedCalls": 10,
  "missedCalls": 2
}
```

Or wrapped format:
```json
{
  "data": {
    "totalCallCount": 150,
    "callsToday": 12,
    "completedCalls": 10,
    "missedCalls": 2
  }
}
```

## Fallback Behavior

If the backend endpoint fails or returns 0 values:
- Dashboard falls back to local calculation
- Counts leads with `callDuration > 0` and `updatedAt` today
- Includes complaint calls in the count
- Filters by selected store if applicable

## Usage in Home Screen

The dashboard now displays:
- **Calls Today**: From backend `/leads/performance` endpoint (or local fallback)
- **Follow Ups**: Total follow-up leads from repository

## Testing

1. **Verify API Call**:
   - Check logs for: `PerformanceController: Fetching metrics...`
   - Check logs for: `PerformanceController: Response received: {...}`

2. **Verify Dashboard Update**:
   - Home screen loads
   - Dashboard shows "Calls Today" and "Follow Ups" cards
   - Values update from backend

3. **Test Fallback**:
   - Disable network or API endpoint
   - Dashboard should still show local calculation

## Files Modified
- `frontend/lib/services/api_service.dart` - Added getPerformanceMetrics()
- `frontend/lib/view/home_screen/home_screen.dart` - Integrated performance controller
- `frontend/lib/controller/performance_controller.dart` - NEW file

## Notes
- Performance metrics are fetched on app load (home screen initialization)
- Metrics are cached in the controller and updated when needed
- The implementation supports both wrapped and unwrapped API responses
- Date parameters are formatted as YYYY-MM-DD for API compatibility
- Includes comprehensive error handling and logging
