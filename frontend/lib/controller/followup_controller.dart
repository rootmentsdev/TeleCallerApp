import 'package:flutter/material.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/utils/store_location.dart';

/// Controller for Followup Screen
class FollowupController extends ChangeNotifier {
  final LeadRepository _repository = LeadRepository();
  HeaderController? _headerController;
  String? _selectedStore;
  String? _selectedCategory;
  int _selectedTabIndex = 0; // 0: Today, 1: Upcoming, 2: Overdue
  bool _isLoading = false;
  String? _error;

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
  String? get selectedStore => _selectedStore;
  String? get selectedCategory => _selectedCategory;
  int get selectedTabIndex => _selectedTabIndex;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Setters
  void setSelectedStore(String? store) {
    _selectedStore = store;
    notifyListeners();
  }

  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSelectedTabIndex(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  // Get follow-up leads based on selected tab and date filter
  List<LeadModel> getCurrentLeads() {
    final selectedDate = _headerController?.selectedDate ?? DateTime.now();

    // Get all leads with follow-up dates
    final allFollowUpLeads = _repository.followUpLeads;

    List<LeadModel> currentLeads = [];

    // Filter by follow-up date relative to selected date
    switch (_selectedTabIndex) {
      case 0:
        // Today: follow-up date equals selected date
        currentLeads =
            allFollowUpLeads.where((lead) {
              if (lead.followUpDate == null) return false;
              final followUpDate = DateTime(
                lead.followUpDate!.year,
                lead.followUpDate!.month,
                lead.followUpDate!.day,
              );
              final today = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
              );
              return followUpDate.isAtSameMomentAs(today);
            }).toList();
        break;
      case 1:
        // Upcoming: follow-up date is after selected date
        currentLeads =
            allFollowUpLeads.where((lead) {
              if (lead.followUpDate == null) return false;
              final followUpDate = DateTime(
                lead.followUpDate!.year,
                lead.followUpDate!.month,
                lead.followUpDate!.day,
              );
              final today = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
              );
              return followUpDate.isAfter(today);
            }).toList();
        break;
      case 2:
        // Overdue: follow-up date is before selected date
        currentLeads =
            allFollowUpLeads.where((lead) {
              if (lead.followUpDate == null) return false;
              final followUpDate = DateTime(
                lead.followUpDate!.year,
                lead.followUpDate!.month,
                lead.followUpDate!.day,
              );
              final today = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
              );
              return followUpDate.isBefore(today);
            }).toList();
        break;
      default:
        currentLeads = allFollowUpLeads;
    }

    // Filter by category if selected
    if (_selectedCategory != null && _selectedCategory != "All") {
      currentLeads =
          currentLeads
              .where((lead) => lead.category == _selectedCategory)
              .toList();
    }

    // Filter by store if selected - extract location from "Brand - Location" format
    if (_selectedStore != null && _selectedStore != 'All Stores') {
      final location = StoreLocations.resolveSelection(_selectedStore).location;
      currentLeads =
          currentLeads.where((lead) => lead.location == location).toList();
    }

    return currentLeads;
  }

  // Get overdue count for badge based on selected date
  int get overdueCount {
    final selectedDate = _headerController?.selectedDate ?? DateTime.now();
    final allFollowUpLeads = _repository.followUpLeads;

    return allFollowUpLeads.where((lead) {
      if (lead.followUpDate == null) return false;
      final followUpDate = DateTime(
        lead.followUpDate!.year,
        lead.followUpDate!.month,
        lead.followUpDate!.day,
      );
      final today = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      return followUpDate.isBefore(today);
    }).length;
  }

  // Convert LeadModel to display format
  Map<String, dynamic> leadToDisplayMap(LeadModel lead) {
    final categoryStyle = _getCategoryStyle(lead.category);
    return {
      "name": lead.name,
      "phone": lead.phone,
      "tag": categoryStyle["tag"],
      "tagColor": categoryStyle["tagColor"],
      "tagBgColor": categoryStyle["tagBgColor"],
      "icon": categoryStyle["icon"],
      "iconColor": categoryStyle["iconColor"],
      "iconBgColor": categoryStyle["iconBgColor"],
      "borderColor": categoryStyle["borderColor"],
      "reason": lead.reason ?? "No reason provided.",
    };
  }

  Map<String, dynamic> _getCategoryStyle(String? category) {
    switch (category) {
      case "Loss of Sales":
        return {
          "tag": "Loss of Sale",
          "tagColor": const Color(0xFFE23434),
          "tagBgColor": const Color(0xFFFFE8E8),
          "icon": Icons.trending_down,
          "iconColor": const Color(0xFFE23434),
          "iconBgColor": const Color(0xFFFFE8E8),
          "borderColor": const Color(0xFFE23434),
        };
      case "Rent out":
        return {
          "tag": "Rent Out",
          "tagColor": const Color(0xFFFFCC00),
          "tagBgColor": const Color(0xFFFFF7CC),
          "icon": Icons.message_outlined,
          "iconColor": const Color(0xFFFFCC00),
          "iconBgColor": const Color(0xFFFFF7CC),
          "borderColor": const Color(0xFFFFCC00),
        };
      case "Booking confirmation":
        return {
          "tag": "Booking Confirmation",
          "tagColor": const Color(0xff56BE6B),
          "tagBgColor": const Color(0xFFD4F5DA),
          "icon": Icons.flag_outlined,
          "iconColor": const Color(0xff56BE6B),
          "iconBgColor": const Color(0xFFD4F5DA),
          "borderColor": const Color(0xff56BE6B),
        };
      case "Feedback":
        return {
          "tag": "Feedback",
          "tagColor": const Color(0xFFFFCC00),
          "tagBgColor": const Color(0xFFFFF7CC),
          "icon": Icons.message_outlined,
          "iconColor": const Color(0xFFFFCC00),
          "iconBgColor": const Color(0xFFFFF7CC),
          "borderColor": const Color(0xFFFFCC00),
        };
      default:
        return {
          "tag": category ?? "Follow Up",
          "tagColor": const Color(0xFF7C5DFF),
          "tagBgColor": const Color(0xFFE8E3FF),
          "icon": Icons.phone_outlined,
          "iconColor": const Color(0xFF7C5DFF),
          "iconBgColor": const Color(0xFFE8E3FF),
          "borderColor": const Color(0xFF7C5DFF),
        };
    }
  }

  void refresh() {
    notifyListeners();
    _repository.addListener(notifyListeners);
  }

  /// Fetch all follow-up leads from API
  /// This should be called when the follow-up screen is first loaded
  Future<void> fetchFollowUpLeads() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Fetch follow-up leads from API
      await _repository.fetchFollowUpLeadsFromApi();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update Follow-Up lead via API
  Future<void> updateFollowUpLead({
    required String id,
    String? callStatus,
    String? leadStatus,
    String? remarks,
    int? callDuration,
    int? rating,
  }) async {
    try {
      print('[FollowupController] updateFollowUpLead called');
      print('[FollowupController] ID: $id');
      print('[FollowupController] callStatus: $callStatus');
      print('[FollowupController] leadStatus: $leadStatus');
      print('[FollowupController] callDuration: $callDuration');
      print('[FollowupController] remarks: $remarks');
      print('[FollowupController] rating: $rating');

      await _repository.updateFollowUpLeadFromApi(
        id: id,
        callStatus: callStatus,
        leadStatus: leadStatus,
        remarks: remarks,
        callDuration: callDuration,
        rating: rating,
      );

      print('[FollowupController] updateFollowUpLeadFromApi completed');
      notifyListeners();
    } catch (e) {
      print('[FollowupController] Error in updateFollowUpLead: $e');
      rethrow;
    }
  }
}
