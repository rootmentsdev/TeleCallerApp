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
      // Silently handle initialization errors
    });
  }

  /// Force reload data from SharedPreferences
  /// This should be called after login to ensure data is properly loaded
  Future<void> forceReloadFromStorage() async {
    await _loadLeads();
    notifyListeners();
  }

  /// Debug method to check data integrity
  Future<void> debugDataIntegrity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final leadsJson = prefs.getString(_storageKey);
      if (leadsJson != null && leadsJson.isNotEmpty) {
        try {
          json.decode(leadsJson);
        } catch (e) {}
      }
    } catch (e) {}
  }

  final List<LeadModel> _leads = [];
  final List<LeadModel> _followUpLeads = []; // Leads from /api/pages/follow-ups
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
        return false;
      });
    }
    return List.unmodifiable(_leads);
  }

  // Backend-driven: Returns follow-up leads fetched from /api/pages/follow-ups
  // Only includes leads that backend returned from the follow-ups collection
  // When a lead is completed, backend removes it from this collection
  List<LeadModel> get followUpLeads {
    return _followUpLeads;
  }

  // Note: Follow-up leads are fetched from backend via fetchFollowUpLeadsFromApi()
  // Frontend should not filter locally - backend manages FollowUps collection

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
        notifyListeners();
      } else {
        _leads.clear();
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
    } catch (e) {}
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

  Future<void> updateLead(LeadModel updatedLead) async {
    await ensureInitialized();
    final index = _leads.indexWhere((lead) => lead.id == updatedLead.id);
    if (index != -1) {
      _leads[index] = updatedLead;

      // Note: Backend handles collection transitions (Leads → FollowUps → Reports)
      // Frontend should not remove leads locally
      // Screens will refresh and fetch from correct backend endpoints

      await _saveLeads();
      notifyListeners();
    }
  }

  LeadModel? getLeadById(String id) {
    try {
      // First check main leads list
      try {
        return _leads.firstWhere((lead) => lead.id == id);
      } catch (e) {
        // If not found in main leads, check follow-up leads
        try {
          return _followUpLeads.firstWhere((lead) => lead.id == id);
        } catch (e) {
          return null;
        }
      }
    } catch (e) {
      return null;
    }
  }

  /// Get booking confirmation specific data for a lead
  Map<String, dynamic>? getBookingConfirmationData(String leadId) {
    return _bookingConfirmationData[leadId];
  }

  // ========== Filtered Queries ==========

  List<LeadModel> getLeadsByCategory(String? category, {DateTime? date}) {
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

    // Apply category filter
    if (category == null || category == 'All') return filtered;
    return filtered.where((lead) => lead.category == category).toList();
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

  List<LeadModel> getLeadsByDateRange(DateTime startDate, DateTime endDate) {
    // Filter leads by date range (inclusive)
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    return _leads.where((lead) {
      final leadDate = lead.createdAt;
      return leadDate.isAfter(start) && leadDate.isBefore(end) ||
          (leadDate.year == start.year &&
              leadDate.month == start.month &&
              leadDate.day == start.day) ||
          (leadDate.year == end.year &&
              leadDate.month == end.month &&
              leadDate.day == end.day);
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

  // Note: Follow-up count is managed by backend
  // Frontend should fetch from backend via fetchFollowUpLeadsFromApi()

  // ========== API Integration ==========

  /// Parse API response to extract leads data
  List<dynamic> _parseResponseToLeadsList(Map<String, dynamic> response) {
    if (response.containsKey('data')) {
      final data = response['data'];
      if (data is List) return data;
      if (data is Map<String, dynamic> && data.containsKey('leads')) {
        final leads = data['leads'];
        if (leads is List) return leads;
      }
    }
    if (response.containsKey('leads') && response['leads'] is List)
      return response['leads'] as List;
    if (response.containsKey('results') && response['results'] is List)
      return response['results'] as List;

    for (var entry in response.entries) {
      if (entry.value is List) return entry.value as List;
    }
    return [];
  }

  /// Fetch Booking Confirmation leads from API and sync with repository
  Future<void> fetchBookingConfirmationLeadsFromApi({String? store}) async {
    try {
      await ensureInitialized();
      final storeFilter =
          (store == null || store == 'All Stores') ? null : store;
      final response = await _apiService.getBookingConfirmationLeads(
        store: storeFilter,
        limit: 1000,
      );
      final leadsData = _parseResponseToLeadsList(response);

      // Remove existing booking confirmation leads before adding fresh ones from API
      _leads.removeWhere(
        (lead) => lead.category == LeadConstants.categoryBookingConfirmation,
      );

      for (var leadData in leadsData) {
        try {
          final lead = _parseApiLeadToLeadModel(leadData);
          if (lead != null) {
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
              callCount: lead.callCount,
              createdAt: lead.createdAt,
            );
            _leads.add(bookingLead);

            _bookingConfirmationData[lead.id] = {
              'bookingNumber':
                  leadData['booking_number']?.toString() ??
                  leadData['bookingNumber']?.toString() ??
                  '',
              'enquiryDate':
                  leadData['enquiry_date']?.toString() ??
                  leadData['enquiryDate']?.toString(),
              'functionDate':
                  leadData['function_date']?.toString() ??
                  leadData['functionDate']?.toString(),
              'securityAmount':
                  leadData['security_amount']?.toString() ??
                  leadData['securityAmount']?.toString(),
            };
          }
        } catch (e) {
          // Continue processing other leads
        }
      }

      await _saveLeads();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch Loss of Sale leads from API and sync with repository
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
      final storeFilter =
          (store == null || store == 'All Stores') ? null : store;
      final response = await _apiService.getLossOfSaleLeads(
        store: storeFilter,
        enquiryFrom: enquiryFrom,
        enquiryTo: enquiryTo,
        functionFrom: functionFrom,
        functionTo: functionTo,
        visitFrom: visitFrom,
        visitTo: visitTo,
      );
      final leadsData = _parseResponseToLeadsList(response);

      // Remove existing loss of sale leads before adding fresh ones from API
      _leads.removeWhere(
        (lead) => lead.category == LeadConstants.categoryLossOfSales,
      );

      for (var leadData in leadsData) {
        try {
          final lead = _parseApiLeadToLeadModel(leadData);
          if (lead != null) _leads.add(lead);
        } catch (e) {
          // Continue processing other leads
        }
      }

      await _saveLeads();
    } catch (e) {
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
  LeadModel? _parseApiLeadToLeadModel(
    dynamic leadData, {
    bool useFunctionDateAsFollowUp = false,
  }) {
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
      // Backend uses 'store' field directly (e.g., "Suitor Guy - Calicut")
      // Normalize store name (Calicut -> Kozhikode, etc.)
      var location =
          leadData['store']?.toString() ?? // Backend field name
          leadData['location']?.toString();

      // If location is just the city name, normalize it
      if (location != null && !location.contains(' - ')) {
        location = StoreLocations.normalizeStoreName(location);
      } else if (location != null && location.contains(' - ')) {
        // If it's "Brand - Location" format, normalize the location part
        final parts = location.split(' - ');
        if (parts.length == 2) {
          final normalizedLocation = StoreLocations.normalizeStoreName(
            parts[1],
          );
          location = '${parts[0]} - $normalizedLocation';
        }
      }
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
      final callCount =
          leadData['callCount'] as int? ?? leadData['call_count'] as int? ?? 0;

      // Parse dates using the helper function that handles multiple formats
      // Backend uses: enquiry_date, function_date, created_at
      DateTime? followUpDate =
          _parseDate(leadData['followUpDate']) ??
          _parseDate(leadData['follow_up_date']) ??
          _parseDate(leadData['followUp']) ??
          _parseDate(leadData['follow_up']);

      // If this is being parsed specifically for Follow-ups endpoint, allow using function_date as a fallback
      if (followUpDate == null && useFunctionDateAsFollowUp) {
        followUpDate =
            _parseDate(leadData['function_date']) ??
            _parseDate(leadData['functionDate']) ??
            _parseDate(leadData['functionDate']);
        if (followUpDate != null) {
          print(
            'LeadRepository: Using function_date as followUpDate for lead id=$id -> $followUpDate',
          );
        }
      }

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
            leadType == 'return' ||
            leadType == 'rentoutfeedback') {
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
        callCount: callCount,
        createdAt: createdAt,
      );
    } catch (e) {
      return null;
    }
  }

  /// Fetch Rent-Out leads from API and sync with repository
  Future<void> fetchRentOutLeadsFromApi({String? store}) async {
    try {
      await ensureInitialized();
      final storeFilter =
          (store == null || store == 'All Stores') ? null : store;
      final response = await _apiService.getRentOutLeads(
        store: storeFilter,
        limit: 1000,
      );
      final leadsData = _parseResponseToLeadsList(response);

      // Remove existing rent-out leads before adding fresh ones from API
      _leads.removeWhere(
        (lead) => lead.category == LeadConstants.categoryRentOut,
      );

      for (var leadData in leadsData) {
        try {
          final lead = _parseApiLeadToLeadModel(leadData);
          if (lead != null) {
            final rentOutLead = LeadModel(
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
              callCount: lead.callCount,
              createdAt: lead.createdAt,
            );
            _leads.add(rentOutLead);
          }
        } catch (e) {
          // Continue processing other leads
        }
      }

      await _saveLeads();
    } catch (e) {
      // Silently handle Rent-Out fetch errors - endpoint may not be available
      // This prevents the entire lead fetch from failing
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
          callCount: lead.callCount,
          createdAt: lead.createdAt,
        );
        await updateLead(updatedLead);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update Rent-Out lead via API
  Future<void> updateRentOutLeadFromApi({
    required String id,
    String? callStatus,
    String? leadStatus,
    bool? followUpFlag,
    DateTime? callDate,
    DateTime? followUpDate,
    int? rating,
    String? remarks,
  }) async {
    try {
      await ensureInitialized();

      await _apiService.updateRentOutLead(
        id: id,
        callStatus: callStatus,
        leadStatus: leadStatus,
        followUpFlag: followUpFlag,
        callDate: followUpDate ?? callDate,
        rating: rating,
        remarks: remarks,
      );

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
                  : (followUpFlag == false ? null : lead.followUpDate),
          reason: remarks ?? lead.reason,
          category: lead.category,
          callDuration: lead.callDuration,
          callCount: lead.callCount,
          createdAt: lead.createdAt,
        );
        await updateLead(updatedLead);
      }
    } catch (e) {
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
    DateTime? followUpDate,
    String? remarks,
  }) async {
    try {
      await ensureInitialized();

      await _apiService.updateBookingConfirmationLead(
        id: id,
        callStatus: callStatus,
        leadStatus: leadStatus,
        followUpFlag: followUpFlag,
        callDate: followUpDate ?? callDate,
        remarks: remarks,
      );

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
                  : (followUpFlag == false ? null : lead.followUpDate),
          reason: remarks ?? lead.reason,
          category: lead.category,
          callDuration: lead.callDuration,
          callCount: lead.callCount,
          createdAt: lead.createdAt,
        );
        await updateLead(updatedLead);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch all leads from API and sync with repository
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
      final leadsData = _parseResponseToLeadsList(response);

      if (page == null || page == 1) {
        // Backend-driven: Clear local cache and replace with fresh data from API
        // Don't preserve leads locally - backend manages all collections
        _leads.clear();
      }

      for (var leadData in leadsData) {
        try {
          final lead = _parseApiLeadToLeadModel(leadData);
          if (lead != null) {
            final existingIndex = _leads.indexWhere((l) => l.id == lead.id);
            if (existingIndex != -1) {
              _leads[existingIndex] = lead;
            } else {
              _leads.add(lead);
            }
          }
        } catch (e) {
          // Continue processing other leads
        }
      }

      await _saveLeads();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Move a lead to report screen (remove from active leads)
  Future<void> moveToReport(String id) async {
    try {
      await ensureInitialized();
      final leadIndex = _leads.indexWhere((lead) => lead.id == id);
      if (leadIndex == -1) return;

      _leads.removeAt(leadIndex);
      await _saveLeads();
      notifyListeners();
    } catch (e) {
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
      String? dateStr;
      if (date != null) {
        dateStr =
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
      return await _apiService.getCallSummary(store: store, date: dateStr);
    } catch (e) {
      rethrow;
    }
  }

  // ========== Follow-Up Lead Methods ==========

  /// Fetch follow-up leads from backend and sync with local storage
  /// Gets leads from /api/pages/follow-ups collection
  Future<void> fetchFollowUpLeadsFromApi({String? store}) async {
    try {
      await ensureInitialized();
      final storeFilter =
          (store == null || store == 'All Stores') ? null : store;
      final response = await _apiService.getFollowUpLeads(
        store: storeFilter,
        limit: 1000,
      );
      final leadsData = _parseResponseToLeadsList(response);

      // Clear previous follow-up leads and fetch fresh from backend
      // This ensures leads completed and moved to Reports are removed
      _followUpLeads.clear();

      print(
        'LeadRepository: Fetched ${leadsData.length} raw follow-up entries from API',
      );

      // Add follow-up leads from backend
      for (var leadData in leadsData) {
        try {
          final lead = _parseApiLeadToLeadModel(
            leadData,
            useFunctionDateAsFollowUp: true,
          );
          if (lead != null) {
            _followUpLeads.add(lead);
            print(
              'LeadRepository: Added follow-up lead -> id=${lead.id}, phone=${lead.phone}, followUpDate=${lead.followUpDate}, callStatus=${lead.callStatus}',
            );
          } else {
            print('LeadRepository: Skipped invalid follow-up entry: $leadData');
          }
        } catch (e) {
          print('LeadRepository: Error parsing follow-up lead entry: $e');
          // Continue processing other leads
        }
      }

      print(
        'LeadRepository: Total follow-up leads after sync: ${_followUpLeads.length}',
      );
      notifyListeners();
    } catch (e) {
      print('LeadRepository: Error fetching follow-up leads: $e');
      rethrow;
    }
  }

  /// Fetch a single follow-up lead by ID from API
  /// Returns the follow-up lead details in listing format
  Future<LeadModel?> getFollowUpLeadFromApi(String id) async {
    try {
      await ensureInitialized();
      final response = await _apiService.getFollowUp(id);

      // Parse the response - backend returns the follow-up lead data
      final leadData = response['data'] ?? response;

      if (leadData is Map<String, dynamic>) {
        return _parseApiLeadToLeadModel(leadData);
      }

      return null;
    } catch (e) {
      print('LeadRepository: Error fetching follow-up lead: $e');
      rethrow;
    }
  }

  /// Update a follow-up lead via API
  /// Updates call status, lead status, remarks, call duration, and follow-up date for a follow-up lead
  /// According to API docs: call_status and lead_status are REQUIRED
  /// Backend expects: call_status, lead_status, call_duration (number in seconds), remarks (optional string)
  Future<void> updateFollowUpLeadFromApi({
    required String id,
    required String callStatus,
    required String leadStatus, // REQUIRED according to API docs
    String? remarks,
    int? callDuration, // Call duration in seconds (number) - backend expects this
    DateTime? callDate, // Deprecated - kept for backward compatibility
    DateTime? followUpDate,
    bool clearFollowUpDate = false,
  }) async {
    try {
      await ensureInitialized();

      await _apiService.postFollowUp(
        id: id,
        callStatus: callStatus,
        leadStatus: leadStatus, // REQUIRED field
        remarks: remarks,
        callDuration: callDuration, // Pass call duration (number in seconds)
        callDate: callDate, // Deprecated but kept for compatibility
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
          leadStatus: lead.leadStatus,
          callStatus: callStatus,
          followUpDate:
              clearFollowUpDate ? null : (followUpDate ?? lead.followUpDate),
          reason: lead.reason,
          category: lead.category,
          callDuration: lead.callDuration,
          callCount: lead.callCount,
          createdAt: lead.createdAt,
        );
        await updateLead(updatedLead);

        // Refresh follow-up leads from server to reflect any server-side movements
        try {
          print(
            'LeadRepository: Refreshing follow-up leads after update for id=$id',
          );
          await fetchFollowUpLeadsFromApi();
        } catch (e) {
          // Log and continue - don't fail the update flow if refresh fails
          print(
            'LeadRepository: Warning - could not refresh follow-up leads after update: $e',
          );
        }
      }
    } catch (e) {
      print('LeadRepository: Error updating follow-up lead: $e');
      rethrow;
    }
  }
}
