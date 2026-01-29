# Call Report List Screen Integration

## Overview
The Call Report List screen has been integrated with the backend API to fetch and display real-time call report data. The UI remains unchanged while the data is now dynamically fetched from the backend.

## Architecture

### Components

1. **ReportController** (`frontend/lib/controller/report_controller.dart`)
   - Manages report data fetching from API
   - Filters reports based on selected lead type
   - Handles date range filtering
   - Provides `getFilteredLeads()` method to get all reports

2. **CallReportListScreen** (`frontend/lib/view/reports_screens/call_report_list_screen.dart`)
   - Displays all call reports with dynamic data from ReportController
   - Supports time range filtering (Last 7 Days, Today, This Month, Last Month)
   - Supports call type filtering (All, Feedback, Enquiry, Booking)
   - Shows store information from HeaderController
   - Displays call duration in human-readable format
   - Navigates to detail screens (EnquiryDetailScreen, BookingDetailScreen)

3. **API Service** (`frontend/lib/services/api_service.dart`)
   - `getReports()` - Fetches reports from backend with optional filters

## Data Flow

```
ReportsScreen "View All" button
    ↓
Navigate to CallReportListScreen
    ↓
ReportController.fetchReportsWithCurrentFilters()
    ↓
API returns filtered reports based on:
  - Date range (Last 7 Days, Today, This Month, Last Month)
  - Store (from HeaderController)
    ↓
CallReportListScreen displays:
  - All reports in list format
  - Filterable by call type (All, Feedback, Enquiry, Booking)
  - Each report shows: name, phone, store, date, call type, duration
```

## Features

### 1. Dynamic Report List
- Fetches all reports from backend
- Shows customer name, phone, store, date, call type, and duration
- Real-time updates when filters change

### 2. Time Range Filtering
- Last 7 Days
- Today
- This Month
- Last Month
- Automatically fetches new data when time range changes

### 3. Call Type Filtering
- All (shows all reports)
- Feedback (reports with leadType = "return")
- Enquiry (reports with leadType = "enquiry")
- Booking (reports with leadType = "bookingconfirmation")
- Filters applied locally without API call

### 4. Store Display
- Shows selected store from HeaderController
- Reports are already filtered by store from API

### 5. Call Duration Display
- Converts seconds to human-readable format
- Examples: "2m 30s", "5m 15s", "1m 20s"
- Shows "0s" for calls with no duration

### 6. Detail Navigation
- Click "Details" on any report to view full details
- Enquiry reports → EnquiryDetailScreen
- Booking/Feedback reports → BookingDetailScreen

## Integration Points

### Screen Initialization
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final reportController = Provider.of<ReportController>(
      context,
      listen: false,
    );
    final headerController = Provider.of<HeaderController>(
      context,
      listen: false,
    );
    reportController.init(headerController);
    reportController.fetchReportsWithCurrentFilters();
  });
}
```

### Data Binding
```dart
Consumer2<ReportController, HeaderController>(
  builder: (context, reportController, headerController, _) {
    final allReports = reportController.getFilteredLeads();
    final filteredReports = _getFilteredReports(allReports);
    // Display filteredReports
  }
)
```

### Time Range Filtering
```dart
GestureDetector(
  onTap: () {
    setState(() => _selectedTimeRange = range);
    // Fetch reports with new time range
    reportController.fetchReportsWithCurrentFilters();
  },
  // ...
)
```

### Call Type Filtering
```dart
GestureDetector(
  onTap: () {
    setState(() => _selectedCallType = type);
    // Local filtering - no API call needed
  },
  // ...
)
```

## Report Data Structure

Each report contains:
```dart
{
  'id': 'report_id',
  'name': 'Customer Name',
  'phone': '+91 98765 43210',
  'storeName': 'Zorucci Edappally',
  'date': '18 Jan 2026 12:05 pm',
  'type': 'enquiry' | 'return' | 'booking',
  'callDuration': 150, // in seconds
  'callStatus': 'Connected',
  'leadStatus': 'Confirmed',
  'reason': 'Product Enquiry',
  // ... other fields
}
```

## Call Type Mapping

| Backend leadType | Display Name | Color |
|---|---|---|
| enquiry | Enquiry | Purple (#7B1FA2) |
| return | Feedback | Blue (#1976D2) |
| bookingconfirmation | Booking | Green (#388E3C) |

## Loading and Empty States

### Loading State
- Shows CircularProgressIndicator while fetching reports
- Centered in the middle of the screen

### Empty State
- Shows "No call reports found" message
- Displayed when no reports match the selected filters

### Error Handling
- Errors are logged to Firebase Crashlytics
- User sees empty state if error occurs

## Performance Considerations

- Reports fetched with limit=100
- Pagination support available for future implementation
- Call type filtering done locally (no API call)
- Time range filtering triggers API call
- UI updates only when data changes (Provider pattern)

## UI Components

### Header
- Back button to return to Reports screen
- Title "Call Reports"
- Notification icon

### Filters
- Time range buttons (horizontal scroll)
- Store dropdown (from HeaderController)
- Call type filter buttons (horizontal scroll)

### Report Cards
- Customer name and phone
- Store location
- Call date and time
- Call duration
- Call type badge with color coding
- Details link to view full report

## Navigation

### From Reports Screen
```dart
GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CallReportListScreen(),
      ),
    );
  },
  child: Text('View All'),
)
```

### To Detail Screens
```dart
if (callType == 'Enquiry') {
  detailScreen = EnquiryDetailScreen(
    name: name,
    phone: phone,
    callType: callType,
  );
} else {
  detailScreen = BookingDetailScreen(
    name: name,
    phone: phone,
    callType: callType,
  );
}
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => detailScreen),
);
```

## Testing Checklist

- [ ] Navigate to Reports screen
- [ ] Click "View All" to open CallReportListScreen
- [ ] Verify reports are displayed
- [ ] Test time range filtering (Last 7 Days, Today, etc.)
- [ ] Test call type filtering (All, Feedback, Enquiry, Booking)
- [ ] Verify call duration displays correctly
- [ ] Click "Details" on Enquiry report → EnquiryDetailScreen
- [ ] Click "Details" on Booking report → BookingDetailScreen
- [ ] Verify store name displays correctly
- [ ] Test empty state (select time range with no reports)
- [ ] Test loading state (observe spinner while fetching)

## Future Enhancements

1. Implement pagination for large report lists
2. Add search functionality by name/phone
3. Add export functionality (PDF/Excel)
4. Add sorting options (by date, name, duration)
5. Add report analytics/statistics
6. Implement real-time updates via WebSocket
7. Add call recording playback
8. Add report sharing functionality

## Troubleshooting

### No reports showing
- Check backend is running
- Verify leads were created with correct leadType
- Check date range includes lead creation date
- Check store filter matches lead store

### Wrong report counts
- Verify leadType mapping in backend
- Check date range filters
- Ensure leads have "Connected" or other called status

### Details screen not opening
- Verify EnquiryDetailScreen and BookingDetailScreen exist
- Check navigation parameters are correct
- Check call type mapping is correct

### Call duration showing incorrectly
- Verify callDuration is in seconds (not milliseconds)
- Check _formatDuration() function logic
- Verify API returns callDuration field

## API Endpoints Used

### Get Reports
```
GET /api/pages/reports
Query Parameters:
  - leadType: "enquiry" | "bookingconfirmation" | "return" | null (all)
  - dateFrom: "YYYY-MM-DD"
  - dateTo: "YYYY-MM-DD"
  - page: page number (default: 1)
  - limit: records per page (default: 100)
```

## Code Quality

- ✅ No compilation errors
- ✅ No unused imports
- ✅ Proper error handling
- ✅ Loading states implemented
- ✅ Empty states implemented
- ✅ Responsive UI
- ✅ Provider pattern for state management
- ✅ Proper navigation
