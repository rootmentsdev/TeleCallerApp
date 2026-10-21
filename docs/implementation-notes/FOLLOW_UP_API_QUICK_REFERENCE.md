# Follow-Up API Quick Reference Guide

## API Endpoints Summary

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/api/pages/follow-ups` | List all follow-up leads |
| GET | `/api/pages/follow-ups/{id}` | Get single follow-up lead |
| POST | `/api/pages/follow-ups/{id}` | Update follow-up lead |

---

## Quick Request/Response Examples

### 1. List Follow-Up Leads
```bash
curl -X GET "https://api.example.com/api/pages/follow-ups" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json"
```

**Response:**
```json
{
  "data": [
    {
      "id": "69722c0ef6c1bce8019f7e98",
      "lead_name": "Abhiram S Kumar",
      "phone_number": "9876543210",
      "call_status": "Not Called",
      "lead_status": "No Status",
      "follow_up_date": "2026-01-25T00:00:00.000Z"
    }
  ]
}
```

---

### 2. Get Single Follow-Up Lead
```bash
curl -X GET "https://api.example.com/api/pages/follow-ups/69722c0ef6c1bce8019f7e98" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json"
```

**Response:**
```json
{
  "id": "69722c0ef6c1bce8019f7e98",
  "lead_name": "Abhiram S Kumar",
  "phone_number": "9876543210",
  "store": "Suitor Guy - Perumbavoor",
  "lead_type": "follow-up",
  "call_status": "Not Called",
  "lead_status": "No Status",
  "function_date": "2026-01-17T00:00:00.000Z",
  "created_at": "2026-01-22T00:00:00.000Z",
  "follow_up_date": "2026-01-25T00:00:00.000Z",
  "follow_up_flag": true,
  "remarks": "Interested in luxury suite",
  "call_duration": 0,
  "sub_category": "Interested",
  "closing_action": "Interested"
}
```

---

### 3. Update Follow-Up Lead (After Call)
```bash
curl -X POST "https://api.example.com/api/pages/follow-ups/69722c0ef6c1bce8019f7e98" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "call_status": "Interested",
    "lead_status": "Interested",
    "call_duration": 120,
    "remarks": "Customer very interested in luxury suite"
  }'
```

**Response:**
```json
{
  "id": "69722c0ef6c1bce8019f7e98",
  "lead_name": "Abhiram S Kumar",
  "call_status": "Interested",
  "lead_status": "Interested",
  "call_duration": 120,
  "remarks": "Customer very interested in luxury suite",
  "updated_at": "2026-01-22T10:30:00.000Z"
}
```

---

## Field Reference

### Request Fields (POST)

#### Required
- **call_status** (string): "Interested" | "Not Interested" | "Call Back Later" | "Connected" | "Not Connected"
- **lead_status** (string): "Interested" | "Not Interested" | "No Status"

#### Optional
- **call_duration** (integer): Duration in seconds (0 for unanswered)
- **remarks** (string): Additional notes (max 500 chars)
- **follow_up_date** (datetime): ISO 8601 format

### Response Fields (GET)

| Field | Type | Description |
|-------|------|-------------|
| id | string | Unique lead ID |
| lead_name | string | Customer name |
| phone_number | string | Phone number |
| store | string | Store location |
| lead_type | string | Type of lead |
| call_status | string | Current call status |
| lead_status | string | Current lead status |
| function_date | datetime | Event date |
| created_at | datetime | Creation timestamp |
| follow_up_date | datetime | Follow-up date |
| follow_up_flag | boolean | Is follow-up scheduled |
| remarks | string | Notes/remarks |
| call_duration | integer | Call duration (seconds) |
| sub_category | string | Sub-category |
| closing_action | string | Closing action |
| booking_number | string | Booking reference |
| assigned_to | string | Assigned user |

---

## Common Scenarios

### Scenario 1: User Calls and is Interested
```json
{
  "call_status": "Interested",
  "lead_status": "Interested",
  "call_duration": 180,
  "remarks": "Customer interested, will call back next week"
}
```

### Scenario 2: User Calls but Not Interested
```json
{
  "call_status": "Not Interested",
  "lead_status": "Not Interested",
  "call_duration": 45,
  "remarks": "Customer not interested in current offerings"
}
```

### Scenario 3: Call Back Later
```json
{
  "call_status": "Call Back Later",
  "lead_status": "No Status",
  "call_duration": 60,
  "remarks": "Customer busy, will call back tomorrow",
  "follow_up_date": "2026-01-23T10:00:00.000Z"
}
```

### Scenario 4: Unanswered Call
```json
{
  "call_status": "Not Connected",
  "lead_status": "No Status",
  "call_duration": 0,
  "remarks": "Call not answered"
}
```

---

## Error Codes

| Code | Error | Solution |
|------|-------|----------|
| 200 | OK | Success |
| 400 | Bad Request | Check required fields |
| 401 | Unauthorized | Re-login |
| 403 | Forbidden | No permission |
| 404 | Not Found | Invalid lead ID |
| 500 | Server Error | Retry later |

---

## Implementation Checklist

- [ ] Fetch lead details on screen load
- [ ] Display all lead information
- [ ] Implement call functionality
- [ ] Capture call duration
- [ ] Show form after call
- [ ] Validate required fields
- [ ] Send POST request with call data
- [ ] Show success/error message
- [ ] Pop back to list on success
- [ ] Handle errors gracefully

---

## Date Format Examples

### Valid Formats
```
2026-01-28T00:00:00.000Z
2026-01-28T10:30:45.123Z
2026-01-28T23:59:59.999Z
```

### Invalid Formats (Don't Use)
```
01/28/2026          ❌
28-01-2026          ❌
2026-01-28          ❌ (missing time)
2026-01-28 10:30    ❌ (wrong format)
```

---

## Frontend Implementation

### In LeadScreenController
```dart
Future<void> updateFollowUpLead({
  required String id,
  String? callStatus,
  String? remarks,
  int? callDuration,
}) async {
  await _repository.updateFollowUpLeadFromApi(
    id: id,
    callStatus: callStatus,
    remarks: remarks,
    callDuration: callDuration,
    clearFollowUpDate: false,
  );
}
```

### In FollowupDetailScreen
```dart
// After call ends
await leadController.updateFollowUpLead(
  id: widget.lead.id,
  callStatus: _selectedClosingAction,
  remarks: _remarksController.text.isNotEmpty 
    ? _remarksController.text 
    : null,
  callDuration: _callDuration > 0 ? _callDuration : null,
);
```

---

## Best Practices

1. ✅ Always include call_duration (even if 0)
2. ✅ Trim remarks before sending
3. ✅ Use ISO 8601 date format
4. ✅ Validate before sending
5. ✅ Show loading indicator
6. ✅ Handle errors gracefully
7. ✅ Show success message
8. ✅ Pop back after success

---

## Troubleshooting

### Issue: 400 Bad Request
**Solution**: Check that `call_status` and `lead_status` are provided

### Issue: 401 Unauthorized
**Solution**: Token expired, user needs to re-login

### Issue: 404 Not Found
**Solution**: Lead ID is incorrect or lead was deleted

### Issue: Call duration not captured
**Solution**: Ensure CallTrackingController is initialized and listening

### Issue: Form not appearing after call
**Solution**: Check that `_hasCalled` state is being updated

---

## Testing with Postman

1. Set Authorization header: `Bearer {token}`
2. Set Content-Type: `application/json`
3. Use POST method for updates
4. Include all required fields
5. Use ISO 8601 dates
6. Check response status code

---

## API Rate Limits

- No specific rate limits documented
- Recommended: Max 10 requests per second
- Cache responses when possible
- Implement exponential backoff for retries

---

## Support

For API issues:
1. Check error message
2. Verify authentication token
3. Validate request format
4. Check backend logs
5. Contact API support team
