import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:telecaller_app/services/api_service.dart';
import 'package:telecaller_app/model/complaint_model.dart';

class ComplaintsController extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<ComplaintModel> _complaints = [];
  bool _isLoading = false;
  String? _error;
  int _totalComplaints = 0;

  // Getters
  List<ComplaintModel> get complaints => _complaints;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalComplaints => _totalComplaints;

  /// Fetch complaints from API
  Future<void> fetchComplaints({
    String? store,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('ComplaintsController: Fetching complaints');
      print(
        'ComplaintsController: Store: $store, DateFrom: $dateFrom, DateTo: $dateTo',
      );

      final response = await _apiService.getComplaints(
        store: store,
        dateFrom: dateFrom,
        dateTo: dateTo,
        page: page,
        limit: limit,
      );

      // Parse response
      List<ComplaintModel> parsedComplaints = [];

      if (response.containsKey('complaints')) {
        final complaintsData = response['complaints'];
        if (complaintsData is List) {
          parsedComplaints =
              complaintsData
                  .map(
                    (item) =>
                        ComplaintModel.fromJson(item as Map<String, dynamic>),
                  )
                  .toList();
        }
      } else if (response.containsKey('data')) {
        final complaintsData = response['data'];
        if (complaintsData is List) {
          parsedComplaints =
              complaintsData
                  .map(
                    (item) =>
                        ComplaintModel.fromJson(item as Map<String, dynamic>),
                  )
                  .toList();
        }
      }

      _complaints = parsedComplaints;
      _totalComplaints = parsedComplaints.length;

      print('ComplaintsController: Fetched ${_complaints.length} complaints');

      _isLoading = false;
      notifyListeners();
    } catch (e, s) {
      _isLoading = false;
      _error = e.toString();
      print('ComplaintsController: Error fetching complaints: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'fetchComplaints failed',
      );
      notifyListeners();
    }
  }

  /// Get complaint by ID
  Future<ComplaintModel?> getComplaintById(String id) async {
    try {
      print('ComplaintsController: Fetching complaint by ID: $id');

      final response = await _apiService.getComplaintById(id);
      final complaint = ComplaintModel.fromJson(response);

      print('ComplaintsController: Fetched complaint: ${complaint.name}');

      return complaint;
    } catch (e, s) {
      print('ComplaintsController: Error fetching complaint: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'getComplaintById failed',
      );
      return null;
    }
  }

  /// Toggle complaint expansion state
  void toggleExpansion(int index) {
    if (index >= 0 && index < _complaints.length) {
      _complaints[index] = _complaints[index].copyWith(
        isExpanded: !_complaints[index].isExpanded,
      );
      notifyListeners();
    }
  }

  /// Refresh complaints
  Future<void> refresh({
    String? store,
    String? dateFrom,
    String? dateTo,
  }) async {
    await fetchComplaints(
      store: store,
      dateFrom: dateFrom,
      dateTo: dateTo,
      page: 1,
    );
  }

  /// Clear complaints
  void clear() {
    _complaints = [];
    _error = null;
    _totalComplaints = 0;
    notifyListeners();
  }
}
