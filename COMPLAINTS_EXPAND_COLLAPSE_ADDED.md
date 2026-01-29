# Complaints Screen - Expand/Collapse Details Added

## Overview
Added expand/collapse functionality to complaint cards. When user clicks "Details" button on a collapsed card, it expands to show full complaint details.

## Changes Made

### File: `frontend/lib/view/complaints_screen/complaints_screen.dart`

#### Updated Details Button Functionality
Changed from:
```dart
onTap: () {
  // Navigate to complaint details
},
```

To:
```dart
onTap: () {
  setState(() {
    complaint['isExpanded'] = !complaint['isExpanded'];
  });
},
```

## Expand/Collapse Behavior

### Collapsed View
- Shows customer name and phone
- Shows date/time with share button
- Shows complaint category (red text)
- Shows truncated remarks
- Shows store name
- "Details" button with arrow icon

### Expanded View (After Clicking Details)
- Shows all information from collapsed view
- Plus additional details:
  - Full remarks/notes
  - Store & Location
  - Function Date
  - Sub Category
  - Call Remarks / Notes (full text)
- Larger card with more padding
- Share button in header

## User Experience
✅ Click "Details" on collapsed card → Card expands
✅ Click "Details" on expanded card → Card collapses
✅ Smooth state transition
✅ All details visible in expanded view
✅ Share button available in both views
✅ No navigation required

## Features
- **Toggle Expand/Collapse**: Click Details button to toggle
- **Full Details Display**: Expanded view shows all complaint information
- **Compact View**: Collapsed view shows summary
- **Share Available**: Share button works in both views
- **Smooth Transition**: State updates immediately

## Testing
1. Open Complaints screen
2. View collapsed complaint cards
3. Click "Details" button on any card
4. Verify card expands to show full details
5. Click "Details" again
6. Verify card collapses back to summary view
7. Verify share button works in both views

## Data Structure
Each complaint object has:
- `isExpanded`: Boolean flag to track expand/collapse state
- `name`: Customer name
- `phone`: Phone number
- `type`: Complaint type
- `date`: Date and time
- `store`: Store location
- `functionDate`: Function date
- `subCategory`: Complaint category
- `remarks`: Full complaint remarks

## Future Enhancements
- Add smooth animation for expand/collapse
- Add expand all / collapse all buttons
- Add animation transition between states
- Persist expand/collapse state
- Add expand/collapse icons that rotate
