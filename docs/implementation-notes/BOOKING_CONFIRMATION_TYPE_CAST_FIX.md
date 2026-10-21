# Booking Confirmation API - Type Cast Error Fix

## Error Fixed
```
type '_Map<String, dynamic>' is not a subtype of type 'List<dynamic>?' in type cast
```

## Root Cause
The API response structure has `data` as a **Map** containing a `leads` array, but the code was trying to cast `data` directly as a **List**.

### API Response Structure
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "leads": [],        // ← Array is nested inside data map
    "total": 0,
    "page": 1,
    "limit": 100
  }
}
```

### Wrong Code
```dart
// ❌ WRONG: Trying to cast Map as List
final data = response['data'] as List<dynamic>? ?? [];
```

### Correct Code
```dart
// ✅ CORRECT: Extract leads array from data map
List<dynamic> data = [];
if (response.containsKey('data')) {
  final dataValue = response['data'];
  if (dataValue is Map<String, dynamic>) {
    // Extract leads array from data map
    final leads = dataValue['leads'];
    if (leads is List<dynamic>) {
      data = leads;
    }
  } else if (dataValue is List<dynamic>) {
    // If data is directly a list (fallback)
    data = dataValue;
  }
}
```

## Fix Applied

### File: `frontend/lib/controller/lead_repository.dart`

**Method**: `fetchBookingConfirmationLeadsFromApi()`

**Changes**:
1. Removed direct type casting of `response['data']` as List
2. Added proper null-safe extraction of nested `leads` array
3. Added fallback handling if `data` is directly a list
4. Improved type checking with `is` operator

## Implementation Details

```dart
Future<void> fetchBookingConfirmationLeadsFromApi({
  String? store,
  String? fromDate,
  String? toDate,
}) async {
  try {
    print('LeadRepository: Fetching booking confirmation leads (store=$store)');

    final response = await _apiService.getBookingConfirmationLeads(
      store: store,
      fromDate: fromDate,
      toDate: toDate,
      page: 1,
      limit: 100,
    );

    // ✅ CORRECT: Handle nested data structure
    List<dynamic> data = [];
    if (response.containsKey('data')) {
      final dataValue = response['data'];
      if (dataValue is Map<String, dynamic>) {
        // Extract leads array from data map
        final leads = dataValue['leads'];
        if (leads is List<dynamic>) {
          data = leads;
        }
      } else if (dataValue is List<dynamic>) {
        // If data is directly a list
        data = dataValue;
      }
    }

    print('LeadRepository: Fetched ${data.length} booking confirmation leads successfully');

    // Store booking confirmation data for later use
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        final id = item['id']?.toString() ?? item['_id']?.toString() ?? '';
        if (id.isNotEmpty) {
          _bookingConfirmationData[id] = item;
        }
      }
    }

    notifyListeners();
  } catch (e, s) {
    print('LeadRepository: Error fetching booking confirmation leads: $e');
    FirebaseCrashlytics.instance.recordError(
      e,
      s,
      reason: 'fetchBookingConfirmationLeadsFromApi failed',
    );
    rethrow;
  }
}
```

## Response Handling

### Before (Broken)
```
API Response: {"success": true, "data": {"leads": [], ...}}
  ↓
Cast response['data'] as List  ❌ ERROR
  ↓
Type mismatch: Map cannot be cast to List
```

### After (Fixed)
```
API Response: {"success": true, "data": {"leads": [], ...}}
  ↓
Check if response['data'] is Map  ✅
  ↓
Extract response['data']['leads']  ✅
  ↓
Cast leads as List  ✅
  ↓
Process leads array  ✅
```

## Compilation Status

✅ **No errors** in `frontend/lib/controller/lead_repository.dart`

## Expected Behavior After Fix

### Logs
```
LeadRepository: Fetching booking confirmation leads (store=null)
ApiService: Fetching booking confirmation leads
ApiService: URL => https://rootstele.onrender.com/api/leads/booking-confirmation?...
ApiService: Booking confirmation leads response status: 200
ApiService: Booking confirmation leads response body: {"success":true,"data":{"leads":[],...}}
LeadRepository: Fetched 0 booking confirmation leads successfully  ✅ NO ERROR
```

### Result
- No type cast error
- Booking confirmation leads properly extracted from API response
- Data stored in `_bookingConfirmationData` cache
- UI updates with booking confirmation leads (if any exist)

## Files Modified

- `frontend/lib/controller/lead_repository.dart` (1 method updated)

## Related API Response Structures

### Booking Confirmation Response
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "leads": [
      {
        "id": "69b981944d45297cf2616371",
        "customerName": "KRISHNA KUMAR",
        "phone": "9946965083",
        "store": "SG-Perinthalmanna",
        "bookingDate": "2026-01-17T12:29:05.000Z",
        "totalAmount": 7500,
        "leadStatus": "new"
      }
    ],
    "total": 1,
    "page": 1,
    "limit": 100
  }
}
```

## Testing

To verify the fix:
1. Open Lead Screen
2. Navigate to Booking Confirmation tab
3. Check logs for "Fetched X booking confirmation leads successfully"
4. No type cast errors should appear
5. Booking confirmation leads should display (if any exist in the date range)

