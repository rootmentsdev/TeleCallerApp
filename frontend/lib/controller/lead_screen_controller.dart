import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/model/lead_display_model.dart';
import 'package:telecaller_app/model/store_model.dart';
import 'package:telecaller_app/utils/lead_constants.dart';

/// Controller for Lead Screen
class LeadScreenController extends ChangeNotifier {
  final LeadRepository _repository = LeadRepository();
  HeaderController? _headerController;
  int _selectedCallTypeIndex = 0; // 0: Feedback Calls, 1: Loss of Sale, etc.

  LeadScreenController() {
    // Listen to repository changes and forward notifications so UI updates
    _repository.addListener(_onRepositoryChanged);
  }

  // If true, UI should show only the newly added lead (if available)
  bool _showOnlyNewLead = false;
  String? _focusedNewLeadId;

  /// Call to explicitly clear the "show only new lead" filter
  void clearShowOnlyNewLead() {
    _showOnlyNewLead = false;
    _focusedNewLeadId = null;
    // Also clear repository marker so subsequent adds work as expected
    _repository.clearLastAddedMarker();
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
    notifyListeners();

    final store = _headerController?.selectedStore;
    final storeParam =
        (store == null || store.normalizedName == 'All Stores')
            ? null
            : store.normalizedName;

    String? dateFrom;
    String? dateTo;
    DateTime? singleDate;

    if (_headerController?.isRangeMode == true &&
        _headerController?.dateRangeStart != null &&
        _headerController?.dateRangeEnd != null) {
      dateFrom = _formatDateForApi(_headerController!.dateRangeStart!);
      final endOfDay = DateTime(
        _headerController!.dateRangeEnd!.year,
        _headerController!.dateRangeEnd!.month,
        _headerController!.dateRangeEnd!.day,
        23,
        59,
        59,
      );
      dateTo = _formatDateForApi(endOfDay);
    } else {
      singleDate = _headerController?.selectedDate ?? DateTime.now();
    }

    _fetchLeadsForCurrentFilters(storeParam, dateFrom, dateTo, singleDate);
  }

  void _fetchLeadsForCurrentFilters(
    String? store,
    String? dateFrom,
    String? dateTo,
    DateTime? singleDate,
  ) {
    // Format single date to API format if provided
    String? formattedDateFrom;
    String? formattedDateTo;

    if (dateFrom != null && dateTo != null) {
      formattedDateFrom = dateFrom;
      formattedDateTo = dateTo;
    } else if (singleDate != null) {
      // Convert single date to date range (full day)
      formattedDateFrom = _formatDateForApi(singleDate);
      // End of day
      final endOfDay = DateTime(
        singleDate.year,
        singleDate.month,
        singleDate.day,
        23,
        59,
        59,
      );
      formattedDateTo = _formatDateForApi(endOfDay);
    }

    // Always pass date parameters if available
    if (store != null) {
      fetchAllLeadsFromApi(
        store: store,
        dateFrom: formattedDateFrom,
        dateTo: formattedDateTo,
        dateField: 'createdAt',
      ).catchError((_) {});
      fetchReturnLeadsFromApi(
        store: store,
        fromDate: formattedDateFrom,
        toDate: formattedDateTo,
      ).catchError((_) {});
    } else {
      fetchAllLeadsFromApi(
        dateFrom: formattedDateFrom,
        dateTo: formattedDateTo,
        dateField: 'createdAt',
      ).catchError((_) {});
      fetchReturnLeadsFromApi(
        fromDate: formattedDateFrom,
        toDate: formattedDateTo,
      ).catchError((_) {});
    }
  }

  void _onRepositoryChanged() {
    final lastAdded = _repository.lastAddedLeadId;
    if (lastAdded != null) {
      _showOnlyNewLead = true;
      _focusedNewLeadId = lastAdded;
      Future.delayed(const Duration(seconds: 2), () {
        if (_focusedNewLeadId == lastAdded) {
          clearShowOnlyNewLead();
        }
      });
    }
    notifyListeners();
  }

  void _removeLeadFromActiveLists(String id) {
    // Removal is handled by LeadRepository.updateLead()
  }

  @override
  void dispose() {
    _headerController?.removeListener(_onHeaderChanged);
    _repository.removeListener(_onRepositoryChanged);
    // NOTE: Do NOT dispose the repository - it's a singleton shared across the app
    // Only remove our listener from it
    super.dispose();
  }

  // Getters
  DateTime get selectedDate =>
      _headerController?.selectedDate ?? DateTime.now();
  Store? get selectedStore => _headerController?.selectedStore;
  int get selectedCallTypeIndex => _selectedCallTypeIndex;

  // Setters
  void setSelectedCallTypeIndex(int index) {
    _selectedCallTypeIndex = index;
    // Clear "show only new lead" when switching tabs so all leads are visible
    if (_showOnlyNewLead) {
      clearShowOnlyNewLead();
    }
    notifyListeners();
  }

  List<Map<String, dynamic>> getCallSummary() {
    int getCalledLeadsCount({String? category}) {
      List<LeadModel> leads = _repository.allLeads;

      if (category != null) {
        leads = leads.where((lead) => lead.category == category).toList();
      }

      final storeFilter = _headerController?.selectedStore;
      if (storeFilter != null && storeFilter.normalizedName != "All Stores") {
        final storeParam = storeFilter.normalizedName;
        leads =
            leads
                .where((lead) => _repository.matchesStore(lead, storeParam))
                .toList();
      }

      // Filter for CALLED leads
      leads =
          leads
              .where((lead) => LeadConstants.isCalledStatus(lead.callStatus))
              .toList();

      return leads.length;
    }

    int getUncalledLeadsCount({String? category}) {
      List<LeadModel> leads = _repository.allLeads;

      if (category != null) {
        leads = leads.where((lead) => lead.category == category).toList();
      }

      final storeFilter = _headerController?.selectedStore;
      if (storeFilter != null && storeFilter.normalizedName != "All Stores") {
        final storeParam = storeFilter.normalizedName;
        leads =
            leads
                .where((lead) => _repository.matchesStore(lead, storeParam))
                .toList();
      }

      leads =
          leads
              .where((lead) => LeadConstants.isUncalledStatus(lead.callStatus))
              .toList();

      leads =
          leads
              .where(
                (lead) =>
                    lead.followUpDate == null ||
                    lead.category != LeadConstants.categoryFollowUp,
              )
              .toList();

      return leads.length;
    }

    int getStarredLeadsCount() {
      List<LeadModel> leads = _repository.starredCallsLeads;

      final storeFilter = _headerController?.selectedStore;
      if (storeFilter != null && storeFilter.normalizedName != "All Stores") {
        final storeParam = storeFilter.normalizedName;
        leads =
            leads
                .where((lead) => _repository.matchesStore(lead, storeParam))
                .toList();
      }

      return leads.length;
    }

    return [
      {
        "title": "Calls Today",
        "count": getCalledLeadsCount().toString(),
        "bgColor": const Color(0xFFE8E3FF),
        "iconColor": const Color(0xFF7C5DFF),
        "icon": Icons.people_alt_outlined,
      },
      {
        "title": "Loss of Sale",
        "count":
            getUncalledLeadsCount(
              category: LeadConstants.categoryLossOfSales,
            ).toString(),
        "bgColor": const Color(0xFFFFE8E8),
        "iconColor": const Color(0xFFE23434),
        "icon": Icons.trending_down,
      },
      {
        "title": "Feedback Calls",
        "count":
            getUncalledLeadsCount(
              category: LeadConstants.categoryRentOut,
            ).toString(),
        "bgColor": const Color(0xFFFFF7CC),
        "iconColor": const Color(0xFFFFCC00),
        "icon": Icons.message_outlined,
      },
      {
        "title": "Marked Calls",
        "count": getStarredLeadsCount().toString(),
        "bgColor": const Color(0xFFE3F2FD),
        "iconColor": const Color(0xFF1976D2),
        "icon": Icons.star_rounded,
        "isStarred": true,
      },
    ];
  }

  List<LeadDisplayModel> getFilteredLeads() {
    final store = _headerController?.selectedStore;
    List<LeadModel> filteredLeads = [];

    // Backend already filters by date range and store, so just get the appropriate leads
    // based on the selected tab - NO additional local filtering
    if (_selectedCallTypeIndex == 0) {
      // Booking Confirmation tab
      filteredLeads =
          _repository.allLeads
              .where(
                (lead) =>
                    lead.category == LeadConstants.categoryBookingConfirmation,
              )
              .toList();
    } else if (_selectedCallTypeIndex == 1) {
      // Feedback Calls tab (Return leads)
      // Backend already filtered by store and date, just filter by category
      filteredLeads =
          _repository.allLeads
              .where((lead) => lead.category == LeadConstants.categoryRentOut)
              .toList();
    } else if (_selectedCallTypeIndex == 3) {
      // Marked Calls tab (Starred leads)
      filteredLeads = _repository.starredCallsLeads;
    } else {
      // Other tabs
      filteredLeads = _repository.allLeads;
    }

    // Handle "show only new lead" feature
    if (_showOnlyNewLead &&
        _focusedNewLeadId != null &&
        _selectedCallTypeIndex == 0) {
      final matches =
          filteredLeads.where((l) => l.id == _focusedNewLeadId).toList();
      if (matches.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_focusedNewLeadId == matches.first.id) {
            clearShowOnlyNewLead();
          }
        });
        return [LeadDisplayModel.fromLead(matches.first)];
      }
      clearShowOnlyNewLead();
    }

    // Sort leads alphabetically by name
    filteredLeads.sort((a, b) => a.name.compareTo(b.name));

    return filteredLeads
        .map((lead) => LeadDisplayModel.fromLead(lead))
        .toList();
  }

  String getCurrentTitle() {
    switch (_selectedCallTypeIndex) {
      case 0:
        return "Booking Confirmation";
      case 1:
        return "Feedback Calls";
      case 2:
        return "Loss of Sale";
      case 3:
        return "Marked Calls";
      default:
        return "Feedback Calls";
    }
  }

  int getBookingConfirmationCount() {
    // Backend already filters by store and date, just count by category
    List<LeadModel> leads =
        _repository.allLeads
            .where(
              (lead) =>
                  lead.category == LeadConstants.categoryBookingConfirmation,
            )
            .toList();

    return leads.length;
  }

  int getReturnLeadsCount() {
    // Backend already filters by store and date, just count by category
    List<LeadModel> leads =
        _repository.allLeads
            .where((lead) => lead.category == LeadConstants.categoryRentOut)
            .toList();

    return leads.length;
  }

  int getFollowUpLeadsCount() {
    List<LeadModel> leads = _repository.followUpLeads;

    final store = _headerController?.selectedStore;
    if (store != null && store.normalizedName != 'All Stores') {
      final storeParam = store.normalizedName;
      leads =
          leads
              .where((lead) => _repository.matchesStore(lead, storeParam))
              .toList();
    }

    return leads.length;
  }

  void refresh() {
    notifyListeners();
  }

  Future<void> fetchReturnLeadsFromApi({
    String? store,
    String? enquiryFrom,
    String? enquiryTo,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      print('═══════════════════════════════════════════════════════════');
      print('LeadScreenController: CALLING fetchReturnLeadsFromApi');
      print('═══════════════════════════════════════════════════════════');
      print('Parameters:');
      print('  store: $store');
      print('  fromDate: $fromDate');
      print('  toDate: $toDate');
      print('  enquiryFrom: $enquiryFrom');
      print('  enquiryTo: $enquiryTo');
      print('═══════════════════════════════════════════════════════════');

      await _repository.fetchReturnLeadsFromApi(
        store: store,
        enquiryFrom: enquiryFrom,
        enquiryTo: enquiryTo,
        fromDate: fromDate,
        toDate: toDate,
      );
      notifyListeners();
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'fetchReturnLeadsFromApi failed',
      );
      rethrow;
    }
  }

  Future<void> fetchAllLeadsFromApi({
    String? store,
    int? page,
    DateTime? date,
    String? enquiryDateFrom,
    String? enquiryDateTo,
    String? functionDateFrom,
    String? functionDateTo,
    String? visitDateFrom,
    String? visitDateTo,
    String? dateFrom,
    String? dateTo,
    String? dateField,
    String? createdAt,
  }) async {
    try {
      String? finalCreatedAt = createdAt;
      if (date != null && createdAt == null) {
        finalCreatedAt = _formatDateForApi(date);
      }

      await _repository.fetchAllLeadsFromApi(
        store: store,
        page: page,
        enquiryDateFrom: enquiryDateFrom,
        enquiryDateTo: enquiryDateTo,
        functionDateFrom: functionDateFrom,
        functionDateTo: functionDateTo,
        visitDateFrom: visitDateFrom,
        visitDateTo: visitDateTo,
        dateFrom: dateFrom,
        dateTo: dateTo,
        dateField: dateField,
        createdAt: finalCreatedAt,
      );
      notifyListeners();
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'fetchAllLeadsFromApi failed',
      );
      rethrow;
    }
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> updateReturnLead({
    required String id,
    String? callStatus,
    String? leadStatus,
    bool? followUpFlag,
    DateTime? callDate,
    int? rating,
    String? remarks,
    int? callDuration,
    DateTime? followUpDate,
    bool? clearFollowUpDate,
    String? subCategory,
    String? itemCategory,
    DateTime? functionDate,
    String? leadType,
    bool? markAsComplaint,
    String? numberOfFunctions,
    String? numberOfAttires,
    String? competitor,
    String? service,
    String? refundStatus,
  }) async {
    try {
      await _repository.updateReturnLeadFromApi(
        id: id,
        callStatus: callStatus,
        leadStatus: leadStatus,
        followUpFlag: followUpFlag,
        callDate: callDate,
        rating: rating,
        remarks: remarks,
        callDuration: callDuration,
        followUpDate: followUpDate,
        clearFollowUpDate: clearFollowUpDate,
        subCategory: subCategory,
        itemCategory: itemCategory,
        functionDate: functionDate,
        leadType: leadType,
        markAsComplaint: markAsComplaint,
        numberOfFunctions: numberOfFunctions,
        numberOfAttires: numberOfAttires,
        competitor: competitor,
        service: service,
        refundStatus: refundStatus,
      );
      _removeLeadFromActiveLists(id);
      notifyListeners();
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'updateReturnLead failed',
      );
      rethrow;
    }
  }

  Future<void> updateFollowUpLead({
    required String id,
    String? callStatus,
    String? leadStatus,
    String? remarks,
    int? callDuration,
    String? subCategory,
    String? closingAction,
    int? rating,
    String? leadType,
    DateTime? functionDate,
    bool? followUpFlag,
    DateTime? followUpDate,
    bool? markAsComplaint,
  }) async {
    try {
      await _repository.updateFollowUpLeadFromApi(
        id: id,
        callStatus: callStatus,
        leadStatus: leadStatus,
        remarks: remarks,
        callDuration: callDuration,
        clearFollowUpDate: false,
        subCategory: subCategory,
        closingAction: closingAction,
        rating: rating,
        leadType: leadType,
        functionDate: functionDate,
        followUpFlag: followUpFlag,
        followUpDate: followUpDate,
        markAsComplaint: markAsComplaint,
      );
      _removeLeadFromActiveLists(id);
      notifyListeners();
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'updateFollowUpLead failed',
      );
      rethrow;
    }
  }

  Future<void> fetchStarredCallsFromApi({String? store}) async {
    try {
      await _repository.fetchStarredCallsFromApi(store: store);
      notifyListeners();
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'fetchStarredCallsFromApi failed',
      );
      rethrow;
    }
  }

  Future<void> fetchBookingConfirmationLeadsFromApi({
    String? store,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      await _repository.fetchBookingConfirmationLeadsFromApi(
        store: store,
        fromDate: fromDate,
        toDate: toDate,
      );
      notifyListeners();
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'fetchBookingConfirmationLeadsFromApi failed',
      );
      rethrow;
    }
  }

  Future<void> updateBookingConfirmationLead({
    required String id,
    String? callStatus,
    String? leadStatus,
    String? service,
    bool? billReceived,
    bool? amountMismatch,
    String? advancePaid,
    String? securityPaid,
    String? remarks,
    int? callDuration,
    bool? followUpFlag,
    DateTime? followUpDate,
    bool? clearFollowUpDate,
  }) async {
    try {
      // Get the lead to preserve existing data
      final lead = _repository.getLeadById(id);
      if (lead == null) {
        throw Exception('Lead not found');
      }

      await _repository.updateBookingConfirmationLeadFromApi(
        id: id,
        leadName: lead.name,
        phoneNumber: lead.phone,
        store: lead.location ?? lead.brand ?? 'N/A',
        source: 'Manual Entry', // Default or get from lead if available
        leadType: lead.leadType ?? 'enquiry',
        callStatus: callStatus ?? lead.callStatus ?? 'Not Called',
        leadStatus: leadStatus ?? lead.leadStatus ?? 'No Status',
        service: service,
        billReceived: billReceived,
        amountMismatch: amountMismatch,
        advancePaid: advancePaid,
        securityPaid: securityPaid,
        remarks: remarks,
        followUpFlag: followUpFlag ?? false,
        followUpDate:
            followUpDate != null ? followUpDate.toIso8601String() : null,
        callDuration: callDuration,
        clearFollowUpDate: clearFollowUpDate ?? false,
      );

      _removeLeadFromActiveLists(id);
      notifyListeners();
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'updateBookingConfirmationLead failed',
      );
      rethrow;
    }
  }
}
