# API Endpoints Reference - Reports & Leads

## Base URL
```
https://rootstele-imrn.onrender.com
```

## Report/Lead Endpoints

### 1. Get Reports (Completed Leads)

#### Get All Completed Leads
```
GET /api/leads/completed
```

**Query Parameters**:
- `store` (optional) - Filter by store name
- `fromDate` (optional) - Start date (YYYY-MM-DD)
- `toDate` (optional) - End date (YYYY-MM-DD)
- `leadtype` (optional) - Filter by lead type
- `page` (optional) - Page number
- `limit` (optional) - Records per page

**Example URLs**:
```
GET https://rootstele-imrn.onrender.com/api/leads/completed

GET https://rootstele-imrn.onrender.com/api/leads/completed?fromDate=2026-04-01&toDate=2026-04-30

GET https://rootstele-imrn.onrender.com/api/leads/completed?store=MG%20Road&fromDate=2026-04-01&toDate=2026-04-30

GET https://rootstele-imrn.onrender.com/api/leads/completed?fromDate=2026-04-01&toDate=2026-04-30&limit=1000
```

#### Get Report by ID
```
GET /api/leads/{id}
```

**Example URLs**:
```
GET https://rootstele-imrn.onrender.com/api/leads/LD001

GET https://rootstele-imrn.onrender.com/api/leads/6507a1b2c3d4e5f6g7h8i9j0
```

---

### 2. Return Leads

#### Get All Return Leads
```
GET /api/leads/returns
```

**Query Parameters**:
- `store` (optional) - Filter by store
- `fromDate` (optional) - Start date
- `toDate` (optional) - End date
- `page` (optional) - Page number
- `limit` (optional) - Records per page

**Example URLs**:
```
GET https://rootstele-imrn.onrender.com/api/leads/returns

GET https://rootstele-imrn.onrender.com/api/leads/returns?fromDate=2026-04-01&toDate=2026-04-30

GET https://rootstele-imrn.onrender.com/api/leads/returns?store=MG%20Road
```

#### Get Return Lead by ID
```
GET /api/leads/returns/{id}
```

**Example URLs**:
```
GET https://rootstele-imrn.onrender.com/api/leads/returns/LD001

GET https://rootstele-imrn.onrender.com/api/leads/returns/6507a1b2c3d4e5f6g7h8i9j0
```

#### Update Return Lead
```
POST /api/leads/returns/{id}
```

**Example URLs**:
```
POST https://rootstele-imrn.onrender.com/api/leads/returns/LD001

POST https://rootstele-imrn.onrender.com/api/leads/returns/6507a1b2c3d4e5f6g7h8i9j0
```

---

### 3. Booking Confirmation Leads

#### Get All Booking Confirmation Leads
```
GET /api/leads/booking-confirmation
```

**Query Parameters**:
- `store` (optional) - Filter by store
- `fromDate` (optional) - Start date
- `toDate` (optional) - End date
- `page` (optional) - Page number
- `limit` (optional) - Records per page

**Example URLs**:
```
GET https://rootstele-imrn.onrender.com/api/leads/booking-confirmation

GET https://rootstele-imrn.onrender.com/api/leads/booking-confirmation?fromDate=2026-04-01&toDate=2026-04-30
```

#### Get Booking Confirmation Lead by ID
```
GET /api/leads/booking-confirmation/{id}
```

**Example URLs**:
```
GET https://rootstele-imrn.onrender.com/api/leads/booking-confirmation/LD001
```

#### Update Booking Confirmation Lead
```
POST /api/leads/booking-confirmation/{id}
```

---

### 4. Follow-up Leads

#### Get All Follow-up Leads
```
GET /api/leads/followups
```

**Query Parameters**:
- `store` (optional) - Filter by store
- `fromDate` (optional) - Start date
- `toDate` (optional) - End date
- `page` (optional) - Page number
- `limit` (optional) - Records per page

**Example URLs**:
```
GET https://rootstele-imrn.onrender.com/api/leads/followups

GET https://rootstele-imrn.onrender.com/api/leads/followups?store=MG%20Road
```

#### Get Follow-up Lead by ID
```
GET /api/leads/followups/{id}
```

**Example URLs**:
```
GET https://rootstele-imrn.onrender.com/api/leads/followups/LD001
```

#### Update Follow-up Lead
```
POST /api/leads/followups/{id}
```

---

### 5. Complaint Leads

#### Get All Complaint Leads
```
GET /api/leads/complaints
```

**Query Parameters**:
- `store` (optional) - Filter by store
- `fromDate` (optional) - Start date
- `toDate` (optional) - End date
- `page` (optional) - Page number
- `limit` (optional) - Records per page

**Example URLs**:
```
GET https://rootstele-imrn.onrender.com/api/leads/complaints

GET https://rootstele-imrn.onrender.com/api/leads/complaints?fromDate=2026-04-01&toDate=2026-04-30
```

#### Get Complaint Lead by ID
```
GET /api/leads/complaints/{id}
```

**Example URLs**:
```
GET https://rootstele-imrn.onrender.com/api/leads/complaints/LD001
```

---

### 6. JustDial Leads

#### Get All JustDial Leads
```
GET /api/leads/justdial
```

**Query Parameters**:
- `store` (optional) - Filter by store
- `fromDate` (optional) - Start date
- `toDate` (optional) - End date
- `page` (optional) - Page number
- `limit` (optional) - Records per page

**Example URLs**:
```
GET https://rootstele-imrn.onrender.com/api/leads/justdial

GET https://rootstele-imrn.onrender.com/api/leads/justdial?fromDate=2026-04-01&toDate=2026-04-30
```

#### Get JustDial Lead by ID
```
GET /api/leads/justdial/{id}
```

**Example URLs**:
```
GET https://rootstele-imrn.onrender.com/api/leads/justdial/LD001

GET https://rootstele-imrn.onrender.com/api/leads/justdial/6507a1b2c3d4e5f6g7h8i9j0
```

---

### 7. Other Endpoints

#### Get Call Summary
```
GET /api/leads/call-summary
```

**Query Parameters**:
- `date` (optional) - Specific date (YYYY-MM-DD)
- `store` (optional) - Filter by store

**Example URLs**:
```
GET https://rootstele-imrn.onrender.com/api/leads/call-summary

GET https://rootstele-imrn.onrender.com/api/leads/call-summary?date=2026-05-01&store=MG%20Road
```

#### Get Starred Calls
```
GET /api/leads/starred-calls
```

**Query Parameters**:
- `store` (optional) - Filter by store
- `page` (optional) - Page number
- `limit` (optional) - Records per page

**Example URLs**:
```
GET https://rootstele-imrn.onrender.com/api/leads/starred-calls

GET https://rootstele-imrn.onrender.com/api/leads/starred-calls?store=MG%20Road
```

#### Get Starred Call by ID
```
GET /api/leads/starred-calls/{id}
```

**Example URLs**:
```
GET https://rootstele-imrn.onrender.com/api/leads/starred-calls/LD001
```

---

## Authentication Endpoints

#### Login
```
POST /api/auth/telecaller-login
```

**Example URL**:
```
POST https://rootstele-imrn.onrender.com/api/auth/telecaller-login
```

#### Logout
```
POST /api/auth/telecaller-logout
```

**Example URL**:
```
POST https://rootstele-imrn.onrender.com/api/auth/telecaller-logout
```

#### Refresh Token
```
POST /api/auth/refresh-token
```

**Example URL**:
```
POST https://rootstele-imrn.onrender.com/api/auth/refresh-token
```

---

## Other Endpoints

#### Get Stores
```
GET /api/stores
```

**Example URL**:
```
GET https://rootstele-imrn.onrender.com/api/stores
```

#### Check Phone
```
GET /api/customers/check-phone
```

**Query Parameters**:
- `phone` (required) - Phone number to check

**Example URL**:
```
GET https://rootstele-imrn.onrender.com/api/customers/check-phone?phone=9876543210
```

---

## URL Encoding

When using special characters in query parameters, use URL encoding:

| Character | Encoded |
|-----------|---------|
| Space | %20 |
| & | %26 |
| = | %3D |
| ? | %3F |
| # | %23 |

**Example**:
```
Store: "MG Road" → "MG%20Road"
Store: "SG-Trivandrum" → "SG-Trivandrum" (no encoding needed)
```

---

## Common Query Parameter Combinations

### Get Reports for Last Month
```
GET /api/leads/completed?fromDate=2026-04-01&toDate=2026-04-30&limit=1000
```

### Get Reports for Specific Store and Date Range
```
GET /api/leads/completed?store=MG%20Road&fromDate=2026-04-01&toDate=2026-04-30
```

### Get Reports with Pagination
```
GET /api/leads/completed?fromDate=2026-04-01&toDate=2026-04-30&page=1&limit=50
```

### Get Reports by Lead Type
```
GET /api/leads/completed?leadtype=enquiry&fromDate=2026-04-01&toDate=2026-04-30
```

---

## Response Format

### Success Response (200 OK)
```json
{
  "data": [
    {
      "id": "LD001",
      "name": "John Doe",
      "phone": "9876543210",
      "store": "MG Road",
      "leadType": "enquiry",
      "leadStatus": "completed",
      "callDuration": 120,
      "callDate": "2026-04-25T14:30:00.000Z",
      "remarks": "Interested in services"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 100
  }
}
```

### Error Response (400/401/500)
```json
{
  "error": "Error message",
  "statusCode": 400
}
```

---

## Implementation in Code

### Using ApiConfig (Recommended)
```dart
// Get all completed leads for date range
final url = ApiConfig.getCompletedLeads(
  fromDate: '2026-04-01',
  toDate: '2026-04-30',
  limit: 1000,
);

// Get report by ID
final url = ApiConfig.getReportById('LD001');

// Get return lead by ID
final url = ApiConfig.updateReturnLead('LD001');
```

### Using HttpClient
```dart
final httpClient = HttpClient();

// Get completed leads
final response = await httpClient.get(
  ApiConfig.getCompletedLeads(
    fromDate: '2026-04-01',
    toDate: '2026-04-30',
  ),
);

// Get report by ID
final response = await httpClient.get(
  ApiConfig.getReportById('LD001'),
);
```

---

## Summary

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/leads/completed` | GET | Get all completed leads (reports) |
| `/api/leads/{id}` | GET | Get report by ID |
| `/api/leads/returns` | GET | Get all return leads |
| `/api/leads/returns/{id}` | GET/POST | Get or update return lead |
| `/api/leads/booking-confirmation` | GET | Get all booking confirmation leads |
| `/api/leads/booking-confirmation/{id}` | GET/POST | Get or update booking confirmation lead |
| `/api/leads/followups` | GET | Get all follow-up leads |
| `/api/leads/followups/{id}` | GET/POST | Get or update follow-up lead |
| `/api/leads/complaints` | GET | Get all complaint leads |
| `/api/leads/complaints/{id}` | GET | Get complaint lead by ID |
| `/api/leads/justdial` | GET | Get all JustDial leads |
| `/api/leads/justdial/{id}` | GET | Get JustDial lead by ID |
| `/api/leads/call-summary` | GET | Get call summary |
| `/api/leads/starred-calls` | GET | Get starred calls |
| `/api/leads/starred-calls/{id}` | GET | Get starred call by ID |
