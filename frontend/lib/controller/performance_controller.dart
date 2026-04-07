import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:telecaller_app/services/api_service.dart';

class PerformanceController extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  int _totalCallCount = 0;
  int _callsToday = 0;
  bool _isLoading = false;
  String? _error;

  int get totalCallCount => _totalCallCount;
  int get callsToday => _callsToday;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch performance metrics from backend
  /// Optionally filter by date range
  Future<void> fetchPerformanceMetrics({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print(
        'PerformanceController: Fetching metrics - fromDate=$fromDate, toDate=$toDate',
      );

      final response = await _apiService.getPerformanceMetrics(
        fromDate: fromDate,
        toDate: toDate,
      );

      print('PerformanceController: Response received: $response');

      // Parse the response
      _totalCallCount = response['totalCallCount'] ?? 0;
      _callsToday = response['callsToday'] ?? 0;

      print(
        'PerformanceController: Parsed - totalCallCount=$_totalCallCount, callsToday=$_callsToday',
      );

      _error = null;
    } catch (e, s) {
      print('PerformanceController: Error fetching metrics: $e');
      _error = e.toString();
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'fetchPerformanceMetrics failed',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch today's performance metrics
  Future<void> fetchTodayMetrics() async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);

    await fetchPerformanceMetrics(fromDate: todayStart, toDate: todayEnd);
  }

  /// Reset metrics
  void reset() {
    _totalCallCount = 0;
    _callsToday = 0;
    _error = null;
    notifyListeners();
  }
}
