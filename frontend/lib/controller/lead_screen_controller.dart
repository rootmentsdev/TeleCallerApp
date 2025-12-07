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

  // ------------------------------------------------------------
  // INITIALIZATION & DISPOSAL
  // ------------------------------------------------------------

  void init(HeaderController headerController) {
    if (_headerController != headerController) {
      _headerController?.removeListener(_onHeaderChanged);
      _headerController = headerController;
      _headerController?.addListener(_onHeaderChanged);
    }
  }

  void _onHeaderChanged() => notifyListeners();

  @override
  void dispose() {
    _headerController?.removeListener(_onHeaderChanged);
    super.dispose();
  }

  // ------------------------------------------------------------
  // GETTERS
  // ------------------------------------------------------------

  DateTime get selectedDate =>
      _headerController?.selectedDate ?? DateTime.now();

  String? get selectedStore => _headerController?.selectedStore;

  int get selectedCallTypeIndex => _selectedCallTypeIndex;

  // ------------------------------------------------------------
  // SETTERS
  // ------------------------------------------------------------

  void setSelectedCallTypeIndex(int index) {
    _selectedCallTypeIndex = index;
    notifyListeners();
  }

  // ------------------------------------------------------------
  // SUMMARY COUNTS (STORE + UNCALLED)
  // ------------------------------------------------------------

  /// Counts uncalled leads in a category (or all)
  int _countUncalledLeads({String? category}) {
    List<LeadModel> leads =
        category != null
            ? _repository.getLeadsByCategory(category)
            : _repository.allLeads;

    final storeFilter = selectedStore;

    // Filter by selected store
    if (storeFilter != null && storeFilter != "All Stores") {
      final location = StoreLocations.resolveSelection(storeFilter).location;
      leads = leads.where((lead) => lead.location == location).toList();
    }

    // Count only uncalled statuses
    return leads
        .where((lead) => LeadConstants.isUncalledStatus(lead.callStatus))
        .length;
  }

  /// Dashboard summary boxes
  List<Map<String, dynamic>> getCallSummary() {
    return [
      {
        "title": "All Calls",
        "count": _countUncalledLeads().toString(),
        "bgColor": const Color(0xFFE8E3FF),
        "iconColor": const Color(0xFF7C5DFF),
        "icon": Icons.people_alt_outlined,
      },
      {
        "title": "Loss of Sale",
        "count":
            _countUncalledLeads(
              category: LeadConstants.categoryLossOfSales,
            ).toString(),
        "bgColor": const Color(0xFFFFE8E8),
        "iconColor": const Color(0xFFE23434),
        "icon": Icons.trending_down,
      },
      {
        "title": "Rent-Out Calls",
        "count":
            _countUncalledLeads(
              category: LeadConstants.categoryRentOut,
            ).toString(),
        "bgColor": const Color(0xFFFFF7CC),
        "iconColor": const Color(0xFFFFCC00),
        "icon": Icons.message_outlined,
      },
      {
        "title": "Booking\nConfirmation",
        "count":
            _countUncalledLeads(
              category: LeadConstants.categoryBookingConfirmation,
            ).toString(),
        "bgColor": const Color(0xFFD4F5DA),
        "iconColor": const Color(0xff56BE6B),
        "icon": Icons.flag_outlined,
      },
      {
        "title": "Just Dial\nEnquiry",
        "count":
            _countUncalledLeads(
              category: LeadConstants.categoryJustDial,
            ).toString(),
        "bgColor": const Color(0xFFFFE8D5),
        "iconColor": const Color(0xFFF37927),
        "icon": Icons.headset_mic_outlined,
      },
      {
        "title": "Follow Up\nCalls",
        "count":
            _countUncalledLeads(
              category: LeadConstants.categoryFollowUp,
            ).toString(),
        "bgColor": const Color(0xFFD5E8FF),
        "iconColor": const Color(0xFF2196F3),
        "icon": Icons.event_note_outlined,
      },
    ];
  }

  // ------------------------------------------------------------
  // FILTERED LEADS FOR LIST VIEW
  // ------------------------------------------------------------

  List<LeadDisplayModel> getFilteredLeads() {
    String? category = _categoryForIndex(_selectedCallTypeIndex);

    List<LeadModel> leads = _repository.getLeadsByCategory(category);

    // Filter by store
    if (selectedStore != null && selectedStore != "All Stores") {
      final location = StoreLocations.resolveSelection(selectedStore!).location;
      leads = leads.where((lead) => lead.location == location).toList();
    }

    // Date filter only for categories other than main 4
    bool skipDateFilter = _selectedCallTypeIndex <= 3;

    if (!skipDateFilter) {
      leads =
          leads.where((lead) {
            final date = lead.createdAt;
            return date.year == selectedDate.year &&
                date.month == selectedDate.month &&
                date.day == selectedDate.day;
          }).toList();
    }

    // Only show uncalled leads except for All Calls
    if (_selectedCallTypeIndex != 0) {
      leads =
          leads
              .where((lead) => LeadConstants.isUncalledStatus(lead.callStatus))
              .toList();
    }

    return leads.map(LeadDisplayModel.fromLead).toList();
  }

  // ------------------------------------------------------------
  // TITLE FOR APP BAR
  // ------------------------------------------------------------

  String getCurrentTitle() {
    switch (_selectedCallTypeIndex) {
      case 1:
        return "Loss of Sale";
      case 2:
        return "Rent-Out Calls";
      case 3:
        return "Booking Confirmation";
      case 4:
        return "Just Dial Enquiries";
      case 5:
        return "Follow Up Calls";
      default:
        return "All Calls";
    }
  }

  // ------------------------------------------------------------
  // CATEGORY MAPPING
  // ------------------------------------------------------------

  String? _categoryForIndex(int index) {
    switch (index) {
      case 1:
        return LeadConstants.categoryLossOfSales;
      case 2:
        return LeadConstants.categoryRentOut;
      case 3:
        return LeadConstants.categoryBookingConfirmation;
      case 4:
        return LeadConstants.categoryJustDial;
      case 5:
        return LeadConstants.categoryFollowUp;
      default:
        return null; // All Calls
    }
  }

  void refresh() => notifyListeners();

  // ------------------------------------------------------------
  // API CALLS → FETCH
  // ------------------------------------------------------------

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
      print("Error fetching Loss of Sale leads: $e");
      rethrow;
    }
  }

  Future<void> fetchBookingConfirmationLeadsFromApi({String? store}) async {
    try {
      await _repository.fetchBookingConfirmationLeadsFromApi(store: store);
      notifyListeners();
    } catch (e) {
      print("Error fetching Booking Confirmation leads: $e");
      rethrow;
    }
  }

  Future<void> fetchRentOutLeadsFromApi({String? store}) async {
    try {
      await _repository.fetchRentOutLeadsFromApi(store: store);
      notifyListeners();
    } catch (e) {
      print("Error fetching Rent-Out leads: $e");
      rethrow;
    }
  }

  // ------------------------------------------------------------
  // API CALLS → UPDATE
  // ------------------------------------------------------------

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
      notifyListeners();
    } catch (e) {
      print("Error updating Loss of Sale lead: $e");
      rethrow;
    }
  }

  Future<void> updateRentOutLead({
    required String id,
    String? callStatus,
    String? leadStatus,
    bool? followUpFlag,
    DateTime? callDate,
    int? rating,
    String? remarks,
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
      );
      notifyListeners();
    } catch (e) {
      print("Error updating Rent-Out lead: $e");
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
  }) async {
    try {
      await _repository.updateBookingConfirmationLeadFromApi(
        id: id,
        callStatus: callStatus,
        leadStatus: leadStatus,
        followUpFlag: followUpFlag,
        callDate: callDate,
        remarks: remarks,
      );
      notifyListeners();
    } catch (e) {
      print("Error updating Booking Confirmation lead: $e");
      rethrow;
    }
  }
}
