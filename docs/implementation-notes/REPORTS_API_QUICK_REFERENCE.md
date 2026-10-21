# Reports API Quick Reference

## Endpoint
```
GET /api/reports
```

## Query Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| leadType | string | No | Filter by lead type: enquiry, return, bookingconfirmation, lossOfSale |
| editedBy | string | No | Filter by editor user ID |
| dateFrom | string | No | Start date (YYYY-MM-DD format) |
| dateTo | string | No | End date (YYYY-MM-DD format) |
| page | integer | No | Page number (default: 1) |
| limit | integer | No | Items per page (default: 50) |

## Example Requests

### Get all reports for a date range
```
GET /api/reports?dateFrom=2026-01-20&dateTo=2026-01-26&page=1&limit=100
```

### Get enquiry reports only
```
GET /api/reports?leadType=enquiry&dateFrom=2026-01-20&dateTo=2026-01-26
```

### Get feedback (return) reports
```
GET /api/reports?leadType=return&dateFrom=2026-01-20&dateTo=2026-01-26
```

### Get booking confirmation reports
```
GET /api/reports?leadType=bookingconfirmation&dateFrom=2026-01-20&dateTo=2026-01-26
```

### Get loss of sale reports
```
GET /api/reports?leadType=lossOfSale&dateFrom=2026-01-20&dateTo=2026-01-26
```

## Response Format

### Success Response (200 OK)
```json
{
  "reports": [
    {
      "report_id": "507f1f77bcf86cd799439011",
      "lead_name": "John Doe",
      "phone_number": "+91-9876543210",
      "store": "Kozhikode",
      "lead_type": "enquiry",
      "call_status": "Connected",
      "lead_status": "Interested",
      "callDuration": 120,
      "edited_by": {
        "id": "507f1f77bcf86cd799439012",
        "name": "Agent Name",
        "employee_id": "EMP001"
      },
      "edited_at": "2026-01-26T05:54:19.9937Z",
      "note": "Customer interested in product",
      "created_at": "2026-01-26T05:54:19.9937Z",
      "updated_at": "2026-01-26T05:54:19.9937Z",
      "rating": 0
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 100,
    "total": 25,
    "pages": 1
  }
}
```

### Error Response (401 Unauthorized)
```json
{
  "message": "Authentication failed. Please login again."
}
```

### Error Response (400 Bad Request)
```json
{
  "message": "Invalid date format. Use YYYY-MM-DD"
}
```

## Lead Type Values

| Value | Display Name | Description |
|---|---|---|
| enquiry | Enquiry | New customer inquiry |
| return | Feedback | Return/Feedback from customer |
| bookingconfirmation | Booking | Booking confirmation |
| lossOfSale | Loss of Sale | Lost sale opportunity |

## Call Status Values
- Connected
- Not Connected
- Not Called
- Voicemail
- Busy
- Switched Off
- Invalid Number

## Lead Status Values
- Interested
- Not Interested
- No Status
- Pending
- Converted
- Lost

## Frontend Implementation

### Fetch Reports
```dart
final reportController = Provider.of<ReportController>(context, listen: false);
await reportController.fetchReportsWithCurrentFilters();
```

### Get Filtered Leads
```dart
final leads = reportController.getFilteredLeads();
```

### Access Report Data
```dart
for (var report in reportController.reports) {
  print('Lead: ${report.leadData?['name']}');
  print('Phone: ${report.leadData?['phone']}');
  print('Type: ${report.leadType}');
  print('Duration: ${report.callDuration}');
}
```

## Date Format
All dates in API requests and responses use ISO 8601 format:
- Request: `YYYY-MM-DD` (e.g., 2026-01-26)
- Response: `YYYY-MM-DDTHH:mm:ss.SSSZ` (e.g., 2026-01-26T05:54:19.9937Z)

## Pagination
- Default page: 1
- Default limit: 50
- Maximum recommended limit: 100
- Total pages calculated as: `ceil(total / limit)`

## Notes
- All timestamps are in UTC (Z timezone)
- Phone numbers may include country code and formatting
- Store names are normalized (e.g., Calicut → Kozhikode)
- Call duration is in seconds
- Rating field is currently not used in frontend
