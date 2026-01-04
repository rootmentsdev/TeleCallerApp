import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/model/report_model.dart';
import 'package:telecaller_app/services/api_service.dart';
import 'package:telecaller_app/utils/lead_constants.dart';
import 'package:telecaller_app/utils/store_location.dart';

/// Controller for Report Screen
class ReportController extends ChangeNotifier {
  final LeadRepository _repository = LeadRepository();
  final ApiService _apiService = ApiService();
  HeaderController? _headerController;
  int _selectedCallTypeIndex = 0; // 0: All Calls, 1: Loss of Sale, etc.

  // Reports fetched from API
  List<ReportModel> _reports = [];
  PaginationInfo? _pagination;
  bool _isLoadingReports = false;
  String? _reportsError;

  // Getters for reports
  List<ReportModel> get reports => _reports;
  PaginationInfo? get pagination => _pagination;
  bool get isLoadingReports => _isLoadingReports;
  String? get reportsError => _reportsError;

  // Static flag to indicate navigation to Equary Calls tab after call save
  static bool _shouldNavigateToEquaryCalls = false;

  // Static method to trigger navigation to Equary Calls tab
  static void navigateToEquaryCalls() {
    _shouldNavigateToEquaryCalls = true;
  }

  // Check and handle navigation flag
  void checkNavigationFlag() {
    if (_shouldNavigateToEquaryCalls) {
      _shouldNavigateToEquaryCalls = false;
      setSelectedCallTypeIndex(5); // Equary Calls tab
    }
  }

  // Force refresh data from repository
  Future<void> forceRefreshData() async {
    await _repository.forceReloadFromStorage();
    notifyListeners();
  }

  // Initialize with header controller
  void init(HeaderController headerController) {
    if (_headerController != headerController) {
      _headerController?.removeListener(_onHeaderChanged);
      _headerController = headerController;
      _headerController?.addListener(_onHeaderChanged);
    }
  }

  void _onHeaderChanged() {
    // When header (store/date) changes, fetch reports from API
    _fetchReportsForCurrentFilters();
  }

  // Fetch reports when filters change
  Future<void> _fetchReportsForCurrentFilters() async {
    try {
      await fetchReportsWithCurrentFilters();
    } catch (e) {
      print('ReportController: Error fetching reports on header change: $e');
    }
  }

  @override
  void dispose() {
    _headerController?.removeListener(_onHeaderChanged);
    super.dispose();
  }

  // Getters
  DateTime get selectedDate =>
      _headerController?.selectedDate ?? DateTime.now();
  String? get selectedStore => _headerController?.selectedStore;
  int get selectedCallTypeIndex => _selectedCallTypeIndex;

  // Setters
  void setSelectedCallTypeIndex(int index) {
    _selectedCallTypeIndex = index;
    notifyListeners();
    // Fetch reports when tab changes
    _fetchReportsForCurrentFilters();
  }

  // Get call summary data (filtered by store and date)
  // Only count leads that have been called (completed calls)
  List<Map<String, dynamic>> getCallSummary() {
    final store = _headerController?.selectedStore;

    // Handle "All Stores" case
    final storeFilter = (store == null || store == 'All Stores') ? null : store;

    // Helper function to count called leads
    int getCalledLeadsCount({String? category}) {
      final date = _headerController?.selectedDate ?? DateTime.now();
      List<dynamic> leads =
          category != null
              ? _repository
                  .getLeadsByCategory(category, date: date)
                  .cast<dynamic>()
              : _repository.getLeadsByDate(date).cast<dynamic>();

      // Filter by store - extract location from "Brand - Location" format
      if (storeFilter != null) {
        final location = StoreLocations.resolveSelection(storeFilter).location;
        leads = leads.where((lead) => lead.location == location).toList();
      }

      // Filter by date
      leads =
          leads.where((lead) {
            final leadDate = lead.createdAt;
            return leadDate.year == date.year &&
                leadDate.month == date.month &&
                leadDate.day == date.day;
          }).toList();

      // Filter to only show leads that have been called
      leads =
          leads
              .where((lead) => LeadConstants.isCalledStatus(lead.callStatus))
              .toList();

      return leads.length;
    }

    return [
      {
        "title": "All Calls",
        "count": getCalledLeadsCount().toString(),
        "bgColor": const Color(0xFFE8E3FF),
        "iconColor": const Color(0xFF7C5DFF),
        "icon": Icons.people_alt_outlined,
      },
      {
        "title": "Loss of Sale",
        "count":
            getCalledLeadsCount(
              category: LeadConstants.categoryLossOfSales,
            ).toString(),
        "bgColor": const Color(0xFFFFE8E8),
        "iconColor": const Color(0xFFE23434),
        "icon": Icons.trending_down,
      },
      {
        "title": "Return",
        "count":
            getCalledLeadsCount(
              category: LeadConstants.categoryRentOut,
            ).toString(),
        "bgColor": const Color(0xFFFFF7CC),
        "iconColor": const Color(0xFFFFCC00),
        "icon": Icons.message_outlined,
      },
      {
        "title": "Booking\nConfirmation",
        "count":
            getCalledLeadsCount(
              category: LeadConstants.categoryBookingConfirmation,
            ).toString(),
        "bgColor": const Color(0xFFD4F5DA),
        "iconColor": const Color(0xff56BE6B),
        "icon": Icons.flag_outlined,
      },
      {
        "title": "Follow Up\nCalls",
        "count":
            getCalledLeadsCount(
              category: LeadConstants.categoryFollowUp,
            ).toString(),
        "bgColor": const Color(0xFFD5E8FF),
        "iconColor": const Color(0xFF2196F3),
        "icon": Icons.event_note_outlined,
      },
    ];
  }

  // Get filtered leads based on selected call type
  // Backend-driven: Uses API reports for tabs 0-4, local repository for tabs 5-6
  // No local filtering - backend returns filtered data
  List<Map<String, dynamic>> getFilteredLeads() {
    final store = _headerController?.selectedStore;

    // Handle "All Stores" case
    final storeFilter = (store == null || store == 'All Stores') ? null : store;

    // Special handling for tab 6 (Follow-up Leads)
    // Shows: Only leads with followUpDate set
    if (_selectedCallTypeIndex == 6) {
      final selectedDate = _headerController?.selectedDate ?? DateTime.now();

      // Get all leads from repository
      List<dynamic> allLeads = _repository.getLeadsByDate(selectedDate);

      // Filter only leads with follow-up date set
      List<dynamic> followUpLeads =
          allLeads.where((lead) {
            return lead.followUpDate != null;
          }).toList();

      // Filter by store if specified
      if (storeFilter != null) {
        final location = StoreLocations.resolveSelection(storeFilter).location;
        followUpLeads =
            followUpLeads.where((lead) {
              final leadLocation = lead.location ?? '';
              return leadLocation.toLowerCase().contains(
                    location.toLowerCase(),
                  ) ||
                  location.toLowerCase().contains(leadLocation.toLowerCase());
            }).toList();
      }

      // Convert to contact format
      return followUpLeads.map((lead) {
        return {
          "id": lead.id,
          "name": lead.name,
          "phone": lead.phone,
          "date": _formatDate(lead.createdAt),
          "callDate": _formatDate(lead.createdAt),
          "storeName": lead.location ?? lead.brand ?? "Not available",
          "type": "followup",
          "callStatus": lead.callStatus ?? "Not called yet",
          "leadStatus": lead.leadStatus,
          "reason": lead.reason,
          "followUpDate": lead.followUpDate?.toIso8601String(),
          "callDuration": lead.callDuration,
          "remarks": lead.reason ?? "",
        };
      }).toList();
    }

    // Special handling for tab 5 (New Leads)
    // Shows: Only newly added leads (not called yet)
    if (_selectedCallTypeIndex == 5) {
      final selectedDate = _headerController?.selectedDate ?? DateTime.now();

      // Get all leads from repository
      List<dynamic> allLeads = _repository.getLeadsByDate(selectedDate);

      // Filter only newly added leads (not called yet)
      List<dynamic> enquiryLeads =
          allLeads.where((lead) {
            // Include only leads that have NOT been called
            final isNotCalled = !LeadConstants.isCalledStatus(lead.callStatus);
            return isNotCalled;
          }).toList();

      // Filter by store if specified
      if (storeFilter != null) {
        final location = StoreLocations.resolveSelection(storeFilter).location;
        enquiryLeads =
            enquiryLeads.where((lead) {
              final leadLocation = lead.location ?? '';
              return leadLocation.toLowerCase().contains(
                    location.toLowerCase(),
                  ) ||
                  location.toLowerCase().contains(leadLocation.toLowerCase());
            }).toList();
      }

      // Convert to contact format
      return enquiryLeads.map((lead) {
        return {
          "id": lead.id,
          "name": lead.name,
          "phone": lead.phone,
          "date": _formatDate(lead.createdAt),
          "callDate": _formatDate(lead.createdAt),
          "storeName": lead.location ?? lead.brand ?? "Not available",
          "type": "enquiry",
          "callStatus": lead.callStatus ?? "Not called yet",
          "leadStatus": lead.leadStatus,
          "reason": lead.reason,
          "followUpDate": lead.followUpDate?.toIso8601String(),
          "callDuration": lead.callDuration,
          "remarks": lead.reason ?? "",
        };
      }).toList();
    }

    // For tabs 0-4, use API reports
    // Backend already filters by leadType based on tab selection
    // Filter to only show leads that have been called (called status)
    List<Map<String, dynamic>> filteredReports =
        _reports
            .where((report) {
              // Get lead data from leadSnapshot (current state of the lead)
              final leadData = report.leadData ?? {};

              // Extract call status
              final callStatus =
                  leadData['call_status']?.toString() ??
                  leadData['callStatus']?.toString() ??
                  '';

              // Only include leads that have been called
              return LeadConstants.isCalledStatus(callStatus);
            })
            .map((report) {
              // Get lead data from leadSnapshot (current state of the lead)
              final leadData = report.leadData ?? {};

              // Extract lead information from leadSnapshot
              final leadName =
                  leadData['lead_name']?.toString() ??
                  leadData['name']?.toString() ??
                  leadData['customerName']?.toString() ??
                  '';
              final leadPhone =
                  leadData['phone_number']?.toString() ??
                  leadData['phone']?.toString() ??
                  '';

              // Normalize store name (Calicut -> Kozhikode, etc.)
              var leadLocation =
                  leadData['store']?.toString() ??
                  leadData['location']?.toString() ??
                  '';

              // Apply store name normalization
              if (leadLocation.isNotEmpty && !leadLocation.contains(' - ')) {
                leadLocation = StoreLocations.normalizeStoreName(leadLocation);
              } else if (leadLocation.isNotEmpty &&
                  leadLocation.contains(' - ')) {
                final parts = leadLocation.split(' - ');
                if (parts.length == 2) {
                  final normalizedLocation = StoreLocations.normalizeStoreName(
                    parts[1],
                  );
                  leadLocation = '${parts[0]} - $normalizedLocation';
                }
              }

              final callStatus =
                  leadData['call_status']?.toString() ??
                  leadData['callStatus']?.toString() ??
                  '';
              final leadStatus =
                  leadData['lead_status']?.toString() ??
                  leadData['leadStatus']?.toString();
              final reason =
                  leadData['reason']?.toString() ??
                  leadData['reason_collected_from_store']?.toString();
              final callDuration =
                  leadData['callDuration'] as int? ??
                  leadData['call_duration'] as int?;

              // Parse dates
              DateTime? parseDate(dynamic dateValue) {
                if (dateValue == null) return null;
                try {
                  return DateTime.parse(dateValue.toString());
                } catch (e) {
                  return null;
                }
              }

              final createdAt =
                  parseDate(leadData['created_at']) ??
                  parseDate(leadData['createdAt']) ??
                  report.editedAt ??
                  report.createdAt;
              final followUpDate =
                  parseDate(leadData['follow_up_date']) ??
                  parseDate(leadData['followUpDate']);
              final enquiryDate =
                  parseDate(leadData['enquiry_date']) ??
                  parseDate(leadData['enquiryDate']);
              final functionDate =
                  parseDate(leadData['function_date']) ??
                  parseDate(leadData['functionDate']);
              final visitDate =
                  parseDate(leadData['visit_date']) ??
                  parseDate(leadData['visitDate']);

              return {
                "id": report.originalId,
                "name": leadName,
                "phone": leadPhone,
                "date": _formatDate(createdAt),
                "callDate":
                    report.editedAt != null
                        ? _formatDate(report.editedAt!)
                        : _formatDate(createdAt),
                "enquiryDate":
                    enquiryDate != null
                        ? _formatDate(enquiryDate)
                        : "Not available",
                "visitDate":
                    visitDate != null
                        ? _formatDate(visitDate)
                        : "Not available",
                "functionDate":
                    functionDate != null
                        ? _formatDate(functionDate)
                        : "Not available",
                "storeName":
                    leadLocation.isNotEmpty ? leadLocation : "Not available",
                "type": _getTypeFromLeadType(report.leadType),
                "callStatus": callStatus.isNotEmpty ? callStatus : "Connected",
                "leadStatus": leadStatus,
                "reason": reason,
                "reasonFromStore": reason,
                "attendedBy":
                    "Not available - ${leadLocation.isNotEmpty ? leadLocation : 'Not available'}",
                "followUpDate": followUpDate?.toIso8601String(),
                "callDuration": callDuration,
                "remarks": report.note ?? "",
              };
            })
            .toList();

    // For "All Calls" tab (index 0), also include newly created leads from local repository
    if (_selectedCallTypeIndex == 0) {
      final selectedDate = _headerController?.selectedDate ?? DateTime.now();
      final localLeads = _repository.getLeadsByDate(selectedDate);

      // Add newly created leads that aren't already in the API reports
      final reportIds = filteredReports.map((r) => r["id"]).toSet();
      for (final lead in localLeads) {
        if (!reportIds.contains(lead.id)) {
          filteredReports.add({
            "id": lead.id,
            "name": lead.name,
            "phone": lead.phone,
            "date": _formatDate(lead.createdAt),
            "callDate": _formatDate(lead.createdAt),
            "storeName": lead.location ?? lead.brand ?? "Not available",
            "type": "general",
            "callStatus": lead.callStatus ?? "Not called yet",
            "leadStatus": lead.leadStatus,
            "reason": lead.reason,
            "followUpDate": lead.followUpDate?.toIso8601String(),
            "callDuration": lead.callDuration,
            "remarks": lead.reason ?? "",
          });
        }
      }
    }

    // Filter by store if specified
    if (storeFilter != null) {
      final location = StoreLocations.resolveSelection(storeFilter).location;
      filteredReports =
          filteredReports.where((report) {
            final storeName = report["storeName"] as String? ?? "";
            return storeName.toLowerCase().contains(location.toLowerCase()) ||
                location.toLowerCase().contains(storeName.toLowerCase());
          }).toList();
    }

    // NOTE: Backend already filters by leadType based on selected tab
    // No need to filter locally - trust backend
    // Tabs 0-4 are handled by API with leadType parameter
    // Tabs 5-6 are handled by local repository filtering above

    return filteredReports;
  }

  // Convert API leadType to display type
  String _getTypeFromLeadType(String? leadType) {
    if (leadType == null) return "general";

    switch (leadType.toLowerCase()) {
      case "lossofsale":
        return "loss";
      case "rentoutfeedback":
        return "hardout";
      case "bookingconfirmation":
        return "booking";
      case "justdial":
        return "justdial";
      default:
        return "general";
    }
  }

  String getCurrentTitle() {
    switch (_selectedCallTypeIndex) {
      case 0:
        return "All calls";
      case 1:
        return "Loss of sale calls";
      case 2:
        return "Return calls";
      case 3:
        return "Booking Confirmation calls";
      case 4:
        return "Follow Up Calls";
      case 5:
        return "New Leads";
      default:
        return "All calls";
    }
  }

  String _formatDate(DateTime date) {
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
    return "${date.day} ${months[date.month - 1]}, ${date.year}";
  }

  void refresh() {
    notifyListeners();
  }

  /// Fetch reports from API
  Future<void> fetchReportsFromApi({
    String? leadType,
    String? editedBy,
    String? dateFrom,
    String? dateTo,
    int? page,
    int? limit,
  }) async {
    try {
      _isLoadingReports = true;
      _reportsError = null;
      notifyListeners();

      final response = await _apiService.getReports(
        leadType: leadType,
        editedBy: editedBy,
        dateFrom: dateFrom,
        dateTo: dateTo,
        page: page,
        limit: limit,
      );

      final reportsResponse = ReportsResponse.fromJson(response);
      _reports = reportsResponse.reports;
      _pagination = reportsResponse.pagination;

      _isLoadingReports = false;
      notifyListeners();
    } catch (e, s) {
      _isLoadingReports = false;
      _reportsError = e.toString();
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'fetchReports failed');
      notifyListeners();
      rethrow;
    }
  }

  /// Fetch reports filtered by current header settings (store and date)
  Future<void> fetchReportsWithCurrentFilters() async {
    // Note: Store filter is not directly supported by reports API
    // We'll filter by store in getFilteredLeads

    // Get selected date from header controller
    final selectedDate = _headerController?.selectedDate ?? DateTime.now();

    // Format date to YYYY-MM-DD for API
    String formatDate(DateTime date) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

    final dateStr = formatDate(selectedDate);

    // Determine leadType based on selected call type index
    String? leadType;

    switch (_selectedCallTypeIndex) {
      case 0:
        leadType = null; // ALL CALLS
        break;
      case 1:
        leadType = "lossOfSale";
        break;

      case 2:
        leadType = "rentoutFeedback";
        break;

      case 3:
        leadType = "bookingConfirmation";
        break;

      case 4:
        // Follow Up Calls → No leadType filter
        leadType = null;
        break;
    }

    await fetchReportsFromApi(
      leadType: leadType,
      dateFrom: dateStr,
      dateTo: dateStr,
      page: 1,
      limit: 100, // Increased limit to get more reports
    );
  }

  /// Get current user ID for filtering reports by editor
  /// This can be used to fetch reports edited by the current user
  Future<void> fetchReportsByCurrentUser({
    String? leadType,
    String? dateFrom,
    String? dateTo,
    int? page,
    int? limit,
  }) async {
    // TODO: Get current user ID from AuthService
    // For now, fetch all reports
    await fetchReportsFromApi(
      leadType: leadType,
      dateFrom: dateFrom,
      dateTo: dateTo,
      page: page,
      limit: limit,
    );
  }
}
