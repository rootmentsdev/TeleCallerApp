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
    int limit = 1000,
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

      print('ComplaintsController: Response keys: ${response.keys.toList()}');

      if (response.containsKey('complaints')) {
        final complaintsData = response['complaints'];
        print(
          'ComplaintsController: Found complaints key, type: ${complaintsData.runtimeType}',
        );
        if (complaintsData is List) {
          print(
            'ComplaintsController: Parsing ${complaintsData.length} complaints',
          );
          for (var item in complaintsData) {
            try {
              if (item is Map<String, dynamic>) {
                final complaint = ComplaintModel.fromJson(item);
                parsedComplaints.add(complaint);
              } else {
                print(
                  'ComplaintsController: Skipping invalid item (not a Map): $item',
                );
              }
            } catch (e, stackTrace) {
              print('ComplaintsController: Error parsing complaint item: $e');
              print('ComplaintsController: Item data: $item');
              print('ComplaintsController: Stack trace: $stackTrace');
              // Continue with next item instead of crashing
              FirebaseCrashlytics.instance.recordError(
                e,
                stackTrace,
                reason: 'Failed to parse complaint item',
              );
            }
          }
        } else {
          print(
            'ComplaintsController: complaints data is not a List: ${complaintsData.runtimeType}',
          );
        }
      } else if (response.containsKey('data')) {
        final dataObj = response['data'];
        print(
          'ComplaintsController: Found data key, type: ${dataObj.runtimeType}',
        );

        // Check if data is a Map (object) with 'leads' array
        if (dataObj is Map<String, dynamic> && dataObj.containsKey('leads')) {
          final complaintsData = dataObj['leads'];
          print(
            'ComplaintsController: Found leads in data, type: ${complaintsData.runtimeType}',
          );
          if (complaintsData is List) {
            print(
              'ComplaintsController: Parsing ${complaintsData.length} complaints from data.leads',
            );
            for (var item in complaintsData) {
              try {
                if (item is Map<String, dynamic>) {
                  final complaint = ComplaintModel.fromJson(item);
                  parsedComplaints.add(complaint);
                } else {
                  print(
                    'ComplaintsController: Skipping invalid item (not a Map): $item',
                  );
                }
              } catch (e, stackTrace) {
                print('ComplaintsController: Error parsing complaint item: $e');
                print('ComplaintsController: Item data: $item');
                print('ComplaintsController: Stack trace: $stackTrace');
                // Continue with next item instead of crashing
                FirebaseCrashlytics.instance.recordError(
                  e,
                  stackTrace,
                  reason: 'Failed to parse complaint item',
                );
              }
            }
          }
        } else if (dataObj is List) {
          // Fallback: if data is directly a list
          print(
            'ComplaintsController: Parsing ${dataObj.length} complaints from data (direct list)',
          );
          for (var item in dataObj) {
            try {
              if (item is Map<String, dynamic>) {
                final complaint = ComplaintModel.fromJson(item);
                parsedComplaints.add(complaint);
              } else {
                print(
                  'ComplaintsController: Skipping invalid item (not a Map): $item',
                );
              }
            } catch (e, stackTrace) {
              print('ComplaintsController: Error parsing complaint item: $e');
              print('ComplaintsController: Item data: $item');
              print('ComplaintsController: Stack trace: $stackTrace');
              // Continue with next item instead of crashing
              FirebaseCrashlytics.instance.recordError(
                e,
                stackTrace,
                reason: 'Failed to parse complaint item',
              );
            }
          }
        } else {
          print(
            'ComplaintsController: data is not a List or Map with leads: ${dataObj.runtimeType}',
          );
        }
      } else {
        print(
          'ComplaintsController: Response does not contain complaints or data keys',
        );
        print('ComplaintsController: Response structure: $response');
        // Check if response has any data that we might have missed
        if (response.isNotEmpty) {
          print(
            'ComplaintsController: Warning: Response has data but no complaints/data key',
          );
          print(
            'ComplaintsController: Response keys: ${response.keys.toList()}',
          );
        }
      }

      // Check if we got data from API but couldn't parse any items
      if (parsedComplaints.isEmpty) {
        // Check if there was actually data in the response
        final hasComplaintsData =
            (response.containsKey('complaints') &&
                response['complaints'] is List &&
                (response['complaints'] as List).isNotEmpty) ||
            (response.containsKey('data') &&
                response['data'] is List &&
                (response['data'] as List).isNotEmpty);

        if (hasComplaintsData) {
          print(
            'ComplaintsController: Warning: API returned data but parsing failed for all items',
          );
          _error = 'Failed to parse complaint data. Please check the logs.';
        }
      }

      // Client-side filtering for exact store match
      // Backend may do substring matching, so we filter on frontend
      if (store != null && store.isNotEmpty) {
        parsedComplaints =
            parsedComplaints
                .where((complaint) => complaint.store == store)
                .toList();
      }

      _complaints = parsedComplaints;
      _totalComplaints = parsedComplaints.length;

      print(
        'ComplaintsController: Successfully parsed ${_complaints.length} complaints',
      );

      // Debug: Print sample complaint data to verify remarks are being fetched
      if (parsedComplaints.isNotEmpty) {
        final sample = parsedComplaints.first;
        print(
          'ComplaintsController: Sample complaint - ID: ${sample.id}, Name: ${sample.name}',
        );
        print(
          'ComplaintsController: Sample complaint - Remarks: ${sample.remarks}',
        );
        print(
          'ComplaintsController: Sample complaint - Complaint Remarks: ${sample.complaintRemarks}',
        );
        print(
          'ComplaintsController: Sample complaint - Call Status: ${sample.callStatus}',
        );
        print(
          'ComplaintsController: Sample complaint - Call Duration: ${sample.callDuration}',
        );
        print(
          'ComplaintsController: Sample complaint - Has Call Been Made: ${sample.hasCallBeenMade}',
        );
      } else {
        print('ComplaintsController: No complaints parsed from response');
      }

      _isLoading = false;
      _error = null; // Clear any previous errors
      notifyListeners();
    } catch (e, s) {
      _isLoading = false;
      _error = e.toString();
      print('ComplaintsController: Error fetching complaints: $e');
      print('ComplaintsController: Stack trace: $s');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'fetchComplaints failed',
      );
      // Ensure we still have an empty list if error occurs
      if (_complaints.isEmpty) {
        _complaints = [];
      }
      notifyListeners();
    } finally {
      // Ensure loading is always set to false
      _isLoading = false;
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
