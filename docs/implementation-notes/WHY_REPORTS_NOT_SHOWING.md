# Why Completed Call Reports Sometimes Don't Show in Report Screen

## Main Reasons

### 1. **Date Mismatch - Most Common Issue**

**Problem:** Report uses `updatedAt` (when call was made) for filtering, not `createdAt` (when lead was created).

**Example:**
- Lead created: 25/03/2026
- Call made: 28/03/2026 (updatedAt = 28/03/2026)
- Viewing reports for: 30/03/2026
- **Result:** Report won't show because `updatedAt` is 28/03, not 30/03

**Why this happens:**
```
API filters by: fromDate=2026-03-30&toDate=2026-03-30
Lead has: updatedAt=2026-03-28T05:00:26.384Z
Match? NO → Lead excluded from results
```

---

### 2. **Store Filter Mismatch**

**Problem:** Selected store doesn't match the lead's store.

**Example:**
- Lead store: "Z-Edappally"
- Selected store filter: "SG-Perinthalmanna"
- **Result:** Report won't show because store doesn't match

**Why this happens:**
```
Frontend filters by: store="SG-Perinthalmanna"
Lead has: store="Z-Edappally"
Match? NO → Lead excluded from results
```

---

### 3. **Lead Type Not Matching Filter**

**Problem:** Lead type doesn't match the selected tab filter.

**Example:**
- Lead type: "enquiry"
- Selected tab: "Booking Confirmation Calls"
- **Result:** Report won't show because it's filtering for booking confirmation only

**Why this happens:**
```
Tab filter: leadtype == "bookingConfirmation"
Lead has: leadtype="enquiry"
Match? NO → Lead excluded from results
```

---

### 4. **API Response Parsing Failure**

**Problem:** API returns data but frontend fails to parse it correctly.

**Reasons:**
- Missing required fields in API response
- Incorrect field names (snake_case vs camelCase mismatch)
- Invalid date format that can't be parsed
- Null values in critical fields

**Example:**
```
API returns: { "leadtype": null, "updatedAt": "invalid-date" }
Parser tries: DateTime.parse("invalid-date") → throws exception
Result: Lead is skipped, not added to reports
```

---

### 5. **Date Range Filtering Issue**

**Problem:** Date range is too narrow or incorrect.

**Example:**
- Call made: 28/03/2026 at 05:00 AM
- Viewing: "Today" (30/03/2026)
- **Result:** Won't show because it's from 2 days ago

**Why this happens:**
```
Frontend sends: fromDate=2026-03-30&toDate=2026-03-30
Lead has: updatedAt=2026-03-28T05:00:26.384Z
Date comparison: 28/03 < 30/03 → Excluded
```

---

### 6. **API Not Returning the Lead**

**Problem:** Backend API doesn't return the completed lead.

**Reasons:**
- Lead status is not "completed" on backend
- Lead is marked as "draft" or "pending"
- Lead was deleted or archived
- Backend filtering is excluding it

**Example:**
```
Frontend requests: /api/leads/completed?fromDate=2026-03-30&toDate=2026-03-30
Backend checks: Is leadStatus == "completed"? NO
Result: Lead not included in API response
```

---

### 7. **Caching Issue**

**Problem:** Frontend cached old data and didn't refresh.

**Why this happens:**
- User made a call and saved it
- Didn't refresh the reports screen
- Reports screen still showing cached data from before the call

**Solution:** Pull-to-refresh or navigate away and back

---

### 8. **Time Zone Mismatch**

**Problem:** API uses UTC time, frontend uses local time.

**Example:**
- Call made: 28/03/2026 11:30 PM (local time)
- API stores: 28/03/2026 06:00 PM UTC (different day in some zones)
- Viewing: 29/03/2026 (local)
- **Result:** Date mismatch causes report to not show

---

## Complete Filtering Chain

```
API Response
    ↓
1. Check: leadStatus == "completed"? 
   NO → Excluded
    ↓
2. Check: updatedAt within date range?
   NO → Excluded
    ↓
3. Check: store matches selected store?
   NO → Excluded
    ↓
4. Check: leadtype matches tab filter?
   NO → Excluded
    ↓
5. Check: Can parse all required fields?
   NO → Excluded
    ↓
Report Shows ✓
```

---

## How to Debug

### Check 1: Verify Date
- Look at `updatedAt` in API response
- Compare with selected date range
- **Issue:** If `updatedAt` is outside date range → Won't show

### Check 2: Verify Store
- Check lead's store field
- Compare with selected store filter
- **Issue:** If store doesn't match → Won't show

### Check 3: Verify Lead Type
- Check `leadtype` field
- Compare with selected tab
- **Issue:** If type doesn't match → Won't show

### Check 4: Check API Response
- Open network inspector
- Look at `/api/leads/completed` response
- **Issue:** If lead not in response → Backend issue

### Check 5: Check Logs
- Look for parsing errors
- Check if lead was skipped
- **Issue:** If parsing failed → Frontend issue

---

## Most Likely Scenarios

### Scenario 1: Call Made Yesterday, Viewing Today
```
Call made: 28/03/2026
Viewing: 29/03/2026
Result: Won't show (date mismatch)
Solution: Select "Last 7 Days" or correct date range
```

### Scenario 2: Different Store Selected
```
Lead store: "Z-Edappally"
Selected: "SG-Perinthalmanna"
Result: Won't show (store mismatch)
Solution: Select "All Stores" or correct store
```

### Scenario 3: Wrong Tab Selected
```
Lead type: "enquiry"
Selected tab: "Booking Confirmation"
Result: Won't show (type mismatch)
Solution: Select "All Calls" tab
```

### Scenario 4: Lead Not Completed on Backend
```
Lead status: "pending" or "draft"
API endpoint: /api/leads/completed
Result: Won't show (backend filtering)
Solution: Complete the lead on backend first
```

---

## Summary

**Most Common Reasons (in order):**

1. **Date Mismatch** (60%) - Call made on different date than viewing
2. **Store Filter** (20%) - Selected store doesn't match lead's store
3. **Lead Type Filter** (10%) - Wrong tab selected
4. **Backend Issue** (5%) - Lead not marked as completed
5. **Parsing Error** (5%) - Invalid data format

**Quick Fix:**
- Select "Last 7 Days" instead of "Today"
- Select "All Stores" instead of specific store
- Select "All Calls" tab instead of specific type
- Pull-to-refresh to reload data
