# Lead Screen Auto-Refresh Implementation

## Overview
Implemented auto-refresh functionality on the Lead Screen to automatically fetch and display updated data when store or date filters change, matching the pattern used in Reports Screen.

## Problem
The lead screen was using `didChangeDependencies()` which is called on every dependency change (too broad), rather than specifically listening to store/date filter changes from the HeaderController. This meant:
- Fetches were triggered unnecessarily on unrelated dependency changes
- No direct connection between filter changes and data refresh
- Inconsistent with other screens (Reports, Call Report List, Follow-up) that use listener pattern

## Solution
Implemented the listener pattern used by ReportController:

### Changes Made

#### 1. Enhanced `initState()` Method
- Added explicit listener registration to HeaderController
- Listener is added after LeadScreenController initialization
- Ensures auto-refresh triggers on store/date changes

```dart
// Add listener to header controller for auto-refresh on store/date changes
headerController.addListener(_onHeaderChanged);
```

#### 2. Added `_onHeaderChanged()` Method
New method that responds to HeaderController changes:
- Checks which tab is currently selected
- Triggers appropriate fetch method for that tab
- Ensures only the active tab refreshes (not all tabs)

```dart
void _onHeaderChanged() {
  final leadController = Provider.of<LeadScreenController>(context, listen: false);
  final headerController = Provider.of<HeaderController>(context, listen: false);

  // Refresh the currently selected tab
  if (leadController.selectedCallTypeIndex == _tabIndexBookingConfirmation) {
    _fetchBookingConfirmationLeads(leadController, headerController);
  } else if (leadController.selectedCallTypeIndex == _tabIndexReturn) {
    _fetchReturnLeads(leadController, headerController);
  } else if (leadController.selectedCallTypeIndex == _tabIndexJustDial) {
    _fetchJustDialLeads(leadController, headerController);
  }
}
```

#### 3. Added `dispose()` Method
Properly cleans up listener when screen is disposed:
- Removes listener from HeaderController
- Prevents memory leaks
- Handles context availability during dispose

```dart
@override
void dispose() {
  // Remove listener when screen is disposed
  WidgetsBinding.instance.addPostFrameCallback((_) {
    try {
      final headerController = Provider.of<HeaderController>(context, listen: false);
      headerController.removeListener(_onHeaderChanged);
    } catch (e) {
      // Context may not be available during dispose
    }
  });
  super.dispose();
}
```

#### 4. Removed `didChangeDependencies()` Method
- Eliminated the overly broad dependency change listener
- Replaced with specific HeaderController listener
- Reduces unnecessary fetches and improves performance

## How It Works

### Flow Diagram
```
User changes store/date filter
         ↓
HeaderController.notifyListeners()
         ↓
_onHeaderChanged() is called
         ↓
Check selected tab
         ↓
Call appropriate fetch method
         ↓
Data refreshed with new filters
```

### Behavior

**When store filter changes:**
1. User selects different store from dropdown
2. HeaderController.setSelectedStore() is called
3. HeaderController notifies all listeners
4. _onHeaderChanged() is triggered
5. Currently selected tab's data is fetched with new store filter

**When date filter changes:**
1. User selects different date range (Today, Last 7 Days, etc.)
2. HeaderController.setDateRange() or setSelectedDate() is called
3. HeaderController notifies all listeners
4. _onHeaderChanged() is triggered
5. Currently selected tab's data is fetched with new date filter

**When tab is switched:**
1. User taps on different category card (Feedback, Booking, JustDial)
2. setSelectedCallTypeIndex() is called
3. Appropriate fetch method is called directly
4. Tab-specific data is loaded

## Benefits

1. **Automatic Refresh**: Data automatically updates when filters change
2. **Efficient**: Only active tab is refreshed, not all tabs
3. **Consistent**: Matches pattern used in Reports, Call Report List, and Follow-up screens
4. **Clean**: Removes unnecessary didChangeDependencies() logic
5. **Memory Safe**: Properly removes listener on dispose

## Testing Checklist

- [ ] Change store filter → Booking Confirmation tab refreshes
- [ ] Change store filter → Feedback Calls tab refreshes
- [ ] Change store filter → JustDial tab refreshes
- [ ] Change date filter → Booking Confirmation tab refreshes
- [ ] Change date filter → Feedback Calls tab refreshes
- [ ] Change date filter → JustDial tab refreshes
- [ ] Switch tabs → Correct data displays
- [ ] Pull-to-refresh still works
- [ ] No memory leaks on screen dispose
- [ ] No duplicate fetches on filter change

## Files Modified

- `frontend/lib/view/lead_screen/lead_screen.dart`
  - Added `_onHeaderChanged()` method
  - Enhanced `initState()` with listener registration
  - Added `dispose()` method with listener cleanup
  - Removed `didChangeDependencies()` method
  - Kept all fetch methods unchanged

## Related Files

- `frontend/lib/controller/header_controller.dart` - Provides store/date filter state
- `frontend/lib/controller/lead_screen_controller.dart` - Manages lead data
- `frontend/lib/controller/report_controller.dart` - Reference implementation of listener pattern
