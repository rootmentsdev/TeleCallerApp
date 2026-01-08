import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/model/lead_display_model.dart';
import 'package:telecaller_app/utils/lead_constants.dart';

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
    // When header (store/date) changes, refresh data from API for current filters
    notifyListeners();

    // Get current store and date filters
    final store = _headerController?.selectedStore;
    final storeParam = (store == null || store == 'All Stores') ? null : store;
    
    // Use date range if available, otherwise use single date
    String? dateFrom;
    String? dateTo;
    DateTime? singleDate;
    
    if (_headerController?.isRangeMode == true &&
        _headerController?.dateRangeStart != null &&
        _headerController?.dateRangeEnd != null) {
      dateFrom = _formatDateForApi(_headerController!.dateRangeStart!);
      dateTo = _formatDateForApi(_headerController!.dateRangeEnd!);
    } else {
      singleDate = _headerController?.selectedDate ?? DateTime.now();
    }

    // Fetch all lead types with store and date filters when header changes
    // This ensures all tabs show filtered data
    if (storeParam != null) {
      // Fetch all leads (for "All Calls" tab)
      // GET /api/pages/leads?store=Suitor Guy - Edappally&enquiryDateFrom=2024-12-08&enquiryDateTo=2024-12-08
      if (dateFrom != null && dateTo != null) {
        fetchAllLeadsFromApi(
          store: storeParam,
          dateFrom: dateFrom,
          dateTo: dateTo,
          dateField: 'createdAt',
        ).catchError((e) {
          print(
            'LeadScreenController: Error fetching all leads on header change: $e',
          );
        });
      } else {
        fetchAllLeadsFromApi(store: storeParam, date: singleDate).catchError((
          e,
        ) {
          print(
            'LeadScreenController: Error fetching all leads on header change: $e',
          );
        });
      }

      // Fetch Loss of Sale leads with store filter
      // GET /api/pages/leads?leadType=lossOfSale&store=Suitor Guy - Edappally
      fetchLossOfSaleLeadsFromApi(store: storeParam).catchError((e) {
        print(
          'LeadScreenController: Error fetching Loss of Sale leads on header change: $e',
        );
      });

      // Fetch Return leads with store filter
      // GET /api/pages/leads?leadType=return&store=Suitor Guy - Edappally
      fetchReturnLeadsFromApi(store: storeParam).catchError((e) {
        print(
          'LeadScreenController: Error fetching Return leads on header change: $e',
        );
      });

      // Fetch Booking Confirmation leads with store filter
      // GET /api/pages/leads?leadType=bookingConfirmation&store=Suitor Guy - Edappally
      fetchBookingConfirmationLeadsFromApi(store: storeParam).catchError((e) {
        print(
          'LeadScreenController: Error fetching Booking Confirmation leads on header change: $e',
        );
      });
    } else {
      // If "All Stores" is selected, fetch without store filter but with date filter
      if (dateFrom != null && dateTo != null) {
        print(
          'LeadScreenController: Fetching leads for "All Stores" with date range: $dateFrom to $dateTo',
        );
        fetchAllLeadsFromApi(
          dateFrom: dateFrom,
          dateTo: dateTo,
          dateField: 'createdAt',
        ).catchError((e) {
          print(
            'LeadScreenController: Error fetching all leads (no store filter): $e',
          );
        });
      } else {
        print(
          'LeadScreenController: Fetching leads for "All Stores" with date: ${_formatDateForApi(singleDate!)}',
        );
        fetchAllLeadsFromApi(date: singleDate).catchError((e) {
          print(
            'LeadScreenController: Error fetching all leads (no store filter): $e',
          );
        });
      }
      // Note: Category-specific API calls don't support date filters,
      // so they will fetch leads from all dates. The date filtering
      // is handled locally in getUncalledLeadsCount() and getFilteredLeads()
      fetchLossOfSaleLeadsFromApi().catchError((e) {
        print(
          'LeadScreenController: Error fetching Loss of Sale leads (no store filter): $e',
        );
      });
      fetchReturnLeadsFromApi().catchError((e) {
        print(
          'LeadScreenController: Error fetching Return leads (no store filter): $e',
        );
      });
      fetchBookingConfirmationLeadsFromApi().catchError((e) {
        print(
          'LeadScreenController: Error fetching Booking Confirmation leads (no store filter): $e',
        );
      });
    }
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
    // NOTE: allLeads returns an unmodifiable list, so we can't remove from it directly
    // The updateLead method in repository already handles removal if lead is no longer uncalled
    // This method is kept for backward compatibility but does nothing
    // The actual removal is handled by LeadRepository.updateLead() which checks if lead should be moved to reports
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

  // Get call summary data (filtered by store and date)
  // Only count leads that haven't been called yet
  List<Map<String, dynamic>> getCallSummary() {
    // Note: store and date filters are handled in getUncalledLeadsCount

    // Helper function to count uncalled leads
    // int getUncalledLeadsCount({String? category}) {
    //   List<LeadModel> leads =
    //       category != null
    //           ? _repository.getLeadsByCategory(category)
    //           : _repository.allLeads;

    //   // Filter by store - extract location from "Brand - Location" format
    //   if (storeFilter != null) {
    //     final location = StoreLocations.resolveSelection(storeFilter).location;
    //     leads = leads.where((lead) => lead.location == location).toList();
    //   }

    //   // Filter by date - but for Loss of Sale, count all leads (date filter is handled by API)
    //   // For other categories, filter by selected date
    //   if (category != LeadConstants.categoryLossOfSales) {
    //     leads =
    //         leads.where((lead) {
    //           final leadDate = lead.createdAt;
    //           return leadDate.year == date.year &&
    //               leadDate.month == date.month &&
    //               leadDate.day == date.day;
    //         }).toList();
    //   }

    //   // Filter out leads that have been called
    //   leads =
    //       leads
    //           .where((lead) => LeadConstants.isUncalledStatus(lead.callStatus))
    //           .toList();

    //   return leads.length;
    // }
    int getUncalledLeadsCount({String? category}) {
      // Use date range if available, otherwise use single date
      DateTime? date;
      DateTime? dateStart;
      DateTime? dateEnd;
      
      if (_headerController?.isRangeMode == true &&
          _headerController?.dateRangeStart != null &&
          _headerController?.dateRangeEnd != null) {
        dateStart = _headerController!.dateRangeStart;
        dateEnd = _headerController!.dateRangeEnd;
      } else {
        date = _headerController?.selectedDate ?? DateTime.now();
      }

      // STEP 1: Get ALL leads first (don't filter by category/date yet)
      // This ensures we have the full dataset before filtering
      List<LeadModel> allLeads = _repository.allLeads;

      // STEP 2: Filter by date FIRST (critical for "All Stores" with date filter)
      List<LeadModel> leads;
      if (dateStart != null && dateEnd != null) {
        // Filter by date range
        final start = dateStart!;
        final end = dateEnd!;
        leads = allLeads.where((lead) {
          final leadDate = lead.createdAt;
          final normalizedLeadDate = DateTime.utc(leadDate.year, leadDate.month, leadDate.day);
          final normalizedStart = DateTime.utc(start.year, start.month, start.day);
          final normalizedEnd = DateTime.utc(end.year, end.month, end.day);
          return normalizedLeadDate.compareTo(normalizedStart) >= 0 && 
                 normalizedLeadDate.compareTo(normalizedEnd) <= 0;
        }).toList();
      } else if (date != null) {
        // Filter by single date
        final selectedDate = date;
        leads = allLeads.where((lead) {
          final leadDate = lead.createdAt;
          return leadDate.year == selectedDate.year &&
              leadDate.month == selectedDate.month &&
              leadDate.day == selectedDate.day;
        }).toList();
      } else {
        leads = allLeads;
      }

      // STEP 3: Filter by category if specified
      if (category != null) {
        leads = leads.where((lead) => lead.category == category).toList();
      }

      // STEP 4: Filter by store using shared helper from repository
      final storeFilter = _headerController?.selectedStore;
      if (storeFilter != null && storeFilter != "All Stores") {
        leads =
            leads
                .where((lead) => _repository.matchesStore(lead, storeFilter))
                .toList();
      }

      // STEP 5: count only uncalled
      leads =
          leads
              .where((lead) => LeadConstants.isUncalledStatus(lead.callStatus))
              .toList();

      // STEP 5: exclude leads with follow-up dates (they appear in Follow-up Screen)
      leads = leads.where((lead) => lead.followUpDate == null).toList();

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
        "title": "Return Calls",
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
        "icon": Icons.flag_outlined,
      },
    ];
  }

  // Get filtered leads based on selected call type
  // For "All Calls" tab (index 0), show all leads regardless of call status
  // For other tabs, only show leads that haven't been called yet
  List<LeadDisplayModel> getFilteredLeads() {
    String? category = _getCategoryForIndex(_selectedCallTypeIndex);

    final store = _headerController?.selectedStore;
    
    // Use date range if available, otherwise use single date
    DateTime? date;
    DateTime? dateStart;
    DateTime? dateEnd;
    
    if (_headerController?.isRangeMode == true &&
        _headerController?.dateRangeStart != null &&
        _headerController?.dateRangeEnd != null) {
      dateStart = _headerController!.dateRangeStart;
      dateEnd = _headerController!.dateRangeEnd;
    } else {
      date = _headerController?.selectedDate ?? DateTime.now();
    }

    // Get leads filtered by category, store, and date
    List<LeadModel> filteredLeads = _repository.getLeadsByCategory(
      category,
      date: date,
      dateStart: dateStart,
      dateEnd: dateEnd,
    );

    // Debug: Print initial lead count
    print(
      'LeadScreenController: getFilteredLeads - Initial leads count: ${filteredLeads.length}, category: $category, store: $store',
    );

    // Filter by store using shared helper from repository
    if (store != null && store != 'All Stores') {
      filteredLeads =
          filteredLeads
              .where((lead) => _repository.matchesStore(lead, store))
              .toList();

      // Debug: Print after store filter
      print(
        'LeadScreenController: After store filter: ${filteredLeads.length} leads',
      );
    }

    // Filter by date - but for All Calls, Loss of Sale, Return, and Booking Confirmation, show all leads (date filter is handled by API)
    // For other categories, filter by selected date or date range
    if (_selectedCallTypeIndex != 0 &&
        _selectedCallTypeIndex != 1 &&
        _selectedCallTypeIndex != 2 &&
        _selectedCallTypeIndex != 3) {
      if (dateStart != null && dateEnd != null) {
        // Filter by date range
        final start = dateStart!;
        final end = dateEnd!;
        filteredLeads = filteredLeads.where((lead) {
          final leadDate = lead.createdAt;
          final normalizedLeadDate = DateTime.utc(leadDate.year, leadDate.month, leadDate.day);
          final normalizedStart = DateTime.utc(start.year, start.month, start.day);
          final normalizedEnd = DateTime.utc(end.year, end.month, end.day);
          return normalizedLeadDate.compareTo(normalizedStart) >= 0 && 
                 normalizedLeadDate.compareTo(normalizedEnd) <= 0;
        }).toList();
      } else if (date != null) {
        // Filter by single date
        final selectedDate = date;
        filteredLeads =
            filteredLeads.where((lead) {
              final leadDate = lead.createdAt;
              return leadDate.year == selectedDate.year &&
                  leadDate.month == selectedDate.month &&
                  leadDate.day == selectedDate.day;
            }).toList();
      }
    }

    // Filter out leads that have been called (only show uncalled leads)
    // EXCEPT for "All Calls" tab (index 0) which should show all leads
    if (_selectedCallTypeIndex != 0) {
      final beforeCallStatusFilter = filteredLeads.length;
      filteredLeads =
          filteredLeads
              .where((lead) => LeadConstants.isUncalledStatus(lead.callStatus))
              .toList();
      print(
        'LeadScreenController: After call status filter: ${filteredLeads.length} leads (was $beforeCallStatusFilter)',
      );
    }

    // Filter by follow-up status - exclude leads with follow-up dates from all tabs
    // (Follow-up leads are managed in the separate FollowUp screen)
    final beforeFollowUpFilter = filteredLeads.length;
    filteredLeads =
        filteredLeads.where((lead) => lead.followUpDate == null).toList();
    print(
      'LeadScreenController: After follow-up filter: ${filteredLeads.length} leads (was $beforeFollowUpFilter, removed ${beforeFollowUpFilter - filteredLeads.length} follow-up leads)',
    );

    // Debug: Print final count
    print(
      'LeadScreenController: Final filtered leads count: ${filteredLeads.length}',
    );

    // Convert to display models
    // If we're showing only the newly added lead, return only that one (if present)
    // But only for "All Calls" tab - other tabs should show all leads
    if (_showOnlyNewLead &&
        _focusedNewLeadId != null &&
        _selectedCallTypeIndex == 0) {
      final matches =
          filteredLeads.where((l) => l.id == _focusedNewLeadId).toList();
      if (matches.isNotEmpty) {
        // Auto-clear after showing once
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_focusedNewLeadId == matches.first.id) {
            clearShowOnlyNewLead();
          }
        });
        return [LeadDisplayModel.fromLead(matches.first)];
      }
      // If not found in filtered list, clear the flag and show all leads
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
        return "Return Calls";
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

    // Filter by store if specified using shared helper
    if (store != null && store != 'All Stores') {
      leads =
          leads.where((lead) => _repository.matchesStore(lead, store)).toList();
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
    } catch (e, s) {
      print('LeadScreenController: Error fetching Loss of Sale leads: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'fetchLossOfSaleLeadsFromApi failed',
      );
      rethrow;
    }
  }

  /// Fetch Booking Confirmation leads from API
  Future<void> fetchBookingConfirmationLeadsFromApi({String? store}) async {
    try {
      await _repository.fetchBookingConfirmationLeadsFromApi(store: store);
      notifyListeners();
    } catch (e, s) {
      print(
        'LeadScreenController: Error fetching Booking Confirmation leads: $e',
      );
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'fetchBookingConfirmationLeadsFromApi failed',
      );
      rethrow;
    }
  }

  /// Fetch Return leads from API
  Future<void> fetchReturnLeadsFromApi({String? store}) async {
    try {
      await _repository.fetchReturnLeadsFromApi(store: store);
      notifyListeners();
    } catch (e, s) {
      print('LeadScreenController: Error fetching Return leads: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'fetchReturnLeadsFromApi failed',
      );
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
    } catch (e, s) {
      print('LeadScreenController: Error fetching all leads: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'fetchAllLeadsFromApi failed',
      );
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
  }) async {
    try {
      await _repository.updateLossOfSaleLeadFromApi(
        id: id,
        callStatus: callStatus,
        leadStatus: leadStatus,
        followUpDate: followUpDate,
        reasonCollectedFromStore: reasonCollectedFromStore,
        remarks: remarks,
      );

      _removeLeadFromActiveLists(id);

      notifyListeners();
    } catch (e, s) {
      print('LeadScreenController: Error updating Loss of Sale lead: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'updateLossOfSaleLead failed',
      );
      rethrow;
    }
  }

  /// Update Return lead via API
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
      );
      _removeLeadFromActiveLists(id);
      notifyListeners();
    } catch (e, s) {
      print('LeadScreenController: Error updating Return lead: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'updateReturnLead failed',
      );
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
    } catch (e, s) {
      print(
        'LeadScreenController: Error updating Booking Confirmation lead: $e',
      );
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'updateBookingConfirmationLead failed',
      );
      rethrow;
    }
  }
}
