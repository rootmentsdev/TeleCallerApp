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
    await _addTestBookingConfirmationDataIfNeeded();
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

  /// Test lead ID for UI checking (used when kDebugMode)
  static const String _testBookingConfirmationLeadId =
      'test_booking_confirmation_lead_001';

  /// Add test booking confirmation lead data for UI checking (debug mode only)
  Future<void> _addTestBookingConfirmationDataIfNeeded() async {
    if (!kDebugMode) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if test lead already exists
    final existingTestLead = _leads.any(
      (l) => l.id == _testBookingConfirmationLeadId,
    );
    if (!existingTestLead) {
      final testLead = LeadModel(
        id: _testBookingConfirmationLeadId,
        name: 'Abhiram S Kumar',
        phone: '9876543210',
        brand: 'Zorucci',
        location: 'Edappally',
        category: LeadConstants.categoryBookingConfirmation,
        callStatus: 'Not called yet',
        leadStatus: 'New Lead',
        enquiryDate: DateTime(2025, 10, 30),
        functionDate: DateTime(2026, 11, 2),
        createdAt: today,
        isStarred: false,
      );
      _leads.add(testLead);
      await _saveLeads();
      print(
        'LeadRepository: Added test booking confirmation lead for UI check',
      );
    }

    // Always ensure booking data is available for test lead (not persisted)
    _bookingConfirmationData[_testBookingConfirmationLeadId] = {
      'attendedBy': 'Arjun GS',
      'attended_by': 'Arjun GS',
      'advance': 5500,
      'totalAmount': 7500,
      'productAmount': 7500,
      'product_amount': 7500,
    };
  }

  // ========== Helper Methods ==========

  /// Apply date filter to a list of leads
  List<LeadModel> _applyDateFilter(List<LeadModel> leads, DateTime date) {
    return leads.where((lead) {
      final leadDate = lead.getEffectiveDate();
      return leadDate.year == date.year &&
          leadDate.month == date.month &&
          leadDate.day == date.day;
    }).toList();
  }

  /// Extract location from store string (handles "Brand - Location" format)
  String _extractLocationFromStore(String? store) {
    if (store == null || store == 'All Stores') return store ?? '';
    return store.contains(' - ')
        ? StoreLocations.resolveSelection(store).location
        : store;
  }

  /// Parse API response to extract leads list
  List<dynamic> _parseResponseData(Map<String, dynamic> response) {
    if (response.containsKey('data')) {
      final data = response['data'];
      if (data is List) return data;
      if (data is Map<String, dynamic> && data.containsKey('leads')) {
        final leads = data['leads'];
        if (leads is List) return leads;
      }
    }
    if (response.containsKey('leads')) {
      final leads = response['leads'];
      if (leads is List) return leads;
    }
    if (response.containsKey('results')) {
      final results = response['results'];
      if (results is List) return results;
    }
    if (response.containsKey('starredCalls')) {
      final starredCalls = response['starredCalls'];
      if (starredCalls is List) return starredCalls;
    }
    // Fallback: find first list value
    for (var entry in response.entries) {
      if (entry.value is List) return entry.value as List;
    }
    return [];
  }

  /// Create lead with specific category
  LeadModel _createLeadWithCategory(LeadModel lead, String category) {
    return LeadModel(
      id: lead.id,
      name: lead.name,
      phone: lead.phone,
      brand: lead.brand,
      location: lead.location,
      leadStatus: lead.leadStatus,
      callStatus: lead.callStatus,
      followUpDate: lead.followUpDate,
      reason: lead.reason,
      category: category,
      callDuration: lead.callDuration,
      createdAt: lead.createdAt,
      subCategory: lead.subCategory,
      closingAction: lead.closingAction,
      functionDate: lead.functionDate,
      enquiryDate: lead.enquiryDate,
      leadType: lead.leadType,
      returnDate: lead.returnDate,
      bookingDate: lead.bookingDate,
    );
  }

  // ========== Filtered Queries ==========

  List<LeadModel> getLeadsByCategory(String? category, {DateTime? date}) {
    List<LeadModel> filtered =
        date != null ? _applyDateFilter(_leads, date) : _leads;
    if (category == null || category == 'All') return filtered;
    return filtered.where((lead) => lead.category == category).toList();
  }

  /// Extract brand and location from store string
  Map<String, String?> _extractBrandAndLocation(String store) {
    String? brand;
    String location;
    if (store.contains(' - ')) {
      final parts = store.split(' - ');
      if (parts.length >= 2) {
        brand = parts[0].trim();
        location = parts[1].trim();
      } else {
        location = store;
      }
    } else {
      location = store;
    }
    return {'brand': brand, 'location': location};
  }

  /// Check if brands match (handles variations)
  bool _brandsMatch(String? brand1, String? brand2) {
    if (brand1 == null || brand2 == null) return true;
    final b1 = brand1.toLowerCase();
    final b2 = brand2.toLowerCase();
    final isSuitor1 = b1.contains('suitor');
    final isSuitor2 = b2.contains('suitor');
    final isZorucci1 = b1.contains('zorucci') || b1.contains('zurocci');
    final isZorucci2 = b2.contains('zorucci') || b2.contains('zurocci');
    return (isSuitor1 == isSuitor2) && (isZorucci1 == isZorucci2);
  }

  /// Helper method to check if a lead matches a store filter
  bool matchesStore(LeadModel lead, String store) {
    if (store.isEmpty || store == 'All Stores') return true;

    final filter = _extractBrandAndLocation(store);
    String? leadBrand = lead.brand;
    String leadLocation = lead.location ?? '';

    if (leadLocation.contains(' - ')) {
      final parts = leadLocation.split(' - ');
      if (parts.length >= 2) {
        if (leadBrand == null || leadBrand.isEmpty) leadBrand = parts[0].trim();
        leadLocation = parts[1].trim();
      }
    }

    leadLocation = StoreLocations.normalizeStoreName(leadLocation);
    String location = StoreLocations.normalizeStoreName(filter['location']!);

    // Brand-aware normalization for Suitor Guy
    final isSuitor =
        (filter['brand']?.toLowerCase().contains('suitor') ?? false) &&
        (leadBrand?.toLowerCase().contains('suitor') ?? false);
    if (isSuitor) {
      if (leadLocation.toLowerCase() == 'kottakkal') leadLocation = 'Kottakal';
      if (location.toLowerCase() == 'kottakkal') location = 'Kottakal';
    }

    if (!_brandsMatch(filter['brand'], leadBrand)) return false;

    final normalizedLead = leadLocation.toLowerCase().trim();
    final normalizedFilter = location.toLowerCase().trim();
    return normalizedLead == normalizedFilter ||
        normalizedLead.contains(normalizedFilter) ||
        normalizedFilter.contains(normalizedLead);
  }

  List<LeadModel> getLeadsByStore(String? store, {DateTime? date}) {
    List<LeadModel> filtered =
        date != null
            ? _leads.where((lead) {
              final leadDate = lead.createdAt;
              return leadDate.year == date.year &&
                  leadDate.month == date.month &&
                  leadDate.day == date.day;
            }).toList()
            : _leads;
    if (store == null || store == 'All Stores') return filtered;
    final location = _extractLocationFromStore(store);
    return filtered.where((lead) => lead.location == location).toList();
  }

  List<LeadModel> getLeadsByDate(DateTime date) =>
      _applyDateFilter(_leads, date);

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
    List<LeadModel> baseList = _leads;
    if (store != null && store != 'All Stores') {
      final location = _extractLocationFromStore(store);
      baseList = baseList.where((lead) => lead.location == location).toList();
    }
    return _applyDateFilter(baseList, date);
  }

  int getCountByCategory(String category, {String? store, DateTime? date}) {
    List<LeadModel> filtered =
        date != null ? _applyDateFilter(_leads, date) : _leads;
    if (store != null && store != 'All Stores') {
      filtered =
          filtered
              .where(
                (lead) => lead.location == _extractLocationFromStore(store),
              )
              .toList();
    }
    return filtered.where((lead) => lead.category == category).length;
  }

  int getCountByCallStatus(String callStatus, {String? store, DateTime? date}) {
    List<LeadModel> filtered =
        date != null ? _applyDateFilter(_leads, date) : _leads;
    if (store != null && store != 'All Stores') {
      filtered =
          filtered
              .where(
                (lead) => lead.location == _extractLocationFromStore(store),
              )
              .toList();
    }
    return filtered.where((lead) => lead.callStatus == callStatus).length;
  }

  int getTotalLeadsCount({String? store, DateTime? date}) {
    List<LeadModel> filtered =
        date != null ? _applyDateFilter(_leads, date) : _leads;
    if (store != null && store != 'All Stores') {
      filtered =
          filtered
              .where(
                (lead) => lead.location == _extractLocationFromStore(store),
              )
              .toList();
    }
    return filtered.length;
  }

  int get totalLeadsCount => _leads.length;

  int getFollowUpLeadsCount({String? store, DateTime? date}) {
    List<LeadModel> filtered =
        _leads.where((lead) => lead.needsFollowUp).toList();
    if (date != null) filtered = _applyDateFilter(filtered, date);
    if (store != null && store != 'All Stores') {
      filtered =
          filtered
              .where(
                (lead) => lead.location == _extractLocationFromStore(store),
              )
              .toList();
    }
    return filtered.length;
  }

  // ========== Storage Operations ==========

  /// Force reload leads from SharedPreferences storage
  Future<void> forceReloadFromStorage() async {
    await _loadLeads();
    notifyListeners();
  }

  /// Clear all followup leads from local storage
  /// This removes all leads with category "Follow Up" from the in-memory list and persists the change
  Future<void> clearFollowupLeads() async {
    try {
      await ensureInitialized();

      final followupCount = followUpLeads.length;

      // Remove all leads with category "Follow Up"
      _leads.removeWhere(
        (lead) => lead.category == LeadConstants.categoryFollowUp,
      );

      // Persist the changes
      await _saveLeads();

      print(
        'LeadRepository: Cleared followup leads - Removed $followupCount leads, Total leads now: ${_leads.length}',
      );

      notifyListeners();
    } catch (e, s) {
      print('LeadRepository: Error clearing followup leads: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'clearFollowupLeads failed',
      );
      rethrow;
    }
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

    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      // Try manual parsing for non-ISO formats
      final parts = dateStr.split(RegExp(r'[-/]'));
      if (parts.length == 3) {
        try {
          final nums = parts.map((p) => int.parse(p)).toList();
          // Try different orderings: yyyy-MM-dd, dd-MM-yyyy, MM/dd/yyyy
          if (nums[0] > 31)
            return DateTime(nums[0], nums[1], nums[2]); // yyyy-MM-dd
          if (nums[2] > 31)
            return DateTime(nums[2], nums[1], nums[0]); // dd-MM-yyyy
          return DateTime(nums[2], nums[0], nums[1]); // MM/dd/yyyy
        } catch (e) {
          return null;
        }
      }
      return null;
    }
  }

  /// Extract field from API response (tries multiple key variations)
  String? _extractField(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  /// Map lead type value to category
  String? _mapLeadTypeToCategory(String? leadType) {
    if (leadType == null) return null;
    final value = leadType.toLowerCase();
    if (value == 'lossofsale' || value == 'loss of sale')
      return LeadConstants.categoryLossOfSales;
    if (value == 'rentout' ||
        value == 'rent out' ||
        value == 'rentoutfeedback' ||
        value == 'return') {
      return LeadConstants.categoryRentOut;
    }
    if (value == 'bookingconfirmation' || value == 'booking confirmation')
      return LeadConstants.categoryBookingConfirmation;
    if (value == 'justdial' || value == 'just dial')
      return LeadConstants.categoryJustDial;
    if (value == 'followup' || value == 'follow up')
      return LeadConstants.categoryFollowUp;
    if (value == 'general' || value == 'walkin' || value == 'walk-in')
      return null;
    return null;
  }

  /// Map lead type value to display name
  String? _mapLeadTypeToDisplay(String? leadType) {
    if (leadType == null) return null;
    final value = leadType.toLowerCase();
    if (value == 'lossofsale' || value == 'loss of sale') return 'Loss of Sale';
    if (value == 'rentout' ||
        value == 'rent out' ||
        value == 'rentoutfeedback' ||
        value == 'return')
      return 'Feedback';
    if (value == 'bookingconfirmation' || value == 'booking confirmation')
      return 'Booking';
    if (value == 'justdial' || value == 'just dial') return 'Just Dial';
    if (value == 'followup' || value == 'follow up') return 'Follow Up';
    if (value == 'enquiry' ||
        value == 'enquiry_booking_reports' ||
        value == 'enquiry booking reports')
      return 'Enquiry';
    if (value == 'general' || value == 'walkin' || value == 'walk-in')
      return 'Lead';
    return leadType;
  }

  /// Parse API lead data to LeadModel
  LeadModel? _parseApiLeadToLeadModel(dynamic leadData) {
    try {
      if (leadData is! Map<String, dynamic>) return null;

      // Debug: log all keys to find date field names
      print('LeadRepository: Lead keys: ${leadData.keys.toList()}');
      print(
        'LeadRepository: returnDate=${leadData['returnDate']}, return_date=${leadData['return_date']}, bookingDate=${leadData['bookingDate']}, booking_date=${leadData['booking_date']}',
      );

      final id =
          _extractField(leadData, ['id', '_id', 'leadId', 'lead_id']) ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final name =
          _extractField(leadData, [
            'lead_name',
            'leadName',
            'name',
            'customerName',
            'customer_name',
            'customer',
            'clientName',
          ]) ??
          '';
      final phone =
          _extractField(leadData, [
            'phone_number',
            'phoneNumber',
            'phone',
            'mobile',
            'contactNumber',
            'contact',
          ]) ??
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

      if (name.isEmpty || phone.isEmpty) return null;

      final leadStatus = _extractField(leadData, [
        'lead_status',
        'leadStatus',
        'status',
      ]);
      final callStatus =
          _extractField(leadData, ['call_status', 'callStatus']) ??
          LeadConstants.callStatusNotCalled;
      final reason = _extractField(leadData, [
        'remarks',
        'reason',
        'reason_collected_from_store',
        'notes',
      ]);
      final callDuration =
          leadData['callDuration'] as int? ?? leadData['call_duration'] as int?;
      final followUpDate =
          _parseDate(leadData['follow_up_date']) ??
          _parseDate(leadData['followUpDate']) ??
          _parseDate(leadData['followupDate']);
      final functionDate =
          _parseDate(leadData['function_date']) ??
          _parseDate(leadData['functionDate']);
      final enquiryDate =
          _parseDate(leadData['enquiry_date']) ??
          _parseDate(leadData['enquiryDate']);
      final returnDate =
          _parseDate(leadData['return_date']) ??
          _parseDate(leadData['returnDate']);
      final bookingDate =
          _parseDate(leadData['bookingDate']) ??
          _parseDate(leadData['booking_date']);
      final createdAt =
          _parseDate(leadData['created_at']) ??
          _parseDate(leadData['createdAt']) ??
          _parseDate(leadData['enquiry_date']) ??
          _parseDate(leadData['enquiryDate']) ??
          _parseDate(leadData['visit_date']) ??
          _parseDate(leadData['visitDate']) ??
          DateTime.now();

      final leadTypeField = _extractField(leadData, ['lead_type', 'leadType']);
      final category = _mapLeadTypeToCategory(leadTypeField);
      final leadType = _mapLeadTypeToDisplay(leadTypeField);

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
        functionDate: functionDate,
        enquiryDate: enquiryDate,
        leadType: leadType,
        returnDate: returnDate,
        bookingDate: bookingDate,
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
    String? fromDate,
    String? toDate,
  }) async {
    try {
      await ensureInitialized();

      print('═══════════════════════════════════════════════════════════');
      print('LeadRepository: FETCHING FEEDBACK CALLS (RETURN LEADS)');
      print('═══════════════════════════════════════════════════════════');
      print('Parameters:');
      print('  store: $store');
      print('  fromDate: $fromDate');
      print('  toDate: $toDate');
      print('  enquiryFrom: $enquiryFrom');
      print('  enquiryTo: $enquiryTo');
      print('═══════════════════════════════════════════════════════════');

      // Pass store in "Brand - Location" format (e.g., "Suitor Guy - Edappal")
      final storeFilter =
          (store == null || store == 'All Stores') ? null : store;
      final response = await _apiService.getReturnLeads(
        store: storeFilter,
        fromDate: fromDate,
        toDate: toDate,
        limit: 1000,
      );

      final leadsData = _parseResponseData(response);

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
            final returnLead = _createLeadWithCategory(
              lead,
              LeadConstants.categoryRentOut,
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

  /// Fetch Booking Confirmation leads from the dedicated API endpoint
  Future<void> fetchBookingConfirmationLeadsFromApi({
    String? store,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      await ensureInitialized();

      final storeFilter =
          (store == null || store == 'All Stores') ? null : store;
      final response = await _apiService.getBookingConfirmationLeads(
        store: storeFilter,
        fromDate: fromDate,
        toDate: toDate,
        limit: 1000,
      );

      final leadsData = _parseResponseData(response);

      // Remove existing booking confirmation leads (avoid duplicates)
      _leads.removeWhere(
        (lead) =>
            lead.category == LeadConstants.categoryBookingConfirmation &&
            !lead.needsFollowUp,
      );

      for (var leadData in leadsData) {
        try {
          final lead = _parseApiLeadToLeadModel(leadData);
          if (lead != null) {
            final bookingLead = _createLeadWithCategory(
              lead,
              LeadConstants.categoryBookingConfirmation,
            );
            _leads.add(bookingLead);
          }
        } catch (e) {
          print('LeadRepository: Error parsing Booking Confirmation lead: $e');
        }
      }

      await _saveLeads();
      notifyListeners();
    } catch (e) {
      print('LeadRepository: Error fetching Booking Confirmation leads: $e');
      rethrow;
    }
  }

  /// Update Booking Confirmation lead via API
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
    String? refundStatus,
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
        subCategory: subCategory,
        itemCategory: itemCategory,
        functionDate: functionDate,
        leadType: leadType,
        markAsComplaint: markAsComplaint,
        numberOfFunctions: numberOfFunctions,
        numberOfAttires: numberOfAttires,
        competitor: competitor,
        service: service,
        refundStatus: refundStatus,
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
      final response = await _apiService.getFollowUpLeads(
        store: storeFilter,
        limit: 1000,
      );

      final leadsData = _parseResponseData(response);

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

  /// Update Booking Confirmation lead via the dedicated API endpoint
  Future<void> updateBookingConfirmationLeadFromApi({
    required String id,
    required String leadName,
    required String phoneNumber,
    required String store,
    required String source,
    required String leadType,
    required String callStatus,
    required String leadStatus,
    String? service,
    bool? billReceived,
    bool? amountMismatch,
    String? advancePaid,
    String? securityPaid,
    String? remarks,
    bool followUpFlag = false,
    String? followUpDate,
    int? callDuration,
    bool clearFollowUpDate = false,
    bool? markAsComplaint,
  }) async {
    try {
      await ensureInitialized();

      DateTime? followupDateTime;
      if (followUpFlag && followUpDate != null) {
        followupDateTime = DateTime.tryParse(followUpDate);
      }
      if (clearFollowUpDate) {
        followupDateTime = null;
      }

      await _apiService.updateBookingConfirmation(
        id: id,
        service: service,
        callDuration: callDuration?.toString(),
        billReceived: billReceived == true ? 'yes' : null,
        amountMismatch: amountMismatch,
        remarks: remarks,
        markasComplaint: markAsComplaint,
        markasFollowup: followUpFlag ? true : null,
        followupDate: followupDateTime,
      );

      // Remove from active list after update
      _leads.removeWhere((l) => l.id == id);
      await _saveLeads();
      notifyListeners();
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'updateBookingConfirmationLeadFromApi failed',
      );
      rethrow;
    }
  }

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
        followUpFlag: followUpFlag,
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
        dateFrom: dateFrom,
        dateTo: dateTo,
        dateField: dateField,
        createdAt: createdAt,
      );

      final leadsData = _parseResponseData(response);

      // Debug: Print how many leads were received
      print('LeadRepository: Received ${leadsData.length} leads from API');

      // If page is specified, we might want to merge/update existing leads
      // Otherwise, replace all leads with fresh data from API
      // BUT: Preserve called leads and follow-up leads so they remain available for reports screen
      // EXCEPT: Don't preserve called return leads or booking confirmation leads (they've been moved to reports)
      if (page == null || page == 1) {
        // Store called leads and follow-up leads before clearing
        // Exclude called return leads and booking confirmation leads (moved to reports)
        // In debug mode, also preserve test booking confirmation lead for UI checking
        final preservedLeads =
            _leads.where((lead) {
              final isReturnLead =
                  lead.category == LeadConstants.categoryRentOut;
              final isBookingConfirmationLead =
                  lead.category == LeadConstants.categoryBookingConfirmation;
              final isCalled = LeadConstants.isCalledStatus(lead.callStatus);

              // Preserve test lead in debug mode for UI checking
              if (kDebugMode && lead.id == _testBookingConfirmationLeadId) {
                return true;
              }

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
      final response = await _apiService.getStarredCalls(
        store: storeFilter,
        limit: 1000,
      );

      final leadsData = _parseResponseData(response);

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
            isStarred: true,
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
