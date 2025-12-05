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
  }

  // Get call summary data (filtered by store and date)
  // Only count leads that haven't been called yet
  List<Map<String, dynamic>> getCallSummary() {
    final store = _headerController?.selectedStore;
    final date = _headerController?.selectedDate ?? DateTime.now();

    // Handle "All Stores" case
    final storeFilter = (store == null || store == 'All Stores') ? null : store;

    // Helper function to count uncalled leads
    int getUncalledLeadsCount({String? category}) {
      List<LeadModel> leads =
          category != null
              ? _repository.getLeadsByCategory(category)
              : _repository.allLeads;

      // Filter by store - extract location from "Brand - Location" format
      if (storeFilter != null) {
        final location = StoreLocations.resolveSelection(storeFilter).location;
        leads = leads.where((lead) => lead.location == location).toList();
      }

      // Filter by date - but for Loss of Sale, count all leads (date filter is handled by API)
      // For other categories, filter by selected date
      if (category != LeadConstants.categoryLossOfSales) {
        leads =
            leads.where((lead) {
              final leadDate = lead.createdAt;
              return leadDate.year == date.year &&
                  leadDate.month == date.month &&
                  leadDate.day == date.day;
            }).toList();
      }

      // Filter out leads that have been called
      leads =
          leads
              .where((lead) => LeadConstants.isUncalledStatus(lead.callStatus))
              .toList();

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
        "title": "Rent-Out Calls",
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
        "title": "Just Dial\nEnquiry",
        "count":
            getUncalledLeadsCount(
              category: LeadConstants.categoryJustDial,
            ).toString(),
        "bgColor": const Color(0xFFFFE8D5),
        "iconColor": const Color(0xFFF37927),
        "icon": Icons.headset_mic_outlined,
      },
      {
        "title": "Follow Up\nCalls",
        "count":
            getUncalledLeadsCount(
              category: LeadConstants.categoryFollowUp,
            ).toString(),
        "bgColor": const Color(0xFFD5E8FF),
        "iconColor": const Color(0xFF2196F3),
        "icon": Icons.event_note_outlined,
      },
    ];
  }

  // Get filtered leads based on selected call type
  // Only show leads that haven't been called yet
  List<LeadDisplayModel> getFilteredLeads() {
    String? category = _getCategoryForIndex(_selectedCallTypeIndex);

    final store = _headerController?.selectedStore;
    final date = _headerController?.selectedDate ?? DateTime.now();

    // Get leads filtered by category, store, and date
    List<LeadModel> filteredLeads = _repository.getLeadsByCategory(category);

    // Filter by store - extract location from "Brand - Location" format
    if (store != null && store != 'All Stores') {
      final location = StoreLocations.resolveSelection(store).location;
      filteredLeads =
          filteredLeads.where((lead) => lead.location == location).toList();
    }

    // Filter by date - but for Loss of Sale, show all leads (date filter is handled by API)
    // For other categories, filter by selected date
    if (_selectedCallTypeIndex != 1) {
      filteredLeads =
          filteredLeads.where((lead) {
            final leadDate = lead.createdAt;
            return leadDate.year == date.year &&
                leadDate.month == date.month &&
                leadDate.day == date.day;
          }).toList();
    }

    // Filter out leads that have been called (only show uncalled leads)
    filteredLeads =
        filteredLeads
            .where((lead) => LeadConstants.isUncalledStatus(lead.callStatus))
            .toList();

    // Convert to display models
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
      case 4:
        return LeadConstants.categoryJustDial;
      case 5:
        return LeadConstants.categoryFollowUp;
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
}
