import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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

  List<LeadModel> get starredCallsLeads {
    // Return all leads marked as starred (isStarred = true)
    return _leads.where((lead) => lead.isStarred == true).toList();
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
      print(
        'LeadRepository: Removed ${removedCount - remainingCount} lead(s) with phone number: $phoneNumber',
      );
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

  List<LeadModel> getLeadsByCategory(String? category, {DateTime? date}) {
    List<LeadModel> filtered = _leads;

    // Apply date filter if provided
    if (date != null) {
      filtered =
          filtered.where((lead) {
            final leadDate = lead.getEffectiveDate();
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
  /// and supports partial matching with brand-aware normalization
  bool matchesStore(LeadModel lead, String store) {
    if (store.isEmpty || store == 'All Stores') {
      return true;
    }

    // Extract brand and location from "Brand - Location" format, or use as-is if already a location
    String? filterBrand;
    String location;
    if (store.contains(' - ')) {
      final parts = store.split(' - ');
      if (parts.length >= 2) {
        filterBrand = parts[0].trim();
        location = parts[1].trim();
      } else {
        location = store;
      }
    } else {
      location = store;
    }

    // Normalize the filter location
    location = StoreLocations.normalizeStoreName(location);

    // Get lead brand and location
    String? leadBrand = lead.brand;
    String leadLocation = lead.location ?? '';

    // Extract brand from lead location if it's in "Brand - Location" format
    if (leadLocation.contains(' - ')) {
      final parts = leadLocation.split(' - ');
      if (parts.length >= 2) {
        if (leadBrand == null || leadBrand.isEmpty) {
          leadBrand = parts[0].trim();
        }
        leadLocation = parts[1].trim();
      }
    }

    // Normalize lead location
    leadLocation = StoreLocations.normalizeStoreName(leadLocation);

    // Brand-aware normalization: "Kottakkal" -> "Kottakal" for Suitor Guy stores only
    final isFilterSuitor =
        filterBrand != null && filterBrand.toLowerCase().contains('suitor');
    final isLeadSuitor =
        leadBrand != null && leadBrand.toLowerCase().contains('suitor');

    if (isFilterSuitor && isLeadSuitor) {
      // Both are Suitor Guy - normalize "Kottakkal" to "Kottakal"
      if (leadLocation.toLowerCase() == 'kottakkal') {
        leadLocation = 'Kottakal';
      }
      if (location.toLowerCase() == 'kottakkal') {
        location = 'Kottakal';
      }
    }

    // Check brand match if both have brands
    if (filterBrand != null && leadBrand != null) {
      final normalizedFilterBrand = filterBrand.toLowerCase().trim();
      final normalizedLeadBrand = leadBrand.toLowerCase().trim();

      // Brand must match (handle variations like "Suitor Guy" vs "Suitor")
      final isFilterSuitorCheck = normalizedFilterBrand.contains('suitor');
      final isLeadSuitorCheck = normalizedLeadBrand.contains('suitor');
      final isFilterZorucci =
          normalizedFilterBrand.contains('zorucci') ||
          normalizedFilterBrand.contains('zurocci');
      final isLeadZorucci =
          normalizedLeadBrand.contains('zorucci') ||
          normalizedLeadBrand.contains('zurocci');

      // Brand mismatch check
      if (isFilterSuitorCheck && !isLeadSuitorCheck) {
        return false; // Filter is Suitor but lead is not
      }
      if (isLeadSuitorCheck && !isFilterSuitorCheck) {
        return false; // Lead is Suitor but filter is not
      }
      if (isFilterZorucci && !isLeadZorucci) {
        return false; // Filter is Zorucci but lead is not
      }
      if (isLeadZorucci && !isFilterZorucci) {
        return false; // Lead is Zorucci but filter is not
      }
    }

    // Case-insensitive location matching
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
      final leadDate = lead.getEffectiveDate();
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
      final leadDate = lead.getEffectiveDate();
      final normalizedLeadDate = DateTime.utc(
        leadDate.year,
        leadDate.month,
        leadDate.day,
      );
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
      final leadDate = lead.getEffectiveDate();
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
            final leadDate = lead.getEffectiveDate();
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
            final leadDate = lead.getEffectiveDate();
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
            final leadDate = lead.getEffectiveDate();
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
            final leadDate = lead.getEffectiveDate();
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
  /// Supports both snake_case (backend list endpoints) and camelCase (individual endpoints)
  LeadModel? _parseApiLeadToLeadModel(dynamic leadData) {
    try {
      if (leadData is! Map<String, dynamic>) {
        return null;
      }

      // Extract fields from API response
      // Supports both snake_case and camelCase field names
      final id =
          leadData['id']?.toString() ??
          leadData['_id']?.toString() ??
          leadData['leadId']?.toString() ??
          leadData['lead_id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();

      // Name field - try both snake_case and camelCase
      final name =
          leadData['lead_name']?.toString() ?? // Backend snake_case
          leadData['leadName']?.toString() ?? // Individual endpoint camelCase
          leadData['name']?.toString() ??
          leadData['customerName']?.toString() ??
          leadData['customer_name']?.toString() ??
          leadData['customer']?.toString() ??
          leadData['clientName']?.toString() ??
          '';

      // Phone field - try both snake_case and camelCase
      final phone =
          leadData['phone_number']?.toString() ?? // Backend snake_case
          leadData['phoneNumber']
              ?.toString() ?? // Individual endpoint camelCase
          leadData['phone']?.toString() ??
          leadData['mobile']?.toString() ??
          leadData['contactNumber']?.toString() ??
          leadData['contact']?.toString() ??
          '';

      // Extract brand and location from store field if available
      String? brand;
      String? location;
      final storeField =
          leadData['store']?.toString() ??
          leadData['store_location']?.toString() ??
          leadData['location']?.toString();

      if (storeField != null && storeField.isNotEmpty) {
        if (storeField.contains(' - ')) {
          // Extract brand and location from "Brand - Location" format
          final parts = storeField.split(' - ');
          if (parts.length >= 2) {
            brand = parts[0].trim();
            location = parts[1].trim();
            // Normalize store name with brand context
            // Special case: "Kottakkal" -> "Kottakal" for Suitor Guy only
            if (brand.toLowerCase().contains('suitor') &&
                location.toLowerCase() == 'kottakkal') {
              location = 'Kottakal';
            } else {
              location = StoreLocations.normalizeStoreName(location);
            }
          } else {
            location = StoreLocations.normalizeStoreName(storeField.trim());
          }
        } else if (storeField.contains('-')) {
          // Extract brand and location from "Brand-Location" format (hyphen without spaces)
          final parts = storeField.split('-');
          if (parts.length >= 2) {
            brand = parts[0].trim();
            location = parts[1].trim();
            // Normalize store name with brand context
            if (brand.toLowerCase().contains('suitor') &&
                location.toLowerCase() == 'kottakkal') {
              location = 'Kottakal';
            } else {
              location = StoreLocations.normalizeStoreName(location);
            }
          } else {
            location = StoreLocations.normalizeStoreName(storeField.trim());
          }
        } else {
          location = StoreLocations.normalizeStoreName(storeField.trim());
        }
      }

      // Fallback to brand field if not extracted from store
      if (brand == null || brand.isEmpty) {
        brand = leadData['brand']?.toString();
      }

      // Lead status - try both snake_case and camelCase
      final leadStatus =
          leadData['lead_status']?.toString() ?? // Backend snake_case
          leadData['leadStatus']?.toString() ?? // Individual endpoint camelCase
          leadData['status']?.toString();

      // Call status - try both snake_case and camelCase
      final callStatus =
          leadData['call_status']?.toString() ?? // Backend snake_case
          leadData['callStatus']?.toString() ?? // Individual endpoint camelCase
          LeadConstants.callStatusNotCalled;

      // Reason/remarks - try multiple field names (optional field)
      final reason =
          leadData['remarks']?.toString() ??
          leadData['reason']?.toString() ??
          leadData['reason_collected_from_store']?.toString() ??
          leadData['notes']?.toString();

      // Note: reason/remarks/notes are optional fields for return leads
      // They may not be present in the API response, which is fine

      final callDuration =
          leadData['callDuration'] as int? ?? leadData['call_duration'] as int?;

      // Parse dates using the helper function that handles multiple formats
      // Backend uses: follow_up_date for follow-up date, function_date for function date
      // Individual endpoint may use camelCase: followUpDate, functionDate
      // IMPORTANT: Only set followUpDate if there's an actual follow_up_date field
      // Do NOT use function_date as a fallback for followUpDate
      DateTime? followUpDate =
          _parseDate(leadData['follow_up_date']) ?? // Backend snake_case
          _parseDate(leadData['followUpDate']); // Individual endpoint camelCase

      // Parse function_date separately (for Function Date display)
      DateTime? functionDate =
          _parseDate(leadData['function_date']) ?? // Backend snake_case
          _parseDate(leadData['functionDate']); // Individual endpoint camelCase

      // Parse enquiry_date separately (for Call Date/Enquiry Date display)
      DateTime? enquiryDate =
          _parseDate(leadData['enquiry_date']) ?? // Backend snake_case
          _parseDate(leadData['enquiryDate']); // Individual endpoint camelCase

      DateTime createdAt = DateTime.now();
      // Try multiple date field names for created date
      final parsedCreatedAt =
          _parseDate(leadData['created_at']) ?? // Backend snake_case
          _parseDate(leadData['createdAt']) ?? // Individual endpoint camelCase
          _parseDate(
            leadData['enquiry_date'],
          ) ?? // Backend snake_case (fallback)
          _parseDate(
            leadData['enquiryDate'],
          ) ?? // Individual endpoint camelCase (fallback)
          _parseDate(leadData['visit_date']) ?? // Backend snake_case
          _parseDate(leadData['visitDate']) ?? // Individual endpoint camelCase
          _parseDate(leadData['return_date']) ?? // Backend snake_case
          _parseDate(leadData['returnDate']) ?? // Individual endpoint camelCase
          DateTime.now();

      createdAt = parsedCreatedAt;

      // Validate required fields
      if (name.isEmpty || phone.isEmpty) {
        return null;
      }

      // Determine category - backend uses lead_type field
      String? category; // Default to null (will show in "All Calls" tab)
      final leadTypeFieldForCategory =
          leadData['lead_type']?.toString() ?? // Backend snake_case
          leadData['leadType']?.toString(); // Individual endpoint camelCase

      if (leadTypeFieldForCategory != null) {
        final leadTypeValue = leadTypeFieldForCategory.toLowerCase();
        if (leadTypeValue == 'lossofsale' || leadTypeValue == 'loss of sale') {
          category = LeadConstants.categoryLossOfSales;
        } else if (leadTypeValue == 'rentout' ||
            leadTypeValue == 'rent out' ||
            leadTypeValue == 'rentoutfeedback' ||
            leadTypeValue == 'return') {
          category = LeadConstants.categoryRentOut;
        } else if (leadTypeValue == 'bookingconfirmation' ||
            leadTypeValue == 'booking confirmation') {
          category = LeadConstants.categoryBookingConfirmation;
        } else if (leadTypeValue == 'justdial' ||
            leadTypeValue == 'just dial') {
          category = LeadConstants.categoryJustDial;
        } else if (leadTypeValue == 'followup' ||
            leadTypeValue == 'follow up') {
          category = LeadConstants.categoryFollowUp;
        } else if (leadTypeValue == 'general' ||
            leadTypeValue == 'walkin' ||
            leadTypeValue == 'walk-in') {
          // General/Walk-in leads don't have a specific category - show in "All Calls"
          category = null;
        }
        // If leadType doesn't match any known type, category remains null
      }

      // Extract lead type for display (e.g., "Enquiry", "Booking", "Feedback")
      String? leadType;
      final leadTypeField =
          leadData['lead_type']?.toString() ?? // Backend snake_case
          leadData['leadType']?.toString(); // Individual endpoint camelCase

      if (leadTypeField != null) {
        final leadTypeLower = leadTypeField.toLowerCase();
        if (leadTypeLower == 'lossofsale' || leadTypeLower == 'loss of sale') {
          leadType = 'Loss of Sale';
        } else if (leadTypeLower == 'rentout' ||
            leadTypeLower == 'rent out' ||
            leadTypeLower == 'rentoutfeedback' ||
            leadTypeLower == 'return') {
          leadType = 'Feedback';
        } else if (leadTypeLower == 'bookingconfirmation' ||
            leadTypeLower == 'booking confirmation') {
          leadType = 'Booking';
        } else if (leadTypeLower == 'justdial' ||
            leadTypeLower == 'just dial') {
          leadType = 'Just Dial';
        } else if (leadTypeLower == 'followup' ||
            leadTypeLower == 'follow up') {
          leadType = 'Follow Up';
        } else if (leadTypeLower == 'enquiry' ||
            leadTypeLower == 'enquiry_booking_reports' ||
            leadTypeLower == 'enquiry booking reports') {
          leadType = 'Enquiry';
        } else if (leadTypeLower == 'general' ||
            leadTypeLower == 'walkin' ||
            leadTypeLower == 'walk-in') {
          leadType = 'Lead';
        } else {
          // Use the original value if it doesn't match known types
          leadType = leadTypeField;
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
        subCategory:
            leadData['sub_category']?.toString() ?? // Backend snake_case
            leadData['subCategory']
                ?.toString(), // Individual endpoint camelCase
        closingAction:
            leadData['closing_action']?.toString() ?? // Backend snake_case
            leadData['closingAction']
                ?.toString(), // Individual endpoint camelCase
        functionDate: functionDate, // Function date from API
        enquiryDate: enquiryDate, // Enquiry date from API
        leadType: leadType, // Lead type for display
      );
    } catch (e) {
      print('Error parsing API lead: $e');
      return null;
    }
  }

  /// Fetch Return leads from API and sync with repository
  /// Uses the list endpoint which returns complete lead data
  Future<void> fetchReturnLeadsFromApi({
    String? store,
    String? enquiryFrom,
    String? enquiryTo,
  }) async {
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
      int successCount = 0;

      // Parse leads directly from list endpoint (which has complete data)
      for (var leadData in leadsData) {
        try {
          // Parse the lead data from list endpoint
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
              subCategory: lead.subCategory,
              closingAction: lead.closingAction,
            );
            _leads.add(returnLead);
            successCount++;
          } else {
            failedCount++;
          }
        } catch (e) {
          failedCount++;
          print('LeadRepository: Error parsing Return lead: $e');
        }
      }

      print(
        'LeadRepository: Fetched $successCount Return leads successfully, $failedCount failed',
      );
      print(
        'LeadRepository: Total leads in repository after fetch: ${_leads.length}',
      );
      print(
        'LeadRepository: Return leads in repository: ${_leads.where((l) => l.category == LeadConstants.categoryRentOut).length}',
      );

      if (failedCount > 0) {
        print('LeadRepository: Failed to parse $failedCount Return leads');
      }

      await _saveLeads();
      notifyListeners(); // Notify UI of changes
    } catch (e) {
      print('LeadRepository: Error fetching Return leads: $e');
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
    String? subCategory,
    String? itemCategory,
    DateTime? functionDate,
    String? leadType,
    bool? markAsComplaint,
    String? numberOfFunctions,
    String? numberOfAttires,
    String? competitor,
    String? service,
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
        subCategory: subCategory,
        itemCategory: itemCategory,
        functionDate: functionDate,
        leadType: leadType,
        markAsComplaint: markAsComplaint,
        numberOfFunctions: numberOfFunctions,
        numberOfAttires: numberOfAttires,
        competitor: competitor,
        service: service,
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
          subCategory: lead.subCategory,
          closingAction: lead.closingAction,
        );
        await updateLead(updatedLead);
      }
    } catch (e) {
      print('LeadRepository: Error updating Return lead: $e');
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
      final followUpLeadsBeforeFetch =
          _leads
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
          final phone =
              leadData['phone_number']?.toString() ??
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
            (lead.phone.isNotEmpty &&
                apiPhoneNumbers.contains(lead.phone.trim())),
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
              subCategory: lead.subCategory,
              closingAction: lead.closingAction,
              functionDate: lead.functionDate,
              enquiryDate: lead.enquiryDate,
              leadType: lead.leadType,
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
      final followUpLeadsAfterFetch =
          _leads
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
    String? subCategory,
    String? closingAction,
    int? rating,
    String? leadType,
    DateTime? functionDate,
    bool? followUpFlag,
    bool? markAsComplaint,
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
        subCategory: subCategory,
        closingAction: closingAction,
        rating: rating,
        leadType: leadType,
        functionDate: functionDate,
        followUpFlag: followUpFlag,
        markAsComplaint: markAsComplaint,
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
          subCategory: subCategory ?? lead.subCategory,
          closingAction: closingAction ?? lead.closingAction,
          enquiryDate: lead.enquiryDate,
          functionDate: functionDate ?? lead.functionDate,
          visitDate: lead.visitDate,
          bookingNumber: lead.bookingNumber,
          assignedTo: lead.assignedTo,
          rating: rating ?? lead.rating,
          followUpFlag: followUpFlag ?? lead.followUpFlag,
          markAsComplaint: markAsComplaint ?? lead.markAsComplaint,
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
            _leads.where((lead) {
              final isReturnLead =
                  lead.category == LeadConstants.categoryRentOut;
              final isBookingConfirmationLead =
                  lead.category == LeadConstants.categoryBookingConfirmation;
              final isCalled = LeadConstants.isCalledStatus(lead.callStatus);

              // Don't preserve called return leads or booking confirmation leads
              if ((isReturnLead || isBookingConfirmationLead) && isCalled) {
                return false;
              }

              // Preserve other called leads and follow-up leads
              return isCalled || lead.needsFollowUp;
            }).toList();

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
            final isBookingConfirmationLead =
                lead.category == LeadConstants.categoryBookingConfirmation;
            final isCalled = LeadConstants.isCalledStatus(lead.callStatus);

            if ((isReturnLead || isBookingConfirmationLead) && isCalled) {
              skippedCalledCount++;
              print(
                'LeadRepository: Skipping called ${lead.category} lead: ${lead.name} (${lead.phone}) - moved to reports',
              );
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
        print(
          'LeadRepository: Skipped $skippedCalledCount called return/booking confirmation leads (moved to reports)',
        );
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

  /// Fetch Starred Calls from API and sync with repository
  Future<void> fetchStarredCallsFromApi({String? store}) async {
    try {
      await ensureInitialized();

      // Pass store in "Brand - Location" format (e.g., "Suitor Guy - Edappal")
      final storeFilter =
          (store == null || store == 'All Stores') ? null : store;
      final response = await _apiService.getStarredCalls(store: storeFilter);

      // Parse response - handle different response formats
      List<dynamic> leadsData = [];

      if (response.containsKey('starredCalls')) {
        final starredCalls = response['starredCalls'];
        if (starredCalls is List) {
          leadsData = starredCalls;
        }
      } else if (response.containsKey('data')) {
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

      print(
        'LeadRepository: Fetched ${leadsData.length} starred calls from API',
      );

      // First, remove all previously starred leads that are not in the new response
      // This ensures we only have the currently starred leads
      final newStarredIds =
          leadsData.map((lead) => lead['_id'] ?? lead['id'] ?? '').toSet();

      _leads.removeWhere(
        (lead) => lead.isStarred && !newStarredIds.contains(lead.id),
      );

      // Parse and add starred calls to repository
      int successCount = 0;
      int failureCount = 0;

      for (var leadData in leadsData) {
        try {
          final lead = LeadModel.fromApiJson(leadData);

          // Mark as starred since it came from the starred calls endpoint
          final starredLead = LeadModel(
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
            callCount: lead.callCount,
            createdAt: lead.createdAt,
            returnDate: lead.returnDate,
            source: lead.source,
            leadType: lead.leadType,
            isStarred: true, // Explicitly mark as starred
            subCategory: lead.subCategory,
            closingAction: lead.closingAction,
          );

          // Check if lead already exists in repository
          final existingIndex = _leads.indexWhere(
            (l) => l.id == starredLead.id,
          );
          if (existingIndex >= 0) {
            // Update existing lead
            _leads[existingIndex] = starredLead;
          } else {
            // Add new lead
            _leads.add(starredLead);
          }
          successCount++;
        } catch (e) {
          print('LeadRepository: Failed to parse starred call: $e');
          failureCount++;
        }
      }

      print(
        'LeadRepository: Added $successCount starred calls, failed to parse $failureCount',
      );

      notifyListeners();
    } catch (e, s) {
      print('LeadRepository: Error fetching starred calls: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'fetchStarredCallsFromApi failed',
      );
      rethrow;
    }
  }

  /// Override dispose to prevent disposal of singleton
  /// LeadRepository is a singleton that should never be disposed
  @override
  // ignore: must_call_super
  void dispose() {
    // Do NOT call super.dispose() - this is a singleton that lives for the app lifetime
    // Just remove listeners if needed, but don't dispose the notifier itself
    print(
      'LeadRepository: dispose() called but ignored - singleton should not be disposed',
    );
  }
}
