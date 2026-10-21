# Store Filter Flow Diagram

## Complete Data Flow: Frontend to Backend

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          USER INTERACTION                                   │
│                                                                              │
│  User selects "Dapper Squad - Edappally" from dropdown                      │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│                    FRONTEND: STORE SELECTION                                │
│                                                                              │
│  File: header_controller.dart                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ Store(                                                              │   │
│  │   brand: 'DS',                                                      │   │
│  │   location: 'Edappally',                                            │   │
│  │   normalizedName: 'DS-Edappally'  ← This is the key!               │   │
│  │ )                                                                   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  HeaderController.setSelectedStore(store)                                   │
│  → Stores the selected store in _selectedStore                              │
│  → Notifies listeners (Lead Screen, Report Screen, etc.)                    │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│                    FRONTEND: API CALL PREPARATION                           │
│                                                                              │
│  File: lead_repository.dart (line 1490-1493)                                │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ Future<void> fetchAllLeadsFromApi({                                 │   │
│  │   String? store,  // Receives: 'DS-Edappally'                       │   │
│  │   ...                                                               │   │
│  │ }) {                                                                │   │
│  │   final storeFilter =                                               │   │
│  │       (store == null || store == 'All Stores') ? null : store;      │   │
│  │   // storeFilter = 'DS-Edappally'  ← Passed as-is                   │   │
│  │                                                                     │   │
│  │   final response = await _apiService.getAllLeads(                  │   │
│  │     store: storeFilter,  // ✅ Passes 'DS-Edappally'               │   │
│  │     page: page,                                                     │   │
│  │   );                                                                │   │
│  │ }                                                                   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ✅ CORRECT: Store parameter is passed without modification                 │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│                    FRONTEND: URL CONSTRUCTION                               │
│                                                                              │
│  File: api_config.dart (line 29-50)                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ static String getAllLeads({                                         │   │
│  │   String? store,  // Receives: 'DS-Edappally'                       │   │
│  │   ...                                                               │   │
│  │ }) {                                                                │   │
│  │   String url = "$leadsEndpoint/leads";                              │   │
│  │   List<String> queryParams = [];                                    │   │
│  │                                                                     │   │
│  │   if (store != null && store.isNotEmpty) {                          │   │
│  │     queryParams.add("store=${Uri.encodeComponent(store)}");         │   │
│  │     // Adds: "store=DS-Edappally"                                   │   │
│  │   }                                                                 │   │
│  │                                                                     │   │
│  │   if (queryParams.isNotEmpty) {                                     │   │
│  │     url += "?${queryParams.join('&')}";                             │   │
│  │   }                                                                 │   │
│  │   return url;  // Returns: /api/leads?store=DS-Edappally            │   │
│  │ }                                                                   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ✅ CORRECT: URL is properly constructed with store parameter               │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│                    FRONTEND: HTTP REQUEST                                   │
│                                                                              │
│  File: api_service.dart                                                     │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ GET https://rootstele-imrn.onrender.com/api/leads?store=DS-Edappally
│  │                                                                     │   │
│  │ Headers:                                                            │   │
│  │   Authorization: Bearer <token>                                     │   │
│  │   Content-Type: application/json                                    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ✅ CORRECT: Request is sent with store parameter                           │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
                        ╔═══════════════════════╗
                        ║   BACKEND RECEIVES    ║
                        ║  store=DS-Edappally   ║
                        ╚═══════════════════════╝
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│                    BACKEND: QUERY EXECUTION                                 │
│                                                                              │
│  ❌ PROBLEM: Backend is likely doing ONE of these:                          │
│                                                                              │
│  Option 1: Ignoring the store parameter entirely                            │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ SELECT * FROM leads                                                 │   │
│  │ -- No WHERE clause, returns ALL leads                               │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  Option 2: Filtering only by location (ignoring brand)                      │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ SELECT * FROM leads                                                 │   │
│  │ WHERE location = 'Edappally'  ← Extracts location from 'DS-Edappally'
│  │ -- Returns: SG-Edappally, Z-Edappally, DS-Edappally                 │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  Option 3: Backend doesn't have DS-Edappally data, returns similar          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ SELECT * FROM leads                                                 │   │
│  │ WHERE store = 'DS-Edappally'                                        │   │
│  │ -- Returns: 0 results (no DS-Edappally data in DB)                  │   │
│  │ -- Fallback: Returns all Edappally locations                        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ✅ WHAT IT SHOULD DO:                                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ Parse store parameter: 'DS-Edappally' → brand='DS', location='Edappally'
│  │                                                                     │   │
│  │ SELECT * FROM leads                                                 │   │
│  │ WHERE brand = 'DS' AND location = 'Edappally'                       │   │
│  │ -- Returns: Only DS-Edappally leads                                 │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│                    BACKEND: RESPONSE                                        │
│                                                                              │
│  ❌ CURRENT (WRONG):                                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ {                                                                   │   │
│  │   "success": true,                                                  │   │
│  │   "data": {                                                         │   │
│  │     "leads": [                                                      │   │
│  │       { "id": "1", "name": "John", "brand": "SG", "location": "Edappally" },
│  │       { "id": "2", "name": "Jane", "brand": "Z", "location": "Edappally" },
│  │       { "id": "3", "name": "Bob", "brand": "DS", "location": "Edappally" }
│  │     ]                                                               │   │
│  │   }                                                                 │   │
│  │ }                                                                   │   │
│  │ -- Returns ALL brands at Edappally                                  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ✅ SHOULD BE:                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ {                                                                   │   │
│  │   "success": true,                                                  │   │
│  │   "data": {                                                         │   │
│  │     "leads": [                                                      │   │
│  │       { "id": "3", "name": "Bob", "brand": "DS", "location": "Edappally" }
│  │     ]                                                               │   │
│  │   }                                                                 │   │
│  │ }                                                                   │   │
│  │ -- Returns ONLY DS-Edappally leads                                  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│                    FRONTEND: RESPONSE HANDLING                              │
│                                                                              │
│  File: lead_repository.dart                                                 │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ final leadsData = _parseResponseData(response);                     │   │
│  │ // Receives: [SG-Edappally, Z-Edappally, DS-Edappally]             │   │
│  │                                                                     │   │
│  │ for (var leadData in leadsData) {                                   │   │
│  │   final lead = _parseApiLeadToLeadModel(leadData);                  │   │
│  │   _leads.add(lead);                                                 │   │
│  │ }                                                                   │   │
│  │                                                                     │   │
│  │ // Frontend stores all received leads (including wrong ones)        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ⚠️  FRONTEND FALLBACK (Local Filtering):                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ bool matchesStore(LeadModel lead, String store) {                   │   │
│  │   final filter = _extractBrandAndLocation(store);                   │   │
│  │   // Extracts: brand='DS', location='Edappally'                     │   │
│  │                                                                     │   │
│  │   if (!_brandsMatch(filter['brand'], lead.brand)) return false;     │   │
│  │   // Checks if brands match (DS == DS? Yes)                         │   │
│  │                                                                     │   │
│  │   // Checks if locations match                                      │   │
│  │   return normalizedLead == normalizedFilter || ...                  │   │
│  │ }                                                                   │   │
│  │                                                                     │   │
│  │ -- This SHOULD filter out SG and Z leads, keeping only DS           │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ⚠️  BUT: This local filtering might not be applied everywhere!             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│                    FRONTEND: UI DISPLAY                                     │
│                                                                              │
│  ❌ RESULT: Shows all three brands                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ Lead Screen                                                         │   │
│  │ ┌─────────────────────────────────────────────────────────────────┐ │   │
│  │ │ Filter: Dapper Squad - Edappally                               │ │   │
│  │ ├─────────────────────────────────────────────────────────────────┤ │   │
│  │ │ • John (SG-Edappally)  ← WRONG                                 │ │   │
│  │ │ • Jane (Z-Edappally)   ← WRONG                                 │ │   │
│  │ │ • Bob (DS-Edappally)   ← CORRECT                               │ │   │
│  │ └─────────────────────────────────────────────────────────────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Key Findings

### ✅ Frontend is Correct
1. **Store Selection**: Correctly selects "DS-Edappally"
2. **Parameter Passing**: Passes "DS-Edappally" to API
3. **URL Encoding**: Properly encodes as `store=DS-Edappally`
4. **Local Filtering**: Has fallback logic to filter by brand+location

### ❌ Backend is the Problem
1. **Parameter Parsing**: Not parsing brand from store parameter
2. **Query Filter**: Filtering only by location, not brand
3. **Response**: Returning all brands at the location instead of just the selected brand

### 🔧 Solution
Backend needs to:
1. Parse "DS-Edappally" into brand="DS" and location="Edappally"
2. Query with BOTH filters: `WHERE brand='DS' AND location='Edappally'`
3. Return only matching leads
