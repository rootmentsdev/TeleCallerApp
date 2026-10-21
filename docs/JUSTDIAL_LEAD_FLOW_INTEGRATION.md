# JustDial Lead Flow Integration

## Overview
Complete integration of JustDial lead endpoints for fetching, retrieving details, and updating JustDial leads.

## API Endpoints

### 1. Get JustDial Leads (List)
**Endpoint**: `GET /api/leads/justdial`

**URL**: `https://rootstele-imrn.onrender.com/api/leads/justdial`

**Query Parameters**:
- `store` (optional): Filter by store name
- `fromDate` (optional): Start date (YYYY-MM-DD)
- `toDate` (optional): End date (YYYY-MM-DD)
- `page` (optional): Page number for pagination
- `limit` (optional): Records per page

**Example**:
```
GET https://rootstele-imrn.onrender.com/api/leads/justdial?fromDate=2026-05-01&toDate=2026-05-02&limit=100
```

**Response**:
```json
{
  "success": true,
  "data": {
    "leads": [
      {
        "_id": "justdial_001",
        "name": "John Doe",
        "phone": "9876543210",
        "store": "MG Road",
        "leadStatus": "new",
        "createdAt": "2026-05-02T10:30:00.000Z",
        "updatedAt": "2026-05-02T10:30:00.000Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 100,
      "total": 50
    }
  }
}
```

---

### 2. Get JustDial Lead Details
**Endpoint**: `GET /api/leads/justdial/{id}`

**URL**: `https://rootstele-imrn.onrender.com/api/leads/justdial/{id}`

**Path Parameters**:
- `id` (required): JustDial lead ID

**Example**:
```
GET https://rootstele-imrn.onrender.com/api/leads/justdial/justdial_001
```

**Response**:
```json
{
  "success": true,
  "data": {
    "_id": "justdial_001",
    "name": "John Doe",
    "phone": "9876543210",
    "email": "john@example.com",
    "store": "MG Road",
    "leadStatus": "new",
    "source": "justdial",
    "remarks": "Interested in services",
    "createdAt": "2026-05-02T10:30:00.000Z",
    "updatedAt": "2026-05-02T10:30:00.000Z"
  }
}
```

---

### 3. Update JustDial Lead
**Endpoint**: `POST /api/leads/justdial/{id}`

**URL**: `https://rootstele-imrn.onrender.com/api/leads/justdial/{id}`

**Path Parameters**:
- `id` (required): JustDial lead ID

**Request Body** (use snake_case):
```json
{
  "lead_status": "contacted",
  "remarks": "Called and discussed services",
  "call_duration": 120,
  "follow_up_date": "2026-05-05T10:00:00.000Z"
}
```

**Example**:
```
POST https://rootstele-imrn.onrender.com/api/leads/justdial/justdial_001
Content-Type: application/json

{
  "lead_status": "contacted",
  "remarks": "Called and discussed services",
  "call_duration": 120
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "_id": "justdial_001",
    "name": "John Doe",
    "phone": "9876543210",
    "lead_status": "contacted",
    "remarks": "Called and discussed services",
    "updated_at": "2026-05-02T11:00:00.000Z"
  }
}
```

---

## Implementation in Code

### ApiConfig (frontend/lib/utils/api_config.dart)

```dart
// Get JustDial Leads
static String getJustDialLeads({
  String? store,
  String? fromDate,
  String? toDate,
  int? page,
  int? limit,
}) {
  String url = "$leadsEndpoint/justdial";
  List<String> queryParams = [];
  
  if (store != null && store.isNotEmpty) {
    queryParams.add("store=${Uri.encodeComponent(store)}");
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
  return url;
}

// Get JustDial Lead by ID
static String getJustDialLeadById(String id) {
  return "$leadsEndpoint/justdial/$id";
}

// Update JustDial Lead
static String updateJustDialLead(String id) {
  return "$leadsEndpoint/justdial/$id";
}
```

### ApiService (frontend/lib/services/api_service.dart)

```dart
// Get JustDial Leads
Future<Map<String, dynamic>> getJustDialLeads({
  String? store,
  String? fromDate,
  String? toDate,
  int? page,
  int? limit,
}) async {
  final url = ApiConfig.getJustDialLeads(
    store: store,
    fromDate: fromDate,
    toDate: toDate,
    page: page,
    limit: limit,
  );
  
  try {
    print('ApiService: Fetching JustDial leads');
    print('ApiService: URL => $url');
    
    final response = await _httpClient.get(url);
    return response;
  } on AuthenticationException {
    throw AuthenticationException();
  } catch (e, s) {
    print('ApiService: Error fetching JustDial leads: $e');
    FirebaseCrashlytics.instance.recordError(e, s, reason: 'getJustDialLeads failed');
    rethrow;
  }
}

// Get JustDial Lead Details
Future<Map<String, dynamic>> getJustDialLeadById(String id) async {
  final url = ApiConfig.getJustDialLeadById(id);
  
  try {
    print('ApiService: getJustDialLeadById - URL: $url');
    
    final response = await _httpClient.get(url);
    
    // Normalize snake_case keys to camelCase
    final normalized = <String, dynamic>{};
    response.forEach((key, value) {
      final camelKey = _snakeToCamel(key);
      normalized[camelKey] = value;
    });
    return normalized;
  } on AuthenticationException {
    throw AuthenticationException();
  } catch (e, s) {
    print('ApiService: Error fetching JustDial lead by ID: $e');
    FirebaseCrashlytics.instance.recordError(e, s, reason: 'getJustDialLeadById failed');
    rethrow;
  }
}

// Update JustDial Lead
Future<Map<String, dynamic>> updateJustDialLead(
  String id,
  Map<String, dynamic> data,
) async {
  final url = ApiConfig.updateJustDialLead(id);
  
  try {
    // Convert camelCase keys to snake_case for API
    final requestBody = <String, dynamic>{};
    data.forEach((key, value) {
      final snakeKey = _camelToSnake(key);
      requestBody[snakeKey] = value;
    });
    
    print('ApiService: updateJustDialLead - URL: $url');
    print('ApiService: updateJustDialLead - Request Body: $requestBody');
    
    // Use POST method like other update endpoints
    final response = await _httpClient.post(url, requestBody);
    
    // Normalize snake_case keys to camelCase
    final normalized = <String, dynamic>{};
    response.forEach((key, value) {
      final camelKey = _snakeToCamel(key);
      normalized[camelKey] = value;
    });
    return normalized;
  } on AuthenticationException {
    throw AuthenticationException();
  } catch (e, s) {
    print('ApiService: Error updating JustDial lead: $e');
    FirebaseCrashlytics.instance.recordError(e, s, reason: 'updateJustDialLead failed');
    rethrow;
  }
}
```

---

## Usage Examples

### Fetch JustDial Leads for Today
```dart
final apiService = ApiService();
final response = await apiService.getJustDialLeads(
  fromDate: '2026-05-02',
  toDate: '2026-05-02',
  limit: 100,
);
```

### Get JustDial Lead Details
```dart
final apiService = ApiService();
final leadDetails = await apiService.getJustDialLeadById('justdial_001');
print('Lead: ${leadDetails['name']}, Phone: ${leadDetails['phone']}');
```

### Update JustDial Lead Status
```dart
final apiService = ApiService();
final updatedLead = await apiService.updateJustDialLead(
  'justdial_001',
  {
    'leadStatus': 'contacted',
    'remarks': 'Called and discussed services',
    'callDuration': 120,
  },
);
```

---

## Lead Status Values

| Status | Description |
|--------|-------------|
| `new` | New lead from JustDial |
| `contacted` | Lead has been contacted |
| `interested` | Lead is interested |
| `not_interested` | Lead is not interested |
| `follow_up` | Lead requires follow-up |
| `converted` | Lead converted to booking |
| `lost` | Lead lost to competitor |

---

## Common Fields

| Field | Type | Description |
|-------|------|-------------|
| `_id` | String | Unique lead ID |
| `name` | String | Lead name |
| `phone` | String | Lead phone number |
| `email` | String | Lead email (optional) |
| `store` | String | Store location |
| `leadStatus` | String | Current status |
| `source` | String | Always "justdial" |
| `remarks` | String | Additional notes |
| `callDuration` | Integer | Call duration in seconds |
| `followUpDate` | DateTime | Next follow-up date |
| `createdAt` | DateTime | Lead creation date |
| `updatedAt` | DateTime | Last update date |

---

## Error Handling

### Authentication Error (401)
```json
{
  "success": false,
  "error": "Unauthorized",
  "statusCode": 401
}
```

### Not Found Error (404)
```json
{
  "success": false,
  "error": "Lead not found",
  "statusCode": 404
}
```

### Validation Error (400)
```json
{
  "success": false,
  "error": "Invalid lead status",
  "statusCode": 400
}
```

---

## Integration Checklist

- [x] Add `getJustDialLeads()` method to ApiService
- [x] Add `getJustDialLeadById()` method to ApiService
- [x] Add `updateJustDialLead()` method to ApiService
- [x] Add URL builders to ApiConfig
- [ ] Create JustDial lead list screen
- [ ] Create JustDial lead detail screen
- [ ] Create JustDial lead update form
- [ ] Add JustDial leads to reports
- [ ] Add JustDial call tracking
- [ ] Add JustDial lead follow-up

---

## Files Modified

1. `frontend/lib/utils/api_config.dart` - Added `updateJustDialLead()` endpoint
2. `frontend/lib/services/api_service.dart` - Added `updateJustDialLead()` method

---

## Next Steps

1. Create a JustDial lead list screen to display all JustDial leads
2. Create a JustDial lead detail screen to view and update individual leads
3. Integrate JustDial leads into the reports section
4. Add call tracking for JustDial leads
5. Implement follow-up scheduling for JustDial leads
