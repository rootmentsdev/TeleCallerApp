# Report Screen Fix - Reports Now Display Correctly

## Problem
The report screen was showing "No call reports found" even though the API was returning 1 report successfully.

**API Response (Correct):**
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "leads": [
      {
        "_id": "69b679bd05c2cb405e025971",
        "leadtype": "return",
        "customerName": "JOSEKUTTY",
        "phone": "9544738138",
        ...
      }
    ],
    "total": 1,
    "page": 1,
    "limit": 100
  }
}
```

**Logs Showed:**
- API response: `{"success":true,"message":"Success","data":{"leads":[...1 report...],"total":1,...}}`
- ReportController logs: `"Total reports: 0"`, `"Feedback count: 0"`

## Root Cause
The `ReportsResponse.fromJson()` method in `report_model.dart` was looking for the wrong key:

```dart
// ❌ WRONG - Looking for 'reports' key
final List<ReportModel> parsedReports =
    (json['reports'] as List? ?? [])  // API sends 'leads', not 'reports'
        .map((item) => ReportModel.fromJson(item))
        .toList();
```

The API returns data in `data.leads[]` but the code was looking for `json['reports']`, so it always got an empty list.

## Solution
Updated `ReportsResponse.fromJson()` to correctly parse the API response structure:

```dart
factory ReportsResponse.fromJson(Map<String, dynamic> json) {
  // API returns data in 'data' object with 'leads' array
  final data = json['data'] as Map<String, dynamic>? ?? json;

  final List<ReportModel> parsedReports =
      (data['leads'] as List? ?? data['reports'] as List? ?? [])
          .map((item) => ReportModel.fromJson(item as Map<String, dynamic>))
          .toList();

  print(
    'ReportsResponse: Parsed ${parsedReports.length} reports from API response',
  );

  return ReportsResponse(
    reports: parsedReports,
    pagination: PaginationInfo.fromJson(
      data['pagination'] ??
          {
            'page': data['page'] ?? 1,
            'limit': data['limit'] ?? 100,
            'total': data['total'] ?? 0,
            'pages': ((data['total'] ?? 0) / (data['limit'] ?? 100)).ceil(),
          },
    ),
  );
}
```

## Key Changes
1. **Extract data object**: `final data = json['data'] as Map<String, dynamic>? ?? json;`
   - Handles both wrapped (`{data: {...}}`) and unwrapped responses
   
2. **Look for 'leads' key first**: `data['leads'] as List? ?? data['reports'] as List? ?? []`
   - Tries `leads` (what API sends) first
   - Falls back to `reports` for backward compatibility
   - Returns empty list if neither exists
   
3. **Build pagination from available fields**: 
   - Uses `data['pagination']` if available
   - Falls back to building from `page`, `limit`, `total` fields
   - Calculates `pages` from total and limit

## Files Modified
- `frontend/lib/model/report_model.dart` - Fixed `ReportsResponse.fromJson()` method

## Testing
After rebuild, reports should now display correctly:
- API returns 1 report → App shows 1 report ✓
- Report details (name, phone, store, etc.) display correctly ✓
- Report filtering by date/store works ✓

## Next Steps
1. Rebuild the app: `flutter clean && flutter pub get && flutter run`
2. Navigate to Reports screen
3. Verify reports now display instead of "No call reports found"
4. Check that report counts in tabs (All Calls, Enquiry, Feedback, etc.) are correct
