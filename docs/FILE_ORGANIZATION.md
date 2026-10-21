# File Organization Guide

## Naming Conventions

### File Names
- Use `snake_case` for file names
- Use descriptive names that indicate purpose
- Suffix files with their type when appropriate

**Examples:**
```
✓ lead_screen.dart
✓ lead_repository.dart
✓ api_service.dart
✓ color_constant.dart
✗ LeadScreen.dart
✗ leadScreen.dart
✗ screen.dart
```

### Class Names
- Use `PascalCase` for class names
- Use descriptive names
- Suffix with type when appropriate

**Examples:**
```
✓ class LeadScreen extends StatefulWidget {}
✓ class LeadRepository extends ChangeNotifier {}
✓ class ApiService {}
✓ class ColorConstant {}
✗ class lead_screen {}
✗ class leadScreen {}
```

### Variable Names
- Use `camelCase` for variables
- Use descriptive names
- Use `_` prefix for private variables

**Examples:**
```
✓ final String leadName;
✓ final List<LeadModel> _leads = [];
✓ bool _isLoading = false;
✗ final String lead_name;
✗ final List<LeadModel> leads = [];
```

### Constant Names
- Use `camelCase` for constants
- Group related constants in classes
- Use descriptive names

**Examples:**
```
✓ const String categoryJustDial = "Just Dial";
✓ const Duration initializationDelay = Duration(milliseconds: 500);
✗ const String CATEGORY_JUST_DIAL = "Just Dial";
✗ const String justdial = "Just Dial";
```

## Directory Structure

### View Layer (`lib/view/`)

**Organization by Feature:**
```
view/
├── home_screen/
│   ├── home_screen.dart
│   └── bottomnavigation_bar.dart
├── lead_screen/
│   ├── lead_screen.dart
│   ├── justdial_detail_screen.dart
│   ├── booking_confirmation_detail_screen.dart
│   └── return_lead_details_screen.dart
├── followup_screen/
│   ├── followup_screen.dart
│   └── followup_detail_screen.dart
├── complaints_screen/
│   ├── complaints_screen.dart
│   └── complaint_detail_screen.dart
├── reports_screens/
│   ├── reports_screen.dart
│   ├── call_report_list_screen.dart
│   └── report_details_screen/
│       ├── booking_detail_screen.dart
│       └── enquiry_detail_screen.dart
├── login_screen.dart
├── profile_screen.dart
└── call_card_details_screen.dart
```

**Rules:**
- One screen per file
- Group related screens in folders
- Use `_screen.dart` suffix for screen files
- Use `_detail_screen.dart` for detail/modal screens

### Controller Layer (`lib/controller/`)

**Organization by Feature:**
```
controller/
├── lead_repository.dart          # Central repository
├── lead_screen_controller.dart   # Lead screen logic
├── add_lead_controller.dart      # Add lead form
├── followup_controller.dart      # Follow-up logic
├── complaints_controller.dart    # Complaints logic
├── report_controller.dart        # Reports logic
├── header_controller.dart        # Header/filter logic
├── home_controller.dart          # Home screen logic
├── call_tracking_controller.dart # Call tracking
└── performance_controller.dart   # Performance metrics
```

**Rules:**
- One controller per file
- Use `_controller.dart` suffix
- Use `_repository.dart` for repository classes
- Group related logic in one controller

### Service Layer (`lib/services/`)

**Organization by Service Type:**
```
services/
├── api_service.dart              # HTTP API
├── auth_service.dart             # Authentication
├── phone_call_service.dart       # Phone calls
├── call_tracking_service.dart    # Call tracking
├── phone_identification_service.dart  # Phone lookup
├── incoming_call_handler.dart    # Incoming calls
└── notification_service.dart     # Notifications
```

**Rules:**
- One service per file
- Use `_service.dart` suffix
- Use `_handler.dart` for event handlers
- Group related functionality

### Model Layer (`lib/model/`)

**Organization by Entity:**
```
model/
├── lead_model.dart               # Lead entity
├── lead_display_model.dart       # Lead display wrapper
├── report_model.dart             # Report entity
├── complaint_model.dart          # Complaint entity
├── call_model.dart               # Call entity
├── store_model.dart              # Store entity
└── phone_check_result.dart       # Phone check result
```

**Rules:**
- One model per file
- Use `_model.dart` suffix
- Use descriptive entity names
- Include serialization methods

### Utils Layer (`lib/utils/`)

**Organization by Purpose:**
```
utils/
├── api_config.dart               # API configuration
├── lead_constants.dart           # Lead constants
├── color_constant.dart           # Colors
├── text_constant.dart            # Fonts & text
├── date_formatter.dart           # Date formatting
├── date_categorization.dart      # Date logic
├── store_location.dart           # Store data
├── navigation_helper.dart        # Navigation
├── responsive_helper.dart        # Responsive design
├── format_helper.dart            # Formatting
├── category_style.dart           # Styling
└── lead_storage.dart             # Storage keys
```

**Rules:**
- Group related utilities
- Use `_constant.dart` for constants
- Use `_helper.dart` for helper functions
- Use `_formatter.dart` for formatters
- Use `_config.dart` for configuration

### Widgets Layer (`lib/widgets.dart/`)

**Organization by Component Type:**
```
widgets.dart/
├── app_header.dart               # Header widget
├── call_card.dart                # Call card
├── common_widgets.dart           # Common components
├── add_lead_bottom_sheet.dart    # Add lead form
├── add_lead_outgoing_call_bottom_sheet.dart
├── new_lead_popup_sheet.dart
├── incoming_call_booking_popup_sheet.dart
├── incoming_call_complaint_popup_sheet.dart
├── incoming_call_feedback_popup_sheet.dart
├── incoming_call_followup_popup_sheet.dart
└── call_duration_display.dart
```

**Rules:**
- One widget per file (or related widgets)
- Use `_bottom_sheet.dart` for bottom sheets
- Use `_popup_sheet.dart` for popups
- Use descriptive names
- Group related widgets

## File Size Guidelines

### Recommended File Sizes
- **Small:** < 300 lines (single responsibility)
- **Medium:** 300-600 lines (related functionality)
- **Large:** 600-1000 lines (complex feature)
- **Too Large:** > 1000 lines (should be split)

### When to Split Files
- Multiple classes in one file
- Multiple responsibilities
- File exceeds 1000 lines
- Reusable components

## Import Organization

### Import Order
1. Dart imports
2. Flutter imports
3. Package imports
4. Relative imports

**Example:**
```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../model/lead_model.dart';
import '../services/api_service.dart';
import '../utils/color_constant.dart';
```

## Documentation Files

### Location
```
docs/
├── ARCHITECTURE.md           # Architecture overview
├── FILE_ORGANIZATION.md      # This file
├── API_DOCUMENTATION.md      # API endpoints
├── SETUP_GUIDE.md           # Setup instructions
└── implementation-notes/    # Implementation details
    ├── FEATURE_NAME.md
    └── ...
```

### Naming
- Use `UPPERCASE_WITH_UNDERSCORES.md` for main docs
- Use `lowercase_with_underscores.md` for feature docs
- Use descriptive names

## Cleanup Checklist

- [ ] Remove unused files
- [ ] Remove unused imports
- [ ] Remove commented code
- [ ] Remove debug print statements
- [ ] Remove TODO comments (or create issues)
- [ ] Verify file naming conventions
- [ ] Verify directory organization
- [ ] Update documentation

## Common Issues

### Issue: File Too Large
**Solution:** Split into multiple files by responsibility

### Issue: Unclear File Purpose
**Solution:** Use descriptive names with appropriate suffixes

### Issue: Misplaced Files
**Solution:** Follow feature-based organization

### Issue: Circular Dependencies
**Solution:** Reorganize to follow layered architecture

### Issue: Mixed Concerns
**Solution:** Separate business logic, UI, and data access

## Migration Guide

If reorganizing existing code:

1. **Plan:** Identify files to move/rename
2. **Create:** New directory structure
3. **Move:** Files to new locations
4. **Update:** All imports in affected files
5. **Test:** Verify app still runs
6. **Commit:** With clear commit message
7. **Document:** Changes in CHANGELOG

## Tools

### Dart Analysis
```bash
flutter analyze
```

### Format Code
```bash
dart format lib/
```

### Organize Imports
```bash
dart fix --apply
```
