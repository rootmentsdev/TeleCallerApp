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

  LeadScreenController() {
    // Listen to repository changes and forward notifications so UI updates
    _repository.addListener(_onRepositoryChanged);
  }

  // If true, UI should show only the newly added lead (if available)
  bool _showOnlyNewLead = false;
  String? _focusedNewLeadId;

  /// Call to explicitly clear the "show only new lead" filter
  void clearShowOnlyNewLead() {
    _showOnlyNewLead = false;
    _focusedNewLeadId = null;
    // Also clear repository marker so subsequent adds work as expected
    _repository.clearLastAddedMarker();
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
    // When header (store/date) changes, refresh data from API for current filters
    notifyListeners();

    // Get current store and date filters
    final store = _headerController?.selectedStore;
    final storeParam = (store == null || store == 'All Stores') ? null : store;
    final selectedDate = _headerController?.selectedDate ?? DateTime.now();

    // Fetch all lead types with store and date filters when header changes
    // This ensures all tabs show filtered data
    if (storeParam != null) {
      // Fetch all leads (for "All Calls" tab)
      // GET /api/pages/leads?store=Suitor Guy - Edappally&enquiryDateFrom=2024-12-08&enquiryDateTo=2024-12-08
      fetchAllLeadsFromApi(store: storeParam, date: selectedDate).catchError((
        e,
      ) {
        print(
          'LeadScreenController: Error fetching all leads on header change: $e',
        );
      });

      // Fetch Loss of Sale leads with store filter
      // GET /api/pages/leads?leadType=lossOfSale&store=Suitor Guy - Edappally
      fetchLossOfSaleLeadsFromApi(store: storeParam).catchError((e) {
        print(
          'LeadScreenController: Error fetching Loss of Sale leads on header change: $e',
        );
      });

      // Fetch Rent Out leads with store filter
      // GET /api/pages/leads?leadType=rentOutFeedback&store=Suitor Guy - Edappally
      fetchRentOutLeadsFromApi(store: storeParam).catchError((e) {
        print(
          'LeadScreenController: Error fetching Rent-Out leads on header change: $e',
        );
      });

      // Fetch Booking Confirmation leads with store filter
      // GET /api/pages/leads?leadType=bookingConfirmation&store=Suitor Guy - Edappally
      fetchBookingConfirmationLeadsFromApi(store: storeParam).catchError((e) {
        print(
          'LeadScreenController: Error fetching Booking Confirmation leads on header change: $e',
        );
      });
    } else {
      // If "All Stores" is selected, fetch without store filter but with date filter
      fetchAllLeadsFromApi(date: selectedDate).catchError((e) {
        print(
          'LeadScreenController: Error fetching all leads (no store filter): $e',
        );
      });
      fetchLossOfSaleLeadsFromApi().catchError((e) {
        print(
          'LeadScreenController: Error fetching Loss of Sale leads (no store filter): $e',
        );
      });
      fetchRentOutLeadsFromApi().catchError((e) {
        print(
          'LeadScreenController: Error fetching Rent-Out leads (no store filter): $e',
        );
      });
      fetchBookingConfirmationLeadsFromApi().catchError((e) {
        print(
          'LeadScreenController: Error fetching Booking Confirmation leads (no store filter): $e',
        );
      });
    }
  }

  void _onRepositoryChanged() {
    // If repository has a last-added lead id, focus on it (show only new lead)
    final lastAdded = _repository.lastAddedLeadId;
    if (lastAdded != null) {
      _showOnlyNewLead = true;
      _focusedNewLeadId = lastAdded;
      // Auto-clear after showing the new lead once (after a short delay)
      Future.delayed(const Duration(seconds: 2), () {
        if (_focusedNewLeadId == lastAdded) {
          clearShowOnlyNewLead();
        }
      });
    }

    // Forward repository changes to listeners of this controller
    notifyListeners();
  }

  void _removeLeadFromActiveLists(String id) {
    _repository.allLeads.removeWhere((lead) => lead.id == id);
  }

  @override
  void dispose() {
    _headerController?.removeListener(_onHeaderChanged);
    _repository.removeListener(_onRepositoryChanged);
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
    // Clear "show only new lead" when switching tabs so all leads are visible
    if (_showOnlyNewLead) {
      clearShowOnlyNewLead();
    }
    notifyListeners();
  }

  // Get call summary data (filtered by store and date)
  // Only count leads that haven't been called yet
  List<Map<String, dynamic>> getCallSummary() {
    // Note: store and date filters are handled in getUncalledLeadsCount

    // Helper function to count uncalled leads
    // int getUncalledLeadsCount({String? category}) {
    //   List<LeadModel> leads =
    //       category != null
    //           ? _repository.getLeadsByCategory(category)
    //           : _repository.allLeads;

    //   // Filter by store - extract location from "Brand - Location" format
    //   if (storeFilter != null) {
    //     final location = StoreLocations.resolveSelection(storeFilter).location;
    //     leads = leads.where((lead) => lead.location == location).toList();
    //   }

    //   // Filter by date - but for Loss of Sale, count all leads (date filter is handled by API)
    //   // For other categories, filter by selected date
    //   if (category != LeadConstants.categoryLossOfSales) {
    //     leads =
    //         leads.where((lead) {
    //           final leadDate = lead.createdAt;
    //           return leadDate.year == date.year &&
    //               leadDate.month == date.month &&
    //               leadDate.day == date.day;
    //         }).toList();
    //   }

    //   // Filter out leads that have been called
    //   leads =
    //       leads
    //           .where((lead) => LeadConstants.isUncalledStatus(lead.callStatus))
    //           .toList();

    //   return leads.length;
    // }
    int getUncalledLeadsCount({String? category}) {
      final date = _headerController?.selectedDate ?? DateTime.now();

      // STEP 1: get leads by category with date filter
      List<LeadModel> leads =
          category != null
              ? _repository.getLeadsByCategory(category, date: date)
              : _repository.getLeadsByDate(date);

      // STEP 2: filter by store using the same logic as getFilteredLeads
      final storeFilter = _headerController?.selectedStore;
      if (storeFilter != null && storeFilter != "All Stores") {
        final selectedLocation =
            StoreLocations.resolveSelection(storeFilter).location;
        final selectedBrand =
            StoreLocations.resolveSelection(storeFilter).brand;

        // Normalize for case-insensitive comparison
        final normalizedSelectedLocation =
            selectedLocation.toLowerCase().trim();
        final normalizedSelectedBrand = selectedBrand.toLowerCase().trim();
        final normalizedStore = storeFilter.toLowerCase().trim();

        leads =
            leads.where((lead) {
              if (lead.location == null || lead.location!.isEmpty) return false;

              final leadLocation = lead.location!.toLowerCase().trim();

              // Extract location from API formats like "SG-Edappally" or "SG-Edappal"
              String extractedLeadLocation;
              if (leadLocation.startsWith('sg-')) {
                // Handle "SG-Edappally" format - extract location part
                extractedLeadLocation = leadLocation.substring(
                  3,
                ); // Remove "sg-" prefix
              } else if (leadLocation.contains('-')) {
                // Handle other formats with dashes
                final parts = leadLocation.split('-');
                extractedLeadLocation = parts.last.trim();
              } else {
                // Just location name
                extractedLeadLocation = leadLocation;
              }

              // Try exact match first
              if (leadLocation == normalizedStore) return true;

              // Try matching location part
              if (leadLocation == normalizedSelectedLocation) return true;
              if (extractedLeadLocation == normalizedSelectedLocation)
                return true;

              // Try contains matching
              if (leadLocation.contains(normalizedSelectedLocation))
                return true;
              if (extractedLeadLocation.contains(normalizedSelectedLocation))
                return true;
              if (normalizedSelectedLocation.contains(leadLocation))
                return true;
              if (normalizedSelectedLocation.contains(extractedLeadLocation))
                return true;

              // Try brand matching
              if (leadLocation.contains(normalizedSelectedBrand)) return true;

              // Handle "Brand - Location" format extraction
              final storeParts = normalizedStore.split(' - ');
              if (storeParts.length > 1) {
                final storeLocationPart = storeParts.last;
                if (leadLocation == storeLocationPart ||
                    leadLocation.contains(storeLocationPart) ||
                    storeLocationPart.contains(leadLocation)) {
                  return true;
                }
                if (extractedLeadLocation == storeLocationPart ||
                    extractedLeadLocation.contains(storeLocationPart) ||
                    storeLocationPart.contains(extractedLeadLocation)) {
                  return true;
                }
              }

              return false;
            }).toList();
      }

      // STEP 3: DO NOT FILTER BY DATE
      // (This is the reason counts were 0 before)

      // STEP 4: count only uncalled
      leads =
          leads
              .where((lead) => LeadConstants.isUncalledStatus(lead.callStatus))
              .toList();

      // STEP 5: exclude leads with follow-up dates (they appear in Follow-up Screen)
      leads = leads.where((lead) => lead.followUpDate == null).toList();

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
  // For "All Calls" tab (index 0), show all leads regardless of call status
  // For other tabs, only show leads that haven't been called yet
  List<LeadDisplayModel> getFilteredLeads() {
    String? category = _getCategoryForIndex(_selectedCallTypeIndex);

    final store = _headerController?.selectedStore;
    final date = _headerController?.selectedDate ?? DateTime.now();

    // Get leads filtered by category, store, and date
    List<LeadModel> filteredLeads = _repository.getLeadsByCategory(
      category,
      date: date,
    );

    // Debug: Print initial lead count
    print(
      'LeadScreenController: getFilteredLeads - Initial leads count: ${filteredLeads.length}, category: $category, store: $store',
    );

    // Filter by store - match store field from API
    // API may return store as:
    // - "KANNUR" (just location, uppercase)
    // - "Suitor Guy - Perinthalmanna" (full "Brand - Location" format)
    // We need to match against the selected store which is "Brand - Location"
    if (store != null && store != 'All Stores') {
      // Extract location from selected store for comparison
      final selectedLocation = StoreLocations.resolveSelection(store).location;
      final selectedBrand = StoreLocations.resolveSelection(store).brand;

      // Normalize for case-insensitive comparison
      final normalizedSelectedLocation = selectedLocation.toLowerCase().trim();
      final normalizedSelectedBrand = selectedBrand.toLowerCase().trim();
      final normalizedStore = store.toLowerCase().trim();

      filteredLeads =
          filteredLeads.where((lead) {
            if (lead.location == null || lead.location!.isEmpty) return false;

            final leadLocation = lead.location!.toLowerCase().trim();

            // Extract location from API formats like "SG-Edappally" or "SG-Edappal"
            String? extractedLeadLocation;
            if (leadLocation.startsWith('sg-')) {
              // Handle "SG-Edappally" format - extract location part
              extractedLeadLocation = leadLocation.substring(
                3,
              ); // Remove "sg-" prefix
            } else if (leadLocation.contains('-')) {
              // Handle other formats with dashes
              final parts = leadLocation.split('-');
              extractedLeadLocation = parts.last.trim();
            } else {
              // Just location name
              extractedLeadLocation = leadLocation;
            }

            // Try exact match first (full "Brand - Location" format, case-insensitive)
            if (leadLocation == normalizedStore) return true;

            // Try matching just the location part (case-insensitive)
            if (leadLocation == normalizedSelectedLocation) return true;
            if (extractedLeadLocation == normalizedSelectedLocation)
              return true;

            // Try matching if lead.location contains the selected location (case-insensitive)
            if (leadLocation.contains(normalizedSelectedLocation)) return true;
            if (extractedLeadLocation.contains(normalizedSelectedLocation))
              return true;

            // Try reverse - if selected location contains lead location
            if (normalizedSelectedLocation.contains(leadLocation)) return true;
            if (normalizedSelectedLocation.contains(extractedLeadLocation))
              return true;

            // Try matching if lead.location contains the selected brand (case-insensitive)
            if (leadLocation.contains(normalizedSelectedBrand)) return true;

            // Handle cases where API returns formats like "SG-Edappally"
            // and we're filtering by "Suitor Guy - Edappal" or "Suitor Guy - Edappally"
            final storeParts = normalizedStore.split(' - ');
            if (storeParts.length > 1) {
              final storeLocationPart =
                  storeParts.last; // Get "edappal" from "suitor guy - edappal"

              // Match if lead location equals the location part, or contains it
              if (leadLocation == storeLocationPart ||
                  leadLocation.contains(storeLocationPart) ||
                  storeLocationPart.contains(leadLocation)) {
                return true;
              }

              // Match extracted location (e.g., "edappally" from "sg-edappally")
              if (extractedLeadLocation == storeLocationPart ||
                  extractedLeadLocation.contains(storeLocationPart) ||
                  storeLocationPart.contains(extractedLeadLocation)) {
                return true;
              }
            } else {
              // If store format is just location (shouldn't happen, but handle it)
              if (leadLocation == normalizedStore ||
                  leadLocation.contains(normalizedStore) ||
                  normalizedStore.contains(leadLocation)) {
                return true;
              }
              if (extractedLeadLocation == normalizedStore ||
                  extractedLeadLocation.contains(normalizedStore) ||
                  normalizedStore.contains(extractedLeadLocation)) {
                return true;
              }
            }

            return false;
          }).toList();

      // Debug: Print after store filter
      print(
        'LeadScreenController: After store filter: ${filteredLeads.length} leads',
      );
      final totalLeadsBeforeFilter =
          _repository.getLeadsByCategory(category, date: date).length;
      if (filteredLeads.isEmpty && totalLeadsBeforeFilter > 0) {
        // Debug: Show sample lead locations for troubleshooting
        final sampleLeads =
            _repository
                .getLeadsByCategory(category, date: date)
                .take(5)
                .toList();
        print(
          'LeadScreenController: DEBUG - Store filter returned 0 leads but ${totalLeadsBeforeFilter} leads exist',
        );
        print(
          'LeadScreenController: Sample lead locations: ${sampleLeads.map((l) => l.location).join(", ")}',
        );
        print('LeadScreenController: Selected store: "$store"');
        print(
          'LeadScreenController: Extracted location: "$selectedLocation" (normalized: "$normalizedSelectedLocation")',
        );
        print(
          'LeadScreenController: Extracted brand: "$selectedBrand" (normalized: "$normalizedSelectedBrand")',
        );

        // Test matching logic
        for (var sampleLead in sampleLeads) {
          if (sampleLead.location != null) {
            final sampleLocation = sampleLead.location!.toLowerCase().trim();
            final matches =
                sampleLocation == normalizedStore ||
                sampleLocation == normalizedSelectedLocation ||
                sampleLocation.contains(normalizedSelectedLocation) ||
                normalizedSelectedLocation.contains(sampleLocation);
            print(
              'LeadScreenController: Sample lead "${sampleLead.name}" location "${sampleLead.location}" -> matches: $matches',
            );
          }
        }
      }
    }

    // Filter by date - but for All Calls, Loss of Sale, Rent-Out, and Booking Confirmation, show all leads (date filter is handled by API)
    // For other categories, filter by selected date
    if (_selectedCallTypeIndex != 0 &&
        _selectedCallTypeIndex != 1 &&
        _selectedCallTypeIndex != 2 &&
        _selectedCallTypeIndex != 3) {
      filteredLeads =
          filteredLeads.where((lead) {
            final leadDate = lead.createdAt;
            return leadDate.year == date.year &&
                leadDate.month == date.month &&
                leadDate.day == date.day;
          }).toList();
    }

    // Filter out leads that have been called (only show uncalled leads)
    // EXCEPT for "All Calls" tab (index 0) which should show all leads
    if (_selectedCallTypeIndex != 0) {
      final beforeCallStatusFilter = filteredLeads.length;
      filteredLeads =
          filteredLeads
              .where((lead) => LeadConstants.isUncalledStatus(lead.callStatus))
              .toList();
      print(
        'LeadScreenController: After call status filter: ${filteredLeads.length} leads (was $beforeCallStatusFilter)',
      );
    }

    // Filter by follow-up status based on selected tab
    // For "Follow Up Calls" tab (index 5), show ONLY leads with follow-up dates
    // For other tabs, show ONLY leads without follow-up dates
    if (_selectedCallTypeIndex == 5) {
      // Follow Up Calls tab - show only leads with follow-up dates
      filteredLeads =
          filteredLeads.where((lead) => lead.followUpDate != null).toList();
      print(
        'LeadScreenController: Follow-up tab - showing ${filteredLeads.length} leads with follow-up dates',
      );
    } else {
      // Other tabs - exclude leads with follow-up dates
      final beforeFollowUpFilter = filteredLeads.length;
      filteredLeads =
          filteredLeads.where((lead) => lead.followUpDate == null).toList();
      print(
        'LeadScreenController: After follow-up filter: ${filteredLeads.length} leads (was $beforeFollowUpFilter, removed ${beforeFollowUpFilter - filteredLeads.length} follow-up leads)',
      );
    }

    // Debug: Print final count
    print(
      'LeadScreenController: Final filtered leads count: ${filteredLeads.length}',
    );

    // Convert to display models
    // If we're showing only the newly added lead, return only that one (if present)
    // But only for "All Calls" tab - other tabs should show all leads
    if (_showOnlyNewLead &&
        _focusedNewLeadId != null &&
        _selectedCallTypeIndex == 0) {
      final matches =
          filteredLeads.where((l) => l.id == _focusedNewLeadId).toList();
      if (matches.isNotEmpty) {
        // Auto-clear after showing once
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_focusedNewLeadId == matches.first.id) {
            clearShowOnlyNewLead();
          }
        });
        return [LeadDisplayModel.fromLead(matches.first)];
      }
      // If not found in filtered list, clear the flag and show all leads
      clearShowOnlyNewLead();
    }

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

  /// Get count of follow-up leads for the selected date and store
  int getFollowUpLeadsCount() {
    final date = _headerController?.selectedDate ?? DateTime.now();
    final store = _headerController?.selectedStore;

    // Get all leads for the selected date
    List<LeadModel> leads = _repository.getLeadsByDate(date);

    // Filter by store if specified
    if (store != null && store != 'All Stores') {
      final selectedLocation = StoreLocations.resolveSelection(store).location;
      leads = leads.where((lead) => lead.location == selectedLocation).toList();
    }

    // Count only leads with follow-up dates
    return leads.where((lead) => lead.followUpDate != null).length;
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

  /// Fetch Booking Confirmation leads from API
  Future<void> fetchBookingConfirmationLeadsFromApi({String? store}) async {
    try {
      await _repository.fetchBookingConfirmationLeadsFromApi(store: store);
      notifyListeners();
    } catch (e) {
      print(
        'LeadScreenController: Error fetching Booking Confirmation leads: $e',
      );
      rethrow;
    }
  }

  /// Fetch Rent-Out leads from API
  Future<void> fetchRentOutLeadsFromApi({String? store}) async {
    try {
      await _repository.fetchRentOutLeadsFromApi(store: store);
      notifyListeners();
    } catch (e) {
      print('LeadScreenController: Error fetching Rent-Out leads: $e');
      rethrow;
    }
  }

  /// Format date to YYYY-MM-DD format for API
  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Fetch all leads from API with store and date filters
  /// Uses endpoint: /api/pages/leads?store=Suitor Guy - Edappal&createdAt=2025-12-04
  Future<void> fetchAllLeadsFromApi({
    String? store,
    int? page,
    DateTime? date,
    String? enquiryDateFrom,
    String? enquiryDateTo,
    String? functionDateFrom,
    String? functionDateTo,
    String? visitDateFrom,
    String? visitDateTo,
    String? dateFrom,
    String? dateTo,
    String? dateField,
    String? createdAt,
  }) async {
    try {
      // If date is provided, use it for createdAt filtering (primary date filter)
      String? finalCreatedAt = createdAt;

      if (date != null && createdAt == null) {
        // Use the provided date for createdAt filter (format: YYYY-MM-DD)
        finalCreatedAt = _formatDateForApi(date);
      }

      await _repository.fetchAllLeadsFromApi(
        store: store,
        page: page,
        enquiryDateFrom: enquiryDateFrom,
        enquiryDateTo: enquiryDateTo,
        functionDateFrom: functionDateFrom,
        functionDateTo: functionDateTo,
        visitDateFrom: visitDateFrom,
        visitDateTo: visitDateTo,
        dateFrom: dateFrom,
        dateTo: dateTo,
        dateField: dateField,
        createdAt: finalCreatedAt,
      );
      notifyListeners();
    } catch (e) {
      print('LeadScreenController: Error fetching all leads: $e');
      rethrow;
    }
  }

  /// Update Loss of Sale lead via API
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

      _removeLeadFromActiveLists(id);

      notifyListeners();
    } catch (e) {
      print('LeadScreenController: Error updating Loss of Sale lead: $e');
      rethrow;
    }
  }

  /// Update Rent-Out lead via API
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
      _removeLeadFromActiveLists(id);
      notifyListeners();
    } catch (e) {
      print('LeadScreenController: Error updating Rent-Out lead: $e');
      rethrow;
    }
  }

  /// Update Booking Confirmation lead via API
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
      _removeLeadFromActiveLists(id);
      notifyListeners();
    } catch (e) {
      print(
        'LeadScreenController: Error updating Booking Confirmation lead: $e',
      );
      rethrow;
    }
  }
}
