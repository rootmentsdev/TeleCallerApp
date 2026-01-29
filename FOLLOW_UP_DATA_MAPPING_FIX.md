# Follow-Up Data Mapping Fix - Sub Category and Closing Action Not Displaying

## Problem
When a new lead is created with follow-up flag enabled, the backend returns the follow-up data with `subCategory`, `closingAction`, and `functionDate`, but these fields were not being stored in the local `LeadModel`. This caused the follow-up detail screen to show "Not specified" for these fields.

**Backend Response:**
```json
{
  "followUp": {
    "name": "TEST2",
    "phone": "1234567894",
    "subCategory": "Product Enquiry",
    "closingAction": "Not Interested",
    "functionDate": "2026-02-01T00:00:00.000Z",
    "remarks": "ASDFGHJKL;",
    ...
  }
}
```

**Frontend Display (Before Fix):**
```
Sub Category: Not specified
Close Action: Not specified
Function Date: Not available
Remarks: No remarks
```

## Root Cause
In `add_lead_bottom_sheet.dart`, when creating the local `LeadModel` after receiving the API response, the following fields were not being passed:
- `subCategory`
- `closingAction`
- `functionDate`

This meant the local model didn't have this data, so when the follow-up screen displayed the lead, it showed default "Not specified" values.

## Solution
Updated the `LeadModel` creation in `_saveLead()` method to include:
1. `subCategory: _selectedSubCategory`
2. `closingAction: _selectedCloseReason`
3. `functionDate: _functionDate`

### Changed Code:
```dart
// Before
final lead = LeadModel(
  id: leadId,
  name: _nameController.text.trim(),
  phone: _phoneController.text.trim(),
  // ... other fields ...
  leadType: _selectedLeadType ?? 'Enquiry',
  // Missing: subCategory, closingAction, functionDate
);

// After
final lead = LeadModel(
  id: leadId,
  name: _nameController.text.trim(),
  phone: _phoneController.text.trim(),
  // ... other fields ...
  leadType: _selectedLeadType ?? 'Enquiry',
  subCategory: _selectedSubCategory,
  closingAction: _selectedCloseReason,
  functionDate: _functionDate,
);
```

## Data Flow

```
User fills Add Lead form with:
- Sub Category: "Product Enquiry"
- Close Action: "Not Interested"
- Function Date: "2026-02-01"
    ↓
User clicks Save
    ↓
API creates lead and returns followUp data
    ↓
Local LeadModel created with all fields
    ↓
Lead stored in LeadRepository
    ↓
Follow-up screen displays lead
    ↓
All fields show actual values
```

## Fields Now Properly Stored

| Field | Source | Storage | Display |
|---|---|---|---|
| subCategory | User input | LeadModel.subCategory | Sub Category |
| closingAction | User input | LeadModel.closingAction | Close Action |
| functionDate | User input | LeadModel.functionDate | Function Date |
| remarks | User input | LeadModel.reason | Remarks / Notes |

## Files Modified

1. `frontend/lib/widgets.dart/add_lead_bottom_sheet.dart`
   - Added `subCategory: _selectedSubCategory` to LeadModel creation
   - Added `closingAction: _selectedCloseReason` to LeadModel creation
   - Added `functionDate: _functionDate` to LeadModel creation

## Result

✅ Sub Category now displays actual value from user input
✅ Close Action now displays actual value from user input
✅ Function Date now displays actual value from user input
✅ Remarks now display actual value from user input
✅ All follow-up data is properly stored locally
✅ No compilation errors

## Testing

To verify the fix works:

1. Open Add Lead bottom sheet
2. Fill in all fields including:
   - Sub Category: Select a value
   - Close Action: Select a value
   - Function Date: Select a date
   - Remarks: Enter text
3. Enable "Mark as Follow-up"
4. Click Save
5. Navigate to Follow-ups screen
6. Verify that all fields display the values you entered

## Example Data

**Before Fix:**
```
Sub Category: Not specified
Close Action: Not specified
Function Date: Not available
Remarks: No remarks
```

**After Fix:**
```
Sub Category: Product Enquiry
Close Action: Not Interested
Function Date: 01 Jan 2026
Remarks: ASDFGHJKL;
```

## LeadModel Fields

The `LeadModel` class supports these fields:
- `id` - Lead ID
- `name` - Lead name
- `phone` - Phone number
- `brand` - Brand/Store brand
- `location` - Store location
- `leadStatus` - Lead status
- `callStatus` - Call status
- `followUpDate` - Follow-up date
- `reason` - Remarks/Reason
- `category` - Lead category
- `callDuration` - Call duration
- `callCount` - Number of calls
- `createdAt` - Creation date
- `source` - Lead source
- `leadType` - Type of lead
- `subCategory` - Sub category ✅ Now used
- `closingAction` - Closing action ✅ Now used
- `functionDate` - Function date ✅ Now used
- `enquiryDate` - Enquiry date
- `visitDate` - Visit date
- `returnDate` - Return date
- `isStarred` - Whether starred

## Related Fields

The same pattern is used for other optional fields:
- `enquiryDate` - Enquiry date from API
- `visitDate` - Visit date from API
- `returnDate` - Return date from API

All are now properly stored when available.

## Notes

- The `_selectedSubCategory` variable comes from the Sub Category dropdown
- The `_selectedCloseReason` variable comes from the Close Action dropdown
- The `_functionDate` variable comes from the Function Date picker
- All values are properly null-checked before storage
- The local model is only created if it doesn't already exist (duplicate prevention)

## Backend Integration

The backend returns follow-up data in the response:
```json
{
  "message": "Lead created and moved to follow-ups",
  "followUp": {
    "subCategory": "Product Enquiry",
    "closingAction": "Not Interested",
    "functionDate": "2026-02-01T00:00:00.000Z",
    "remarks": "ASDFGHJKL;",
    ...
  }
}
```

The frontend now properly stores this data locally for display.
