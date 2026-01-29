# Complaints Screen - Double-Tap to Close Details Added

## Overview
Added double-tap functionality to expanded complaint cards. When user double-taps on an expanded card, it collapses back to the normal summary view.

## Changes Made

### File: `frontend/lib/view/complaints_screen/complaints_screen.dart`

#### Updated Expanded Card with GestureDetector
Wrapped the expanded card Container with GestureDetector:

```dart
if (isExpanded) {
  return GestureDetector(
    onDoubleTap: () {
      setState(() {
        complaint['isExpanded'] = false;
      });
    },
    child: Container(
      // ... expanded card content
    ),
  );
}
```

## Interaction Flow

### Single Click (Details Button)
- Collapsed card → Expanded card (shows full details)
- Expanded card → Collapsed card (hides details)

### Double-Tap
- Expanded card → Collapsed card (quick close)
- Works anywhere on the expanded card

## User Experience
✅ Click "Details" button to expand/collapse
✅ Double-tap expanded card to quickly close
✅ Smooth state transition
✅ Intuitive gesture-based interaction
✅ Works with all card content

## Features
- **Single Click**: Toggle expand/collapse via Details button
- **Double-Tap**: Quick close for expanded cards
- **Flexible**: Both methods work seamlessly
- **Responsive**: Immediate state update

## Testing
1. Open Complaints screen
2. Click "Details" on a collapsed card → Card expands
3. Double-tap anywhere on the expanded card → Card collapses
4. Click "Details" again → Card expands
5. Double-tap again → Card collapses
6. Verify smooth transitions

## Gesture Handling
- **onDoubleTap**: Detects double-tap gesture on expanded card
- **setState**: Updates isExpanded flag to false
- **Immediate Collapse**: Card immediately shows collapsed view

## Benefits
- Faster interaction for users
- More intuitive gesture-based UI
- Reduces need to find Details button
- Improves user experience
- Follows modern mobile app patterns

## Future Enhancements
- Add animation for expand/collapse
- Add haptic feedback on double-tap
- Add visual feedback during double-tap
- Add swipe gestures for collapse
- Add keyboard shortcuts for desktop
