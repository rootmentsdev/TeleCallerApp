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

  List<LeadModel> get followUpLeads {
    // Return only leads that:
    // 1. Have a follow-up date set
    // 2. Are NOT yet completed (not moved to reports)
    // 3. Are marked as follow-up only (isolated from normal flow)
    return _leads
        .where(
          (lead) =>
              lead.needsFollowUp &&
              !lead.isFollowUpCompleted &&
              lead.isFollowUpOnly,
        )
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

  /// Create a follow-up lead when follow-up date is set
  /// This moves the lead to Follow-Up Screen only, NOT to Reports
  Future<void> createFollowUpLead(LeadModel lead) async {
    await ensureInitialized();

    // Create a new lead with follow-up flags set
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
      category: lead.category,
      callDuration: lead.callDuration,
      createdAt: lead.createdAt,
      source: lead.source,
      leadType: lead.leadType,
      isFollowUpCompleted: false, // Not yet completed
      isFollowUpOnly: true, // Mark as follow-up only (isolated from reports)
    );

    _leads.add(followUpLead);
    _lastAddedLeadId = followUpLead.id;
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
      final oldLead = _leads[index];
      _leads[index] = updatedLead;

      final wasUncalled = LeadConstants.isUncalledStatus(oldLead.callStatus);
      final isNowCalled = LeadConstants.isCalledStatus(updatedLead.callStatus);

      if (wasUncalled && isNowCalled && updatedLead.followUpDate == null) {
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

      _leads.removeWhere(
        (lead) =>
            lead.category == LeadConstants.categoryBookingConfirmation &&
            !lead.needsFollowUp,
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

      _leads.removeWhere(
        (lead) =>
            lead.category == LeadConstants.categoryLossOfSales &&
            !lead.needsFollowUp,
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
        createdAt: createdAt,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse API report data to LeadModel
  /// Reports come from backend after follow-up completion
  LeadModel? _parseApiReportToLeadModel(dynamic reportData) {
    try {
      if (reportData is! Map<String, dynamic>) {
        return null;
      }

      final id =
          reportData['_id']?.toString() ??
          reportData['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();

      final name =
          reportData['lead_name']?.toString() ??
          reportData['name']?.toString() ??
          '';

      final phone =
          reportData['phone_number']?.toString() ??
          reportData['phone']?.toString() ??
          '';

      if (name.isEmpty || phone.isEmpty) {
        return null;
      }

      var location =
          reportData['store']?.toString() ?? reportData['location']?.toString();

      // Normalize store name if needed
      if (location != null && !location.contains(' - ')) {
        location = StoreLocations.normalizeStoreName(location);
      } else if (location != null && location.contains(' - ')) {
        final parts = location.split(' - ');
        if (parts.length == 2) {
          final normalizedLocation = StoreLocations.normalizeStoreName(
            parts[1],
          );
          location = '${parts[0]} - $normalizedLocation';
        }
      }

      return LeadModel(
        id: id,
        name: name,
        phone: phone,
        brand: reportData['brand']?.toString(),
        location: location,
        leadStatus: reportData['lead_status']?.toString(),
        callStatus: reportData['call_status']?.toString(),
        followUpDate: _parseDate(reportData['follow_up_date']),
        reason: reportData['reason']?.toString(),
        category: reportData['category']?.toString(),
        callDuration: reportData['call_duration'] as int?,
        createdAt: _parseDate(reportData['created_at']) ?? DateTime.now(),
        source: reportData['source']?.toString(),
        leadType: reportData['lead_type']?.toString(),
        isFollowUpCompleted: reportData['category']?.toString() == 'followup',
        isFollowUpOnly: false,
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

      _leads.removeWhere(
        (lead) =>
            lead.category == LeadConstants.categoryRentOut &&
            !lead.needsFollowUp,
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
    int? callDuration,
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
        callDuration: callDuration,
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
          callDuration: callDuration ?? lead.callDuration,
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
    int? rating,
    String? remarks,
    int? callDuration,
  }) async {
    try {
      await ensureInitialized();

      await _apiService.updateRentOutLead(
        id: id,
        callStatus: callStatus,
        leadStatus: leadStatus,
        followUpFlag: followUpFlag,
        callDate: callDate,
        rating: rating,
        remarks: remarks,
        callDuration: callDuration,
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
        final preservedLeads =
            _leads
                .where(
                  (lead) =>
                      LeadConstants.isCalledStatus(lead.callStatus) ||
                      lead.needsFollowUp,
                )
                .toList();
        _leads.clear();
        _leads.addAll(preservedLeads);
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

  /// Fetch Follow-Up leads from API
  /// Matches backend GET /api/pages/follow-ups
  Future<void> fetchFollowUpLeadsFromApi({
    String? store,
    String? dateFrom,
    String? dateTo,
    int? page,
    int? limit,
  }) async {
    try {
      await ensureInitialized();

      print('[LeadRepository] Fetching follow-up leads from API');
      print(
        '[LeadRepository] store: $store, dateFrom: $dateFrom, dateTo: $dateTo',
      );

      final storeFilter =
          (store == null || store == 'All Stores') ? null : store;

      final response = await _apiService.getFollowUpLeads(
        store: storeFilter,
        dateFrom: dateFrom,
        dateTo: dateTo,
        page: page,
        limit: limit,
      );

      print('[LeadRepository] Follow-up leads API response received');
      print('[LeadRepository] Response: $response');

      // Parse response - handle different response formats
      List<dynamic> followUpLeadsData = [];

      if (response.containsKey('follow_ups')) {
        followUpLeadsData = response['follow_ups'] as List<dynamic>? ?? [];
      } else if (response.containsKey('data')) {
        final data = response['data'];
        if (data is List) {
          followUpLeadsData = data;
        } else if (data is Map && data.containsKey('follow_ups')) {
          final followUps = data['follow_ups'];
          if (followUps is List) {
            followUpLeadsData = followUps;
          }
        }
      } else if (response is List) {
        followUpLeadsData = response as List<dynamic>;
      }

      print(
        '[LeadRepository] Parsed ${followUpLeadsData.length} follow-up leads',
      );

      // Update or add follow-up leads to repository
      for (var leadData in followUpLeadsData) {
        try {
          final lead = _parseApiLeadToLeadModel(leadData);
          if (lead != null) {
            // Mark as follow-up lead
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
              category: lead.category,
              callDuration: lead.callDuration,
              createdAt: lead.createdAt,
              source: lead.source,
              leadType: lead.leadType,
              isFollowUpCompleted: false,
              isFollowUpOnly: true, // Mark as follow-up only
            );

            final existingIndex = _leads.indexWhere(
              (l) => l.id == followUpLead.id,
            );
            if (existingIndex != -1) {
              _leads[existingIndex] = followUpLead;
              print(
                '[LeadRepository] Updated follow-up lead: ${followUpLead.name}',
              );
            } else {
              _leads.add(followUpLead);
              print(
                '[LeadRepository] Added new follow-up lead: ${followUpLead.name}',
              );
            }
          }
        } catch (e) {
          print('[LeadRepository] Error parsing follow-up lead: $e');
          // Continue processing other leads
        }
      }

      await _saveLeads();
      notifyListeners();
      print('[LeadRepository] Follow-up leads fetched and saved successfully');
    } catch (e) {
      print('[LeadRepository] Error fetching follow-up leads: $e');
      rethrow;
    }
  }

  /// Fetch Reports from API and sync with repository
  Future<void> fetchReportsFromApi({
    String? store,
    String? leadType,
    DateTime? date,
    int? page,
    int? limit,
  }) async {
    try {
      await ensureInitialized();

      print('[LeadRepository] Fetching reports from API');
      print('[LeadRepository] leadType: $leadType, store: $store, date: $date');

      final response = await _apiService.getReports(
        store: store,
        leadType: leadType,
        date: date,
        page: page,
        limit: limit,
      );

      print('[LeadRepository] Reports API response received');

      // Parse response - handle different response formats
      List<dynamic> reportsData = [];

      if (response.containsKey('reports')) {
        reportsData = response['reports'] as List<dynamic>? ?? [];
      } else if (response.containsKey('data')) {
        final data = response['data'];
        if (data is List) {
          reportsData = data;
        }
      }

      print('[LeadRepository] Parsed ${reportsData.length} reports');

      // Add reports to repository as LeadModel objects
      for (var reportData in reportsData) {
        try {
          final report = _parseApiReportToLeadModel(reportData);
          if (report != null) {
            final existingIndex = _leads.indexWhere((l) => l.id == report.id);
            if (existingIndex != -1) {
              _leads[existingIndex] = report;
            } else {
              _leads.add(report);
            }
          }
        } catch (e) {
          print('[LeadRepository] Error parsing report: $e');
        }
      }

      await _saveLeads();
      notifyListeners();
      print('[LeadRepository] Reports fetched and saved successfully');
    } catch (e) {
      print('[LeadRepository] Error fetching reports: $e');
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

  /// Remove follow-up lead from local storage
  void removeFollowUpLead(String id) {
    _leads.removeWhere((lead) => lead.id == id);
    notifyListeners();
  }

  /// Update Follow-Up lead via API
  Future<void> updateFollowUpLeadFromApi({
    required String id,
    String? callStatus,
    String? leadStatus,
    String? remarks,
    int? callDuration,
    int? rating,
  }) async {
    try {
      print('[LeadRepository] updateFollowUpLeadFromApi called');
      print('[LeadRepository] ID: $id');
      print('[LeadRepository] callStatus: $callStatus');
      print('[LeadRepository] leadStatus: $leadStatus');
      print('[LeadRepository] callDuration: $callDuration');
      print('[LeadRepository] remarks: $remarks');
      print('[LeadRepository] rating: $rating');

      await ensureInitialized();

      print('[LeadRepository] Calling API updateFollowUp...');
      await _apiService.updateFollowUp(
        id: id,
        callStatus: callStatus,
        leadStatus: leadStatus,
        remarks: remarks,
        callDuration: callDuration,
        rating: rating,
      );

      print('[LeadRepository] API updateFollowUp completed successfully');

      // Get the current lead before removing it
      final lead = getLeadById(id);
      print(
        '[LeadRepository] Retrieved lead from local storage: ${lead?.name}',
      );

      if (lead != null) {
        // STEP 1: Remove lead from local list (it's now in Reports on backend)
        print('[LeadRepository] Removing lead from local list...');
        _leads.removeWhere((l) => l.id == id);
        await _saveLeads();
        print('[LeadRepository] Lead removed from local list');

        // STEP 2: Fetch Reports from backend to sync with backend state
        print('[LeadRepository] Fetching reports from backend...');
        try {
          final response = await _apiService.getReportsForFollowUp(
            leadType: lead.leadType,
          );

          // Parse response and add reports to local list
          List<dynamic> reportsData = [];
          if (response.containsKey('reports')) {
            reportsData = response['reports'] as List<dynamic>? ?? [];
          } else if (response.containsKey('data')) {
            final data = response['data'];
            if (data is List) {
              reportsData = data;
            }
          }

          for (var reportData in reportsData) {
            try {
              final report = _parseApiReportToLeadModel(reportData);
              if (report != null) {
                final existingIndex = _leads.indexWhere(
                  (l) => l.id == report.id,
                );
                if (existingIndex != -1) {
                  _leads[existingIndex] = report;
                } else {
                  _leads.add(report);
                }
              }
            } catch (e) {
              print('[LeadRepository] Error parsing report: $e');
            }
          }

          await _saveLeads();
          print('[LeadRepository] Reports fetched successfully');
        } catch (e) {
          print('[LeadRepository] Error fetching reports after follow-up: $e');
          // Don't block - continue even if report fetch fails
        }
      }

      notifyListeners();
      print('[LeadRepository] Listeners notified');
    } catch (e) {
      print('[LeadRepository] Error in updateFollowUpLeadFromApi: $e');
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
}
