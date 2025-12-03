import 'package:flutter/material.dart';
import 'package:telecaller_app/utils/store_location.dart';

/// Shared controller for header state (store and date)
/// This is used across Home Screen, Lead Screen, and Report Screen
class HeaderController extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  String? _selectedStore;

  // Getters
  DateTime get selectedDate => _selectedDate;
  String? get selectedStore => _selectedStore ?? StoreLocations.allStoresLabel;

  // Setters
  void setSelectedDate(DateTime date) {
    if (_selectedDate.year != date.year ||
        _selectedDate.month != date.month ||
        _selectedDate.day != date.day) {
      _selectedDate = date;
      notifyListeners();
    }
  }

  void setSelectedStore(String? store) {
    if (_selectedStore != store) {
      _selectedStore = store;
      notifyListeners();
    }
  }

  // Reset to defaults
  void reset() {
    _selectedDate = DateTime.now();
    _selectedStore = null;
    notifyListeners();
  }
}
