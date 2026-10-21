# Follow-Up API Summary

## Overview
The Follow-Up API manages follow-up leads in the telecaller application. It provides three main endpoints for fetching and updating follow-up leads.

---

## Three Main Endpoints

### 1. GET /api/pages/follow-ups
**List all follow-up leads**
- Fetches all follow-up leads for the authenticated user
- Optional filters: store, limit
- Returns array of lead objects

### 2. GET /api/pages/follow-ups/{id}
**Get single follow-up lead details**
- Fetches detailed information for a specific lead
- Returns complete lead object with all fields

### 3. POST /api/pages/follow-ups/{id}
**Update follow-up lead after call**
- Updates lead with call information
- Required: call_status, lead_status
- Optional: call_duration, remarks, follow_up_date

---

## Key Fields Explained

### Required Fields (POST)
1. **call_status**: How the call went
   - "Interested" - Customer interested
   - "Not Interested" - Customer not interested
   - "Call Back Later" - Need to call back
   - "Connected" - Call connected
   - "Not Connected" - Call not connected

2. **lead_status**: Overall lead status
   - "Interested" - Lead is interested
   - "Not Interested" - Lead not interested
   - "No Status" - No status yet

### Optional Fields (POST)
1. **call_duration**: How long the call lasted (in seconds)
   - Include even if 0 (0 = unanswered call)
   - Example: 120 (2 minutes)

2. **remarks**: Notes about the call
   - What customer said
   - Any important information
   - Max 500 characters

3. **follow_up_date**: When to follow up next
   - ISO 8601 format: "2026-01-28T00:00:00.000Z"
   - Optional scheduling

### Response Fields (GET)
- **id**: Unique lead identifier
- **lead_name**: Customer name
- **phone_number**: Customer phone
- **store**: Store location
- **lead_type**: Type of lead
- **call_status**: Current call status
- **lead_status**: Current lead status
- **function_date**: Event date
- **created_at**: When lead was created
- **follow_up_date**: Scheduled follow-up date
- **follow_up_flag**: Is follow-up scheduled
- **remarks**: Notes/remarks
- **call_duration**: Call duration in seconds
- **sub_category**: Sub-category
- **closing_action**: Closing action taken

---

## Complete Flow

```
1. User opens follow-up lead
   ↓
2. GET /api/pages/follow-ups/{id}
   ↓
3. Display lead information
   ↓
4. User clicks "Call Now"
   ↓
5. Phone call is made
   ↓
6. Call ends, duration captured
   ↓
7. User fills form:
   - Select closing action (required)
   - Add remarks (optional)
   ↓
8. User clicks "Save"
   ↓
9. POST /api/pages/follow-ups/{id}
   Body: {
     "call_status": "Interested",
     "lead_status": "Interested",
     "call_duration": 120,
     "remarks": "Customer interested"
   }
   ↓
10. Response: 200 OK
    ↓
11. Show success message
    ↓
12. Pop back to list
```

---

## Request/Response Examples

### GET Single Lead
```
Request:
GET /api/pages/follow-ups/69722c0ef6c1bce8019f7e98
Authorization: Bearer {token}

Response (200):
{
  "id": "69722c0ef6c1bce8019f7e98",
  "lead_name": "Abhiram S Kumar",
  "phone_number": "9876543210",
  "call_status": "Not Called",
  "lead_status": "No Status",
  "follow_up_date": "2026-01-25T00:00:00.000Z"
}
```

### POST Update Lead
```
Request:
POST /api/pages/follow-ups/69722c0ef6c1bce8019f7e98
Authorization: Bearer {token}
Content-Type: application/json

{
  "call_status": "Interested",
  "lead_status": "Interested",
  "call_duration": 120,
  "remarks": "Customer very interested"
}

Response (200):
{
  "id": "69722c0ef6c1bce8019f7e98",
  "call_status": "Interested",
  "lead_status": "Interested",
  "call_duration": 120,
  "remarks": "Customer very interested",
  "updated_at": "2026-01-22T10:30:00.000Z"
}
```

---

## Important Notes

1. **Always include call_duration**: Even if 0, it's important for reporting
2. **Trim remarks**: Remove leading/trailing whitespace
3. **Use ISO 8601 dates**: Format: "2026-01-28T00:00:00.000Z"
4. **Required fields**: call_status and lead_status are REQUIRED
5. **Optional fields**: Only include if user provided data
6. **Error handling**: Show user-friendly error messages
7. **Loading state**: Show spinner during API call
8. **Success message**: Confirm to user after save

---

## Common Scenarios

### Scenario 1: Interested Customer
```json
{
  "call_status": "Interested",
  "lead_status": "Interested",
  "call_duration": 180,
  "remarks": "Customer interested, will call back next week"
}
```

### Scenario 2: Not Interested
```json
{
  "call_status": "Not Interested",
  "lead_status": "Not Interested",
  "call_duration": 45,
  "remarks": "Customer not interested"
}
```

### Scenario 3: Unanswered Call
```json
{
  "call_status": "Not Connected",
  "lead_status": "No Status",
  "call_duration": 0,
  "remarks": "Call not answered"
}
```

---

## Error Handling

| Status | Meaning | Action |
|--------|---------|--------|
| 200 | Success | Show success message, pop back |
| 400 | Bad Request | Check required fields |
| 401 | Unauthorized | Re-login |
| 403 | Forbidden | Show permission error |
| 404 | Not Found | Show lead not found error |
| 500 | Server Error | Retry or show error |

---

## Frontend Implementation

### Controller Method
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

### UI Implementation
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

## Date Format

### Correct Format (ISO 8601)
```
2026-01-28T00:00:00.000Z
2026-01-28T10:30:45.123Z
```

### Incorrect Formats
```
01/28/2026          ❌
28-01-2026          ❌
2026-01-28          ❌
```

---

## Best Practices Checklist

- ✅ Validate required fields before sending
- ✅ Show loading indicator during API call
- ✅ Include call_duration even if 0
- ✅ Trim remarks before sending
- ✅ Use ISO 8601 date format
- ✅ Handle errors gracefully
- ✅ Show success message
- ✅ Pop back after successful save
- ✅ Cache responses when possible
- ✅ Implement retry logic for failures

---

## Summary

The Follow-Up API is straightforward:
1. **GET** to fetch lead details
2. **POST** to update after call
3. **Required**: call_status, lead_status
4. **Optional**: call_duration, remarks
5. **Always include**: call_duration (even if 0)
6. **Date format**: ISO 8601
7. **Error handling**: Show user-friendly messages
8. **Success**: Pop back to list

That's it! The API is simple and follows REST conventions.
