import 'package:flutter/material.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/utils/store_location.dart';

/// Controller for Home Screen
class HomeController extends ChangeNotifier {
  final LeadRepository _repository = LeadRepository();
  HeaderController? _headerController;

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

  // Get call summary data (filtered by store and date)
  List<Map<String, dynamic>> getCallSummary() {
    final store = _headerController?.selectedStore;
    final date = _headerController?.selectedDate ?? DateTime.now();

    // Handle "All Stores" case and extract location from "Brand - Location" format
    final storeFilter =
        (store == null || store == 'All Stores')
            ? null
            : StoreLocations.resolveSelection(store).location;

    return [
      {
        "title": "All Calls",
        "count":
            _repository
                .getTotalLeadsCount(store: storeFilter, date: date)
                .toString(),
        "bgColor": const Color(0xFFE8E3FF),
        "iconColor": const Color(0xFF7C5DFF),
        "icon": Icons.people_alt_outlined,
      },
      {
        "title": "Loss of Sale",
        "count":
            _repository
                .getCountByCategory(
                  "Loss of Sales",
                  store: storeFilter,
                  date: date,
                )
                .toString(),
        "bgColor": const Color(0xFFFFE8E8),
        "iconColor": const Color(0xFFE23434),
        "icon": Icons.trending_down,
      },
      {
        "title": "Rent-Out Calls",
        "count":
            _repository
                .getCountByCategory("Rent out", store: storeFilter, date: date)
                .toString(),
        "bgColor": const Color(0xFFFFF7CC),
        "iconColor": const Color(0xFFFFCC00),
        "icon": Icons.message_outlined,
      },
      {
        "title": "Booking\nConfirmation",
        "count":
            _repository
                .getCountByCategory(
                  "Booking confirmation",
                  store: storeFilter,
                  date: date,
                )
                .toString(),
        "bgColor": const Color(0xFFD4F5DA),
        "iconColor": const Color(0xff56BE6B),
        "icon": Icons.flag_outlined,
      },
      {
        "title": "Just Dial\nEnquiry",
        "count":
            _repository
                .getCountByCategory("Just Dial", store: storeFilter, date: date)
                .toString(),
        "bgColor": const Color(0xFFFFE8D5),
        "iconColor": const Color(0xFFF37927),
        "icon": Icons.headset_mic_outlined,
      },
      {
        "title": "Follow Up\nCalls",
        "count":
            _repository
                .getFollowUpLeadsCount(store: storeFilter, date: date)
                .toString(),
        "bgColor": const Color(0xFFD5E8FF),
        "iconColor": const Color(0xFF2196F3),
        "icon": Icons.event_note_outlined,
      },
    ];
  }

  // Get call list data (filtered by store and date)
  List<Map<String, dynamic>> getCallList() {
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
      {
        "icon": Icons.block_outlined,
        "title": "Cancelled / Rejected",
        "subtitle": "Customer Declined",
        "count":
            _repository
                .getCountByCategory(
                  "Loss of Sales",
                  store: storeFilter,
                  date: date,
                )
                .toString(),
        "bgColor": const Color(0xffE7E7E7),
        "iconColor": const Color(0xff797979),
      },
    ];
  }

  // Refresh data (notify listeners when repository data changes)
  void refresh() {
    notifyListeners();
  }
}
