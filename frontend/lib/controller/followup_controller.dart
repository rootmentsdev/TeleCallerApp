import 'package:flutter/material.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/model/store_model.dart';
import 'package:telecaller_app/utils/category_style.dart';
import 'package:telecaller_app/services/notification_service.dart';

/// Controller for Followup Screen
class FollowupController extends ChangeNotifier {
  final LeadRepository _repository = LeadRepository();
  HeaderController? _headerController;
  Store? _selectedStore;
  String? _selectedCategory;
  int _selectedTabIndex = 0; // 0: Overdue, 1: Today, 2: Tomorrow, 3: Upcoming
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
      // Set initial store from header controller
      _selectedStore = _headerController?.selectedStore;
    }
  }

  void _onHeaderChanged() {
    // When header changes (store selection), update the store filter and refresh
    final newStore = _headerController?.selectedStore;
    if (_selectedStore != newStore) {
      _selectedStore = newStore;
      // Refetch follow-up leads with new store filter
      fetchFollowUpLeads();
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _headerController?.removeListener(_onHeaderChanged);
    _repository.removeListener(_onRepositoryChanged);
    super.dispose();
  }

  // Getters
  Store? get selectedStore => _selectedStore;
  String? get selectedCategory => _selectedCategory;
  int get selectedTabIndex => _selectedTabIndex;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<LeadModel> get allFollowUpLeads => _repository.followUpLeads;

  // Setters
  void setSelectedStore(Store? store) {
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
    // Fetch reports when tab changes
    _fetchReportsForCurrentFilters();
  }

  void _fetchReportsForCurrentFilters() {
    notifyListeners();
  }

  // Get follow-up leads based on selected tab and date filter
  // Local filtering: Filter all follow-up leads by their followUpDate relative to today
  List<LeadModel> getCurrentLeads() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final tomorrowDate = todayDate.add(const Duration(days: 1));

    // Get all leads from repository
    final allFollowUpLeads = _repository.followUpLeads;

    print(
      'FollowupController: getCurrentLeads called (tab=$_selectedTabIndex) - total follow-up leads available=${allFollowUpLeads.length}',
    );

    // Debug: Log all follow-up leads with their dates
    for (var lead in allFollowUpLeads) {
      print(
        'FollowupController: Lead - name=${lead.name}, followUpDate=${lead.followUpDate}, category=${lead.category}',
      );
    }

    print('FollowupController: Today=$todayDate, Tomorrow=$tomorrowDate');

    List<LeadModel> currentLeads = [];

    switch (_selectedTabIndex) {
      case 0:
        // Overdue: follow-up date is before today
        currentLeads =
            allFollowUpLeads.where((lead) {
              if (lead.followUpDate == null) return false;
              final followUpDate = DateTime(
                lead.followUpDate!.year,
                lead.followUpDate!.month,
                lead.followUpDate!.day,
              );
              final isOverdue = followUpDate.isBefore(todayDate);
              print(
                'FollowupController: Tab 0 (Overdue) - Lead ${lead.name}: followUpDate=$followUpDate, isOverdue=$isOverdue',
              );
              return isOverdue;
            }).toList();
        break;

      case 1:
        // Today: follow-up date equals today
        currentLeads =
            allFollowUpLeads.where((lead) {
              if (lead.followUpDate == null) return false;
              final followUpDate = DateTime(
                lead.followUpDate!.year,
                lead.followUpDate!.month,
                lead.followUpDate!.day,
              );
              final isToday = followUpDate.compareTo(todayDate) == 0;
              print(
                'FollowupController: Tab 1 (Today) - Lead ${lead.name}: followUpDate=$followUpDate, isToday=$isToday',
              );
              return isToday;
            }).toList();
        break;

      case 2:
        // Tomorrow: follow-up date equals tomorrow
        currentLeads =
            allFollowUpLeads.where((lead) {
              if (lead.followUpDate == null) return false;
              final followUpDate = DateTime(
                lead.followUpDate!.year,
                lead.followUpDate!.month,
                lead.followUpDate!.day,
              );
              final isTomorrow = followUpDate.compareTo(tomorrowDate) == 0;
              print(
                'FollowupController: Tab 2 (Tomorrow) - Lead ${lead.name}: followUpDate=$followUpDate, isTomorrow=$isTomorrow',
              );
              return isTomorrow;
            }).toList();
        break;

      case 3:
        // Upcoming: follow-up date is after tomorrow
        currentLeads =
            allFollowUpLeads.where((lead) {
              if (lead.followUpDate == null) return false;
              final followUpDate = DateTime(
                lead.followUpDate!.year,
                lead.followUpDate!.month,
                lead.followUpDate!.day,
              );
              final isUpcoming = followUpDate.isAfter(tomorrowDate);
              print(
                'FollowupController: Tab 3 (Upcoming) - Lead ${lead.name}: followUpDate=$followUpDate, isUpcoming=$isUpcoming',
              );
              return isUpcoming;
            }).toList();
        break;

      case 4:
        // All: show all follow-up leads (including those without dates)
        currentLeads = allFollowUpLeads;
        break;

      default:
        // Default: show only leads that actually have a followUpDate
        currentLeads =
            allFollowUpLeads
                .where((lead) => lead.followUpDate != null)
                .toList();
    }

    // Sort by followUpDate ascending (earliest first)
    currentLeads.sort((a, b) {
      if (a.followUpDate == null && b.followUpDate == null) return 0;
      if (a.followUpDate == null) return 1;
      if (b.followUpDate == null) return -1;
      return a.followUpDate!.compareTo(b.followUpDate!);
    });

    // Debug: show first and last followUpDate after sorting if any
    if (currentLeads.isNotEmpty) {
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
    if (_selectedStore != null &&
        _selectedStore!.normalizedName != 'All Stores') {
      final location = _selectedStore!.location;
      currentLeads =
          currentLeads.where((lead) => lead.location == location).toList();
    }

    return currentLeads;
  }

  // Get overdue count for badge based on today's date
  int get overdueCount {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final allFollowUpLeads = _repository.followUpLeads;

    return allFollowUpLeads.where((lead) {
      if (lead.followUpDate == null) return false;
      final followUpDate = DateTime(
        lead.followUpDate!.year,
        lead.followUpDate!.month,
        lead.followUpDate!.day,
      );
      return followUpDate.isBefore(todayDate);
    }).length;
  }

  // Get today count for badge based on today's date
  int get todayCount {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final allFollowUpLeads = _repository.followUpLeads;

    return allFollowUpLeads.where((lead) {
      if (lead.followUpDate == null) return false;
      final followUpDate = DateTime(
        lead.followUpDate!.year,
        lead.followUpDate!.month,
        lead.followUpDate!.day,
      );
      return followUpDate.compareTo(todayDate) == 0;
    }).length;
  }

  // Get tomorrow count for badge based on today's date
  int get tomorrowCount {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final tomorrowDate = todayDate.add(const Duration(days: 1));
    final allFollowUpLeads = _repository.followUpLeads;

    return allFollowUpLeads.where((lead) {
      if (lead.followUpDate == null) return false;
      final followUpDate = DateTime(
        lead.followUpDate!.year,
        lead.followUpDate!.month,
        lead.followUpDate!.day,
      );
      return followUpDate.compareTo(tomorrowDate) == 0;
    }).length;
  }

  // Get upcoming count for badge based on today's date
  int get upcomingCount {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final tomorrowDate = todayDate.add(const Duration(days: 1));
    final allFollowUpLeads = _repository.followUpLeads;

    return allFollowUpLeads.where((lead) {
      if (lead.followUpDate == null) return false;
      final followUpDate = DateTime(
        lead.followUpDate!.year,
        lead.followUpDate!.month,
        lead.followUpDate!.day,
      );
      return followUpDate.isAfter(tomorrowDate);
    }).length;
  }

  // Convert LeadModel to display format
  // Includes all fields needed by DetailsScreen to properly identify and update follow-up leads
  Map<String, dynamic> leadToDisplayMap(LeadModel lead) {
    final categoryStyle = CategoryStyleHelper.getStyle(lead.category);
    return {
      "lead": lead, // REQUIRED: Needed to navigate to detail screen
      "id": lead.id, // REQUIRED: Needed to identify the lead for API updates
      "name": lead.name,
      "phone": lead.phone,
      "tag": categoryStyle.tag,
      "tagColor": categoryStyle.tagColor,
      "tagBgColor": categoryStyle.tagBgColor,
      "icon": categoryStyle.icon,
      "iconColor": categoryStyle.iconColor,
      "iconBgColor":
          categoryStyle.tagBgColor, // Use tagBgColor for icon background
      "borderColor": categoryStyle.tagColor, // Use tagColor for border
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
      "leadType": lead.leadType ?? "Lead", // Lead type for display
      "storeName": lead.brand ?? lead.location, // Store name for display
    };
  }

  void refresh() {
    notifyListeners();
    _repository.addListener(notifyListeners);
  }

  /// Fetch follow-up leads from backend to populate follow-up data
  /// This should be called when the follow-up screen is first loaded
  /// Fetches from /api/leads/followups endpoint
  Future<void> fetchFollowUpLeads() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final storeParam =
          (_selectedStore == null ||
                  _selectedStore!.normalizedName == 'All Stores')
              ? null
              : _selectedStore!.normalizedName;

      print(
        'FollowupController: Fetching follow-up leads (store=${storeParam ?? 'All'})',
      );
      // Fetch follow-up leads from backend (/api/leads/followups)
      await _repository.fetchFollowUpLeadsFromApi(store: storeParam);

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
      final todayDate = DateTime(today.year, today.month, today.day);

      print('FollowupController: Today: $todayDate');
      print(
        'FollowupController: Total follow-up leads: ${_repository.followUpLeads.length}',
      );

      // Get today's follow-ups
      final todayFollowUps =
          _repository.followUpLeads.where((lead) {
            if (lead.followUpDate == null) return false;
            final followUpDate = DateTime(
              lead.followUpDate!.year,
              lead.followUpDate!.month,
              lead.followUpDate!.day,
            );
            return followUpDate.compareTo(todayDate) == 0;
          }).length;

      print('FollowupController: Today follow-ups count: $todayFollowUps');

      // Get upcoming follow-ups (next 7 days)
      final sevenDaysFromNow = todayDate.add(const Duration(days: 7));
      final upcomingFollowUps =
          _repository.followUpLeads.where((lead) {
            if (lead.followUpDate == null) return false;
            final followUpDate = DateTime(
              lead.followUpDate!.year,
              lead.followUpDate!.month,
              lead.followUpDate!.day,
            );
            return followUpDate.isAfter(todayDate) &&
                followUpDate.isBefore(sevenDaysFromNow);
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
