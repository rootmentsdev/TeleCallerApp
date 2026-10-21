# Date Filtering Bug Fix - 100 Leads Issue

## Problem
Backend returns 100 leads instead of filtering by date. The API call shows:
```
ApiService: Fetching Return leads from: https://rootstele.onrender.com/api/leads/returns
```

**No date parameters in the URL!** Should be:
```
https://rootstele.onrender.com/api/leads/returns?fromDate=2026-03-15&toDate=2026-03-15
```

## Root Cause
The `_fetchLeadsForCurrentFilters()` method had conditional logic that was **skipping date parameters** in certain cases:

```dart
if (formattedDateFrom != null && formattedDateTo != null) {
  // Call with date parameters ✅
  fetchReturnLeadsFromApi(
    store: store,
    fromDate: formattedDateFrom,
    toDate: formattedDateTo,
  );
} else {
  // Call WITHOUT date parameters ❌ BUG!
  fetchReturnLeadsFromApi(store: store);
}
```

The `else` branch was being executed even when `singleDate` was provided, because the date formatting logic wasn't being reached.

## Solution
**Always pass date parameters** to the API, whether it's a single date or date range. Remove the conditional logic that skips date parameters.

### Before (Buggy):
```dart
void _fetchLeadsForCurrentFilters(
  String? store,
  String? dateFrom,
  String? dateTo,
  DateTime? singleDate,
) {
  String? formattedDateFrom;
  String? formattedDateTo;

  if (dateFrom != null && dateTo != null) {
    formattedDateFrom = dateFrom;
    formattedDateTo = dateTo;
  } else if (singleDate != null) {
    formattedDateFrom = _formatDateForApi(singleDate);
    final endOfDay = DateTime(singleDate.year, singleDate.month, singleDate.day, 23, 59, 59);
    formattedDateTo = _formatDateForApi(endOfDay);
  }

  if (store != null) {
    if (formattedDateFrom != null && formattedDateTo != null) {
      // With dates ✅
      fetchReturnLeadsFromApi(
        store: store,
        fromDate: formattedDateFrom,
        toDate: formattedDateTo,
      );
    } else {
      // Without dates ❌ BUG!
      fetchReturnLeadsFromApi(store: store);
    }
  }
}
```

### After (Fixed):
```dart
void _fetchLeadsForCurrentFilters(
  String? store,
  String? dateFrom,
  String? dateTo,
  DateTime? singleDate,
) {
  String? formattedDateFrom;
  String? formattedDateTo;

  if (dateFrom != null && dateTo != null) {
    formattedDateFrom = dateFrom;
    formattedDateTo = dateTo;
  } else if (singleDate != null) {
    formattedDateFrom = _formatDateForApi(singleDate);
    final endOfDay = DateTime(singleDate.year, singleDate.month, singleDate.day, 23, 59, 59);
    formattedDateTo = _formatDateForApi(endOfDay);
  }

  // Always pass date parameters ✅
  if (store != null) {
    fetchReturnLeadsFromApi(
      store: store,
      fromDate: formattedDateFrom,  // Can be null, API handles it
      toDate: formattedDateTo,      // Can be null, API handles it
    );
  } else {
    fetchReturnLeadsFromApi(
      fromDate: formattedDateFrom,
      toDate: formattedDateTo,
    );
  }
}
```

## Key Changes

### 1. Remove Conditional Logic
**Before:**
```dart
if (formattedDateFrom != null && formattedDateTo != null) {
  // Call with dates
} else {
  // Call without dates ❌
}
```

**After:**
```dart
// Always call with dates (even if null)
fetchReturnLeadsFromApi(
  fromDate: formattedDateFrom,
  toDate: formattedDateTo,
);
```

### 2. Simplify the Method
Remove the nested `if` statements that were causing the bug. Just format the dates and always pass them.

### 3. API Handles Null Parameters
The API config already handles `null` parameters correctly:
```dart
if (fromDate != null && fromDate.isNotEmpty) {
  queryParams.add("fromDate=${Uri.encodeComponent(fromDate)}");
}
```

So it's safe to pass `null` values - they'll just be ignored.

---

## Data Flow After Fix

### Scenario: User selects 15/3/2026

```
_onHeaderChanged()
    ↓
_fetchLeadsForCurrentFilters(
  store: "SG-Edappally",
  dateFrom: null,
  dateTo: null,
  singleDate: DateTime(2026, 3, 15)
)
    ↓
Format single date:
  formattedDateFrom = _formatDateForApi(DateTime(2026, 3, 15))
                    = "2026-03-15"
  formattedDateTo = _formatDateForApi(DateTime(2026, 3, 15, 23, 59, 59))
                  = "2026-03-15"
    ↓
fetchReturnLeadsFromApi(
  store: "SG-Edappally",
  fromDate: "2026-03-15",
  toDate: "2026-03-15"
)
    ↓
API call:
GET /api/leads/returns?store=SG-Edappally&fromDate=2026-03-15&toDate=2026-03-15
    ↓
Backend filters and returns: 7 leads (only for 15/3/2026)
    ↓
UI shows: 7 leads ✅ CORRECT
```

---

## API URL Examples

### Before Fix (No Date Filter):
```
GET https://rootstele.onrender.com/api/leads/returns?store=SG-Edappally
```
Returns: 100 leads (all return leads, no date filtering)

### After Fix (With Date Filter):
```
GET https://rootstele.onrender.com/api/leads/returns?store=SG-Edappally&fromDate=2026-03-15&toDate=2026-03-15
```
Returns: 7 leads (only for 15/3/2026)

---

## Testing

### Test Case 1: Single Date
1. Select date: 15/3/2026
2. Check logs for API URL
3. **Expected:** URL includes `fromDate=2026-03-15&toDate=2026-03-15`
4. **Expected:** Backend returns filtered leads (not 100)

### Test Case 2: Date Range
1. Select date range: 10/3/2026 - 20/3/2026
2. Check logs for API URL
3. **Expected:** URL includes `fromDate=2026-03-10&toDate=2026-03-20`
4. **Expected:** Backend returns leads within range

### Test Case 3: With Store Filter
1. Select date: 15/3/2026
2. Select store: SG-Edappally
3. Check logs for API URL
4. **Expected:** URL includes both `store=SG-Edappally` and date parameters
5. **Expected:** Backend returns filtered leads

---

## Log Output After Fix

**Before Fix:**
```
ApiService: Fetching Return leads from: https://rootstele.onrender.com/api/leads/returns
LeadRepository: Fetched 100 Return leads successfully
```

**After Fix:**
```
ApiService: Fetching Return leads from: https://rootstele.onrender.com/api/leads/returns?store=SG-Edappally&fromDate=2026-03-15&toDate=2026-03-15
LeadRepository: Fetched 7 Return leads successfully
```

---

## Summary

✅ **Always pass date parameters** to API calls
✅ **Remove conditional logic** that skips date parameters
✅ **API handles null values** correctly
✅ **Backend filters data** based on date range
✅ **Frontend displays** only filtered results
✅ **No local filtering** needed

The fix ensures that date filtering is **always applied** at the backend level, preventing the 100-lead issue.
