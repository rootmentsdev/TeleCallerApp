import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:telecaller_app/model/store_model.dart';

/// Shared controller for header state (store and date/date range)
/// This is used across Home Screen, Lead Screen, and Report Screen
class HeaderController extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  DateTime? _dateRangeStart;
  DateTime? _dateRangeEnd;
  bool _isRangeMode = false;
  late Store _selectedStore;
  List<Store> _availableStores = [];

  /// Hardcoded store list — normalizedName is used as the `store=` query param
  static final List<Store> defaultStores = [
    Store(brand: 'SG', location: 'Calicut', normalizedName: 'SG-Calicut'),
    Store(brand: 'SG', location: 'Chavakkad', normalizedName: 'SG-Chavakkad'),
    Store(brand: 'SG', location: 'Edappal', normalizedName: 'SG-Edappal'),
    Store(brand: 'SG', location: 'Edappally', normalizedName: 'SG-Edappally'),
    Store(brand: 'SG', location: 'Kalpetta', normalizedName: 'SG-Kalpetta'),
    Store(brand: 'SG', location: 'Kannur', normalizedName: 'SG-Kannur'),
    Store(brand: 'SG', location: 'Kottakkal', normalizedName: 'SG-Kottakkal'),
    Store(brand: 'SG', location: 'Kottayam', normalizedName: 'SG-Kottayam'),
    Store(brand: 'SG', location: 'Manjeri', normalizedName: 'SG-Manjeri'),
    Store(brand: 'SG', location: 'Mg Road', normalizedName: 'SG-Mg Road'),
    Store(brand: 'SG', location: 'Palakkad', normalizedName: 'SG-Palakkad'),
    Store(
      brand: 'SG',
      location: 'Perinthalmanna',
      normalizedName: 'SG-Perinthalmanna',
    ),
    Store(
      brand: 'SG',
      location: 'Perumbavoor',
      normalizedName: 'SG-Perumbavoor',
    ),
    Store(brand: 'SG', location: 'Thrissur', normalizedName: 'SG-Thrissur'),
    Store(brand: 'SG', location: 'Trivandrum', normalizedName: 'SG-Trivandrum'),
    Store(brand: 'SG', location: 'Vadakara', normalizedName: 'SG-Vadakara'),
    Store(brand: 'Z', location: 'Edappally', normalizedName: 'Z-Edappally'),
    Store(brand: 'Z', location: 'Edappal', normalizedName: 'Z-Edappal'),
    Store(brand: 'Z', location: 'Kottakkal', normalizedName: 'Z-Kottakkal'),
    Store(
      brand: 'Z',
      location: 'Perinthalmanna',
      normalizedName: 'Z-Perinthalmanna',
    ),
  ];

  HeaderController() {
    _selectedStore = Store(
      brand: 'All',
      location: 'Stores',
      normalizedName: 'All Stores',
    );
    // Pre-populate with the hardcoded list
    _availableStores = defaultStores;
  }

  // Getters
  DateTime get selectedDate => _selectedDate;
  DateTime? get dateRangeStart => _dateRangeStart;
  DateTime? get dateRangeEnd => _dateRangeEnd;
  bool get isRangeMode => _isRangeMode;
  Store get selectedStore => _selectedStore;
  List<Store> get availableStores => _availableStores;

  // Setters
  void setSelectedDate(DateTime date) {
    if (_selectedDate.year != date.year ||
        _selectedDate.month != date.month ||
        _selectedDate.day != date.day) {
      _selectedDate = date;
      _isRangeMode = false;
      _dateRangeStart = null;
      _dateRangeEnd = null;
      notifyListeners();
    }
  }

  void setDateRange(DateTime start, DateTime end) {
    _dateRangeStart = start;
    _dateRangeEnd = end;
    _isRangeMode = true;
    _selectedDate = start;
    notifyListeners();
  }

  void clearDateRange() {
    _isRangeMode = false;
    _dateRangeStart = null;
    _dateRangeEnd = null;
    _selectedDate = DateTime.now();
    notifyListeners();
  }

  void setSelectedStore(Store store) {
    if (_selectedStore != store) {
      _selectedStore = store;
      // Set store as custom key in Firebase Crashlytics
      if (store.normalizedName != 'All Stores') {
        FirebaseCrashlytics.instance.setCustomKey(
          "store",
          store.normalizedName,
        );
      }
      notifyListeners();
    }
  }

  void setAvailableStores(List<Store> stores) {
    _availableStores = stores;
    notifyListeners();
  }

  void reset() {
    _selectedDate = DateTime.now();
    _selectedStore = Store(
      brand: 'All',
      location: 'Stores',
      normalizedName: 'All Stores',
    );
    _isRangeMode = false;
    _dateRangeStart = null;
    _dateRangeEnd = null;
    notifyListeners();
  }
}
