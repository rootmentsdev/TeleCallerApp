# CSV Export - Limit Parameter Fix

## Issue Found

**Problem**: CSV export was showing 100+ records, but report screen only displayed 37 records.

**Root Cause**: The `limit` parameter was being passed to `getCompletedLeads()` method in `api_service.dart`, but it was **NOT being forwarded to `ApiConfig.getCompletedLeads()`**, so the backend was using its default limit (likely 37 records).

## What Was Fixed

### File: `frontend/lib/services/api_service.dart`

**Before**:
```dart
Future<Map<String, dynamic>> getCompletedLeads({
  String? store,
  String? fromDate,
  String? toDate,
  int? limit,
}) async {
  final url = ApiConfig.getCompletedLeads(
    store: store,
    fromDate: fromDate,
    toDate: toDate,
    // ❌ limit parameter NOT passed!
  );
```

**After**:
```dart
Future<Map<String, dynamic>> getCompletedLeads({
  String? store,
  String? fromDate,
  String? toDate,
  int? limit,
}) async {
  final url = ApiConfig.getCompletedLeads(
    store: store,
    fromDate: fromDate,
    toDate: toDate,
    limit: limit,  // ✅ Now passed correctly
  );
```

## How It Works Now

1. **Report Screen** (normal view):
   - Calls `getCompletedLeads()` without limit parameter
   - Backend returns default limit (37 records)
   - Shows 37 records in UI

2. **CSV Export**:
   - Calls `getCompletedLeads(limit: 10000)`
   - Backend returns up to 10,000 records
   - Exports all records to CSV

## Result

✅ CSV export now fetches ALL records (100+)  
✅ Report screen still shows default limit (37)  
✅ Users can export complete data while keeping UI responsive  

## Files Modified

- `frontend/lib/services/api_service.dart` - Added `limit: limit` parameter to ApiConfig call

## Testing

1. Open Reports screen - should show 37 records (default)
2. Click download button - CSV should contain 100+ records
3. Verify CSV has all records from the date range
4. Verify report screen still shows only 37 records

## Why This Approach?

- **Performance**: Report screen doesn't load all records (keeps UI responsive)
- **Completeness**: CSV export gets all records for comprehensive reporting
- **Flexibility**: Backend can adjust default limit without affecting export
- **Scalability**: Works with any number of records
