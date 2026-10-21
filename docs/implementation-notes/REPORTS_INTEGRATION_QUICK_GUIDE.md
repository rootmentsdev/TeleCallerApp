# Reports API Integration - Quick Guide

## What Changed

### UI
✅ **No UI changes** - The Reports screen looks exactly the same

### Data Source
- **Before**: Hardcoded dummy data (452 Total Calls, 120 Enquiry Calls, etc.)
- **After**: Real data fetched from backend API

## How It Works

### 1. Lead Creation Flow
```
User adds lead (Incoming/Outgoing/Mark Booking/Enquiry)
    ↓
Lead saved to backend with leadType
    ↓
Lead appears in Reports screen automatically
```

### 2. Report Display
- **Total Calls**: All reports from backend
- **Enquiry Calls**: Reports where leadType = "enquiry"
- **Feedback Calls**: Reports where leadType = "return"
- **Booking Calls**: Reports where leadType = "bookingconfirmation"

### 3. Time Range Filtering
- Select time range (Last 7 Days, Today, This Month, Last Month)
- Or use "Custom Range" for date picker
- Reports automatically refresh with new date range

### 4. Latest Reports
- Shows latest 3 reports on Reports screen
- Click "View All" to see complete list
- Click "Details" on any report to view full details

## Lead Type Mapping

| Add Lead Type | Backend leadType | Reports Category |
|---|---|---|
| Enquiry | enquiry | Enquiry Calls |
| Booking | bookingconfirmation | Booking Calls |
| Feedback/Return | return | Feedback Calls |

## Key Files Modified

1. **frontend/lib/view/reports_screens/reports_screen.dart**
   - Integrated with ReportController
   - Dynamic data binding
   - Real-time report display

2. **frontend/lib/controller/report_controller.dart**
   - Already had API integration
   - Fetches reports from backend
   - Filters by leadType and date range

3. **frontend/lib/services/api_service.dart**
   - Already had getReports() method
   - Supports leadType, dateFrom, dateTo filters

## Testing Checklist

- [ ] Add a new "Enquiry" lead
- [ ] Verify "Enquiry Calls" count increases
- [ ] Add a new "Booking" lead
- [ ] Verify "Booking Calls" count increases
- [ ] Check "Total Calls" increases
- [ ] Test time range filtering
- [ ] Test custom date range
- [ ] Click "Details" on a report
- [ ] Verify correct detail screen opens

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
      "editedAt": "2026-01-18T12:10:00Z",
      "callDuration": 120
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 100,
    "total": 452
  }
}
```

## Troubleshooting

### No reports showing
- Check backend is running
- Verify leads were created with correct leadType
- Check date range includes lead creation date

### Wrong report counts
- Verify leadType mapping in backend
- Check date range filters
- Ensure leads have "Connected" or other called status

### Details screen not opening
- Verify EnquiryDetailScreen and BookingDetailScreen exist
- Check navigation parameters are correct

## Performance Notes

- Reports fetched with limit=100 (can be increased if needed)
- Pagination support available for future use
- Filtering done on backend (efficient)
- UI updates only when data changes (Provider pattern)

## Future Enhancements

- [ ] Add pagination for large datasets
- [ ] Add export to PDF/Excel
- [ ] Add report search
- [ ] Add analytics/charts
- [ ] Real-time updates via WebSocket
