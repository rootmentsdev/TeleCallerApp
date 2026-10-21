# CSV Export - Phone Number Formatting Issue

## Issue Observed

In the CSV export, phone numbers are displaying in scientific notation:
- `7.74E+09` instead of `7746543210`
- `9.21E+09` instead of `9876543210`
- `8.28E+09` instead of `8289876543`

## Why This Happens

When Excel/Google Sheets opens a CSV file, it automatically detects data types. Phone numbers that look like large numbers are converted to scientific notation for display.

## Solution

### For Users (Immediate Fix)

1. **In Excel**:
   - Select the Phone column
   - Right-click → Format Cells
   - Choose "Text" format
   - Click OK
   - Phone numbers will display correctly

2. **In Google Sheets**:
   - Select the Phone column
   - Format → Number → Text
   - Phone numbers will display correctly

### For Developers (Permanent Fix)

We can force phone numbers to be treated as text in the CSV by prefixing with a single quote:

**Current Implementation** (in `csv_formatter.dart`):
```dart
final phone = _escapeCsv(report['phone']?.toString() ?? '');
buffer.writeln('$id,$name,$phone,$store,$type,$status,$duration,$callDate,$remarks');
```

**Improved Implementation**:
```dart
// Force phone as text by prefixing with single quote
final phone = "'${_escapeCsv(report['phone']?.toString() ?? '')}";
buffer.writeln('$id,$name,$phone,$store,$type,$status,$duration,$callDate,$remarks');
```

## Implementation

To fix this permanently, update `frontend/lib/utils/csv_formatter.dart`:

```dart
// In formatReportsToCsv method, change:
final phone = _escapeCsv(report['phone']?.toString() ?? '');

// To:
final phone = "'${_escapeCsv(report['phone']?.toString() ?? '')}";
```

The single quote prefix tells Excel/Google Sheets to treat the value as text, preventing scientific notation conversion.

## Testing

After implementing the fix:

1. Export CSV
2. Open in Excel/Google Sheets
3. Phone numbers should display as: `7746543210` (not `7.74E+09`)
4. No manual formatting needed

## Alternative Solutions

1. **Add leading zero**: `07746543210` (makes it text automatically)
2. **Add country code**: `+917746543210` (makes it text automatically)
3. **Format as text in CSV**: `'7746543210` (our chosen solution)

## Current Status

The CSV export is working correctly. Phone numbers display in scientific notation in Excel/Google Sheets due to automatic type detection, but this is a display issue, not a data issue. The actual phone numbers are stored correctly in the CSV file.

## Recommended Fix

Update `csv_formatter.dart` to prefix phone numbers with a single quote to force text formatting:

```dart
// Line in formatReportsToCsv method
final phone = "'${_escapeCsv(report['phone']?.toString() ?? '')}";
```

This ensures phone numbers display correctly without requiring manual formatting by users.
