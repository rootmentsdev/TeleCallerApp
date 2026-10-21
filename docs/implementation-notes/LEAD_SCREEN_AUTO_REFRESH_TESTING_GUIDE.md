# Lead Screen Auto-Refresh Testing Guide

## Quick Test Steps

### Test 1: Store Filter Auto-Refresh
1. Open Lead Screen
2. Navigate to **Booking Confirmation** tab
3. Note the number of leads displayed
4. Open store dropdown (top header)
5. Select a different store (e.g., "SG-Calicut")
6. **Expected**: Booking Confirmation tab automatically refreshes with data for selected store
7. Repeat for **Feedback Calls** and **JustDial** tabs

### Test 2: Date Filter Auto-Refresh
1. Open Lead Screen
2. Navigate to **Feedback Calls** tab
3. Note the leads displayed
4. Open date filter (top header)
5. Select different date range (e.g., "Last 7 Days" instead of "Today")
6. **Expected**: Feedback Calls tab automatically refreshes with data for selected date range
7. Repeat for **Booking Confirmation** and **JustDial** tabs

### Test 3: Combined Store + Date Filter
1. Open Lead Screen
2. Navigate to **JustDial** tab
3. Change store filter to "SG-Chavakkad"
4. Change date filter to "This Month"
5. **Expected**: JustDial tab refreshes with data matching both filters

### Test 4: Tab Switching
1. Open Lead Screen
2. Navigate to **Booking Confirmation** tab
3. Switch to **Feedback Calls** tab
4. **Expected**: Feedback Calls data loads correctly
5. Switch back to **Booking Confirmation** tab
6. **Expected**: Booking Confirmation data is still there (cached)

### Test 5: Pull-to-Refresh Still Works
1. Open Lead Screen
2. Navigate to any tab
3. Pull down to refresh
4. **Expected**: Data refreshes manually

### Test 6: No Duplicate Fetches
1. Open Lead Screen
2. Open device logs (Android Studio / Xcode)
3. Change store filter
4. **Expected**: Only ONE fetch request for the current tab (not multiple)
5. Change date filter
6. **Expected**: Only ONE fetch request for the current tab (not multiple)

## What Should NOT Happen

- ❌ All tabs refreshing when you change filter (only active tab should refresh)
- ❌ Multiple fetch requests for same filter change
- ❌ Data not updating when filter changes
- ❌ App crashing when switching tabs
- ❌ Memory leaks when navigating away from Lead Screen

## Debug Logging

To verify the listener is working, check the lead_screen_controller logs:

```
LeadScreenController: _onHeaderChanged triggered
LeadScreenController: Fetching leads with new filters
```

## Performance Notes

- **Before**: didChangeDependencies() called on every dependency change (inefficient)
- **After**: _onHeaderChanged() called only when HeaderController changes (efficient)
- **Result**: Fewer unnecessary fetches, better performance

## Troubleshooting

### Issue: Data not refreshing when filter changes
**Solution**: 
- Check if listener is properly registered in initState()
- Verify HeaderController.notifyListeners() is called when filters change
- Check device logs for errors

### Issue: Multiple fetches on single filter change
**Solution**:
- Verify didChangeDependencies() was removed
- Check if _onHeaderChanged() is being called multiple times
- Add logging to track listener calls

### Issue: App crashes when navigating away
**Solution**:
- Verify dispose() method properly removes listener
- Check for null context errors in dispose()
- Ensure try-catch in dispose() handles exceptions

## Files to Monitor

- `frontend/lib/view/lead_screen/lead_screen.dart` - Main implementation
- `frontend/lib/controller/lead_screen_controller.dart` - Controller methods
- `frontend/lib/controller/header_controller.dart` - Filter state management
