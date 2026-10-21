# Call Report List Screen - Quick Integration Guide

## What Changed

### UI
✅ **No UI changes** - The Call Report List screen looks exactly the same

### Data Source
- **Before**: Hardcoded dummy data (5 sample reports)
- **After**: Real data fetched from backend API

## How It Works

### 1. Navigation Flow
```
Reports Screen
    ↓
Click "View All" button
    ↓
CallReportListScreen opens
    ↓
Fetches all reports from backend
    ↓
Displays reports in list format
```

### 2. Report Display
- Shows all reports from backend
- Each report displays:
  - Customer name
  - Phone number
  - Store location
  - Call date and time
  - Call type (Enquiry/Feedback/Booking)
  - Call duration (in seconds converted to readable format)
  - Details link

### 3. Filtering

#### Time Range (Triggers API call)
- Last 7 Days
- Today
- This Month
- Last Month
- Automatically fetches new data

#### Call Type (Local filtering)
- All (shows all reports)
- Feedback (leadType = "return")
- Enquiry (leadType = "enquiry")
- Booking (leadType = "bookingconfirmation")
- No API call needed

#### Store
- Displays selected store from HeaderController
- Reports already filtered by store from API

### 4. Detail Navigation
- Click "Details" on any report
- Enquiry reports → EnquiryDetailScreen
- Booking/Feedback reports → BookingDetailScreen

## Key Features

✅ **Dynamic Data** - Real reports from backend  
✅ **Time Range Filtering** - Last 7 Days, Today, This Month, Last Month  
✅ **Call Type Filtering** - All, Feedback, Enquiry, Booking  
✅ **Duration Display** - Converts seconds to readable format (2m 30s)  
✅ **Loading State** - Shows spinner while fetching  
✅ **Empty State** - Shows message when no reports found  
✅ **Error Handling** - Logs to Firebase Crashlytics  
✅ **Detail Navigation** - Click Details to view full report  

## Data Flow

```
User selects time range
    ↓
ReportController.fetchReportsWithCurrentFilters()
    ↓
API returns filtered reports
    ↓
reportController.getFilteredLeads()
    ↓
Local call type filtering
    ↓
Display in ListView
```

## Call Type Mapping

| Backend | Display | Color |
|---|---|---|
| enquiry | Enquiry | Purple |
| return | Feedback | Blue |
| bookingconfirmation | Booking | Green |

## Duration Format

| Seconds | Display |
|---|---|
| 0 | 0s |
| 30 | 30s |
| 60 | 1m |
| 150 | 2m 30s |
| 315 | 5m 15s |

## Testing Quick Checklist

- [ ] Open Reports screen
- [ ] Click "View All"
- [ ] Verify reports display
- [ ] Change time range
- [ ] Filter by call type
- [ ] Click Details on report
- [ ] Verify correct detail screen opens

## Files Modified

1. **frontend/lib/view/reports_screens/call_report_list_screen.dart**
   - Integrated with ReportController
   - Dynamic data binding
   - Real-time report display
   - Time range filtering
   - Call type filtering

## Integration Points

### Initialization
```dart
reportController.init(headerController);
reportController.fetchReportsWithCurrentFilters();
```

### Data Binding
```dart
Consumer2<ReportController, HeaderController>(
  builder: (context, reportController, headerController, _) {
    final allReports = reportController.getFilteredLeads();
    // Use allReports
  }
)
```

### Time Range Change
```dart
setState(() => _selectedTimeRange = range);
reportController.fetchReportsWithCurrentFilters();
```

### Call Type Change
```dart
setState(() => _selectedCallType = type);
// Local filtering - no API call
```

## API Response Format

```json
{
  "data": [
    {
      "id": "lead_id",
      "leadType": "enquiry",
      "leadSnapshot": {
        "lead_name": "John Doe",
        "phone_number": "+91 98765 43210",
        "store": "Zorucci Edappally",
        "call_status": "Connected",
        "created_at": "2026-01-18T12:05:00Z"
      },
      "callDuration": 150
    }
  ]
}
```

## Troubleshooting

### No reports showing
- Check backend is running
- Verify date range includes lead creation date
- Check store filter matches lead store

### Wrong call type displayed
- Verify leadType mapping (enquiry, return, bookingconfirmation)
- Check _getCallTypeDisplay() function

### Duration showing incorrectly
- Verify callDuration is in seconds
- Check _formatDuration() function

### Details screen not opening
- Verify EnquiryDetailScreen and BookingDetailScreen exist
- Check navigation parameters

## Performance

- Reports fetched with limit=100
- Call type filtering done locally (fast)
- Time range filtering triggers API call
- UI updates only when data changes

## Future Enhancements

- [ ] Pagination for large datasets
- [ ] Search by name/phone
- [ ] Export to PDF/Excel
- [ ] Sorting options
- [ ] Analytics/statistics
- [ ] Real-time updates
- [ ] Call recording playback
- [ ] Report sharing

## Code Quality

✅ No compilation errors  
✅ No unused imports  
✅ Proper error handling  
✅ Loading states  
✅ Empty states  
✅ Responsive UI  
✅ Provider pattern  
✅ Proper navigation  
