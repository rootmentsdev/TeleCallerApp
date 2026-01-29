# POST Follow-Up Lead - Complete Request Fields

## Endpoint
```
POST /api/pages/follow-ups/{id}
Authorization: Bearer {token}
Content-Type: application/json
```

---

## Request Body - All Fields

### Complete JSON Structure

```json
{
  "call_status": "Interested",
  "lead_status": "Interested",
  "call_duration": 180,
  "remarks": "Customer very interested in the service",
  "follow_up_flag": true,
  "follow_up_date": "2026-01-28T00:00:00.000Z",
  "mark_as_complaint": false,
  "rating": 5,
  "sub_category": "Product Quality Issue",
  "service": "Excellent",
  "number_of_functions": "2",
  "number_of_attires": "4",
  "competitor": "Brand XYZ"
}
```

---

## Field Descriptions

### Required Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `call_status` | String | Status of the call | "Interested", "Not Interested", "Connected", "Not Connected", "Call Back Later" |
| `lead_status` | String | Overall lead status | "Interested", "Not Interested", "No Status" |

---

### Optional Fields

| Field | Type | Description | Example | Notes |
|-------|------|-------------|---------|-------|
| `call_duration` | Number | Duration of call in seconds | 180 | Include even if 0 for unanswered calls |
| `remarks` | String | Notes/remarks about the call | "Customer interested, will call back next week" | Max 500 characters, trimmed |
| `follow_up_flag` | Boolean | Whether to schedule follow-up | true | Required if follow_up_date is provided |
| `follow_up_date` | String (ISO 8601) | When to follow up next | "2026-01-28T00:00:00.000Z" | Format: YYYY-MM-DDTHH:mm:ss.sssZ |
| `mark_as_complaint` | Boolean | Mark as complaint | false | If true, moves to Complaints section |
| `rating` | Number | Customer satisfaction rating | 5 | Range: 1-5 (only if not marked as complaint) |
| `sub_category` | String | Complaint sub-category | "Product Quality Issue" | Only if mark_as_complaint is true |
| `service` | String | Service quality rating | "Excellent" | Options: "Excellent", "Average", "Not satisfied" |
| `number_of_functions` | String | Number of functions | "2" | Numeric string |
| `number_of_attires` | String | Number of attires | "4" | Numeric string |
| `competitor` | String | Competitor name | "Brand XYZ" | Optional competitor information |

---

## Complete Request Examples

### Example 1: Interested Customer with Follow-up

```json
{
  "call_status": "Interested",
  "lead_status": "Interested",
  "call_duration": 180,
  "remarks": "Customer very interested in the service",
  "follow_up_flag": true,
  "follow_up_date": "2026-01-28T00:00:00.000Z",
  "service": "Excellent",
  "number_of_functions": "2",
  "number_of_attires": "4"
}
```

### Example 2: Complaint with Sub-Category

```json
{
  "call_status": "Not Connected",
  "lead_status": "No Status",
  "call_duration": 0,
  "remarks": "Call not answered",
  "mark_as_complaint": true,
  "sub_category": "Product Quality Issue",
  "service": "Not satisfied"
}
```

### Example 3: Satisfied Customer with Rating

```json
{
  "call_status": "Connected",
  "lead_status": "Interested",
  "call_duration": 240,
  "remarks": "Customer satisfied with service",
  "rating": 5,
  "service": "Excellent",
  "number_of_functions": "3",
  "number_of_attires": "5",
  "competitor": "Brand ABC"
}
```

### Example 4: Minimal Request (Only Required Fields)

```json
{
  "call_status": "Not Interested",
  "lead_status": "Not Interested",
  "call_duration": 45
}
```

---

## Response (200 OK)

```json
{
  "id": "69722c0ef6c1bce8019f7e98",
  "lead_name": "Abhiram S Kumar",
  "phone_number": "9876543210",
  "call_status": "Interested",
  "lead_status": "Interested",
  "call_duration": 180,
  "remarks": "Customer very interested in the service",
  "follow_up_flag": true,
  "follow_up_date": "2026-01-28T00:00:00.000Z",
  "mark_as_complaint": false,
  "rating": 5,
  "sub_category": null,
  "service": "Excellent",
  "number_of_functions": "2",
  "number_of_attires": "4",
  "competitor": null,
  "updated_at": "2026-01-23T10:30:00.000Z"
}
```

---

## Routing Logic

After POST request, the lead is routed based on these conditions:

```
IF mark_as_complaint = true
  → Move to Complaints section
ELSE IF follow_up_flag = true AND follow_up_date is provided
  → Stay in Follow-Ups section (scheduled for follow-up date)
ELSE
  → Move to Reports section (considered complete)
```

---

## Validation Rules

1. **call_status** - Required, must be one of the predefined values
2. **lead_status** - Required, must be one of the predefined values
3. **call_duration** - Should be >= 0 (include even if 0)
4. **remarks** - Optional, max 500 characters, trimmed
5. **follow_up_date** - Must be ISO 8601 format if provided
6. **rating** - Must be 1-5 if provided
7. **service** - Must be one of: "Excellent", "Average", "Not satisfied"
8. **number_of_functions** - Numeric string
9. **number_of_attires** - Numeric string
10. **competitor** - Optional text field

---

## Important Notes

- ✅ Always include `call_duration` (even if 0)
- ✅ Trim `remarks` before sending
- ✅ Use ISO 8601 date format for `follow_up_date`
- ✅ Only send fields that have values (omit null/empty fields)
- ✅ `rating` should only be sent if `mark_as_complaint` is false
- ✅ `sub_category` should only be sent if `mark_as_complaint` is true
- ✅ `follow_up_date` is required if `follow_up_flag` is true

---

## Error Responses

### 400 Bad Request
```json
{
  "error": "Invalid request",
  "message": "call_status is required"
}
```

### 401 Unauthorized
```json
{
  "error": "Unauthorized",
  "message": "Authentication token expired"
}
```

### 404 Not Found
```json
{
  "error": "Not Found",
  "message": "Lead with ID 69722c0ef6c1bce8019f7e98 not found"
}
```

### 500 Server Error
```json
{
  "error": "Internal Server Error",
  "message": "An unexpected error occurred"
}
```

---

## Summary

**Required Fields:**
- `call_status`
- `lead_status`

**Always Include:**
- `call_duration` (even if 0)

**Conditional Fields:**
- `rating` - Only if not marking as complaint
- `sub_category` - Only if marking as complaint
- `follow_up_date` - Required if `follow_up_flag` is true

**New Fields (Added):**
- `service` - Service quality rating
- `number_of_functions` - Number of functions
- `number_of_attires` - Number of attires
- `competitor` - Competitor name

**Date Format:**
- ISO 8601: `2026-01-28T00:00:00.000Z`

