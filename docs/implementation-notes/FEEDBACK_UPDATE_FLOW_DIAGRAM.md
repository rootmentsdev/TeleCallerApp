# Feedback Update Flow - Visual Diagrams

## Current (BROKEN) Flow - Outgoing Call

```
┌──────────────────────────────────────────────────────────────────────┐
│                    OUTGOING CALL FEEDBACK FLOW                       │
│                         (CURRENTLY BROKEN)                           │
└──────────────────────────────────────────────────────────────────────┘

USER INTERFACE
┌─────────────────────────────────────────────────────────────────────┐
│ Outgoing Call Bottom Sheet                                          │
│                                                                     │
│ [Call Now Button]                                                   │
│                                                                     │
│ After Call:                                                         │
│ ┌─────────────────────────────────────────────────────────────┐   │
│ │ Call Status: [Connected ▼]                                 │   │
│ │ Remarks: [Customer interested in product]                  │   │
│ │ Call Duration: 00:45 Mins                                  │   │
│ │ Mark as Complaint: [☐]                                     │   │
│ │ Sub Category: [Product Enquiry ▼]                          │   │
│ │ Item Category: [Suit ▼]                                    │   │
│ │ Number of Functions: [2]                                   │   │
│ │ Number of Attires: [5]                                     │   │
│ │ Competitor: [XYZ Store]                                    │   │
│ │ Service: [Excellent ▼]                                     │   │
│ │                                                             │   │
│ │ [Cancel]  [Save Lead]                                      │   │
│ └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
                    User clicks "Save Lead"
                              ↓
FRONTEND LOGIC
┌─────────────────────────────────────────────────────────────────────┐
│ _saveLead() method                                                  │
│                                                                     │
│ 1. Validate form                                                    │
│ 2. Call apiService.createLead()                                    │
│    ├─ Sends: name, phone, store, leadType, remarks                │
│    ├─ Sends: functionDate, callDuration, subCategory              │
│    ├─ Sends: itemCategory, closingAction, markAsComplaint         │
│    ├─ Sends: callStatus, followUpFlag, followUpDate               │
│    └─ ✅ All fields sent to createLead()                          │
│                                                                     │
│ 3. Extract leadId from response                                    │
│                                                                     │
│ 4. ❌ MISSING: No call to updateReturnLead()                      │
│    ❌ MISSING: Feedback is not saved!                             │
│                                                                     │
│ 5. Add lead to local repository                                    │
│ 6. Close screen                                                    │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
BACKEND API
┌─────────────────────────────────────────────────────────────────────┐
│ POST /api/lead/create                                               │
│                                                                     │
│ Request Body:                                                       │
│ {                                                                   │
│   "name": "John Doe",                                              │
│   "phone": "9876543210",                                           │
│   "store": "suitor guy-edappally",                                 │
│   "leadType": "enquiry",                                           │
│   "remarks": "Customer interested in product",                     │
│   "functionDate": "2026-04-10T00:00:00Z",                         │
│   "callDuration": 45,                                              │
│   "subCategory": "Product Enquiry",                                │
│   "itemCategory": "Suit",                                          │
│   "closingAction": "Connected to store",                           │
│   "markAsComplaint": false,                                        │
│   "callStatus": "Connected",                                       │
│   "followUpFlag": false,                                           │
│   "source": "Outgoing Call"                                        │
│ }                                                                   │
│                                                                     │
│ Response:                                                           │
│ {                                                                   │
│   "success": true,                                                 │
│   "lead": {                                                        │
│     "_id": "69c763f59767fbce256df30d",                            │
│     "name": "John Doe",                                            │
│     "phone": "9876543210",                                         │
│     ...                                                            │
│   }                                                                │
│ }                                                                   │
│                                                                     │
│ ✅ Lead created successfully                                       │
│ ❌ But feedback fields are NOT saved!                             │
│    (They were sent to createLead, not updateReturnLead)           │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
DATABASE
┌─────────────────────────────────────────────────────────────────────┐
│ Lead Document:                                                      │
│ {                                                                   │
│   "_id": "69c763f59767fbce256df30d",                              │
│   "name": "John Doe",                                              │
│   "phone": "9876543210",                                           │
│   "store": "suitor guy-edappally",                                 │
│   "leadType": "enquiry",                                           │
│   "remarks": "Customer interested in product",                     │
│   "functionDate": "2026-04-10T00:00:00Z",                         │
│   "callDuration": 45,                                              │
│   "subCategory": "Product Enquiry",                                │
│   "itemCategory": "Suit",                                          │
│   "closingAction": "Connected to store",                           │
│   "markAsComplaint": false,                                        │
│   "callStatus": "Connected",                                       │
│   "createdAt": "2026-03-30T10:30:00Z",                            │
│   "updatedAt": "2026-03-30T10:30:00Z",                            │
│   "updatedBy": "Emp188",                                           │
│   "rating": null,  ← ❌ MISSING                                   │
│   "numberOfFunctions": null,  ← ❌ MISSING                        │
│   "numberOfAttires": null,  ← ❌ MISSING                          │
│   "competitor": null,  ← ❌ MISSING                               │
│   "service": null,  ← ❌ MISSING                                  │
│   "refundStatus": null  ← ❌ MISSING                              │
│ }                                                                   │
│                                                                     │
│ ❌ RESULT: Lead created but feedback is INCOMPLETE!               │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Fixed (CORRECT) Flow - Outgoing Call

```
┌──────────────────────────────────────────────────────────────────────┐
│                    OUTGOING CALL FEEDBACK FLOW                       │
│                         (AFTER FIX)                                  │
└──────────────────────────────────────────────────────────────────────┘

USER INTERFACE
┌─────────────────────────────────────────────────────────────────────┐
│ Outgoing Call Bottom Sheet                                          │
│ [Same form as before]                                               │
│ [Cancel]  [Save Lead]                                               │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
                    User clicks "Save Lead"
                              ↓
FRONTEND LOGIC
┌─────────────────────────────────────────────────────────────────────┐
│ _saveLead() method                                                  │
│                                                                     │
│ 1. Validate form                                                    │
│                                                                     │
│ 2. Call apiService.createLead()                                    │
│    └─ Creates new lead                                             │
│                                                                     │
│ 3. Extract leadId from response                                    │
│                                                                     │
│ 4. ✅ NEW: Call apiService.updateReturnLead()                      │
│    ├─ Sends: callStatus, rating, remarks, callDuration            │
│    ├─ Sends: markAsComplaint, subCategory, numberOfFunctions      │
│    ├─ Sends: numberOfAttires, competitor, service                 │
│    ├─ Sends: refundStatus, functionDate, leadType                 │
│    └─ ✅ All feedback fields sent!                                │
│                                                                     │
│ 5. Add lead to local repository                                    │
│ 6. Close screen                                                    │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
BACKEND API - STEP 1
┌─────────────────────────────────────────────────────────────────────┐
│ POST /api/lead/create                                               │
│ (Creates lead with basic info)                                      │
│                                                                     │
│ Response: { "_id": "69c763f59767fbce256df30d", ... }              │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
BACKEND API - STEP 2
┌─────────────────────────────────────────────────────────────────────┐
│ PUT /api/return/update/69c763f59767fbce256df30d                    │
│                                                                     │
│ Request Body:                                                       │
│ {                                                                   │
│   "call_status": "Connected",                                      │
│   "lead_status": "No Status",                                      │
│   "rating": 5,                                                     │
│   "remarks": "Customer interested in product",                     │
│   "call_duration": 45,                                             │
│   "mark_as_complaint": false,                                      │
│   "sub_category": "Product Enquiry",                               │
│   "no_of_functions": "2",                                          │
│   "no_of_attires": "5",                                            │
│   "competitor": "XYZ Store",                                       │
│   "service": "Excellent",                                          │
│   "refund_status": "Security Amount Refunded",                     │
│   "function_date": "2026-04-10T00:00:00Z",                        │
│   "lead_type": "enquiry"                                           │
│ }                                                                   │
│                                                                     │
│ ✅ All feedback fields sent!                                       │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
DATABASE
┌─────────────────────────────────────────────────────────────────────┐
│ Lead Document:                                                      │
│ {                                                                   │
│   "_id": "69c763f59767fbce256df30d",                              │
│   "name": "John Doe",                                              │
│   "phone": "9876543210",                                           │
│   "store": "suitor guy-edappally",                                 │
│   "leadType": "enquiry",                                           │
│   "remarks": "Customer interested in product",                     │
│   "functionDate": "2026-04-10T00:00:00Z",                         │
│   "callDuration": 45,                                              │
│   "subCategory": "Product Enquiry",                                │
│   "itemCategory": "Suit",                                          │
│   "closingAction": "Connected to store",                           │
│   "markAsComplaint": false,                                        │
│   "callStatus": "Connected",                                       │
│   "rating": 5,  ← ✅ SAVED                                        │
│   "numberOfFunctions": "2",  ← ✅ SAVED                           │
│   "numberOfAttires": "5",  ← ✅ SAVED                             │
│   "competitor": "XYZ Store",  ← ✅ SAVED                          │
│   "service": "Excellent",  ← ✅ SAVED                             │
│   "refundStatus": "Security Amount Refunded",  ← ✅ SAVED         │
│   "createdAt": "2026-03-30T10:30:00Z",                            │
│   "updatedAt": "2026-03-30T10:35:00Z",                            │
│   "updatedBy": "Emp188"                                            │
│ }                                                                   │
│                                                                     │
│ ✅ RESULT: Lead created with COMPLETE feedback!                   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## API Request Body Comparison

### Current (BROKEN) - updateReturnLead Request

```
PUT /api/return/update/69c763f59767fbce256df30d

{
  "call_status": "Connected",
  "lead_status": "No Status",
  "call_date": "2026-03-30T10:30:00Z",
  "rating": 5,
  "remarks": "Customer interested",
  "call_duration": 45,
  "follow_up_flag": false,
  "follow_up_date": null
}

❌ Missing 10 fields:
- sub_category
- item_category
- function_date
- lead_type
- mark_as_complaint
- no_of_functions
- no_of_attires
- competitor
- service
- refund_status
```

### Fixed (CORRECT) - updateReturnLead Request

```
PUT /api/return/update/69c763f59767fbce256df30d

{
  "call_status": "Connected",
  "lead_status": "No Status",
  "call_date": "2026-03-30T10:30:00Z",
  "rating": 5,
  "remarks": "Customer interested",
  "call_duration": 45,
  "follow_up_flag": false,
  "follow_up_date": null,
  "sub_category": "Product Enquiry",           ← ✅ ADDED
  "item_category": "Suit",                     ← ✅ ADDED
  "function_date": "2026-04-10T00:00:00Z",    ← ✅ ADDED
  "lead_type": "enquiry",                      ← ✅ ADDED
  "mark_as_complaint": false,                  ← ✅ ADDED
  "no_of_functions": "2",                      ← ✅ ADDED
  "no_of_attires": "5",                        ← ✅ ADDED
  "competitor": "XYZ Store",                   ← ✅ ADDED
  "service": "Excellent",                      ← ✅ ADDED
  "refund_status": "Security Amount Refunded"  ← ✅ ADDED
}

✅ All 18 fields sent!
```

---

## Data Flow Comparison

### BROKEN Flow (Current)

```
Form Input
    ↓
_saveLead()
    ├─ createLead() ← Sends all fields
    │   ├─ Backend creates lead
    │   └─ Returns leadId
    │
    ├─ ❌ NO updateReturnLead() call
    │
    └─ Add to local repo
        ↓
    ❌ RESULT: Feedback lost!
```

### FIXED Flow (After Fix)

```
Form Input
    ↓
_saveLead()
    ├─ createLead() ← Creates lead
    │   ├─ Backend creates lead
    │   └─ Returns leadId
    │
    ├─ ✅ updateReturnLead() ← Sends feedback
    │   ├─ Backend updates lead
    │   └─ Saves all feedback fields
    │
    └─ Add to local repo
        ↓
    ✅ RESULT: Feedback saved!
```

---

## Field Mapping Issue

### Current (BROKEN)

```
Method receives:
  subCategory ────────────────────────────────────────────┐
  itemCategory ───────────────────────────────────────────┤
  functionDate ────────────────────────────────────────────┤
  leadType ────────────────────────────────────────────────┤
  markAsComplaint ─────────────────────────────────────────┤
  numberOfFunctions ──────────────────────────────────────┤
  numberOfAttires ────────────────────────────────────────┤
  competitor ─────────────────────────────────────────────┤
  service ────────────────────────────────────────────────┤
  refundStatus ───────────────────────────────────────────┤
                                                           ↓
                                                    ❌ IGNORED!
                                                    Not added to
                                                    request body
```

### Fixed (CORRECT)

```
Method receives:
  subCategory ────────────────────────────────────────────┐
  itemCategory ───────────────────────────────────────────┤
  functionDate ────────────────────────────────────────────┤
  leadType ────────────────────────────────────────────────┤
  markAsComplaint ─────────────────────────────────────────┤
  numberOfFunctions ──────────────────────────────────────┤
  numberOfAttires ────────────────────────────────────────┤
  competitor ─────────────────────────────────────────────┤
  service ────────────────────────────────────────────────┤
  refundStatus ───────────────────────────────────────────┤
                                                           ↓
                                                    ✅ ADDED to
                                                    request body
                                                           ↓
                                                    Sent to backend
```

---

## Summary

| Aspect | Current (Broken) | Fixed (Correct) |
|--------|------------------|-----------------|
| **Outgoing Call** | Feedback lost | Feedback saved ✓ |
| **API Fields** | 8 fields sent | 18 fields sent ✓ |
| **Update Call** | No update call | updateReturnLead() called ✓ |
| **Data Persistence** | Incomplete | Complete ✓ |
| **User Experience** | "Saved" but lost | Actually saved ✓ |
