# Store Filter - Complete Code Trace

## Step-by-Step Code Execution

### Step 1: User Selects Store from Dropdown

**File:** `lib/view/reports_screens/reports_screen.dart` (Line 515-520)

```dart
// Hardcoded store list
...HeaderController.defaultStores
    .map((Store store) {
      return DropdownMenuItem<Store>(
        value: store,
        child: Text(store.normalizedName),  // Shows "DS-Edappally"
      );
    })
    .toList(),
```

**User clicks:** "Dapper Squad - Edappally" (which is `DS-Edappally`)

---

### Step 2: Store Selection is Saved

**File:** `lib/controller/header_controller.dart` (Line 95-105)

```dart
void setSelectedStore(Store store) {
  if (_selectedStore != store) {
    _selectedStore = store;  // Stores: Store(brand: 'DS', location: 'Edappally', normalizedName: 'DS-Edappally')
    
    // Set store as custom key in Firebase Crashlytics
    if (store.normalizedName != 'All Stores') {
      FirebaseCrashlytics.instance.setCustomKey(
        "store",
        store.normalizedName,  // Sets: "DS-Edappally"
      );
    }
    notifyListeners();  // Notifies all listeners (Lead Screen, Report Screen, etc.)
  }
}
```

**Result:** `_selectedStore = Store(brand: 'DS', location: 'Edappally', normalizedName: 'DS-Edappally')`

---

### Step 3: Lead Screen Detects Store Change

**File:** `lib/view/lead_screen/lead_screen.dart` (Line 63-75)

```dart
/// Called when header controller changes (store or date filter)
void _onHeaderChanged() {
  final leadController = Provider.of<LeadScreenController>(
    context,
    listen: false,
  );
  
  // Fetch leads with new store filter
  leadController.fetchLeadsForCurrentFilters();
}
```

**Triggered by:** `HeaderController.notifyListeners()`

---

### Step 4: Lead Screen Controller Fetches Leads

**File:** `lib/controller/lead_screen_controller.dart` (Line 50-75)

```dart
void fetchLeadsForCurrentFilters({
  String? storeParam,
  DateTime? dateFrom,
  DateTime? dateTo,
  DateTime? singleDate,
}) {
  final store = storeParam ?? _headerController?.selectedStore;
  
  // Get store's normalizedName
  final storeString = store?.normalizedName;  // Gets: "DS-Edappally"
  
  _fetchLeadsForCurrentFilters(storeString, dateFrom, dateTo, singleDate);
}

void _fetchLeadsForCurrentFilters(
  String? storeParam,
  DateTime? dateFrom,
  DateTime? dateTo,
  DateTime? singleDate,
) {
  // Calls repository to fetch leads
  _repository.fetchAllLeadsFromApi(
    store: storeParam,  // Passes: "DS-Edappally"
    dateFrom: dateFrom,
    dateTo: dateTo,
  );
}
```

**Result:** Calls `_repository.fetchAllLeadsFromApi(store: "DS-Edappally")`

---

### Step 5: Lead Repository Prepares API Call

**File:** `lib/controller/lead_repository.dart` (Line 1472-1510)

```dart
Future<void> fetchAllLeadsFromApi({
  String? store,  // Receives: "DS-Edappally"
  int? page,
  String? enquiryDateFrom,
  String? enquiryDateTo,
  String? functionDateFrom,
  String? functionDateTo,
  String? visitDateFrom,
  String? visitDateTo,
  String? dateFrom,
  String? dateTo,
  String? dateField,
  String? createdAt,
}) async {
  try {
    await ensureInitialized();

    // Pass store in "Brand - Location" format (e.g., "Suitor Guy - Edappal")
    final storeFilter =
        (store == null || store == 'All Stores') ? null : store;
    // storeFilter = "DS-Edappally"  ← Passed as-is, no modification
    
    final response = await _apiService.getAllLeads(
      store: storeFilter,  // ✅ Passes: "DS-Edappally"
      page: page,
      dateFrom: dateFrom,
      dateTo: dateTo,
      dateField: dateField,
      createdAt: createdAt,
    );

    final leadsData = _parseResponseData(response);
    // ... rest of the method
  } catch (e) {
    print('LeadRepository: Error fetching all leads: $e');
    rethrow;
  }
}
```

**Key Point:** Store parameter is passed **without any modification**

**Result:** Calls `_apiService.getAllLeads(store: "DS-Edappally")`

---

### Step 6: API Service Calls Backend

**File:** `lib/services/api_service.dart` (Line 998-1060)

```dart
// Get All Leads
Future<Map<String, dynamic>> getAllLeads({
  String? store,  // Receives: "DS-Edappally"
  int? page,
  String? dateFrom,
  String? dateTo,
  String? dateField,
  String? createdAt,
}) async {
  final url = ApiConfig.getAllLeads(
    store: store,  // ✅ Passes: "DS-Edappally"
    page: page,
    dateFrom: dateFrom,
    dateTo: dateTo,
    dateField: dateField,
    createdAt: createdAt,
  );

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to fetch all leads');
    }
  } catch (e, s) {
    FirebaseCrashlytics.instance.recordError(
      e,
      s,
      reason: 'getAllLeads failed',
    );
    rethrow;
  }
}
```

**Result:** Makes HTTP request to the URL returned by `ApiConfig.getAllLeads()`

---

### Step 7: API Config Builds URL

**File:** `lib/utils/api_config.dart` (Line 29-50)

```dart
// ===== Return Leads =====
static String getReturnLeads({
  String? store,  // Receives: "DS-Edappally"
  String? fromDate,
  String? toDate,
  int? page,
  int? limit,
}) {
  String url = "$leadsEndpoint/returns";
  List<String> queryParams = [];

  if (store != null && store.isNotEmpty) {
    queryParams.add("store=${Uri.encodeComponent(store)}");
    // ✅ Adds: "store=DS-Edappally"
    // Uri.encodeComponent() properly encodes special characters
  }
  if (fromDate != null && fromDate.isNotEmpty) {
    queryParams.add("fromDate=${Uri.encodeComponent(fromDate)}");
  }
  if (toDate != null && toDate.isNotEmpty) {
    queryParams.add("toDate=${Uri.encodeComponent(toDate)}");
  }
  if (page != null) {
    queryParams.add("page=$page");
  }
  if (limit != null) {
    queryParams.add("limit=$limit");
  }

  if (queryParams.isNotEmpty) {
    url += "?${queryParams.join('&')}";
  }
  return url;  // ✅ Returns: "/api/leads/returns?store=DS-Edappally"
}
```

**Result:** Returns URL: `https://rootstele-imrn.onrender.com/api/leads?store=DS-Edappally`

---

### Step 8: HTTP Request is Sent

**Network Request:**

```
GET /api/leads?store=DS-Edappally HTTP/1.1
Host: rootstele-imrn.onrender.com
Authorization: Bearer <token>
Content-Type: application/json
```

**✅ Frontend has done everything correctly up to this point**

---

### Step 9: Backend Receives Request

**Backend receives:**
```
store=DS-Edappally
```

**❌ Backend Problem Starts Here**

---

### Step 10: Backend Query (PROBLEM)

**What Backend SHOULD do:**

```python
# Parse the store parameter
store_param = request.args.get('store')  # Gets: "DS-Edappally"

if store_param and store_param != 'All Stores':
    # Parse: "DS-Edappally" → brand="DS", location="Edappally"
    parts = store_param.split('-', 1)
    brand = parts[0]  # "DS"
    location = parts[1]  # "Edappally"
    
    # Query with BOTH filters
    leads = db.leads.find({
        'brand': brand,
        'location': location
    })
    # Returns: Only DS-Edappally leads ✅
else:
    leads = db.leads.find({})
```

**What Backend is LIKELY doing (WRONG):**

```python
# Option 1: Ignoring the store parameter
leads = db.leads.find({})
# Returns: ALL leads ❌

# Option 2: Filtering only by location (MOST LIKELY)
store_param = request.args.get('store')  # Gets: "DS-Edappally"
location = store_param.split('-')[1]  # Extracts: "Edappally"

leads = db.leads.find({
    'location': location  # Only filters by location
})
# Returns: SG-Edappally, Z-Edappally, DS-Edappally ❌

# Option 3: No data for DS-Edappally
leads = db.leads.find({
    'store': store_param  # Looks for exact match
})
# Returns: 0 results (no DS data)
# Fallback: Returns all Edappally locations ❌
```

---

### Step 11: Backend Response

**❌ Current (Wrong) Response:**

```json
{
  "success": true,
  "data": {
    "leads": [
      {
        "id": "1",
        "name": "John",
        "brand": "SG",
        "location": "Edappally",
        "phone": "9876543210"
      },
      {
        "id": "2",
        "name": "Jane",
        "brand": "Z",
        "location": "Edappally",
        "phone": "9876543211"
      },
      {
        "id": "3",
        "name": "Bob",
        "brand": "DS",
        "location": "Edappally",
        "phone": "9876543212"
      }
    ]
  }
}
```

**✅ Correct Response Should Be:**

```json
{
  "success": true,
  "data": {
    "leads": [
      {
        "id": "3",
        "name": "Bob",
        "brand": "DS",
        "location": "Edappally",
        "phone": "9876543212"
      }
    ]
  }
}
```

---

### Step 12: Frontend Receives Response

**File:** `lib/controller/lead_repository.dart` (Line 1510-1550)

```dart
final leadsData = _parseResponseData(response);
// Receives: [SG-Edappally, Z-Edappally, DS-Edappally]

// Debug: Print how many leads were received
print('LeadRepository: Received ${leadsData.length} leads from API');
// Prints: "Received 3 leads from API"

// Convert API data to LeadModel and add to repository
for (var leadData in leadsData) {
  try {
    final lead = _parseApiLeadToLeadModel(leadData);
    if (lead != null) {
      _leads.add(lead);  // Adds all 3 leads (including wrong ones)
    }
  } catch (e) {
    print('LeadRepository: Error parsing lead: $e');
  }
}

await _saveLeads();
notifyListeners();  // Notifies UI to refresh
```

**Result:** Frontend stores all 3 leads (SG, Z, DS) in `_leads`

---

### Step 13: Frontend Displays Results

**File:** `lib/view/lead_screen/lead_screen.dart`

```dart
// Lead Screen displays all leads from _leads
// Shows: SG-Edappally, Z-Edappally, DS-Edappally
// Expected: Only DS-Edappally
```

**❌ Result: Wrong leads are displayed**

---

## Summary of Code Flow

| Step | Component | Action | Status |
|------|-----------|--------|--------|
| 1 | UI | User selects "DS-Edappally" | ✅ |
| 2 | HeaderController | Saves store selection | ✅ |
| 3 | LeadScreen | Detects store change | ✅ |
| 4 | LeadScreenController | Calls repository | ✅ |
| 5 | LeadRepository | Prepares API call with "DS-Edappally" | ✅ |
| 6 | ApiService | Calls backend | ✅ |
| 7 | ApiConfig | Builds URL with store parameter | ✅ |
| 8 | Network | Sends HTTP request | ✅ |
| 9 | Backend | Receives "store=DS-Edappally" | ✅ |
| 10 | Backend | **Filters incorrectly** | ❌ |
| 11 | Backend | Returns all Edappally brands | ❌ |
| 12 | Frontend | Receives wrong data | ❌ |
| 13 | UI | Displays wrong leads | ❌ |

---

## Conclusion

**Frontend is 100% correct.** It:
- ✅ Selects the correct store
- ✅ Passes the correct parameter ("DS-Edappally")
- ✅ Builds the correct URL
- ✅ Sends the correct HTTP request

**Backend is the problem.** It:
- ❌ Doesn't parse the brand from the store parameter
- ❌ Filters only by location, not brand
- ❌ Returns all brands at the location instead of just the selected brand

**Fix needed:** Update backend to parse and filter by both brand AND location.
