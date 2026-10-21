# Architecture Guide

## Overview

The Telecaller App follows a layered architecture pattern with clear separation of concerns:

```
┌─────────────────────────────────────────┐
│         UI Layer (Views)                │
│  - Screens, Widgets, UI Components      │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│    Controller Layer (State Mgmt)        │
│  - Business Logic, Data Processing      │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│    Repository Layer (Data Access)       │
│  - Local Storage, Data Sync             │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│    Service Layer (External APIs)        │
│  - HTTP Requests, Authentication        │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│    Model Layer (Data Structures)        │
│  - Data Classes, Serialization          │
└─────────────────────────────────────────┘
```

## Directory Structure

### `/lib/view/`
Contains all UI screens organized by feature:

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
├── login_screen.dart
├── profile_screen.dart
└── call_card_details_screen.dart
```

**Responsibilities:**
- Build UI using Flutter widgets
- Handle user interactions
- Call controller methods
- Display data from controllers
- Show loading/error states

### `/lib/controller/`
Contains business logic and state management:

```
controller/
├── lead_repository.dart          # Central data repository
├── lead_screen_controller.dart   # Lead screen logic
├── lead_screen_controller.dart   # Lead screen logic
├── add_lead_controller.dart      # Add lead form logic
├── followup_controller.dart      # Follow-up logic
├── complaints_controller.dart    # Complaints logic
├── report_controller.dart        # Reports logic
├── header_controller.dart        # Header/filter logic
├── home_controller.dart          # Home screen logic
├── call_tracking_controller.dart # Call tracking logic
└── performance_controller.dart   # Performance metrics
```

**Responsibilities:**
- Implement business logic
- Manage application state
- Communicate with repositories
- Notify listeners of state changes
- Handle data transformations

### `/lib/services/`
Contains external service integrations:

```
services/
├── api_service.dart              # HTTP API calls
├── auth_service.dart             # Authentication
├── phone_call_service.dart       # Phone call integration
├── call_tracking_service.dart    # Call duration tracking
├── phone_identification_service.dart  # Phone lookup
├── incoming_call_handler.dart    # Incoming call handling
└── notification_service.dart     # Push notifications
```

**Responsibilities:**
- Make HTTP requests
- Handle authentication
- Integrate with device features
- Manage external APIs
- Error handling and retries

### `/lib/model/`
Contains data models:

```
model/
├── lead_model.dart               # Lead data structure
├── lead_display_model.dart       # Lead display wrapper
├── report_model.dart             # Report data
├── complaint_model.dart          # Complaint data
├── call_model.dart               # Call data
├── store_model.dart              # Store data
└── phone_check_result.dart       # Phone check result
```

**Responsibilities:**
- Define data structures
- Implement serialization (toMap, fromMap)
- Implement JSON conversion (toJson, fromJson)
- Data validation

### `/lib/utils/`
Contains utilities and constants:

```
utils/
├── api_config.dart               # API endpoints
├── lead_constants.dart           # Lead-related constants
├── color_constant.dart           # Color palette
├── text_constant.dart            # Font families
├── date_formatter.dart           # Date formatting
├── date_categorization.dart      # Date categorization logic
├── store_location.dart           # Store location data
├── navigation_helper.dart        # Navigation utilities
├── responsive_helper.dart        # Responsive design
├── format_helper.dart            # Formatting utilities
├── category_style.dart           # Category styling
└── lead_storage.dart             # Local storage keys
```

**Responsibilities:**
- Define constants
- Provide helper functions
- Format data
- Navigation utilities

### `/lib/widgets.dart/`
Contains reusable UI components:

```
widgets.dart/
├── app_header.dart               # App header widget
├── call_card.dart                # Call card widget
├── common_widgets.dart           # Common UI components
├── add_lead_bottom_sheet.dart    # Add lead form
├── add_lead_outgoing_call_bottom_sheet.dart
├── new_lead_popup_sheet.dart
├── incoming_call_*_popup_sheet.dart  # Incoming call popups
└── call_duration_display.dart
```

**Responsibilities:**
- Reusable UI components
- Consistent styling
- Encapsulated widget logic

## Data Flow

### Creating a Lead

```
1. User fills form in AddLeadBottomSheet
2. Calls AddLeadController.addLead()
3. Controller validates data
4. Calls ApiService.createLead()
5. ApiService makes HTTP POST request
6. Response is parsed to LeadModel
7. LeadRepository.addLead() stores locally
8. Repository notifies listeners
9. UI updates with new lead
```

### Fetching Leads

```
1. Screen loads (initState)
2. Calls LeadScreenController.fetchLeadsFromApi()
3. Controller calls LeadRepository.fetchLeadsFromApi()
4. Repository calls ApiService.getLeads()
5. ApiService makes HTTP GET request
6. Response is parsed to List<LeadModel>
7. Repository stores in memory and local storage
8. Repository notifies listeners
9. UI rebuilds with new data
```

### Updating a Lead

```
1. User submits form in detail screen
2. Calls LeadScreenController.updateLead()
3. Controller calls ApiService.updateLead()
4. ApiService makes HTTP POST request
5. Response is parsed
6. LeadRepository.updateLead() updates local data
7. Repository notifies listeners
8. UI updates
9. Navigation back to list
```

## State Management

### ChangeNotifier Pattern

Controllers extend `ChangeNotifier` to manage state:

```dart
class LeadScreenController extends ChangeNotifier {
  List<LeadModel> _leads = [];
  
  List<LeadModel> get leads => _leads;
  
  Future<void> fetchLeads() async {
    _leads = await _repository.fetchLeads();
    notifyListeners();  // Notify UI to rebuild
  }
}
```

### Provider Integration

UI widgets use `Consumer` to listen to controller changes:

```dart
Consumer<LeadScreenController>(
  builder: (context, controller, child) {
    return ListView(
      children: controller.leads.map((lead) => LeadCard(lead)).toList(),
    );
  },
)
```

## Error Handling

### API Errors

```dart
try {
  final response = await apiService.getLeads();
  // Process response
} catch (e) {
  // Log to Firebase Crashlytics
  FirebaseCrashlytics.instance.recordError(e, stackTrace);
  // Show user-friendly error message
  showErrorSnackBar('Failed to load leads');
}
```

### Validation

```dart
if (phoneNumber.isEmpty) {
  throw ValidationException('Phone number is required');
}
```

## Best Practices

### 1. Separation of Concerns
- Views only handle UI
- Controllers handle business logic
- Services handle external APIs
- Models define data structures

### 2. Dependency Injection
- Use Provider for dependency injection
- Avoid creating instances directly
- Pass dependencies through constructors

### 3. Error Handling
- Always wrap API calls in try-catch
- Log errors to Crashlytics
- Show user-friendly error messages
- Provide retry mechanisms

### 4. State Management
- Use ChangeNotifier for state
- Notify listeners when state changes
- Avoid direct state mutations
- Use immutable data structures where possible

### 5. Code Organization
- One class per file
- Meaningful file names
- Clear method names
- Proper documentation

### 6. Testing
- Unit test models and utilities
- Widget test UI components
- Integration test API calls
- Mock external dependencies

## Performance Considerations

### 1. Data Caching
- Cache API responses locally
- Avoid redundant API calls
- Implement cache invalidation

### 2. List Performance
- Use ListView.builder for large lists
- Implement pagination
- Lazy load data

### 3. Image Optimization
- Compress images
- Use appropriate image sizes
- Implement image caching

### 4. Memory Management
- Dispose controllers properly
- Clean up listeners
- Avoid memory leaks

## Security

### 1. Authentication
- Store tokens securely
- Implement token refresh
- Handle session expiration

### 2. Data Protection
- Validate user input
- Sanitize API responses
- Encrypt sensitive data

### 3. API Security
- Use HTTPS only
- Implement request signing
- Validate SSL certificates

## Future Improvements

1. **Offline Support**
   - Implement offline-first architecture
   - Sync data when online

2. **Performance**
   - Implement pagination
   - Add data caching strategies
   - Optimize list rendering

3. **Testing**
   - Add comprehensive unit tests
   - Add widget tests
   - Add integration tests

4. **Accessibility**
   - Add semantic labels
   - Improve color contrast
   - Support screen readers

5. **Internationalization**
   - Add multi-language support
   - Localize date/time formats
   - Localize currency formats
