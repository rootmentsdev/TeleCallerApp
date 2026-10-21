# Lead Screen vs Report Screen - Date Range Fetching Explanation

## Overview
Both Lead Screen and Report Screen fetch data based on date ranges from the Header Controller, but they use **different API endpoints** and **different date parameters**.

---

## Lead Screen (Feedback Calls Tab)

### How It Works
When you select a date in the Lead Screen:

1. **Date Range Detection**
   ```dart
   if (headerController.isRangeMode &&
       headerController.dateRangeStart != null &&
       headerController.dateRangeEnd != null) {
     // Use date range
     dateFrom = _formatDateForApi(headerController.dateRangeStart!);
     dateTo = _formatDateForApi(headerController.dateRangeEnd!);
   } else {
     // Use single date
     final selectedDate = headerController.selectedDate;
     dateFrom = _formatDateForApi(selectedDate);
     final endOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
     dateTo = _formatDateForApi(endOfDay);
   }
   ```

2. **API Call**
   ```dart
   await controller.fetchReturnLeadsFromApi(
     store: storeParam,
     fromDate: dateFrom,      // e.g., "2026-03-13"
     toDate: dateTo,          // e.g., "2026-03-13"
   );
   ```

3. **API Endpoint**
   ```
   GET /api/leads/returns?fromDate=2026-03-13&toDate=2026-03-13
   ```

4. **Date Format**
   - Format: `YYYY-MM-DD` (date only, no time)
   - Example: `2026-03-13`

### Example Flow
- User selects: **13/3/2026**
- Lead Screen converts to: `fromDate=2026-03-13`, `toDate=2026-03-13`
- API returns: All return leads with `returnDate` or `createdAt` on 13/3/2026

---

## Report Screen

### How It Works
When you select a date in the Report Screen:

1. **Date Range Detection**
   ```dart
   if (_headerController?.isRangeMode == true &&
       _headerController?.dateRangeStart != null &&
       _headerController?.dateRangeEnd != null) {
     // Use date range - format with time to ensure full day coverage
     editedAtFromStr = formatDateWithTime(_headerController!.dateRangeStart!);
     editedAtToStr = formatDateWithTime(_headerController!.dateRangeEnd!);
   } else {
     // Use single date - format with time to ensure full day coverage
     final selectedDate = _headerController?.selectedDate ?? DateTime.now();
     editedAtFromStr = formatDateWithTime(selectedDate);
     
     // For end date, use 23:59:59 of the same day
     final endOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
     editedAtToStr = formatDateWithTime(endOfDay);
   }
   ```

2. **API Call**
   ```dart
   await fetchReportsFromApi(
     leadType: leadType,
     editedAtFrom: editedAtFromStr,    // e.g., "2026-03-13T00:00:00.000"
     editedAtTo: editedAtToStr,        // e.g., "2026-03-13T23:59:59.000"
     page: 1,
     limit: 100,
   );
   ```

3. **API Endpoint**
   ```
   GET /api/leads/completed?editedAtFrom=2026-03-13T00:00:00.000&editedAtTo=2026-03-13T23:59:59.000
   ```

4. **Date Format**
   - Format: `YYYY-MM-DDTHH:MM:SS.000` (ISO8601 with time)
   - Example: `2026-03-13T00:00:00.000` to `2026-03-13T23:59:59.000`

### Example Flow
- User selects: **13/3/2026**
- Report Screen converts to: `editedAtFrom=2026-03-13T00:00:00.000`, `editedAtTo=2026-03-13T23:59:59.000`
- API returns: All reports with `updatedAt` (edited time) between 00:00:00 and 23:59:59 on 13/3/2026

---

## Key Differences

| Aspect | Lead Screen | Report Screen |
|--------|-------------|---------------|
| **API Endpoint** | `/api/leads/returns` | `/api/leads/completed` |
| **Date Parameters** | `fromDate`, `toDate` | `editedAtFrom`, `editedAtTo` |
| **Date Format** | `YYYY-MM-DD` | `YYYY-MM-DDTHH:MM:SS.000` |
| **Time Component** | No time (date only) | Full time (00:00:00 to 23:59:59) |
| **Backend Filtering** | Filters by `returnDate` or `createdAt` | Filters by `updatedAt` (when report was edited) |
| **Use Case** | Show leads that were returned on a specific date | Show reports that were edited/updated on a specific date |

---

## Why They're Different

### Lead Screen Purpose
- Shows **return leads** that were physically returned on a specific date
- Uses `returnDate` field from the lead
- Needs simple date format because it's filtering by a specific date

### Report Screen Purpose
- Shows **reports** (completed leads) that were edited/updated on a specific date
- Uses `updatedAt` field from the report
- Needs full timestamp to capture the entire day (00:00:00 to 23:59:59)

---

## Example Scenario

**Date Selected: 13/3/2026**

### Lead Screen
```
Request: GET /api/leads/returns?fromDate=2026-03-13&toDate=2026-03-13
Response: 21 return leads with returnDate = 2026-03-13
```

### Report Screen
```
Request: GET /api/leads/completed?editedAtFrom=2026-03-13T00:00:00.000&editedAtTo=2026-03-13T23:59:59.000
Response: 2 reports with updatedAt between 2026-03-13T00:00:00 and 2026-03-13T23:59:59
```

---

## Why Leads Might Not Show

If leads are not showing in the Lead Screen when you select a date:

1. **Check the API Response**
   - Verify API returns leads for that date
   - Check if `returnDate` matches the selected date

2. **Check Date Formatting**
   - Lead Screen uses: `YYYY-MM-DD` format
   - Verify dates are formatted correctly

3. **Check Date Range Mode**
   - If `isRangeMode = true`, uses `dateRangeStart` and `dateRangeEnd`
   - If `isRangeMode = false`, uses `selectedDate` with 00:00:00 to 23:59:59

4. **Check UI Filtering**
   - Even if API returns leads, they might be filtered out by:
     - Category filter (must be `categoryRentOut`)
     - Starred filter (must not be starred)
     - Follow-up date filter (must not have follow-up date)

---

## Summary

- **Lead Screen** fetches return leads using simple date format (`YYYY-MM-DD`)
- **Report Screen** fetches reports using full timestamp format (`YYYY-MM-DDTHH:MM:SS.000`)
- Both use the **same date range** from Header Controller
- But they query **different endpoints** with **different parameters**
- This is by design because they serve different purposes
