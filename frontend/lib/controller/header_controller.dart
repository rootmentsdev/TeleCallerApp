import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Shared controller for header state (store and date/date range)
/// This is used across Home Screen, Lead Screen, and Report Screen
class HeaderController extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  DateTime? _dateRangeStart;
  DateTime? _dateRangeEnd;
  bool _isRangeMode = false;
  late String _selectedStore;

  HeaderController() {
    _selectedStore = 'All Stores';
  }

  // Getters
  DateTime get selectedDate => _selectedDate;
  DateTime? get dateRangeStart => _dateRangeStart;
  DateTime? get dateRangeEnd => _dateRangeEnd;
  bool get isRangeMode => _isRangeMode;
  String get selectedStore => _selectedStore;

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

  void setSelectedStore(String store) {
    if (_selectedStore != store) {
      _selectedStore = store;
      // Set store as custom key in Firebase Crashlytics
      if (store != 'All Stores') {
        FirebaseCrashlytics.instance.setCustomKey("store", store);
      }
      notifyListeners();
    }
  }

  void reset() {
    _selectedDate = DateTime.now();
    _selectedStore = 'All Stores';
    _isRangeMode = false;
    _dateRangeStart = null;
    _dateRangeEnd = null;
    notifyListeners();
  }
}
