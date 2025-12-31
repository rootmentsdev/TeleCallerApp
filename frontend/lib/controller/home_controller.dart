import 'package:flutter/material.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/utils/lead_constants.dart';
import 'package:telecaller_app/utils/store_location.dart';

/// Controller for Home Screen
class HomeController extends ChangeNotifier {
  final LeadRepository _repository = LeadRepository();
  HeaderController? _headerController;

  // API calls overview data
  Map<String, dynamic>? _apiCallsOverview;
  bool _isLoadingCallsOverview = false;
  String? _callsOverviewError;

  // Initialize with header controller
  void init(HeaderController headerController) {
    if (_headerController != headerController) {
      _headerController?.removeListener(_onHeaderChanged);
      _headerController = headerController;
      _headerController?.addListener(_onHeaderChanged);
    }
    _repository.debugDataIntegrity();
    fetchCallsOverviewFromApi();
  }

  void _onHeaderChanged() {
    fetchCallsOverviewFromApi();
    notifyListeners();
  }

  @override
  void dispose() {
    _headerController?.removeListener(_onHeaderChanged);
    super.dispose();
  }

  /// Fetch calls overview from API
  Future<void> fetchCallsOverviewFromApi() async {
    try {
      _isLoadingCallsOverview = true;
      _callsOverviewError = null;
      notifyListeners();

      final store = _headerController?.selectedStore;
      final date = _headerController?.selectedDate ?? DateTime.now();

      // Pass store in "Brand - Location" format if not "All Stores"
      final storeParam =
          (store == null || store == 'All Stores') ? null : store;

      final response = await _repository.fetchCallSummaryFromApi(
        store: storeParam,
        date: date,
      );

      _apiCallsOverview = response;
      _isLoadingCallsOverview = false;
      notifyListeners();
    } catch (e) {
      _isLoadingCallsOverview = false;
      _callsOverviewError = e.toString();
      notifyListeners();
    }
  }

  // Get call summary data (calculated locally, not from API)
  List<Map<String, dynamic>> getCallSummary() {
    final date = _headerController?.selectedDate ?? DateTime.now();
    final allLeads = _repository.getLeadsByDate(date);

    final store = _headerController?.selectedStore;

    // Filter by store (brand + location)
    final storeFilter =
        (store == null || store == 'All Stores')
            ? null
            : StoreLocations.resolveSelection(store).location;

    List<T> filterStore<T extends LeadModel>(List<T> leads) {
      if (storeFilter == null) return leads;
      return leads.where((e) => e.location == storeFilter).toList();
    }

    // Count only uncalled leads
    int count(String? category) {
      List<LeadModel> leads = allLeads;

      if (category != null) {
        leads = leads.where((e) => e.category == category).toList();
      }

      leads = filterStore(leads);

      return leads
          .where((e) => LeadConstants.isUncalledStatus(e.callStatus))
          .length;
    }

    return [
      {
        "title": "All Calls",
        "count": count(null).toString(),
        "bgColor": const Color(0xFFE8E3FF),
        "iconColor": const Color(0xFF7C5DFF),
        "icon": Icons.people_alt_outlined,
      },
      {
        "title": "Loss of Sale",
        "count": count(LeadConstants.categoryLossOfSales).toString(),
        "bgColor": const Color(0xFFFFE8E8),
        "iconColor": const Color(0xFFE23434),
        "icon": Icons.trending_down,
      },
      {
        "title": "Return",
        "count": count(LeadConstants.categoryRentOut).toString(),
        "bgColor": const Color(0xFFFFF7CC),
        "iconColor": const Color(0xFFFFCC00),
        "icon": Icons.message_outlined,
      },
      {
        "title": "Booking\nConfirmation",
        "count": count(LeadConstants.categoryBookingConfirmation).toString(),
        "bgColor": const Color(0xFFD4F5DA),
        "iconColor": const Color(0xff56BE6B),
        "icon": Icons.flag_outlined,
      },
    ];
  }

  // Get call list data (calls overview from API)
  List<Map<String, dynamic>> getCallList() {
    // If API data is available, use it
    if (_apiCallsOverview != null) {
      return _buildCallListFromApi(_apiCallsOverview!);
    }

    // Fallback to local calculation if API fails
    return _buildCallListFromLocal();
  }

  /// Build calls overview from API response
  List<Map<String, dynamic>> _buildCallListFromApi(
    Map<String, dynamic> apiData,
  ) {
    // Extract counts from API response
    final connected = apiData['connected']?.toString() ?? '0';
    final notConnected = apiData['not_connected']?.toString() ?? '0';
    final callBackLater = apiData['call_back_later']?.toString() ?? '0';
    final confirmed = apiData['confirmed']?.toString() ?? '0';

    return [
      {
        "icon": Icons.phone_outlined,
        "title": "Connected Calls",
        "subtitle": "Customer Answered",
        "count": connected,
        "bgColor": const Color(0xffD4F5DA),
        "iconColor": const Color(0xff56BE6B),
      },
      {
        "icon": Icons.call_end_outlined,
        "title": "Not Connected",
        "subtitle": "Busy / Switched Off",
        "count": notConnected,
        "bgColor": const Color(0xffFFD8D8),
        "iconColor": const Color(0xffFF0000),
      },
      {
        "icon": Icons.access_time,
        "title": "Call Back Later",
        "subtitle": "Follow-up pending",
        "count": callBackLater,
        "bgColor": const Color(0xffFFF7CC),
        "iconColor": const Color(0xffFFCC00),
      },
      {
        "icon": Icons.task_alt_outlined,
        "title": "Confirmed / Converted",
        "subtitle": "Customer Booked",
        "count": confirmed,
        "bgColor": const Color(0xffD4F5DA),
        "iconColor": const Color(0xff56BE6B),
      },
    ];
  }

  /// Fallback: Build calls overview from local data
  List<Map<String, dynamic>> _buildCallListFromLocal() {
    final store = _headerController?.selectedStore;
    final date = _headerController?.selectedDate ?? DateTime.now();

    // Handle "All Stores" case and extract location from "Brand - Location" format
    final storeFilter =
        (store == null || store == 'All Stores')
            ? null
            : StoreLocations.resolveSelection(store).location;

    return [
      {
        "icon": Icons.phone_outlined,
        "title": "Connected Calls",
        "subtitle": "Customer Answered",
        "count":
            _repository
                .getCountByCallStatus(
                  "Connected",
                  store: storeFilter,
                  date: date,
                )
                .toString(),
        "bgColor": const Color(0xffD4F5DA),
        "iconColor": const Color(0xff56BE6B),
      },
      {
        "icon": Icons.call_end_outlined,
        "title": "Not Connected",
        "subtitle": "Busy / Switched Off",
        "count":
            _repository
                .getCountByCallStatus(
                  "Not Connected",
                  store: storeFilter,
                  date: date,
                )
                .toString(),
        "bgColor": const Color(0xffFFD8D8),
        "iconColor": const Color(0xffFF0000),
      },
      {
        "icon": Icons.access_time,
        "title": "Call Back Later",
        "subtitle": "Follow-up pending",
        "count":
            _repository
                .getCountByCallStatus(
                  "Call Back Later",
                  store: storeFilter,
                  date: date,
                )
                .toString(),
        "bgColor": const Color(0xffFFF7CC),
        "iconColor": const Color(0xffFFCC00),
      },
      {
        "icon": Icons.task_alt_outlined,
        "title": "Confirmed / Converted",
        "subtitle": "Customer Booked",
        "count":
            _repository
                .getCountByCallStatus(
                  "Connected",
                  store: storeFilter,
                  date: date,
                )
                .toString(),
        "bgColor": const Color(0xffD4F5DA),
        "iconColor": const Color(0xff56BE6B),
      },
    ];
  }

  // Getters for API state
  bool get isLoadingCallsOverview => _isLoadingCallsOverview;
  String? get callsOverviewError => _callsOverviewError;
  bool get hasApiData => _apiCallsOverview != null;

  // Refresh data (notify listeners when repository data changes)
  void refresh() {
    fetchCallsOverviewFromApi();
    notifyListeners();
  }
}
