# Reports API Integration

## Overview
The Reports screen has been integrated with the backend API to fetch and display real-time report data. The UI remains unchanged while the data is now dynamically fetched from the backend.

## Architecture

### Components

1. **ReportController** (`frontend/lib/controller/report_controller.dart`)
   - Manages report data fetching from API
   - Filters reports based on selected lead type
   - Handles date range filtering
   - Provides methods to get report counts and filtered leads

2. **ReportsScreen** (`frontend/lib/view/reports_screens/reports_screen.dart`)
   - Displays reports with dynamic data from ReportController
   - Shows lead report metrics (Total Calls, Enquiry Calls, Feedback Calls, Booking Calls)
   - Displays latest 3 call reports
   - Supports time range selection and custom date range picker

3. **API Service** (`frontend/lib/services/api_service.dart`)
   - `getReports()` - Fetches reports from backend with optional filters
   - Supports filtering by leadType, dateFrom, dateTo, editedBy, page, limit

## Lead Types Mapping

When leads are added from Add Lead bottom sheet, they are categorized as:

- **Enquiry** - Product/Price enquiries, Store location enquiries
- **Booking** - Booking-related calls (Delivery Preparation, Cancellation, etc.)
- **Feedback** - Return/Feedback calls (mapped as "return" in backend)

### Report Display Logic

The Reports screen displays reports based on lead types:

1. **Total Calls** - All reports regardless of type
2. **Enquiry Calls** - Reports with leadType = "enquiry"
3. **Feedback Calls** - Reports with leadType = "return" (backend uses "return" for feedback)
4. **Booking Calls** - Reports with leadType = "bookingconfirmation"

## Data Flow

```
Add Lead (Incoming/Outgoing/Mark Booking/Enquiry)
    ↓
Lead saved to backend with leadType
    ↓
ReportController.fetchReportsWithCurrentFilters()
    ↓
API returns filtered reports based on:
  - leadType (Enquiry, Booking, Return/Feedback)
  - Date range (Last 7 Days, Today, This Month, Last Month, Custom)
  - Store (if selected)
    ↓
ReportsScreen displays:
  - Lead Report metrics (counts by type)
  - Latest Call Report cards (latest 3 reports)
```

## API Endpoints Used

### Get Reports
```
GET /api/pages/reports
Query Parameters:
  - leadType: "enquiry" | "bookingconfirmation" | "return" | null (all)
  - dateFrom: "YYYY-MM-DD"
  - dateTo: "YYYY-MM-DD"
  - editedBy: user ID (optional)
  - page: page number (default: 1)
  - limit: records per page (default: 100)
```

## Features

### 1. Dynamic Report Counts
- Total Calls: Sum of all reports
- Enquiry Calls: Count of reports with leadType = "enquiry"
- Feedback Calls: Count of reports with leadType = "return"
- Booking Calls: Count of reports with leadType = "bookingconfirmation"

### 2. Time Range Filtering
- Last 7 Days
- Today
- This Month
- Last Month
- Custom Range (date picker)

### 3. Store Filtering
- Displays selected store from HeaderController
- Reports are filtered by store location

### 4. Latest Reports Display
- Shows latest 3 reports on Reports screen
- Full list available in CallReportListScreen
- Each report shows:
  - Customer name
  - Phone number
  - Store location
  - Call date/time
  - Call type badge (Enquiry/Feedback/Booking)
  - Details link to view full report

## Integration Points

### ReportController Initialization
```dart
// In ReportsScreen.initState()
final reportController = Provider.of<ReportController>(context, listen: false);
final headerController = Provider.of<HeaderController>(context, listen: false);
reportController.init(headerController);
reportController.fetchReportsWithCurrentFilters();
```

### Data Binding
```dart
// Consumer2 listens to both ReportController and HeaderController
Consumer2<ReportController, HeaderController>(
  builder: (context, reportController, headerController, _) {
    // Use reportController.reports for data
    // Use reportController.isLoadingReports for loading state
  }
)
```

### Report Count Calculation
```dart
String _getReportCount(ReportController controller, String type) {
  final reports = controller.reports;
  
  switch (type) {
    case 'total':
      return reports.length.toString();
    case 'enquiry':
      return reports
          .where((r) => r.leadType?.toLowerCase() == 'enquiry')
          .length
          .toString();
    // ... other types
  }
}
```

## Error Handling

- Loading state: Shows CircularProgressIndicator while fetching
- Empty state: Shows "No reports available" message
- Error state: Handled by ReportController with error logging to Firebase Crashlytics

## Performance Considerations

- Reports are fetched with limit=100 to get sufficient data
- Pagination support available for future implementation
- Filtering done on backend to reduce data transfer
- UI updates only when data changes (Provider pattern)

## Future Enhancements

1. Implement pagination for large report lists
2. Add export functionality (PDF/Excel)
3. Add report filtering by user/team
4. Add report search functionality
5. Add report analytics/charts
6. Implement real-time report updates via WebSocket

## Testing

To test the integration:

1. Add a new lead with type "Enquiry" or "Booking"
2. Navigate to Reports screen
3. Verify the report count increases
4. Check that the new report appears in "Latest Call Report"
5. Test time range filtering
6. Test custom date range picker
7. Verify Details link navigates to correct detail screen
