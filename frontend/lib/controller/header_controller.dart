import 'package:flutter/material.dart';
import 'package:telecaller_app/utils/store_location.dart';

/// Shared controller for header state (store and date)
/// This is used across Home Screen, Lead Screen, and Report Screen
class HeaderController extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  late String _selectedStore;

  HeaderController() {
    // Initialize with first available store (no "All Stores")
    final stores = StoreLocations.buildStoreOptions();
    _selectedStore =
        stores.isNotEmpty
            ? stores.first
            : '${StoreLocations.defaultBrand} - ${StoreLocations.defaultLocationForBrand(StoreLocations.defaultBrand)}';
  }

  // Getters
  DateTime get selectedDate => _selectedDate;
  String get selectedStore => _selectedStore;

  // Setters
  void setSelectedDate(DateTime date) {
    if (_selectedDate.year != date.year ||
        _selectedDate.month != date.month ||
        _selectedDate.day != date.day) {
      _selectedDate = date;
      notifyListeners();
    }
  }

  void setSelectedStore(String store) {
    if (_selectedStore != store) {
      _selectedStore = store;
      notifyListeners();
    }
  }

  // Reset to defaults
  void reset() {
    _selectedDate = DateTime.now();
    final stores = StoreLocations.buildStoreOptions();
    _selectedStore =
        stores.isNotEmpty
            ? stores.first
            : '${StoreLocations.defaultBrand} - ${StoreLocations.defaultLocationForBrand(StoreLocations.defaultBrand)}';
    notifyListeners();
  }
}
