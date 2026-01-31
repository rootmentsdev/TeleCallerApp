 📞 Telecaller App

A Flutter-based mobile application built to support telecaller teams in managing leads, calls, follow-ups, complaints, and reports efficiently.

 ✨ Overview

The Telecaller App helps telecallers handle their daily workflow with features like:

- Lead creation & tracking
- Call logging & duration tracking
- Follow-up scheduling
- Complaint management
- Performance reports & analytics
- Multi-store filtering

📂 Project Structure

```
frontend/
├── lib/
│   ├── main.dart                  # App entry point
│   ├── controller/                # State & business logic
│   │   ├── lead_screen_controller.dart
│   │   ├── report_controller.dart
│   │   ├── lead_repository.dart
│   │   └── header_controller.dart
│   ├── view/                      # UI Screens
│   │   ├── home_screen/
│   │   ├── lead_screen/
│   │   ├── followup_screen/
│   │   ├── complaints_screen/
│   │   └── reports_screens/
│   ├── model/                     # Data Models
│   │   ├── lead_model.dart
│   │   ├── report_model.dart
│   │   └── call_model.dart
│   ├── services/                  # API & integrations
│   │   ├── api_service.dart
│   │   ├── auth_service.dart
│   │   └── phone_call_service.dart
│   ├── widgets/                   # Reusable components
│   │   ├── add_lead_bottom_sheet.dart
│   │   ├── add_lead_outgoing_call_bottom_sheet.dart
│   │   └── common_widgets.dart
│   └── utils/                     # Constants & helpers
│       ├── api_config.dart
│       ├── color_constant.dart
│       └── navigation_helper.dart
├── pubspec.yaml                   # Dependencies
└── README.md                      # Documentation
```

🚀 Key Features

1. Lead Management
- Create leads from incoming/outgoing calls
- Track lead status and history
- Support lead types: Enquiry, Booking, Return, Feedback
- Store lead details with timestamps

 2. Call Tracking
- Real-time call duration tracking
- Call status handling (Connected, Not Called, etc.)
- Remarks and call notes storage
- Call history logging

 3. Follow-up Scheduling
- Schedule follow-up calls with optional dates
- Categorize follow-ups:
  - Today
  - Upcoming
  - Overdue
- Notifications for follow-ups

4. Complaint Management
- Mark leads as complaints
- Categorize complaints by type
- Track resolution status (Open, In Progress, Resolved)
- Link complaints to original leads

 5. Reports & Analytics
- Reports based on lead types
- Filters: Date range, Store/location
- Share/export call summaries
- Performance metrics

 6. Multi-Store Support
- Store-based filtering
- Location-based lead tracking
- Store-specific analytics

 🛠 Technology Stack

- **Framework**: Flutter 3.7.2+
- **State Management**: Provider
- **Storage**: Shared Preferences
- **Networking**: HTTP
- **Notifications**: Firebase Cloud Messaging + Local Notifications
- **Crash Reporting**: Firebase Crashlytics
- **Permissions**: permission_handler

📦 Dependencies

```yaml
dependencies:
  flutter: sdk: flutter
  provider: ^6.1.1
  http: ^0.13.6
  shared_preferences: ^2.2.2
  firebase_core: ^4.3.0
  firebase_crashlytics: ^5.0.6
  permission_handler: ^11.3.1
  flutter_local_notifications: ^17.0.0
  url_launcher: ^6.3.1
  share_plus: ^10.1.2
  intl: ^0.20.2
```

⚙️ Getting Started

 Prerequisites
- Flutter SDK 3.7.2+
- Android Studio / Xcode
- Backend API configured

Installation

1. Clone repository
```bash
git clone <repository-url>
cd frontend
```

2. Install packages
```bash
flutter pub get
```

3. Configure API
Edit `lib/utils/api_config.dart` with your backend URL

4. Run the application
```bash
flutter run
```

🏗 Build Commands

Debug APK
```bash
flutter build apk --debug
```

Release APK
```bash
flutter build apk --release
```

Split APKs (by architecture)
```bash
flutter build apk --release --split-per-abi
```

🧩 Architecture

The project follows **MVC + Provider** pattern:

- **Models**: Data structures and API response parsing
- **Views**: UI Screens and widgets
- **Controllers**: Business logic and state management
- **Services**: API communication and external integrations
- **Repository**: Local caching and data filtering

🔄 How It Works

1. User Authentication
- User logs in with Employee ID and Password
- Credentials validated against backend
- Authentication token stored locally
- Token automatically refreshed when expired

2. Lead Creation Flow

Incoming Call
1. User receives incoming call
2. App displays incoming call bottom sheet
3. User enters lead details (name, phone, store, location, etc.)
4. User selects function date (optional)
5. User can mark as complaint or follow-up
6. Save button enabled when call duration > 0
7. Lead created via API and stored locally

Outgoing Call
1. User initiates outgoing call
2. App tracks call duration in real-time
3. After call ends, user fills in lead details
4. Save button enabled when:
   - Call was made AND
   - (Call duration > 0 OR marked as follow-up)
5. Lead saved with call information

3. Lead Management
- **Lead Repository**: Maintains in-memory cache of all leads
- **Local Storage**: Leads persisted using Shared Preferences
- **API Sync**: Changes synced with backend API
- **Filtering**: Leads filtered by store, date, status, and type

4. Follow-up System
- Users mark leads as follow-ups with scheduled date
- Follow-ups categorized as:
  - **Today**: Follow-ups scheduled for today
  - **Upcoming**: Follow-ups scheduled for future dates
  - **Overdue**: Follow-ups past their scheduled date
- Follow-up screen displays all scheduled follow-ups
- Users can call directly from follow-up detail screen

5. Call Tracking
- **Real-time Duration**: Call duration tracked from when call starts
- **Call Status**: Tracks if call was connected or not called
- **Call History**: All calls logged with timestamp and duration
- **Reports**: Call data aggregated for performance reporting

6. Complaint Management
- Leads can be marked as complaints
- Complaints categorized by type (Product Quality, Delivery, etc.)
- Complaints tracked separately from regular leads
- Complaint status can be updated (Open, In Progress, Resolved)

7. Reports & Analytics
- **Report Types**: Enquiry, Booking, Feedback, Loss of Sale
- **Filtering**: Reports filtered by:
  - Date range
  - Store/Location
  - Lead type
  - Call status
- **Metrics**: Displays call count, duration, and status breakdown
- **Export**: Reports can be shared via email or messaging

8. Data Flow

```
User Input
    ↓
UI Screen (View)
    ↓
Controller (Business Logic)
    ↓
API Service (HTTP Request)
    ↓
Backend Server
    ↓
API Response
    ↓
Model (Parse Response)
    ↓
Repository (Cache & Store)
    ↓
UI Update (Display Data)
```

9. State Management with Provider

The app uses Provider for reactive state management:

**HeaderController**
- Manages selected store and date filters
- Notifies listeners when filters change
- Used by all screens for consistent filtering

**LeadScreenController**
- Manages lead list state
- Handles lead filtering and sorting
- Triggers API calls when needed

**ReportController**
- Manages report data
- Handles report filtering by type and date
- Caches report data for performance

**LeadRepository**
- Central data store for all leads
- Manages local persistence
- Provides filtered views of leads
- Syncs with backend API

10. Key Workflows

Creating a Lead from Incoming Call
```
1. Incoming call received
2. Bottom sheet opens with pre-filled phone number
3. User enters: name, store, location, remarks
4. User selects function date (optional)
5. User marks as complaint/follow-up (optional)
6. User taps "Save Lead"
7. Lead sent to API
8. Response parsed and stored locally
9. Bottom sheet closes
10. Lead appears in lead list
```

Scheduling a Follow-up
```
1. User opens a lead detail
2. User checks "Mark as Follow Up"
3. User selects follow-up date
4. User saves the lead
5. Lead moved to Follow-ups collection
6. Lead appears in Follow-up screen
7. On follow-up date, user can call directly
8. Call logged and linked to original lead
```

Viewing Reports
```
1. User navigates to Reports screen
2. User selects report type (Enquiry, Booking, etc.)
3. User selects date range
4. User selects store (optional)
5. Reports fetched from API
6. Reports displayed with metrics
7. User can tap on report to view details
8. User can share report via email/messaging
```

🌐 API Service Architecture

The `ApiService` class handles all backend communication. It's a singleton that manages:

Authentication
```dart
// Login with employee credentials
final response = await apiService.loginUser(
  empId: '12345',
  password: 'password123'
);
// Returns: token, refreshToken, user data
// Token is automatically saved to local storage
```

Lead Operations

**Create Lead**
```dart
final response = await apiService.createLead(
  leadName: 'John Doe',
  phoneNumber: '9876543210',
  store: 'Zorucci-Palakkad',
  source: 'Incoming Call',
  leadType: 'enquiry',
  functionDate: '2026-01-30T00:00:00.000Z',
  callDuration: 120,
  subCategory: 'Product Enquiry',
  markAsComplaint: false,
  followUpFlag: true,
);
// Returns: lead ID and created lead data
```

**Update Lead**
```dart
final response = await apiService.updateLead(
  id: 'lead123',
  leadName: 'John Doe',
  callStatus: 'Connected',
  leadStatus: 'Interested',
  remarks: 'Customer interested in product',
  followUpFlag: true,
  followUpDate: '2026-02-05T00:00:00.000Z',
);
// Returns: updated lead data
```

**Get All Leads**
```dart
final response = await apiService.getAllLeads(
  store: 'Zorucci-Palakkad',
  page: 1,
  dateFrom: '2026-01-01',
  dateTo: '2026-01-31',
);
// Returns: paginated list of leads
```

Report Operations

**Fetch Reports**
```dart
final response = await apiService.fetchReportsFromApi(
  leadType: 'enquiry',  // enquiry, return, bookingconfirmation, lossOfSale
  editedAtFrom: '2026-01-01',
  editedAtTo: '2026-01-31',
  page: 1,
  limit: 50,
);
// Returns: list of reports with metrics
```

Return Lead Operations

**Update Return Lead**
```dart
final response = await apiService.updateReturnLead(
  id: 'return123',
  callStatus: 'Connected',
  leadStatus: 'Satisfied',
  rating: 5,
  remarks: 'Customer satisfied with service',
  followUpFlag: false,
);
// Returns: updated return lead data
```

Walk-in Leads

**Get Walk-in Leads**
```dart
final response = await apiService.getWalkInLeads();
// Returns: list of walk-in leads
```

Request/Response Handling

**Request Body Format**
```dart
// All requests use snake_case for backend compatibility
{
  "customer_name": "John Doe",
  "phone_number": "9876543210",
  "store_location": "Zorucci-Palakkad",
  "lead_status": "No Status",
  "call_status": "Not Called",
  "function_date": "2026-01-30T00:00:00.000Z",
  "call_duration": 120,
  "mark_as_complaint": false,
  "follow_up_flag": true,
  "follow_up_date": "2026-02-05T00:00:00.000Z"
}
```

**Response Parsing**
- Responses automatically parsed into model objects
- Both snake_case and camelCase supported
- Null values handled gracefully
- Dates parsed from ISO 8601 format

Error Handling

**Status Code Handling**
- **200/201**: Success - response parsed and returned
- **400**: Validation error - detailed error message extracted
- **401**: Unauthorized - token refresh attempted, or session expired error
- **404**: Not found - specific resource error
- **5xx**: Server error - generic error message

**Error Response Example**
```dart
try {
  await apiService.createLead(...);
} catch (e) {
  // Error caught and logged to Firebase Crashlytics
  // User-friendly error message displayed
  print('Error: $e');
}
```

Authentication & Token Management

**Token Handling**
```
1. Token obtained during login
2. Token stored in Shared Preferences
3. Token included in all API requests via headers
4. If 401 response, token refresh attempted
5. If refresh fails, user redirected to login

Headers added to all requests:
{
  "Authorization": "Bearer $token",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

Key Features of ApiService

1. **Automatic Header Management**
   - Retrieves token from local storage
   - Adds authorization headers to all requests
   - Handles content-type negotiation

2. **Response Normalization**
   - Converts snake_case to camelCase
   - Handles both formats in responses
   - Normalizes nested objects

3. **Error Logging**
   - All errors logged to Firebase Crashlytics
   - Detailed error messages for debugging
   - Stack traces captured for analysis

4. **Null Value Handling**
   - Null values excluded from request body
   - Optional fields handled gracefully
   - Default values provided where needed

5. **Date Handling**
   - All dates converted to ISO 8601 format
   - Timezone-aware date handling
   - Consistent date formatting across app

6. **Session Management**
   - Automatic token refresh on 401
   - Session expiry callback
   - Graceful logout on auth failure

API Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/auth/login` | POST | User login |
| `/api/pages/add-lead` | POST | Create new lead |
| `/api/pages/leads/{id}` | POST | Update lead |
| `/api/pages/leads` | GET | Get all leads |
| `/api/reports` | GET | Fetch reports |
| `/api/return/{id}` | POST | Update return lead |
| `/api/walk-in-leads` | GET | Get walk-in leads |

Best Practices

1. **Always handle errors** - Wrap API calls in try-catch
2. **Use meaningful parameters** - Pass only required fields
3. **Check response structure** - Validate response before using
4. **Log important operations** - Use print statements for debugging
5. **Test with slow network** - Ensure app handles delays gracefully
6. **Validate input data** - Check data before sending to API
7. **Handle null responses** - Provide fallback values

🧯 Troubleshooting

Large Build Size
- **Debug APK**: ~147MB (includes debug symbols)
- **Release APK**: ~50–60MB (optimized)
- Use release mode for production

API Errors
- Verify API URL in `api_config.dart`
- Check backend server status
- Review logs in console

Permission Issues
- Ensure call permissions are granted
- Add required permissions in `AndroidManifest.xml`
- Request runtime permissions for call tracking

🤝 Contributing

When contributing:

1. Follow folder structure
2. Keep widgets reusable
3. Test on Android & iOS
4. Handle API errors properly
5. Update README for major changes
6. Ensure API calls handle errors gracefully
7. Test with slow network conditions

