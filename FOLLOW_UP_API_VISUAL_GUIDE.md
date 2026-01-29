# Follow-Up API Visual Guide

## API Endpoints at a Glance

```
┌─────────────────────────────────────────────────────────────────┐
│                    FOLLOW-UP API ENDPOINTS                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. GET /api/pages/follow-ups                                  │
│     └─ List all follow-up leads                                │
│        └─ Returns: Array of leads                              │
│                                                                 │
│  2. GET /api/pages/follow-ups/{id}                             │
│     └─ Get single follow-up lead                               │
│        └─ Returns: Single lead object                          │
│                                                                 │
│  3. POST /api/pages/follow-ups/{id}                            │
│     └─ Update follow-up lead after call                        │
│        └─ Returns: Updated lead object                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Request/Response Structure

### GET Request
```
┌──────────────────────────────────────┐
│  GET /api/pages/follow-ups/{id}      │
├──────────────────────────────────────┤
│  Headers:                            │
│  • Authorization: Bearer {token}     │
│  • Content-Type: application/json    │
│                                      │
│  No Body Required                    │
└──────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  Response (200 OK)                   │
├──────────────────────────────────────┤
│  {                                   │
│    "id": "...",                      │
│    "lead_name": "...",               │
│    "phone_number": "...",            │
│    "call_status": "...",             │
│    "lead_status": "...",             │
│    "call_duration": 0,               │
│    "remarks": "...",                 │
│    ...                               │
│  }                                   │
└──────────────────────────────────────┘
```

### POST Request
```
┌──────────────────────────────────────┐
│  POST /api/pages/follow-ups/{id}     │
├──────────────────────────────────────┤
│  Headers:                            │
│  • Authorization: Bearer {token}     │
│  • Content-Type: application/json    │
│                                      │
│  Body (JSON):                        │
│  {                                   │
│    "call_status": "Interested",      │
│    "lead_status": "Interested",      │
│    "call_duration": 120,             │
│    "remarks": "Customer interested"  │
│  }                                   │
└──────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  Response (200 OK)                   │
├──────────────────────────────────────┤
│  {                                   │
│    "id": "...",                      │
│    "call_status": "Interested",      │
│    "lead_status": "Interested",      │
│    "call_duration": 120,             │
│    "remarks": "Customer interested", │
│    "updated_at": "2026-01-22T..."    │
│  }                                   │
└──────────────────────────────────────┘
```

---

## Field Categories

### Required Fields (POST Only)
```
┌─────────────────────────────────────┐
│  REQUIRED FIELDS                    │
├─────────────────────────────────────┤
│                                     │
│  call_status ⭐                     │
│  ├─ "Interested"                    │
│  ├─ "Not Interested"                │
│  ├─ "Call Back Later"               │
│  ├─ "Connected"                     │
│  └─ "Not Connected"                 │
│                                     │
│  lead_status ⭐                     │
│  ├─ "Interested"                    │
│  ├─ "Not Interested"                │
│  └─ "No Status"                     │
│                                     │
└─────────────────────────────────────┘
```

### Optional Fields (POST)
```
┌─────────────────────────────────────┐
│  OPTIONAL FIELDS                    │
├─────────────────────────────────────┤
│                                     │
│  call_duration (integer)            │
│  └─ Duration in seconds             │
│     Example: 120 (2 minutes)        │
│     Include even if 0               │
│                                     │
│  remarks (string)                   │
│  └─ Notes about the call            │
│     Example: "Customer interested"  │
│     Max 500 characters              │
│                                     │
│  follow_up_date (datetime)          │
│  └─ Next follow-up date             │
│     Format: ISO 8601                │
│     Example: "2026-01-28T..."       │
│                                     │
└─────────────────────────────────────┘
```

### Response Fields (GET)
```
┌─────────────────────────────────────┐
│  RESPONSE FIELDS                    │
├─────────────────────────────────────┤
│                                     │
│  Customer Info:                     │
│  • id                               │
│  • lead_name                        │
│  • phone_number                     │
│  • store                            │
│                                     │
│  Call Info:                         │
│  • call_status                      │
│  • lead_status                      │
│  • call_duration                    │
│  • remarks                          │
│                                     │
│  Dates:                             │
│  • function_date                    │
│  • created_at                       │
│  • follow_up_date                   │
│  • follow_up_flag                   │
│                                     │
│  Other:                             │
│  • lead_type                        │
│  • sub_category                     │
│  • closing_action                   │
│  • booking_number                   │
│                                     │
└─────────────────────────────────────┘
```

---

## Call Status Options

```
┌──────────────────────────────────────────────────────────┐
│                  CALL STATUS OPTIONS                     │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ✅ "Interested"                                        │
│     └─ Customer is interested in the product/service   │
│                                                          │
│  ❌ "Not Interested"                                    │
│     └─ Customer is not interested                      │
│                                                          │
│  ⏰ "Call Back Later"                                   │
│     └─ Customer wants to be called back later          │
│                                                          │
│  📞 "Connected"                                         │
│     └─ Call was successfully connected                 │
│                                                          │
│  ❌ "Not Connected"                                    │
│     └─ Call was not connected (unanswered)             │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## Lead Status Options

```
┌──────────────────────────────────────────────────────────┐
│                   LEAD STATUS OPTIONS                    │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ✅ "Interested"                                        │
│     └─ Lead is interested                              │
│                                                          │
│  ❌ "Not Interested"                                    │
│     └─ Lead is not interested                          │
│                                                          │
│  ❓ "No Status"                                         │
│     └─ Status not yet determined                       │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│              FOLLOW-UP DETAIL SCREEN                    │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │  GET /api/pages/follow-ups/{id}│
        │  Fetch lead details            │
        └────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │  Display Lead Information      │
        │  • Name, Phone, Location       │
        │  • Function Date, Category     │
        │  • Closing Action, Remarks     │
        │  • "Call Now" Button           │
        └────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │  User Clicks "Call Now"        │
        └────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │  Phone Call Made               │
        │  • Call duration tracked       │
        │  • Call ends                   │
        └────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │  Show Form Fields              │
        │  • Close Action (required)     │
        │  • Call Remarks (optional)     │
        │  • Save Button                 │
        └────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │  User Fills Form & Clicks Save │
        └────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │  POST /api/pages/follow-ups/{id}
        │  Update with call information  │
        │  • call_status                 │
        │  • lead_status                 │
        │  • call_duration               │
        │  • remarks                     │
        └────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │  Response: 200 OK              │
        │  Lead updated successfully     │
        └────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │  Show Success Message          │
        │  Pop back to Follow-Up List    │
        └────────────────────────────────┘
```

---

## Date Format Comparison

```
┌──────────────────────────────────────────────────────────┐
│                    DATE FORMATS                          │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ✅ CORRECT (ISO 8601)                                  │
│     2026-01-28T00:00:00.000Z                            │
│     2026-01-28T10:30:45.123Z                            │
│     2026-01-28T23:59:59.999Z                            │
│                                                          │
│  ❌ INCORRECT                                           │
│     01/28/2026          (US format)                     │
│     28-01-2026          (EU format)                     │
│     2026-01-28          (missing time)                  │
│     2026-01-28 10:30    (wrong separator)               │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## Error Handling Flow

```
┌─────────────────────────────────────┐
│  POST /api/pages/follow-ups/{id}    │
└─────────────────────────────────────┘
              │
    ┌─────────┼─────────┬──────────┐
    │         │         │          │
    ▼         ▼         ▼          ▼
  ┌───┐   ┌───┐   ┌───┐   ┌──────────┐
  │200│   │400│   │401│   │403/404  │
  │OK │   │Bad│   │Auth│  │Error    │
  └───┘   │Req│   │Err│   └──────────┘
    │     └───┘   └───┘        │
    │       │       │          │
    ▼       ▼       ▼          ▼
  Success  Check  Re-login   Show
  Message  Fields Required   Error
  Pop Back Show    Show      Message
           Error   Error
```

---

## Implementation Checklist

```
┌─────────────────────────────────────────────────────────┐
│              IMPLEMENTATION CHECKLIST                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  □ Fetch lead details on screen load                   │
│  □ Display all lead information                        │
│  □ Implement call functionality                        │
│  □ Capture call duration                               │
│  □ Show form after call                                │
│  □ Validate required fields                            │
│  □ Send POST request with call data                    │
│  □ Show loading indicator                              │
│  □ Show success/error message                          │
│  □ Pop back to list on success                         │
│  □ Handle errors gracefully                            │
│  □ Trim remarks before sending                         │
│  □ Include call_duration even if 0                     │
│  □ Use ISO 8601 date format                            │
│  □ Test all scenarios                                  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Quick Reference Table

| Aspect | Details |
|--------|---------|
| **Base URL** | `https://api.example.com` |
| **List Endpoint** | `GET /api/pages/follow-ups` |
| **Get Endpoint** | `GET /api/pages/follow-ups/{id}` |
| **Update Endpoint** | `POST /api/pages/follow-ups/{id}` |
| **Auth** | Bearer token in Authorization header |
| **Content-Type** | application/json |
| **Required Fields** | call_status, lead_status |
| **Optional Fields** | call_duration, remarks, follow_up_date |
| **Date Format** | ISO 8601 (e.g., 2026-01-28T00:00:00.000Z) |
| **Call Duration** | In seconds (0 for unanswered) |
| **Success Code** | 200 OK |
| **Error Codes** | 400, 401, 403, 404, 500 |

---

## Summary

The Follow-Up API is simple and follows REST conventions:

1. **GET** to fetch lead details
2. **POST** to update after call
3. **Required**: call_status, lead_status
4. **Optional**: call_duration, remarks
5. **Always include**: call_duration (even if 0)
6. **Date format**: ISO 8601
7. **Error handling**: Show user-friendly messages
8. **Success**: Pop back to list

That's all you need to know!
