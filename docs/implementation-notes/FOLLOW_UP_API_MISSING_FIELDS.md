# Follow-Up API Missing Fields Issue

## Problem
When fetching follow-up leads from the backend API (`/api/pages/follow-ups`), the response is missing several important fields that were sent when creating the lead:

**Fields sent when creating lead:**
- `sub_category`: "Product Enquiry"
- `item_category`: "Tie"
- `closing_action`: "Not Interested"
- `call_duration`: 2
- `remarks`: "asdfghjkl;"

**Fields returned by follow-up API:**
- `reason_collected_from_store`: null
- `attended_by`: null
- `booking_number`: null
- `visit_date`: null
- `return_date`: null
- `security_amount`: null

**Result:** Frontend shows "Not specified" for Sub Category, Close Action, and Call Duration

## Root Cause
The backend's FollowUps collection schema is different from the Leads collection schema. When a lead is moved to follow-ups, the backend creates a new document with a simplified schema that doesn't include all the original fields.

## Backend Database vs API Response

### What's stored in backend database:
```json
{
  "_id": "69720146f6c1bce8019ceed4",
  "name": "test",
  "phone": "1234567890",
  "store": "Suitor Guy - Palakkad",
  "source": "Manual Entry",
  "leadType": "enquiry",
  "brand": "Suitor Guy",
  "subCategory": "Product Enquiry",
  "itemCategory": null,
  "functionDate": "2026-01-29T16:21:31.861Z",
  "followUpDate": "2026-01-29T16:21:31.861Z",
  "callStatus": "Not Called",
  "leadStatus": "No Status",
  "closingAction": null,
  "followUpFlag": true,
  "remarks": "asdfghjkl;",
  "callDuration": 2,
  "createdBy": "695b97e060b02714e2ad4784",
  "assignedTo": "695b97e060b02714e2ad4784",
  "movedToFollowUpAt": "2026-01-22T10:51:50.199Z",
  "movedToFollowUpBy": "695b97e060b02714e2ad4784",
  "createdAt": "2026-01-22T10:51:50.202Z",
  "updatedAt": "2026-01-22T10:51:50.202Z"
}
```

### What's returned by /api/pages/follow-ups:
```json
{
  "id": "69720146f6c1bce8019ceed4",
  "lead_name": "test",
  "phone_number": "1234567890",
  "store": "Suitor Guy - Palakkad",
  "lead_type": "enquiry",
  "call_status": "Not Called",
  "lead_status": "No Status",
  "function_date": "2026-01-29T16:21:31.861Z",
  "created_at": "2026-01-22T10:51:50.202Z",
  "assigned_to": {
    "id": "695b97e060b02714e2ad4784",
    "name": "SHAFNA ISMAIL",
    "employee_id": "Emp188"
  },
  "reason_collected_from_store": null,
  "attended_by": null,
  "booking_number": null,
  "visit_date": null,
  "return_date": null,
  "follow_up_date": "2026-01-29T16:21:31.861Z",
  "security_amount": null
}
```

## Solution Options

### Option 1: Backend API Enhancement (Recommended)
Update the `/api/pages/follow-ups` endpoint to include all fields from the FollowUps collection:
- `sub_category` or `subCategory`
- `item_category` or `itemCategory`
- `closing_action` or `closingAction`
- `call_duration` or `callDuration`
- `remarks`
- `brand`
- `source`

### Option 2: Fetch Full Lead Details
After fetching follow-up leads, make additional API calls to fetch the full lead details for each follow-up lead using the lead ID.

### Option 3: Store Missing Fields Locally
When creating a lead with follow-up flag, store the `sub_category`, `item_category`, `closing_action`, and `call_duration` in local storage so they can be displayed even if the API doesn't return them.

## Current Workaround
Updated `_parseApiLeadToLeadModel` to check for `reason_collected_from_store` as a fallback for remarks:
```dart
final reason =
    leadData['remarks']?.toString() ??
    leadData['reason']?.toString() ??
    leadData['reason_collected_from_store']?.toString() ??
    leadData['notes']?.toString();
```

## Files Affected
- `frontend/lib/controller/lead_repository.dart` - `_parseApiLeadToLeadModel` method
- `frontend/lib/model/lead_model.dart` - LeadModel parsing

## Recommended Action
**Contact backend team to update `/api/pages/follow-ups` endpoint to include:**
- `sub_category`
- `item_category`
- `closing_action`
- `call_duration`
- `remarks`
- `brand`
- `source`

This will ensure all lead information is available on the frontend without requiring additional API calls.
