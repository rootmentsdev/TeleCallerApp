# Code Refactoring Quick Reference

## New Utilities Available

### 1. Custom Exceptions
**Import**: `import 'package:telecaller_app/exceptions/api_exceptions.dart';`

```dart
// Throw specific exceptions
throw AuthenticationException();
throw NetworkException('Connection timeout');
throw ValidationException('Invalid email format');
throw DataParsingException('Failed to parse JSON');

// Catch specific exceptions
try {
  await apiService.getLeads();
} on AuthenticationException {
  // Handle auth failure
} on NetworkException catch (e) {
  // Handle network error
} on ApiException catch (e) {
  // Handle any API error
}
```

### 2. HTTP Client Wrapper
**Import**: `import 'package:telecaller_app/services/http_client.dart';`

```dart
final httpClient = HttpClient();

// GET request
final data = await httpClient.get('https://api.example.com/leads');

// POST request
final response = await httpClient.post(
  'https://api.example.com/leads',
  {'name': 'John', 'phone': '1234567890'},
);

// PUT request
final updated = await httpClient.put(
  'https://api.example.com/leads/123',
  {'status': 'completed'},
);

// DELETE request
await httpClient.delete('https://api.example.com/leads/123');
```

**Features**:
- Automatic Authorization header injection
- Automatic Content-Type headers
- 30-second timeout
- Automatic response parsing
- Error handling with custom exceptions

### 3. Date Formatter Utility
**Import**: `import 'package:telecaller_app/utils/date_formatter_util.dart';`

```dart
final date = DateTime(2026, 4, 20);

// Format for display
String display = DateFormatterUtil.formatDate(date);
// Output: "20 Apr, 2026"

// Format for API
String api = DateFormatterUtil.formatDateForApi(date);
// Output: "2026-04-20"

// Format with time
String dateTime = DateFormatterUtil.formatDateTime(DateTime.now());
// Output: "20 Apr, 2026 14:30"

// Format duration
String duration = DateFormatterUtil.formatDuration(3661);
// Output: "1h 1m 1s"

// Parse date from various formats
DateTime? parsed = DateFormatterUtil.parseDate('2026-04-20');
DateTime? parsed2 = DateFormatterUtil.parseDate({'$date': '2026-04-20T...'});

// Relative time
String relative = DateFormatterUtil.getRelativeTime(DateTime.now().subtract(Duration(days: 2)));
// Output: "2 days ago"

// Date comparisons
bool today = DateFormatterUtil.isToday(DateTime.now());
bool tomorrow = DateFormatterUtil.isTomorrow(DateTime.now().add(Duration(days: 1)));

// Date range
String range = DateFormatterUtil.formatDateRange(
  DateTime(2026, 4, 18),
  DateTime(2026, 4, 25),
);
// Output: "18 - 25 Apr, 2026"
```

### 4. Logger Utility
**Import**: `import 'package:telecaller_app/utils/logger.dart';`

```dart
// Info level
Logger.info('User logged in successfully');

// Debug level
Logger.debug('Lead data: $leadData');

// Warning level
Logger.warning('API response took 5 seconds');

// Error level
try {
  await apiService.getLeads();
} catch (e, s) {
  Logger.error('Failed to fetch leads', e, s);
}

// API logging
Logger.apiRequest('GET', 'https://api.example.com/leads', body: {'store': 'NYC'});
Logger.apiResponse('GET', 'https://api.example.com/leads', 200, body: '{"data": [...]}');
```

**Output Format**:
```
[TeleCaller] [INFO] User logged in successfully
[TeleCaller] [DEBUG] Lead data: {...}
[TeleCaller] [WARN] API response took 5 seconds
[TeleCaller] [ERROR] Failed to fetch leads
```

## Migration Guide

### Before (Old Pattern)
```dart
// Old: Direct HTTP calls
final response = await http.get(url, headers: headers);
if (response.statusCode == 200) {
  final data = json.decode(response.body);
  // ...
} else if (response.statusCode == 401) {
  throw Exception('Auth failed');
}

// Old: Generic exceptions
try {
  // ...
} catch (e) {
  print('Error: $e');
}

// Old: Duplicate date formatting
String formatDate(DateTime date) {
  final months = ['Jan', 'Feb', ...];
  return "${date.day} ${months[date.month - 1]}, ${date.year}";
}
```

### After (New Pattern)
```dart
// New: HttpClient wrapper
final data = await httpClient.get(url);
// Automatic header management, error handling, response parsing

// New: Typed exceptions
try {
  // ...
} on AuthenticationException {
  // Handle auth
} on NetworkException catch (e) {
  Logger.error('Network error', e);
}

// New: Centralized date formatting
String formatted = DateFormatterUtil.formatDate(date);
```

## Best Practices

### 1. Always Use Custom Exceptions
```dart
// ✅ Good
throw AuthenticationException();
throw ValidationException('Email is required');

// ❌ Avoid
throw Exception('Auth failed');
throw Exception('Invalid input');
```

### 2. Use HttpClient for All API Calls
```dart
// ✅ Good
final data = await httpClient.get(url);

// ❌ Avoid
final response = await http.get(url, headers: headers);
```

### 3. Use DateFormatterUtil for All Date Operations
```dart
// ✅ Good
String formatted = DateFormatterUtil.formatDate(date);
DateTime? parsed = DateFormatterUtil.parseDate(dateStr);

// ❌ Avoid
String formatted = "${date.day} ${months[date.month - 1]}, ${date.year}";
DateTime parsed = DateTime.parse(dateStr);
```

### 4. Use Logger Instead of Print
```dart
// ✅ Good
Logger.info('Operation completed');
Logger.error('Failed to fetch data', error, stackTrace);

// ❌ Avoid
print('Operation completed');
print('Error: $error');
```

## File Locations
- Exceptions: `frontend/lib/exceptions/api_exceptions.dart`
- HTTP Client: `frontend/lib/services/http_client.dart`
- Date Formatter: `frontend/lib/utils/date_formatter_util.dart`
- Logger: `frontend/lib/utils/logger.dart`

## Related Documentation
- [Code Refactoring Phase 1 Complete](./implementation-notes/CODE_REFACTORING_PHASE_1_COMPLETE.md)
- [Architecture](./ARCHITECTURE.md)
- [Clean Code Rating](./CLEAN_CODE_RATING.md)
