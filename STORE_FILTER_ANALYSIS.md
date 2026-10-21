# Store Filter Issue Analysis: Why Multiple Stores Are Shown

## Problem Statement
When filtering by "Dapper Squad - Edappally", the app shows results from:
- Dapper Squad - Edappally (DS-Edappally)
- Zorucci - Edappally (Z-Edappally)
- Suitor Guy - Edappally (SG-Edappally)

Instead of showing only Dapper Squad - Edappally results.

---

## Root Cause Analysis

### 1. **Frontend Passes Correct Filter to Backend**

The frontend correctly passes the store filter to the backend:

**Flow:**
```
User selects "Dapper Squad - Edappally" in dropdown
    ↓
HeaderController.setSelectedStore() stores: Store(brand: 'DS', location: 'Edappally', normalizedName: 'DS-Edappally')
    ↓
Lead Screen calls: fetchAllLeadsFromApi(store: 'DS-Edappally')
    ↓
API Service builds URL: /api/leads?store=DS-Edappally
    ↓
Backend receives: store=DS-Edappally
```

**Code Evidence (lead_repository.dart, line 1490-1493):**
```dart
final storeFilter = (store == null || store == 'All Stores') ? null : store;
final response = await _apiService.getAllLeads(
  store: storeFilter,  // Passes 'DS-Edappally' correctly
  page: page,
```

**Code Evidence (api_config.dart, line 29-50):**
```dart
if (store != null && store.isNotEmpty) {
  queryParams.add("store=${Uri.encodeComponent(store)}");  // Encodes 'DS-Edappally'
}
```

### 2. **The Issue is in the Backend**

The backend is NOT filtering correctly by the `store` parameter. Instead, it appears to be:

**Hypothesis 1: Backend ignores the store parameter**
- Backend returns ALL leads with location "Edappally" regardless of brand
- This would explain why SG-Edappally, Z-Edappally, and DS-Edappally all appear

**Hypothesis 2: Backend filters only by location, not by brand**
- Backend extracts "Edappally" from "DS-Edappally"
- Backend queries: `WHERE location = 'Edappally'` (ignoring the brand prefix)
- This returns all brands at that location

**Hypothesis 3: Backend has incomplete store data**
- Backend doesn't have DS-Edappally in its database yet
- Backend returns similar locations as fallback

---

## What the Frontend is Doing Correctly

### ✅ Correct Store Selection
```dart
// header_controller.dart - Store is correctly defined
Store(brand: 'DS', location: 'Edappally', normalizedName: 'DS-Edappally')
```

### ✅ Correct API Parameter Passing
```dart
// lead_repository.dart - Store filter is passed as-is
final storeFilter = (store == null || store == 'All Stores') ? null : store;
final response = await _apiService.getAllLeads(store: storeFilter);
```

### ✅ Correct URL Encoding
```dart
// api_config.dart - Store parameter is properly URL encoded
queryParams.add("store=${Uri.encodeComponent(store)}");
// Result: store=DS-Edappally (or store=SG-Edappally, etc.)
```

### ✅ Correct Local Filtering (Fallback)
```dart
// lead_repository.dart - Local filtering as fallback
bool matchesStore(LeadModel lead, String store) {
  final filter = _extractBrandAndLocation(store);  // Extracts brand and location
  // Checks both brand AND location match
  if (!_brandsMatch(filter['brand'], leadBrand)) return false;
  // Compares locations
  return normalizedLead == normalizedFilter || ...
}
```

---

## What the Backend Should Be Doing

The backend should:

1. **Parse the store parameter** (e.g., "DS-Edappally")
2. **Extract brand and location** (brand="DS", location="Edappally")
3. **Query with both filters**:
   ```sql
   SELECT * FROM leads 
   WHERE brand = 'DS' AND location = 'Edappally'
   ```

4. **NOT just filter by location**:
   ```sql
   -- ❌ WRONG - This is what's happening
   SELECT * FROM leads 
   WHERE location = 'Edappally'  -- Returns all brands at this location
   ```

---

## Evidence from Frontend Code

### API Service Call (api_service.dart)
```dart
Future<Map<String, dynamic>> getAllLeads({
  String? store,  // Receives 'DS-Edappally'
  int? page,
  ...
}) async {
  final url = ApiConfig.getAllLeads(
    store: store,  // Passes 'DS-Edappally' to URL builder
    page: page,
    ...
  );
  // Makes HTTP request with store parameter
}
```

### URL Construction (api_config.dart)
```dart
static String getAllLeads({
  String? store,
  int? page,
  ...
}) {
  String url = "$leadsEndpoint/leads";
  List<String> queryParams = [];
  
  if (store != null && store.isNotEmpty) {
    queryParams.add("store=${Uri.encodeComponent(store)}");
  }
  // Result: /api/leads?store=DS-Edappally
}
```

---

## Summary

| Component | Status | What It Does |
|-----------|--------|-------------|
| **Frontend Store Selection** | ✅ Correct | Selects "DS-Edappally" correctly |
| **Frontend API Parameter** | ✅ Correct | Passes "DS-Edappally" to backend |
| **Frontend URL Encoding** | ✅ Correct | Encodes as `store=DS-Edappally` |
| **Frontend Local Filtering** | ✅ Correct | Has fallback logic to filter by brand+location |
| **Backend Store Parsing** | ❌ **ISSUE** | Backend likely ignores brand prefix |
| **Backend Query Filter** | ❌ **ISSUE** | Backend filters only by location, not brand |

---

## Recommended Backend Fix

The backend should:

1. **Parse the store parameter** to extract brand and location
2. **Query with both brand AND location** filters
3. **Return only leads matching both criteria**

Example backend logic:
```python
# Backend (Python/Node.js example)
store_param = request.args.get('store')  # Gets 'DS-Edappally'

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
```

---

## Next Steps

1. **Check Backend Logs**: Verify what store parameter the backend is receiving
2. **Check Backend Query**: Verify the backend is filtering by brand AND location
3. **Test Backend Directly**: Call the API with `?store=DS-Edappally` and check the response
4. **Update Backend**: Ensure it parses and filters correctly by both brand and location
