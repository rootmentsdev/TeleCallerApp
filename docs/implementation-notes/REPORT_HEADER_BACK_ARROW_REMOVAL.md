# Remove Back Arrow from Report Headers - COMPLETED

## Problem
The report screens (Reports and Call Reports) had back arrow buttons in their headers, making them inconsistent with other detail screens and taking up unnecessary space.

## Solution
Removed the back arrow button from both report screen headers and adjusted the layout to match other screens.

### Changes Made

**File: `frontend/lib/view/reports_screens/reports_screen.dart`**
- Removed back arrow icon and its GestureDetector
- Removed the nested Row that contained the back arrow
- Changed header layout from `Row(children: [Row(children: [back arrow, title]), notification])` to `Row(children: [title, notification])`
- Header now spans full width with title on left and notification icon on right

**File: `frontend/lib/view/reports_screens/call_report_list_screen.dart`**
- Removed back arrow icon and its GestureDetector
- Removed the nested Row that contained the back arrow
- Changed header layout to match reports_screen.dart
- Header now spans full width with title on left and notification icon on right

## Header Structure Before
```
[← Back Arrow] [Title] [Notification Icon]
```

## Header Structure After
```
[Title] [Notification Icon]
```

## Benefits
✅ Consistent header design across all report screens
✅ More space for title text
✅ Matches the layout of detail screens (enquiry, booking, feedback)
✅ Cleaner, simpler header design
✅ Better use of screen real estate

## Files Modified
- `frontend/lib/view/reports_screens/reports_screen.dart`
- `frontend/lib/view/reports_screens/call_report_list_screen.dart`

## Result
✅ Back arrow removed from both report screen headers
✅ Headers now match the length and style of other screens
✅ All code compiles without errors
