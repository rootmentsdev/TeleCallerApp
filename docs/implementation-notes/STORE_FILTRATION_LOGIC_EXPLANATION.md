# Store Filtration Logic - Complete Explanation

## Overview
The application uses a two-tier store filtering system:
1. **Backend Filtering**: API-level filtering by store
2. **Local Filtering**: Client-side filtering in controllers

---

## Store Model Structure

```dart
class Store {
  final String brand;           // e.g., "SG" (Shyam Garments)
  final String location;        // e.g., "Edappally", "MG Road"
  final String normalizedName;  // e.g., "SG-Edappally"
}
```

### Example Stores:
```
Store(brand: "SG", location: "Edappally", normalizedName: "SG-Edappally")
Store(brand: "SG", location: "MG Road", normalizedName: "SG.MG ROAD")
Store(brand: "SG", location: "Trivandrum", normalizedName: "SG-Trivandrum")
```

---

## Current Application Logic

### 1. HeaderController - Store Management
```dart
class HeaderController extends ChangeNotifier {
  Store _selectedStore = Store(
    brand: 'All',
    location: 'Stores',
    normalizedName: 'All Stores',
  );
  
  List<Store> _availableStores = [];
  
  Store get selectedStore => _selectedStore;
  List<Store> get availableStores => _availableStores;
  
  void setSelectedStore(Store store) {
    _selectedStore = store;
    notifyListeners();
  }
  
  void setAvailableStores(List<Store> stores) {
    _availableStores = stores;
    notifyListeners();
  }
}
```

### 2. ReportController - Store Filtering
```dart
List<Map<String, dynamic>> getFilteredLeads() {
  final store = _headerController?.selectedStore;
  
  // Check if "All Stores" is selected
  final storeFilter = 
    (store == null || store.normalizedName == 'All Stores') 
      ? null 
      : store;
  
  // ... other filtering logic ...
  
  // Apply store filter
  if (storeFilter != null) {
    filteredReports = filteredReports.where((report) {
      final storeName = report["storeName"] as String? ?? "";
      
      // Case-insensitive substring matching
      return storeName.toLowerCase().contains(
            storeFilter.location.toLowerCase(),
          ) ||
          storeFilter.location.toLowerCase().contains(
            storeName.toLowerCase(),
          );
    }).toList();
  }
  
  return filteredReports;
}
```

---

## Store Name Variations in Data

### Backend Returns Store Names Like:
```
"SG-Edappally"
"SG.MG ROAD"
"SG-Trivandrum"
"SG-Kozhikode"
"SG-Kannur"
"SG-Kottayam"
"SG-Thrissur"
"SG-Palakkad"
"SG-Vadakara"
"SG-Chavakkad"
"SG-Edappal"
"SG-Perinthalmanna"
"SG-Manjeri"
"SG-Kottakal"
"SG-Kalpetta"
"SG-Perumbavoor"
```

### Store Filter Location Values:
```
"Edappally"
"MG Road"
"Trivandrum"
"Kozhikode"
"Kannur"
"Kottayam"
"Thrissur"
"Palakkad"
"Vadakara"
"Chavakkad"
"Edappal"
"Perinthalmanna"
"Manjeri"
"Kottakal"
"Kalpetta"
"Perumbavoor"
```

---

## Matching Logic Explained

### Example 1: Edappally Store
```
Filter Store: Store(location: "Edappally")
Report Store Name: "SG-Edappally"

Matching Process:
1. storeName.toLowerCase() = "sg-edappally"
2. storeFilter.location.toLowerCase() = "edappally"
3. Check: "sg-edappally".contains("edappally") = TRUE ✓
4. Result: MATCH
```

### Example 2: MG Road Store
```
Filter Store: Store(location: "MG Road")
Report Store Name: "SG.MG ROAD"

Matching Process:
1. storeName.toLowerCase() = "sg.mg road"
2. storeFilter.location.toLowerCase() = "mg road"
3. Check: "sg.mg road".contains("mg road") = TRUE ✓
4. Result: MATCH
```

### Example 3: All Stores
```
Filter Store: Store(normalizedName: "All Stores")

Matching Process:
1. storeFilter = null (because normalizedName == 'All Stores')
2. No filtering applied
3. Result: ALL REPORTS SHOWN
```

### Example 4: No Match
```
Filter Store: Store(location: "Edappally")
Report Store Name: "SG-Trivandrum"

Matching Process:
1. storeName.toLowerCase() = "sg-trivandrum"
2. storeFilter.location.toLowerCase() = "edappally"
3. Check: "sg-trivandrum".contains("edappally") = FALSE
4. Check: "edappally".contains("sg-trivandrum") = FALSE
5. Result: NO MATCH (filtered out)
```

---

## Store Filtering in Different Screens

### 1. Reports Screen
```dart
// In ReportController.getFilteredLeads()
if (storeFilter != null) {
  filteredReports = filteredReports.where((report) {
    final storeName = report["storeName"] as String? ?? "";
    return storeName.toLowerCase().contains(
          storeFilter.location.toLowerCase(),
        ) ||
        storeFilter.location.toLowerCase().contains(
          storeName.toLowerCase(),
        );
  }).toList();
}
```

**Flow:**
1. User selects store from dropdown in Reports Screen
2. HeaderController.setSelectedStore(store) is called
3. ReportController listens to HeaderController changes
4. ReportController.getFilteredLeads() applies store filter
5. Reports are filtered by store location

### 2. Lead Screen
```dart
// In LeadScreenController
List<Lead> getFilteredLeads() {
  final store = _headerController?.selectedStore;
  final storeFilter = 
    (store == null || store.normalizedName == 'All Stores') 
      ? null 
      : store;
  
  List<Lead> leads = _repository.getLeadsByDate(selectedDate);
  
  if (storeFilter != null) {
    leads = leads.where((lead) {
      final leadLocation = lead.location ?? '';
      return leadLocation.toLowerCase().contains(
            storeFilter.location.toLowerCase(),
          ) ||
          storeFilter.location.toLowerCase().contains(
            leadLocation.toLowerCase(),
          );
    }).toList();
  }
  
  return leads;
}
```

### 3. Follow-Up Screen
```dart
// In FollowUpController
List<Lead> getFollowUpLeads() {
  final store = _headerController?.selectedStore;
  final storeFilter = 
    (store == null || store.normalizedName == 'All Stores') 
      ? null 
      : store;
  
  List<Lead> leads = _repository.getFollowUpLeads();
  
  if (storeFilter != null) {
    leads = leads.where((lead) {
      final leadLocation = lead.location ?? '';
      return leadLocation.toLowerCase().contains(
            storeFilter.location.toLowerCase(),
          ) ||
          storeFilter.location.toLowerCase().contains(
            leadLocation.toLowerCase(),
          );
    }).toList();
  }
  
  return leads;
}
```

---

## Store Normalization

The application includes a store name normalization map to handle variations:

```dart
const Map<String, String> normalization = {
  'Calicut': 'Kozhikode',
  'calicut': 'Kozhikode',
  'Cochin': 'Edappally',
  'cochin': 'Edappally',
  'mg road': 'MG Road',
  'MG road': 'MG Road',
  'MG_Road': 'MG Road',
  'mg-road': 'MG Road',
  'M.G. Road': 'MG Road',
  'Vatakara': 'Vadakara',
  'vatakara': 'Vadakara',
  'trivandrum': 'Trivandrum',
  'Thiruvananthapuram': 'Trivandrum',
  'edappally': 'Edappally',
  'Edapally': 'Edappally',
  'perumbavoor': 'Perumbavoor',
  'Perumbavur': 'Perumbavoor',
  'thrissur': 'Thrissur',
  'Trichur': 'Thrissur',
  'palakkad': 'Palakkad',
  'Palghat': 'Palakkad',
  'chavakkad': 'Chavakkad',
  'Chavakad': 'Chavakkad',
  'edappal': 'Edappal',
  'Edapal': 'Edappal',
  'perinthalmanna': 'Perinthalmanna',
  'manjeri': 'Manjeri',
  'kottakal': 'Kottakal',
  'kozhikode': 'Kozhikode',
  'vadakara': 'Vadakara',
  'kannur': 'Kannur',
  'Cannanore': 'Kannur',
  'kalpetta': 'Kalpetta',
};
```

---

## API Integration

### Backend Store Filtering
When fetching reports, the store filter is passed to the API:

```dart
// In ReportController.fetchReportsWithCurrentFilters()
String? storeParam;
if (selectedStore != null && selectedStore.normalizedName != 'All Stores') {
  storeParam = selectedStore.normalizedName; // e.g., "SG-Edappally"
}

await fetchReportsFromApi(
  store: storeParam,
  editedAtFrom: editedAtFromStr,
  editedAtTo: editedAtToStr,
);
```

### API Request Example
```
GET /api/reports?store=SG-Edappally&editedAtFrom=2026-03-18T00:00:00&editedAtTo=2026-03-18T23:59:59
```

---

## Summary Table

| Aspect | Details |
|--------|---------|
| **Store Object** | Contains brand, location, normalizedName |
| **Filter Type** | Case-insensitive substring matching |
| **Matching Logic** | storeName contains location OR location contains storeName |
| **All Stores** | When normalizedName == 'All Stores', no filtering applied |
| **Normalization** | Store names normalized to handle variations |
| **Backend Integration** | Store filter passed to API as normalizedName |
| **Local Filtering** | Applied in controllers after backend returns data |
| **Screens Using** | Reports, Lead Screen, Follow-Up Screen, Complaints |

---

## Common Issues & Solutions

### Issue 1: Store Filter Not Working
**Cause**: Store name format mismatch
**Solution**: Check if report store name contains the filter location using substring matching

### Issue 2: "All Stores" Not Showing All Reports
**Cause**: storeFilter not set to null
**Solution**: Check if `store.normalizedName == 'All Stores'` before applying filter

### Issue 3: Case Sensitivity Issues
**Cause**: Not converting to lowercase before comparison
**Solution**: Always use `.toLowerCase()` for both store name and filter location

### Issue 4: Store Dropdown Not Updating
**Cause**: HeaderController not notifying listeners
**Solution**: Ensure `notifyListeners()` is called after `setSelectedStore()`

