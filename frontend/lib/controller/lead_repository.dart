import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/services/api_service.dart';
import 'package:telecaller_app/utils/lead_constants.dart';
import 'package:telecaller_app/utils/store_location.dart';

/// Shared repository for managing all lead data
/// This is a singleton that all controllers can access
class LeadRepository {
  static final LeadRepository _instance = LeadRepository._internal();
  factory LeadRepository() => _instance;
  LeadRepository._internal() {
    _initialize();
  }

  final List<LeadModel> _leads = [];
  static const String _storageKey = 'saved_leads';
  bool _isInitialized = false;
  final ApiService _apiService = ApiService();

  // ========== Getters ==========

  List<LeadModel> get allLeads {
    // Initialize synchronously if not already done (for immediate access)
    if (!_isInitialized) {
      _initialize().then((_) => _isInitialized = true);
    }
    return List.unmodifiable(_leads);
  }

  List<LeadModel> get followUpLeads {
    return _leads.where((lead) => lead.needsFollowUp).toList();
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
    await _saveLeads();
  }

  Future<void> removeLead(String id) async {
    await ensureInitialized();
    _leads.removeWhere((lead) => lead.id == id);
    await _saveLeads();
  }

  Future<void> updateLead(LeadModel updatedLead) async {
    await ensureInitialized();
    final index = _leads.indexWhere((lead) => lead.id == updatedLead.id);
    if (index != -1) {
      _leads[index] = updatedLead;
      await _saveLeads();
    }
  }

  LeadModel? getLeadById(String id) {
    try {
      return _leads.firstWhere((lead) => lead.id == id);
    } catch (e) {
      return null;
    }
  }

  // ========== Filtered Queries ==========

  List<LeadModel> getLeadsByCategory(String? category) {
    if (category == null || category == 'All') return allLeads;
    return _leads.where((lead) => lead.category == category).toList();
  }

  List<LeadModel> getLeadsByStore(String? store) {
    if (store == null || store == 'All Stores') return allLeads;
    // Extract location from "Brand - Location" format, or use as-is if already a location
    final location =
        store.contains(' - ')
            ? StoreLocations.resolveSelection(store).location
            : store;
    return _leads.where((lead) => lead.location == location).toList();
  }

  List<LeadModel> getLeadsByDate(DateTime date) {
    return _leads.where((lead) {
      final leadDate = lead.createdAt;
      return leadDate.year == date.year &&
          leadDate.month == date.month &&
          leadDate.day == date.day;
    }).toList();
  }

  List<LeadModel> getLeadsByStoreAndDate(String? store, DateTime date) {
    List<LeadModel> filtered = getLeadsByDate(date);

    if (store != null && store != 'All Stores') {
      // Extract location from "Brand - Location" format, or use as-is if already a location
      final location =
          store.contains(' - ')
              ? StoreLocations.resolveSelection(store).location
              : store;
      filtered = filtered.where((lead) => lead.location == location).toList();
    }

    return filtered;
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
      _leads.removeWhere(
        (lead) => lead.category == LeadConstants.categoryLossOfSales,
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
          _parseDate(
            leadData['enquiry_date'],
          ) ?? // Backend field name (primary)
          _parseDate(leadData['created_at']) ?? // Backend field name
          _parseDate(leadData['enquiryDate']) ??
          _parseDate(leadData['createdAt']) ??
          _parseDate(leadData['date']) ??
          _parseDate(leadData['leadDate']) ??
          _parseDate(leadData['lead_date']);

      if (parsedCreatedAt != null) {
        createdAt = parsedCreatedAt;
      }

      // Validate required fields
      if (name.isEmpty || phone.isEmpty) {
        return null;
      }

      // Determine category - backend uses lead_type field
      String? category =
          LeadConstants.categoryLossOfSales; // Default for Loss of Sale API
      if (leadData['lead_type'] != null) {
        final leadType = leadData['lead_type'].toString().toLowerCase();
        if (leadType == 'lossofsale' || leadType == 'loss of sale') {
          category = LeadConstants.categoryLossOfSales;
        } else if (leadType == 'rentout' || leadType == 'rent out') {
          category = LeadConstants.categoryRentOut;
        } else if (leadType == 'bookingconfirmation' ||
            leadType == 'booking confirmation') {
          category = LeadConstants.categoryBookingConfirmation;
        } else if (leadType == 'justdial' || leadType == 'just dial') {
          category = LeadConstants.categoryJustDial;
        } else if (leadType == 'followup' || leadType == 'follow up') {
          category = LeadConstants.categoryFollowUp;
        }
      }

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
}
