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
    notifyListeners();

    final store = _headerController?.selectedStore;
    final storeParam = (store == null || store == 'All Stores') ? null : store;

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

    _fetchLeadsForCurrentFilters(storeParam, dateFrom, dateTo, singleDate);
  }

  void _fetchLeadsForCurrentFilters(
    String? store,
    String? dateFrom,
    String? dateTo,
    DateTime? singleDate,
  ) {
    if (store != null) {
      if (dateFrom != null && dateTo != null) {
        fetchAllLeadsFromApi(
          store: store,
          dateFrom: dateFrom,
          dateTo: dateTo,
          dateField: 'createdAt',
        ).catchError((_) {});
      } else {
        fetchAllLeadsFromApi(store: store, date: singleDate).catchError((_) {});
      }

      fetchLossOfSaleLeadsFromApi(store: store).catchError((_) {});
      fetchReturnLeadsFromApi(store: store).catchError((_) {});
      fetchBookingConfirmationLeadsFromApi(store: store).catchError((_) {});
    } else {
      if (dateFrom != null && dateTo != null) {
        fetchAllLeadsFromApi(
          dateFrom: dateFrom,
          dateTo: dateTo,
          dateField: 'createdAt',
        ).catchError((_) {});
      } else {
        fetchAllLeadsFromApi(date: singleDate).catchError((_) {});
      }

      fetchLossOfSaleLeadsFromApi().catchError((_) {});
      fetchReturnLeadsFromApi().catchError((_) {});
      fetchBookingConfirmationLeadsFromApi().catchError((_) {});
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

  List<Map<String, dynamic>> getCallSummary() {
    int getUncalledLeadsCount({String? category}) {
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

      List<LeadModel> leads = _repository.allLeads;

      if (dateStart != null && dateEnd != null) {
        final start = dateStart;
        final end = dateEnd;
        leads =
            leads.where((lead) {
              final leadDate = lead.createdAt;
              final normalizedLeadDate = DateTime.utc(
                leadDate.year,
                leadDate.month,
                leadDate.day,
              );
              final normalizedStart = DateTime.utc(
                start.year,
                start.month,
                start.day,
              );
              final normalizedEnd = DateTime.utc(end.year, end.month, end.day);
              return normalizedLeadDate.compareTo(normalizedStart) >= 0 &&
                  normalizedLeadDate.compareTo(normalizedEnd) <= 0;
            }).toList();
      } else if (date != null) {
        final selectedDate = date;
        leads =
            leads.where((lead) {
              final leadDate = lead.createdAt;
              return leadDate.year == selectedDate.year &&
                  leadDate.month == selectedDate.month &&
                  leadDate.day == selectedDate.day;
            }).toList();
      }

      if (category != null) {
        leads = leads.where((lead) => lead.category == category).toList();
      }

      final storeFilter = _headerController?.selectedStore;
      if (storeFilter != null && storeFilter != "All Stores") {
        leads =
            leads
                .where((lead) => _repository.matchesStore(lead, storeFilter))
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

      List<LeadModel> leads = _repository.allLeads;

      if (dateStart != null && dateEnd != null) {
        final start = dateStart;
        final end = dateEnd;
        leads =
            leads.where((lead) {
              final leadDate = lead.createdAt;
              final normalizedLeadDate = DateTime.utc(
                leadDate.year,
                leadDate.month,
                leadDate.day,
              );
              final normalizedStart = DateTime.utc(
                start.year,
                start.month,
                start.day,
              );
              final normalizedEnd = DateTime.utc(end.year, end.month, end.day);
              return normalizedLeadDate.compareTo(normalizedStart) >= 0 &&
                  normalizedLeadDate.compareTo(normalizedEnd) <= 0;
            }).toList();
      } else if (date != null) {
        final selectedDate = date;
        leads =
            leads.where((lead) {
              final leadDate = lead.createdAt;
              return leadDate.year == selectedDate.year &&
                  leadDate.month == selectedDate.month &&
                  leadDate.day == selectedDate.day;
            }).toList();
      }

      final storeFilter = _headerController?.selectedStore;
      if (storeFilter != null && storeFilter != "All Stores") {
        leads =
            leads
                .where((lead) => _repository.matchesStore(lead, storeFilter))
                .toList();
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
      {
        "title": "Starred",
        "count": getStarredLeadsCount().toString(),
        "bgColor": const Color(0xFFFFF4E6),
        "iconColor": const Color(0xFFFFB800),
        "icon": Icons.star,
        "isStarred": true,
      },
    ];
  }

  List<LeadDisplayModel> getFilteredLeads() {
    String? category = _getCategoryForIndex(_selectedCallTypeIndex);
    final store = _headerController?.selectedStore;

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

    List<LeadModel> filteredLeads;
    if (dateStart != null && dateEnd != null) {
      filteredLeads = _repository.getLeadsByDateRange(dateStart, dateEnd);
      if (category != null) {
        filteredLeads =
            filteredLeads.where((lead) => lead.category == category).toList();
      }
    } else {
      filteredLeads = _repository.getLeadsByCategory(category, date: date);
    }

    if (store != null && store != 'All Stores') {
      filteredLeads =
          filteredLeads
              .where((lead) => _repository.matchesStore(lead, store))
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
          if (_focusedNewLeadId == matches.first.id) {
            clearShowOnlyNewLead();
          }
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
        return "Return Calls";
      case 3:
        return "Booking Confirmation";
      default:
        return "All Calls";
    }
  }

  int getFollowUpLeadsCount() {
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

    List<LeadModel> leads;
    if (dateStart != null && dateEnd != null) {
      leads = _repository.getLeadsByDateRange(dateStart, dateEnd);
    } else {
      leads = _repository.getLeadsByDate(date!);
    }

    final store = _headerController?.selectedStore;
    if (store != null && store != 'All Stores') {
      leads =
          leads.where((lead) => _repository.matchesStore(lead, store)).toList();
    }

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

  Future<void> fetchLossOfSaleLeadsFromApi({String? store}) async {
    try {
      await _repository.fetchLossOfSaleLeadsFromApi(store: store);
      notifyListeners();
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'fetchLossOfSaleLeadsFromApi failed',
      );
      rethrow;
    }
  }

  Future<void> fetchBookingConfirmationLeadsFromApi({String? store}) async {
    try {
      await _repository.fetchBookingConfirmationLeadsFromApi(store: store);
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

  Future<void> fetchReturnLeadsFromApi({String? store}) async {
    try {
      await _repository.fetchReturnLeadsFromApi(store: store);
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
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'updateLossOfSaleLead failed',
      );
      rethrow;
    }
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
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'updateReturnLead failed',
      );
      rethrow;
    }
  }

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
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'updateBookingConfirmationLead failed',
      );
      rethrow;
    }
  }
}
