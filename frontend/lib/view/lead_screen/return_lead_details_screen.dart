import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/date_formatter.dart';
import 'package:telecaller_app/services/api_service.dart';
import 'package:telecaller_app/services/phone_call_service.dart';
import 'package:telecaller_app/controller/call_tracking_controller.dart';
import 'package:telecaller_app/controller/lead_screen_controller.dart';

class ReturnLeadDetailsScreen extends StatefulWidget {
  final LeadModel lead;

  const ReturnLeadDetailsScreen({super.key, required this.lead});

  @override
  State<ReturnLeadDetailsScreen> createState() =>
      _ReturnLeadDetailsScreenState();
}

class _ReturnLeadDetailsScreenState extends State<ReturnLeadDetailsScreen> {
  late Map<String, dynamic> returnData;
  bool _isLoading = true;
  String? _error;
  bool _hasCalled = false;
  int _callDuration = 0;

  // Form fields
  String? _selectedCallStatus;
  String? _selectedRemarks;
  bool _markAsComplaint = false;
  String? _selectedComplaintSubCategory;
  int _rating = 0;
  final TextEditingController _remarksController = TextEditingController();
  bool _isSaving = false;
  String? _selectedService;
  String?
  _securityAmountRefundStatus; // New field for security amount refund status
  bool _isDetailsCollapsed = false;

  // New fields for redesigned form
  final TextEditingController _numberOfFunctionsController =
      TextEditingController();
  final TextEditingController _numberOfAttireController =
      TextEditingController();
  final TextEditingController _competitorController = TextEditingController();

  final List<String> callStatusOptions = [
    "Interested",
    "Not Interested",
    "Call Back Later",
    "Connected",
    "Not Connected",
  ];

  final List<String> serviceOptions = ["Excellent", "Average", "Not satisfied"];

  final List<String> securityAmountRefundOptions = [
    "Security Amount Refunded",
    "Security Amount Not Refunded",
    "Customer Not Checked",
  ];

  final List<String> complaintSubCategoryOptions = [
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
    "Product Damage",
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
    _fetchReturnLeadDetails();

    // Initialize call tracking and listen for call duration updates
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

    print('ReturnLeadDetailsScreen: _onCallDurationUpdate called');
    print('  - lastDuration: ${callTrackingController.lastDuration}');
    print(
      '  - lastCallWasAnswered: ${callTrackingController.lastCallWasAnswered}',
    );
    print('  - current _callDuration: $_callDuration');

    if (callTrackingController.lastDuration != null &&
        callTrackingController.lastDuration! > 0) {
      if (mounted) {
        setState(() {
          _callDuration = callTrackingController.lastDuration!;
          print('  - Updated _callDuration to: $_callDuration');
          // Auto-set call status to Connected if duration > 0
          if (_selectedCallStatus == null) {
            _selectedCallStatus = "Connected";
          }
        });
      }
    } else {
      print('  - Duration not captured (null or 0)');
    }
  }

  Future<void> _fetchReturnLeadDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final apiService = ApiService();
      final response = await apiService.getReturn(widget.lead.id);

      if (mounted) {
        setState(() {
          returnData = response;
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

  Future<void> _makeCall() async {
    try {
      final phoneNumber = widget.lead.phone;
      await PhoneCallService.makeCall(phoneNumber);

      // After call is made, show the form
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

  @override
  void dispose() {
    _remarksController.dispose();
    _numberOfFunctionsController.dispose();
    _numberOfAttireController.dispose();
    _competitorController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')} Mins';
  }

  /// Format ISO date string to readable format (e.g., "29 Jan, 2026")
  String _formatDateString(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'N/A';
    }
    try {
      final date = DateTime.parse(dateString);
      return DateFormatter.formatDate(date);
    } catch (e) {
      return dateString;
    }
  }

  /// Get store display name in "Brand - Location" format
  String _getStoreDisplayName() {
    final brand = widget.lead.brand;
    final location = widget.lead.location;

    if (brand != null && location != null) {
      return '$brand - $location';
    } else if (brand != null) {
      return brand;
    } else if (location != null) {
      return location;
    } else {
      return 'N/A';
    }
  }

  Future<void> _saveReturnLead() async {
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
      // FIX: Get latest duration from CallTrackingController before saving
      final callTrackingController = Provider.of<CallTrackingController>(
        context,
        listen: false,
      );

      // Use the latest duration from controller if available
      final finalCallDuration =
          callTrackingController.lastDuration ?? _callDuration;

      print(
        'ReturnLeadDetailsScreen: Saving with duration=$finalCallDuration (controller=${callTrackingController.lastDuration}, local=$_callDuration)',
      );

      // Use custom remarks if "Others" is selected, otherwise use the selected remarks
      final finalRemarks =
          _selectedRemarks == 'Others'
              ? _remarksController.text
              : _selectedRemarks;

      final leadController = Provider.of<LeadScreenController>(
        context,
        listen: false,
      );

      await leadController.updateReturnLead(
        id: widget.lead.id,
        callStatus: _selectedCallStatus,
        rating: _markAsComplaint ? null : (_rating > 0 ? _rating : null),
        remarks: finalRemarks,
        callDuration: finalCallDuration,
        markAsComplaint: _markAsComplaint ? true : null,
        subCategory: _selectedComplaintSubCategory,
        numberOfFunctions:
            _numberOfFunctionsController.text.isNotEmpty
                ? _numberOfFunctionsController.text
                : null,
        numberOfAttires:
            _numberOfAttireController.text.isNotEmpty
                ? _numberOfAttireController.text
                : null,
        competitor:
            _competitorController.text.isNotEmpty
                ? _competitorController.text
                : null,
        service: _selectedService,
        refundStatus: _securityAmountRefundStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback call updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving feedback call: ${e.toString()}'),
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
                      "Feedback Call",
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
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading feedback call',
                              style: TextStyle(
                                fontFamily: TextConstant.dmSansMedium,
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchReturnLeadDetails,
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
                            // Customer Details Card
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
                                    "Customer Details",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: TextConstant.dmSansMedium,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Name and Phone Number
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Name",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontFamily:
                                                    TextConstant.dmSansRegular,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              widget.lead.name,
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
                                              "Phone Number",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontFamily:
                                                    TextConstant.dmSansRegular,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              widget.lead.phone,
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

                                  const SizedBox(height: 16),

                                  // Store & Location and Attended by
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Store & Location",
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
                                              returnData['attendedBy'] ?? "N/A",
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

                                  const SizedBox(height: 16),

                                  // Return Date and Attended Date
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Return Date",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontFamily:
                                                    TextConstant.dmSansRegular,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatDateString(
                                                widget.lead.returnDate
                                                        ?.toIso8601String() ??
                                                    returnData['returnDate'] ??
                                                    returnData['return_date'],
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
                                              "Attended Date",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontFamily:
                                                    TextConstant.dmSansRegular,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatDateString(
                                                returnData['created_at'] ??
                                                    returnData['createdAt'],
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
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            if (!_hasCalled)
                              // Call Now Button (before call)
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
                              // Form fields (after call)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!_isDetailsCollapsed) ...[
                                    // Call Status and Call Duration
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Service",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                  fontFamily:
                                                      TextConstant
                                                          .dmSansRegular,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.grey[300]!,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: DropdownButton<String>(
                                                  value: _selectedService,
                                                  hint: const Text("Select"),
                                                  isExpanded: true,
                                                  underline: const SizedBox(),
                                                  items:
                                                      serviceOptions.map((
                                                        String item,
                                                      ) {
                                                        return DropdownMenuItem<
                                                          String
                                                        >(
                                                          value: item,
                                                          child: Text(item),
                                                        );
                                                      }).toList(),
                                                  onChanged: (String? value) {
                                                    setState(() {
                                                      _selectedService = value;
                                                    });
                                                  },
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
                                                "Call Duration",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                  fontFamily:
                                                      TextConstant
                                                          .dmSansRegular,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
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
                                                child: Text(
                                                  _formatDuration(
                                                    _callDuration,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[800],
                                                    fontFamily:
                                                        TextConstant
                                                            .dmSansRegular,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Call Status
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Call Status",
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
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: DropdownButton<String>(
                                            value: _selectedCallStatus,
                                            hint: const Text("Select"),
                                            isExpanded: true,
                                            underline: const SizedBox(),
                                            items:
                                                callStatusOptions.map((
                                                  String item,
                                                ) {
                                                  return DropdownMenuItem<
                                                    String
                                                  >(
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
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Security Amount Refund Status (hidden when complaint is marked)
                                    if (!_markAsComplaint)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Security Amount Refund Status",
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
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey[300]!,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: DropdownButton<String>(
                                              value:
                                                  _securityAmountRefundStatus,
                                              hint: const Text("Select"),
                                              isExpanded: true,
                                              underline: const SizedBox(),
                                              items:
                                                  securityAmountRefundOptions
                                                      .map((String item) {
                                                        return DropdownMenuItem<
                                                          String
                                                        >(
                                                          value: item,
                                                          child: Text(item),
                                                        );
                                                      })
                                                      .toList(),
                                              onChanged: (String? value) {
                                                setState(() {
                                                  _securityAmountRefundStatus =
                                                      value;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],

                                  // Mark as Complaint
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _markAsComplaint,
                                        onChanged: (value) {
                                          setState(() {
                                            _markAsComplaint = value ?? false;
                                            _isDetailsCollapsed =
                                                _markAsComplaint;
                                            if (!_markAsComplaint) {
                                              _selectedComplaintSubCategory =
                                                  null;
                                            } else {
                                              // Clear refund status when complaint is marked
                                              _securityAmountRefundStatus =
                                                  null;
                                            }
                                          });
                                        },
                                        activeColor: ColorConstant.primaryColor,
                                      ),
                                      Text(
                                        "Mark as Complaint",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.red[400],
                                          fontFamily: TextConstant.dmSansMedium,
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (_markAsComplaint) ...[
                                    const SizedBox(height: 16),
                                    // Sub Category Dropdown
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Sub Category",
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
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: DropdownButton<String>(
                                            value:
                                                _selectedComplaintSubCategory,
                                            hint: const Text("Select"),
                                            isExpanded: true,
                                            underline: const SizedBox(),
                                            items:
                                                complaintSubCategoryOptions.map(
                                                  (String item) {
                                                    return DropdownMenuItem<
                                                      String
                                                    >(
                                                      value: item,
                                                      child: Text(item),
                                                    );
                                                  },
                                                ).toList(),
                                            onChanged: (String? value) {
                                              setState(() {
                                                _selectedComplaintSubCategory =
                                                    value;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  if (!_isDetailsCollapsed) ...[
                                    const SizedBox(height: 16),

                                    // No. of functions and No. of attires
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "No. of functions",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                  fontFamily:
                                                      TextConstant
                                                          .dmSansRegular,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              TextField(
                                                controller:
                                                    _numberOfFunctionsController,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration: InputDecoration(
                                                  hintText: "Eg. 2",
                                                  hintStyle: TextStyle(
                                                    color: Colors.grey[400],
                                                    fontFamily:
                                                        TextConstant
                                                            .dmSansRegular,
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    borderSide: BorderSide(
                                                      color: Colors.grey[300]!,
                                                    ),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              Colors.grey[300]!,
                                                        ),
                                                      ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              ColorConstant
                                                                  .primaryColor,
                                                          width: 2,
                                                        ),
                                                      ),
                                                  contentPadding:
                                                      const EdgeInsets.all(12),
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
                                                "No. of attires",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                  fontFamily:
                                                      TextConstant
                                                          .dmSansRegular,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              TextField(
                                                controller:
                                                    _numberOfAttireController,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration: InputDecoration(
                                                  hintText: "Eg. 4",
                                                  hintStyle: TextStyle(
                                                    color: Colors.grey[400],
                                                    fontFamily:
                                                        TextConstant
                                                            .dmSansRegular,
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    borderSide: BorderSide(
                                                      color: Colors.grey[300]!,
                                                    ),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              Colors.grey[300]!,
                                                        ),
                                                      ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              ColorConstant
                                                                  .primaryColor,
                                                          width: 2,
                                                        ),
                                                      ),
                                                  contentPadding:
                                                      const EdgeInsets.all(12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Competitor (Optional)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Competitor (Optional)",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontFamily:
                                                TextConstant.dmSansRegular,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: _competitorController,
                                          decoration: InputDecoration(
                                            hintText: "Enter competitor name",
                                            hintStyle: TextStyle(
                                              color: Colors.grey[400],
                                              fontFamily:
                                                  TextConstant.dmSansRegular,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Colors.grey[300]!,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Colors.grey[300]!,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color:
                                                    ColorConstant.primaryColor,
                                                width: 2,
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.all(12),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Rating (only show if not marked as complaint)
                                    if (!_markAsComplaint)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Rating",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontFamily:
                                                  TextConstant.dmSansRegular,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: List.generate(5, (index) {
                                              return GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _rating = index + 1;
                                                  });
                                                },
                                                child: Icon(
                                                  Icons.star,
                                                  size: 32,
                                                  color:
                                                      index < _rating
                                                          ? Colors.amber
                                                          : Colors.grey[300],
                                                ),
                                              );
                                            }),
                                          ),
                                        ],
                                      ),

                                    const SizedBox(height: 16),
                                  ],

                                  if (!_isDetailsCollapsed) ...[
                                    // Call Remarks - Show in expanded view
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Call Remarks / Notes",
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
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: DropdownButton<String>(
                                            value: _selectedRemarks,
                                            hint: const Text("Select remarks"),
                                            isExpanded: true,
                                            underline: const SizedBox(),
                                            items:
                                                remarksOptions.map((
                                                  String item,
                                                ) {
                                                  return DropdownMenuItem<
                                                    String
                                                  >(
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
                                        const SizedBox(height: 8),
                                        // Custom remarks text field (shown only if "Others" is selected)
                                        if (_selectedRemarks == 'Others') ...[
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller: _remarksController,
                                            maxLines: 3,
                                            decoration: InputDecoration(
                                              hintText:
                                                  "Enter your custom remarks",
                                              hintStyle: TextStyle(
                                                color: Colors.grey[400],
                                                fontFamily:
                                                    TextConstant.dmSansRegular,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: Colors.grey[300]!,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: Colors.grey[300]!,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color:
                                                      ColorConstant
                                                          .primaryColor,
                                                  width: 2,
                                                ),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.all(12),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 16),
                                      ],
                                    ),
                                  ],

                                  // Call Remarks for Complaint - Show only when complaint is marked
                                  if (_markAsComplaint)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Call Remarks / Notes",
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
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: DropdownButton<String>(
                                            value: _selectedRemarks,
                                            hint: const Text("Select remarks"),
                                            isExpanded: true,
                                            underline: const SizedBox(),
                                            items:
                                                remarksOptions.map((
                                                  String item,
                                                ) {
                                                  return DropdownMenuItem<
                                                    String
                                                  >(
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
                                        const SizedBox(height: 8),
                                        // Custom remarks text field (shown only if "Others" is selected)
                                        if (_selectedRemarks == 'Others') ...[
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller: _remarksController,
                                            maxLines: 3,
                                            decoration: InputDecoration(
                                              hintText:
                                                  "Enter your custom remarks",
                                              hintStyle: TextStyle(
                                                color: Colors.grey[400],
                                                fontFamily:
                                                    TextConstant.dmSansRegular,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: Colors.grey[300]!,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: Colors.grey[300]!,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color:
                                                      ColorConstant
                                                          .primaryColor,
                                                  width: 2,
                                                ),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.all(12),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 16),
                                      ],
                                    ),

                                  if (!_isDetailsCollapsed) ...[
                                    const SizedBox(height: 24),
                                  ],

                                  // Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            side: BorderSide(
                                              color: Colors.grey[300]!,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            "Cancel",
                                            style: TextStyle(
                                              color: Colors.grey[800],
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              fontFamily:
                                                  TextConstant.dmSansMedium,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed:
                                              _isSaving
                                                  ? null
                                                  : _saveReturnLead,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                ColorConstant.primaryColor,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child:
                                              _isSaving
                                                  ? const SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  )
                                                  : const Text(
                                                    "Save Call Update",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontFamily:
                                                          TextConstant
                                                              .dmSansMedium,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                    ],
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
