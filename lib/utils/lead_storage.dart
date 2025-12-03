import 'package:telecaller_app/model/lead_model.dart';

class LeadStorage {
  static final LeadStorage _instance = LeadStorage._internal();
  factory LeadStorage() => _instance;
  LeadStorage._internal();

  // In-memory storage for leads
  // In a real app, this would be replaced with a database
  final List<LeadModel> _leads = [];

  // Get all leads
  List<LeadModel> get allLeads => List.unmodifiable(_leads);

  // Get leads that need follow-up
  List<LeadModel> get followUpLeads {
    return _leads.where((lead) => lead.needsFollowUp).toList();
  }

  // Get today's follow-ups
  List<LeadModel> get todayFollowUps {
    return _leads.where((lead) => lead.isToday).toList();
  }

  // Get upcoming follow-ups
  List<LeadModel> get upcomingFollowUps {
    return _leads.where((lead) => lead.isUpcoming).toList();
  }

  // Get overdue follow-ups
  List<LeadModel> get overdueFollowUps {
    return _leads.where((lead) => lead.isOverdue).toList();
  }

  // Add a new lead
  void addLead(LeadModel lead) {
    _leads.add(lead);
  }

  // Remove a lead
  void removeLead(String id) {
    _leads.removeWhere((lead) => lead.id == id);
  }

  // Update a lead
  void updateLead(LeadModel updatedLead) {
    final index = _leads.indexWhere((lead) => lead.id == updatedLead.id);
    if (index != -1) {
      _leads[index] = updatedLead;
    }
  }

  // Get lead by ID
  LeadModel? getLeadById(String id) {
    try {
      return _leads.firstWhere((lead) => lead.id == id);
    } catch (e) {
      return null;
    }
  }

  // Clear all leads (for testing)
  void clearAll() {
    _leads.clear();
  }
}
