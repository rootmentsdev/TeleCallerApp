import 'package:flutter/material.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/utils/store_location.dart';

/// Controller for Followup Screen
class FollowupController extends ChangeNotifier {
  final LeadRepository _repository = LeadRepository();
  String? _selectedStore;
  String? _selectedCategory;
  int _selectedTabIndex = 0; // 0: Today, 1: Upcoming, 2: Overdue

  // Getters
  String? get selectedStore => _selectedStore;
  String? get selectedCategory => _selectedCategory;
  int get selectedTabIndex => _selectedTabIndex;

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

  // Get follow-up leads based on selected tab
  List<LeadModel> getCurrentLeads() {
    List<LeadModel> currentLeads;
    switch (_selectedTabIndex) {
      case 0:
        currentLeads = _repository.todayFollowUps;
        break;
      case 1:
        currentLeads = _repository.upcomingFollowUps;
        break;
      case 2:
        currentLeads = _repository.overdueFollowUps;
        break;
      default:
        currentLeads = _repository.todayFollowUps;
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

  // Get overdue count for badge
  int get overdueCount => _repository.overdueFollowUps.length;

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
  }
}
