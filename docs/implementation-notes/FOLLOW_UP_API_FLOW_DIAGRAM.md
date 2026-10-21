# Follow-Up API Flow Diagram

## Complete Follow-Up Call Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    FOLLOW-UP DETAIL SCREEN                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  User Opens Lead │
                    └──────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │  GET /api/pages/follow-ups/{id}         │
        │  Fetch lead details                     │
        │  Response: Lead data with all fields    │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │  Display Lead Information:              │
        │  - Name, Phone, Location                │
        │  - Function Date, Sub Category          │
        │  - Closing Action, Remarks              │
        │  - "Call Now" Button                    │
        └─────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ User Clicks Call │
                    │     Now Button   │
                    └──────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │  PhoneCallService.makeCall()            │
        │  - Initiates phone call                 │
        │  - Tracks call duration                 │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │  Call Ends                              │
        │  - Call duration captured               │
        │  - UI transitions to form               │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │  Display Form Fields:                   │
        │  - Call Duration (auto-filled)          │
        │  - Close Action Dropdown (required)     │
        │  - Call Remarks Text Field (optional)   │
        │  - Cancel & Save Buttons                │
        └─────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ User Fills Form  │
                    │ & Clicks Save    │
                    └──────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │  POST /api/pages/follow-ups/{id}        │
        │  Update lead with call information      │
        │                                         │
        │  Request Body:                          │
        │  {                                      │
        │    "call_status": "Interested",         │
        │    "lead_status": "Interested",         │
        │    "call_duration": 120,                │
        │    "remarks": "Customer interested"     │
        │  }                                      │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │  Response: 200 OK                       │
        │  Lead updated successfully              │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │  Show Success Message                   │
        │  Pop back to Follow-Up List             │
        └─────────────────────────────────────────┘
```

---

## API Request/Response Details

### 1. GET Single Follow-Up Lead

```
REQUEST:
┌─────────────────────────────────────────┐
│ GET /api/pages/follow-ups/{id}          │
│ Headers:                                │
│   Authorization: Bearer {token}         │
│   Content-Type: application/json        │
└─────────────────────────────────────────┘

RESPONSE (200 OK):
┌─────────────────────────────────────────┐
│ {                                       │
│   "id": "69722c0ef6c1bce8019f7e98",    │
│   "lead_name": "Abhiram S Kumar",       │
│   "phone_number": "9876543210",         │
│   "store": "Suitor Guy - Perumbavoor",  │
│   "lead_type": "follow-up",             │
│   "call_status": "Not Called",          │
│   "lead_status": "No Status",           │
│   "function_date": "2026-01-17T...",    │
│   "created_at": "2026-01-22T...",       │
│   "follow_up_date": "2026-01-25T...",   │
│   "follow_up_flag": true,               │
│   "remarks": "Interested in suite",     │
│   "call_duration": 0,                   │
│   "sub_category": "Interested",         │
│   "closing_action": "Interested"        │
│ }                                       │
└─────────────────────────────────────────┘
```

### 2. POST Update Follow-Up Lead

```
REQUEST:
┌─────────────────────────────────────────┐
│ POST /api/pages/follow-ups/{id}         │
│ Headers:                                │
│   Authorization: Bearer {token}         │
│   Content-Type: application/json        │
│                                         │
│ Body:                                   │
│ {                                       │
│   "call_status": "Interested",          │
│   "lead_status": "Interested",          │
│   "call_duration": 120,                 │
│   "remarks": "Very interested"          │
│ }                                       │
└─────────────────────────────────────────┘

RESPONSE (200 OK):
┌─────────────────────────────────────────┐
│ {                                       │
│   "id": "69722c0ef6c1bce8019f7e98",    │
│   "lead_name": "Abhiram S Kumar",       │
│   "call_status": "Interested",          │
│   "lead_status": "Interested",          │
│   "call_duration": 120,                 │
│   "remarks": "Very interested",         │
│   "updated_at": "2026-01-22T10:30:00Z"  │
│ }                                       │
└─────────────────────────────────────────┘
```

---

## Field Mapping

### Call Status Values
```
┌──────────────────────┐
│  Call Status Options │
├──────────────────────┤
│ • Interested         │
│ • Not Interested     │
│ • Call Back Later    │
│ • Connected          │
│ • Not Connected      │
└──────────────────────┘
```

### Lead Status Values
```
┌──────────────────────┐
│  Lead Status Options │
├──────────────────────┤
│ • Interested         │
│ • Not Interested     │
│ • No Status          │
└──────────────────────┘
```

---

## Data Flow in Frontend

```
┌──────────────────────────────────────────────────────────┐
│                   FollowupDetailScreen                   │
│                                                          │
│  State Variables:                                        │
│  - _hasCalled: bool (tracks if call made)               │
│  - _callDuration: int (in seconds)                      │
│  - _selectedClosingAction: string                       │
│  - _remarksController: TextEditingController            │
│  - _isSaving: bool (tracks save state)                  │
└──────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────┐
│                   LeadScreenController                   │
│                                                          │
│  updateFollowUpLead({                                   │
│    id: String,                                          │
│    callStatus: String?,                                 │
│    remarks: String?,                                    │
│    callDuration: int?                                   │
│  })                                                      │
└──────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────┐
│                    LeadRepository                        │
│                                                          │
│  updateFollowUpLeadFromApi({                            │
│    id: String,                                          │
│    callStatus: String?,                                 │
│    remarks: String?,                                    │
│    callDuration: int?,                                  │
│    clearFollowUpDate: bool                              │
│  })                                                      │
└──────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────┐
│                     ApiService                          │
│                                                          │
│  postFollowUp({                                         │
│    id: String,                                          │
│    callStatus: String,                                  │
│    leadStatus: String,                                  │
│    remarks: String?,                                    │
│    callDuration: int?,                                  │
│    clearFollowUpDate: bool                              │
│  })                                                      │
│                                                          │
│  POST /api/pages/follow-ups/{id}                        │
└──────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │   Backend API    │
                    │  Updates Lead    │
                    └──────────────────┘
```

---

## Error Handling Flow

```
┌─────────────────────────────────────────┐
│  POST /api/pages/follow-ups/{id}        │
└─────────────────────────────────────────┘
                    │
        ┌───────────┼───────────┐
        │           │           │
        ▼           ▼           ▼
    ┌─────┐   ┌─────┐   ┌─────────┐
    │ 200 │   │ 400 │   │ 401/403 │
    │ OK  │   │Bad  │   │ Auth    │
    └─────┘   │Req  │   │Error    │
        │     └─────┘   └─────────┘
        │         │           │
        ▼         ▼           ▼
    Success   Validation   Re-login
    Message   Error Msg    Required
    Pop Back  Show Error   Show Error
```

---

## Summary

1. **GET /api/pages/follow-ups/{id}**: Fetch lead details
2. **POST /api/pages/follow-ups/{id}**: Update lead with call info
3. **Required Fields**: call_status, lead_status
4. **Optional Fields**: call_duration, remarks, follow_up_date
5. **Date Format**: ISO 8601 (e.g., "2026-01-28T00:00:00.000Z")
6. **Call Duration**: In seconds (0 for unanswered)
7. **Error Handling**: Show user-friendly messages
