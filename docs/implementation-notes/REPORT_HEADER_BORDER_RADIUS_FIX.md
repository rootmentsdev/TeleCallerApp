# Add Border Radius to Report Screen Headers - COMPLETED

## Problem
The report screen headers (Reports and Call Reports) had sharp corners, making them inconsistent with the design and not matching the visual style of other screens.

## Solution
Added border radius to the bottom corners of both report screen headers to create a rounded appearance.

### Changes Made

**File: `frontend/lib/view/reports_screens/reports_screen.dart`**
- Added `decoration` property to the header Container
- Applied `BorderRadius.only()` with 16px radius on bottom-left and bottom-right corners
- Maintained the same padding and styling

**File: `frontend/lib/view/reports_screens/call_report_list_screen.dart`**
- Added `decoration` property to the header Container
- Applied `BorderRadius.only()` with 16px radius on bottom-left and bottom-right corners
- Maintained the same padding and styling

## Header Styling

### Before
```dart
Container(
  color: ColorConstant.primaryColor,
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  child: SafeArea(...)
)
```

### After
```dart
Container(
  color: ColorConstant.primaryColor,
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  decoration: const BoxDecoration(
    color: ColorConstant.primaryColor,
    borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(16),
    ),
  ),
  child: SafeArea(...)
)
```

## Visual Changes
✅ Header now has rounded bottom corners (16px radius)
✅ Matches the design language of other screens
✅ Creates a more polished, modern appearance
✅ Consistent with Material Design principles

## Files Modified
- `frontend/lib/view/reports_screens/reports_screen.dart`
- `frontend/lib/view/reports_screens/call_report_list_screen.dart`

## Result
✅ Border radius added to both report screen headers
✅ Headers now have rounded bottom corners matching the design
✅ All code compiles without errors
