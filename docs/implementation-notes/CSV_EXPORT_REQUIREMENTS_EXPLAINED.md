# CSV Export Requirements - Explained

## Current Issue

The CSV export currently includes:
- ❌ Summary data (counts, aggregations)
- ❌ All fields from the database
- ❌ Inconsistent formatting
- ❌ Unnecessary columns

## What You Need

**Export ONLY the filtered report data based on date selection with clean, neat formatting**

### Requirements
1. **Data Source**: Only reports visible on the report screen (after date filtering)
2. **Date Filtering**: Respect the selected date range (Today, Last 7 Days, This Month, Last Month, Custom)
3. **Format**: Clean, readable, professional format
4. **Columns**: Only essential columns for reporting

## Current Implementation Analysis

### Current CSV Structure
```
ID | Customer Name | Phone | Store | Lead Type | Lead Status | Call Duration | ... (18 columns)
```

**Problems**:
- Too many columns (18 total)
- Includes unnecessary fields (deliveryDate, updatedAt)
- No summary information
- No date range information in export
- Inconsistent data formatting

### Current Data Flow
```
Reports Screen
    ↓
getFilteredReportsByDateCategory()
    ↓
exportReportsCsv()
    ↓
CSV File
```

## Proposed Solution

### New CSV Structure

#### Header Section (Metadata)
```
Report Export
Date Range: Last Month (01 Apr 2026 - 30 Apr 2026)
Export Date: 01 May 2026 14:30:00
Total Records: 35
```

#### Summary Section
```
Summary Statistics
Total Calls: 35
Booking Confirmation: 4
Enquiry Calls: 28
Feedback Calls: 2
Booked Calls: 1
```

#### Data Section (Filtered Reports)
```
ID | Name | Phone | Store | Type | Status | Duration | Date | Remarks
```

### Neat Format Example

```csv
CALL REPORT EXPORT
Date Range,Last Month (01 Apr 2026 - 30 Apr 2026)
Export Date,01 May 2026 14:30:00
Total Records,35
Store Filter,All Stores

SUMMARY STATISTICS
Total Calls,35
Booking Confirmation,4
Enquiry Calls,28
Feedback Calls,2
Booked Calls,1

DETAILED REPORT
ID,Name,Phone,Store,Type,Status,Duration (sec),Call Date,Remarks
001,John Doe,9876543210,MG Road,Enquiry,Completed,120,25 Apr 2026,Interested in services
002,Jane Smith,9876543211,Edappally,Booking Confirmation,Completed,180,24 Apr 2026,Confirmed booking
...
```

## Implementation Details

### 1. Data Source
```dart
// Use only filtered reports based on current date selection
final filteredReports = getFilteredReportsByDateCategory();
```

### 2. Date Range Information
```dart
// Get current date range from header controller
String dateRangeLabel = _getDateRangeLabel();
// Output: "Last Month (01 Apr 2026 - 30 Apr 2026)"
```

### 3. Summary Calculation
```dart
// Calculate summary from filtered reports
int totalCalls = filteredReports.length;
int bookingConfirmation = filteredReports
    .where((r) => r['type'] == 'bookingconfirmation')
    .length;
// ... etc
```

### 4. Clean Column Selection
```dart
// Only essential columns
[
  "ID",
  "Name",
  "Phone",
  "Store",
  "Type",
  "Status",
  "Duration (sec)",
  "Call Date",
  "Remarks"
]
```

### 5. Data Formatting
```dart
// Format data consistently
{
  "ID": lead['id'] ?? "N/A",
  "Name": lead['name'] ?? "N/A",
  "Phone": lead['phone'] ?? "N/A",
  "Store": lead['storeName'] ?? "N/A",
  "Type": _getCallTypeDisplay(lead['type']),
  "Status": lead['leadStatus'] ?? "N/A",
  "Duration (sec)": lead['callDuration']?.toString() ?? "0",
  "Call Date": lead['callDateFormatted'] ?? "N/A",
  "Remarks": lead['remarks'] ?? "N/A",
}
```

## File Naming Convention

### Current
```
call_report_1746086400000.csv
```

### Proposed
```
CallReport_LastMonth_20260501_143000.csv
CallReport_Today_20260501_143000.csv
CallReport_Custom_20260401_20260430_20260501_143000.csv
```

**Format**: `CallReport_[DateRange]_[ExportDate]_[Time].csv`

## Benefits

### For Users
- ✅ Clean, professional format
- ✅ Easy to read and understand
- ✅ Includes summary statistics
- ✅ Shows date range information
- ✅ Only relevant data

### For Analysis
- ✅ Quick overview with summary
- ✅ Detailed data for analysis
- ✅ Consistent formatting
- ✅ Easy to import to Excel/Sheets
- ✅ Audit trail with export date

## Example CSV Output

```csv
CALL REPORT EXPORT
Date Range,Last Month (01 Apr 2026 - 30 Apr 2026)
Export Date,01 May 2026 14:30:00
Total Records,35
Store Filter,All Stores

SUMMARY STATISTICS
Total Calls,35
Booking Confirmation,4
Enquiry Calls,28
Feedback Calls,2
Booked Calls,1

DETAILED REPORT
ID,Name,Phone,Store,Type,Status,Duration (sec),Call Date,Remarks
LD001,Nidhin,7736350589,SG Trivandrum,Booking Confirmation,Completed,120,25 Apr 2026,Confirmed booking
LD002,JUBIN,9207239690,SG Kottayam,Booking Confirmation,Completed,180,24 Apr 2026,Booking confirmed
LD003,Rajesh Kumar,9876543210,MG Road,Enquiry,Completed,90,23 Apr 2026,Interested in services
LD004,Priya Singh,9876543211,Edappally,Enquiry,Completed,150,22 Apr 2026,Follow up required
LD005,Amit Patel,9876543212,Thrissur,Feedback,Completed,60,21 Apr 2026,Good feedback received
```

## Implementation Steps

1. **Create CSV Formatter Utility**
   - File: `frontend/lib/utils/csv_formatter.dart`
   - Methods: formatReportsToCsv(), getDateRangeLabel(), calculateSummary()

2. **Update Report Controller**
   - File: `frontend/lib/controller/report_controller.dart`
   - Method: exportReportsCsv()
   - Use new CSV formatter

3. **Update File Naming**
   - Use descriptive names with date range
   - Include export timestamp

4. **Test Export**
   - Test with different date ranges
   - Verify formatting
   - Check file size and readability

## Related Files
- `frontend/lib/controller/report_controller.dart` - exportReportsCsv() method
- `frontend/lib/view/reports_screens/reports_screen.dart` - Export button
- `frontend/lib/utils/csv_formatter.dart` - New utility (to be created)
