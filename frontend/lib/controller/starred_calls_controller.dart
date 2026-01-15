import 'package:flutter/material.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/utils/store_location.dart';

/// Controller for Starred Calls Screen
class StarredCallsController extends ChangeNotifier {
  final LeadRepository _repository = LeadRepository();
  HeaderController? _headerController;
  String? _selectedStore;
  String? _selectedCategory;
  bool _isLoading = false;
  String? _error;

  StarredCallsController() {
    // Listen to repository changes and forward notifications so UI updates
    _repository.addListener(_onRepositoryChanged);
  }

  void _onRepositoryChanged() {
    // Forward repository changes to listeners of this controller
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
  }

  @override
  void dispose() {
    _headerController?.removeListener(_onHeaderChanged);
    _repository.removeListener(_onRepositoryChanged);
    super.dispose();
  }

  // Getters
  String? get selectedStore => _selectedStore;
  String? get selectedCategory => _selectedCategory;
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

  // Get starred calls leads
  List<LeadModel> getCurrentLeads() {
    // Get all leads from backend (already filtered to starred calls)
    final allStarredLeads = _repository.starredCallsLeads;

    List<LeadModel> currentLeads = allStarredLeads;

    print(
      'StarredCallsController: getCurrentLeads called - total starred leads available=${allStarredLeads.length}',
    );

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

    print(
      'StarredCallsController: Returning ${currentLeads.length} leads after filtering',
    );

    return currentLeads;
  }

  // Convert LeadModel to display format
  Map<String, dynamic> leadToDisplayMap(LeadModel lead) {
    final categoryStyle = _getCategoryStyle(lead.category);
    return {
      "id": lead.id,
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
      "callStatus": lead.callStatus,
      "leadStatus": lead.leadStatus,
      "category": lead.category,
      "brand": lead.brand,
      "location": lead.location,
      "callDuration": lead.callDuration,
      "callCount": lead.callCount,
      "isStarred": lead.isStarred,
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
      case "Return":
        return {
          "tag": "Return",
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
          "tag": category ?? "Marked Call",
          "tagColor": const Color(0xFFFFB800),
          "tagBgColor": const Color(0xFFFFF4E6),
          "icon": Icons.star,
          "iconColor": const Color(0xFFFFB800),
          "iconBgColor": const Color(0xFFFFF4E6),
          "borderColor": const Color(0xFFFFB800),
        };
    }
  }

  void refresh() {
    notifyListeners();
    _repository.addListener(notifyListeners);
  }

  /// Fetch starred calls from backend
  Future<void> fetchStarredCalls() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print(
        'StarredCallsController: Fetching starred calls (store=${_selectedStore ?? 'All'})',
      );
      // Fetch starred calls from backend (/api/pages/starred-calls)
      await _repository.fetchStarredCallsFromApi(store: _selectedStore);

      print(
        'StarredCallsController: Fetch completed - total starred calls in repository: ${_repository.starredCallsLeads.length}',
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('StarredCallsController: Error fetching starred calls: $e');
      notifyListeners();
    }
  }
}
