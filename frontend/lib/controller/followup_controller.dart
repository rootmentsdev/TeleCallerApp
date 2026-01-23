import 'package:flutter/material.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/utils/store_location.dart';
import 'package:telecaller_app/services/notification_service.dart';

/// Controller for Followup Screen
class FollowupController extends ChangeNotifier {
  final LeadRepository _repository = LeadRepository();
  HeaderController? _headerController;
  String? _selectedStore;
  String? _selectedCategory;
  int _selectedTabIndex = 0; // 0: Today, 1: Upcoming, 2: Overdue
  bool _isLoading = false;
  String? _error;

  FollowupController() {
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
  // Backend-driven: No local filtering - backend returns only follow-up leads from /api/pages/follow-ups
  List<LeadModel> getCurrentLeads() {
    final selectedDate = _headerController?.selectedDate ?? DateTime.now();

    // Get all leads from backend (already filtered to follow-up leads)
    final allFollowUpLeads = _repository.followUpLeads;

    List<LeadModel> currentLeads = [];

    print(
      'FollowupController: getCurrentLeads called (tab=$_selectedTabIndex) - total follow-up leads available=${allFollowUpLeads.length}',
    );
    // Filter by follow-up date relative to selected date
    // IMPORTANT: Normalize all dates to UTC midnight for accurate date-only comparison
    // Backend returns dates in UTC, so we normalize both API dates and filter dates to UTC
    final selectedDateUtc = DateTime.utc(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final tomorrowUtc = selectedDateUtc.add(const Duration(days: 1));

    switch (_selectedTabIndex) {
      case 0:
        // Overdue: follow-up date is before selected date
        currentLeads =
            allFollowUpLeads.where((lead) {
              if (lead.followUpDate == null) return false;
              // Normalize follow-up date to UTC midnight for date-only comparison
              final followUpUtc = DateTime.utc(
                lead.followUpDate!.year,
                lead.followUpDate!.month,
                lead.followUpDate!.day,
              );
              // Compare normalized UTC dates - overdue means followUpDate < selectedDate
              final isOverdue = followUpUtc.compareTo(selectedDateUtc) < 0;
              return isOverdue;
            }).toList();
        break;
      case 1:
        // Today: follow-up date equals selected date
        currentLeads =
            allFollowUpLeads.where((lead) {
              if (lead.followUpDate == null) return false;
              // Normalize follow-up date to UTC midnight for date-only comparison
              final followUpUtc = DateTime.utc(
                lead.followUpDate!.year,
                lead.followUpDate!.month,
                lead.followUpDate!.day,
              );
              // Compare normalized UTC dates
              final isToday = followUpUtc.compareTo(selectedDateUtc) == 0;
              return isToday;
            }).toList();
        break;
      case 2:
        // Tomorrow: follow-up date equals tomorrow
        currentLeads =
            allFollowUpLeads.where((lead) {
              if (lead.followUpDate == null) return false;
              // Normalize follow-up date to UTC midnight for date-only comparison
              final followUpUtc = DateTime.utc(
                lead.followUpDate!.year,
                lead.followUpDate!.month,
                lead.followUpDate!.day,
              );
              // Compare normalized UTC dates - tomorrow means followUpDate == tomorrowUtc
              final isTomorrow = followUpUtc.compareTo(tomorrowUtc) == 0;
              return isTomorrow;
            }).toList();
        break;
      case 3:
        // Upcoming: follow-up date is after tomorrow
        currentLeads =
            allFollowUpLeads.where((lead) {
              if (lead.followUpDate == null) return false;
              // Normalize follow-up date to UTC midnight for date-only comparison
              final followUpUtc = DateTime.utc(
                lead.followUpDate!.year,
                lead.followUpDate!.month,
                lead.followUpDate!.day,
              );
              // Compare normalized UTC dates - upcoming means followUpDate > tomorrowUtc
              final isUpcoming = followUpUtc.compareTo(tomorrowUtc) > 0;
              return isUpcoming;
            }).toList();
        break;
      default:
        // Default: show only leads that actually have a followUpDate
        currentLeads =
            allFollowUpLeads
                .where((lead) => lead.followUpDate != null)
                .toList();
    }

    // Sort by followUpDate ascending (earliest first)
    // Normalize to UTC for consistent sorting regardless of timezone
    currentLeads.sort((a, b) {
      if (a.followUpDate == null && b.followUpDate == null) return 0;
      if (a.followUpDate == null) return 1;
      if (b.followUpDate == null) return -1;

      final aUtc = DateTime.utc(
        a.followUpDate!.year,
        a.followUpDate!.month,
        a.followUpDate!.day,
      );
      final bUtc = DateTime.utc(
        b.followUpDate!.year,
        b.followUpDate!.month,
        b.followUpDate!.day,
      );
      return aUtc.compareTo(bUtc);
    });

    // Debug: show first and last followUpDate after sorting if any
    if (currentLeads.isNotEmpty) {
      // ignore: avoid_print
      print(
        'FollowupController: Sorted lead range for tab=$_selectedTabIndex => first=${currentLeads.first.followUpDate}, last=${currentLeads.last.followUpDate}',
      );
    }

    print(
      'FollowupController: Returning ${currentLeads.length} leads for tab=$_selectedTabIndex after sorting',
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

  // Get today count for badge based on selected date
  int get todayCount {
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
      return followUpDate.compareTo(today) == 0;
    }).length;
  }

  // Get tomorrow count for badge based on selected date
  int get tomorrowCount {
    final selectedDate = _headerController?.selectedDate ?? DateTime.now();
    final allFollowUpLeads = _repository.followUpLeads;
    final tomorrow = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day + 1,
    );

    return allFollowUpLeads.where((lead) {
      if (lead.followUpDate == null) return false;
      final followUpDate = DateTime(
        lead.followUpDate!.year,
        lead.followUpDate!.month,
        lead.followUpDate!.day,
      );
      return followUpDate.compareTo(tomorrow) == 0;
    }).length;
  }

  // Get upcoming count for badge based on selected date
  int get upcomingCount {
    final selectedDate = _headerController?.selectedDate ?? DateTime.now();
    final allFollowUpLeads = _repository.followUpLeads;
    final tomorrow = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day + 1,
    );

    return allFollowUpLeads.where((lead) {
      if (lead.followUpDate == null) return false;
      final followUpDate = DateTime(
        lead.followUpDate!.year,
        lead.followUpDate!.month,
        lead.followUpDate!.day,
      );
      return followUpDate.isAfter(tomorrow);
    }).length;
  }

  // Convert LeadModel to display format
  // Includes all fields needed by DetailsScreen to properly identify and update follow-up leads
  Map<String, dynamic> leadToDisplayMap(LeadModel lead) {
    final categoryStyle = _getCategoryStyle(lead.category);
    return {
      "lead": lead, // REQUIRED: Needed to navigate to detail screen
      "id": lead.id, // REQUIRED: Needed to identify the lead for API updates
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
      "followUpDate":
          lead.followUpDate, // REQUIRED: Needed to identify follow-up leads
      "callStatus": lead.callStatus, // Needed for initial status display
      "leadStatus": lead.leadStatus, // Needed for initial status display
      "category": lead.category, // Needed for category-specific updates
      "brand": lead.brand, // Needed for display
      "location": lead.location, // Needed for display
      "callDuration": lead.callDuration, // Needed to display call duration
      "callCount": lead.callCount, // Needed to display call count
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

  /// Fetch follow-up leads from backend to populate follow-up data
  /// This should be called when the follow-up screen is first loaded
  /// Fetches from /api/pages/follow-ups collection
  Future<void> fetchFollowUpLeads() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print(
        'FollowupController: Fetching follow-up leads (store=${_selectedStore ?? 'All'})',
      );
      // Fetch follow-up leads from backend (/api/pages/follow-ups)
      await _repository.fetchFollowUpLeadsFromApi(store: _selectedStore);

      print(
        'FollowupController: Fetch completed - total follow-up leads in repository: ${_repository.followUpLeads.length}',
      );

      // Check and show notifications for today's follow-ups
      print(
        'FollowupController: About to call _checkAndShowFollowUpNotifications',
      );
      await _checkAndShowFollowUpNotifications();
      print('FollowupController: _checkAndShowFollowUpNotifications completed');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('FollowupController: Error fetching follow-up leads: $e');
      notifyListeners();
    }
  }

  /// Check for today's and upcoming follow-ups and show notifications
  Future<void> _checkAndShowFollowUpNotifications() async {
    try {
      print('FollowupController: Starting notification check...');
      final today = DateTime.now();
      final todayUtc = DateTime.utc(today.year, today.month, today.day);

      print('FollowupController: Today UTC: $todayUtc');
      print(
        'FollowupController: Total follow-up leads: ${_repository.followUpLeads.length}',
      );

      // Get today's follow-ups
      final todayFollowUps =
          _repository.followUpLeads.where((lead) {
            if (lead.followUpDate == null) return false;
            final followUpUtc = DateTime.utc(
              lead.followUpDate!.year,
              lead.followUpDate!.month,
              lead.followUpDate!.day,
            );
            return followUpUtc.compareTo(todayUtc) == 0;
          }).length;

      print('FollowupController: Today follow-ups count: $todayFollowUps');

      // Get upcoming follow-ups (next 7 days)
      final upcomingFollowUps =
          _repository.followUpLeads.where((lead) {
            if (lead.followUpDate == null) return false;
            final followUpUtc = DateTime.utc(
              lead.followUpDate!.year,
              lead.followUpDate!.month,
              lead.followUpDate!.day,
            );
            final sevenDaysFromNow = todayUtc.add(const Duration(days: 7));
            return followUpUtc.isAfter(todayUtc) &&
                followUpUtc.isBefore(sevenDaysFromNow);
          }).length;

      print(
        'FollowupController: Upcoming follow-ups count: $upcomingFollowUps',
      );

      // Show notifications if there are follow-ups
      if (todayFollowUps > 0) {
        print(
          'FollowupController: Showing today notification for $todayFollowUps leads',
        );
        await NotificationService().showTodayFollowUpNotification(
          todayFollowUps,
        );
      }

      if (upcomingFollowUps > 0) {
        print(
          'FollowupController: Showing upcoming notification for $upcomingFollowUps leads',
        );
        await NotificationService().showUpcomingFollowUpNotification(
          upcomingFollowUps,
        );
      }

      print('FollowupController: Notification check completed');
    } catch (e) {
      print('FollowupController: Error checking follow-up notifications: $e');
    }
  }
}
