import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:telecaller_app/services/api_service.dart';

class ComplaintsController extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = false;
  String? _error;
  int _totalComplaints = 0;

  // Getters
  List<Map<String, dynamic>> get complaints => _complaints;
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
      List<Map<String, dynamic>> parsedComplaints = [];

      if (response.containsKey('complaints')) {
        final complaintsData = response['complaints'];
        if (complaintsData is List) {
          parsedComplaints =
              complaintsData
                  .map((item) => _parseComplaint(item as Map<String, dynamic>))
                  .toList();
        }
      } else if (response.containsKey('data')) {
        final complaintsData = response['data'];
        if (complaintsData is List) {
          parsedComplaints =
              complaintsData
                  .map((item) => _parseComplaint(item as Map<String, dynamic>))
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

  /// Parse complaint data from API response
  Map<String, dynamic> _parseComplaint(Map<String, dynamic> json) {
    return {
      'id': json['_id']?.toString() ?? json['id']?.toString() ?? '',
      'name': json['name']?.toString() ?? 'Unknown',
      'phone': json['phone']?.toString() ?? '',
      'store': json['store']?.toString() ?? '',
      'type': json['leadType']?.toString() ?? 'Enquiry',
      'date': _formatDate(json['createdAt']),
      'functionDate': json['functionDate']?.toString() ?? '',
      'subCategory': json['subCategory']?.toString() ?? '',
      'remarks': json['remarks']?.toString() ?? '',
      'callStatus': json['callStatus']?.toString() ?? 'Not Called',
      'leadStatus': json['leadStatus']?.toString() ?? 'No Status',
      'isExpanded': false,
      'rawData': json, // Store raw data for reference
    };
  }

  /// Format date from ISO string
  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    try {
      final date = DateTime.parse(dateValue.toString());
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '${date.day} ${months[date.month - 1]} ${date.year} $hour:$minute';
    } catch (e) {
      return dateValue.toString();
    }
  }

  /// Get complaint by ID
  Future<Map<String, dynamic>?> getComplaintById(String id) async {
    try {
      print('ComplaintsController: Fetching complaint by ID: $id');

      final response = await _apiService.getComplaintById(id);
      final complaint = _parseComplaint(response);

      print('ComplaintsController: Fetched complaint: ${complaint['name']}');

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
