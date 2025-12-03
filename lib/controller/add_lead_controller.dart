import 'package:flutter/material.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/utils/store_location.dart';

/// Controller for Add Lead Screen
class AddLeadController extends ChangeNotifier {
  final LeadRepository _repository = LeadRepository();

  // Form fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String? selectedBrand;
  String? selectedLocation;
  String? selectedLeadStatus;
  String? selectedCallStatus;
  DateTime? followUpDate;

  // Options
  final List<String> brands = ['Suitor Guy', 'Zorucci'];
  final List<String> leadStatuses = [
    'New Lead',
    'Contacted',
    'Qualified',
    'Negotiation',
    'Won',
    'Lost',
  ];
  final List<String> callStatuses = [
    'Not Called',
    'Connected',
    'Not Connected',
    'Call Back Later',
    'Busy',
  ];

  // Get locations based on selected brand
  List<String> get locations {
    if (selectedBrand == null) {
      return [];
    }
    return StoreLocations.brandStores[selectedBrand] ?? [];
  }

  // Setters
  void setSelectedBrand(String? brand) {
    selectedBrand = brand;
    // Clear location when brand changes
    selectedLocation = null;
    notifyListeners();
  }

  void setSelectedLocation(String? location) {
    selectedLocation = location;
    notifyListeners();
  }

  void setSelectedLeadStatus(String? status) {
    selectedLeadStatus = status;
    notifyListeners();
  }

  void setSelectedCallStatus(String? status) {
    selectedCallStatus = status;
    notifyListeners();
  }

  void setFollowUpDate(DateTime? date) {
    followUpDate = date;
    notifyListeners();
  }

  // Submit lead
  Future<bool> submitLead() async {
    // Validate required fields
    if (nameController.text.trim().isEmpty) {
      return false;
    }

    if (phoneController.text.trim().isEmpty) {
      return false;
    }

    // Create lead model
    final lead = LeadModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      brand: selectedBrand,
      location: selectedLocation,
      leadStatus: selectedLeadStatus,
      callStatus: selectedCallStatus,
      followUpDate: followUpDate,
      category: null, // Category removed from add lead form
      reason: null, // Reason removed from add lead form
    );

    // Save lead to repository
    await _repository.addLead(lead);

    // Clear form
    clearForm();

    return true;
  }

  // Clear form
  void clearForm() {
    nameController.clear();
    phoneController.clear();
    selectedBrand = null;
    selectedLocation = null;
    selectedLeadStatus = null;
    selectedCallStatus = null;
    followUpDate = null;
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
