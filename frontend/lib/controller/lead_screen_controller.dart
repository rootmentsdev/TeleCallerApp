import 'package:flutter/material.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/model/lead_display_model.dart';
import 'package:telecaller_app/utils/lead_constants.dart';
import 'package:telecaller_app/utils/store_location.dart';

/// Controller for Lead Screen
class LeadScreenController extends ChangeNotifier {
  final LeadRepository _repository = LeadRepository();
  HeaderController? _headerController;
  int _selectedCallTypeIndex = 0; // 0: All Calls, 1: Loss of Sale, etc.

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
    final storeParam = (store == null || store == 'All Stores') ? null : store;
    final selectedDate = _headerController?.selectedDate ?? DateTime.now();

    _fetchAllLeadTypes(storeParam, selectedDate);
  }

  void _fetchAllLeadTypes(String? store, DateTime date) {
    fetchAllLeadsFromApi(store: store, date: date).catchError((_) {});
    fetchLossOfSaleLeadsFromApi(store: store).catchError((_) {});
    fetchRentOutLeadsFromApi(store: store).catchError((_) {});
    fetchBookingConfirmationLeadsFromApi(store: store).catchError((_) {});
  }

  void _onRepositoryChanged() {
    // If repository has a last-added lead id, focus on it (show only new lead)
    final lastAdded = _repository.lastAddedLeadId;
    if (lastAdded != null) {
      _showOnlyNewLead = true;
      _focusedNewLeadId = lastAdded;
      // Auto-clear after showing the new lead once (after a short delay)
      Future.delayed(const Duration(seconds: 2), () {
        if (_focusedNewLeadId == lastAdded) {
          clearShowOnlyNewLead();
        }
      });
    }

    // Forward repository changes to listeners of this controller
    notifyListeners();
  }

  void _removeLeadFromActiveLists(String id) {
    _repository.allLeads.removeWhere((lead) => lead.id == id);
  }

  bool _matchesStore(String? leadLocation, String storeFilter) {
    if (leadLocation == null || leadLocation.isEmpty) return false;

    final selectedLocation =
        StoreLocations.resolveSelection(storeFilter).location;
    final selectedBrand = StoreLocations.resolveSelection(storeFilter).brand;
    final normalizedLocation = selectedLocation.toLowerCase().trim();
    final normalizedBrand = selectedBrand.toLowerCase().trim();
    final normalizedStore = storeFilter.toLowerCase().trim();
    final leadLoc = leadLocation.toLowerCase().trim();

    // Extract location from "SG-Edappally" format
    final extractedLoc =
        leadLoc.startsWith('sg-')
            ? leadLoc.substring(3)
            : leadLoc.contains('-')
            ? leadLoc.split('-').last.trim()
            : leadLoc;

    return leadLoc == normalizedStore ||
        leadLoc == normalizedLocation ||
        extractedLoc == normalizedLocation ||
        leadLoc.contains(normalizedLocation) ||
        extractedLoc.contains(normalizedLocation) ||
        normalizedLocation.contains(leadLoc) ||
        normalizedLocation.contains(extractedLoc) ||
        leadLoc.contains(normalizedBrand) ||
        (normalizedStore.contains(' - ') &&
            _matchesStoreParts(leadLoc, extractedLoc, normalizedStore));
  }

  bool _matchesStoreParts(
    String leadLoc,
    String extractedLoc,
    String normalizedStore,
  ) {
    final parts = normalizedStore.split(' - ');
    if (parts.length <= 1) return false;
    final storeLocPart = parts.last;
    return leadLoc == storeLocPart ||
        leadLoc.contains(storeLocPart) ||
        storeLocPart.contains(leadLoc) ||
        extractedLoc == storeLocPart ||
        extractedLoc.contains(storeLocPart) ||
        storeLocPart.contains(extractedLoc);
  }

  @override
  void dispose() {
    _headerController?.removeListener(_onHeaderChanged);
    _repository.removeListener(_onRepositoryChanged);
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
    // Clear "show only new lead" when switching tabs so all leads are visible
    if (_showOnlyNewLead) {
      clearShowOnlyNewLead();
    }
    notifyListeners();
  }

  // Get call summary data (filtered by store and date/date range)
  // Only count leads that haven't been called yet
  List<Map<String, dynamic>> getCallSummary() {
    int getUncalledLeadsCount({String? category, bool followUpOnly = false}) {
      final headerController = _headerController;
      if (headerController == null) return 0;

      List<LeadModel> leads;

      // Use date range if available, otherwise use single date
      if (headerController.isRangeMode &&
          headerController.dateRangeStart != null &&
          headerController.dateRangeEnd != null) {
        leads =
            category != null
                ? _repository
                    .getLeadsByDateRange(
                      headerController.dateRangeStart!,
                      headerController.dateRangeEnd!,
                    )
                    .where((lead) => lead.category == category)
                    .toList()
                : _repository.getLeadsByDateRange(
                  headerController.dateRangeStart!,
                  headerController.dateRangeEnd!,
                );
      } else {
        final date = headerController.selectedDate;
        leads =
            category != null
                ? _repository.getLeadsByCategory(category, date: date)
                : _repository.getLeadsByDate(date);
      }

      final storeFilter = headerController.selectedStore;
      if (storeFilter != "All Stores") {
        leads =
            leads
                .where((lead) => _matchesStore(lead.location, storeFilter))
                .toList();
      }

      if (followUpOnly) {
        leads = leads.where((lead) => lead.followUpDate != null).toList();
      } else {
        leads =
            leads
                .where(
                  (lead) => LeadConstants.isUncalledStatus(lead.callStatus),
                )
                .toList();
        leads = leads.where((lead) => lead.followUpDate == null).toList();
      }

      return leads.length;
    }

    return [
      {
        "title": "All Calls",
        "count": getUncalledLeadsCount().toString(),
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
        "title": "Return",
        "count":
            getUncalledLeadsCount(
              category: LeadConstants.categoryRentOut,
            ).toString(),
        "bgColor": const Color(0xFFFFF7CC),
        "iconColor": const Color(0xFFFFCC00),
        "icon": Icons.message_outlined,
      },
      {
        "title": "Booking\nConfirmation",
        "count":
            getUncalledLeadsCount(
              category: LeadConstants.categoryBookingConfirmation,
            ).toString(),
        "bgColor": const Color(0xFFD4F5DA),
        "iconColor": const Color(0xff56BE6B),
        "icon": Icons.check_circle_outlined,
      },
    ];
  }

  // Get filtered leads based on selected call type
  List<LeadDisplayModel> getFilteredLeads() {
    String? category = _getCategoryForIndex(_selectedCallTypeIndex);
    final headerController = _headerController;
    if (headerController == null) return [];

    final store = headerController.selectedStore;

    List<LeadModel> filteredLeads;

    // Use date range if available, otherwise use single date
    if (headerController.isRangeMode &&
        headerController.dateRangeStart != null &&
        headerController.dateRangeEnd != null) {
      filteredLeads = _repository.getLeadsByDateRange(
        headerController.dateRangeStart!,
        headerController.dateRangeEnd!,
      );
      if (category != null) {
        filteredLeads =
            filteredLeads.where((lead) => lead.category == category).toList();
      }
    } else {
      final date = headerController.selectedDate;
      filteredLeads = _repository.getLeadsByCategory(category, date: date);
    }

    if (store != 'All Stores') {
      filteredLeads =
          filteredLeads
              .where((lead) => _matchesStore(lead.location, store))
              .toList();
    }

    if (_selectedCallTypeIndex != 0) {
      filteredLeads =
          filteredLeads
              .where((lead) => LeadConstants.isUncalledStatus(lead.callStatus))
              .toList();
    }

    filteredLeads =
        filteredLeads.where((lead) => lead.followUpDate == null).toList();

    if (_showOnlyNewLead &&
        _focusedNewLeadId != null &&
        _selectedCallTypeIndex == 0) {
      final matches =
          filteredLeads.where((l) => l.id == _focusedNewLeadId).toList();
      if (matches.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_focusedNewLeadId == matches.first.id) clearShowOnlyNewLead();
        });
        return [LeadDisplayModel.fromLead(matches.first)];
      }
      clearShowOnlyNewLead();
    }

    return filteredLeads
        .map((lead) => LeadDisplayModel.fromLead(lead))
        .toList();
  }

  String getCurrentTitle() {
    switch (_selectedCallTypeIndex) {
      case 0:
        return "All Calls";
      case 1:
        return "Loss of Sale";
      case 2:
        return "Return";
      case 3:
        return "Booking Confirmation";
      default:
        return "All Calls";
    }
  }

  /// Get count of follow-up leads for the selected date and store
  int getFollowUpLeadsCount() {
    final date = _headerController?.selectedDate ?? DateTime.now();
    final store = _headerController?.selectedStore;

    // Get all leads for the selected date
    List<LeadModel> leads = _repository.getLeadsByDate(date);

    // Filter by store if specified
    if (store != null && store != 'All Stores') {
      final selectedLocation = StoreLocations.resolveSelection(store).location;
      leads = leads.where((lead) => lead.location == selectedLocation).toList();
    }

    // Count only leads with follow-up dates
    return leads.where((lead) => lead.followUpDate != null).length;
  }

  String? _getCategoryForIndex(int index) {
    switch (index) {
      case 0:
        return null; // All Calls
      case 1:
        return LeadConstants.categoryLossOfSales;
      case 2:
        return LeadConstants.categoryRentOut;
      case 3:
        return LeadConstants.categoryBookingConfirmation;
      default:
        return null;
    }
  }

  void refresh() {
    notifyListeners();
  }

  /// Fetch Loss of Sale leads from API
  Future<void> fetchLossOfSaleLeadsFromApi({
    String? store,
    String? enquiryFrom,
    String? enquiryTo,
    String? functionFrom,
    String? functionTo,
    String? visitFrom,
    String? visitTo,
  }) async {
    try {
      await _repository.fetchLossOfSaleLeadsFromApi(
        store: store,
        enquiryFrom: enquiryFrom,
        enquiryTo: enquiryTo,
        functionFrom: functionFrom,
        functionTo: functionTo,
        visitFrom: visitFrom,
        visitTo: visitTo,
      );
      notifyListeners();
    } catch (e) {
      print('LeadScreenController: Error fetching Loss of Sale leads: $e');
      rethrow;
    }
  }

  /// Fetch Booking Confirmation leads from API
  Future<void> fetchBookingConfirmationLeadsFromApi({String? store}) async {
    try {
      await _repository.fetchBookingConfirmationLeadsFromApi(store: store);
      notifyListeners();
    } catch (e) {
      print(
        'LeadScreenController: Error fetching Booking Confirmation leads: $e',
      );
      rethrow;
    }
  }

  /// Fetch Rent-Out leads from API
  Future<void> fetchRentOutLeadsFromApi({String? store}) async {
    try {
      await _repository.fetchRentOutLeadsFromApi(store: store);
      notifyListeners();
    } catch (e) {
      print('LeadScreenController: Error fetching Rent-Out leads: $e');
      rethrow;
    }
  }

  /// Format date to YYYY-MM-DD format for API
  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Fetch all leads from API with store and date filters
  /// Uses endpoint: /api/pages/leads?store=Suitor Guy - Edappal&createdAt=2025-12-04
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
      // If date is provided, use it for createdAt filtering (primary date filter)
      String? finalCreatedAt = createdAt;

      if (date != null && createdAt == null) {
        // Use the provided date for createdAt filter (format: YYYY-MM-DD)
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
    } catch (e) {
      print('LeadScreenController: Error fetching all leads: $e');
      rethrow;
    }
  }

  /// Update Loss of Sale lead via API
  Future<void> updateLossOfSaleLead({
    required String id,
    String? callStatus,
    String? leadStatus,
    DateTime? followUpDate,
    String? reasonCollectedFromStore,
    String? remarks,
    int? callDuration,
  }) async {
    try {
      print('[LeadScreenController] updateLossOfSaleLead called');
      print('[LeadScreenController] ID: $id');
      print('[LeadScreenController] callStatus: $callStatus');
      print('[LeadScreenController] leadStatus: $leadStatus');
      print('[LeadScreenController] callDuration: $callDuration');
      print('[LeadScreenController] remarks: $remarks');

      await _repository.updateLossOfSaleLeadFromApi(
        id: id,
        callStatus: callStatus,
        leadStatus: leadStatus,
        followUpDate: followUpDate,
        reasonCollectedFromStore: reasonCollectedFromStore,
        remarks: remarks,
        callDuration: callDuration,
      );

      print('[LeadScreenController] updateLossOfSaleLeadFromApi completed');

      _removeLeadFromActiveLists(id);
      print('[LeadScreenController] Lead removed from active lists');

      notifyListeners();
      print('[LeadScreenController] Listeners notified');
    } catch (e) {
      print('[LeadScreenController] Error updating Loss of Sale lead: $e');
      rethrow;
    }
  }

  /// Update Rent-Out lead via API
  Future<void> updateRentOutLead({
    required String id,
    String? callStatus,
    String? leadStatus,
    bool? followUpFlag,
    DateTime? callDate,
    int? rating,
    String? remarks,
    int? callDuration,
  }) async {
    try {
      await _repository.updateRentOutLeadFromApi(
        id: id,
        callStatus: callStatus,
        leadStatus: leadStatus,
        followUpFlag: followUpFlag,
        callDate: callDate,
        rating: rating,
        remarks: remarks,
        callDuration: callDuration,
      );
      _removeLeadFromActiveLists(id);
      notifyListeners();
    } catch (e) {
      print('LeadScreenController: Error updating Rent-Out lead: $e');
      rethrow;
    }
  }

  /// Update Booking Confirmation lead via API
  Future<void> updateBookingConfirmationLead({
    required String id,
    String? callStatus,
    String? leadStatus,
    bool? followUpFlag,
    DateTime? callDate,
    String? remarks,
    int? callDuration,
  }) async {
    try {
      await _repository.updateBookingConfirmationLeadFromApi(
        id: id,
        callStatus: callStatus,
        leadStatus: leadStatus,
        followUpFlag: followUpFlag,
        callDate: callDate,
        remarks: remarks,
        callDuration: callDuration,
      );
      _removeLeadFromActiveLists(id);
      notifyListeners();
    } catch (e) {
      print(
        'LeadScreenController: Error updating Booking Confirmation lead: $e',
      );
      rethrow;
    }
  }
}
