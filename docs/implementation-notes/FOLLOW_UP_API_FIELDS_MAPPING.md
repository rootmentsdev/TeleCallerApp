# Follow-Up API Fields Mapping

## Problem
The follow-up leads API response from the backend includes additional fields that were not being parsed and stored in the LeadModel:
- `enquiry_date`
- `function_date`
- `visit_date`
- `booking_number`
- `assigned_to`

These fields were being ignored, causing data loss when fetching follow-up leads.

## Solution
Updated the `LeadModel` class to include all fields from the follow-up API response:

### New Fields Added to LeadModel
```dart
final DateTime? enquiryDate;      // Enquiry date from API
final DateTime? functionDate;     // Function date from API
final DateTime? visitDate;        // Visit date from API
final String? bookingNumber;      // Booking number from API
final Map<String, dynamic>? assignedTo;  // Assigned to user info from API
```

### Updated Methods
1. **Constructor** - Added parameters for all new fields
2. **toMap()** - Serializes new fields for local storage
3. **fromMap()** - Deserializes new fields from local storage
4. **fromApiJson()** - Parses new fields from API response with both snake_case and camelCase support

### API Response Mapping
The `fromApiJson()` method now handles:

| API Field | Dart Field | Type | Notes |
|-----------|-----------|------|-------|
| `enquiry_date` | `enquiryDate` | DateTime | Parsed from ISO 8601 string |
| `function_date` | `functionDate` | DateTime | Parsed from ISO 8601 string |
| `visit_date` | `visitDate` | DateTime | Parsed from ISO 8601 string |
| `booking_number` | `bookingNumber` | String | Direct mapping |
| `assigned_to` | `assignedTo` | Map<String, dynamic> | Contains user info (id, name, employee_id) |

### Example API Response
```json
{
  "id": "string",
  "lead_name": "string",
  "phone_number": "string",
  "store": "string",
  "lead_type": "string",
  "call_status": "string",
  "lead_status": "string",
  "enquiry_date": "2026-01-22T06:57:08.736Z",
  "function_date": "2026-01-22T06:57:08.736Z",
  "visit_date": "2026-01-22T06:57:08.736Z",
  "booking_number": "string",
  "return_date": "2026-01-22T06:57:08.736Z",
  "call_duration": 0,
  "remarks": "string",
  "follow_up_date": "2026-01-22T06:57:08.736Z",
  "created_at": "2026-01-22T06:57:08.736Z",
  "assigned_to": {
    "id": "string",
    "name": "string",
    "employee_id": "string"
  }
}
```

## Files Modified
- `frontend/lib/model/lead_model.dart` - Added new fields and updated all serialization methods

## Testing
To verify the fix:
1. Fetch follow-up leads from the API
2. Check that all fields are properly parsed and stored
3. Verify that the follow-up screen displays leads correctly with all available data
4. Check logs to ensure no parsing errors occur
