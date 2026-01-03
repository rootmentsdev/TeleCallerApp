import 'package:flutter/material.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/services/api_service.dart';
import 'package:telecaller_app/services/phone_call_service.dart';

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

  String? selectedCallStatus;
  String? selectedLeadStatus;
  int rating = 0;
  final TextEditingController remarksController = TextEditingController();
  bool _isDirty = false;
  bool _hasCalled = false; // Track if call has been made

  final List<String> callStatusOptions = [
    "Not called yet",
    "Connected",
    "Not Connected",
    "Call Back Later",
    "Confirmed",
    "Cancelled",
  ];

  final List<String> leadStatusOptions = [
    "New Lead",
    "Contacted",
    "Qualified",
    "Negotiation",
    "Won",
    "Lost",
  ];

  @override
  void initState() {
    super.initState();
    _fetchReturnLeadDetails();
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

          // Initialize form fields from fetched data
          selectedCallStatus = returnData['callStatus'] ?? 'Not called yet';
          selectedLeadStatus = returnData['leadStatus'];
          rating = returnData['rating'] ?? 0;
          remarksController.text = returnData['remarks'] ?? '';
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

  Future<void> _saveChanges() async {
    try {
      final apiService = ApiService();
      await apiService.updateRentOutLead(
        id: widget.lead.id,
        callStatus: selectedCallStatus,
        leadStatus: selectedLeadStatus,
        remarks: remarksController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Return lead updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving changes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _makeCall() async {
    try {
      final phoneNumber = widget.lead.phone;
      await PhoneCallService.makeCall(phoneNumber);

      // Enable form fields after call is initiated
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
    remarksController.dispose();
    super.dispose();
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Return Lead",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: TextConstant.dmSansMedium,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.lead.location ?? "Store",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontFamily: TextConstant.dmSansRegular,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
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
                              'Error loading return lead',
                              style: TextStyle(
                                fontFamily: TextConstant.dmSansMedium,
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error ?? '',
                              style: TextStyle(
                                fontFamily: TextConstant.dmSansRegular,
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
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
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Customer Information
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            widget.lead.name,
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              fontFamily:
                                                  TextConstant.dmSansMedium,
                                            ),
                                          ),
                                          const SizedBox(width: 132),
                                          ElevatedButton.icon(
                                            onPressed: _makeCall,
                                            icon: const Icon(
                                              Icons.call,
                                              size: 18,
                                            ),
                                            label: const Text("Call Now"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  ColorConstant.primaryColor,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.lead.phone,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.grey[700],
                                          fontFamily:
                                              TextConstant.dmSansRegular,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Return Details from Backend
                            _buildDetailRow(
                              "Booking Number",
                              returnData['bookingNumber'] ?? "N/A",
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              "Return Date",
                              returnData['returnDate'] ?? "N/A",
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              "Security Amount",
                              returnData['securityAmount'] ?? "N/A",
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              "Refund Status",
                              returnData['refundStatus'] ?? "N/A",
                            ),
                            const SizedBox(height: 24),

                            // Call Status and Lead Status
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDropdown(
                                    label: "Call Status",
                                    value: selectedCallStatus,
                                    items: callStatusOptions,
                                    enabled: _hasCalled,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedCallStatus = value;
                                        _isDirty = true;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDropdown(
                                    label: "Lead Status",
                                    value: selectedLeadStatus,
                                    items: leadStatusOptions,
                                    hint: "Select Lead Status",
                                    enabled: _hasCalled,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedLeadStatus = value;
                                        _isDirty = true;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Rating
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Rating",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: TextConstant.dmSansMedium,
                                    color:
                                        _hasCalled
                                            ? Colors.grey[800]
                                            : Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: List.generate(5, (index) {
                                    return GestureDetector(
                                      onTap:
                                          _hasCalled
                                              ? () {
                                                setState(() {
                                                  rating = index + 1;
                                                  _isDirty = true;
                                                });
                                              }
                                              : null,
                                      child: Icon(
                                        Icons.star,
                                        size: 32,
                                        color:
                                            index < rating
                                                ? Colors.amber
                                                : (_hasCalled
                                                    ? Colors.grey[300]
                                                    : Colors.grey[200]),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Remarks
                            Text(
                              "Remarks",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: TextConstant.dmSansMedium,
                                color:
                                    _hasCalled
                                        ? Colors.grey[800]
                                        : Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: remarksController,
                              enabled: _hasCalled,
                              maxLines: 3,
                              onChanged: (_) {
                                setState(() {
                                  _isDirty = true;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: "Enter your remarks",
                                hintStyle: TextStyle(
                                  color:
                                      _hasCalled
                                          ? Colors.grey[400]
                                          : Colors.grey[300],
                                  fontFamily: TextConstant.dmSansRegular,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color:
                                        _hasCalled
                                            ? Colors.grey[300]!
                                            : Colors.grey[200]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: ColorConstant.primaryColor,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      side: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      "Cancel",
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: TextConstant.dmSansMedium,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed:
                                        _hasCalled && _isDirty
                                            ? () async {
                                              await _saveChanges();
                                            }
                                            : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          _hasCalled && _isDirty
                                              ? ColorConstant.primaryColor
                                              : Colors.grey[300],
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      "Save Changes",
                                      style: TextStyle(
                                        color:
                                            _hasCalled && _isDirty
                                                ? Colors.white
                                                : Colors.grey[600],
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: TextConstant.dmSansMedium,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
            fontFamily: TextConstant.dmSansRegular,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
            fontFamily: TextConstant.dmSansMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    String? hint,
    required Function(String?)? onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: TextConstant.dmSansMedium,
            color: enabled ? Colors.grey[800] : Colors.grey[400],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
            ),
            borderRadius: BorderRadius.circular(8),
            color: enabled ? Colors.transparent : Colors.grey[100],
          ),
          child: DropdownButton<String>(
            value: value,
            hint: Text(
              hint ?? "Select $label",
              style: TextStyle(
                color: enabled ? Colors.grey[400] : Colors.grey[300],
                fontFamily: TextConstant.dmSansRegular,
              ),
            ),
            isExpanded: true,
            underline: const SizedBox(),
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: enabled ? Colors.grey[600] : Colors.grey[300],
            ),
            items:
                items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: TextStyle(
                        fontFamily: TextConstant.dmSansRegular,
                        fontSize: 14,
                        color: enabled ? Colors.black : Colors.grey[400],
                      ),
                    ),
                  );
                }).toList(),
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ],
    );
  }
}
