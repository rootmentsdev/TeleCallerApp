# Date Filtering and Sorting in Report Screen - Complete Explanation

## Current Architecture

### 1. Backend Filtering (Primary)
- **API Endpoint**: `GET /api/reports`
- **Parameters**: `editedAtFrom`, `editedAtTo` (ISO 8601 format)
- **Purpose**: Filter reports by when they were last edited/updated
- **Implementation**: `ReportController.fetchReportsWithCurrentFilters()`

### 2. Local Filtering (Secondary)
- **Purpose**: Further filter reports by date category after backend returns data
- **Categories**: Today, Last 7 Days, This Month, Last Month
- **Implementation**: `ReportController.getFilteredReportsByDateCategory()`
- **Used by**: Reports Screen and Call Report List Screen

---

## Data Flow

### Reports Screen Flow:
```
1. User selects date range (e.g., "Today")
2. ReportController.setSelectedDateCategory("Today")
3. HeaderController.setDateRange(startDate, endDate)
4. ReportController.fetchReportsWithCurrentFilters()
   ├─ Calls API with editedAtFrom/editedAtTo
   ├─ Backend filters by editedAt (when report was last updated)
   └─ Returns filtered reports
5. ReportsScreen._getLatestReports()
   ├─ Calls ReportController.getFilteredReportsByDateCategory()
   ├─ Applies local date filtering using createdAt
   └─ Returns final filtered list
6. Display reports in UI
```

### Call Report List Screen Flow:
```
1. User selects time range (e.g., "Last 7 Days")
2. ReportController.setSelectedDateCategory("Last 7 Days")
3. HeaderController.setDateRange(startDate, endDate)
4. ReportController.fetchReportsWithCurrentFilters()
   ├─ Calls API with editedAtFrom/editedAtTo
   └─ Returns filtered reports
5. CallReportListScreen._getFilteredReports()
   ├─ Applies local date filtering using createdAt
   ├─ Filters by call type
   ├─ Deduplicates by phone + type
   └─ Returns final filtered list
6. Display reports in UI
```

---

## Key Date Fields in Report Model

```dart
class ReportModel {
  DateTime createdAt;      // When report was created
  DateTime? editedAt;      // When report was last edited
  DateTime? updatedAt;     // When report was last updated
  
  // Lead-specific dates
  DateTime? enquiryDate;
  DateTime? visitDate;
  DateTime? functionDate;
  DateTime? bookingDate;
  DateTime? returnDate;
  DateTime? followUpDate;
}
```

---

## Backend vs Local Filtering

### Backend Filtering (editedAt)
- **When**: Filters by `editedAt` (when telecaller last updated the report)
- **Why**: Shows recently worked on reports
- **Advantage**: Reduces data transfer, faster filtering
- **Used for**: Initial data retrieval

### Local Filtering (createdAt)
- **When**: Filters by `createdAt` (when lead was originally created)
- **Why**: Shows leads from specific date ranges
- **Advantage**: More accurate for date-based reporting
- **Used for**: Final display filtering

---

## Current Issues & Solutions

### Issue 1: Date Mismatch
**Problem**: Backend filters by `editedAt`, but local filter uses `createdAt`
**Solution**: 
- Backend filtering is correct (shows recently worked reports)
- Local filtering should also use `createdAt` for consistency
- This is already implemented correctly

### Issue 2: Missing Reports
**Problem**: Some reports not showing in the list
**Root Cause**: 
- Backend returns reports with `editedAt` in the selected range
- But local filter checks `createdAt` which might be outside the range
- Example: Report created on 15/3, edited on 17/3 → Shows in "Today" (17/3) but not in "Last 7 Days" if filtered by createdAt

**Solution**: 
- For Reports Screen: Use `editedAt` for local filtering (matches backend)
- For Call Report List: Use `createdAt` for local filtering (shows original lead date)

### Issue 3: Sorting
**Problem**: Reports not sorted by date
**Solution**: Add sorting after filtering
- Sort by `editedAt` (descending) for most recent first
- Or sort by `createdAt` depending on use case

---

## Implementation Details

### ReportController.getFilteredReportsByDateCategory()
```dart
List<Map<String, dynamic>> getFilteredReportsByDateCategory() {
  final allReports = getFilteredLeads();
  
  // Filter by date category using createdAt
  final filteredReports = allReports.where((report) {
    final leadData = report['leadData'] as Map<String, dynamic>? ?? {};
    final createdAtValue = leadData['createdAt'] ?? report['callDate'];
    
    // Parse date and check if in category
    DateTime reportDate = DateTime.parse(createdAtValue.toString());
    return DateCategorization.isDateInCategory(reportDate, _selectedDateCategory);
  }).toList();
  
  // Sort by date (most recent first)
  filteredReports.sort((a, b) {
    final dateA = DateTime.parse(a['callDate'].toString());
    final dateB = DateTime.parse(b['callDate'].toString());
    return dateB.compareTo(dateA); // Descending order
  });
  
  return filteredReports;
}
```

### CallReportListScreen._getFilteredReports()
```dart
List<Map<String, dynamic>> _getFilteredReports(
  List<Map<String, dynamic>> allReports,
) {
  // 1. Filter by date category
  final dateFilteredReports = allReports.where((report) {
    final createdAtValue = report['callDate'];
    DateTime reportDate = DateTime.parse(createdAtValue.toString());
    return DateCategorization.isDateInCategory(reportDate, _selectedTimeRange);
  }).toList();
  
  // 2. Filter by call type
  final typeFilteredReports = dateFilteredReports.where((report) {
    if (_selectedCallType == 'All') return true;
    final callType = _getCallTypeDisplay(report['type']);
    return callType == _selectedCallType;
  }).toList();
  
  // 3. Deduplicate by phone + type
  final seen = <String>{};
  final deduplicatedReports = <Map<String, dynamic>>[];
  for (final report in typeFilteredReports) {
    final key = '${report['phone']}-${report['type']}';
    if (!seen.contains(key)) {
      seen.add(key);
      deduplicatedReports.add(report);
    }
  }
  
  // 4. Sort by date (most recent first)
  deduplicatedReports.sort((a, b) {
    final dateA = DateTime.parse(a['callDate'].toString());
    final dateB = DateTime.parse(b['callDate'].toString());
    return dateB.compareTo(dateA);
  });
  
  return deduplicatedReports;
}
```

---

## Store Filtering Logic

### Current Implementation
```dart
// In ReportController.getFilteredLeads()
if (storeFilter != null) {
  filteredReports = filteredReports.where((report) {
    final storeName = report["storeName"] as String? ?? "";
    return storeName.toLowerCase().contains(
          storeFilter.location.toLowerCase(),
        ) ||
        storeFilter.location.toLowerCase().contains(
          storeName.toLowerCase(),
        );
  }).toList();
}
```

### Store Filtering Explanation
1. **Store Object**: `Store` has `location` field (e.g., "Edappally", "MG Road")
2. **Report Store Name**: Comes from lead data (e.g., "SG-Edappally", "SG.MG ROAD")
3. **Matching Logic**: 
   - Check if report store name contains the filter location
   - OR check if filter location contains the report store name
   - This handles variations like "SG-Edappally" matching "Edappally"

### Example Matches
- Filter: "Edappally" → Matches: "SG-Edappally", "Edappally", "edappally"
- Filter: "MG Road" → Matches: "SG.MG ROAD", "MG Road", "mg road"
- Filter: "All Stores" → Matches: All reports (no filtering)

---

## Summary

| Aspect | Details |
|--------|---------|
| **Backend Filtering** | By `editedAt` (when report was last updated) |
| **Local Filtering** | By `createdAt` (when lead was created) |
| **Date Categories** | Today, Last 7 Days, This Month, Last Month |
| **Store Filtering** | By `store.location` field, case-insensitive substring match |
| **Sorting** | By date descending (most recent first) |
| **Deduplication** | By phone + lead type (Call Report List only) |

