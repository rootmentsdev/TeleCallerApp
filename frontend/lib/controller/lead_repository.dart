import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/services/api_service.dart';
import 'package:telecaller_app/utils/lead_constants.dart';
import 'package:telecaller_app/utils/store_location.dart';

/// Shared repository for managing all lead data
/// This is a singleton that all controllers can access
class LeadRepository extends ChangeNotifier {
  static final LeadRepository _instance = LeadRepository._internal();
  factory LeadRepository() => _instance;
  LeadRepository._internal() {
    // Initialize asynchronously without blocking
    _initialize().catchError((error) {
      // Silently handle initialization errors - app should still work
      print('LeadRepository: Error during initialization: $error');
    });
  }

  final List<LeadModel> _leads = [];
  static const String _storageKey = 'saved_leads';
  bool _isInitialized = false;
  final ApiService _apiService = ApiService();
  // Track the most recently added lead id so UI can focus on it
  String? _lastAddedLeadId;

  // Store booking confirmation specific data (booking number, enquiry date, function date)
  final Map<String, Map<String, dynamic>> _bookingConfirmationData = {};

  // ========== Getters ==========

  List<LeadModel> get allLeads {
    // Initialize asynchronously if not already done (for immediate access)
    if (!_isInitialized) {
      _initialize().then((_) => _isInitialized = true).catchError((error) {
        print('LeadRepository: Error initializing in allLeads getter: $error');
        return false;
      });
    }
    return List.unmodifiable(_leads);
  }

  List<LeadModel> get followUpLeads {
    // IMPORTANT: Only return leads with category "Follow Up" (from backend follow-up collection)
    // Do NOT return leads that just have followUpDate set but are not in the follow-up collection
    // This prevents duplicates where a lead exists both in local storage and in backend follow-up collection
    return _leads
        .where((lead) => lead.category == LeadConstants.categoryFollowUp)
        .toList();
  }

  List<LeadModel> get todayFollowUps {
    return _leads.where((lead) => lead.isToday).toList();
  }

  List<LeadModel> get upcomingFollowUps {
    return _leads.where((lead) => lead.isUpcoming).toList();
  }

  List<LeadModel> get overdueFollowUps {
    return _leads.where((lead) => lead.isOverdue).toList();
  }

  // ========== Initialization ==========

  Future<void> _initialize() async {
    if (_isInitialized) return;
    await _loadLeads();
    _isInitialized = true;
  }

  // Ensure initialization is complete before operations
  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await _initialize();
    }
  }

  // ========== Persistence ==========

  Future<void> _loadLeads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final leadsJson = prefs.getString(_storageKey);

      if (leadsJson != null && leadsJson.isNotEmpty) {
        final List<dynamic> leadsList = json.decode(leadsJson);
        _leads.clear();
        _leads.addAll(
          leadsList
              .map(
                (leadMap) => LeadModel.fromMap(leadMap as Map<String, dynamic>),
              )
              .toList(),
        );
        // Notify listeners that leads have been loaded from persistence
        notifyListeners();
      }
    } catch (e) {
      // If loading fails, start with empty list
      _leads.clear();
    }
  }

  Future<void> _saveLeads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final leadsJson = json.encode(
        _leads.map((lead) => lead.toMap()).toList(),
      );
      await prefs.setString(_storageKey, leadsJson);
    } catch (e) {
      // Handle save error silently or log it
      print('Error saving leads: $e');
    }
  }

  // ========== CRUD Operations ==========

  Future<void> addLead(LeadModel lead) async {
    await ensureInitialized();
    _leads.add(lead);
    _lastAddedLeadId = lead.id;
    await _saveLeads();
    notifyListeners();
  }

  /// Return the id of the most recently added lead (if any).
  String? get lastAddedLeadId => _lastAddedLeadId;

  /// Clear the last-added marker (call when UI has focused the new lead).
  void clearLastAddedMarker() {
    _lastAddedLeadId = null;
  }

  Future<void> removeLead(String id) async {
    await ensureInitialized();
    _leads.removeWhere((lead) => lead.id == id);
    await _saveLeads();
    notifyListeners();
  }

  /// Remove a lead by phone number (useful when ID might differ after backend update)
  Future<void> removeLeadByPhone(String phoneNumber) async {
    await ensureInitialized();
    final removedCount = _leads.length;
    _leads.removeWhere((lead) => lead.phone == phoneNumber);
    final remainingCount = _leads.length;
    if (removedCount != remainingCount) {
      print('LeadRepository: Removed ${removedCount - remainingCount} lead(s) with phone number: $phoneNumber');
      await _saveLeads();
      notifyListeners();
    }
  }

  Future<void> updateLead(LeadModel updatedLead) async {
    await ensureInitialized();
    final index = _leads.indexWhere((lead) => lead.id == updatedLead.id);
    if (index != -1) {
      final oldLead = _leads[index];
      _leads[index] = updatedLead;

      // Check if lead should be moved to reports
      // Move to reports if the lead status changed from uncalled to called
      final wasUncalled = LeadConstants.isUncalledStatus(oldLead.callStatus);
      final isNowCalled = LeadConstants.isCalledStatus(updatedLead.callStatus);

      if (wasUncalled && isNowCalled && updatedLead.followUpDate == null) {
        print(
          'LeadRepository: Lead ${updatedLead.id} (${updatedLead.name}) status changed from "${oldLead.callStatus}" to "${updatedLead.callStatus}", moving to reports',
        );
        // Remove from active leads (move to reports)
        _leads.removeAt(index);
      }

      await _saveLeads();
      notifyListeners();
    }
  }

  LeadModel? getLeadById(String id) {
    try {
      return _leads.firstWhere((lead) => lead.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get booking confirmation specific data for a lead
  Map<String, dynamic>? getBookingConfirmationData(String leadId) {
    return _bookingConfirmationData[leadId];
  }

  // ========== Filtered Queries ==========

  List<LeadModel> getLeadsByCategory(String? category, {DateTime? date, DateTime? dateStart, DateTime? dateEnd}) {
    List<LeadModel> filtered = _leads;

    // Apply date filter if provided
    if (dateStart != null && dateEnd != null) {
      // Use date range filter
      filtered = getLeadsByDateRange(dateStart, dateEnd);
    } else if (date != null) {
      // Use single date filter
      filtered =
          filtered.where((lead) {
            final leadDate = lead.createdAt;
            return leadDate.year == date.year &&
                leadDate.month == date.month &&
                leadDate.day == date.day;
          }).toList();
    }

    // Apply category filter
    if (category == null || category == 'All') return filtered;
    return filtered.where((lead) => lead.category == category).toList();
  }

  /// Helper method to check if a lead matches a store filter
  /// Handles case-insensitive matching, extracts locations from "Brand - Location" formats,
  /// and supports partial matching
  bool matchesStore(LeadModel lead, String store) {
    if (store.isEmpty || store == 'All Stores') {
      return true;
    }

    // Extract location from "Brand - Location" format, or use as-is if already a location
    final location =
        store.contains(' - ')
            ? StoreLocations.resolveSelection(store).location
            : store;

    // Case-insensitive matching
    final leadLocation = lead.location ?? '';
    final normalizedLeadLocation = leadLocation.toLowerCase().trim();
    final normalizedFilterLocation = location.toLowerCase().trim();

    // Exact match
    if (normalizedLeadLocation == normalizedFilterLocation) {
      return true;
    }

    // Partial match (check if filter location is contained in lead location or vice versa)
    if (normalizedLeadLocation.contains(normalizedFilterLocation) ||
        normalizedFilterLocation.contains(normalizedLeadLocation)) {
      return true;
    }

    return false;
  }

  List<LeadModel> getLeadsByStore(String? store, {DateTime? date}) {
    List<LeadModel> filtered = _leads;

    // Apply date filter if provided
    if (date != null) {
      filtered =
          filtered.where((lead) {
            final leadDate = lead.createdAt;
            return leadDate.year == date.year &&
                leadDate.month == date.month &&
                leadDate.day == date.day;
          }).toList();
    }

    // Apply store filter
    if (store == null || store == 'All Stores') return filtered;
    // Extract location from "Brand - Location" format, or use as-is if already a location
    final location =
        store.contains(' - ')
            ? StoreLocations.resolveSelection(store).location
            : store;
    return filtered.where((lead) => lead.location == location).toList();
  }

  List<LeadModel> getLeadsByDate(DateTime date) {
    // Filter leads by selected date only
    return _leads.where((lead) {
      final leadDate = lead.createdAt;
      return leadDate.year == date.year &&
          leadDate.month == date.month &&
          leadDate.day == date.day;
    }).toList();
  }

  /// Get leads within a date range (inclusive)
  List<LeadModel> getLeadsByDateRange(DateTime startDate, DateTime endDate) {
    // Normalize dates to start of day for comparison
    final start = DateTime.utc(startDate.year, startDate.month, startDate.day);
    final end = DateTime.utc(endDate.year, endDate.month, endDate.day);
    
    return _leads.where((lead) {
      final leadDate = lead.createdAt;
      final normalizedLeadDate = DateTime.utc(leadDate.year, leadDate.month, leadDate.day);
      // Check if lead date is within range (inclusive)
      return normalizedLeadDate.compareTo(start) >= 0 && 
             normalizedLeadDate.compareTo(end) <= 0;
    }).toList();
  }

  List<LeadModel> getLeadsByStoreAndDate(String? store, DateTime date) {
    // Apply store filter first
    List<LeadModel> baseList = _leads;

    if (store != null && store != 'All Stores') {
      final location =
          store.contains(' - ')
              ? StoreLocations.resolveSelection(store).location
              : store;

      baseList = baseList.where((lead) => lead.location == location).toList();
    }

    // Apply date filter to show only selected date
    return baseList.where((lead) {
      final leadDate = lead.createdAt;
      return leadDate.year == date.year &&
          leadDate.month == date.month &&
          leadDate.day == date.day;
    }).toList();
  }

  int getCountByCategory(String category, {String? store, DateTime? date}) {
    List<LeadModel> filtered = _leads;

    if (date != null) {
      filtered =
          filtered.where((lead) {
            final leadDate = lead.createdAt;
            return leadDate.year == date.year &&
                leadDate.month == date.month &&
                leadDate.day == date.day;
          }).toList();
    }

    if (store != null && store != 'All Stores') {
      // Extract location from "Brand - Location" format, or use as-is if already a location
      final location =
          store.contains(' - ')
              ? StoreLocations.resolveSelection(store).location
              : store;
      filtered = filtered.where((lead) => lead.location == location).toList();
    }

    return filtered.where((lead) => lead.category == category).length;
  }

  int getCountByCallStatus(String callStatus, {String? store, DateTime? date}) {
    List<LeadModel> filtered = _leads;

    if (date != null) {
      filtered =
          filtered.where((lead) {
            final leadDate = lead.createdAt;
            return leadDate.year == date.year &&
                leadDate.month == date.month &&
                leadDate.day == date.day;
          }).toList();
    }

    if (store != null && store != 'All Stores') {
      // Extract location from "Brand - Location" format, or use as-is if already a location
      final location =
          store.contains(' - ')
              ? StoreLocations.resolveSelection(store).location
              : store;
      filtered = filtered.where((lead) => lead.location == location).toList();
    }

    return filtered.where((lead) => lead.callStatus == callStatus).length;
  }

  int getTotalLeadsCount({String? store, DateTime? date}) {
    List<LeadModel> filtered = _leads;

    if (date != null) {
      filtered =
          filtered.where((lead) {
            final leadDate = lead.createdAt;
            return leadDate.year == date.year &&
                leadDate.month == date.month &&
                leadDate.day == date.day;
          }).toList();
    }

    if (store != null && store != 'All Stores') {
      // Extract location from "Brand - Location" format, or use as-is if already a location
      final location =
          store.contains(' - ')
              ? StoreLocations.resolveSelection(store).location
              : store;
      filtered = filtered.where((lead) => lead.location == location).toList();
    }

    return filtered.length;
  }

  int get totalLeadsCount => _leads.length;

  int getFollowUpLeadsCount({String? store, DateTime? date}) {
    List<LeadModel> filtered =
        _leads.where((lead) => lead.needsFollowUp).toList();

    if (date != null) {
      filtered =
          filtered.where((lead) {
            final leadDate = lead.createdAt;
            return leadDate.year == date.year &&
                leadDate.month == date.month &&
                leadDate.day == date.day;
          }).toList();
    }

    if (store != null && store != 'All Stores') {
      // Extract location from "Brand - Location" format, or use as-is if already a location
      final location =
          store.contains(' - ')
              ? StoreLocations.resolveSelection(store).location
              : store;
      filtered = filtered.where((lead) => lead.location == location).toList();
    }

    return filtered.length;
  }

  // ========== Storage Operations ==========

  /// Force reload leads from SharedPreferences storage
  Future<void> forceReloadFromStorage() async {
    await _loadLeads();
    notifyListeners();
  }

  /// Debug method to check data integrity
  void debugDataIntegrity() {
    print('LeadRepository: Total leads: ${_leads.length}');
    print('LeadRepository: Follow-up leads: ${followUpLeads.length}');
    print('LeadRepository: Today follow-ups: ${todayFollowUps.length}');
    print('LeadRepository: Upcoming follow-ups: ${upcomingFollowUps.length}');
    print('LeadRepository: Overdue follow-ups: ${overdueFollowUps.length}');
  }

  // ========== API Integration ==========

  /// Fetch Booking Confirmation leads from API and sync with repository
  /// This will replace existing booking confirmation leads with fresh data from API
  Future<void> fetchBookingConfirmationLeadsFromApi({String? store}) async {
    try {
      await ensureInitialized();

      // Pass store in "Brand - Location" format (e.g., "Suitor Guy - Edappal")
      final storeFilter =
          (store == null || store == 'All Stores') ? null : store;
      final response = await _apiService.getBookingConfirmationLeads(
        store: storeFilter,
      );

      // Parse response - handle different response formats
      List<dynamic> leadsData = [];

      if (response.containsKey('data')) {
        final data = response['data'];
        if (data is List) {
          leadsData = data;
        } else if (data is Map<String, dynamic> && data.containsKey('leads')) {
          final leads = data['leads'];
          if (leads is List) {
            leadsData = leads;
          }
        }
      } else if (response.containsKey('leads')) {
        final leads = response['leads'];
        if (leads is List) {
          leadsData = leads;
        }
      } else if (response.containsKey('results')) {
        final results = response['results'];
        if (results is List) {
          leadsData = results;
        }
      } else {
        // If no recognized key, check if any value is a list
        for (var entry in response.entries) {
          if (entry.value is List) {
            leadsData = entry.value as List;
            break;
          }
        }
      }

      // Remove existing booking confirmation leads (to avoid duplicates)
      // Remove existing booking confirmation leads (to avoid duplicates)
      // BUT: Preserve booking confirmation leads that have follow-up dates set
      _leads.removeWhere(
        (lead) =>
            lead.category == LeadConstants.categoryBookingConfirmation &&
            !lead.needsFollowUp, // Keep if it has follow-up date
      );

      // Convert API data to LeadModel and add to repository
      int failedCount = 0;

      for (var leadData in leadsData) {
        try {
          final lead = _parseApiLeadToLeadModel(leadData);
          if (lead != null) {
            // Ensure category is set to Booking Confirmation
            final bookingLead = LeadModel(
              id: lead.id,
              name: lead.name,
              phone: lead.phone,
              brand: lead.brand,
              location: lead.location,
              leadStatus: lead.leadStatus,
              callStatus: lead.callStatus,
              followUpDate: lead.followUpDate,
              reason: lead.reason,
              category: LeadConstants.categoryBookingConfirmation,
              callDuration: lead.callDuration,
              createdAt: lead.createdAt,
            );
            _leads.add(bookingLead);

            // Store booking confirmation specific data
            final bookingNumber =
                leadData['booking_number']?.toString() ??
                leadData['bookingNumber']?.toString() ??
                '';
            final enquiryDate =
                leadData['enquiry_date']?.toString() ??
                leadData['enquiryDate']?.toString();
            final functionDate =
                leadData['function_date']?.toString() ??
                leadData['functionDate']?.toString();
            final securityAmount =
                leadData['security_amount']?.toString() ??
                leadData['securityAmount']?.toString();

            _bookingConfirmationData[lead.id] = {
              'bookingNumber': bookingNumber,
              'enquiryDate': enquiryDate,
              'functionDate': functionDate,
              'securityAmount': securityAmount,
            };
          } else {
            failedCount++;
          }
        } catch (e) {
          failedCount++;
          print('LeadRepository: Error parsing booking confirmation lead: $e');
        }
      }

      if (failedCount > 0) {
        print(
          'LeadRepository: Failed to parse $failedCount booking confirmation leads',
        );
      }

      await _saveLeads();
    } catch (e) {
      print('LeadRepository: Error fetching Booking Confirmation leads: $e');
      rethrow;
    }
  }

  /// Fetch Loss of Sale leads from API and sync with repository
  /// This will replace existing loss of sale leads with fresh data from API
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
      await ensureInitialized();

      final response = await _apiService.getLossOfSaleLeads(
        store: store,
        enquiryFrom: enquiryFrom,
        enquiryTo: enquiryTo,
        functionFrom: functionFrom,
        functionTo: functionTo,
        visitFrom: visitFrom,
        visitTo: visitTo,
      );

      // Parse response - handle different response formats
      List<dynamic> leadsData = [];

      if (response.containsKey('data')) {
        final data = response['data'];
        if (data is List) {
          leadsData = data;
        } else if (data is Map<String, dynamic> && data.containsKey('leads')) {
          final leads = data['leads'];
          if (leads is List) {
            leadsData = leads;
          }
        }
      } else if (response.containsKey('leads')) {
        final leads = response['leads'];
        if (leads is List) {
          leadsData = leads;
        }
      } else if (response.containsKey('results')) {
        final results = response['results'];
        if (results is List) {
          leadsData = results;
        }
      } else {
        // If no recognized key, check if any value is a list
        for (var entry in response.entries) {
          if (entry.value is List) {
            leadsData = entry.value as List;
            break;
          }
        }
      }

      // Remove existing loss of sale leads (to avoid duplicates)
      // BUT: Preserve loss of sale leads that have follow-up dates set
      _leads.removeWhere(
        (lead) =>
            lead.category == LeadConstants.categoryLossOfSales &&
            !lead.needsFollowUp, // Keep if it has follow-up date
      );

      // Convert API data to LeadModel and add to repository
      int failedCount = 0;

      for (var leadData in leadsData) {
        try {
          final lead = _parseApiLeadToLeadModel(leadData);
          if (lead != null) {
            _leads.add(lead);
          } else {
            failedCount++;
          }
        } catch (e) {
          failedCount++;
          print('LeadRepository: Error parsing lead: $e');
        }
      }

      if (failedCount > 0) {
        print('LeadRepository: Failed to parse $failedCount leads');
      }

      await _saveLeads();
    } catch (e) {
      print('LeadRepository: Error fetching Loss of Sale leads: $e');
      rethrow;
    }
  }

  /// Parse date string from API - handles multiple date formats
  DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;

    final dateStr = dateValue.toString().trim();
    if (dateStr.isEmpty) return null;

    // List of common date formats to try
    final dateFormats = [
      'yyyy-MM-dd', // 2024-01-15
      'yyyy-MM-ddTHH:mm:ss', // 2024-01-15T10:30:00
      'yyyy-MM-ddTHH:mm:ssZ', // 2024-01-15T10:30:00Z
      'yyyy-MM-ddTHH:mm:ss.SSSZ', // 2024-01-15T10:30:00.000Z
      'yyyy-MM-dd HH:mm:ss', // 2024-01-15 10:30:00
      'yyyy/MM/dd', // 2024/01/15
      'dd-MM-yyyy', // 15-01-2024
      'dd/MM/yyyy', // 15/01/2024
      'MM/dd/yyyy', // 01/15/2024
    ];

    // First try DateTime.parse (handles ISO 8601 and most standard formats)
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      // If standard parse fails, try custom formats
      for (final format in dateFormats) {
        try {
          // For simple date formats like yyyy-MM-dd, we need to handle them manually
          if (format == 'yyyy-MM-dd') {
            final parts = dateStr.split('-');
            if (parts.length == 3) {
              final year = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final day = int.parse(parts[2]);
              return DateTime(year, month, day);
            }
          } else if (format == 'yyyy/MM/dd') {
            final parts = dateStr.split('/');
            if (parts.length == 3) {
              final year = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final day = int.parse(parts[2]);
              return DateTime(year, month, day);
            }
          } else if (format == 'dd-MM-yyyy') {
            final parts = dateStr.split('-');
            if (parts.length == 3) {
              final day = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final year = int.parse(parts[2]);
              return DateTime(year, month, day);
            }
          } else if (format == 'dd/MM/yyyy') {
            final parts = dateStr.split('/');
            if (parts.length == 3) {
              final day = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final year = int.parse(parts[2]);
              return DateTime(year, month, day);
            }
          } else if (format == 'MM/dd/yyyy') {
            final parts = dateStr.split('/');
            if (parts.length == 3) {
              final month = int.parse(parts[0]);
              final day = int.parse(parts[1]);
              final year = int.parse(parts[2]);
              return DateTime(year, month, day);
            }
          }
        } catch (e) {
          // Continue to next format
          continue;
        }
      }

      return null;
    }
  }

  /// Parse API lead data to LeadModel
  /// Handles different possible API response formats
  LeadModel? _parseApiLeadToLeadModel(dynamic leadData) {
    try {
      if (leadData is! Map<String, dynamic>) {
        return null;
      }

      // Extract fields from API response
      // Backend uses: lead_name, phone_number, store, lead_type, call_status, lead_status, enquiry_date, function_date
      final id =
          leadData['id']?.toString() ??
          leadData['_id']?.toString() ??
          leadData['leadId']?.toString() ??
          leadData['lead_id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final name =
          leadData['lead_name']?.toString() ?? // Backend field name
          leadData['name']?.toString() ??
          leadData['customerName']?.toString() ??
          leadData['customer_name']?.toString() ??
          leadData['customer']?.toString() ??
          leadData['clientName']?.toString() ??
          '';
      final phone =
          leadData['phone_number']?.toString() ?? // Backend field name
          leadData['phone']?.toString() ??
          leadData['phoneNumber']?.toString() ??
          leadData['mobile']?.toString() ??
          leadData['contactNumber']?.toString() ??
          leadData['contact']?.toString() ??
          '';
      final brand = leadData['brand']?.toString();
      // Backend uses 'store' field directly (e.g., "Zurocci - Perinthalmanna")
      final location =
          leadData['store']?.toString() ?? // Backend field name
          leadData['location']?.toString();
      final leadStatus =
          leadData['lead_status']?.toString() ?? // Backend field name
          leadData['leadStatus']?.toString();
      final callStatus =
          leadData['call_status']?.toString() ?? // Backend field name
          leadData['callStatus']?.toString() ??
          LeadConstants.callStatusNotCalled;
      final reason = leadData['reason']?.toString();
      final callDuration =
          leadData['callDuration'] as int? ?? leadData['call_duration'] as int?;

      // Parse dates using the helper function that handles multiple formats
      // Backend uses: enquiry_date, function_date, created_at
      DateTime? followUpDate =
          _parseDate(leadData['followUpDate']) ??
          _parseDate(leadData['follow_up_date']) ??
          _parseDate(leadData['followUp']) ??
          _parseDate(leadData['follow_up']);

      DateTime createdAt = DateTime.now();
      // Backend uses enquiry_date as the main date field
      final parsedCreatedAt =
          _parseDate(leadData['created_at']) ??
          _parseDate(leadData['enquiry_date']) ??
          _parseDate(leadData['enquiryDate']) ??
          _parseDate(leadData['visit_date']) ??
          _parseDate(leadData['visitDate']) ??
          DateTime.now();

      // _parseDate(
      //   leadData['enquiry_date'],
      // ) ??
      // Backend field name (primary)
      // _parseDate(leadData['created_at']) ?? // Backend field name
      // _parseDate(leadData['enquiryDate']) ??
      // _parseDate(leadData['createdAt']) ??
      // _parseDate(leadData['date']) ??
      // _parseDate(leadData['leadDate']) ??
      // _parseDate(leadData['lead_date']);

      createdAt = parsedCreatedAt;

      // Validate required fields
      if (name.isEmpty || phone.isEmpty) {
        return null;
      }

      // Determine category - backend uses lead_type field
      String? category; // Default to null (will show in "All Calls" tab)
      if (leadData['lead_type'] != null) {
        final leadType = leadData['lead_type'].toString().toLowerCase();
        if (leadType == 'lossofsale' || leadType == 'loss of sale') {
          category = LeadConstants.categoryLossOfSales;
        } else if (leadType == 'rentout' ||
            leadType == 'rent out' ||
            leadType == 'rentoutfeedback' ||
            leadType == 'return') {
          category = LeadConstants.categoryRentOut;
        } else if (leadType == 'bookingconfirmation' ||
            leadType == 'booking confirmation') {
          category = LeadConstants.categoryBookingConfirmation;
        } else if (leadType == 'justdial' || leadType == 'just dial') {
          category = LeadConstants.categoryJustDial;
        } else if (leadType == 'followup' || leadType == 'follow up') {
          category = LeadConstants.categoryFollowUp;
        } else if (leadType == 'general' ||
            leadType == 'walkin' ||
            leadType == 'walk-in') {
          // General/Walk-in leads don't have a specific category - show in "All Calls"
          category = null;
        }
        // If leadType doesn't match any known type, category remains null
      }

      // if (leadData['lead_type'] != null) {
      //   final leadType = leadData['lead_type'].toString().toLowerCase();
      //   if (leadType == 'lossofsale' || leadType == 'loss of sale') {
      //     category = LeadConstants.categoryLossOfSales;
      //   } else if (leadType == 'rentout' || leadType == 'rent out') {
      //     category = LeadConstants.categoryRentOut;
      //   } else if (leadType == 'bookingconfirmation' ||
      //       leadType == 'booking confirmation') {
      //     category = LeadConstants.categoryBookingConfirmation;
      //   } else if (leadType == 'justdial' || leadType == 'just dial') {
      //     category = LeadConstants.categoryJustDial;
      //   } else if (leadType == 'followup' || leadType == 'follow up') {
      //     category = LeadConstants.categoryFollowUp;
      //   }
      // }

      return LeadModel(
        id: id,
        name: name,
        phone: phone,
        brand: brand,
        location: location,
        leadStatus: leadStatus,
        callStatus: callStatus,
        followUpDate: followUpDate,
        reason: reason,
        category: category,
        callDuration: callDuration,
        createdAt: createdAt,
      );
    } catch (e) {
      print('Error parsing API lead: $e');
      return null;
    }
  }

  /// Fetch Return leads from API and sync with repository
  /// This will replace existing return leads with fresh data from API
  Future<void> fetchReturnLeadsFromApi({String? store}) async {
    try {
      await ensureInitialized();

      // Pass store in "Brand - Location" format (e.g., "Suitor Guy - Edappal")
      final storeFilter =
          (store == null || store == 'All Stores') ? null : store;
      final response = await _apiService.getReturnLeads(store: storeFilter);

      // Parse response - handle different response formats
      List<dynamic> leadsData = [];

      if (response.containsKey('data')) {
        final data = response['data'];
        if (data is List) {
          leadsData = data;
        } else if (data is Map<String, dynamic> && data.containsKey('leads')) {
          final leads = data['leads'];
          if (leads is List) {
            leadsData = leads;
          }
        }
      } else if (response.containsKey('leads')) {
        final leads = response['leads'];
        if (leads is List) {
          leadsData = leads;
        }
      } else if (response.containsKey('results')) {
        final results = response['results'];
        if (results is List) {
          leadsData = results;
        }
      } else {
        // Fallback: take first list in map
        for (var entry in response.entries) {
          if (entry.value is List) {
            leadsData = entry.value as List;
            break;
          }
        }
      }

      // Remove existing return leads (to avoid duplicates)
      // BUT: Preserve return leads that have follow-up dates set
      _leads.removeWhere(
        (lead) =>
            lead.category == LeadConstants.categoryRentOut &&
            !lead.needsFollowUp, // Keep if it has follow-up date
      );

      int failedCount = 0;

      for (var leadData in leadsData) {
        try {
          final lead = _parseApiLeadToLeadModel(leadData);
          if (lead != null) {
            // Ensure category is Return
            final returnLead = LeadModel(
              id: lead.id,
              name: lead.name,
              phone: lead.phone,
              brand: lead.brand,
              location: lead.location,
              leadStatus: lead.leadStatus,
              callStatus: lead.callStatus,
              followUpDate: lead.followUpDate,
              reason: lead.reason,
              category: LeadConstants.categoryRentOut,
              callDuration: lead.callDuration,
              createdAt: lead.createdAt,
            );
            _leads.add(returnLead);
          } else {
            failedCount++;
          }
        } catch (e) {
          failedCount++;
          print('LeadRepository: Error parsing Return lead: $e');
        }
      }

      if (failedCount > 0) {
        print('LeadRepository: Failed to parse $failedCount Return leads');
      }

      await _saveLeads();
    } catch (e) {
      print('LeadRepository: Error fetching Return leads: $e');
      rethrow;
    }
  }

  /// Update Loss of Sale lead via API
  Future<void> updateLossOfSaleLeadFromApi({
    required String id,
    String? callStatus,
    String? leadStatus,
    DateTime? followUpDate,
    String? reasonCollectedFromStore,
    String? remarks,
  }) async {
    try {
      await ensureInitialized();

      // Convert DateTime to ISO 8601 string format if provided
      String? followUpDateString;
      if (followUpDate != null) {
        followUpDateString = followUpDate.toIso8601String();
      }

      await _apiService.updateLossOfSaleLead(
        id: id,
        callStatus: callStatus,
        leadStatus: leadStatus,
        followUpDate: followUpDateString,
        reasonCollectedFromStore: reasonCollectedFromStore,
        remarks: remarks,
      );

      // Update local lead if it exists
      final lead = getLeadById(id);
      if (lead != null) {
        final updatedLead = LeadModel(
          id: lead.id,
          name: lead.name,
          phone: lead.phone,
          brand: lead.brand,
          location: lead.location,
          leadStatus: leadStatus ?? lead.leadStatus,
          callStatus: callStatus ?? lead.callStatus,
          followUpDate: followUpDate ?? lead.followUpDate,
          reason: reasonCollectedFromStore ?? lead.reason,
          category: lead.category,
          callDuration: lead.callDuration,
          createdAt: lead.createdAt,
        );
        await updateLead(updatedLead);
      }
    } catch (e) {
      print('LeadRepository: Error updating Loss of Sale lead: $e');
      rethrow;
    }
  }

  /// Update Return lead via API
  Future<void> updateReturnLeadFromApi({
    required String id,
    String? callStatus,
    String? leadStatus,
    bool? followUpFlag,
    DateTime? callDate,
    int? rating,
    String? remarks,
    int? callDuration,
    DateTime? followUpDate,
    bool? clearFollowUpDate,
  }) async {
    try {
      await ensureInitialized();

      await _apiService.updateReturnLead(
        id: id,
        callStatus: callStatus,
        leadStatus: leadStatus,
        followUpFlag: followUpFlag,
        callDate: callDate,
        rating: rating,
        remarks: remarks,
        callDuration: callDuration,
        followUpDate: followUpDate,
        clearFollowUpDate: clearFollowUpDate,
      );

      // Update local lead if it exists
      final lead = getLeadById(id);
      if (lead != null) {
        final updatedLead = LeadModel(
          id: lead.id,
          name: lead.name,
          phone: lead.phone,
          brand: lead.brand,
          location: lead.location,
          leadStatus: leadStatus ?? lead.leadStatus,
          callStatus: callStatus ?? lead.callStatus,
          followUpDate:
              followUpFlag == true
                  ? (followUpDate ?? callDate)
                  : (followUpFlag == false || clearFollowUpDate == true
                      ? null
                      : lead.followUpDate),
          reason: remarks ?? lead.reason,
          category: lead.category,
          callDuration: callDuration ?? lead.callDuration,
          createdAt: lead.createdAt,
        );
        await updateLead(updatedLead);
      }
    } catch (e) {
      print('LeadRepository: Error updating Return lead: $e');
      rethrow;
    }
  }

  /// Update Booking Confirmation lead via API
  Future<void> updateBookingConfirmationLeadFromApi({
    required String id,
    String? callStatus,
    String? leadStatus,
    bool? followUpFlag,
    DateTime? callDate,
    String? remarks,
    int? callDuration,
  }) async {
    try {
      await ensureInitialized();

      await _apiService.updateBookingConfirmationLead(
        id: id,
        callStatus: callStatus,
        leadStatus: leadStatus,
        followUpFlag: followUpFlag,
        callDate: callDate,
        remarks: remarks,
        callDuration: callDuration,
      );

      // Update local lead if it exists
      final lead = getLeadById(id);
      if (lead != null) {
        final updatedLead = LeadModel(
          id: lead.id,
          name: lead.name,
          phone: lead.phone,
          brand: lead.brand,
          location: lead.location,
          leadStatus: leadStatus ?? lead.leadStatus,
          callStatus: callStatus ?? lead.callStatus,
          followUpDate:
              followUpFlag == true
                  ? callDate
                  : (followUpFlag == false ? null : lead.followUpDate),
          reason: remarks ?? lead.reason,
          category: lead.category,
          callDuration: callDuration ?? lead.callDuration,
          createdAt: lead.createdAt,
        );
        await updateLead(updatedLead);
      }
    } catch (e) {
      print('LeadRepository: Error updating Booking Confirmation lead: $e');
      rethrow;
    }
  }

  /// Fetch Follow-Up leads from API and sync with repository
  Future<void> fetchFollowUpLeadsFromApi({String? store}) async {
    try {
      await ensureInitialized();

      // Pass store in "Brand - Location" format (e.g., "Suitor Guy - Edappal")
      final storeFilter =
          (store == null || store == 'All Stores') ? null : store;
      final response = await _apiService.getFollowUpLeads(store: storeFilter);

      // Parse response - handle different response formats
      List<dynamic> leadsData = [];

      if (response.containsKey('data')) {
        final data = response['data'];
        if (data is List) {
          leadsData = data;
        } else if (data is Map<String, dynamic> && data.containsKey('leads')) {
          final leads = data['leads'];
          if (leads is List) {
            leadsData = leads;
          }
        }
      } else if (response.containsKey('leads')) {
        final leads = response['leads'];
        if (leads is List) {
          leadsData = leads;
        }
      } else if (response.containsKey('results')) {
        final results = response['results'];
        if (results is List) {
          leadsData = results;
        }
      } else {
        // If no recognized key, check if any value is a list
        for (var entry in response.entries) {
          if (entry.value is List) {
            leadsData = entry.value as List;
            break;
          }
        }
      }

      // Debug: Log current state before fetch
      final leadsBeforeFetch = _leads.length;
      final followUpLeadsBeforeFetch = _leads
          .where((lead) => lead.category == LeadConstants.categoryFollowUp)
          .length;
      print(
        'LeadRepository: Before fetch - Total leads: $leadsBeforeFetch, Follow-up leads: $followUpLeadsBeforeFetch',
      );

      // Extract all IDs and phone numbers from API response to identify which leads to replace
      final apiLeadIds = <String>{};
      final apiPhoneNumbers = <String>{};
      for (var leadData in leadsData) {
        try {
          final id = leadData['id']?.toString() ?? leadData['_id']?.toString();
          if (id != null && id.isNotEmpty) {
            apiLeadIds.add(id);
          }
          // Also extract phone number to match leads that were moved to follow-up
          // (backend creates new lead with new ID, but same phone number)
          final phone = leadData['phone_number']?.toString() ?? 
                       leadData['phone']?.toString() ?? 
                       leadData['phoneNumber']?.toString();
          if (phone != null && phone.isNotEmpty) {
            apiPhoneNumbers.add(phone.trim());
          }
        } catch (e) {
          // Ignore parsing errors for ID/phone extraction
        }
      }

      print(
        'LeadRepository: API returned ${leadsData.length} leads with ${apiLeadIds.length} unique IDs and ${apiPhoneNumbers.length} unique phone numbers',
      );

      // Remove ALL existing follow-up leads to prevent duplicates
      // Strategy: Remove leads that:
      // 1. Have category == "Follow Up", OR
      // 2. Have an ID matching any ID from the API response, OR
      // 3. Have a phone number matching any phone number from the API response
      // This ensures that if a lead was moved to follow-up (backend creates new lead with new ID),
      // the original lead with the same phone number is removed
      final removedCount = _leads.length;
      _leads.removeWhere(
        (lead) =>
            lead.category == LeadConstants.categoryFollowUp ||
            apiLeadIds.contains(lead.id) ||
            (lead.phone.isNotEmpty && apiPhoneNumbers.contains(lead.phone.trim())),
      );
      final actuallyRemoved = removedCount - _leads.length;
      print(
        'LeadRepository: Removed $actuallyRemoved existing leads (category match, ID match, or phone number match)',
      );

      // Convert API data to LeadModel and add to repository
      int addedCount = 0;
      int failedCount = 0;

      for (var leadData in leadsData) {
        try {
          final lead = _parseApiLeadToLeadModel(leadData);
          if (lead != null) {
            // Ensure category is set to Follow-Up
            final followUpLead = LeadModel(
              id: lead.id,
              name: lead.name,
              phone: lead.phone,
              brand: lead.brand,
              location: lead.location,
              leadStatus: lead.leadStatus,
              callStatus: lead.callStatus,
              followUpDate: lead.followUpDate,
              reason: lead.reason,
              category: LeadConstants.categoryFollowUp,
              callDuration: lead.callDuration,
              createdAt: lead.createdAt,
            );
            _leads.add(followUpLead);
            addedCount++;
          } else {
            failedCount++;
          }
        } catch (e) {
          failedCount++;
          print('LeadRepository: Error parsing follow-up lead: $e');
        }
      }

      // Debug: Log final state after fetch
      final leadsAfterFetch = _leads.length;
      final followUpLeadsAfterFetch = _leads
          .where((lead) => lead.category == LeadConstants.categoryFollowUp)
          .length;
      print(
        'LeadRepository: After fetch - Total leads: $leadsAfterFetch, Follow-up leads: $followUpLeadsAfterFetch',
      );
      print(
        'LeadRepository: Added $addedCount new follow-up leads, failed to parse $failedCount',
      );

      if (failedCount > 0) {
        print('LeadRepository: Failed to parse $failedCount follow-up leads');
      }

      await _saveLeads();
      notifyListeners();
    } catch (e) {
      print('LeadRepository: Error fetching Follow-Up leads: $e');
      rethrow;
    }
  }

  /// Update Follow-Up lead via API
  Future<void> updateFollowUpLeadFromApi({
    required String id,
    String? callStatus,
    String? leadStatus,
    String? remarks,
    int? callDuration,
    DateTime? followUpDate,
    required bool clearFollowUpDate,
  }) async {
    try {
      await ensureInitialized();

      await _apiService.postFollowUp(
        id: id,
        callStatus: callStatus ?? LeadConstants.callStatusNotCalled,
        leadStatus: leadStatus ?? 'No Status',
        remarks: remarks,
        callDuration: callDuration,
        followUpDate: followUpDate,
        clearFollowUpDate: clearFollowUpDate,
      );

      // Update local lead if it exists
      final lead = getLeadById(id);
      if (lead != null) {
        final updatedLead = LeadModel(
          id: lead.id,
          name: lead.name,
          phone: lead.phone,
          brand: lead.brand,
          location: lead.location,
          leadStatus: leadStatus ?? lead.leadStatus,
          callStatus: callStatus ?? lead.callStatus,
          followUpDate:
              clearFollowUpDate ? null : (followUpDate ?? lead.followUpDate),
          reason: remarks ?? lead.reason,
          category: lead.category,
          callDuration: callDuration ?? lead.callDuration,
          createdAt: lead.createdAt,
        );
        await updateLead(updatedLead);
      }
    } catch (e) {
      print('LeadRepository: Error updating Follow-Up lead: $e');
      rethrow;
    }
  }

  /// Fetch all leads from API and sync with repository
  /// This will fetch all leads (across all categories) with pagination, store filter, and date filter support
  Future<void> fetchAllLeadsFromApi({
    String? store,
    int? page,
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
      await ensureInitialized();

      // Pass store in "Brand - Location" format (e.g., "Suitor Guy - Edappal")
      final storeFilter =
          (store == null || store == 'All Stores') ? null : store;
      final response = await _apiService.getAllLeads(
        store: storeFilter,
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
        createdAt: createdAt,
      );

      // Parse response - handle different response formats
      List<dynamic> leadsData = [];

      if (response.containsKey('data')) {
        final data = response['data'];
        if (data is List) {
          leadsData = data;
        } else if (data is Map<String, dynamic> && data.containsKey('leads')) {
          final leads = data['leads'];
          if (leads is List) {
            leadsData = leads;
          }
        }
      } else if (response.containsKey('leads')) {
        final leads = response['leads'];
        if (leads is List) {
          leadsData = leads;
        }
      } else if (response.containsKey('results')) {
        final results = response['results'];
        if (results is List) {
          leadsData = results;
        }
      } else {
        // If no recognized key, check if any value is a list
        for (var entry in response.entries) {
          if (entry.value is List) {
            leadsData = entry.value as List;
            break;
          }
        }
      }

      // Debug: Print how many leads were received
      print('LeadRepository: Received ${leadsData.length} leads from API');

      // If page is specified, we might want to merge/update existing leads
      // Otherwise, replace all leads with fresh data from API
      // BUT: Preserve called leads and follow-up leads so they remain available for reports screen
      // EXCEPT: Don't preserve called return leads or booking confirmation leads (they've been moved to reports)
      if (page == null || page == 1) {
        // Store called leads and follow-up leads before clearing
        // Exclude called return leads and booking confirmation leads (moved to reports)
        final preservedLeads =
            _leads
                .where(
                  (lead) {
                    final isReturnLead = lead.category == LeadConstants.categoryRentOut;
                    final isBookingConfirmationLead = lead.category == LeadConstants.categoryBookingConfirmation;
                    final isCalled = LeadConstants.isCalledStatus(lead.callStatus);

                    // Don't preserve called return leads or booking confirmation leads
                    if ((isReturnLead || isBookingConfirmationLead) && isCalled) {
                      return false;
                    }

                    // Preserve other called leads and follow-up leads
                    return isCalled || lead.needsFollowUp;
                  },
                )
                .toList();

        print(
          'LeadRepository: Preserving ${preservedLeads.length} called/follow-up leads before refresh (excluding called return/booking confirmation leads)',
        );

        _leads.clear();

        // Restore called leads and follow-up leads so they remain available for reports
        _leads.addAll(preservedLeads);
      }

      // Convert API data to LeadModel and add to repository
      int failedCount = 0;
      int skippedCalledCount = 0;

      for (var leadData in leadsData) {
        try {
          final lead = _parseApiLeadToLeadModel(leadData);
          if (lead != null) {
            // Skip return leads and booking confirmation leads that have been called
            // These leads have been moved to reports and should not appear in the leads list
            final isReturnLead = lead.category == LeadConstants.categoryRentOut;
            final isBookingConfirmationLead = lead.category == LeadConstants.categoryBookingConfirmation;
            final isCalled = LeadConstants.isCalledStatus(lead.callStatus);

            if ((isReturnLead || isBookingConfirmationLead) && isCalled) {
              skippedCalledCount++;
              print('LeadRepository: Skipping called ${lead.category} lead: ${lead.name} (${lead.phone}) - moved to reports');
              continue;
            }

            // Check if lead already exists (by ID) to avoid duplicates
            final existingIndex = _leads.indexWhere((l) => l.id == lead.id);
            if (existingIndex != -1) {
              // Update existing lead
              _leads[existingIndex] = lead;
            } else {
              // Add new lead
              _leads.add(lead);
            }
          } else {
            failedCount++;
          }
        } catch (e) {
          failedCount++;
          print('LeadRepository: Error parsing lead: $e');
        }
      }

      if (skippedCalledCount > 0) {
        print('LeadRepository: Skipped $skippedCalledCount called return/booking confirmation leads (moved to reports)');
      }

      if (failedCount > 0) {
        print('LeadRepository: Failed to parse $failedCount leads');
      }

      print(
        'LeadRepository: Successfully added ${_leads.length} leads to repository',
      );
      print(
        'LeadRepository: Sample lead - name: ${_leads.isNotEmpty ? _leads.first.name : "none"}, location: ${_leads.isNotEmpty ? _leads.first.location : "none"}, category: ${_leads.isNotEmpty ? _leads.first.category : "none"}',
      );

      await _saveLeads();
      notifyListeners();
    } catch (e) {
      print('LeadRepository: Error fetching all leads: $e');
      rethrow;
    }
  }

  /// Move a lead to report screen (remove from active leads)
  Future<void> moveToReport(String id) async {
    try {
      await ensureInitialized();

      // Find the lead to move
      final leadIndex = _leads.indexWhere((lead) => lead.id == id);
      if (leadIndex == -1) {
        print('LeadRepository: Lead with id $id not found');
        return;
      }

      final lead = _leads[leadIndex];
      print(
        'LeadRepository: Moving lead to report - ID: $id, Name: ${lead.name}, Category: ${lead.category}',
      );

      // Remove the lead from active leads list
      _leads.removeAt(leadIndex);

      // Save the updated leads list
      await _saveLeads();

      // Notify listeners that the lead has been moved
      notifyListeners();

      print('LeadRepository: Successfully moved lead $id to report screen');
    } catch (e) {
      print('LeadRepository: Error moving lead to report: $e');
      rethrow;
    }
  }

  // ========== API Call Summary ==========

  /// Fetch call summary from API
  Future<Map<String, dynamic>> fetchCallSummaryFromApi({
    String? store,
    DateTime? date,
  }) async {
    try {
      // Format date for API (YYYY-MM-DD)
      String? dateStr;
      if (date != null) {
        dateStr =
            '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}';
      }

      final response = await _apiService.getCallSummary(
        store: store,
        date: dateStr,
      );

      return response;
    } catch (e) {
      print('LeadRepository: Error fetching call summary from API: $e');
      rethrow;
    }
  }
}
