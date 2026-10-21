# Frontend Report Flow Explanation

## Overview
The report flow in the frontend follows a **Provider-based state management pattern** with data flowing from the API through controllers to the UI.

---

## 1. ENTRY POINT: ReportsScreen

**File:** `frontend/lib/view/reports_screens/reports_screen.dart`

### What happens:
- User navigates to Reports tab
- `ReportsScreen` initializes and sets up the report controller
- Default filter: **Today's date**
- Calls `reportController.fetchReportsWithCurrentFilters()`

### Key Components:
```
ReportsScreen (UI)
    ↓
ReportController (State Management)
    ↓
LeadRepository (Data Access)
    ↓
ApiService (API Calls)
    ↓
Backend API
```

---

## 2. REPORT CONTROLLER: ReportController

**File:** `frontend/lib/controller/report_controller.dart`

### Main Methods:

#### a) `fetchReportsWithCurrentFilters()`
- Gets current date range from HeaderController
- Gets selected store from HeaderController
- Calls `fetchCompletedLeadsFromApi()` with date range and store

#### b) `fetchCompletedLeadsFromApi()`
- Makes API call to `/api/leads/completed`
- Passes parameters:
  - `store`: Selected store (or null for all stores)
  - `fromDate`: Start date (YYYY-MM-DD format)
  - `toDate`: End date (YYYY-MM-DD format)
  - `limit`: 1000 leads per request
- Receives response and parses into `ReportModel` objects
- Stores in `_reports` list
- Notifies listeners (UI updates)

#### c) `getFilteredLeads()`
- Converts API reports to display format
- Filters by:
  - Selected call type (Booking Confirmation, Enquiry, Feedback, Booking)
  - Selected store
  - Selected date category
- Returns formatted list for UI display

---

## 3. DATA FLOW: API Response → Display

### Step 1: API Response
```json
{
  "success": true,
  "data": {
    "leads": [
      {
        "_id": "69c364e14d45297cf261aff9",
        "leadtype": "bookingConfirmation",
        "name": "ANNA",
        "phone": "8590685376",
        "callDuration": "29",
        "updatedAt": "2026-03-28T05:00:26.384Z",
        ...
      }
    ]
  }
}
```

### Step 2: Parse to ReportModel
- `ReportModel.fromJson()` extracts:
  - `originalId`: Lead ID
  - `leadType`: Type of lead (bookingConfirmation, enquiry, etc.)
  - `callDuration`: Duration of call
  - `editedAt`: When the call was made (updatedAt)
  - `leadData`: All raw data from API

### Step 3: Convert to Display Format
- `getFilteredLeads()` transforms ReportModel to Map:
  ```dart
  {
    "id": "69c364e14d45297cf261aff9",
    "name": "ANNA",
    "phone": "8590685376",
    "date": "28 Mar, 2026",
    "callDate": "28 Mar, 2026",
    "callDuration": 29,
    "storeName": "Z-Edappally",
    "type": "bookingconfirmation",
    ...
  }
  ```

---

## 4. FILTERING LOGIC

### Date Filtering
- Uses `updatedAt` (when call was made) instead of `createdAt`
- Filters leads by selected date range
- Example: If today is 30/03/2026, only shows leads with `updatedAt` on 30/03/2026

### Category Filtering
- **Booking Confirmation Calls**: `leadtype == "bookingConfirmation"`
- **Enquiry Calls**: `leadtype == "enquiry"`
- **Feedback Calls**: `leadtype == "return"` or `"rentoutfeedback"`
- **Booking Calls**: Completed bookings

### Store Filtering
- Extracts location from store name
- Matches against lead's store location
- Supports "All Stores" (no filter)

---

## 5. UI DISPLAY: ReportsScreen → CallReportListScreen

### ReportsScreen Shows:
1. **Time Range Buttons**: Today, Last 7 Days, This Month, Last Month
2. **Store Selector**: Dropdown to select store
3. **Lead Report Cards**: Summary counts
   - Booking Confirmation Calls
   - Enquiry Calls
   - Feedback Calls
   - Booking Calls

### CallReportListScreen Shows:
1. **Tab Navigation**: All Calls, Loss of Sale, Feedback, Follow Up Calls
2. **Lead List**: Filtered leads with:
   - Customer name
   - Phone number
   - Call date
   - Call duration
   - Lead status

---

## 6. DETAIL SCREEN NAVIGATION

When user taps a report lead:

```
CallReportListScreen (List)
    ↓ (User taps lead)
NavigationHelper.navigateToDetails()
    ↓
Determines lead type:
    - Booking Confirmation → BookingDetailScreen
    - Enquiry → EnquiryDetailScreen
    - Feedback/Return → ReturnLeadDetailsScreen
    - Just Dial → JustDialDetailScreen
```

---

## 7. KEY DATA TRANSFORMATIONS

### API Response → ReportModel
```
API JSON → ReportModel.fromJson()
  - Extracts leadtype
  - Parses dates (createdAt, updatedAt)
  - Stores raw leadData
```

### ReportModel → Display Map
```
ReportModel → getFilteredLeads()
  - Formats dates to readable format (28 Mar, 2026)
  - Extracts customer info
  - Calculates call duration
  - Determines lead type for UI display
```

---

## 8. STATE MANAGEMENT FLOW

```
HeaderController (Selected Date, Store)
    ↓
ReportController (Fetches & Filters)
    ↓
_reports (List<ReportModel>)
    ↓
getFilteredLeads() (Transforms to display format)
    ↓
UI (ReportsScreen, CallReportListScreen)
```

### When User Changes:
- **Date Range**: HeaderController updates → ReportController refetches → UI updates
- **Store**: HeaderController updates → ReportController refetches → UI updates
- **Tab**: ReportController filters existing data → UI updates (no API call)

---

## 9. IMPORTANT NOTES

### Date Filtering
- Uses `updatedAt` (when call was made) not `createdAt` (when lead was created)
- This ensures leads appear in the correct date's report

### Call Duration
- Stored as string in API response
- Converted to int for display
- Shown in seconds or formatted as MM:SS

### Lead Type Mapping
```
API leadtype → Display type
"bookingConfirmation" → "bookingconfirmation"
"enquiry" → "enquiry"
"return" → "hardout"
"rentoutfeedback" → "hardout"
```

### Store Name Format
- API returns: "Brand - Location" (e.g., "Z-Edappally")
- Extracted for filtering and display

---

## 10. COMPLETE FLOW DIAGRAM

```
User Opens Reports
    ↓
ReportsScreen.initState()
    ↓
reportController.init(headerController)
    ↓
headerController.setDateRange(today)
    ↓
reportController.fetchReportsWithCurrentFilters()
    ↓
ApiService.getCompletedLeads(store, fromDate, toDate)
    ↓
Backend API /api/leads/completed
    ↓
Response: List<ReportModel>
    ↓
reportController._reports = response
    ↓
notifyListeners()
    ↓
ReportsScreen rebuilds
    ↓
getFilteredLeads() transforms data
    ↓
CallReportListScreen displays leads
    ↓
User taps lead
    ↓
NavigationHelper.navigateToDetails()
    ↓
Detail Screen (Booking/Enquiry/Feedback/JustDial)
```

---

## Summary

The report flow is a **clean separation of concerns**:
1. **UI Layer** (ReportsScreen, CallReportListScreen) - Displays data
2. **Controller Layer** (ReportController) - Manages state and filtering
3. **Data Layer** (LeadRepository, ApiService) - Fetches and caches data
4. **Model Layer** (ReportModel) - Defines data structure

Data flows **one direction**: API → Controller → UI, with state changes triggering UI updates via Provider's `notifyListeners()`.
