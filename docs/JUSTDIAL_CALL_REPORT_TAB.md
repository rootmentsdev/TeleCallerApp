# JustDial Tab in Call Report Screen

## Overview
Added JustDial as a new tab/filter in the Call Report List screen, allowing users to view and manage JustDial leads alongside other call types.

## Changes Made

### 1. Call Types List
Added 'JustDial' to the available call type filters:
```dart
final List<String> callTypes = [
  'All',
  'Feedback',
  'Enquiry',
  'Booked',
  'Booking Confirmation',
  'Loss of Sale',
  'JustDial',  // ← NEW
];
```

### 2. Call Type Display Mapping
Updated `_getCallTypeDisplay()` to recognize JustDial type:
```dart
case 'justdial':
  return 'JustDial';
```

### 3. Color Scheme
Added JustDial colors for UI consistency:

**Background Color**: `0xFFE0F2F1` (Light Teal)
```dart
case 'JustDial':
  return const Color(0xFFE0F2F1);
```

**Text Color**: `0xFF00695C` (Dark Teal)
```dart
case 'JustDial':
  return const Color(0xFF00695C);
```

### 4. Detail Screen Navigation
Added JustDial handling in the detail screen navigation:
```dart
else if (callType == 'JustDial') {
  // Use Enquiry screen for JustDial (similar structure)
  detailScreen = EnquiryDetailScreen(
    name: name,
    phone: phone,
    callType: callType,
    reportData: report,
  );
}
```

## User Experience

### Viewing JustDial Reports
1. Open Call Reports screen
2. Select "JustDial" from the call type filter buttons
3. View all JustDial leads for the selected date range
4. Click "Details" to view full JustDial lead information

### Filtering Options
- **By Date**: Today, Last 7 Days, This Month, Last Month
- **By Store**: All Stores or specific store location
- **By Call Type**: All, Feedback, Enquiry, Booked, Booking Confirmation, Loss of Sale, **JustDial**

## Visual Design

### JustDial Tab Badge
- **Background**: Light Teal (#E0F2F1)
- **Text**: Dark Teal (#00695C)
- **Label**: "JustDial"

### Report Card Layout
```
┌─────────────────────────────────────┐
│ Name                    [JustDial]   │
│ Phone Number                        │
│ Store Location                      │
│ Date | Duration | Details →         │
└─────────────────────────────────────┘
```

## Data Flow

1. **Fetch JustDial Reports**
   - API: `GET /api/leads/justdial`
   - Filters: date range, store, pagination

2. **Display in List**
   - Type mapping: `justdial` → `JustDial`
   - Color coding: Teal theme
   - Deduplication: By phone + type

3. **View Details**
   - Opens Enquiry detail screen (similar structure)
   - Shows lead information
   - Allows status updates

## File Modified

- `frontend/lib/view/reports_screens/call_report_list_screen.dart`

## Future Enhancements

1. **Create Dedicated JustDial Detail Screen**
   - Custom fields for JustDial-specific data
   - JustDial-specific actions and workflows

2. **JustDial-Specific Metrics**
   - JustDial conversion rate
   - Average response time
   - Lead quality scoring

3. **JustDial Integration Features**
   - Auto-sync with JustDial API
   - Lead assignment workflow
   - Performance analytics

## Testing Checklist

- [ ] JustDial tab appears in call type filter
- [ ] Clicking JustDial filters shows only JustDial leads
- [ ] JustDial leads display with correct colors
- [ ] Clicking Details opens lead information
- [ ] Date range filtering works with JustDial
- [ ] Store filtering works with JustDial
- [ ] Deduplication works correctly for JustDial leads

## Notes

- JustDial leads currently use the Enquiry detail screen template
- A dedicated JustDial detail screen can be created in the future for more specific functionality
- JustDial leads are identified by `type: 'justdial'` in the report data
- Color scheme uses teal to differentiate from other lead types
