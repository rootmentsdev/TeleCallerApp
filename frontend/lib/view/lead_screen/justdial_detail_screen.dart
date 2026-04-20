import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/services/api_service.dart';
import 'package:telecaller_app/services/phone_call_service.dart';
import 'package:telecaller_app/controller/call_tracking_controller.dart';
import 'package:telecaller_app/controller/lead_screen_controller.dart';

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
  String? _selectedCallStatus;
  String? _selectedRemarks;
  bool _isSaving = false;
  final TextEditingController _remarksController = TextEditingController();

  final List<String> callStatusOptions = [
    "Interested",
    "Not Interested",
    "Call Back Later",
    "Connected",
    "Not Connected",
  ];

  final List<String> remarksOptions = [
    'Satisfied',
    'Not satisfied',
    'Timely Delivered',
    'Excellent customer service',
    'Include more collections',
    'Improve size availability',
    'Matching shoes for rental',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _fetchJustDialLeadDetails();

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
          _selectedCallStatus ??= "Connected";
        });
      }
    }
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

  Future<void> _saveJustDialLead() async {
    if (_selectedCallStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a call status'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Use custom remarks if "Others" is selected, otherwise use the selected remarks
      final finalRemarks =
          _selectedRemarks == 'Others'
              ? _remarksController.text
              : _selectedRemarks;

      final leadController = Provider.of<LeadScreenController>(
        context,
        listen: false,
      );

      await leadController.updateFollowUpLead(
        id: widget.lead.id,
        callStatus: _selectedCallStatus,
        remarks: finalRemarks,
        callDuration: _callDuration > 0 ? _callDuration : null,
      );

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
    _remarksController.dispose();
    super.dispose();
  }

  String _getStoreDisplayName() {
    final brand = widget.lead.brand;
    final location = widget.lead.location;

    if (brand != null && location != null) {
      return '$brand $location';
    } else if (brand != null) {
      return brand;
    } else if (location != null) {
      return location;
    } else {
      return 'N/A';
    }
  }

  String _getDisplayValue(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    return value.toString();
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
                            // Call Details Card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title
                                  const Text(
                                    "Call Details",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: TextConstant.dmSansMedium,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Name
                                  Text(
                                    widget.lead.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: TextConstant.dmSansMedium,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // Phone
                                  Text(
                                    "+91 ${widget.lead.phone}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontFamily: TextConstant.dmSansRegular,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Location and Attended by
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Location",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontFamily:
                                                    TextConstant.dmSansRegular,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _getStoreDisplayName(),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                fontFamily:
                                                    TextConstant.dmSansMedium,
                                                color: Color(0xFF1A1A1A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Attended by",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontFamily:
                                                    TextConstant.dmSansRegular,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _getDisplayValue(
                                                justDialData['attendedBy'] ??
                                                    justDialData['attended_by'],
                                                'N/A',
                                              ),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                fontFamily:
                                                    TextConstant.dmSansMedium,
                                                color: Color(0xFF1A1A1A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Booking Date and Pick Up Date
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Booking Date",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontFamily:
                                                    TextConstant.dmSansRegular,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _getDisplayValue(
                                                justDialData['bookingDate'] ??
                                                    justDialData['booking_date'],
                                                'N/A',
                                              ),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                fontFamily:
                                                    TextConstant.dmSansMedium,
                                                color: Color(0xFF1A1A1A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Pick Up Date",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontFamily:
                                                    TextConstant.dmSansRegular,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _getDisplayValue(
                                                justDialData['functionDate'] ??
                                                    justDialData['function_date'],
                                                'N/A',
                                              ),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                fontFamily:
                                                    TextConstant.dmSansMedium,
                                                color: Color(0xFF1A1A1A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Advance Amount and Total Amount
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Advance Amount",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontFamily:
                                                    TextConstant.dmSansRegular,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '₹${_getDisplayValue(justDialData['advance'] ?? justDialData['advanceAmount'], '0')}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                fontFamily:
                                                    TextConstant.dmSansMedium,
                                                color: Color(0xFF1A1A1A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Total Amount",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontFamily:
                                                    TextConstant.dmSansRegular,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '₹${_getDisplayValue(justDialData['totalAmount'] ?? justDialData['total_amount'] ?? justDialData['productAmount'] ?? justDialData['product_amount'], '0')}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                fontFamily:
                                                    TextConstant.dmSansMedium,
                                                color: Color(0xFF1A1A1A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            if (!_hasCalled)
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
                              )
                            else
                              // Form fields after call
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Call Status
                                  Text(
                                    "Call Status",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontFamily: TextConstant.dmSansRegular,
                                    ),
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
                                      value: _selectedCallStatus,
                                      hint: const Text("Select Status"),
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      items:
                                          callStatusOptions.map((String item) {
                                            return DropdownMenuItem<String>(
                                              value: item,
                                              child: Text(item),
                                            );
                                          }).toList(),
                                      onChanged: (String? value) {
                                        setState(() {
                                          _selectedCallStatus = value;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Remarks
                                  Text(
                                    "Remarks",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontFamily: TextConstant.dmSansRegular,
                                    ),
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
                                      value: _selectedRemarks,
                                      hint: const Text("Select remarks"),
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      items:
                                          remarksOptions.map((String item) {
                                            return DropdownMenuItem<String>(
                                              value: item,
                                              child: Text(item),
                                            );
                                          }).toList(),
                                      onChanged: (String? value) {
                                        setState(() {
                                          _selectedRemarks = value;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Custom remarks text field (shown only if "Others" is selected)
                                  if (_selectedRemarks == 'Others') ...[
                                    Text(
                                      "Enter Custom Remarks",
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
                                      decoration: InputDecoration(
                                        hintText:
                                            "Enter your custom remarks...",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.all(
                                          12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // Save Button
                                  SizedBox(
                                    width: double.infinity,
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
                                                "Save",
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
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
