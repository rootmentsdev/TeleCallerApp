import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/model/call_model.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/utils/store_location.dart';
import 'package:telecaller_app/services/api_service.dart';
import 'package:telecaller_app/services/phone_call_service.dart';
import 'package:telecaller_app/controller/call_tracking_controller.dart';
import 'package:telecaller_app/view/home_screen/bottomnavigation_bar.dart';

class AddLeadOutgoingCallBottomSheet extends StatefulWidget {
  final String? prefilledPhoneNumber;
  final CallData? callData;

  const AddLeadOutgoingCallBottomSheet({
    super.key,
    this.prefilledPhoneNumber,
    this.callData,
  });

  @override
  State<AddLeadOutgoingCallBottomSheet> createState() =>
      _AddLeadOutgoingCallBottomSheetState();
}

class _AddLeadOutgoingCallBottomSheetState
    extends State<AddLeadOutgoingCallBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _remarksController = TextEditingController();

  String? _selectedBrand;
  String? _selectedLocation;
  String? _selectedLeadType = "Enquiry";
  String? _selectedSubCategory;
  String? _selectedCloseReason;
  String? _selectedItemCategory;
  DateTime? _followUpDate;
  DateTime? _functionDate;
  bool _markAsFollowUp = false;
  bool _markAsComplaint = false;
  bool _hasCalled = false;
  int _callDuration = 0;
  String? _selectedCallStatus;
  int _rating = 0;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.prefilledPhoneNumber != null) {
      _phoneController.text = widget.prefilledPhoneNumber!;
    }

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

    // Initialize call tracking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final callTrackingController = Provider.of<CallTrackingController>(
        context,
        listen: false,
      );
      callTrackingController.initialize();
      callTrackingController.addListener(_onCallDurationUpdate);
    });
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
          if (_selectedCallStatus == null) {
            _selectedCallStatus = "Connected";
          }
        });
      }
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Outgoing Call Header
            Container(
              margin: const EdgeInsets.only(bottom: 0),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: const BoxDecoration(color: Color(0xFF0A2540)),
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 0),
                            child: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Column(
                              children: [
                                const Text(
                                  'Outgoing Call',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatCallDateTime(DateTime.now())} | ${_hasCalled ? "Connected" : "Not Connected"}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Form Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
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
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Form fields - NO FORM WIDGET HERE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lead Type Selector
                  _buildDropdownField(
                    value: _selectedLeadType,
                    label: 'Select Lead Type',
                    items: ["Enquiry", "Booking"],
                    onChanged: (value) {
                      setState(() {
                        _selectedLeadType = value;
                        _selectedSubCategory = null;
                        _selectedCloseReason = null;
                        _selectedItemCategory = null;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Phone Number
                  _buildIconTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 16),

                  // Customer Name
                  _buildIconTextField(
                    controller: _nameController,
                    label: 'Customer Name (Optional)',
                    icon: Icons.person,
                  ),

                  const SizedBox(height: 16),

                  // Call Now Button - only show BEFORE call
                  if (!_hasCalled)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _makeCall,
                        icon: const Icon(Icons.phone, size: 20),
                        label: const Text('Call Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003D7A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // All fields below only show AFTER call is made
                  if (_hasCalled) ...[
                    // Store and Location
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField(
                            value: _selectedBrand,
                            label: 'Store',
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
                          child: _buildDropdownField(
                            value: _selectedLocation,
                            label: 'Location',
                            items:
                                _selectedBrand != null
                                    ? (StoreLocations
                                            .brandStores[_selectedBrand!] ??
                                        [])
                                    : [],
                            onChanged: (value) {
                              setState(() {
                                _selectedLocation = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Function Date and Call Duration (after call)
                    if (_hasCalled)
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectFunctionDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFE0E0E0),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Function Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _functionDate != null
                                          ? _formatDate(_functionDate!)
                                          : 'dd/mm/yyyy',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFE0E0E0),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Call Duration',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _callDuration > 0
                                        ? _formatDuration(_callDuration)
                                        : '00:00 Mins',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF333333),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      InkWell(
                        onTap: _selectFunctionDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Function Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF666666),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _functionDate != null
                                    ? _formatDate(_functionDate!)
                                    : 'dd/mm/yyyy',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Mark as Complaint
                    Row(
                      children: [
                        Checkbox(
                          value: _markAsComplaint,
                          onChanged: (value) {
                            setState(() {
                              _markAsComplaint = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFF003D7A),
                        ),
                        const Text(
                          "Mark as Complaint",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Complaint sub category - only show if marked as complaint
                    if (_markAsComplaint) ...[
                      _buildDropdownField(
                        value: _selectedSubCategory,
                        label: 'Complaint Sub Category',
                        items: [
                          "Product Changed",
                          "Product Cleaning/Quality Issue",
                          "Price Issue",
                          "Delivery Issue",
                          "Return/Exchange Issue",
                          "Bill not recieved",
                          "Security Refund",
                          "Stitching/Alteration Issue",
                          "Product Missing",
                          "Staff Attitude/Communication",
                          "Product-Return-Damage",
                          "Store Ambience",
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSubCategory = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Enquiry specific fields
                    if (!_markAsComplaint &&
                        _selectedLeadType == "Enquiry") ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              value: _selectedSubCategory,
                              label: "Sub Category",
                              items: [
                                "Store Location",
                                "Product Enquiry",
                                "Price Enquiry",
                                "Outside Products",
                                "Others",
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedSubCategory = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdownField(
                              value: _selectedCloseReason,
                              label: 'Close Reason',
                              items: [
                                "Connected to store",
                                "Not Interested",
                                "Visit Directly",
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCloseReason = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField(
                        value: _selectedItemCategory,
                        label: 'Item Category',
                        items: [
                          "Suit",
                          "Bandgala/Jodhpuri",
                          "Indo-western",
                          "Sherwani",
                          "Kurtha",
                          "Kids Suit",
                          "Gowns",
                          "Sarees",
                          "Tie",
                          "Shoes",
                          "Blazer",
                          "Others",
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedItemCategory = value;
                          });
                        },
                      ),
                    ] else if (!_markAsComplaint &&
                        _selectedLeadType == "Booking") ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              value: _selectedSubCategory,
                              label: 'Sub Category',
                              items: [
                                "Delivery Preparation Enquiry",
                                "Cancelation",
                                "Change Product",
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedSubCategory = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdownField(
                              value: _selectedCloseReason,
                              label: 'Close Reason',
                              items: [
                                "Connected to Branch",
                                "Found Another Product",
                                "Price Issue",
                                "Converted to Booking",
                                "Not Interested",
                                "Follow Up Later",
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCloseReason = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Call Remarks
                    _buildIconTextField(
                      controller: _remarksController,
                      label: 'Call Remarks / Notes',
                      icon: Icons.note_outlined,
                      keyboardType: TextInputType.multiline,
                    ),

                    const SizedBox(height: 16),

                    // Mark As Follow Up
                    _buildFollowUpSection(),

                    const SizedBox(height: 20),
                  ],

                  // Buttons
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
                          onPressed:
                              (_isLoading || !_hasCalled || _callDuration == 0)
                                  ? null
                                  : _saveLead,
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
          ],
        ),
      ),
    );
  }

  String _formatCallDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day-$month-$year, $hour:$minute AM';
  }

  Widget _buildIconTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
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
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
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
              child: Text(item, overflow: TextOverflow.ellipsis, maxLines: 1),
            );
          }).toList(),
      selectedItemBuilder: (BuildContext context) {
        return items.map((item) {
          return Text(item, overflow: TextOverflow.ellipsis, maxLines: 1);
        }).toList();
      },
      onChanged: isDisabled ? null : onChanged,
    );
  }

  Widget _buildFollowUpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _markAsFollowUp,
              onChanged: (value) {
                setState(() {
                  _markAsFollowUp = value ?? false;
                  if (_markAsFollowUp && _followUpDate == null) {
                    _followUpDate = DateTime.now().add(const Duration(days: 7));
                  } else if (!_markAsFollowUp) {
                    _followUpDate = null;
                  }
                });
              },
              activeColor: const Color(0xFF003D7A),
            ),
            const Text(
              "Mark as Follow Up",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        if (_markAsFollowUp) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: _selectFollowUpDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF003D7A)),
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF003D7A).withValues(alpha: 0.05),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Follow Up Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _followUpDate != null
                            ? _formatDate(_followUpDate!)
                            : 'Select Date',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              _followUpDate != null
                                  ? const Color(0xFF333333)
                                  : const Color(0xFF999999),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF003D7A),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _makeCall() async {
    try {
      final phoneNumber = _phoneController.text.trim();
      if (phoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter phone number'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Mark this as an outgoing call in CallTrackingController
      final callTrackingController = Provider.of<CallTrackingController>(
        context,
        listen: false,
      );
      callTrackingController.startOutgoingCall(phoneNumber);

      if (mounted) {
        setState(() {
          _hasCalled = true;
          _callDuration = 0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Call initiated'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
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
    final date = await showDatePicker(
      context: context,
      initialDate: _followUpDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _followUpDate = date;
      });
    }
  }

  Future<void> _selectFunctionDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _functionDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _functionDate = date;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')} Mins';
  }

  Future<void> _saveLead() async {
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

      // Concatenate brand and location like 'suitor guy-chavakkad'
      final store =
          _selectedBrand != null && _selectedLocation != null
              ? '$_selectedBrand-$_selectedLocation'
              : _selectedLocation ?? _selectedBrand ?? 'Unknown';

      // Normalize lead type to lowercase format expected by backend
      String normalizedLeadType =
          (_selectedLeadType ?? 'Enquiry').toLowerCase();
      if (normalizedLeadType == 'booking') {
        normalizedLeadType = 'booked'; // Backend expects 'booked' not 'booking'
      }

      final apiResponse = await apiService.createLead(
        leadName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        store: store,
        source: 'Outgoing Call',
        leadType: normalizedLeadType,
        remarks:
            _remarksController.text.trim().isEmpty
                ? null
                : _remarksController.text.trim(),
        followUpFlag: _markAsFollowUp,
        functionDate: _markAsFollowUp ? _followUpDate?.toIso8601String() : null,
        callDuration: _callDuration,
        subCategory: _selectedSubCategory,
        itemCategory: _selectedItemCategory,
        closingAction: _selectedCloseReason,
        markAsComplaint: _markAsComplaint,
      );

      String leadId = '';

      // Try multiple ways to extract lead ID from response
      if (apiResponse.containsKey('lead') && apiResponse['lead'] is Map) {
        final lead = apiResponse['lead'] as Map<String, dynamic>;
        leadId = lead['id']?.toString() ?? lead['_id']?.toString() ?? '';
      }

      if (leadId.isEmpty &&
          apiResponse.containsKey('followUp') &&
          apiResponse['followUp'] is Map) {
        final followUp = apiResponse['followUp'] as Map<String, dynamic>;
        leadId =
            followUp['id']?.toString() ?? followUp['_id']?.toString() ?? '';
      }

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

      // If still no ID found, use phone number as temporary ID (will be updated when backend confirms)
      if (leadId.isEmpty) {
        print(
          'AddLeadOutgoingCallBottomSheet: Warning - Could not extract lead ID from response, using phone as temp ID',
        );
        leadId = _phoneController.text.trim();
      }

      // Check if lead already exists locally to avoid duplicates
      final existingLead = leadRepository.allLeads
          .cast<LeadModel?>()
          .firstWhere(
            (lead) => lead != null && lead.id == leadId,
            orElse: () => null,
          );

      if (existingLead == null) {
        // Only add if it doesn't already exist
        final lead = LeadModel(
          id: leadId,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          brand: _selectedBrand,
          location: _selectedLocation,
          leadStatus: 'New',
          callStatus: _callDuration > 0 ? 'Connected' : 'Not Called',
          followUpDate: _markAsFollowUp ? _followUpDate : null,
          reason:
              _remarksController.text.trim().isEmpty
                  ? null
                  : _remarksController.text.trim(),
          category: null,
          callDuration: _callDuration > 0 ? _callDuration : null,
          callCount: _callDuration > 0 ? 1 : 0,
          createdAt: DateTime.now(),
          source: 'Outgoing Call',
          leadType: normalizedLeadType,
        );

        await leadRepository.addLead(lead);
      }

      if (mounted) {
        if (_markAsFollowUp && _followUpDate != null) {
          Navigator.pop(context);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            BottomNavState.navigateToFollowUp();
          });
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
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
}

void showAddLeadOutgoingCallBottomSheet(
  BuildContext context, {
  String? phoneNumber,
  CallData? callData,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder:
          (context) => AddLeadOutgoingCallBottomSheet(
            prefilledPhoneNumber: phoneNumber,
            callData: callData,
          ),
      fullscreenDialog: true,
    ),
  );
}
