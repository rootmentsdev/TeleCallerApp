# Complaints Screen - Share Button Added

## Overview
Added share functionality to every complaint card in the Complaints screen, allowing users to share complaint details via native share dialog.

## Changes Made

### File: `frontend/lib/view/complaints_screen/complaints_screen.dart`

#### 1. Added Import
```dart
import 'package:share_plus/share_plus.dart';
```

#### 2. Added Share Method
```dart
void _shareComplaint(Map<String, dynamic> complaint) {
  final shareText = '''
Complaint Details:
Name: ${complaint['name']}
Phone: ${complaint['phone']}
Store: ${complaint['store']}
Category: ${complaint['subCategory']}
Date: ${complaint['date']}
Remarks: ${complaint['remarks']}
''';
  Share.share(shareText);
}
```

#### 3. Updated Expanded Card Header
- Added share button next to complaint type badge
- Share button styled with blue background and icon
- Positioned in top-right corner with type badge

#### 4. Updated Collapsed Card Header
- Added share icon next to date
- Share icon styled in grey color
- Positioned in top-right corner

## Share Button Features

### Expanded Card
- Blue background container with share icon
- Positioned next to complaint type badge
- Consistent styling with other UI elements

### Collapsed Card
- Grey share icon
- Positioned next to date/time
- Compact design for collapsed view

### Share Content
When user taps share button, the following information is shared:
- Customer name
- Phone number
- Store location
- Complaint category
- Date and time
- Remarks/notes

## User Experience
✅ Share button visible on every complaint card
✅ Native share dialog opens on tap
✅ Formatted complaint details for easy sharing
✅ Works with all available share methods (Email, SMS, WhatsApp, etc.)
✅ Consistent styling across expanded and collapsed views

## Testing
1. Open Complaints screen
2. View complaint cards (both expanded and collapsed)
3. Tap share button on any card
4. Verify native share dialog opens
5. Select a share method (Email, SMS, WhatsApp, etc.)
6. Verify complaint details are properly formatted

## Dependencies
- `share_plus` package (already in pubspec.yaml)

## Future Enhancements
- Add share analytics tracking
- Customize share message template
- Add option to include complaint ID
- Add option to include complaint status
- Add share history/log
