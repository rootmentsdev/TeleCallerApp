import 'package:flutter/material.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/utils/lead_constants.dart';
import 'package:telecaller_app/utils/store_location.dart';

/// Controller for Report Screen
class ReportController extends ChangeNotifier {
  final LeadRepository _repository = LeadRepository();
  HeaderController? _headerController;
  int _selectedCallTypeIndex = 0; // 0: All Calls, 1: Loss of Sale, etc.

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
      setSelectedCallTypeIndex(4); // Equary Calls tab
    }
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
  // Only count leads that have been called (completed calls)
  List<Map<String, dynamic>> getCallSummary() {
    final store = _headerController?.selectedStore;
    final date = _headerController?.selectedDate ?? DateTime.now();

    // Handle "All Stores" case
    final storeFilter = (store == null || store == 'All Stores') ? null : store;

    // Helper function to count called leads
    int getCalledLeadsCount({String? category}) {
      List<dynamic> leads =
          category != null
              ? _repository.getLeadsByCategory(category).cast<dynamic>()
              : _repository.allLeads.cast<dynamic>();

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
        "title": "Rent-Out Calls",
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
        "title": "Just Dial\nEnquiry",
        "count":
            getCalledLeadsCount(
              category: LeadConstants.categoryJustDial,
            ).toString(),
        "bgColor": const Color(0xFFFFE8D5),
        "iconColor": const Color(0xFFF37927),
        "icon": Icons.headset_mic_outlined,
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
  // Only show leads that have been called (completed calls)
  List<Map<String, dynamic>> getFilteredLeads() {
    final store = _headerController?.selectedStore;
    final date = _headerController?.selectedDate ?? DateTime.now();

    // Handle "All Stores" case
    final storeFilter = (store == null || store == 'All Stores') ? null : store;

    String? category;
    switch (_selectedCallTypeIndex) {
      case 0:
        category = null; // All Calls
        break;
      case 1:
        category = LeadConstants.categoryLossOfSales;
        break;
      case 2:
        category = LeadConstants.categoryRentOut;
        break;
      case 3:
        category = LeadConstants.categoryJustDial;
        break;
      case 4:
        // Equary Calls (Enquiry) - Show all called leads that are general enquiries
        // This includes leads with no category or category not matching specific types
        category = null; // Will filter differently for Equary Calls
        break;
      case 5:
        category = LeadConstants.categoryFollowUp;
        break;
    }

    List<dynamic> filteredLeads;

    // Special handling for Equary Calls (index 4) - show all called leads
    // that are not in specific categories (Loss of Sales, Rent out, Just Dial, Booking confirmation, Follow Up)
    if (_selectedCallTypeIndex == 4) {
      // Get all leads and filter out specific categories
      filteredLeads = _repository.allLeads.cast<dynamic>();
      filteredLeads =
          filteredLeads.where((lead) {
            final leadCategory = lead.category;
            // Exclude leads with specific categories
            return leadCategory == null ||
                (leadCategory != LeadConstants.categoryLossOfSales &&
                    leadCategory != LeadConstants.categoryRentOut &&
                    leadCategory != LeadConstants.categoryJustDial &&
                    leadCategory != LeadConstants.categoryBookingConfirmation &&
                    leadCategory != LeadConstants.categoryFollowUp);
          }).toList();
    } else {
      // For other tabs, filter by category as before
      filteredLeads = _repository.getLeadsByCategory(category).cast<dynamic>();
    }

    // Filter by store - extract location from "Brand - Location" format
    if (storeFilter != null) {
      final location = StoreLocations.resolveSelection(storeFilter).location;
      filteredLeads =
          filteredLeads.where((lead) => lead.location == location).toList();
    }

    // Filter by date (for Equary Calls, show all called leads regardless of creation date)
    if (_selectedCallTypeIndex != 4) {
      // For other tabs, filter by creation date
      filteredLeads =
          filteredLeads.where((lead) {
            final leadDate = lead.createdAt;
            return leadDate.year == date.year &&
                leadDate.month == date.month &&
                leadDate.day == date.day;
          }).toList();
    }
    // For Equary Calls (index 4), don't filter by date - show all called leads

    // Filter to only show leads that have been called (exclude uncalled leads)
    filteredLeads =
        filteredLeads.where((lead) {
          final callStatus = lead.callStatus;
          // Show leads that have been called
          return LeadConstants.isCalledStatus(callStatus);
        }).toList();

    return filteredLeads.map((lead) {
      return {
        "id": lead.id,
        "name": lead.name,
        "phone": lead.phone,
        "date": _formatDate(lead.createdAt),
        "callDate": _formatDate(lead.createdAt),
        "enquiryDate": _formatDate(lead.createdAt),
        "visitDate": _formatDate(lead.createdAt),
        "functionDate":
            lead.followUpDate != null
                ? _formatDate(lead.followUpDate!)
                : "Not available",
        "storeName": lead.location ?? "Not available",
        "type": _getTypeFromCategory(lead.category),
        "callStatus": lead.callStatus,
        "leadStatus": lead.leadStatus,
        "reason": lead.reason,
        "reasonFromStore": lead.reason,
        "attendedBy": "Krishna - ${lead.location ?? 'Zorucci Edappally'}",
        "followUpDate": lead.followUpDate?.toIso8601String(),
        "callDuration": lead.callDuration,
        "remarks": "",
      };
    }).toList();
  }

  String getCurrentTitle() {
    switch (_selectedCallTypeIndex) {
      case 0:
        return "All calls";
      case 1:
        return "Loss of sale calls";
      case 2:
        return "Rent-Out calls";
      case 3:
        return "Just Dial Enquiries";
      case 4:
        return "Equary Calls";
      default:
        return "All calls";
    }
  }

  String _getTypeFromCategory(String? category) {
    switch (category) {
      case LeadConstants.categoryLossOfSales:
        return "loss";
      case LeadConstants.categoryRentOut:
        return "hardout";
      case LeadConstants.categoryBookingConfirmation:
        return "booking";
      case LeadConstants.categoryJustDial:
        return "justdial";
      default:
        return "all";
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
}
