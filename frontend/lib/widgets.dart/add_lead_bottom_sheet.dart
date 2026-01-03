import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/model/call_model.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/utils/lead_constants.dart';
import 'package:telecaller_app/utils/store_location.dart';
import 'package:telecaller_app/services/api_service.dart';
import 'package:telecaller_app/view/bottomnavigation_bar.dart';

class AddLeadBottomSheet extends StatefulWidget {
  final String? prefilledPhoneNumber;
  final int? prefilledCallDuration;
  final CallData? callData;

  const AddLeadBottomSheet({
    super.key,
    this.prefilledPhoneNumber,
    this.prefilledCallDuration,
    this.callData,
  });

  @override
  State<AddLeadBottomSheet> createState() => _AddLeadBottomSheetState();
}

class _AddLeadBottomSheetState extends State<AddLeadBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _remarksController = TextEditingController();

  String? _selectedBrand;
  String? _selectedLocation;
  String? _selectedLeadStatus;
  String? _selectedCallStatus;
  DateTime? _followUpDate;
  bool _markAsFollowUp = false;
  int? _callDuration;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    // Pre-fill phone number if provided
    if (widget.prefilledPhoneNumber != null) {
      _phoneController.text = widget.prefilledPhoneNumber!;
    }

    // Pre-fill call duration if provided
    if (widget.prefilledCallDuration != null) {
      _callDuration = widget.prefilledCallDuration;
    }

    // Set default values
    _selectedCallStatus =
        LeadConstants
            .callStatusConnected; // Default to Connected since call was made
    _selectedLeadStatus = LeadConstants.leadStatusNewLead;

    // Set default location from header controller
    final headerController = Provider.of<HeaderController>(
      context,
      listen: false,
    );
    final selectedStore = headerController.selectedStore;
    if (selectedStore != 'All Stores') {
      final storeInfo = StoreLocations.resolveSelection(selectedStore);
      _selectedBrand = storeInfo.brand;
      _selectedLocation = storeInfo.location;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add New Lead',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      size: 28,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Customer Name with icon
              _buildIconTextField(
                controller: _nameController,
                label: 'Customer Name',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Phone Number with icon
              _buildIconTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter phone number';
                  }
                  if (value.trim().length < 10) {
                    return 'Please enter valid phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Brand and Location in row
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      value: _selectedBrand,
                      label: 'Brand',
                      items: StoreLocations.brandStores.keys.toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBrand = value;
                          _selectedLocation = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedLocation != null &&
                              _selectedBrand != null &&
                              (StoreLocations.brandStores[_selectedBrand!] ?? [])
                                  .contains(_selectedLocation)
                          ? _selectedLocation
                          : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _selectedBrand == null
                                ? const Color(0xFFCCCCCC)
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF003D7A),
                            width: 2,
                          ),
                        ),
                        filled: _selectedBrand == null,
                        fillColor: _selectedBrand == null
                            ? const Color(0xFFF5F5F5)
                            : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      items:
                          _selectedBrand != null
                              ? (StoreLocations.brandStores[_selectedBrand!] ??
                                      [])
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(
                                        item,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  )
                                  .toList()
                              : [],
                      selectedItemBuilder: (BuildContext context) {
                        if (_selectedBrand == null) return [];
                        return (StoreLocations.brandStores[_selectedBrand!] ?? [])
                            .map((item) => Text(
                                  item,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ))
                            .toList();
                      },
                      onChanged:
                          _selectedBrand == null
                              ? null
                              : (value) {
                                setState(() {
                                  _selectedLocation = value;
                                });
                              },
                      validator: (value) {
                        if (_selectedBrand != null && value == null) {
                          return 'Location is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Lead Status and Call Status in row
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      value: _selectedLeadStatus,
                      label: 'Lead Status',
                      items: [
                        LeadConstants.leadStatusNewLead,
                        LeadConstants.leadStatusContacted,
                        LeadConstants.leadStatusQualified,
                        LeadConstants.leadStatusNegotiation,
                        LeadConstants.leadStatusWon,
                        LeadConstants.leadStatusLost,
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedLeadStatus = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownField(
                      value: _selectedCallStatus,
                      label: 'Call Status',
                      items: [
                        LeadConstants.callStatusConnected,
                        LeadConstants.callStatusNotConnected,
                        LeadConstants.callStatusCallBackLater,
                        LeadConstants.callStatusNotCalled,
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCallStatus = value;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Follow-up Date
              _buildFollowUpDateField(),

              const SizedBox(height: 24),

              // Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: Color(0xFFE0E0E0),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveLead,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003D7A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: const Color(0xFFCCCCCC),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text(
                                'Save Lead',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF666666), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF003D7A), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    // Ensure value is in items list, otherwise set to null
    final validValue = (value != null && items.contains(value)) ? value : null;
    final isDisabled = items.isEmpty;

    return DropdownButtonFormField<String>(
      value: validValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                isDisabled ? const Color(0xFFCCCCCC) : const Color(0xFFE0E0E0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                isDisabled ? const Color(0xFFCCCCCC) : const Color(0xFFE0E0E0),
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF003D7A), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        filled: isDisabled,
        fillColor: isDisabled ? const Color(0xFFF5F5F5) : Colors.white,
      ),
      items:
          items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
      selectedItemBuilder: (BuildContext context) {
        return items.map((item) {
          return Text(
            item,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          );
        }).toList();
      },
      onChanged: isDisabled ? null : onChanged,
    );
  }

  Widget _buildFollowUpDateField() {
    return InkWell(
      onTap: _selectFollowUpDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _followUpDate != null
                  ? 'Follow-Ups Date (Optional)\n${_formatDate(_followUpDate!)}'
                  : 'Follow-Ups Date (Optional)',
              style: TextStyle(
                fontSize: 14,
                color:
                    _followUpDate != null
                        ? const Color(0xFF333333)
                        : const Color(0xFF999999),
              ),
            ),
            const Icon(
              Icons.calendar_today,
              color: Color(0xFF666666),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectFollowUpDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _followUpDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _followUpDate = date;
      });
    }
  }

  Future<void> _saveLead() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_markAsFollowUp && _followUpDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select follow-up date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final leadRepository = LeadRepository();

      // Get store name from brand and location
      final store = _selectedLocation ?? _selectedBrand ?? 'Unknown';

      // Call API to create lead with correct snake_case fields
      final apiResponse = await apiService.createLead(
        leadName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        store: store,
        source: 'Walk-in',
        leadType: 'General',
        remarks:
            _remarksController.text.trim().isEmpty
                ? null
                : _remarksController.text.trim(),
        followUpFlag: _markAsFollowUp,
        functionDate: _markAsFollowUp ? _followUpDate?.toIso8601String() : null,
      );

      print('AddLeadBottomSheet: API Response: $apiResponse');

      // Extract the lead ID from API response
      String leadId = '';

      // Check nested lead object first (new format)
      if (apiResponse.containsKey('lead') && apiResponse['lead'] is Map) {
        final lead = apiResponse['lead'] as Map<String, dynamic>;
        leadId = lead['id']?.toString() ?? lead['_id']?.toString() ?? '';
      }

      // Check top-level fields
      if (leadId.isEmpty) {
        if (apiResponse.containsKey('_id')) {
          leadId = apiResponse['_id'].toString();
        } else if (apiResponse.containsKey('id')) {
          leadId = apiResponse['id'].toString();
        } else if (apiResponse.containsKey('data') &&
            apiResponse['data'] is Map) {
          final data = apiResponse['data'] as Map<String, dynamic>;
          leadId = data['_id']?.toString() ?? data['id']?.toString() ?? '';
        }
      }

      print('AddLeadBottomSheet: Extracted lead ID: $leadId');

      if (leadId.isEmpty) {
        throw Exception('Failed to get lead ID from server response');
      }

      // Create local lead model with the ID from API
      final lead = LeadModel(
        id: leadId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        brand: _selectedBrand,
        location: _selectedLocation,
        leadStatus: _selectedLeadStatus,
        callStatus: _selectedCallStatus,
        followUpDate: _markAsFollowUp ? _followUpDate : null,
        reason:
            _remarksController.text.trim().isEmpty
                ? null
                : _remarksController.text.trim(),
        category: null,
        callDuration: _callDuration,
        callCount: _callDuration != null && _callDuration! > 0 ? 1 : 0,
        createdAt: DateTime.now(),
        source: 'Walk-in',
        leadType: 'General',
      );

      // Add to local repository
      await leadRepository.addLead(lead);

      if (mounted) {
        Navigator.pop(context);

        // If follow-up date is set, navigate to follow-up screen
        if (_markAsFollowUp && _followUpDate != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            BottomNavState.navigateToFollowUp();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lead saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('AddLeadBottomSheet: Error saving lead: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving lead: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Show Add Lead Bottom Sheet
void showAddLeadBottomSheet(
  BuildContext context, {
  String? phoneNumber,
  int? callDuration,
  CallData? callData,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (context) => AddLeadBottomSheet(
          prefilledPhoneNumber: phoneNumber,
          prefilledCallDuration: callDuration,
          callData: callData,
        ),
  );
}
