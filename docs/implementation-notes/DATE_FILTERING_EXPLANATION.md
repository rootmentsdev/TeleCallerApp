# Date Filtering System - Complete Explanation

## Overview
The Telecaller app uses a sophisticated date filtering system that allows users to filter leads and reports by single dates or date ranges. The system is centralized through a `HeaderController` that manages state across multiple screens.

---

## Architecture Components

### 1. **HeaderController** (State Management)
**File:** `frontend/lib/controller/header_controller.dart`

This is the central controller that manages all date-related state:

```dart
class HeaderController extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();           // Single date
  DateTime? _dateRangeStart;                         // Range start
  DateTime? _dateRangeEnd;                           // Range end
  bool _isRangeMode = false;                         // Toggle between single/range
  late String _selectedStore;                        // Store filter
}
```

**Key Methods:**
- `setSelectedDate(DateTime date)` - Set single date filter
- `setDateRange(DateTime start, DateTime end)` - Set date range filter
- `clearDateRange()` - Reset to single date mode
- `setSelectedStore(String store)` - Set store filter

---

## 2. **UI Layer - Date Picker** (AppHeader Widget)
**File:** `frontend/lib/widgets.dart/app_header.dart`

### Date Picker UI:
```dart
InkWell(
  onTap: () async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      currentDate: headerController.selectedDate,
      initialDateRange: headerController.isRangeMode
          ? DateTimeRange(
              start: headerController.dateRangeStart ?? DateTime.now(),
              end: headerController.dateRangeEnd ?? DateTime.now(),
            )
          : null,
    );
    if (pickedRange != null) {
      headerController.setDateRange(pickedRange.start, pickedRange.end);
    }
  },
  child: Container(
    // Date display: "15/3 - 20/3" (range) or "15/3" (single)
    child: Text(
      headerController.isRangeMode
          ? '${headerController.dateRangeStart?.day}/${headerController.dateRangeStart?.month} - ${headerController.dateRangeEnd?.day}/${headerController.dateRangeEnd?.month}'
          : '${headerController.selectedDate.day}/${headerController.selectedDate.month}',
    ),
  ),
)
```

**Features:**
- Shows date range picker (Flutter's built-in `showDateRangePicker`)
- Displays selected date or date range in header
- Supports both single date and date range selection
- Updates HeaderController when date changes

---

## 3. **Business Logic Layer - ReportController**
**File:** `frontend/lib/controller/report_controller.dart`

### How Date Filtering Works:

#### Step 1: Listen to Header Changes
```dart
void init(HeaderController headerController) {
  _headerController = headerController;
  _headerController?.addListener(_onHeaderChanged);
}

void _onHeaderChanged() {
  // When header (store/date) changes, fetch reports from API
  _fetchReportsForCurrentFilters();
}
```

#### Step 2: Format Dates for API
```dart
Future<void> fetchReportsWithCurrentFilters() async {
  String formatDateWithTime(DateTime date) {
    return date.toIso8601String();  // e.g., "2026-03-15T00:00:00.000Z"
  }

  String editedAtFromStr;
  String editedAtToStr;

  if (_headerController?.isRangeMode == true &&
      _headerController?.dateRangeStart != null &&
      _headerController?.dateRangeEnd != null) {
    // Use date range
    editedAtFromStr = formatDateWithTime(_headerController!.dateRangeStart!);
    editedAtToStr = formatDateWithTime(_headerController!.dateRangeEnd!);
  } else {
    // Use single date - format with time to ensure full day coverage
    final selectedDate = _headerController?.selectedDate ?? DateTime.now();
    editedAtFromStr = formatDateWithTime(selectedDate);
    
    // For end date, use 23:59:59 of the same day
    final endOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      23,
      59,
      59,
    );
    editedAtToStr = formatDateWithTime(endOfDay);
  }
}
```

#### Step 3: Fetch Reports from API
```dart
Future<void> fetchReportsFromApi({
  String? leadType,
  String? editedBy,
  String? dateFrom,
  String? dateTo,
  String? createdAtFrom,
  String? createdAtTo,
  String? editedAtFrom,
  String? editedAtTo,
  int? page,
  int? limit,
}) async {
  final response = await _apiService.getReports(
    leadType: leadType,
    editedAtFrom: editedAtFromStr,  // "2026-03-15T00:00:00.000Z"
    editedAtTo: editedAtToStr,      // "2026-03-15T23:59:59.000Z"
    page: 1,
    limit: 100,
  );
  
  _reports = ReportsResponse.fromJson(response).reports;
  notifyListeners();
}
```

---

## 4. **API Layer - ApiService**
**File:** `frontend/lib/services/api_service.dart`

### API Call:
```dart
Future<Map<String, dynamic>> getReports({
  String? leadType,
  String? editedBy,
  String? dateFrom,
  String? dateTo,
  String? createdAtFrom,
  String? createdAtTo,
  String? editedAtFrom,
  String? editedAtTo,
  int? page,
  int? limit,
}) async {
  final url = Uri.parse(
    ApiConfig.getReports(
      leadType: leadType,
      editedAtFrom: editedAtFromStr,
      editedAtTo: editedAtToStr,
      page: page,
      limit: limit,
    ),
  );
  
  final response = await http.get(url, headers: headers);
  return json.decode(response.body);
}
```

### API Config:
**File:** `frontend/lib/utils/api_config.dart`

```dart
static String getReports({
  String? leadType,
  String? editedBy,
  String? dateFrom,
  String? dateTo,
  String? createdAtFrom,
  String? createdAtTo,
  String? editedAtFrom,
  String? editedAtTo,
  int? page,
  int? limit,
}) {
  String url = reportsBaseUrl;  // https://rootstele.onrender.com/api/leads/completed
  List<String> queryParams = [];

  if (editedAtFrom != null && editedAtFrom.isNotEmpty) {
    queryParams.add("editedAtFrom=${Uri.encodeComponent(editedAtFrom)}");
  }
  if (editedAtTo != null && editedAtTo.isNotEmpty) {
    queryParams.add("editedAtTo=${Uri.encodeComponent(editedAtTo)}");
  }
  
  if (queryParams.isNotEmpty) {
    url += "?${queryParams.join('&')}";
  }
  
  return url;
}
```

**Example API Call:**
```
GET https://rootstele.onrender.com/api/leads/completed?editedAtFrom=2026-03-15T00:00:00.000Z&editedAtTo=2026-03-15T23:59:59.000Z&page=1&limit=100
```

---

## 5. **Data Flow Diagram**

```
User selects date in UI
        ↓
AppHeader.showDateRangePicker()
        ↓
HeaderController.setDateRange() / setSelectedDate()
        ↓
notifyListeners() → triggers _onHeaderChanged()
        ↓
ReportController._fetchReportsForCurrentFilters()
        ↓
Format dates to ISO8601 with time component
        ↓
ApiService.getReports(editedAtFrom, editedAtTo)
        ↓
API Config builds URL with query parameters
        ↓
HTTP GET request to backend
        ↓
Backend filters reports by date range
        ↓
Response returned to app
        ↓
ReportController updates _reports list
        ↓
notifyListeners() → UI rebuilds with filtered data
```

---

## 6. **Date Filtering Modes**

### Mode 1: Single Date Filter
```dart
// User selects: March 15, 2026
headerController.setSelectedDate(DateTime(2026, 3, 15));

// Converted to API parameters:
editedAtFrom = "2026-03-15T00:00:00.000Z"
editedAtTo = "2026-03-15T23:59:59.000Z"

// API returns all reports edited on March 15, 2026
```

### Mode 2: Date Range Filter
```dart
// User selects: March 10 - March 20, 2026
headerController.setDateRange(
  DateTime(2026, 3, 10),
  DateTime(2026, 3, 20),
);

// Converted to API parameters:
editedAtFrom = "2026-03-10T00:00:00.000Z"
editedAtTo = "2026-03-20T23:59:59.000Z"

// API returns all reports edited between March 10-20, 2026
```

---

## 7. **Key Features**

### ✅ Automatic Refresh
When date changes, reports automatically refresh:
```dart
void _onHeaderChanged() {
  _fetchReportsForCurrentFilters();  // Auto-fetch new data
}
```

### ✅ Store + Date Filtering
Both filters work together:
```dart
// Get store parameter
final storeFilter = (store == null || store == 'All Stores') ? null : store;

// Filter reports by store
filteredReports = filteredReports.where((report) {
  final storeName = report["storeName"] as String? ?? "";
  return storeName.toLowerCase().contains(location.toLowerCase());
}).toList();
```

### ✅ Tab-Based Lead Type Filtering
Different tabs fetch different lead types:
```dart
switch (_selectedCallTypeIndex) {
  case 0: leadType = null;                    // ALL CALLS
  case 1: leadType = "enquiry";               // ENQUIRY CALLS
  case 2: leadType = "return";                // FEEDBACK CALLS
  case 3: leadType = "bookingconfirmation";   // BOOKING CALLS
  case 4: leadType = "lossOfSale";            // LOSS OF SALE CALLS
  case 5: leadType = null;                    // FOLLOW UP CALLS
}
```

### ✅ Local + API Filtering
- **API Filtering:** Reports (tabs 0-3) - backend filters by date
- **Local Filtering:** Follow-ups (tab 6) - app filters from local repository

```dart
if (_selectedCallTypeIndex == 6) {
  // Get leads by date range from local repository
  List<dynamic> allLeads = _repository.getLeadsByDateRange(
    _headerController!.dateRangeStart!,
    _headerController!.dateRangeEnd!,
  );
  
  // Filter only leads with follow-up date set
  List<dynamic> followUpLeads = allLeads.where((lead) {
    return lead.followUpDate != null;
  }).toList();
}
```

---

## 8. **Date Format Handling**

### Input Format (UI)
- User sees: `15/3` or `15/3 - 20/3`
- Stored as: `DateTime` objects

### API Format
- Sent to backend: ISO8601 with time
- Example: `2026-03-15T00:00:00.000Z`

### Display Format
- Reports show: `15 Mar, 2026`
```dart
String _formatDate(DateTime date) {
  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return "${date.day} ${months[date.month - 1]}, ${date.year}";
}
```

---

## 9. **Screens Using Date Filtering**

| Screen | Date Filter | Store Filter | Lead Type Filter |
|--------|------------|--------------|------------------|
| Home Screen | ✅ | ✅ | N/A |
| Lead Screen | ✅ | ✅ | N/A |
| Report Screen | ✅ | ✅ | ✅ (Tabs) |
| Follow-up Screen | ✅ | ✅ | N/A |
| Complaints Screen | ✅ | ✅ | N/A |

---

## 10. **Example: Complete Flow**

### Scenario: User filters reports for March 15, 2026, SG-Edappally store

1. **User Action:**
   - Taps date picker in header
   - Selects March 15, 2026
   - Store already set to "SG-Edappally"

2. **HeaderController:**
   ```dart
   setSelectedDate(DateTime(2026, 3, 15));
   // _selectedDate = DateTime(2026, 3, 15)
   // _isRangeMode = false
   // notifyListeners() → triggers _onHeaderChanged()
   ```

3. **ReportController:**
   ```dart
   fetchReportsWithCurrentFilters() {
     editedAtFromStr = "2026-03-15T00:00:00.000Z"
     editedAtTo = "2026-03-15T23:59:59.000Z"
     
     fetchReportsFromApi(
       leadType: null,  // All calls
       editedAtFrom: editedAtFromStr,
       editedAtTo: editedAtToStr,
     );
   }
   ```

4. **API Call:**
   ```
   GET https://rootstele.onrender.com/api/leads/completed?editedAtFrom=2026-03-15T00:00:00.000Z&editedAtTo=2026-03-15T23:59:59.000Z&page=1&limit=100
   ```

5. **Backend Processing:**
   - Filters reports where `editedAt` is between 00:00:00 and 23:59:59 on March 15
   - Returns matching reports

6. **Frontend Processing:**
   ```dart
   // Filter by store
   filteredReports = filteredReports.where((report) {
     return report["storeName"].contains("SG-Edappally");
   }).toList();
   ```

7. **UI Update:**
   - Reports screen displays filtered results
   - Header shows "15/3" and "SG-Edappally"

---

## Summary

The date filtering system is:
- **Centralized:** All date state managed by HeaderController
- **Reactive:** Changes automatically trigger data refresh
- **Flexible:** Supports single date and date range filtering
- **Efficient:** Backend does heavy filtering, app does light filtering
- **User-Friendly:** Simple date picker UI with clear display
- **Scalable:** Works across multiple screens with different data sources
