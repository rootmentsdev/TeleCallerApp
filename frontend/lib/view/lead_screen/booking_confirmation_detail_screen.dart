import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/date_formatter.dart';
import 'package:telecaller_app/services/phone_call_service.dart';
import 'package:telecaller_app/controller/call_tracking_controller.dart';
import 'package:telecaller_app/controller/lead_screen_controller.dart';
import 'package:telecaller_app/controller/lead_repository.dart';

class BookingConfirmationDetailScreen extends StatefulWidget {
  final LeadModel lead;

  const BookingConfirmationDetailScreen({super.key, required this.lead});

  @override
  State<BookingConfirmationDetailScreen> createState() =>
      _BookingConfirmationDetailScreenState();
}

class _BookingConfirmationDetailScreenState
    extends State<BookingConfirmationDetailScreen> {
  late Map<String, dynamic> bookingData;
  bool _isLoading = true;
  String? _error;
  bool _hasCalled = false;
  int _callDuration = 0;

  // Form fields
  String? _selectedCallStatus;
  String? _selectedLeadStatus;
  String? _selectedService;
  bool _billReceived = false;
  bool _amountMismatch = false;
  String? _selectedAmountType; // Advance, Security, Both

  final List<String> amountTypeOptions = ["Advance", "Security", "Both"];
  final TextEditingController _remarksController = TextEditingController();
  bool _isSaving = false;

  final List<String> callStatusOptions = [
    "Not called yet",
    "Interested",
    "Not Interested",
    "Call Back Later",
    "Connected",
    "Not Connected",
  ];

  final List<String> leadStatusOptions = [
    "No Status",
    "New Lead",
    "Contacted",
    "Qualified",
    "Negotiation",
    "Won",
    "Lost",
  ];

  final List<String> serviceOptions = ["Excellent", "Average", "Not satisfied"];

  @override
  void initState() {
    super.initState();
    _fetchBookingConfirmationDetails();

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

    if (callTrackingController.lastDuration != null &&
        callTrackingController.lastDuration! > 0) {
      if (mounted) {
        setState(() {
          _callDuration = callTrackingController.lastDuration!;
          // Auto-set call status to Connected if duration > 0
          if (_selectedCallStatus == null) {
            _selectedCallStatus = "Connected";
          }
        });
      }
    }
  }

  Future<void> _fetchBookingConfirmationDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final repository = LeadRepository();
      final bookingDataFromRepo = repository.getBookingConfirmationData(
        widget.lead.id,
      );

      if (mounted) {
        setState(() {
          bookingData = bookingDataFromRepo ?? {};
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
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')} Mins';
  }

  /// Format date from DateTime
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormatter.formatDate(date);
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

  /// Format currency (e.g. ₹5,500)
  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'N/A';
    try {
      final value = amount is String ? double.tryParse(amount) : amount;
      if (value == null) return 'N/A';
      final formatted = value
          .toStringAsFixed(0)
          .replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
      return '₹$formatted';
    } catch (e) {
      return amount.toString();
    }
  }

  String? _formatPhoneDisplay(String? phone) {
    if (phone == null || phone.isEmpty) return null;
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) {
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    return phone;
  }

  Future<void> _saveBookingConfirmation() async {
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
      final leadController = Provider.of<LeadScreenController>(
        context,
        listen: false,
      );

      // Use updateBookingConfirmationLead method
      String? remarks =
          _remarksController.text.isNotEmpty ? _remarksController.text : null;
      if (_amountMismatch && _selectedAmountType != null) {
        final typeNote = 'Amount Mismatch Type: $_selectedAmountType';
        remarks = remarks != null ? '$remarks\n$typeNote' : typeNote;
      }

      await leadController.updateBookingConfirmationLead(
        id: widget.lead.id,
        callStatus: _selectedCallStatus,
        leadStatus: _selectedLeadStatus,
        service: _selectedService,
        billReceived: _billReceived,
        amountMismatch: _amountMismatch,
        advancePaid: null,
        securityPaid: null,
        remarks: remarks,
        callDuration: _callDuration > 0 ? _callDuration : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking confirmation call updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving booking confirmation call: ${e.toString()}',
            ),
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
                      "Booking Confirmation Leads",
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
                              'Error loading booking confirmation',
                              style: TextStyle(
                                fontFamily: TextConstant.dmSansMedium,
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchBookingConfirmationDetails,
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

                                  // Name (bold, prominent)
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
                                  // Phone Number (below name, smaller)
                                  Text(
                                    _formatPhoneDisplay(widget.lead.phone) ??
                                        widget.lead.phone,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                      fontFamily: TextConstant.dmSansRegular,
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Two-column: Location | Attended by
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                fontWeight: FontWeight.w500,
                                                fontFamily:
                                                    TextConstant.dmSansMedium,
                                                color: Color(0xFF1A1A1A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
                                              bookingData['attendedBy'] ??
                                                  bookingData['attended_by'] ??
                                                  "N/A",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
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

                                  // Two-column: Booking Date | Pick Up Date
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                              _formatDate(
                                                widget.lead.enquiryDate,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                fontFamily:
                                                    TextConstant.dmSansMedium,
                                                color: Color(0xFF1A1A1A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
                                              _formatDate(
                                                widget.lead.functionDate,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
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

                                  // Two-column: Advance Amount | Total Amount
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                              _formatCurrency(
                                                bookingData['advance'] ??
                                                    bookingData['advanceAmount'] ??
                                                    bookingData['advance_amount'],
                                              ),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                fontFamily:
                                                    TextConstant.dmSansMedium,
                                                color: Color(0xFF1A1A1A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
                                              _formatCurrency(
                                                bookingData['totalAmount'] ??
                                                    bookingData['total_amount'] ??
                                                    bookingData['productAmount'] ??
                                                    bookingData['product_amount'],
                                              ),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
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
                                  // Service and Call Duration
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
                                                    TextConstant.dmSansRegular,
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
                                                    TextConstant.dmSansRegular,
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
                                                _formatDuration(_callDuration),
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

                                  // Bill Received
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Bill Received",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontFamily:
                                              TextConstant.dmSansRegular,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: _billReceived,
                                            onChanged: (value) {
                                              setState(() {
                                                _billReceived = value ?? false;
                                              });
                                            },
                                            activeColor:
                                                ColorConstant.primaryColor,
                                          ),
                                          const Text(
                                            "Yes",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(width: 48),
                                          Checkbox(
                                            value: !_billReceived,
                                            onChanged: (value) {
                                              setState(() {
                                                _billReceived =
                                                    !(value ?? false);
                                              });
                                            },
                                            activeColor:
                                                ColorConstant.primaryColor,
                                          ),
                                          const Text(
                                            "No",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Amount Mismatch Checkbox
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _amountMismatch,
                                        onChanged: (value) {
                                          setState(() {
                                            _amountMismatch = value ?? false;
                                            if (!_amountMismatch) {
                                              _selectedAmountType = null;
                                            }
                                          });
                                        },
                                        activeColor: ColorConstant.primaryColor,
                                      ),
                                      Text(
                                        "Amount Mismatch",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.red[400],
                                          fontFamily: TextConstant.dmSansMedium,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Amount Type (shown when amount mismatch is checked)
                                  if (_amountMismatch) ...[
                                    const SizedBox(height: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Amount Type",
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
                                            value: _selectedAmountType,
                                            hint: const Text(
                                              "Select Amount Type",
                                            ),
                                            isExpanded: true,
                                            underline: const SizedBox(),
                                            items:
                                                amountTypeOptions.map((
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
                                                _selectedAmountType = value;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  const SizedBox(height: 16),

                                  // Call Remarks / Notes
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
                                      TextField(
                                        controller: _remarksController,
                                        maxLines: 3,
                                        decoration: InputDecoration(
                                          hintText: "Enter your remarks",
                                          hintStyle: TextStyle(
                                            color: Colors.grey[400],
                                            fontFamily:
                                                TextConstant.dmSansRegular,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.grey[300]!,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.grey[300]!,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide(
                                              color: ColorConstant.primaryColor,
                                              width: 2,
                                            ),
                                          ),
                                          contentPadding: const EdgeInsets.all(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 24),

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
                                                  : _saveBookingConfirmation,
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
