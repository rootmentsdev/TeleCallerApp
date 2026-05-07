import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/model/report_model.dart';
import 'package:telecaller_app/model/store_model.dart';
import 'package:telecaller_app/services/api_service.dart';
import 'package:telecaller_app/utils/lead_constants.dart';
import 'package:telecaller_app/utils/date_formatter_util.dart';
import 'package:telecaller_app/utils/csv_formatter.dart';
import 'package:telecaller_app/utils/logger.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ReportController extends ChangeNotifier {
  final LeadRepository _repository = LeadRepository();
  final ApiService _apiService = ApiService();
  HeaderController? _headerController;
  int _selectedCallTypeIndex = 0;

  List<ReportModel> _reports = [];
  PaginationInfo? _pagination;
  bool _isLoadingReports = false;
  String? _reportsError;
  String _selectedDateCategory = 'Today';

  static bool _shouldNavigateToEquaryCalls = false;

  List<ReportModel> get reports => _reports;
  PaginationInfo? get pagination => _pagination;
  bool get isLoadingReports => _isLoadingReports;
  String? get reportsError => _reportsError;
  String get selectedDateCategory => _selectedDateCategory;

  static void navigateToEquaryCalls() {
    _shouldNavigateToEquaryCalls = true;
  }

  void checkNavigationFlag() {
    if (_shouldNavigateToEquaryCalls) {
      _shouldNavigateToEquaryCalls = false;
      setSelectedCallTypeIndex(5);
    }
  }

  Future<void> forceRefreshData() async {
    await _repository.forceReloadFromStorage();
    notifyListeners();
  }

  void init(HeaderController headerController) {
    if (_headerController != headerController) {
      _headerController?.removeListener(_onHeaderChanged);
      _headerController = headerController;
      _headerController?.addListener(_onHeaderChanged);
    }
  }

  void _onHeaderChanged() {
    _fetchReportsForCurrentFilters();
  }

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

  DateTime get selectedDate =>
      _headerController?.selectedDate ?? DateTime.now();
  Store? get selectedStore => _headerController?.selectedStore;
  int get selectedCallTypeIndex => _selectedCallTypeIndex;

  void setSelectedCallTypeIndex(int index) {
    _selectedCallTypeIndex = index;
    notifyListeners();
    _fetchReportsForCurrentFilters();
  }

  List<Map<String, dynamic>> getCallSummary() {
    final store = _headerController?.selectedStore;
    final storeFilter =
        (store == null || store.normalizedName == 'All Stores') ? null : store;

    int getCalledLeadsCount({String? category}) {
      final date = _headerController?.selectedDate ?? DateTime.now();
      List<dynamic> leads =
          category != null
              ? _repository
                  .getLeadsByCategory(category, date: date)
                  .cast<dynamic>()
              : _repository.getLeadsByDate(date).cast<dynamic>();

      if (storeFilter != null) {
        leads =
            leads.where((lead) {
              final leadLocation = lead.location ?? '';
              return leadLocation.toLowerCase().contains(
                    storeFilter.location.toLowerCase(),
                  ) ||
                  storeFilter.location.toLowerCase().contains(
                    leadLocation.toLowerCase(),
                  );
            }).toList();
      }

      leads =
          leads.where((lead) {
            final leadDate = lead.createdAt;
            return leadDate.year == date.year &&
                leadDate.month == date.month &&
                leadDate.day == date.day;
          }).toList();

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

  List<Map<String, dynamic>> getFilteredLeads() {
    final store = _headerController?.selectedStore;
    final storeFilter =
        (store == null || store.normalizedName == 'All Stores') ? null : store;

    if (_selectedCallTypeIndex == 6) {
      List<dynamic> allLeads;
      if (_headerController?.isRangeMode == true &&
          _headerController?.dateRangeStart != null &&
          _headerController?.dateRangeEnd != null) {
        allLeads = _repository.getLeadsByDateRange(
          _headerController!.dateRangeStart!,
          _headerController!.dateRangeEnd!,
        );
      } else {
        final selectedDate = _headerController?.selectedDate ?? DateTime.now();
        allLeads = _repository.getLeadsByDate(selectedDate);
      }

      List<dynamic> followUpLeads =
          allLeads.where((lead) {
            return lead.followUpDate != null;
          }).toList();

      if (storeFilter != null) {
        followUpLeads =
            followUpLeads.where((lead) {
              final leadLocation = lead.location ?? '';
              return leadLocation.toLowerCase().contains(
                    storeFilter.location.toLowerCase(),
                  ) ||
                  storeFilter.location.toLowerCase().contains(
                    leadLocation.toLowerCase(),
                  );
            }).toList();
      }

      return followUpLeads.map((lead) {
        return {
          "id": lead.id,
          "name": lead.name,
          "phone": lead.phone,
          "date": _formatDate(lead.createdAt),
          "callDate": lead.createdAt.toIso8601String(),
          "callDateFormatted": _formatDate(lead.createdAt),
          "callDateObj": lead.createdAt,
          "storeName": lead.location ?? lead.brand ?? "Not available",
          "type": "followup",
          "callStatus": lead.callStatus ?? "Not called yet",
          "leadStatus": lead.leadStatus,
          "reason": lead.reason,
          "followUpDate": lead.followUpDate?.toIso8601String(),
          "callDuration": lead.callDuration,
          "remarks": lead.reason ?? "",
          "leadData": {},
        };
      }).toList();
    }

    List<Map<String, dynamic>> filteredReports =
        _reports.map((report) {
          final leadData = report.leadData ?? {};

          final leadName =
              leadData['name']?.toString() ??
              leadData['lead_name']?.toString() ??
              leadData['customerName']?.toString() ??
              '';
          final leadPhone =
              leadData['phone']?.toString() ??
              leadData['phone_number']?.toString() ??
              '';

          final callStatus =
              leadData['callStatus']?.toString() ??
              leadData['call_status']?.toString() ??
              '';

          var leadLocation =
              leadData['store']?.toString() ??
              leadData['location']?.toString() ??
              '';

          if (leadLocation.isNotEmpty && !leadLocation.contains(' - ')) {
            leadLocation = _normalizeStoreName(leadLocation);
          } else if (leadLocation.isNotEmpty && leadLocation.contains(' - ')) {
            final parts = leadLocation.split(' - ');
            if (parts.length == 2) {
              final normalizedLocation = _normalizeStoreName(parts[1]);
              leadLocation = '${parts[0]} - $normalizedLocation';
            }
          }

          final leadStatus =
              leadData['leadStatus']?.toString() ??
              leadData['lead_status']?.toString();
          final reason =
              leadData['remarks']?.toString() ??
              leadData['reason']?.toString() ??
              leadData['reason_collected_from_store']?.toString() ??
              '';

          // Parse callDuration - API returns as String, need to convert to int
          final callDuration = () {
            final callDur =
                leadData['callDuration'] ??
                leadData['call_duration'] ??
                report.callDuration;
            if (callDur == null) return null;
            if (callDur is int) return callDur;
            if (callDur is String) {
              try {
                return int.parse(callDur);
              } catch (_) {
                return null;
              }
            }
            return null;
          }();

          final subCategory =
              leadData['subCategory']?.toString() ??
              leadData['sub_category']?.toString() ??
              '';
          final closingAction =
              leadData['closingAction']?.toString() ??
              leadData['closing_action']?.toString() ??
              '';
          final itemCategory =
              leadData['itemCategory']?.toString() ??
              leadData['item_category']?.toString() ??
              '';

          final createdAt =
              DateFormatterUtil.parseDate(leadData['createdAt']) ??
              DateFormatterUtil.parseDate(leadData['created_at']) ??
              report.editedAt ??
              report.createdAt;
          final followUpDate =
              DateFormatterUtil.parseDate(leadData['followUpDate']) ??
              DateFormatterUtil.parseDate(leadData['follow_up_date']);
          final enquiryDate =
              DateFormatterUtil.parseDate(leadData['enquiryDate']) ??
              DateFormatterUtil.parseDate(leadData['enquiry_date']);
          final functionDate =
              DateFormatterUtil.parseDate(leadData['functionDate']) ??
              DateFormatterUtil.parseDate(leadData['function_date']);
          final visitDate =
              DateFormatterUtil.parseDate(leadData['visitDate']) ??
              DateFormatterUtil.parseDate(leadData['visit_date']);
          final returnDate =
              DateFormatterUtil.parseDate(leadData['returnDate']) ??
              DateFormatterUtil.parseDate(leadData['return_date']);
          final bookingDate =
              DateFormatterUtil.parseDate(leadData['bookingDate']) ??
              DateFormatterUtil.parseDate(leadData['booking_date']) ??
              enquiryDate;

          final attendedBy =
              leadData['attendedBy']?.toString() ??
              leadData['attended_by']?.toString() ??
              report.editedBy?['name']?.toString();
          final service = leadData['service']?.toString();
          final rating = leadData['rating'] as int?;
          final markAsComplaint =
              leadData['markAsComplaint'] as bool? ??
              leadData['mark_as_complaint'] as bool? ??
              false;
          final noOfFunctions =
              leadData['noOfFunctions']?.toString() ??
              leadData['no_of_functions']?.toString();
          final noOfAttires =
              leadData['noOfAttires']?.toString() ??
              leadData['no_of_attires']?.toString();
          final competitor = leadData['competitor']?.toString();

          // Use updatedAt for display and filtering (when report was called or updated today)
          final dateToUse = report.updatedAt;

          return {
            "id": report.originalId,
            "name": leadName,
            "phone": leadPhone,
            "date": _formatDate(createdAt),
            "callDate": dateToUse.toIso8601String(),
            "callDateFormatted": _formatDate(dateToUse),
            "callDateObj": dateToUse,
            "enquiryDate":
                enquiryDate != null
                    ? _formatDate(enquiryDate)
                    : "Not available",
            "visitDate":
                visitDate != null ? _formatDate(visitDate) : "Not available",
            "functionDate":
                functionDate != null
                    ? _formatDate(functionDate)
                    : "Not available",
            "bookingDate": bookingDate?.toIso8601String(),
            "returnDate": returnDate?.toIso8601String(),
            "storeName":
                leadLocation.isNotEmpty ? leadLocation : "Not available",
            "type": _getTypeFromLeadType(report.leadType),
            "callStatus": callStatus.isNotEmpty ? callStatus : "Connected",
            "leadStatus": leadStatus,
            "reason": reason,
            "reasonFromStore": reason,
            "attendedBy": attendedBy ?? "Not available",
            "followUpDate": followUpDate?.toIso8601String(),
            "callDuration": callDuration,
            "remarks": report.note ?? reason,
            "subCategory":
                subCategory.isNotEmpty ? subCategory : "Not specified",
            "closingAction":
                closingAction.isNotEmpty ? closingAction : "Not specified",
            "itemCategory":
                itemCategory.isNotEmpty ? itemCategory : "Not specified",
            "service": service,
            "rating": rating,
            "markAsComplaint": markAsComplaint,
            "noOfFunctions": noOfFunctions,
            "noOfAttires": noOfAttires,
            "competitor": competitor,
            "leadData": leadData,
          };
        }).toList();

    if (_selectedCallTypeIndex == 0) {
      List<dynamic> localLeads;
      if (_headerController?.isRangeMode == true &&
          _headerController?.dateRangeStart != null &&
          _headerController?.dateRangeEnd != null) {
        localLeads = _repository.getLeadsByDateRange(
          _headerController!.dateRangeStart!,
          _headerController!.dateRangeEnd!,
        );
      } else {
        final selectedDate = _headerController?.selectedDate ?? DateTime.now();
        localLeads = _repository.getLeadsByDate(selectedDate);
      }

      final calledLocalLeads =
          localLeads
              .where((lead) => LeadConstants.isCalledStatus(lead.callStatus))
              .toList();

      // Filter by date range - use updatedAt if available, otherwise createdAt
      final filteredByDate =
          calledLocalLeads.where((lead) {
            final dateToCheck = lead.updatedAt ?? lead.createdAt;

            if (_headerController?.isRangeMode == true &&
                _headerController?.dateRangeStart != null &&
                _headerController?.dateRangeEnd != null) {
              final rangeStart = _headerController!.dateRangeStart!;
              final rangeEnd = DateTime(
                _headerController!.dateRangeEnd!.year,
                _headerController!.dateRangeEnd!.month,
                _headerController!.dateRangeEnd!.day,
                23,
                59,
                59,
              );
              return dateToCheck.isAfter(rangeStart) &&
                  dateToCheck.isBefore(rangeEnd);
            } else {
              final selectedDate =
                  _headerController?.selectedDate ?? DateTime.now();
              return dateToCheck.year == selectedDate.year &&
                  dateToCheck.month == selectedDate.month &&
                  dateToCheck.day == selectedDate.day;
            }
          }).toList();

      final reportIds = filteredReports.map((r) => r["id"]).toSet();
      for (final lead in filteredByDate) {
        if (!reportIds.contains(lead.id)) {
          final dateToUse = lead.updatedAt ?? lead.createdAt;
          filteredReports.add({
            "id": lead.id,
            "name": lead.name,
            "phone": lead.phone,
            "date": _formatDate(lead.createdAt),
            "callDate": dateToUse.toIso8601String(),
            "callDateFormatted": _formatDate(dateToUse),
            "callDateObj": dateToUse,
            "storeName": lead.location ?? lead.brand ?? "Not available",
            "type": "general",
            "callStatus": lead.callStatus ?? "Not called yet",
            "leadStatus": lead.leadStatus,
            "reason": lead.reason,
            "followUpDate": lead.followUpDate?.toIso8601String(),
            "callDuration": lead.callDuration,
            "remarks": lead.reason ?? "",
            "leadData": {},
          });
        }
      }
    }

    // Filter by call type index (1=Feedback, 2=Enquiry, 3=Booked, 4=Booking Confirmation, 5=Loss of Sale)
    if (_selectedCallTypeIndex > 0 && _selectedCallTypeIndex < 6) {
      final callTypeMap = {
        1: 'hardout', // Feedback
        2: 'enquiry', // Enquiry
        3: 'booking', // Booked
        4: 'bookingconfirmation', // Booking Confirmation
        5: 'lossofsale', // Loss of Sale
      };

      final selectedType = callTypeMap[_selectedCallTypeIndex];
      if (selectedType != null) {
        filteredReports =
            filteredReports.where((report) {
              final reportType = report["type"] as String? ?? "";
              return reportType == selectedType;
            }).toList();
      }
    }

    if (storeFilter != null) {
      print(
        'ReportController: Filtering by store - storeFilter.location: ${storeFilter.location}, storeFilter.normalizedName: ${storeFilter.normalizedName}',
      );
      filteredReports =
          filteredReports.where((report) {
            final storeName = report["storeName"] as String? ?? "";
            final matches =
                storeName.toLowerCase().contains(
                  storeFilter.location.toLowerCase(),
                ) ||
                storeFilter.location.toLowerCase().contains(
                  storeName.toLowerCase(),
                ) ||
                storeName.toLowerCase().contains(
                  storeFilter.normalizedName.toLowerCase(),
                ) ||
                storeFilter.normalizedName.toLowerCase().contains(
                  storeName.toLowerCase(),
                );
            if (!matches) {
              print(
                'ReportController: Report filtered out - storeName: "$storeName" does not match filter: "${storeFilter.location}" or "${storeFilter.normalizedName}"',
              );
            }
            return matches;
          }).toList();
      print(
        'ReportController: After store filter - ${filteredReports.length} reports remaining',
      );
    }

    return filteredReports;
  }

  String _normalizeStoreName(String? storeName) {
    if (storeName == null || storeName.isEmpty) return '';

    const Map<String, String> normalization = {
      'Calicut': 'Kozhikode',
      'calicut': 'Kozhikode',
      'CALICUT': 'Kozhikode',
      'Cochin': 'Edappally',
      'cochin': 'Edappally',
      'COCHIN': 'Edappally',
      'mg road': 'MG Road',
      'MG road': 'MG Road',
      'mg Road': 'MG Road',
      'MG_Road': 'MG Road',
      'mg_road': 'MG Road',
      'MG-Road': 'MG Road',
      'mg-road': 'MG Road',
      'M.G. Road': 'MG Road',
      'm.g. road': 'MG Road',
      'Vatakara': 'Vadakara',
      'vatakara': 'Vadakara',
      'VATAKARA': 'Vadakara',
      'trivandrum': 'Trivandrum',
      'TRIVANDRUM': 'Trivandrum',
      'Thiruvananthapuram': 'Trivandrum',
      'thiruvananthapuram': 'Trivandrum',
      'kottayam': 'Kottayam',
      'KOTTAYAM': 'Kottayam',
      'edappally': 'Edappally',
      'EDAPPALLY': 'Edappally',
      'Edapally': 'Edappally',
      'edapally': 'Edappally',
      'perumbavoor': 'Perumbavoor',
      'PERUMBAVOOR': 'Perumbavoor',
      'Perumbavur': 'Perumbavoor',
      'perumbavur': 'Perumbavoor',
      'thrissur': 'Thrissur',
      'THRISSUR': 'Thrissur',
      'Trichur': 'Thrissur',
      'trichur': 'Thrissur',
      'palakkad': 'Palakkad',
      'PALAKKAD': 'Palakkad',
      'Palghat': 'Palakkad',
      'palghat': 'Palakkad',
      'chavakkad': 'Chavakkad',
      'CHAVAKKAD': 'Chavakkad',
      'Chavakad': 'Chavakkad',
      'chavakad': 'Chavakkad',
      'edappal': 'Edappal',
      'EDAPPAL': 'Edappal',
      'Edapal': 'Edappal',
      'edapal': 'Edappal',
      'perinthalmanna': 'Perinthalmanna',
      'PERINTHALMANNA': 'Perinthalmanna',
      'manjeri': 'Manjeri',
      'MANJERI': 'Manjeri',
      'kottakal': 'Kottakal',
      'KOTTAKAL': 'Kottakal',
      'kozhikode': 'Kozhikode',
      'KOZHIKODE': 'Kozhikode',
      'vadakara': 'Vadakara',
      'VADAKARA': 'Vadakara',
      'kannur': 'Kannur',
      'KANNUR': 'Kannur',
      'Cannanore': 'Kannur',
      'cannanore': 'Kannur',
      'kalpetta': 'Kalpetta',
      'KALPETTA': 'Kalpetta',
      'Kottakkal': 'Kottakkal',
      'kottakkal': 'Kottakkal',
      'KOTTAKKAL': 'Kottakkal',
    };

    return normalization[storeName] ?? storeName;
  }

  String _getTypeFromLeadType(String? leadType) {
    if (leadType == null) return "general";

    final normalizedType = leadType.toLowerCase().trim();
    print(
      'ReportController: _getTypeFromLeadType - Input: "$leadType", Normalized: "$normalizedType"',
    );

    switch (normalizedType) {
      case "enquiry":
        return "enquiry";
      case "lossofsale":
      case "loss of sale":
        return "lossofsale";
      case "rentoutfeedback":
      case "return":
      case "feedback":
        return "hardout";
      case "bookingconfirmation":
      case "booking confirmation":
      case "booking_confirmation":
        return "bookingconfirmation";
      case "booked":
      case "booking":
        return "booking";
      case "justdial":
      case "just dial":
        return "justdial";
      default:
        print(
          'ReportController: Unknown leadType: "$leadType" -> mapping to "general"',
        );
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
        return "Feedback calls";
      case 3:
        return "Follow Up Calls";
      default:
        return "All calls";
    }
  }

  String _formatDate(DateTime date) {
    return DateFormatterUtil.formatDate(date);
  }

  void refresh() {
    notifyListeners();
  }

  Future<void> fetchReportsFromApi({
    String? leadType,
    String? editedBy,
    String? dateFrom,
    String? dateTo,
    String? createdAtFrom,
    String? createdAtTo,
    String? editedAtFrom,
    String? editedAtTo,
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
        createdAtFrom: createdAtFrom,
        createdAtTo: createdAtTo,
        editedAtFrom: editedAtFrom,
        editedAtTo: editedAtTo,
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
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'fetchReports failed',
      );
      notifyListeners();
      rethrow;
    }
  }

  Future<void> fetchReportsWithCurrentFilters() async {
    String dateFromStr;
    String dateToStr;

    if (_headerController?.isRangeMode == true &&
        _headerController?.dateRangeStart != null &&
        _headerController?.dateRangeEnd != null) {
      dateFromStr = DateFormatterUtil.formatDateForApi(
        _headerController!.dateRangeStart!,
      );
      dateToStr = DateFormatterUtil.formatDateForApi(
        _headerController!.dateRangeEnd!,
      );
    } else {
      final selectedDate = _headerController?.selectedDate ?? DateTime.now();
      dateFromStr = DateFormatterUtil.formatDateForApi(selectedDate);
      dateToStr = DateFormatterUtil.formatDateForApi(selectedDate);
    }

    String? storeParam;
    final store = _headerController?.selectedStore;
    if (store != null && store.normalizedName != 'All Stores') {
      storeParam = store.normalizedName;
    }

    print(
      'ReportController: Fetching completed leads - store: $storeParam, dateFrom: $dateFromStr, dateTo: $dateToStr',
    );

    try {
      // Don't pass store to API - filter on frontend instead
      // Backend /api/leads/completed may not support store filtering
      await fetchCompletedLeadsFromApi(
        store: null,
        fromDate: dateFromStr,
        toDate: dateToStr,
      );
    } catch (e) {
      print('ReportController: Error fetching completed leads: $e');
      rethrow;
    }
  }

  Future<void> fetchCompletedLeadsFromApi({
    String? store,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      _isLoadingReports = true;
      _reportsError = null;
      notifyListeners();

      final response = await _apiService.getCompletedLeads(
        store: store,
        fromDate: fromDate,
        toDate: toDate,
        limit: 1000,
      );

      final reportsResponse = ReportsResponse.fromJson(response);
      _reports = reportsResponse.reports;
      _pagination = reportsResponse.pagination;

      print(
        'ReportController: Fetched ${_reports.length} completed leads from API',
      );

      _isLoadingReports = false;
      notifyListeners();
    } catch (e, s) {
      _isLoadingReports = false;
      _reportsError = e.toString();
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'fetchCompletedLeads failed',
      );
      notifyListeners();
      rethrow;
    }
  }

  Future<void> fetchReportsByCurrentUser({
    String? leadType,
    String? dateFrom,
    String? dateTo,
    int? page,
    int? limit,
  }) async {
    await fetchReportsFromApi(
      leadType: leadType,
      dateFrom: dateFrom,
      dateTo: dateTo,
      page: page,
      limit: limit,
    );
  }

  void setSelectedDateCategory(String category) {
    _selectedDateCategory = category;
    notifyListeners();
  }

  List<Map<String, dynamic>> getFilteredReportsByDateCategory() {
    // Backend already filters by date range, so just return all reports
    // converted to the display format
    final allReports = getFilteredLeads();

    print(
      'ReportController: getFilteredReportsByDateCategory - Total reports: ${allReports.length}',
    );

    return allReports;
  }

  /// Export filtered reports to CSV with fresh data from backend API
  Future<void> exportReportsCsv() async {
    try {
      // Show loading indicator
      _isLoadingReports = true;
      notifyListeners();

      // Get date range parameters
      String dateFromStr;
      String dateToStr;

      if (_headerController?.isRangeMode == true &&
          _headerController?.dateRangeStart != null &&
          _headerController?.dateRangeEnd != null) {
        dateFromStr = DateFormatterUtil.formatDateForApi(
          _headerController!.dateRangeStart!,
        );
        dateToStr = DateFormatterUtil.formatDateForApi(
          _headerController!.dateRangeEnd!,
        );
      } else {
        final selectedDate = _headerController?.selectedDate ?? DateTime.now();
        dateFromStr = DateFormatterUtil.formatDateForApi(selectedDate);
        dateToStr = DateFormatterUtil.formatDateForApi(selectedDate);
      }

      // Get store filter if applied
      String? storeParam;
      final store = _headerController?.selectedStore;
      if (store != null && store.normalizedName != 'All Stores') {
        storeParam = store.normalizedName;
      }

      Logger.info(
        'CSV Export: Fetching reports from backend - store: $storeParam, dateFrom: $dateFromStr, dateTo: $dateToStr',
      );

      // Fetch fresh data from backend API
      final response = await _apiService.getCompletedLeads(
        store: storeParam,
        fromDate: dateFromStr,
        toDate: dateToStr,
        limit: 10000, // Get all records for export
      );

      // Parse response
      final reportsResponse = ReportsResponse.fromJson(response);
      final apiReports = reportsResponse.reports;

      if (apiReports.isEmpty) {
        _isLoadingReports = false;
        notifyListeners();
        throw Exception('No reports available to export');
      }

      // Convert API reports to display format
      final displayReports = _convertApiReportsToDisplayFormat(apiReports);

      Logger.info(
        'CSV Export: Fetched ${displayReports.length} reports from backend',
      );

      // Get date range label
      final dateRangeLabel = _getDateRangeLabel();

      // Format reports to CSV
      final csvData = CsvFormatter.formatReportsToCsv(
        reports: displayReports,
        dateRangeLabel: dateRangeLabel,
        exportDate: DateTime.now(),
        storeFilter: storeParam,
      );

      // Generate filename
      final fileName = CsvFormatter.generateFileName(dateRangeLabel);

      // Get application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File("${directory.path}/$fileName");

      // Write CSV to file
      await file.writeAsString(csvData);

      // Share the file
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Call Report Export - $dateRangeLabel');

      _isLoadingReports = false;
      notifyListeners();

      Logger.info('CSV exported successfully: ${file.path}');
    } catch (e, s) {
      _isLoadingReports = false;
      notifyListeners();
      Logger.error('CSV Export Error', e, s);
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'exportReportsCsv failed',
      );
      rethrow;
    }
  }

  /// Convert API reports to display format for CSV export
  List<Map<String, dynamic>> _convertApiReportsToDisplayFormat(
    List<ReportModel> apiReports,
  ) {
    return apiReports.map((report) {
      final leadData = report.leadData ?? {};

      final leadName =
          leadData['name']?.toString() ??
          leadData['lead_name']?.toString() ??
          leadData['customerName']?.toString() ??
          '';
      final leadPhone =
          leadData['phone']?.toString() ??
          leadData['phone_number']?.toString() ??
          '';

      var leadLocation =
          leadData['store']?.toString() ??
          leadData['location']?.toString() ??
          '';

      if (leadLocation.isNotEmpty && !leadLocation.contains(' - ')) {
        leadLocation = _normalizeStoreName(leadLocation);
      } else if (leadLocation.isNotEmpty && leadLocation.contains(' - ')) {
        final parts = leadLocation.split(' - ');
        if (parts.length == 2) {
          final normalizedLocation = _normalizeStoreName(parts[1]);
          leadLocation = '${parts[0]} - $normalizedLocation';
        }
      }

      final leadStatus =
          leadData['leadStatus']?.toString() ??
          leadData['lead_status']?.toString();
      final reason =
          leadData['remarks']?.toString() ??
          leadData['reason']?.toString() ??
          leadData['reason_collected_from_store']?.toString() ??
          '';

      final callDuration = () {
        final callDur =
            leadData['callDuration'] ??
            leadData['call_duration'] ??
            report.callDuration;
        if (callDur == null) return null;
        if (callDur is int) return callDur;
        if (callDur is String) {
          try {
            return int.parse(callDur);
          } catch (_) {
            return null;
          }
        }
        return null;
      }();

      final createdAt =
          DateFormatterUtil.parseDate(leadData['createdAt']) ??
          DateFormatterUtil.parseDate(leadData['created_at']) ??
          report.editedAt ??
          report.createdAt;

      return {
        "id": report.originalId,
        "name": leadName,
        "phone": leadPhone,
        "date": _formatDate(createdAt),
        "callDate":
            report.editedAt != null
                ? report.editedAt!.toIso8601String()
                : createdAt.toIso8601String(),
        "callDateFormatted":
            report.editedAt != null
                ? _formatDate(report.editedAt!)
                : _formatDate(createdAt),
        "callDateObj": report.editedAt ?? createdAt,
        "storeName": leadLocation.isNotEmpty ? leadLocation : "Not available",
        "type": _getTypeFromLeadType(report.leadType),
        "leadStatus": leadStatus,
        "callDuration": callDuration,
        "remarks": report.note ?? reason,
      };
    }).toList();
  }

  /// Get human-readable date range label for CSV export
  String _getDateRangeLabel() {
    if (_headerController?.isRangeMode == true &&
        _headerController?.dateRangeStart != null &&
        _headerController?.dateRangeEnd != null) {
      final startDate = DateFormatterUtil.formatDate(
        _headerController!.dateRangeStart!,
      );
      final endDate = DateFormatterUtil.formatDate(
        _headerController!.dateRangeEnd!,
      );
      return '$startDate to $endDate';
    } else {
      return _selectedDateCategory;
    }
  }
}
