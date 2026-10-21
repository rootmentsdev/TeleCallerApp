# Report API Endpoints - Quick Reference

## Base URL
```
https://rootstele-imrn.onrender.com
```

## Main Report Endpoints

### 1. Get All Reports (Completed Leads)
```
GET /api/leads/completed
```

**Full URL**:
```
https://rootstele-imrn.onrender.com/api/leads/completed
```

**Query Parameters**:
```
?store=MG%20Road&fromDate=2026-04-01&toDate=2026-04-30&limit=1000
```

**Complete Example**:
```
https://rootstele-imrn.onrender.com/api/leads/completed?fromDate=2026-04-01&toDate=2026-04-30&limit=1000
```

---

### 2. Get Report by ID ⭐ (Most Common)
```
GET /api/leads/{id}
```

**Full URL**:
```
https://rootstele-imrn.onrender.com/api/leads/{id}
```

**Examples**:
```
https://rootstele-imrn.onrender.com/api/leads/LD001
https://rootstele-imrn.onrender.com/api/leads/6507a1b2c3d4e5f6g7h8i9j0
```

---

## Lead Type Specific Endpoints

### Return Leads
```
GET /api/leads/returns/{id}
https://rootstele-imrn.onrender.com/api/leads/returns/LD001
```

### Booking Confirmation Leads
```
GET /api/leads/booking-confirmation/{id}
https://rootstele-imrn.onrender.com/api/leads/booking-confirmation/LD001
```

### Follow-up Leads
```
GET /api/leads/followups/{id}
https://rootstele-imrn.onrender.com/api/leads/followups/LD001
```

### Complaint Leads
```
GET /api/leads/complaints/{id}
https://rootstele-imrn.onrender.com/api/leads/complaints/LD001
```

### JustDial Leads
```
GET /api/leads/justdial/{id}
https://rootstele-imrn.onrender.com/api/leads/justdial/LD001
```

---

## Date Range Examples

### Today
```
https://rootstele-imrn.onrender.com/api/leads/completed?fromDate=2026-05-01&toDate=2026-05-01
```

### Last 7 Days
```
https://rootstele-imrn.onrender.com/api/leads/completed?fromDate=2026-04-24&toDate=2026-05-01
```

### This Month
```
https://rootstele-imrn.onrender.com/api/leads/completed?fromDate=2026-05-01&toDate=2026-05-01
```

### Last Month
```
https://rootstele-imrn.onrender.com/api/leads/completed?fromDate=2026-04-01&toDate=2026-04-30
```

### Custom Range
```
https://rootstele-imrn.onrender.com/api/leads/completed?fromDate=2026-04-15&toDate=2026-04-25
```

---

## Store Filter Examples

### Single Store
```
https://rootstele-imrn.onrender.com/api/leads/completed?store=MG%20Road
```

### With Date Range
```
https://rootstele-imrn.onrender.com/api/leads/completed?store=MG%20Road&fromDate=2026-04-01&toDate=2026-04-30
```

### All Stores (No Filter)
```
https://rootstele-imrn.onrender.com/api/leads/completed?fromDate=2026-04-01&toDate=2026-04-30
```

---

## Pagination Examples

### First Page
```
https://rootstele-imrn.onrender.com/api/leads/completed?page=1&limit=50
```

### Second Page
```
https://rootstele-imrn.onrender.com/api/leads/completed?page=2&limit=50
```

### Large Limit
```
https://rootstele-imrn.onrender.com/api/leads/completed?limit=1000
```

---

## Complete Examples

### Get Last Month Reports for MG Road Store
```
https://rootstele-imrn.onrender.com/api/leads/completed?store=MG%20Road&fromDate=2026-04-01&toDate=2026-04-30&limit=1000
```

### Get Today's Reports with Pagination
```
https://rootstele-imrn.onrender.com/api/leads/completed?fromDate=2026-05-01&toDate=2026-05-01&page=1&limit=50
```

### Get Specific Report by ID
```
https://rootstele-imrn.onrender.com/api/leads/LD001
```

### Get Return Lead by ID
```
https://rootstele-imrn.onrender.com/api/leads/returns/LD001
```

---

## URL Encoding Reference

| Character | Encoded | Example |
|-----------|---------|---------|
| Space | %20 | MG%20Road |
| & | %26 | - |
| = | %3D | - |
| ? | %3F | - |
| # | %23 | - |

---

## In Code (Using ApiConfig)

```dart
// Get all completed leads
String url = ApiConfig.getCompletedLeads(
  fromDate: '2026-04-01',
  toDate: '2026-04-30',
  limit: 1000,
);
// Result: https://rootstele-imrn.onrender.com/api/leads/completed?fromDate=2026-04-01&toDate=2026-04-30&limit=1000

// Get report by ID
String url = ApiConfig.getReportById('LD001');
// Result: https://rootstele-imrn.onrender.com/api/leads/LD001

// Get return lead by ID
String url = ApiConfig.updateReturnLead('LD001');
// Result: https://rootstele-imrn.onrender.com/api/leads/returns/LD001
```

---

## Response Example

```json
{
  "data": [
    {
      "id": "LD001",
      "name": "Nidhin",
      "phone": "7736350589",
      "store": "SG Trivandrum",
      "leadType": "bookingconfirmation",
      "leadStatus": "completed",
      "callDuration": 120,
      "callDate": "2026-04-25T14:30:00.000Z",
      "remarks": "Confirmed booking"
    },
    {
      "id": "LD002",
      "name": "JUBIN",
      "phone": "9207239690",
      "store": "SG Kottayam",
      "leadType": "bookingconfirmation",
      "leadStatus": "completed",
      "callDuration": 180,
      "callDate": "2026-04-24T10:15:00.000Z",
      "remarks": "Booking confirmed"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 35
  }
}
```

---

## Summary Table

| Use Case | Endpoint | Example |
|----------|----------|---------|
| Get all reports | `/api/leads/completed` | `https://rootstele-imrn.onrender.com/api/leads/completed?fromDate=2026-04-01&toDate=2026-04-30` |
| Get report by ID | `/api/leads/{id}` | `https://rootstele-imrn.onrender.com/api/leads/LD001` |
| Get return lead | `/api/leads/returns/{id}` | `https://rootstele-imrn.onrender.com/api/leads/returns/LD001` |
| Get booking lead | `/api/leads/booking-confirmation/{id}` | `https://rootstele-imrn.onrender.com/api/leads/booking-confirmation/LD001` |
| Get follow-up lead | `/api/leads/followups/{id}` | `https://rootstele-imrn.onrender.com/api/leads/followups/LD001` |
| Get complaint lead | `/api/leads/complaints/{id}` | `https://rootstele-imrn.onrender.com/api/leads/complaints/LD001` |
| Get JustDial lead | `/api/leads/justdial/{id}` | `https://rootstele-imrn.onrender.com/api/leads/justdial/LD001` |

---

## Key Points

✅ **Base URL**: `https://rootstele-imrn.onrender.com`  
✅ **Get Report by ID**: `/api/leads/{id}` (Most common)  
✅ **Get All Reports**: `/api/leads/completed` with date filters  
✅ **Date Format**: `YYYY-MM-DD` (e.g., 2026-04-01)  
✅ **URL Encoding**: Use %20 for spaces  
✅ **Authentication**: Include Bearer token in headers  
✅ **Response**: JSON with data array and pagination info
