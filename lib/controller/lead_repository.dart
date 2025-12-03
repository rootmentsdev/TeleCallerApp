import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telecaller_app/model/lead_model.dart';
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
}
