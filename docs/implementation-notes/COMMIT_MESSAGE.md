# Commit Message

## Title
```
feat: Add date filtering and sorting to reports screens
```

## Description
```
Implement comprehensive date filtering and sorting for Reports Screen and Call Report List Screen:

### Changes:
1. **Date Categorization**
   - Added DateCategorization utility with categories: Today, Last 7 Days, This Month, Last Month
   - Implemented getDateRange() for converting categories to date ranges
   - Implemented isDateInCategory() for checking if a date falls within a category

2. **Report Controller Updates**
   - Added _selectedDateCategory field to track current date filter
   - Added setSelectedDateCategory() method to update date filter
   - Added getFilteredReportsByDateCategory() method for local date filtering
   - Implemented sorting by date (most recent first) in filtered reports

3. **Reports Screen Updates**
   - Integrated date categorization buttons (Today, Last 7 Days, This Month, Last Month)
   - Added custom date range picker for flexible date selection
   - Updated _getLatestReports() to use getFilteredReportsByDateCategory()
   - Reports now display sorted by date (most recent first)

4. **Call Report List Screen Updates**
   - Integrated date categorization buttons matching Reports Screen
   - Updated _getFilteredReports() to apply date filtering before call type filtering
   - Added sorting by date (most recent first)
   - Maintained deduplication by phone + lead type

### Backend Integration:
- Backend filters by editedAt (when report was last updated)
- Local filtering uses createdAt (when lead was originally created)
- This two-level filtering ensures accurate date-based reporting

### Store Filtering:
- Store filtering uses store.location field
- Case-insensitive substring matching handles store name variations
- Example: "Edappally" filter matches "SG-Edappally", "edappally", etc.

### Sorting:
- All reports sorted by date in descending order (most recent first)
- Sorting applied after all filtering operations
- Handles both string and DateTime date formats

### Bug Fixes:
- Fixed date field extraction from report data
- Improved error handling in date parsing
- Added null-safety checks for date fields

### Files Modified:
- frontend/lib/utils/date_categorization.dart (new)
- frontend/lib/controller/report_controller.dart
- frontend/lib/view/reports_screens/reports_screen.dart
- frontend/lib/view/reports_screens/call_report_list_screen.dart

### Testing:
- Verified date filtering works correctly for all categories
- Confirmed sorting displays most recent reports first
- Tested store filtering with various store name formats
- Validated deduplication in Call Report List Screen
```

## Full Commit Message (for git)
```
feat: Add date filtering and sorting to reports screens

Implement comprehensive date filtering and sorting for Reports Screen and Call Report List Screen:

CHANGES:
- Added DateCategorization utility with 4 date categories (Today, Last 7 Days, This Month, Last Month)
- Implemented local date filtering using createdAt field
- Added sorting by date (most recent first) to all report lists
- Integrated date categorization buttons in both screens
- Added custom date range picker for flexible date selection
- Improved store filtering with case-insensitive substring matching

BACKEND INTEGRATION:
- Backend filters by editedAt (when report was last updated)
- Local filtering uses createdAt (when lead was originally created)
- Two-level filtering ensures accurate date-based reporting

STORE FILTERING:
- Uses store.location field for filtering
- Case-insensitive substring matching handles store name variations
- Example: "Edappally" matches "SG-Edappally", "edappally", etc.

SORTING:
- All reports sorted by date in descending order (most recent first)
- Sorting applied after all filtering operations
- Handles both string and DateTime date formats

BUG FIXES:
- Fixed date field extraction from report data
- Improved error handling in date parsing
- Added null-safety checks for date fields

FILES MODIFIED:
- frontend/lib/utils/date_categorization.dart (new)
- frontend/lib/controller/report_controller.dart
- frontend/lib/view/reports_screens/reports_screen.dart
- frontend/lib/view/reports_screens/call_report_list_screen.dart

TESTING:
- Verified date filtering works correctly for all categories
- Confirmed sorting displays most recent reports first
- Tested store filtering with various store name formats
- Validated deduplication in Call Report List Screen
```
