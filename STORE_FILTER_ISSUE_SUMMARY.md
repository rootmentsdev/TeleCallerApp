# Store Filter Issue - Executive Summary

## The Problem
When you select "Dapper Squad - Edappally" from the store filter dropdown, the app displays leads from:
- ✅ Dapper Squad - Edappally (DS-Edappally) — **CORRECT**
- ❌ Zorucci - Edappally (Z-Edappally) — **WRONG**
- ❌ Suitor Guy - Edappally (SG-Edappally) — **WRONG**

**Expected:** Only Dapper Squad - Edappally leads
**Actual:** All brands at Edappally location

---

## Why This Happens

### Frontend (✅ Working Correctly)

The frontend does everything right:

1. **Stores the selection correctly**
   ```dart
   Store(brand: 'DS', location: 'Edappally', normalizedName: 'DS-Edappally')
   ```

2. **Passes the correct parameter to the API**
   ```
   GET /api/leads?store=DS-Edappally
   ```

3. **Encodes the URL properly**
   ```
   store=DS-Edappally  (URL encoded)
   ```

### Backend (❌ Not Working Correctly)

The backend is **NOT filtering by brand**. It's likely doing one of these:

**Option 1: Ignoring the store parameter**
```sql
SELECT * FROM leads
-- Returns ALL leads, ignoring the store filter
```

**Option 2: Filtering only by location (MOST LIKELY)**
```sql
SELECT * FROM leads
WHERE location = 'Edappally'
-- Extracts 'Edappally' from 'DS-Edappally'
-- Returns all brands at this location: SG, Z, DS
```

**Option 3: No data for DS-Edappally**
```sql
SELECT * FROM leads
WHERE store = 'DS-Edappally'
-- Returns 0 results (no DS data in DB)
-- Fallback: Returns all Edappally locations
```

---

## What Should Happen

The backend should:

1. **Parse the store parameter**
   ```
   Input: 'DS-Edappally'
   Extract: brand = 'DS', location = 'Edappally'
   ```

2. **Query with BOTH filters**
   ```sql
   SELECT * FROM leads
   WHERE brand = 'DS' AND location = 'Edappally'
   ```

3. **Return only matching leads**
   ```json
   {
     "leads": [
       { "id": "3", "name": "Bob", "brand": "DS", "location": "Edappally" }
     ]
   }
   ```

---

## Code Evidence

### Frontend Correctly Passes Filter

**File: `lead_repository.dart` (Line 1490-1493)**
```dart
Future<void> fetchAllLeadsFromApi({
  String? store,  // Receives: 'DS-Edappally'
  ...
}) {
  final storeFilter = (store == null || store == 'All Stores') ? null : store;
  final response = await _apiService.getAllLeads(
    store: storeFilter,  // ✅ Passes 'DS-Edappally' correctly
    page: page,
  );
}
```

**File: `api_config.dart` (Line 29-50)**
```dart
static String getAllLeads({
  String? store,  // Receives: 'DS-Edappally'
  ...
}) {
  String url = "$leadsEndpoint/leads";
  List<String> queryParams = [];
  
  if (store != null && store.isNotEmpty) {
    queryParams.add("store=${Uri.encodeComponent(store)}");
    // ✅ Adds: "store=DS-Edappally"
  }
  
  if (queryParams.isNotEmpty) {
    url += "?${queryParams.join('&')}";
  }
  return url;  // ✅ Returns: /api/leads?store=DS-Edappally
}
```

**Result:** Frontend sends `GET /api/leads?store=DS-Edappally` ✅

---

## How to Verify

### 1. Check Backend Logs
When you filter by "Dapper Squad - Edappally", check if the backend receives:
```
store=DS-Edappally
```

### 2. Test Backend Directly
Make a direct API call:
```bash
curl "https://rootstele-imrn.onrender.com/api/leads?store=DS-Edappally"
```

Check the response:
- ✅ **Correct:** Returns only DS-Edappally leads
- ❌ **Wrong:** Returns SG-Edappally, Z-Edappally, and DS-Edappally leads

### 3. Check Backend Query
Verify the backend is using:
```sql
-- ✅ CORRECT
WHERE brand = 'DS' AND location = 'Edappally'

-- ❌ WRONG
WHERE location = 'Edappally'
```

---

## Backend Fix Required

The backend needs to:

1. **Parse the store parameter** to extract brand and location
2. **Filter by BOTH brand AND location** in the database query
3. **Return only matching leads**

### Example Backend Fix (Python/Node.js)

```python
# Backend receives: store=DS-Edappally
store_param = request.args.get('store')

if store_param and store_param != 'All Stores':
    # Parse: 'DS-Edappally' → brand='DS', location='Edappally'
    parts = store_param.split('-', 1)
    brand = parts[0]
    location = parts[1] if len(parts) > 1 else None
    
    # Query with BOTH filters
    leads = db.leads.find({
        'brand': brand,
        'location': location
    })
else:
    # No filter - return all
    leads = db.leads.find({})

return leads
```

---

## Summary Table

| Aspect | Frontend | Backend | Status |
|--------|----------|---------|--------|
| **Receives store parameter** | N/A | ✅ Receives "DS-Edappally" | ✅ |
| **Parses brand from parameter** | ✅ Done | ❌ Not done | ❌ |
| **Parses location from parameter** | ✅ Done | ❌ Likely not done | ❌ |
| **Filters by brand** | ✅ Yes | ❌ No | ❌ |
| **Filters by location** | ✅ Yes | ✅ Yes (but only this) | ⚠️ |
| **Returns correct results** | N/A | ❌ Returns all brands | ❌ |

---

## Action Items

1. **Investigate Backend**: Check backend logs and query logic
2. **Fix Backend**: Update backend to parse and filter by both brand and location
3. **Test**: Verify the fix works by filtering by each store
4. **Verify Frontend**: Confirm frontend displays only filtered results

---

## Files Involved

### Frontend Files
- `lib/controller/header_controller.dart` — Store selection
- `lib/controller/lead_repository.dart` — API calls
- `lib/services/api_service.dart` — HTTP requests
- `lib/utils/api_config.dart` — URL construction

### Backend Files
- API endpoint: `/api/leads`
- Query logic: Should filter by brand AND location
- Response: Should return only matching leads

---

## Conclusion

**The frontend is working correctly.** It's passing the correct store parameter (`DS-Edappally`) to the backend. The issue is in the backend, which is not properly parsing and filtering by the brand prefix. The backend needs to be updated to:

1. Parse the store parameter into brand and location
2. Filter the database query by BOTH brand AND location
3. Return only the matching leads

Once the backend is fixed, the store filtering will work correctly across all screens.
