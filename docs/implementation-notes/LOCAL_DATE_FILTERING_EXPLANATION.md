# Local Date Filtering - Complete Explanation

## Overview
Local date filtering occurs **on the device** (in the app) using data stored in `SharedPreferences`. This is different from API filtering which happens on the backend. The app uses local filtering for:

1. **Lead Screen** - Filters locally stored leads
2. **Report Screen** - Filters follow-up leads from local storage
3. **Call Summary** - Counts leads by date/category locally
4. **Dashboard Statistics** - Calculates metrics from local data

---

## Architecture

### Data Storage Hierarchy
```
Backend API
    ↓
API Response (Reports, Leads)
    ↓
LeadRepository (Singleton)
    ↓
SharedPreferences (Local Storage)
    ↓
LeadModel List (_leads)
    ↓
Local Filtering Methods
    ↓
UI Display
```

---

## 1. Core Local Filtering Methods

### File: `frontend/lib/controller/lead_repository.dart`

#### Method 1: `_applyDateFilter()` - Single Date Filter
```dart
/// Apply date filter to a list of leads
List<LeadModel> _applyDateFilter(List<LeadModel> leads, DateTime date) {
  return leads.where((lead) {
    final leadDate = lead.getEffectiveDate();
    return leadDate.year == date.year &&
        leadDate.month == date.month &&
        leadDate.day == date.day;
  }).toList();
}
```

**What it does:**
- Filters leads to match a specific date (year, month, day)
- Uses `lead.getEffectiveDate()` to get the lead's date
- Returns only leads created on that exact date

**Example:**
```dart
// Get all leads created on March 15, 2026
final leadsOnMarch15 = _applyDateFilter(_leads, DateTime(2026, 3, 15));
// Returns: [Lead1, Lead3, Lead5] (only leads with createdAt = March 15)
```

---

#### Method 2: `getLeadsByDateRange()` - Date Range Filter
```dart
/// Get leads within a date range (inclusive)
List<LeadModel> getLeadsByDateRange(DateTime startDate, DateTime endDate) {
  // Normalize dates to start of day for comparison
  final start = DateTime.utc(startDate.year, startDate.month, startDate.day);
  final end = DateTime.utc(endDate.year, endDate.month, endDate.day);

  return _leads.where((lead) {
    final leadDate = lead.getEffectiveDate();
    final normalizedLeadDate = DateTime.utc(
      leadDate.year,
      leadDate.month,
      leadDate.day,
    );
    // Check if lead date is within range (inclusive)
    return normalizedLeadDate.compareTo(start) >= 0 &&
        normalizedLeadDate.compareTo(end) <= 0;
  }).toList();
}
```

**What it does:**
- Filters leads within a date range (start to end, inclusive)
- Normalizes all dates to UTC for consistent comparison
- Compares dates at day level (ignores time)

**Example:**
```dart
// Get all leads from March 10 to March 20, 2026
final leadsInRange = getLeadsByDateRange(
  DateTime(2026, 3, 10),
  DateTime(2026, 3, 20),
);
// Returns: [Lead1, Lead2, Lead3, ...] (all leads between March 10-20)
```

---

#### Method 3: `getLeadsByDate()` - Simple Single Date
```dart
List<LeadModel> getLeadsByDate(DateTime date) =>
    _applyDateFilter(_leads, date);
```

**What it does:**
- Wrapper around `_applyDateFilter()`
- Gets all leads for a specific date

---

#### Method 4: `getLeadsByStoreAndDate()` - Combined Filter
```dart
List<LeadModel> getLeadsByStoreAndDate(String? store, DateTime date) {
  List<LeadModel> baseList = _leads;
  if (store != null && store != 'All Stores') {
    final location = _extractLocationFromStore(store);
    baseList = baseList.where((lead) => lead.location == location).toList();
  }
  return _applyDateFilter(baseList, date);
}
```

**What it does:**
- Filters by BOTH store AND date
- First filters by store, then by date
- Returns leads matching both criteria

**Example:**
```dart
// Get leads from SG-Edappally on March 15, 2026
final leads = getLeadsByStoreAndDate("SG-Edappally", DateTime(2026, 3, 15));
// Returns: [Lead1, Lead3] (only leads from that store on that date)
```

---

#### Method 5: `getLeadsByCategory()` - Category + Date Filter
```dart
List<LeadModel> getLeadsByCategory(String? category, {DateTime? date}) {
  List<LeadModel> filtered =
      date != null ? _applyDateFilter(_leads, date) : _leads;
  if (category == null || category == 'All') return filtered;
  return filtered.where((lead) => lead.category == category).toList();
}
```

**What it does:**
- Filters by category (optional date filter)
- If date provided, applies date filter first
- Then filters by category

**Example:**
```dart
// Get all "Loss of Sale" leads on March 15
final lossOfSaleLeads = getLeadsByCategory(
  "Loss of Sale",
  date: DateTime(2026, 3, 15),
);
```

---

## 2. Count Methods with Date Filtering

### Method 6: `getCountByCategory()` - Count by Category + Date
```dart
int getCountByCategory(String category, {String? store, DateTime? date}) {
  List<LeadModel> filtered =
      date != null ? _applyDateFilter(_leads, date) : _leads;
  if (store != null && store != 'All Stores') {
    filtered =
        filtered
            .where(
              (lead) => lead.location == _extractLocationFromStore(store),
            )
            .toList();
  }
  return filtered.where((lead) => lead.category == category).length;
}
```

**What it does:**
- Counts leads by category
- Optionally filters by date and store first
- Returns count (integer)

**Example:**
```dart
// Count "Return" leads on March 15 from SG-Edappally
int count = getCountByCategory(
  "Return",
  store: "SG-Edappally",
  date: DateTime(2026, 3, 15),
);
// Returns: 5 (5 return leads from that store on that date)
```

---

### Method 7: `getCountByCallStatus()` - Count by Call Status + Date
```dart
int getCountByCallStatus(String callStatus, {String? store, DateTime? date}) {
  List<LeadModel> filtered =
      date != null ? _applyDateFilter(_leads, date) : _leads;
  if (store != null && store != 'All Stores') {
    filtered =
        filtered
            .where(
              (lead) => lead.location == _extractLocationFromStore(store),
            )
            .toList();
  }
  return filtered.where((lead) => lead.callStatus == callStatus).length;
}
```

**What it does:**
- Counts leads by call status (e.g., "Called", "Not Called")
- Optionally filters by date and store
- Returns count

---

### Method 8: `getTotalLeadsCount()` - Total Count with Filters
```dart
int getTotalLeadsCount({String? store, DateTime? date}) {
  List<LeadModel> filtered =
      date != null ? _applyDateFilter(_leads, date) : _leads;
  if (store != null && store != 'All Stores') {
    filtered =
        filtered
            .where(
              (lead) => lead.location == _extractLocationFromStore(store),
            )
            .toList();
  }
  return filtered.length;
}
```

**What it does:**
- Gets total count of leads
- Optionally filters by date and store
- Returns total count

---

## 3. Usage in Controllers

### LeadScreenController - Local Date Filtering

**File:** `frontend/lib/controller/lead_screen_controller.dart`

#### Single Date Filtering:
```dart
int getCalledLeadsCount({String? category}) {
  DateTime? date;
  
  // Get selected date from header
  date = _headerController?.selectedDate ?? DateTime.now();

  List<LeadModel> leads = _repository.allLeads;

  // Filter by single date
  if (date != null) {
    final selectedDate = date;
    leads = leads.where((lead) {
      final leadDate = lead.getEffectiveDate();
      return leadDate.year == selectedDate.year &&
          leadDate.month == selectedDate.month &&
          leadDate.day == selectedDate.day;
    }).toList();
  }

  // Filter by category if provided
  if (category != null) {
    leads = leads.where((lead) => lead.category == category).toList();
  }

  // Filter by store if selected
  final storeFilter = _headerController?.selectedStore;
  if (storeFilter != null && storeFilter != "All Stores") {
    leads = leads
        .where((lead) => _repository.matchesStore(lead, storeFilter))
        .toList();
  }

  // Filter for CALLED leads only
  leads = leads
      .where((lead) => LeadConstants.isCalledStatus(lead.callStatus))
      .toList();

  return leads.length;
}
```

**What it does:**
1. Gets all leads from repository
2. Filters by selected date (year, month, day match)
3. Filters by category if provided
4. Filters by store if selected
5. Filters for called leads only
6. Returns count

---

#### Date Range Filtering:
```dart
int getCalledLeadsCount({String? category}) {
  DateTime? dateStart;
  DateTime? dateEnd;

  // Check if range mode is enabled
  if (_headerController?.isRangeMode == true &&
      _headerController?.dateRangeStart != null &&
      _headerController?.dateRangeEnd != null) {
    dateStart = _headerController!.dateRangeStart;
    dateEnd = _headerController!.dateRangeEnd;
  }

  List<LeadModel> leads = _repository.allLeads;

  // Filter by date range
  if (dateStart != null && dateEnd != null) {
    final start = dateStart;
    final end = dateEnd;
    leads = leads.where((lead) {
      final leadDate = lead.getEffectiveDate();
      final normalizedLeadDate = DateTime.utc(
        leadDate.year,
        leadDate.month,
        leadDate.day,
      );
      final normalizedStart = DateTime.utc(
        start.year,
        start.month,
        start.day,
      );
      final normalizedEnd = DateTime.utc(end.year, end.month, end.day);
      return normalizedLeadDate.compareTo(normalizedStart) >= 0 &&
          normalizedLeadDate.compareTo(normalizedEnd) <= 0;
    }).toList();
  }

  // ... rest of filtering
  return leads.length;
}
```

**What it does:**
1. Checks if date range mode is enabled
2. Gets start and end dates from header controller
3. Normalizes all dates to UTC for comparison
4. Filters leads within the range (inclusive)
5. Continues with category, store, and call status filtering

---

### ReportController - Local Follow-up Filtering

**File:** `frontend/lib/controller/report_controller.dart`

```dart
// For tabs 0-3, use API reports
// For tab 6 (Follow-up Leads), use local repository filtering

if (_selectedCallTypeIndex == 6) {
  // Get leads by date range if available, otherwise by single date
  List<dynamic> allLeads;
  if (_headerController?.isRangeMode == true &&
      _headerController?.dateRangeStart != null &&
      _headerController?.dateRangeEnd != null) {
    allLeads = _repository.getLeadsByDateRange(
      _headerController!.dateRangeStart!,
      _headerController!.dateRangeEnd!,
    );
  } else {
    final selectedDate = _headerController?.selectedDate ?? DateTime.now();
    allLeads = _repository.getLeadsByDate(selectedDate);
  }

  // Filter only leads with follow-up date set
  List<dynamic> followUpLeads = allLeads.where((lead) {
    return lead.followUpDate != null;
  }).toList();

  // Filter by store if specified
  if (storeFilter != null) {
    final location = StoreLocations.resolveSelection(storeFilter).location;
    followUpLeads = followUpLeads.where((lead) {
      final leadLocation = lead.location ?? '';
      return leadLocation.toLowerCase().contains(
            location.toLowerCase(),
          ) ||
          location.toLowerCase().contains(leadLocation.toLowerCase());
    }).toList();
  }

  // Convert to display format
  return followUpLeads.map((lead) {
    return {
      "id": lead.id,
      "name": lead.name,
      "phone": lead.phone,
      "date": _formatDate(lead.createdAt),
      "followUpDate": lead.followUpDate?.toIso8601String(),
      // ... other fields
    };
  }).toList();
}
```

**What it does:**
1. Checks if follow-up tab is selected (tab 6)
2. Gets leads by date range or single date from local repository
3. Filters to only leads with `followUpDate` set
4. Filters by store if selected
5. Converts to display format
6. Returns filtered follow-up leads

---

## 4. Date Comparison Logic

### How Dates Are Compared

#### Single Date Comparison:
```dart
// Check if lead date matches selected date
leadDate.year == selectedDate.year &&
leadDate.month == selectedDate.month &&
leadDate.day == selectedDate.day
```

**Example:**
```
Lead created: 2026-03-15 14:30:00
Selected date: 2026-03-15 00:00:00
Match: YES (same year, month, day)

Lead created: 2026-03-14 23:59:59
Selected date: 2026-03-15 00:00:00
Match: NO (different day)
```

---

#### Date Range Comparison:
```dart
// Normalize to UTC for consistent comparison
final normalizedLeadDate = DateTime.utc(
  leadDate.year,
  leadDate.month,
  leadDate.day,
);
final normalizedStart = DateTime.utc(
  start.year,
  start.month,
  start.day,
);
final normalizedEnd = DateTime.utc(end.year, end.month, end.day);

// Check if within range (inclusive)
return normalizedLeadDate.compareTo(normalizedStart) >= 0 &&
    normalizedLeadDate.compareTo(normalizedEnd) <= 0;
```

**Example:**
```
Range: March 10 - March 20, 2026

Lead 1: March 9 → NO (before range)
Lead 2: March 10 → YES (start of range)
Lead 3: March 15 → YES (within range)
Lead 4: March 20 → YES (end of range)
Lead 5: March 21 → NO (after range)
```

---

## 5. Effective Date Logic

### `lead.getEffectiveDate()` Method

The app uses an "effective date" concept to determine which date to use for filtering:

```dart
// In LeadModel
DateTime getEffectiveDate() {
  // Priority order:
  // 1. enquiryDate (if set)
  // 2. functionDate (if set)
  // 3. createdAt (default)
  
  if (enquiryDate != null) return enquiryDate!;
  if (functionDate != null) return functionDate!;
  return createdAt;
}
```

**Why?**
- Different lead types have different relevant dates
- Return leads: Use enquiry date
- Booking leads: Use function date
- General leads: Use creation date

**Example:**
```dart
// Return lead
Lead {
  createdAt: 2026-03-15,
  enquiryDate: 2026-03-10,
  functionDate: null,
}
// getEffectiveDate() returns: 2026-03-10 (enquiry date)

// Booking lead
Lead {
  createdAt: 2026-03-15,
  enquiryDate: null,
  functionDate: 2026-03-20,
}
// getEffectiveDate() returns: 2026-03-20 (function date)

// General lead
Lead {
  createdAt: 2026-03-15,
  enquiryDate: null,
  functionDate: null,
}
// getEffectiveDate() returns: 2026-03-15 (created at)
```

---

## 6. Complete Data Flow Example

### Scenario: User filters for "Loss of Sale" leads on March 15, 2026, from SG-Edappally

#### Step 1: User selects date and store
```dart
// AppHeader
headerController.setSelectedDate(DateTime(2026, 3, 15));
headerController.setSelectedStore("SG-Edappally");
```

#### Step 2: LeadScreenController detects change
```dart
void _onHeaderChanged() {
  notifyListeners();
  _fetchLeadsForCurrentFilters(...);
}
```

#### Step 3: Local filtering in LeadScreenController
```dart
int getCalledLeadsCount({String? category}) {
  // 1. Get all leads from repository
  List<LeadModel> leads = _repository.allLeads;
  // leads = [Lead1, Lead2, Lead3, Lead4, Lead5, ...]

  // 2. Filter by date (March 15, 2026)
  leads = leads.where((lead) {
    final leadDate = lead.getEffectiveDate();
    return leadDate.year == 2026 &&
        leadDate.month == 3 &&
        leadDate.day == 15;
  }).toList();
  // leads = [Lead1, Lead3, Lead5] (only March 15 leads)

  // 3. Filter by category (Loss of Sale)
  if (category != null) {
    leads = leads.where((lead) => lead.category == category).toList();
  }
  // leads = [Lead1, Lead3] (only Loss of Sale leads)

  // 4. Filter by store (SG-Edappally)
  final storeFilter = "SG-Edappally";
  leads = leads
      .where((lead) => _repository.matchesStore(lead, storeFilter))
      .toList();
  // leads = [Lead1] (only from SG-Edappally)

  // 5. Filter for called leads
  leads = leads
      .where((lead) => LeadConstants.isCalledStatus(lead.callStatus))
      .toList();
  // leads = [Lead1] (only called leads)

  return leads.length; // Returns: 1
}
```

#### Step 4: UI displays result
```
Loss of Sale Calls: 1
```

---

## 7. Performance Considerations

### Filtering Chain
```
All Leads (1000+)
    ↓ Filter by date
Leads on March 15 (50)
    ↓ Filter by category
Loss of Sale leads (10)
    ↓ Filter by store
SG-Edappally leads (3)
    ↓ Filter by call status
Called leads (2)
```

**Why this order?**
- Date filter reduces dataset most (1000 → 50)
- Category filter reduces further (50 → 10)
- Store filter reduces more (10 → 3)
- Call status filter is final (3 → 2)

**Result:** Efficient filtering with minimal iterations

---

## 8. Summary Table

| Method | Input | Output | Use Case |
|--------|-------|--------|----------|
| `_applyDateFilter()` | List, Date | Filtered List | Single date filtering |
| `getLeadsByDateRange()` | Start Date, End Date | Filtered List | Date range filtering |
| `getLeadsByDate()` | Date | Filtered List | Get leads for one day |
| `getLeadsByStoreAndDate()` | Store, Date | Filtered List | Combined store + date |
| `getLeadsByCategory()` | Category, Date? | Filtered List | Category + optional date |
| `getCountByCategory()` | Category, Store?, Date? | Count | Count by category |
| `getCountByCallStatus()` | Status, Store?, Date? | Count | Count by call status |
| `getTotalLeadsCount()` | Store?, Date? | Count | Total count |

---

## 9. Key Differences: Local vs API Filtering

| Aspect | Local Filtering | API Filtering |
|--------|-----------------|---------------|
| **Data Source** | SharedPreferences | Backend Database |
| **Speed** | Fast (in-memory) | Slower (network) |
| **Data Volume** | Limited (device storage) | Unlimited (server) |
| **Used For** | Leads, Follow-ups | Reports, Completed calls |
| **Date Params** | Single date or range | ISO8601 with time |
| **Filtering Logic** | Year/Month/Day comparison | Backend query |
| **Real-time** | Immediate | Depends on network |

---

## 10. Conclusion

Local date filtering in the Telecaller app:
- ✅ Filters leads stored in `SharedPreferences`
- ✅ Supports single date and date range filtering
- ✅ Combines with store and category filters
- ✅ Used for dashboard statistics and lead screens
- ✅ Efficient filtering chain (date → category → store → status)
- ✅ Uses "effective date" concept for different lead types
- ✅ Complements API filtering for complete data management
