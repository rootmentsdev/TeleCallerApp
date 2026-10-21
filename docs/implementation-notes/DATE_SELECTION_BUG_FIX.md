# Date Selection Bug Fix - Booking Confirmation Leads

## Issue Identified

**User selects**: 14/3/2026 (March 14, 2026)
**API receives**: 2026-03-18 (March 18, 2026 - Today's date)

### Screenshot Evidence
```
UI Shows: 14/3 - 14/3 (selected date)
API Call: fromDate=2026-03-18&toDate=2026-03-18 (today's date)
Result: Wrong date sent to backend ❌
```

---

## Root Cause

The `fetchBookingConfirmationLeadsFromApi()` method was **hardcoded to use today's date** instead of the **selected date from HeaderController**.

### Wrong Code
```dart
Future<void> fetchBookingConfirmationLeadsFromApi({String? store}) async {
  try {
    // ❌ WRONG: Always uses today's date
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Sends today's date to API, ignoring user's selection
    await _repository.fetchBookingConfirmationLeadsFromApi(
      store: store,
      fromDate: dateStr,  // ← Today's date, not selected date
      toDate: dateStr,    // ← Today's date, not selected date
    );
  } catch (e, s) {
    // ...
  }
}
```

### Correct Code
```dart
Future<void> fetchBookingConfirmationLeadsFromApi({String? store}) async {
  try {
    // ✅ CORRECT: Uses selected date from HeaderController
    final selectedDate = _headerController?.selectedDate ?? DateTime.now();
    final dateStr =
        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    // Sends selected date to API
    await _repository.fetchBookingConfirmationLeadsFromApi(
      store: store,
      fromDate: dateStr,  // ← Selected date from user
      toDate: dateStr,    // ← Selected date from user
    );
  } catch (e, s) {
    // ...
  }
}
```

---

## Data Flow Comparison

### Before Fix (WRONG)
```
User selects: 14/3/2026
  ↓
LeadScreen._fetchBookingConfirmationLeads()
  ↓
LeadScreenController.fetchBookingConfirmationLeadsFromApi()
  ↓
Gets DateTime.now() = 2026-03-18  ❌ IGNORES USER SELECTION
  ↓
API Call: GET /api/leads/booking-confirmation?fromDate=2026-03-18&toDate=2026-03-18
  ↓
Backend returns: Booking confirmations for 2026-03-18 (not 2026-03-14)
  ↓
Result: Wrong data shown ❌
```

### After Fix (CORRECT)
```
User selects: 14/3/2026
  ↓
LeadScreen._fetchBookingConfirmationLeads()
  ↓
LeadScreenController.fetchBookingConfirmationLeadsFromApi()
  ↓
Gets _headerController.selectedDate = 2026-03-14  ✅ USES USER SELECTION
  ↓
API Call: GET /api/leads/booking-confirmation?fromDate=2026-03-14&toDate=2026-03-14
  ↓
Backend returns: Booking confirmations for 2026-03-14 (correct date)
  ↓
Result: Correct data shown ✅
```

---

## Why This Happened

### HeaderController Stores Selected Date
```dart
class HeaderController extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  
  DateTime get selectedDate => _selectedDate;
  
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
}
```

### LeadScreenController Has Access to HeaderController
```dart
class LeadScreenController extends ChangeNotifier {
  final HeaderController? _headerController;
  
  // Can access selected date
  DateTime get selectedDate => _headerController?.selectedDate ?? DateTime.now();
}
```

### But fetchBookingConfirmationLeadsFromApi() Didn't Use It
```dart
// ❌ WRONG: Ignored _headerController.selectedDate
final now = DateTime.now();  // Always today
```

---

## Fix Applied

### File: `frontend/lib/controller/lead_screen_controller.dart`

**Method**: `fetchBookingConfirmationLeadsFromApi()`

**Change**:
```dart
// Before
final now = DateTime.now();

// After
final selectedDate = _headerController?.selectedDate ?? DateTime.now();
```

**Impact**:
- Now uses the date selected by user in the date picker
- Respects HeaderController's selectedDate
- Falls back to today's date if HeaderController is null

---

## Verification

### Before Fix
```
User selects: 14/3/2026
API receives: 2026-03-18 (today)
Result: ❌ Wrong date
```

### After Fix
```
User selects: 14/3/2026
API receives: 2026-03-14 (selected)
Result: ✅ Correct date
```

---

## Related Methods (Already Correct)

These methods already use the selected date correctly:

### 1. fetchReturnLeadsFromApi()
```dart
Future<void> fetchReturnLeadsFromApi({...}) async {
  final selectedDate = _headerController?.selectedDate ?? DateTime.now();
  // ✅ Uses selected date
}
```

### 2. fetchComplaintsFromApi()
```dart
Future<void> fetchComplaintsFromApi({...}) async {
  final selectedDate = _headerController?.selectedDate ?? DateTime.now();
  // ✅ Uses selected date
}
```

### 3. fetchFollowUpLeadsFromApi()
```dart
Future<void> fetchFollowUpLeadsFromApi({...}) async {
  final selectedDate = _headerController?.selectedDate ?? DateTime.now();
  // ✅ Uses selected date
}
```

**Only booking confirmation method was using hardcoded today's date.**

---

## Compilation Status

✅ **No errors** in `frontend/lib/controller/lead_screen_controller.dart`

---

## Testing

To verify the fix:

1. **Open Lead Screen**
2. **Select a date**: 14/3/2026 (or any date)
3. **Check logs**:
   ```
   LeadScreenController: Fetching booking confirmation leads (store=null, date=2026-03-14)
   ApiService: URL => https://rootstele.onrender.com/api/leads/booking-confirmation?fromDate=2026-03-14&toDate=2026-03-14
   ```
4. **Verify**: API receives the selected date, not today's date ✅

---

## Summary

| Aspect | Before | After |
|--------|--------|-------|
| **Date Used** | `DateTime.now()` (today) | `_headerController.selectedDate` (selected) |
| **User Selection** | ❌ Ignored | ✅ Respected |
| **API Call** | Wrong date sent | Correct date sent |
| **Data Shown** | Wrong data | Correct data |
| **Consistency** | ❌ Different from other methods | ✅ Same as other methods |

---

## Files Modified

- `frontend/lib/controller/lead_screen_controller.dart` (1 method updated)

---

## Related Issue

This was the same issue affecting other lead types. Now all methods consistently use the selected date from HeaderController:
- ✅ Return Leads
- ✅ Complaints
- ✅ Follow-up Leads
- ✅ Booking Confirmation Leads (FIXED)

