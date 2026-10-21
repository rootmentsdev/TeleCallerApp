# Report Data Mapping Fix - Complete

## Issues Fixed

### 1. **Report ID Extraction** ✅
**Problem**: Backend returns `report_id` but model was looking for `originalLeadId`
**Fix**: Updated `ReportModel.fromJson()` to check for `report_id` first:
```dart
originalId: json['report_id']?.toString() ?? json['originalLeadId']?.toString() ?? '',
```

### 2. **Fallback Snapshot Completeness** ✅
**Problem**: Missing `followUpFlag` field in fallback snapshot
**Fix**: Added `follow_up_flag` and `followUpFlag` to fallback snapshot mapping:
```dart
"follow_up_flag": json["followUpFlag"] ?? json["follow_up_flag"],
"followUpFlag": json["followUpFlag"] ?? json["follow_up_flag"],
```

### 3. **Lead Type Mapping** ✅
**Status**: Already correct in `fetchReportsWithCurrentFilters()`:
- Case 0: `null` (ALL CALLS)
- Case 1: `"enquiry"` (ENQUIRY CALLS)
- Case 2: `"return"` (FEEDBACK CALLS)
- Case 3: `"bookingconfirmation"` (BOOKING CALLS)
- Case 4: `"lossOfSale"` (LOSS OF SALE)
- Case 5: `null` (FOLLOW UP CALLS)

### 4. **Type Conversion** ✅
**Status**: `_getTypeFromLeadType()` correctly maps:
- `"enquiry"` → `"enquiry"`
- `"return"` → `"hardout"` (Feedback)
- `"bookingconfirmation"` → `"booking"`
- `"lossofsale"` → `"loss"`

## Data Flow

1. **Backend Response** → Contains fields at top level:
   - `report_id`, `name`, `phone`, `store`, `leadType`, `callStatus`, etc.

2. **ReportModel.fromJson()** → Creates fallback snapshot mapping all fields:
   - Supports both camelCase and snake_case
   - Extracts `report_id` as `originalId`
   - Creates comprehensive `leadSnapshot` with all field variations

3. **ReportController.getFilteredLeads()** → Extracts data from leadSnapshot:
   - Gets lead data from `leadSnapshot` (current state)
   - Supports multiple field name variations
   - Formats dates and normalizes store names

4. **Reports Screen** → Displays data:
   - Counts reports by `leadType` from API response
   - Shows latest 3 reports with name, phone, store, date
   - Navigates to detail screens based on call type

## Testing

All reports should now display correctly:
- ✅ Enquiry leads appear in "Enquiry Calls" count
- ✅ Feedback leads appear in "Feedback Calls" count  
- ✅ Booking leads appear in "Booking Calls" count
- ✅ All data fields display correctly (name, phone, store, date)
- ✅ Navigation to detail screens works

## Files Modified

1. `frontend/lib/model/report_model.dart`
   - Fixed `report_id` extraction
   - Added `followUpFlag` to fallback snapshot

2. `frontend/lib/controller/report_controller.dart`
   - Added default case to switch statement (minor improvement)

## Notes

- Backend API returns data at top level, not in nested snapshots
- Fallback snapshot creation handles both response formats
- All field name variations (camelCase/snake_case) are supported
- Store name normalization applied for consistency
