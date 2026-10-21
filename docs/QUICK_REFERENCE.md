# Quick Reference Guide

## Project Structure at a Glance

```
frontend/lib/
├── controller/          → Business logic & state management
├── model/              → Data structures & serialization
├── services/           → API & external integrations
├── utils/              → Constants, helpers, formatters
├── view/               → UI screens (organized by feature)
├── widgets.dart/       → Reusable UI components
└── main.dart           → App entry point
```

## Common Tasks

### Adding a New Screen

1. **Create screen file** in `lib/view/{feature}/{feature}_screen.dart`
2. **Create controller** in `lib/controller/{feature}_controller.dart`
3. **Add navigation** in `navigation_helper.dart`
4. **Update main.dart** with provider if needed

**Example:**
```dart
// lib/view/new_feature/new_feature_screen.dart
class NewFeatureScreen extends StatefulWidget {
  @override
  State<NewFeatureScreen> createState() => _NewFeatureScreenState();
}

class _NewFeatureScreenState extends State<NewFeatureScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<NewFeatureController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(title: Text('New Feature')),
          body: Center(child: Text('Content')),
        );
      },
    );
  }
}
```

### Adding an API Endpoint

1. **Add endpoint** in `lib/utils/api_config.dart`
2. **Add method** in `lib/services/api_service.dart`
3. **Add repository method** in `lib/controller/lead_repository.dart`
4. **Add controller method** in appropriate controller
5. **Call from view** in screen

**Example:**
```dart
// api_config.dart
static String getNewEndpoint() {
  return "$baseUrl/api/new-endpoint";
}

// api_service.dart
Future<Map<String, dynamic>> getNewData() async {
  final url = Uri.parse(ApiConfig.getNewEndpoint());
  final headers = await _getAuthHeaders();
  final response = await http.get(url, headers: headers);
  // Handle response
}

// lead_repository.dart
Future<void> fetchNewData() async {
  final response = await _apiService.getNewData();
  // Process and store
  notifyListeners();
}

// controller
Future<void> fetchNewData() async {
  await _repository.fetchNewData();
  notifyListeners();
}

// view
await controller.fetchNewData();
```

### Adding a Data Model

1. **Create model file** in `lib/model/{entity}_model.dart`
2. **Define class** with properties
3. **Implement toMap()** for local storage
4. **Implement fromMap()** for deserialization
5. **Implement toJson()** for API requests
6. **Implement fromJson()** for API responses

**Example:**
```dart
class NewModel {
  final String id;
  final String name;
  
  NewModel({
    required this.id,
    required this.name,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
  
  factory NewModel.fromMap(Map<String, dynamic> map) {
    return NewModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() => toMap();
  
  factory NewModel.fromJson(Map<String, dynamic> json) {
    return NewModel.fromMap(json);
  }
}
```

### Adding a Reusable Widget

1. **Create widget file** in `lib/widgets.dart/{widget_name}.dart`
2. **Define widget class**
3. **Implement build method**
4. **Add documentation**

**Example:**
```dart
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  
  const CustomButton({
    required this.label,
    required this.onPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
```

### Adding a Constant

1. **Add to appropriate constant file** in `lib/utils/`
2. **Use descriptive name**
3. **Add documentation**

**Example:**
```dart
// lib/utils/lead_constants.dart
class LeadConstants {
  static const String categoryJustDial = "Just Dial";
  static const String categoryBooking = "Booking";
  static const String callStatusConnected = "Connected";
}
```

### Adding Error Handling

1. **Wrap API calls** in try-catch
2. **Log to Crashlytics**
3. **Show user message**
4. **Provide retry option**

**Example:**
```dart
try {
  await controller.fetchData();
} catch (e, s) {
  FirebaseCrashlytics.instance.recordError(e, s);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: ${e.toString()}')),
  );
}
```

## Code Snippets

### State Management with ChangeNotifier

```dart
class MyController extends ChangeNotifier {
  List<Item> _items = [];
  
  List<Item> get items => _items;
  
  Future<void> loadItems() async {
    _items = await _repository.getItems();
    notifyListeners();
  }
}
```

### Using Provider in Widget

```dart
Consumer<MyController>(
  builder: (context, controller, child) {
    return ListView(
      children: controller.items.map((item) => ItemTile(item)).toList(),
    );
  },
)
```

### API Call with Error Handling

```dart
Future<void> fetchData() async {
  try {
    setState(() => _isLoading = true);
    final response = await _apiService.getData();
    setState(() {
      _data = response;
      _error = null;
    });
  } catch (e) {
    setState(() => _error = e.toString());
    FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
  } finally {
    setState(() => _isLoading = false);
  }
}
```

### Loading/Error/Success States

```dart
if (_isLoading) {
  return Center(child: CircularProgressIndicator());
} else if (_error != null) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Error: $_error'),
        ElevatedButton(
          onPressed: _retry,
          child: Text('Retry'),
        ),
      ],
    ),
  );
} else {
  return ListView(children: _buildItems());
}
```

### Form Validation

```dart
if (_formKey.currentState!.validate()) {
  // Form is valid
  await _submitForm();
} else {
  // Form is invalid
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Please fix errors')),
  );
}
```

## Debugging Tips

### Enable Debug Logging
```dart
// In api_service.dart
print('ApiService: Request URL: $url');
print('ApiService: Response: ${response.body}');
```

### Check State Changes
```dart
// In controller
void notifyListeners() {
  print('${runtimeType}: State changed');
  super.notifyListeners();
}
```

### Verify Data Flow
```dart
// Add prints at each layer
print('View: Calling controller');
print('Controller: Calling repository');
print('Repository: Calling API');
print('API: Response received');
```

### Use Flutter DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

## Performance Tips

### Optimize List Rendering
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemTile(items[index]),
)
```

### Avoid Rebuilds
```dart
// Use const constructors
const SizedBox(height: 16);

// Use Consumer with specific type
Consumer<MyController>(builder: ...)
```

### Cache Data
```dart
// Store in repository
final _cachedData = <String, dynamic>{};

// Return cached if available
if (_cachedData.containsKey(key)) {
  return _cachedData[key];
}
```

## Testing

### Run Tests
```bash
flutter test
```

### Run Specific Test
```bash
flutter test test/unit/model_test.dart
```

### Generate Coverage
```bash
flutter test --coverage
```

## Deployment

### Build APK
```bash
flutter build apk --release
```

### Build App Bundle
```bash
flutter build appbundle --release
```

### Build iOS
```bash
flutter build ios --release
```

## Useful Commands

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Analyze code
flutter analyze

# Format code
dart format lib/

# Run app
flutter run

# Run with specific device
flutter run -d <device_id>

# List devices
flutter devices

# Check Flutter version
flutter --version

# Update Flutter
flutter upgrade
```

## Common Errors & Solutions

| Error | Solution |
|-------|----------|
| `No Material widget found` | Wrap with MaterialApp |
| `setState called after dispose` | Check if mounted before setState |
| `Null safety error` | Add ? for nullable types |
| `Import not found` | Run `flutter pub get` |
| `Build failed` | Run `flutter clean` then rebuild |
| `Device not found` | Run `flutter devices` |

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Provider Package](https://pub.dev/packages/provider)
- [Firebase Crashlytics](https://firebase.google.com/docs/crashlytics)
- [HTTP Package](https://pub.dev/packages/http)
