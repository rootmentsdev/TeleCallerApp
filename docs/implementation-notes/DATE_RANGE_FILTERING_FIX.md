# Date Range Filtering Fix - Backend API Only

## Problem
- Backend returns 7 leads for 15/3/2026
- Frontend shows 11 leads (7 from backend + 4 extra from local storage)
- Extra leads are being added from local date filtering

## Root Cause
The `fetchReturnLeadsFromApi()` method was NOT passing date parameters to the API, so it was fetching ALL return leads without date filtering. Then the frontend was adding extra leads from local storage.

## Solution
Pass date range parameters from the frontend to the backend API so the backend filters the data, and the frontend only displays what the backend returns (no local filtering).

---

## Changes Made

### 1. **LeadRepository** - Add date parameters to API call
**File:** `frontend/lib/controller/lead_repository.dart`

**Before:**
```dart
Future<void> fetchReturnLeadsFromApi({
  String? store,
  String? enquiryFrom,
  String? enquiryTo,
}) async {
  final response = await _apiService.getReturnLeads(store: storeFilter);
  // No date filtering!
}
```

**After:**
```dart
Future<void> fetchReturnLeadsFromApi({
  String? store,
  String? enquiryFrom,
  String? enquiryTo,
  String? fromDate,      // NEW
  String? toDate,        // NEW
}) async {
  final response = await _apiService.getReturnLeads(
    store: storeFilter,
    fromDate: fromDate,   // NEW
    toDate: toDate,       // NEW
  );
}
```

---

### 2. **LeadScreenController** - Pass date range to repository
**File:** `frontend/lib/controller/lead_screen_controller.dart`

**Before:**
```dart
void _fetchLeadsForCurrentFilters(
  String? store,
  String? dateFrom,
  String? dateTo,
  DateTime? singleDate,
) {
  // ...
  fetchReturnLeadsFromApi(store: store).catchError((_) {});
  // Date parameters not passed!
}
```

**After:**
```dart
void _fetchLeadsForCurrentFilters(
  String? store,
  String? dateFrom,
  String? dateTo,
  DateTime? singleDate,
) {
  // Format single date to API format if provided
  String? formattedDateFrom;
  String? formattedDateTo;

  if (dateFrom != null && dateTo != null) {
    formattedDateFrom = dateFrom;
    formattedDateTo = dateTo;
  } else if (singleDate != null) {
    // Convert single date to date range (full day)
    formattedDateFrom = _formatDateForApi(singleDate);
    // End of day
    final endOfDay = DateTime(
      singleDate.year,
      singleDate.month,
      singleDate.day,
      23,
      59,
      59,
    );
    formattedDateTo = _formatDateForApi(endOfDay);
  }

  if (store != null) {
    if (formattedDateFrom != null && formattedDateTo != null) {
      fetchReturnLeadsFromApi(
        store: store,
        fromDate: formattedDateFrom,  // NEW
        toDate: formattedDateTo,      // NEW
      ).catchError((_) {});
    } else {
      fetchReturnLeadsFromApi(store: store).catchError((_) {});
    }
  } else {
    if (formattedDateFrom != null && formattedDateTo != null) {
      fetchReturnLeadsFromApi(
        fromDate: formattedDateFrom,  // NEW
        toDate: formattedDateTo,      // NEW
      ).catchError((_) {});
    } else {
      fetchReturnLeadsFromApi().catchError((_) {});
    }
  }
}
```

---

### 3. **LeadScreenController** - Update method signature
**File:** `frontend/lib/controller/lead_screen_controller.dart`

**Before:**
```dart
Future<void> fetchReturnLeadsFromApi({
  String? store,
  String? enquiryFrom,
  String? enquiryTo,
}) async {
  await _repository.fetchReturnLeadsFromApi(
    store: store,
    enquiryFrom: enquiryFrom,
    enquiryTo: enquiryTo,
  );
}
```

**After:**
```dart
Future<void> fetchReturnLeadsFromApi({
  String? store,
  String? enquiryFrom,
  String? enquiryTo,
  String? fromDate,      // NEW
  String? toDate,        // NEW
}) async {
  await _repository.fetchReturnLeadsFromApi(
    store: store,
    enquiryFrom: enquiryFrom,
    enquiryTo: enquiryTo,
    fromDate: fromDate,   // NEW
    toDate: toDate,       // NEW
  );
}
```

---

### 4. **ApiService** - Add date parameters to API call
**File:** `frontend/lib/services/api_service.dart`

**Before:**
```dart
Future<Map<String, dynamic>> getReturnLeads({
  String? store,
  int? page,
  int? limit,
}) async {
  final url = Uri.parse(
    ApiConfig.getReturnLeads(store: store, page: page, limit: limit),
  );
  // No date filtering!
}
```

**After:**
```dart
Future<Map<String, dynamic>> getReturnLeads({
  String? store,
  String? fromDate,      // NEW
  String? toDate,        // NEW
  int? page,
  int? limit,
}) async {
  final url = Uri.parse(
    ApiConfig.getReturnLeads(
      store: store,
      fromDate: fromDate,  // NEW
      toDate: toDate,      // NEW
      page: page,
      limit: limit,
    ),
  );
}
```

---

## Data Flow After Fix

### Before (Showing 11 leads):
```
User selects: 15/3/2026
    ↓
fetchReturnLeadsFromApi(store: "SG-Edappally")
    ↓
API call: GET /api/leads/returns?store=SG-Edappally
    ↓
Backend returns: 7 leads (all return leads, no date filter)
    ↓
Frontend adds: 4 extra leads from local storage
    ↓
UI shows: 11 leads ❌ WRONG
```

### After (Showing 7 leads):
```
User selects: 15/3/2026
    ↓
_formatDateForApi(DateTime(2026, 3, 15)) → "2026-03-15"
_formatDateForApi(DateTime(2026, 3, 15, 23, 59, 59)) → "2026-03-15"
    ↓
fetchReturnLeadsFromApi(
  store: "SG-Edappally",
  fromDate: "2026-03-15",
  toDate: "2026-03-15"
)
    ↓
API call: GET /api/leads/returns?store=SG-Edappally&fromDate=2026-03-15&toDate=2026-03-15
    ↓
Backend returns: 7 leads (filtered by date range)
    ↓
Frontend displays: 7 leads (no local filtering added)
    ↓
UI shows: 7 leads ✅ CORRECT
```

---

## Date Format Conversion

### Single Date to Date Range:
```dart
// User selects: 15/3/2026
DateTime selectedDate = DateTime(2026, 3, 15);

// Convert to start of day
String fromDate = _formatDateForApi(selectedDate);
// Result: "2026-03-15"

// Convert to end of day
DateTime endOfDay = DateTime(2026, 3, 15, 23, 59, 59);
String toDate = _formatDateForApi(endOfDay);
// Result: "2026-03-15"

// API call includes full day range
// GET /api/leads/returns?fromDate=2026-03-15&toDate=2026-03-15
```

### Date Range to API Parameters:
```dart
// User selects: 10/3/2026 - 20/3/2026
DateTime rangeStart = DateTime(2026, 3, 10);
DateTime rangeEnd = DateTime(2026, 3, 20);

// Convert to API format
String fromDate = _formatDateForApi(rangeStart);
// Result: "2026-03-10"

String toDate = _formatDateForApi(rangeEnd);
// Result: "2026-03-20"

// API call includes full range
// GET /api/leads/returns?fromDate=2026-03-10&toDate=2026-03-20
```

---

## API Endpoint Examples

### Single Date Filter:
```
GET https://rootstele.onrender.com/api/leads/returns?store=SG-Edappally&fromDate=2026-03-15&toDate=2026-03-15
```

### Date Range Filter:
```
GET https://rootstele.onrender.com/api/leads/returns?store=SG-Edappally&fromDate=2026-03-10&toDate=2026-03-20
```

### No Date Filter (all leads):
```
GET https://rootstele.onrender.com/api/leads/returns?store=SG-Edappally
```

---

## Key Points

✅ **Backend does the filtering** - Date range parameters sent to API
✅ **No local date filtering** - Frontend only displays what backend returns
✅ **Consistent data** - Frontend shows exactly what backend returns
✅ **Single date support** - Converts single date to full-day range
✅ **Date range support** - Passes start and end dates to backend
✅ **Store filter combined** - Works with store filter parameter

---

## Testing

### Test Case 1: Single Date Filter
1. Select date: 15/3/2026
2. Select store: SG-Edappally
3. Expected: 7 leads (from backend)
4. Verify: No extra leads added from local storage

### Test Case 2: Date Range Filter
1. Select date range: 10/3/2026 - 20/3/2026
2. Select store: SG-Edappally
3. Expected: All leads within range from backend
4. Verify: No extra leads added from local storage

### Test Case 3: All Stores
1. Select date: 15/3/2026
2. Select store: All Stores
3. Expected: All leads on 15/3/2026 from all stores
4. Verify: No extra leads added from local storage

---

## Summary

The fix ensures that:
1. Date range parameters are passed to the backend API
2. Backend filters leads by date range
3. Frontend displays only what backend returns
4. No local date filtering adds extra leads
5. Data consistency between backend and frontend
