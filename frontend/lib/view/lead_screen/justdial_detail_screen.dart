import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/store_location.dart';
import 'package:telecaller_app/services/api_service.dart';
import 'package:telecaller_app/services/phone_call_service.dart';
import 'package:telecaller_app/controller/call_tracking_controller.dart';

class JustDialDetailScreen extends StatefulWidget {
  final LeadModel lead;

  const JustDialDetailScreen({super.key, required this.lead});

  @override
  State<JustDialDetailScreen> createState() => _JustDialDetailScreenState();
}

class _JustDialDetailScreenState extends State<JustDialDetailScreen> {
  late Map<String, dynamic> justDialData;
  bool _isLoading = true;
  String? _error;
  bool _hasCalled = false;
  int _callDuration = 0;

  // New form fields
  final TextEditingController _customerNameController = TextEditingController();
  String? _selectedBrand;
  String? _selectedLocation;
  DateTime? _selectedFunctionDate;
  bool _isComplaint = false;
  String? _selectedSubCategory;
  String? _selectedCloseReason;
  String? _selectedItemCategory;
  final TextEditingController _remarksController = TextEditingController();
  bool _isSaving = false;
  
  String? _selectedCallStatus;
  DateTime? _selectedFollowUpDate;

  // Dropdown options
  final List<String> callStatusOptions = [
    'Connected',
    'Not Connected',
    'Interested',
    'Not Interested',
    'Forwarded',
  ];
  final List<String> brandOptions = ['Suitor Guy', 'Zorucci', 'Dapper Squad'];
  late List<String> locationOptions = [];
  final List<String> subCategoryOptions = [
    'Product Enquiry',
    'Price Enquiry',
    'Outside Products',
    'Others',
  ];
  final List<String> closeReasonOptions = [
    'Converted',
    'Not Interested',
    'Call Back Later',
  ];
  final List<String> itemCategoryOptions = [
    'Suit',
    'Bandgala/Jodhpuri',
    'Indo-western/Sherwani',
    'Kurta',
    'Kids Suit',
    'Gowns',
    'Sarees',
    'Tie',
    'Shoes',
    'Blazer',
  ];

  @override
  void initState() {
    super.initState();
    _fetchJustDialLeadDetails();
    // Initialize location options for first brand
    if (brandOptions.isNotEmpty) {
      locationOptions = StoreLocations.brandStores[brandOptions.first] ?? [];
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final callTrackingController = Provider.of<CallTrackingController>(
        context,
        listen: false,
      );
      callTrackingController.initialize();
      callTrackingController.addListener(_onCallDurationUpdate);
    });
  }

  Future<void> _fetchJustDialLeadDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final apiService = ApiService();
      final response = await apiService.getJustDialLeadById(widget.lead.id);

      if (mounted) {
        setState(() {
          justDialData = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onCallDurationUpdate() {
    final callTrackingController = Provider.of<CallTrackingController>(
      context,
      listen: false,
    );

    if (callTrackingController.lastDuration != null &&
        callTrackingController.lastDuration! > 0) {
      if (mounted) {
        setState(() {
          _callDuration = callTrackingController.lastDuration!;
        });
      }
    }
  }

  String _formatCallDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')} Mins';
  }

  Future<void> _makeCall() async {
    try {
      final phoneNumber = widget.lead.phone;
      await PhoneCallService.makeCall(phoneNumber);

      if (mounted) {
        setState(() {
          _hasCalled = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making call: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectFollowUpDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedFollowUpDate) {
      setState(() {
        _selectedFollowUpDate = picked;
      });
    }
  }

  Future<void> _selectFunctionDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedFunctionDate) {
      setState(() {
        _selectedFunctionDate = picked;
      });
    }
  }

  Future<void> _saveJustDialLead() async {
    // Validate required fields
    if (_selectedCallStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Call Status'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if ((_selectedCallStatus == 'Not Connected' || _selectedCallStatus == 'Interested') && _selectedFollowUpDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Follow-up Date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCallStatus != 'Not Connected') {
      if (_selectedSubCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select Sub Category'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedCloseReason == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select Close Reason'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedItemCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select Item Category'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final apiService = ApiService();

      final payload = {
        'customerName':
            _customerNameController.text.isEmpty
                ? null
                : _customerNameController.text,
        'brand': _selectedBrand,
        'location': _selectedLocation,
        'functionDate': _selectedFunctionDate?.toIso8601String(),
        'callDuration': _callDuration,
        'markAsComplaint': _isComplaint,
        'subCategory': _selectedSubCategory,
        'closeReason': _selectedCloseReason,
        'itemCategory': _selectedItemCategory,
        'remarks':
            _remarksController.text.isEmpty ? null : _remarksController.text,
        'callStatus': _selectedCallStatus,
        'followUpDate': _selectedFollowUpDate?.toIso8601String(),
      };

      await apiService.updateJustDialLead(widget.lead.id, payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Just Dial lead updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving Just Dial lead: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Widget _buildPhoneField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.phone, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Text(
            '+91 ${widget.lead.phone}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerNameField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _customerNameController,
        decoration: InputDecoration(
          hintText: 'Customer Name (Optional)',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.person, color: Colors.grey[600], size: 20),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> options,
    Function(String?) onChanged, {
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: TextConstant.dmSansRegular,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontFamily: TextConstant.dmSansRegular,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            hint: Text('Select $label'),
            isExpanded: true,
            underline: const SizedBox(),
            items:
                options.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.primaryColor,
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 30, bottom: 10),
                    child: Text(
                      "Just Dial Leads",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: TextConstant.dmSansMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error loading lead details',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchJustDialLeadDetails,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                      : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!_hasCalled) ...[
                              // Customer Info Display (before Call Now)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Phone
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          color: Colors.grey[600],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '+91 ${widget.lead.phone}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1A1A1A),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Name
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          color: Colors.grey[600],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            widget.lead.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1A1A1A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Location
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: Colors.grey[600],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            widget.lead.location ?? 'N/A',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1A1A1A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Call Now Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _makeCall,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorConstant.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "Call Now",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: TextConstant.dmSansMedium,
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              // Phone Number Field
                              _buildPhoneField(),
                              const SizedBox(height: 16),

                              // Customer Name Field
                              _buildCustomerNameField(),
                              const SizedBox(height: 16),

                              // Call Status Dropdown
                              _buildDropdownField(
                                'Call Status',
                                _selectedCallStatus,
                                callStatusOptions,
                                (value) {
                                  setState(() {
                                    _selectedCallStatus = value;
                                  });
                                },
                                isRequired: true,
                              ),
                              const SizedBox(height: 16),

                              if (_selectedCallStatus == 'Not Connected' ||
                                  _selectedCallStatus == 'Interested') ...[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Follow-up Date',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontFamily:
                                                TextConstant.dmSansRegular,
                                          ),
                                        ),
                                        Text(
                                          ' *',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red,
                                            fontFamily:
                                                TextConstant.dmSansRegular,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: _selectFollowUpDate,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: ColorConstant.primaryColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _selectedFollowUpDate != null
                                              ? DateFormat('dd/MM/yyyy')
                                                  .format(_selectedFollowUpDate!)
                                              : 'Select Follow-up Date',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _selectedFollowUpDate != null
                                                ? Colors.black
                                                : Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Store and Location Row
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDropdownField(
                                      'Brand',
                                      _selectedBrand,
                                      brandOptions,
                                      (value) {
                                        setState(() {
                                          _selectedBrand = value;
                                          // Update location options based on selected brand
                                          if (value != null) {
                                            locationOptions =
                                                StoreLocations
                                                    .brandStores[value] ??
                                                [];
                                            _selectedLocation =
                                                null; // Reset location
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildDropdownField(
                                      'Location',
                                      _selectedLocation,
                                      locationOptions,
                                      (value) => setState(
                                        () => _selectedLocation = value,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Function Date and Call Duration Row
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Function Date',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontFamily:
                                                TextConstant.dmSansRegular,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        GestureDetector(
                                          onTap: _selectFunctionDate,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey[300]!,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  _selectedFunctionDate != null
                                                      ? DateFormat(
                                                        'dd/MM/yyyy',
                                                      ).format(
                                                        _selectedFunctionDate!,
                                                      )
                                                      : 'dd/mm/yyyy',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        _selectedFunctionDate !=
                                                                null
                                                            ? Colors.black
                                                            : Colors.grey[400],
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.calendar_today,
                                                  color: Colors.grey[600],
                                                  size: 18,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Call Duration',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontFamily:
                                                TextConstant.dmSansRegular,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            _callDuration > 0
                                                ? _formatCallDuration(
                                                  _callDuration,
                                                )
                                                : '00:00 Mins',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1A1A1A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Mark as Complaint Checkbox
                              Row(
                                children: [
                                  Checkbox(
                                    value: _isComplaint,
                                    onChanged:
                                        (value) => setState(
                                          () => _isComplaint = value ?? false,
                                        ),
                                  ),
                                  const Text(
                                    'Mark as Complaint',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Sub Category Dropdown
                              _buildDropdownField(
                                'Sub Category',
                                _selectedSubCategory,
                                subCategoryOptions,
                                (value) => setState(
                                  () => _selectedSubCategory = value,
                                ),
                                isRequired: _selectedCallStatus != 'Not Connected',
                              ),
                              const SizedBox(height: 16),

                              // Close Reason Dropdown
                              _buildDropdownField(
                                'Close Reason',
                                _selectedCloseReason,
                                closeReasonOptions,
                                (value) => setState(
                                  () => _selectedCloseReason = value,
                                ),
                                isRequired: _selectedCallStatus != 'Not Connected',
                              ),
                              const SizedBox(height: 16),

                              // Item Category Dropdown
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Item Category',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontFamily:
                                              TextConstant.dmSansRegular,
                                        ),
                                      ),
                                      if (_selectedCallStatus != 'Not Connected')
                                        Text(
                                          ' *',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red,
                                            fontFamily:
                                                TextConstant.dmSansRegular,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButton<String>(
                                      value: _selectedItemCategory,
                                      hint: const Text('Kurta'),
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      items:
                                          itemCategoryOptions.map((
                                            String item,
                                          ) {
                                            return DropdownMenuItem<String>(
                                              value: item,
                                              child: Text(item),
                                            );
                                          }).toList(),
                                      onChanged:
                                          (value) => setState(
                                            () => _selectedItemCategory = value,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Call Remarks Text Area
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Call Remarks / Notes',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontFamily: TextConstant.dmSansRegular,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _remarksController,
                                    maxLines: 4,
                                    maxLength: 500,
                                    decoration: InputDecoration(
                                      hintText: 'Enter your remarks',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: const EdgeInsets.all(12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Cancel and Save Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[200],
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: TextConstant.dmSansMedium,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed:
                                          _isSaving ? null : _saveJustDialLead,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            ColorConstant.primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child:
                                          _isSaving
                                              ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                  strokeWidth: 2,
                                                ),
                                              )
                                              : const Text(
                                                'Save Lead',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily:
                                                      TextConstant.dmSansMedium,
                                                ),
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
