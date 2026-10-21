# Sub Category and Closing Action Mapping Fix

## Problem
The "Sub Category" and "Close Action" fields were always showing "Not specified" in the report detail screens, even though the backend was providing this data.

## Root Cause
In `report_controller.dart`, the `getFilteredLeads()` method was not extracting the `subCategory`, `closingAction`, and `itemCategory` fields from the backend response and adding them to the returned map.

## Solution
Updated `report_controller.dart` to:
1. Extract `subCategory` from backend data (supporting both camelCase and snake_case)
2. Extract `closingAction` from backend data (supporting both camelCase and snake_case)
3. Extract `itemCategory` from backend data (supporting both camelCase and snake_case)
4. Add these fields to the returned map with proper fallback values

## Changes Made

### Added Field Extraction:
```dart
// Extract sub category and closing action
final subCategory =
    leadData['subCategory']?.toString() ??
    leadData['sub_category']?.toString() ??
    '';
final closingAction =
    leadData['closingAction']?.toString() ??
    leadData['closing_action']?.toString() ??
    '';
final itemCategory =
    leadData['itemCategory']?.toString() ??
    leadData['item_category']?.toString() ??
    '';
```

### Added to Returned Map:
```dart
"subCategory": subCategory.isNotEmpty ? subCategory : "Not specified",
"closingAction": closingAction.isNotEmpty ? closingAction : "Not specified",
"itemCategory": itemCategory.isNotEmpty ? itemCategory : "Not specified",
```

## Backend Field Mapping

The controller now properly maps these backend fields:

| Backend Field (snake_case) | Backend Field (camelCase) | Frontend Field | Display |
|---|---|---|---|
| sub_category | subCategory | subCategory | Sub Category |
| closing_action | closingAction | closingAction | Close Action |
| item_category | itemCategory | itemCategory | Item Category |

## Data Flow

```
Backend API Response
    ↓
ReportModel.fromJson() creates leadSnapshot
    ↓
ReportController.getFilteredLeads()
    ↓
Extracts subCategory, closingAction, itemCategory
    ↓
Adds to returned map
    ↓
CallReportListScreen passes report to detail screen
    ↓
EnquiryDetailScreen / BookingDetailScreen displays values
```

## Fallback Behavior

- If `subCategory` is empty or null → displays "Not specified"
- If `closingAction` is empty or null → displays "Not specified"
- If `itemCategory` is empty or null → displays "Not specified"

This ensures the UI always shows meaningful text instead of blank fields.

## Files Modified

1. `frontend/lib/controller/report_controller.dart`
   - Added extraction of subCategory, closingAction, itemCategory
   - Added these fields to the returned map in getFilteredLeads()

## Result

✅ Sub Category now displays actual backend value
✅ Close Action now displays actual backend value
✅ Item Category now displays actual backend value
✅ Proper fallback to "Not specified" if data is missing
✅ Supports both camelCase and snake_case field names
✅ No compilation errors

## Testing

To verify the fix works:

1. Open Reports screen
2. Click on a report to view Call Report List
3. Click "Details" on any report
4. Verify that "Sub Category" and "Close Action" display actual values
5. If values are empty in backend, they should show "Not specified"

## Example Data

Before Fix:
```
Sub Category: Not specified
Close Action: Not specified
Item Category: Not specified
```

After Fix:
```
Sub Category: Product Enquiry
Close Action: Converted to Store
Item Category: Kids Suit
```

## Related Fields

The same extraction pattern is now used for:
- `subCategory` / `sub_category`
- `closingAction` / `closing_action`
- `itemCategory` / `item_category`

This ensures consistency across all field mappings.

## Future Enhancements

1. Add more field mappings if needed
2. Add field validation and formatting
3. Add custom display names for field values
4. Add field grouping by category
5. Add field search/filter functionality

## Notes

- The extraction supports both camelCase and snake_case to handle different backend response formats
- Empty strings are treated as missing data and show "Not specified"
- The fallback value "Not specified" is consistent with the UI design
- All fields are properly null-checked before conversion to string
