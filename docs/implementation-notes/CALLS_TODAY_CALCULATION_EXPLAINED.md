# "Calls Today" = 1 - Explanation

## Current Calculation Logic

The "Calls Today" metric is calculated in `home_screen.dart` (lines 177-225):

```dart
// Count leads created TODAY with call duration > 0
List<LeadModel> callsTodayLeads =
    _repository.allLeads
        .where(
          (lead) =>
              lead.createdAt.isAfter(todayStart) &&      // Created after 00:00:00 today
              lead.createdAt.isBefore(todayEnd) &&       // Created before 23:59:59 today
              (lead.callDuration ?? 0) > 0 &&            // Has call duration > 0
              (lead.markAsComplaint != true),            // NOT marked as complaint
        )
        .toList();

// Add complaint calls with duration > 0
int complaintCallsCount = 0;
for (final complaint in _complaintsController.complaints) {
  if ((complaint.callDuration ?? 0) > 0) {
    complaintCallsCount++;
  }
}

// Total = Regular leads + Complaint calls
final callsTodayCount = (callsTodayLeads.length + complaintCallsCount).toString();
```

---

## Why It Shows "1"

### Criteria for a Call to Count:

1. ✅ **Lead created TODAY** (between 00:00:00 and 23:59:59)
2. ✅ **Call duration > 0** (call was answered)
3. ✅ **NOT marked as complaint** (to avoid double counting)
4. ✅ **Matches selected store** (if specific store selected)

### Your Scenario:
- **Calls Today = 1** means:
  - Only **1 lead** was created today with a successful call (duration > 0)
  - OR 1 complaint call with duration > 0

---

## What "Calls Today" Counts

### ✅ Counted:
- Leads created today with `callDuration > 0`
- Complaint calls with `callDuration > 0`
- Only answered calls (due to our recent fix)

### ❌ NOT Counted:
- Leads created on previous days
- Calls with `callDuration = 0` (missed/unanswered calls)
- Leads marked as complaints (counted separately in complaint section)
- Calls from other stores (if store filter applied)

---

## Example Scenarios

### Scenario 1: Why count is 1
```
Today's Leads:
├─ Lead A: Created today, callDuration=45s, markAsComplaint=false ✅ COUNTED
├─ Lead B: Created today, callDuration=0, markAsComplaint=false ❌ NOT COUNTED (no duration)
├─ Lead C: Created yesterday, callDuration=120s, markAsComplaint=false ❌ NOT COUNTED (not today)
└─ Lead D: Created today, callDuration=60s, markAsComplaint=true ❌ NOT COUNTED (marked as complaint)

Complaints Today:
└─ Complaint X: callDuration=0 ❌ NOT COUNTED (no duration)

Result: Calls Today = 1 (only Lead A)
```

### Scenario 2: Why count could be higher
```
Today's Leads:
├─ Lead A: Created today, callDuration=45s ✅ COUNTED
├─ Lead B: Created today, callDuration=120s ✅ COUNTED
└─ Lead C: Created today, callDuration=30s ✅ COUNTED

Complaints Today:
└─ Complaint X: callDuration=60s ✅ COUNTED

Result: Calls Today = 4
```

---

## Key Points About the Calculation

### 1. **Time-Based Filtering**
```dart
lead.createdAt.isAfter(todayStart) &&      // After 00:00:00
lead.createdAt.isBefore(todayEnd)          // Before 23:59:59
```
- Only counts leads created in the current calendar day
- Uses local device time

### 2. **Duration Requirement**
```dart
(lead.callDuration ?? 0) > 0
```
- Must have answered the call (duration > 0)
- Missed calls (duration = 0) are NOT counted
- This is because of our recent fix to only track answered calls

### 3. **Complaint Exclusion**
```dart
(lead.markAsComplaint != true)
```
- Prevents double counting
- Complaints are counted separately in the complaint section

### 4. **Store Filter**
```dart
if (selectedStore.normalizedName != 'All Stores') {
  callsTodayLeads = callsTodayLeads.where(
    (lead) => lead.location?.toLowerCase() == storeLocation.toLowerCase()
  ).toList();
}
```
- If a specific store is selected, only counts calls from that store
- "All Stores" shows calls from all stores

---

## How to Increase "Calls Today" Count

To see the count increase, you need to:

1. **Make answered calls** (duration > 0)
2. **Create leads today** (not from previous days)
3. **Don't mark as complaint** (unless counting in complaint section)
4. **Match the selected store** (if store filter is active)

### Example:
- Make a call to a new lead today
- Call gets answered (duration > 0)
- Save the lead
- "Calls Today" count increases by 1

---

## Related Metrics

### Dashboard Shows:
- **Calls Today**: 1 (answered calls created today)
- **Follow Ups**: 6 (leads with follow-up dates set)
- **Today's Follow Ups**: 0 Calls (follow-ups scheduled for today)

### These are Different:
- **Calls Today** = Calls made/received today
- **Follow Ups** = Total leads with follow-up dates
- **Today's Follow Ups** = Follow-ups scheduled for today

---

## Recent Changes Impact

With our recent **call duration fix**:
- Only **answered calls** count (duration > 0)
- **Missed calls** are NOT counted (duration = 0)
- This makes the metric more accurate

Before the fix:
- Any call (answered or missed) with duration > 0 was counted
- Now only truly answered calls count

---

## Debugging: Why is it showing 1?

To verify why the count is 1, check:

1. **How many leads were created today?**
   - Check `lead.createdAt` for today's date

2. **How many have call duration > 0?**
   - Check `lead.callDuration > 0`

3. **Are any marked as complaints?**
   - Check `lead.markAsComplaint == true`

4. **Is store filter applied?**
   - Check if "All Stores" is selected or a specific store

5. **Are there complaint calls with duration > 0?**
   - Check `_complaintsController.complaints`

---

## Code Location

**File**: `frontend/lib/view/home_screen/home_screen.dart`  
**Lines**: 177-225  
**Method**: `build()` in `_HomeScreenState`

The calculation happens every time the home screen rebuilds, so it's always current.
